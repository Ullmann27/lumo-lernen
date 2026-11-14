"""Actual 7b16 window captures and explicitly synthetic InputDispatcher cases.

The failed job did not capture dumpsys input. Supplementary dispatcher states
below follow the AOSP dump contract; they are not Android acceptance evidence.
The original GMS broadcast ANR remains a terminal failure in every replay.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "framework_existing_contracts", ROOT / "scripts/tests/test_android_framework_ready.py"
)
EXISTING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EXISTING)
READY = EXISTING.READY
FIXTURES = ROOT / "scripts/tests/fixtures/android37_window_7b16"

# Explicitly synthetic supplementary input, not a member of the failed CI ZIP.
# AOSP InputDispatcher.cpp, blob 4c1dffaf2c3598b25f3d485fd48c96a0de7c98ea:
# dump() emits the current section; dumpDispatchStateLocked() emits these booleans.
SYNTHETIC_INPUT_READY = """Input Manager State:
  UnrelatedField: true
Input Dispatcher State:
  DispatchEnabled: true
  DispatchFrozen: false
  InputFilterEnabled: false
  FocusedDisplayId: 0
"""
SAMPLES = (("0014", "0015"), ("0028", "0029"), ("0042", "0043"), ("0056", "0057"))


class ActualAndroid17WindowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads((FIXTURES / "manifest.json").read_text())
        if manifest["host_sha"] != "7b16f2f5ab16f3d913ee170aefd9807c87216260":
            raise AssertionError("Unexpected original source")
        if manifest["artifact_id"] != 14093659058:
            raise AssertionError("Unexpected original artifact")
        for item in manifest["files"]:
            content = (FIXTURES / item["path"]).read_bytes()
            if len(content) != item["bytes"] or hashlib.sha256(content).hexdigest() != item["sha256"]:
                raise AssertionError(f"Changed original fixture: {item['path']}")

    def original(self, prefix, kind):
        return (FIXTURES / f"{prefix}-{kind}.stdout").read_text()

    def test_four_original_windows_recognize_actual_fields_but_need_dispatch_observation(self):
        for window, events in SAMPLES:
            with self.subTest(window=window):
                result = READY.interactive_surface(
                    self.original(window, "window-state"), self.original(events, "events-anr")
                )
                self.assertFalse(result["ready"])
                self.assertEqual(result["errors"], ["display_dispatch_not_observed_unfrozen"])
                self.assertEqual(result["keyguard"]["systemReady"], "true")
                self.assertNotIn("secure", result["keyguard"])
                self.assertFalse(result["unlock_eligible"])
                self.assertFalse(result["anr_observed"])

    def test_original_unlocked_windows_with_synthetic_positive_dispatch_are_parseable(self):
        for window, events in SAMPLES:
            with self.subTest(window=window):
                result = READY.interactive_surface(
                    self.original(window, "window-state"), self.original(events, "events-anr"),
                    SYNTHETIC_INPUT_READY,
                )
                self.assertTrue(result["ready"], result["errors"])
                self.assertFalse(result["unlock_eligible"])
                self.assertIsNone(result["credential_secure"])
                self.assertEqual(result["input_dispatch"]["enabled"], "true")
                self.assertEqual(result["input_dispatch"]["frozen"], "false")

    def test_actual_gms_broadcast_anr_is_terminal_with_positive_dispatch(self):
        events = self.original("0071", "events-anr")
        self.assertIn("com.google.android.gms.persistent", events)
        self.assertIn("SIM_STATE_CHANGED", events)
        result = READY.interactive_surface(
            self.original("0070", "window-state"), events, SYNTHETIC_INPUT_READY
        )
        self.assertFalse(result["ready"])
        self.assertTrue(result["anr_observed"])
        self.assertIn("android_anr_or_error_window_observed", result["errors"])
        self.assertFalse(result["unlock_eligible"])

    def test_missing_or_ambiguous_dispatch_fields_cannot_replace_positive_observation(self):
        inputs = {
            "missing": "",
            "unknown": SYNTHETIC_INPUT_READY.replace("DispatchFrozen: false", "DispatchFrozen: unknown"),
            "frozen": SYNTHETIC_INPUT_READY.replace("DispatchFrozen: false", "DispatchFrozen: true"),
            "disabled": SYNTHETIC_INPUT_READY.replace("DispatchEnabled: true", "DispatchEnabled: false"),
            "duplicate_field": SYNTHETIC_INPUT_READY + "  DispatchFrozen: false\n",
            "duplicate_section": SYNTHETIC_INPUT_READY + SYNTHETIC_INPUT_READY,
            "fields_outside_section": "DispatchEnabled: true\nDispatchFrozen: false\n",
            "missing_enabled": SYNTHETIC_INPUT_READY.replace("  DispatchEnabled: true\n", ""),
        }
        for label, input_dump in inputs.items():
            with self.subTest(label=label):
                result = READY.interactive_surface(
                    self.original("0014", "window-state"), self.original("0015", "events-anr"),
                    input_dump,
                )
                self.assertFalse(result["ready"])
                self.assertIn("display_dispatch_not_observed_unfrozen", result["errors"])
                self.assertFalse(result["unlock_eligible"])

    def test_historical_input_anr_section_never_supplies_current_dispatch_or_hides_anr(self):
        history = "\nInput Dispatcher State at time of last ANR:\n  DispatchEnabled: true\n  DispatchFrozen: false\n"
        for input_dump in (history, SYNTHETIC_INPUT_READY + history):
            with self.subTest(current_present=input_dump.startswith("Input Manager")):
                result = READY.interactive_surface(
                    self.original("0014", "window-state"), self.original("0015", "events-anr"),
                    input_dump,
                )
                self.assertFalse(result["ready"])
                self.assertTrue(result["anr_observed"])
                self.assertFalse(result["unlock_eligible"])

    def test_explicit_window_freeze_cannot_be_overridden_by_input_boolean(self):
        for tail in ("\n  mDisplayFrozen=true\n", "\n  mInputFreezeReason=resize\n",
                     "\n  mDisplayFrozen=false\n  mDisplayFrozen=true\n"):
            with self.subTest(tail=tail):
                result = READY.interactive_surface(
                    self.original("0014", "window-state") + tail,
                    self.original("0015", "events-anr"), SYNTHETIC_INPUT_READY,
                )
                self.assertFalse(result["ready"])
                self.assertIn("display_dispatch_not_observed_unfrozen", result["errors"])

    def test_legacy_and_current_system_ready_aliases_cannot_conflict_or_be_unknown(self):
        window = self.original("0014", "window-state")
        for replacement in ("systemReady=false", "systemReady=unknown", "unrecognizedReady=true",
                            "systemReady=true\n      systemIsReady=false",
                            "systemReady=true\n      systemReady=true"):
            with self.subTest(replacement=replacement):
                result = READY.interactive_surface(
                    window.replace("systemReady=true", replacement),
                    self.original("0015", "events-anr"), SYNTHETIC_INPUT_READY,
                )
                self.assertFalse(result["ready"])
                self.assertFalse(result["unlock_eligible"])

    def test_missing_credential_security_never_borrows_sim_state_for_unlock(self):
        window = self.original("0014", "window-state")
        locked = window.replace("      showing=false", "      showing=true").replace(
            "      inputRestricted=false", "      inputRestricted=true"
        )
        self.assertIn("      simSecure=false", locked)
        for value in (locked, locked.replace("simSecure=false", "simSecure=true")):
            result = READY.interactive_surface(value, self.original("0015", "events-anr"),
                                               SYNTHETIC_INPUT_READY)
            self.assertFalse(result["ready"])
            self.assertFalse(result["unlock_eligible"])
            self.assertIsNone(result["credential_secure"])

    def test_present_malformed_credential_security_fails_closed(self):
        result = READY.interactive_surface(
            self.original("0014", "window-state").replace("      simSecure=false", "      secure=unknown"),
            self.original("0015", "events-anr"), SYNTHETIC_INPUT_READY,
        )
        self.assertFalse(result["ready"])
        self.assertFalse(result["unlock_eligible"])

    def test_real_observer_records_new_read_only_input_command(self):
        clock = EXISTING.Clock()
        recorder = EXISTING.SyntheticRecorder(clock, [{}])
        result = READY.observe(recorder, 10, clock.now)
        self.assertTrue(result["ready"], result["errors"])
        calls = [item for item in recorder.commands if item[0] == "input-state"]
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][1], ["dumpsys", "input"])
        self.assertLessEqual(calls[0][2], 5)
        self.assertIn("input-state", result["command_records"])

    def test_failed_or_timed_out_input_command_is_not_readiness(self):
        for sample in ({"input_failure": True}, {"timeout_command": "input-state"},
                       {"input_dump": ""}, {"input_frozen": True}, {"input_disabled": True}):
            with self.subTest(sample=sample):
                clock = EXISTING.Clock()
                recorder = EXISTING.SyntheticRecorder(clock, [sample])
                result = READY.poll_framework(recorder, 14, 10, 3, 2, clock.now, clock.sleep)
                self.assertEqual(result["status"], "FAIL")
                self.assertLessEqual(result["elapsed_seconds"], 14.000001)
                self.assertFalse(result["unlock_action"]["attempted"])


if __name__ == "__main__":
    unittest.main()
