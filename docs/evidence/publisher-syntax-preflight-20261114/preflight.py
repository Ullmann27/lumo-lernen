#!/usr/bin/env python3
"""Syntax-only review of the immutable, superseded LUMO publisher.

The workflow is data. Its run blocks are passed exclusively to bash -n.
Python heredocs are parsed and compiled, never executed.
"""
from __future__ import annotations
import ast
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import yaml
from yaml.nodes import MappingNode, ScalarNode, SequenceNode

ROOT = Path(__file__).resolve().parent
EXPECTED_BLOB = "04247c39f61e138bcca767447b1b0bec5aeac611"
SOURCE_COMMIT = "bb5aa0e58355d29258392693674c5144079b9e6b"
SOURCE = ROOT / "original-publisher.yml"
HEREDOC = re.compile(
    r"^[ \t]*python(?:3(?:\.\d+)?)?\s+-\s+<<(?P<tabs>-?)"
    r"(?P<quote>['\"]?)(?P<delimiter>[A-Za-z_][A-Za-z0-9_]*)(?P=quote)[ \t]*$"
)

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def git_blob(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()

def mapping(node: object, where: str) -> dict[str, object]:
    if not isinstance(node, MappingNode):
        raise ValueError(f"{where}: expected a YAML mapping")
    result = {}
    for key, value in node.value:
        if not isinstance(key, ScalarNode):
            raise ValueError(f"{where}: non-scalar mapping key")
        if key.value in result:
            raise ValueError(f"{where}: duplicate key {key.value!r}")
        result[key.value] = value
    return result

def scalar(node: object, where: str) -> str:
    if not isinstance(node, ScalarNode):
        raise ValueError(f"{where}: expected a YAML scalar")
    return node.value

def assert_unique_keys(node: object, where: str) -> None:
    if isinstance(node, MappingNode):
        for key, value in mapping(node, where).items():
            assert_unique_keys(value, f"{where}.{key}")
    elif isinstance(node, SequenceNode):
        for index, value in enumerate(node.value):
            assert_unique_keys(value, f"{where}[{index}]")

def default_shell(node: object, where: str) -> str | None:
    if node is None:
        return None
    defaults = mapping(node, where)
    if "run" not in defaults:
        return None
    run = mapping(defaults["run"], f"{where}.run")
    return scalar(run["shell"], f"{where}.run.shell") if "shell" in run else None

def write_exact(relative: str, content: str) -> Path:
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content.encode("utf-8"))
    return path

def python_heredocs(block: str, step: str):
    lines = block.splitlines(keepends=True)
    index = 0
    while index < len(lines):
        line = lines[index].rstrip("\r\n")
        match = HEREDOC.fullmatch(line)
        if not match:
            if "<<" in line:
                raise ValueError(f"{step}: unsupported heredoc at run line {index + 1}")
            index += 1
            continue
        header_index = index
        delimiter = match["delimiter"]
        strip_tabs = bool(match["tabs"])
        index += 1
        body = []
        while index < len(lines):
            candidate = lines[index].rstrip("\r\n")
            if strip_tabs:
                candidate = candidate.lstrip("\t")
            if candidate == delimiter:
                break
            body.append(lines[index].lstrip("\t") if strip_tabs else lines[index])
            index += 1
        if index == len(lines):
            raise ValueError(f"{step}: unterminated Python heredoc {delimiter}")
        yield header_index, index, "".join(body)
        index += 1

