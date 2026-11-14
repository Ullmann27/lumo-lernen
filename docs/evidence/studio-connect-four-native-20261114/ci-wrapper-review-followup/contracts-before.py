"""Actual subprocess/source-integrity counterexamples for the C4 CI runner.

These small synthetic process contracts are not game/Android acceptance.
"""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest


RUNNER = Path(__file__).resolve().parents[1] / "run_connect_four_runtime.py"
SPEC = importlib.util.spec_from_file_location("c4_runtime_gate", RUNNER)
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)


class SourceContracts(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "lib").mkdir()
        (self.root / "lib/game.dart").write_text("final moves = <int>[];\n")
        subprocess.run(["git", "-C", str(self.root), "add", "lib/game.dart"], check=True)
        subprocess.run(["git", "-C", str(self.root), "-c", "user.name=C4 gate test",
                        "-c", "user.email=c4-gate@example.invalid", "commit", "-qm", "synthetic fixture"], check=True)

    def test_exact_tracked_bytes_and_modes_are_bound(self):
        result = gate.source_snapshot(self.root, ("lib",))
        self.assertEqual(len(result["files"]), 1)
        self.assertEqual(result["files"][0]["path"], "lib/game.dart")
        self.assertEqual(result["files"][0]["mode"], "100644")
        self.assertEqual(len(result["files"][0]["sha256"]), 64)

    def test_generated_capture_does_not_hide_source_mutation(self):
        (self.root / "capture.png").write_bytes(b"synthetic unused capture")
        gate.source_snapshot(self.root, ("lib",))
        (self.root / "lib/game.dart").write_text("final moves = <int>[4];\n")
        with self.assertRaisesRegex(ValueError, "differs from exact HEAD"):
            gate.source_snapshot(self.root, ("lib",))

    def test_symlink_cannot_substitute_even_identical_source(self):
        target = self.root / "outside.dart"
        target.write_bytes((self.root / "lib/game.dart").read_bytes())
        (self.root / "lib/game.dart").unlink()
        (self.root / "lib/game.dart").symlink_to(target)
        with self.assertRaisesRegex(ValueError, "nonregular source"):
            gate.source_snapshot(self.root, ("lib",))

    def test_changed_executable_mode_is_rejected(self):
        (self.root / "lib/game.dart").chmod(0o755)
        with self.assertRaisesRegex(ValueError, "mode differs"):
            gate.source_snapshot(self.root, ("lib",))

    def test_empty_path_scope_cannot_claim_source_binding(self):
        with self.assertRaisesRegex(ValueError, "Empty source inventory"):
            gate.source_snapshot(self.root, ("absent",))


class ProcessContracts(unittest.TestCase):
    def child(self, code):
        child = subprocess.Popen([sys.executable, "-c", code], start_new_session=True,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(gate.stop_owned_process, child)
        return child

    def test_child_exiting_before_handshake_is_not_success(self):
        child = self.child("raise SystemExit(0)")
        child.wait(timeout=2)
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(RuntimeError, "before renderer handshake"):
                gate.wait_for_session(Path(tmp) / "session.json", child, 1)

    def test_malformed_session_is_rejected_without_waiting_for_timeout(self):
        child = self.child("import time;time.sleep(10)")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "session.json"
            path.write_text(json.dumps({"token": "wrong", "owner": "0" * 64, "roundId": "1" * 32}))
            with self.assertRaisesRegex(ValueError, "Malformed renderer handshake"):
                gate.wait_for_session(path, child, 1)

    def test_native_failure_is_observed_while_other_process_is_running(self):
        dart = self.child("import time;time.sleep(10)")
        native = self.child("raise SystemExit(7)")
        native.wait(timeout=2)
        start = time.monotonic()
        with self.assertRaisesRegex(RuntimeError, "Godot=7"):
            gate.wait_for_pair(dart, native, 5)
        self.assertLess(time.monotonic() - start, 1)
        self.assertIsNone(dart.poll())

    def test_hung_pair_is_bounded_and_owned_processes_are_terminated(self):
        dart = self.child("import time;time.sleep(10)")
        native = self.child("import time;time.sleep(10)")
        with self.assertRaisesRegex(TimeoutError, "bounded deadline"):
            gate.wait_for_pair(dart, native, 0.05)
        gate.stop_owned_process(native)
        gate.stop_owned_process(dart)
        self.assertIsNotNone(native.poll())
        self.assertIsNotNone(dart.poll())

    def test_two_actual_successful_processes_are_both_required(self):
        dart = self.child("raise SystemExit(0)")
        native = self.child("raise SystemExit(0)")
        gate.wait_for_pair(dart, native, 2)
        self.assertEqual((dart.returncode, native.returncode), (0, 0))

    def test_existing_evidence_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output = root / "evidence"
            output.mkdir()
            original = output / "original.log"
            original.write_bytes(b"preserved failed result")
            with self.assertRaisesRegex(ValueError, "Refusing to overwrite"):
                gate.run(root / "host", root / "native", output)
            self.assertEqual(original.read_bytes(), b"preserved failed result")


class ResultCounterexamples(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        saved = {"columns": gate.WIN_HISTORY, "rewarded": True,
                 "id": "1" * 32, "owner": "2" * 64}
        self.dart = {"passed": True, "round": saved, "reopened_same_round": True,
                     "single_player_human_and_bot_observed": True,
                     "stars": 5, "xp": 40}
        self.native = {"passed": True, "errors": [], "checks": 143,
                       "inputs": [{} for _ in range(14)],
                       "targets": [{"size_dp": [48, 48]} for _ in range(7)],
                       "final_state": {"columns": gate.WIN_HISTORY, "winningLine": gate.WIN_LINE,
                                       "phase": "won", "rewarded": True, "exit": True,
                                       "roundId": "1" * 32, "owner": "2" * 64,
                                       "token": "a" * 32}}

    def validate(self):
        gate.write_json(self.root / "dart-result.json", self.dart)
        gate.write_json(self.root / "native-result.json", self.native)
        gate.write_json(self.root / "done.json", {"finished": True})
        return gate.validate_results(self.root)

    def test_nan_target_cannot_be_counted_as_large_enough(self):
        self.native["targets"][0]["size_dp"][0] = float("nan")
        with self.assertRaisesRegex(ValueError, "smaller than48dp"):
            self.validate()

    def test_positive_labels_cannot_hide_a_missing_exit_ack(self):
        self.native["final_state"]["exit"] = False
        with self.assertRaisesRegex(ValueError, "exit disagree"):
            self.validate()

    def test_different_round_owner_cannot_be_accepted(self):
        self.native["final_state"]["owner"] = "3" * 64
        with self.assertRaisesRegex(ValueError, "ownership"):
            self.validate()

    def test_duplicate_reward_total_cannot_be_accepted(self):
        self.dart["stars"] = 10
        with self.assertRaisesRegex(ValueError, "reward"):
            self.validate()


if __name__ == "__main__":
    unittest.main()
