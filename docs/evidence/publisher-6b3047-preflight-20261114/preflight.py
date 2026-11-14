#!/usr/bin/env python3
"""Static syntax and preservation checks for the inactive 6b publisher."""
import ast
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import yaml
from yaml.nodes import MappingNode, SequenceNode, ScalarNode

ROOT = Path(__file__).resolve().parent
WORKFLOW = ROOT / "lumo-live-2020-publish.yml"
EXPECTED_BLOB = "c4a901a649f49b80cd16e22ece3c40b1a3cbd12d"
ACTIONLINT = Path("/workspace/scratch/909ddb52fe7b/native-upstream-057-review/trigger-patch/bin/actionlint")
HEREDOC = re.compile(r"^(?:python3 -|cat > publication/verify-additional-acceptance[.]py) <<'(?P<delimiter>[A-Za-z_][A-Za-z0-9_]*)'$")

def mapping(node):
    if not isinstance(node, MappingNode):
        raise ValueError("Expected mapping")
    result = {}
    for key, value in node.value:
        if not isinstance(key, ScalarNode) or key.value in result:
            raise ValueError("Duplicate or non-scalar YAML key")
        result[key.value] = value
    return result

def unique_keys(node):
    if isinstance(node, MappingNode):
        for value in mapping(node).values():
            unique_keys(value)
    elif isinstance(node, SequenceNode):
        for value in node.value:
            unique_keys(value)

def main():
    data = WORKFLOW.read_bytes()
    blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
    if blob != EXPECTED_BLOB:
        raise ValueError("Unexpected workflow bytes")
    doc = yaml.compose(data.decode(), Loader=yaml.SafeLoader)
    unique_keys(doc)
    parsed = yaml.load(data.decode(), Loader=yaml.BaseLoader)
    job = parsed["jobs"]["publish-verified-test-apk"]
    if job["env"]["SOURCE_SHA"] != "6b3047b7979dfb86d837e74a21b0fd890e4f9e66":
        raise ValueError("Wrong accepted source")
    if job["env"]["ACCEPTANCE_RUN"] != "43616038272":
        raise ValueError("Wrong complete acceptance")
    if parsed["on"]["push"]["branches"] != ["delivery/lumo-live-2020-20261114"]:
        raise ValueError("Unexpected activation ref")
    env = {"PATH": os.defpath, "LC_ALL": "C"}
    blocks, python_blocks = [], []
    for index, step in enumerate(job["steps"], 1):
        if "run" not in step:
            continue
        if step.get("shell") != "bash":
            raise ValueError("Unexpected shell")
        block = step["run"]
        if "$" + "{{" in block:
            raise ValueError("Expressions inside run blocks require separate expansion")
        path = ROOT / "syntax" / f"step-{index:02d}.sh"
        path.parent.mkdir(exist_ok=True)
        path.write_text(block)
        checked = subprocess.run(["bash", "--noprofile", "--norc", "-n", str(path)],
                                 env=env, capture_output=True, text=True)
        blocks.append({"step": index, "name": step["name"], "exit_code": checked.returncode,
                       "sha256": hashlib.sha256(block.encode()).hexdigest(),
                       "stdout": checked.stdout, "stderr": checked.stderr})
        if checked.returncode:
            raise ValueError("Bash syntax failed: " + step["name"])
        lines = block.splitlines(keepends=True)
        line = 0
        while line < len(lines):
            opening = lines[line].rstrip("\n")
            match = HEREDOC.fullmatch(opening)
            if not match:
                if "<<" in opening:
                    raise ValueError("Unreviewed heredoc form")
                line += 1
                continue
            line += 1
            body = []
            while line < len(lines) and lines[line].rstrip("\n") != match["delimiter"]:
                body.append(lines[line])
                line += 1
            if line == len(lines):
                raise ValueError("Unterminated heredoc")
            source = "".join(body)
            compiled = compile(ast.parse(source), "<publisher-heredoc>", "exec")
            del compiled
            if opening.startswith("cat "):
                if source != (ROOT / "verify_additional_acceptance.py").read_text():
                    raise ValueError("Embedded tested verifier differs")
            py_path = ROOT / "syntax" / f"python-{len(python_blocks) + 1:02d}.py"
            py_path.write_text(source)
            python_blocks.append({"step": index, "sha256": hashlib.sha256(source.encode()).hexdigest(),
                                  "parse": True, "compile": True, "executed": False})
            line += 1
    lint = subprocess.run([str(ACTIONLINT), str(WORKFLOW)], capture_output=True, text=True)
    (ROOT / "actionlint.original.log").write_text(lint.stdout + lint.stderr)
    if lint.returncode:
        raise ValueError("Actionlint failed: " + lint.stdout + lint.stderr)
    result = {
        "status": "PASS_STATIC_PREPARATION_ONLY",
        "accepted_host_source": job["env"]["SOURCE_SHA"],
        "acceptance_run": int(job["env"]["ACCEPTANCE_RUN"]),
        "workflow_git_blob": blob, "workflow_sha256": hashlib.sha256(data).hexdigest(),
        "workflow_bytes": len(data), "run_blocks": blocks, "python_heredocs": python_blocks,
        "actionlint": {"exit_code": lint.returncode, "binary_sha256": hashlib.sha256(ACTIONLINT.read_bytes()).hexdigest()},
        "yaml_duplicate_keys": False, "embedded_metadata_verifier_matches_tested_file": True,
        "workflow_commands_executed": False, "release_operations_executed": False,
        "new_full_host_acceptance": "PENDING",
    }
    (ROOT / "syntax-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"status": result["status"], "bash_blocks": len(blocks),
                      "python_heredocs": len(python_blocks), "actionlint_exit": lint.returncode,
                      "sha256": result["workflow_sha256"]}))

if __name__ == "__main__":
    main()