def main() -> int:
    started = datetime.now(timezone.utc).isoformat()
    source_bytes = SOURCE.read_bytes()
    actual_blob = git_blob(source_bytes)
    if actual_blob != EXPECTED_BLOB:
        raise ValueError(f"Source blob mismatch: {actual_blob}")
    text = source_bytes.decode("utf-8")
    # Composition preserves keys such as 'on' without YAML 1.1 boolean conversion.
    yaml.safe_load(text)
    document = yaml.compose(text, Loader=yaml.SafeLoader)
    assert_unique_keys(document, "workflow")
    workflow = mapping(document, "workflow")
    jobs = mapping(workflow["jobs"], "jobs")
    bash = shutil.which("bash")
    if bash is None:
        raise RuntimeError("bash is unavailable")
    bash = str(Path(bash).resolve())
    # No BASH_ENV, imported functions, profile, or other startup commands.
    syntax_env = {"PATH": os.defpath, "LC_ALL": "C"}
    version = subprocess.run(
        [bash, "--version"], check=True, capture_output=True, text=True,
        env=syntax_env, stdin=subprocess.DEVNULL,
    )
    write_exact("bash-version.txt", version.stdout)
    print(f"UTC_START {started}", flush=True)
    print(f"SOURCE_COMMIT {SOURCE_COMMIT}", flush=True)
    print(f"SOURCE_BLOB {actual_blob}", flush=True)
    print(f"SOURCE_SHA256 {sha256(source_bytes)}", flush=True)
    print(f"PYTHON {sys.version}", flush=True)
    print(f"PYYAML {yaml.__version__}", flush=True)
    print(f"BASH {version.stdout.splitlines()[0]}", flush=True)
    print("PASS YAML safe parse and unique mapping keys", flush=True)
    bash_results = []
    python_results = []
    steps_seen = 0
    run_steps_seen = 0
    workflow_default = default_shell(workflow.get("defaults"), "workflow.defaults")
    for job_id, job_node in jobs.items():
        job = mapping(job_node, f"jobs.{job_id}")
        job_default = default_shell(job.get("defaults"), f"jobs.{job_id}.defaults")
        steps_node = job.get("steps")
        if not isinstance(steps_node, SequenceNode):
            raise ValueError(f"jobs.{job_id}.steps: expected a sequence")
        for step_index, step_node in enumerate(steps_node.value, 1):
            steps_seen += 1
            step_id = f"{job_id}/step-{step_index:02d}"
            step = mapping(step_node, step_id)
            if "run" not in step:
                continue
            run_steps_seen += 1
            name = scalar(step["name"], f"{step_id}.name") if "name" in step else step_id
            shell = (scalar(step["shell"], f"{step_id}.shell")
                     if "shell" in step else job_default or workflow_default)
            if shell != "bash":
                raise ValueError(f"{step_id}: unsupported or implicit shell {shell!r}")
            run_node = step["run"]
            block = scalar(run_node, f"{step_id}.run")
            if "$" + "{{" in block:
                raise ValueError(f"{step_id}: expression rendering requires separate review")
            relative = f"bash/step-{step_index:02d}.sh"
            path = write_exact(relative, block)
            command = [bash, "--noprofile", "--norc", "-n", str(path)]
            print("CHECK " + json.dumps(command), flush=True)
            checked = subprocess.run(
                command, check=False, capture_output=True, text=True,
                env=syntax_env, stdin=subprocess.DEVNULL, timeout=10,
            )
            result = {
                "job": job_id, "step_index": step_index, "name": name,
                "shell": shell, "original_run_line": run_node.start_mark.line + 2,
                "file": relative, "bytes": len(block.encode("utf-8")),
                "sha256": sha256(block.encode("utf-8")),
                "command": command, "exit_code": checked.returncode,
                "stdout": checked.stdout, "stderr": checked.stderr,
            }
            bash_results.append(result)
            print("BASH_RESULT " + json.dumps(result, ensure_ascii=False), flush=True)
            if checked.returncode:
                raise RuntimeError(f"{step_id}: bash -n failed")
            for opening, closing, body in python_heredocs(block, step_id):
                number = len(python_results) + 1
                py_relative = f"python/heredoc-{number:02d}-step-{step_index:02d}.py"
                py_path = write_exact(py_relative, body)
                parsed = ast.parse(body, filename=str(py_path), mode="exec")
                compiled = compile(parsed, str(py_path), "exec", dont_inherit=True)
                del compiled
                py_result = {
                    "job": job_id, "step_index": step_index, "name": name,
                    "file": py_relative, "bytes": len(body.encode("utf-8")),
                    "sha256": sha256(body.encode("utf-8")),
                    "opening_run_line": opening + 1, "closing_run_line": closing + 1,
                    "original_body_first_line": run_node.start_mark.line + opening + 3,
                    "ast_parse": "PASS", "compile": "PASS", "executed": False,
                }
                python_results.append(py_result)
                print("PYTHON_RESULT " + json.dumps(py_result, ensure_ascii=False), flush=True)
    if run_steps_seen != len(bash_results) or not bash_results:
        raise RuntimeError("Run-step coverage is incomplete")
    summary = {
        "schema": 1, "status": "PASS_SYNTAX_ONLY",
        "started_at": started, "completed_at": datetime.now(timezone.utc).isoformat(),
        "source_commit": SOURCE_COMMIT, "source_blob": actual_blob,
        "source_sha256": sha256(source_bytes), "source_bytes": len(source_bytes),
        "source_state": "SUPERSEDED; bound to 07cac722 / run 43586101225; not publishable",
        "python_version": sys.version, "pyyaml_version": yaml.__version__,
        "bash_executable": bash, "bash_version": version.stdout.splitlines()[0],
        "yaml_parse": "PASS", "jobs": len(jobs), "steps_seen": steps_seen,
        "run_steps_seen": run_steps_seen, "bash_blocks_checked": len(bash_results),
        "python_heredocs_checked": len(python_results),
        "bash_blocks": bash_results, "python_heredocs": python_results,
        "workflow_commands_executed": False, "python_heredocs_executed": False,
        "workflow_triggered": False, "source_binding_modified": False,
        "publication_attempted": False,
        "limits": [
            "No workflow command, action, network request or release operation was executed.",
            "YAML parsing is not actionlint or GitHub Actions expression validation.",
            "Bash syntax checking does not validate command availability or runtime behavior.",
            "Python compilation does not resolve imports, inspect data, or execute verifier logic.",
            "This superseded 07-bound workflow must not be activated or published.",
        ],
    }
    write_exact("result.json", json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    print("PASS_SYNTAX_ONLY "
          + json.dumps({key: summary[key] for key in (
              "jobs", "steps_seen", "run_steps_seen",
              "bash_blocks_checked", "python_heredocs_checked",
          )}), flush=True)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
