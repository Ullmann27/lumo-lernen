"""Execute the actual C4 return workflow step with a fake Godot boundary.

Bash, Git, timeout, tee, grep, and Python are real subprocesses. Temporary
Git commits stand in for the pinned Native checkout; no game or Android
acceptance is claimed by these shell/source-integrity contracts.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/lumo-connect-four-2020.yml"
STEP = "Require acknowledged Connect Four return retry"
MARKER = "CONNECT_FOUR_RETURN_PASS checks=21"
PROTECTED = (
    "scripts/games/connect_four/connect_four_table.gd",
    "scripts/tests/connect_four_return_regression.gd",
)

FAKE_GODOT = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys

behavior = json.loads(Path(os.environ["LUMO_RETURN_FAKE_BEHAVIOR"]).read_text())
record = {
    "argv": sys.argv[1:],
    "cwd": os.getcwd(),
    "xdg": {key: os.environ.get(key) for key in
            ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME")},
}
Path(os.environ["LUMO_RETURN_FAKE_RECORD"]).write_text(json.dumps(record))
print("FAKE_GODOT: host shell contract; no engine executed", flush=True)
print(behavior.get("stdout", ""), end="", flush=True)
print(behavior.get("stderr", ""), end="", file=sys.stderr, flush=True)
mutation = behavior.get("mutation")
if mutation:
    native = Path(sys.argv[sys.argv.index("--path") + 1])
    path = native / mutation["path"]
    path.write_text(path.read_text() + "# changed by fake engine\n")
    if mutation.get("stage"):
        subprocess.run(["git", "-C", str(native), "add", "--", mutation["path"]],
                       check=True)
    if mutation.get("commit"):
        subprocess.run(["git", "-C", str(native), "commit", "-qm",
                        "fake engine source change"], check=True)
raise SystemExit(behavior.get("exit_code", 0))
'''


def actual_shell_step() -> str:
    source = WORKFLOW.read_text()
    heading = "      - name: " + STEP + "\n"
    if source.count(heading) != 1:
        raise AssertionError("Expected exactly one actual C4 return step")
    block = source.split(heading, 1)[1].split("\n      - ", 1)[0]
    run = "        run: |\n"
    if run not in block:
        raise AssertionError("The actual return step has no literal shell body")
    return textwrap.dedent(block.split(run, 1)[1]).rstrip() + "\n"


class Fixture:
    def __init__(self, case: unittest.TestCase):
        temporary = tempfile.TemporaryDirectory(prefix="lumo c4 return ")
        case.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.host = self.root / "host workspace"
        self.runner = self.root / "runner temporary"
        self.native = self.runner / "lumo-native-acceptance"
        self.logs = self.host / "acceptance-native"
        self.record = self.root / "fake-invocation.json"
        self.behavior = self.root / "fake-behavior.json"
        self.native.mkdir(parents=True)
        (self.host / "config").mkdir(parents=True)
        self.bin = self.root / "fake bin"
        self.bin.mkdir()
        (self.bin / "godot").write_text(FAKE_GODOT)
        (self.bin / "godot").chmod(0o755)
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith("GIT_")}
        self.env.update({
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_TERMINAL_PROMPT": "0",
            "GITHUB_WORKSPACE": str(self.host),
            "RUNNER_TEMP": str(self.runner),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "LUMO_RETURN_FAKE_BEHAVIOR": str(self.behavior),
            "LUMO_RETURN_FAKE_RECORD": str(self.record),
        })
        self.git("init", "-q")
        for key, value in (
            ("user.name", "C4 return shell fixture"),
            ("user.email", "c4-return@example.invalid"),
            ("commit.gpgsign", "false"),
            ("core.hooksPath", os.devnull),
        ):
            self.git("config", key, value)
        for relative in PROTECTED:
            path = self.native / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("# Synthetic tracked source for the shell guard.\n")
        self.git("add", "--", *PROTECTED)
        self.git("commit", "-qm", "synthetic pinned native fixture")
        self.revision = self.git("rev-parse", "HEAD").stdout.strip()
        self.write_pin(self.revision)

    def git(self, *arguments):
        return subprocess.run(
            ["git", "-C", str(self.native), *arguments], env=self.env,
            capture_output=True, text=True, check=True, timeout=10,
        )

    def write_pin(self, revision):
        (self.host / "config/godot-source.json").write_text(json.dumps({
            "repository": "https://example.invalid/synthetic-native.git",
            "revision": revision, "engine": "synthetic-not-executed",
        }))

    def change(self, relative, *, stage):
        path = self.native / relative
        path.write_text(path.read_text() + "# changed before the gate\n")
        if stage:
            self.git("add", "--", relative)


class ConnectFourReturnGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        for binary in ("bash", "git", "timeout", "tee", "grep", "python3"):
            if shutil.which(binary) is None:
                raise RuntimeError("Required real shell tool is missing: " + binary)
        cls.shell = actual_shell_step()

    def setUp(self):
        self.gate_executions = []

    def run_gate(self, fixture, **behavior):
        fixture.behavior.write_text(json.dumps({
            "stdout": MARKER + "\n", "stderr": "", "exit_code": 0, **behavior,
        }))
        self.assertEqual(shutil.which("godot", path=fixture.env["PATH"]),
                         str(fixture.bin / "godot"))
        before = fixture.git("rev-parse", "HEAD").stdout.strip()
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", "-c", self.shell],
            cwd=fixture.host, env=fixture.env, capture_output=True,
            text=True, timeout=15,
        )
        log = fixture.logs / "connect-four-return.log"
        self.gate_executions.append({
            "behavior": behavior,
            "shell_sha256": hashlib.sha256(self.shell.encode()).hexdigest(),
            "fixture_pin": fixture.revision,
            "native_head_before": before,
            "native_head_after": fixture.git("rev-parse", "HEAD").stdout.strip(),
            "returncode": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr,
            "original_gate_log": log.read_text() if log.exists() else None,
            "fake_invocation": (
                json.loads(fixture.record.read_text())
                if fixture.record.exists() else None
            ),
        })
        return result

    def assert_rejected(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_success_runs_exact_script_with_isolated_data_paths(self):
        fixture = Fixture(self)
        warning = "WARNING: synthetic optional renderer feature\n"
        result = self.run_gate(fixture, stderr=warning)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        invocation = json.loads(fixture.record.read_text())
        self.assertEqual(invocation["argv"], [
            "--headless", "--path", str(fixture.native),
            "--script", PROTECTED[1],
        ])
        self.assertEqual(invocation["cwd"], str(fixture.host))
        for variable, suffix in (
            ("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
            ("XDG_CACHE_HOME", "cache"),
        ):
            expected = fixture.logs / ("connect-four-return-user-" + suffix)
            self.assertEqual(invocation["xdg"][variable], str(expected))
            self.assertTrue(expected.is_dir())
        log = (fixture.logs / "connect-four-return.log").read_text()
        self.assertEqual(log.splitlines().count(MARKER), 1)
        self.assertIn(warning, log)
        self.assertEqual(fixture.git("status", "--porcelain").stdout, "")

    def test_missing_marker_cannot_reuse_an_old_successful_log(self):
        fixture = Fixture(self)
        fixture.logs.mkdir()
        log = fixture.logs / "connect-four-return.log"
        log.write_text(MARKER + "\n")
        result = self.run_gate(fixture, stdout="completed without a success marker\n")
        self.assert_rejected(result)
        self.assertTrue(fixture.record.exists())
        self.assertNotIn(MARKER, log.read_text())

    def test_wrong_marker_is_rejected(self):
        for marker in (
            "CONNECT_FOUR_RETURN_PASS checks=20",
            "CONNECT_FOUR_RETURN_PASS checks=210",
            "prefix " + MARKER,
            "CONNECT_FOUR_RETURN_FAIL checks=21",
        ):
            with self.subTest(marker=marker):
                self.assert_rejected(self.run_gate(Fixture(self), stdout=marker + "\n"))

    def test_duplicate_success_marker_is_rejected(self):
        result = self.run_gate(Fixture(self), stdout=(MARKER + "\n") * 2)
        self.assert_rejected(result)

    def test_engine_error_after_success_on_stderr_is_rejected(self):
        for error in ("ERROR: synthetic failure", "SCRIPT ERROR: synthetic failure",
                      "Parse Error: synthetic failure"):
            with self.subTest(error=error):
                result = self.run_gate(Fixture(self), stderr=error + "\n")
                self.assert_rejected(result)
                self.assertIn(MARKER, self.gate_executions[-1]["original_gate_log"])
                self.assertIn(error, self.gate_executions[-1]["original_gate_log"])

    def test_nonzero_engine_exit_is_rejected_despite_success_marker(self):
        result = self.run_gate(Fixture(self), exit_code=7)
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertIn(MARKER, self.gate_executions[-1]["original_gate_log"])

    def test_wrong_pin_or_wrong_head_stops_before_engine(self):
        for mismatch in ("pin", "head"):
            with self.subTest(mismatch=mismatch):
                fixture = Fixture(self)
                if mismatch == "pin":
                    fixture.write_pin("0" * 40)
                else:
                    fixture.git("commit", "--allow-empty", "-qm", "different native head")
                self.assert_rejected(self.run_gate(fixture))
                self.assertFalse(fixture.record.exists())

    def test_staged_and_unstaged_source_changes_stop_before_engine(self):
        for relative in PROTECTED:
            for stage in (False, True):
                with self.subTest(path=relative, staged=stage):
                    fixture = Fixture(self)
                    fixture.change(relative, stage=stage)
                    self.assert_rejected(self.run_gate(fixture))
                    self.assertFalse(fixture.record.exists())

    def test_staged_and_unstaged_changes_during_engine_are_rejected(self):
        for relative in PROTECTED:
            for stage in (False, True):
                with self.subTest(path=relative, staged=stage):
                    fixture = Fixture(self)
                    result = self.run_gate(fixture, mutation={"path": relative, "stage": stage})
                    self.assertTrue(fixture.record.exists())
                    self.assert_rejected(result)

    def test_new_clean_commit_during_engine_is_not_the_pinned_source(self):
        fixture = Fixture(self)
        result = self.run_gate(fixture, mutation={
            "path": PROTECTED[0], "stage": True, "commit": True,
        })
        self.assertNotEqual(fixture.git("rev-parse", "HEAD").stdout.strip(),
                            fixture.revision)
        self.assertEqual(fixture.git("status", "--porcelain").stdout, "")
        self.assert_rejected(result)

    def test_success_cannot_hide_a_contradictory_return_marker(self):
        for contradictory in (
            "CONNECT_FOUR_RETURN_FAIL checks=21",
            "CONNECT_FOUR_RETURN_PASS checks=20",
        ):
            with self.subTest(contradictory=contradictory):
                result = self.run_gate(
                    Fixture(self), stdout=MARKER + "\n" + contradictory + "\n",
                )
                self.assert_rejected(result)


if __name__ == "__main__":
    unittest.main()
