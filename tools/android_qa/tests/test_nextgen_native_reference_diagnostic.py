import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "native_reference_diagnostic",
    ROOT / ".github/probes/lumo_nextgen_native_reference_diagnostic.py")
diagnostic = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(diagnostic)


class ObservedRouteStub:
    """No Android/device claim: only the new starter's isolation is exercised."""

    def __init__(self, args, result, *, failure=False, api=35, absent=True):
        self.args, self.result = args, result
        self.calls, self.failure, self.api, self.absent = [], failure, api, absent

    def run(self):
        raise AssertionError("Diagnostic must never invoke acceptance ReferenceProbe.run")

    def reset_successful_original(self):
        raise AssertionError("Diagnostic must never manufacture/reset a successful original probe")

    def identify_and_install(self):
        self.calls.append("identify_and_install")
        self.result["device"] = {"api": self.api, "package_absent_before_install": self.absent}

    def onboard(self):
        self.calls.append("onboard")

    def configure_local_voice(self):
        self.calls.append("configure_local_voice")

    def banana(self):
        self.calls.append("banana")
        if self.failure:
            raise RuntimeError("Actual reference route failed")

    def pattern(self):
        self.calls.append("pattern")

    def preferences(self, tag):
        self.calls.append("preferences")
        return {}

    def capture(self, *args, **kwargs):
        self.calls.append("failure_capture")


class DiagnosticIsolationTests(unittest.TestCase):
    def test_direct_routes_do_not_call_original_acceptance_or_reset(self):
        result = diagnostic.diagnostic_result("a" * 40)
        probe = ObservedRouteStub(SimpleNamespace(), result)
        with patch.object(diagnostic.learning, "learning_snapshot", return_value={"profile": {"name": "fixture"}}):
            diagnostic.observe_routes(probe)
        self.assertEqual(probe.calls, ["identify_and_install", "onboard", "configure_local_voice", "banana", "pattern", "preferences"])
        self.assertEqual(result["status"], "DIAGNOSTIC_ONLY")
        self.assertFalse(result["original_probe_requirement_satisfied"])
        self.assertNotIn("previous_complete_probe", result)

    def test_wrong_api_or_not_fresh_device_blocks_routes(self):
        for api, absent in ((34, True), (35, False)):
            with self.subTest(api=api, absent=absent):
                probe = ObservedRouteStub(SimpleNamespace(), {}, api=api, absent=absent)
                with self.assertRaises(RuntimeError):
                    diagnostic.observe_routes(probe)
                self.assertEqual(probe.calls, ["identify_and_install"])

    def test_original_acceptance_gate_rejects_diagnostic_result(self):
        with self.assertRaisesRegex(RuntimeError, "Original probe has not passed"):
            diagnostic.reference.verify_original_success(diagnostic.diagnostic_result("b" * 40), {})

    def test_success_and_failure_remain_diagnostic_only(self):
        for failure in (False, True):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                out = Path(directory) / "out"
                made = []

                def factory(args, result):
                    probe = ObservedRouteStub(args, result, failure=failure)
                    made.append(probe)
                    return probe

                with patch.object(diagnostic, "prepare_candidate"), \
                     patch.object(diagnostic.shutil, "which", return_value="/usr/bin/ffprobe"), \
                     patch.object(diagnostic.reference, "ReferenceProbe", side_effect=factory), \
                     patch.object(diagnostic.learning, "learning_snapshot", return_value={"profile": {"name": "fixture"}}), \
                     contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                    code = diagnostic.main(["--candidate", directory, "--download-evidence", directory,
                                            "--out", str(out), "--qa-commit", "c" * 40])
                result = json.loads((out / "diagnostic-android-result.json").read_text())
                self.assertEqual(code, 1 if failure else 0)
                self.assertEqual(result["status"], "DIAGNOSTIC_ONLY")
                self.assertEqual(result["diagnostic_outcome"], "FAILED" if failure else "COMPLETED")
                self.assertIs(result["original_probe_requirement_satisfied"], False)
                self.assertIs(result["release_eligible"], False)
                self.assertNotIn("previous_complete_probe", result)
                self.assertFalse(made[0].args.submit_core_answer)
                self.assertFalse((out / "reference-android-result.json").exists())
                self.assertFalse((out / "learning-android-result.json").exists())


if __name__ == "__main__":
    unittest.main()
