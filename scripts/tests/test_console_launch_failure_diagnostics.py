"""Failure-only collection contracts, not an emulator/console success claim.

The three terminal transcripts are byte-original PR483 observations. Local
Python children explicitly simulate adb output only to test collection limits,
original-byte retention, errors and unchanged failure propagation.
"""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shlex
import sys
import tempfile
import time
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("console_failure_diagnostics", ROOT / "scripts/android_framework_ready.py")
FRAMEWORK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(FRAMEWORK)
FIXTURES = ROOT / "scripts/tests/fixtures/console_launch_pr483"
TOKEN = "a" * 32


class ConsoleFailureDiagnosticsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="console-failure-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.fake_adb = self.root / "synthetic-adb"
        self.fake_adb.write_text("#!" + sys.executable + "\nimport os,sys\nos.write(1,b'original-out\\x00\\xff')\nos.write(2,b'original-err\\x00\\xfe')\nsys.exit(7)\n")
        self.fake_adb.chmod(0o700)

    def session(self, name="start"):
        return FRAMEWORK.DeviceLogSession(self.root / name, str(self.fake_adb),
                                         "emulator-5554", "/data/local/tmp/lumo-runtime-" + TOKEN)

    def test_original_exit1_is_unchanged_after_all_failure_only_reads(self):
        for case in ("host", "swiftshader", "swangle"):
            with self.subTest(original=case):
                folder = FIXTURES / case
                token = json.loads((folder / "config.json").read_bytes())["token"]
                original = (folder / "transcript.stdout").read_bytes()
                try:
                    FRAMEWORK.CONSOLE.launch_frame(original, token)
                except ValueError as caught:
                    launch_error = caught
                else:
                    self.fail("Actual original Exit1 must be rejected")
                out = self.root / case
                with mock.patch.object(FRAMEWORK, "adb_path", return_value=str(self.fake_adb)), \
                     mock.patch.object(FRAMEWORK.secrets, "token_hex", return_value=token), \
                     mock.patch.object(FRAMEWORK.CONSOLE, "start", side_effect=launch_error), \
                     mock.patch.object(FRAMEWORK.DeviceLogSession, "snapshot") as snapshot:
                    with self.assertRaises(ValueError) as raised:
                        FRAMEWORK.start_device_log(out, self.root / "framework", "emulator-5554")
                self.assertIs(raised.exception, launch_error)
                snapshot.assert_not_called()
                result = json.loads((out / "start.json").read_bytes())
                self.assertEqual(result["status"], "FAIL")
                self.assertEqual(result["errors"], ["ValueError: " + str(launch_error)])
                self.assertNotIn("root", result)
                diagnostic = result["launch_failure_diagnostics"]
                self.assertEqual(diagnostic["status"], "DIAGNOSTIC_ONLY")
                self.assertEqual(diagnostic["remote"], result["remote"])
                self.assertEqual(len(diagnostic["commands"]), 6)
                for row in diagnostic["commands"]:
                    self.assertEqual(row["returncode"], 7)
                    self.assertTrue(row["output_complete"])
                    self.assertEqual(row["command"][:4], [str(self.fake_adb), "-s", "emulator-5554", "shell"])
                    script = shlex.split(row["command"][-1])[0]
                    self.assertIn(result["remote"], script)
                    for mutation in ("mkdir ", " kill ", " root ", " logcat ", " > ", "rm "):
                        self.assertNotIn(mutation, script)
                    for stream, expected in (("stdout", b"original-out\x00\xff"), ("stderr", b"original-err\x00\xfe")):
                        self.assertEqual((out / diagnostic["path"] / row[stream + "_file"]).read_bytes(), expected)

    def test_local_child_nonzero_output_and_both_streams_are_byte_original(self):
        out = self.root / "command"
        out.mkdir()
        record = FRAMEWORK._launch_failure_read(out, "nonzero", [str(self.fake_adb)], time.monotonic() + 2, 1024)
        self.assertEqual(record["returncode"], 7)
        self.assertTrue(record["output_complete"])
        self.assertFalse(record["timed_out"])
        self.assertEqual((out / "nonzero.stdout").read_bytes(), b"original-out\x00\xff")
        self.assertEqual((out / "nonzero.stderr").read_bytes(), b"original-err\x00\xfe")
        self.assertEqual(json.loads((out / "nonzero.json").read_bytes()), record)

    def test_byte_limit_stores_only_original_prefix_and_never_a_complete_claim(self):
        out = self.root / "limited"
        out.mkdir()
        record = FRAMEWORK._launch_failure_read(out, "limited", [sys.executable, "-c", "import os;os.write(1,b'x'*65536)"], time.monotonic() + 2, 80)
        self.assertTrue(record["byte_limit_exceeded"])
        self.assertFalse(record["output_complete"])
        self.assertEqual((out / "limited.stdout").read_bytes(), b"x" * 80)
        self.assertEqual(sum(item["bytes"] for item in record["files"].values()), 80)

    def test_timeout_preserves_available_bytes_and_actual_killed_returncode(self):
        out = self.root / "timeout"
        out.mkdir()
        with mock.patch.object(FRAMEWORK, "LAUNCH_FAILURE_COMMAND_SECONDS", .15):
            record = FRAMEWORK._launch_failure_read(out, "timeout", [sys.executable, "-c", "import os,time;os.write(1,b'early-out');os.write(2,b'early-err');time.sleep(5)"], time.monotonic() + 1, 1024)
        self.assertTrue(record["timed_out"])
        self.assertFalse(record["output_complete"])
        self.assertEqual(record["returncode"], -9)
        self.assertEqual((out / "timeout.stdout").read_bytes(), b"early-out")
        self.assertEqual((out / "timeout.stderr").read_bytes(), b"early-err")

    def test_aggregate_byte_budget_stops_remaining_fixed_reads(self):
        session = self.session()
        with mock.patch.object(FRAMEWORK, "LAUNCH_FAILURE_COMMAND_BYTES", 20), \
             mock.patch.object(FRAMEWORK, "LAUNCH_FAILURE_TOTAL_BYTES", 60):
            report = FRAMEWORK.collect_launch_failure(session)
        self.assertEqual(report["raw_bytes"], 60)
        self.assertEqual(len(report["commands"]), 3)
        self.assertFalse(report["all_commands_attempted"])
        self.assertTrue(report["errors"])
        self.assertTrue(all(row["byte_limit_exceeded"] for row in report["commands"]))

    def test_global_deadline_stops_further_commands_without_extending_launch(self):
        self.fake_adb.write_text("#!" + sys.executable + "\nimport os,time\nos.write(1,b'early');time.sleep(5)\n")
        with mock.patch.object(FRAMEWORK, "LAUNCH_FAILURE_SECONDS", .3):
            report = FRAMEWORK.collect_launch_failure(self.session())
        self.assertEqual(len(report["commands"]), 1)
        self.assertTrue(report["commands"][0]["timed_out"])
        self.assertFalse(report["all_commands_attempted"])
        self.assertLess(report["elapsed_seconds"], 1)

    def test_spawn_and_collection_errors_cannot_replace_the_original_failure(self):
        self.fake_adb.unlink()
        report = FRAMEWORK.collect_launch_failure(self.session())
        self.assertEqual(len(report["commands"]), 6)
        for row in report["commands"]:
            self.assertIsNone(row["returncode"])
            self.assertFalse(row["output_complete"])
            self.assertTrue(row["errors"])
            self.assertEqual(sum(item["bytes"] for item in row["files"].values()), 0)
        failure = RuntimeError("actual original console failure")
        out = self.root / "failed-collection"
        with mock.patch.object(FRAMEWORK, "adb_path", return_value=str(self.fake_adb)), \
             mock.patch.object(FRAMEWORK.CONSOLE, "start", side_effect=failure), \
             mock.patch.object(FRAMEWORK, "collect_launch_failure", side_effect=OSError("diagnostic storage unavailable")):
            with self.assertRaises(RuntimeError) as raised:
                FRAMEWORK.start_device_log(out, self.root / "framework", "emulator-5554")
        self.assertIs(raised.exception, failure)
        result = json.loads((out / "start.json").read_bytes())
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["launch_failure_diagnostics"]["status"], "INCOMPLETE")
        self.assertIn("diagnostic storage unavailable", result["launch_failure_diagnostics"]["error"])

    def test_later_strict_launch_output_failure_does_not_trigger_extra_reads(self):
        with mock.patch.object(FRAMEWORK, "adb_path", return_value=str(self.fake_adb)), \
             mock.patch.object(FRAMEWORK.CONSOLE, "start", return_value={"synthetic_boundary_only": True}), \
             mock.patch.object(FRAMEWORK.DeviceLogSession, "run", return_value={"stdout": "unexpected actual output"}), \
             mock.patch.object(FRAMEWORK, "collect_launch_failure") as collection:
            with self.assertRaisesRegex(ValueError, "emitted output or errors"):
                FRAMEWORK.start_device_log(self.root / "later", self.root / "framework", "emulator-5554")
        collection.assert_not_called()

    def test_invalid_binding_and_existing_originals_are_not_read_or_replaced(self):
        session = self.session()
        session.remote = "/data/local/tmp/lumo-runtime-" + TOKEN + "/../foreign"
        with mock.patch.object(FRAMEWORK.subprocess, "Popen") as process:
            with self.assertRaises(ValueError):
                FRAMEWORK.collect_launch_failure(session)
        process.assert_not_called()
        session.remote = "/data/local/tmp/lumo-runtime-" + TOKEN
        folder = session.out / "launch-failure"
        folder.mkdir()
        sentinel = folder / "original"
        sentinel.write_bytes(b"unchanged")
        with self.assertRaises(FileExistsError):
            FRAMEWORK.collect_launch_failure(session)
        self.assertEqual(sentinel.read_bytes(), b"unchanged")
        (folder / "retained.stdout").write_bytes(b"retained")
        with mock.patch.object(FRAMEWORK.subprocess, "Popen") as process:
            with self.assertRaises(ValueError):
                FRAMEWORK._launch_failure_read(folder, "retained", [str(self.fake_adb)], time.monotonic() + 1, 1024)
        process.assert_not_called()
        self.assertEqual((folder / "retained.stdout").read_bytes(), b"retained")


if __name__ == "__main__":
    unittest.main()
