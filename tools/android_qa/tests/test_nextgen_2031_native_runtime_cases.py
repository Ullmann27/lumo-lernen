"""Small host checks; historical raw fixtures and simulated timing are separate.

These tests do not execute an Android tour or certify audible speed/stop quality.
"""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("native_runtime_cases_under_test",
    ROOT / ".github/probes/lumo_nextgen_2031_native_runtime_cases.py")
cases = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cases)
FIXTURE = Path(__file__).parent / "fixtures/nextgen_native_runtime_2031"


def start(turn=21, pid=4999, profile=cases.PROFILE):
    return f"I/LumoLearningSpeech( {pid}): started id={turn} profile={profile}\n"


def complete(turn=21, pid=4999):
    return f"I/LumoLearningSpeech( {pid}): completed id={turn}\n"


class PlaybackWindowTest(unittest.TestCase):
    def test_original_inflight_and_completed_logs_are_not_interchangeable(self):
        manifest = json.loads((FIXTURE / "manifest.json").read_text())
        for name, record in manifest["files"].items():
            raw = (FIXTURE / name).read_bytes()
            self.assertEqual(len(raw), record["bytes"])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), record["sha256"])
        active = (FIXTURE / "0143-native-speech.txt").read_text()
        finished = (FIXTURE / "0148-native-speech.txt").read_text()
        self.assertEqual(cases.active_playback(active, 4999, ())["utterance_id"], 3)
        self.assertIsNone(cases.active_playback(active, 5000, ()))
        self.assertIsNone(cases.active_playback(active, 4999, {3}))
        with self.assertRaisesRegex(RuntimeError, "completed or changed"):
            cases.active_playback(finished, 4999, ())

    def test_wrong_profile_old_id_duplicate_and_premature_completion_fail_closed(self):
        for log, old in ((start(profile="other-profile"), {7}),
                         (start(6), {7}), (start() + start(), {7}),
                         (start() + complete(), {7}), (complete(), {7}),
                         (start() + start(22), {7})):
            with self.subTest(log=log, old=old), self.assertRaises(RuntimeError):
                cases.active_playback(log, 4999, old)
        self.assertIsNone(cases.active_playback(start(pid=123), 4999, {7}))
        self.assertIsNone(cases.active_playback(start(7) + complete(7), 4999, {7}))

    def test_stopped_window_rejects_later_segment_completion_or_lost_start(self):
        baseline = start(7) + complete(7) + start()
        cases.verify_stopped_window(baseline, 4999, {7}, 21)
        for log in (baseline + start(22), baseline + complete(), "", start(pid=123), start(profile="other")):
            with self.subTest(log=log), self.assertRaises(RuntimeError):
                cases.verify_stopped_window(log, 4999, {7}, 21)

    def test_current_explicit_host_failure_is_not_inflight_or_a_successful_stop(self):
        failure = 'I/LumoLearningSpeech( 4999): failed {"id":21,"generation":9,"phase":"media_playback","code":"media_error"}\n'
        with self.assertRaisesRegex(RuntimeError, "explicit failure"):
            cases.active_playback(start() + failure, 4999, {7})
        with self.assertRaisesRegex(RuntimeError, "explicit failure"):
            cases.verify_stopped_window(start() + failure, 4999, {7}, 21)
        self.assertIsNotNone(cases.active_playback(start() + failure.replace('"id":21', '"id":7'), 4999, {7}))
        self.assertIsNotNone(cases.active_playback(start() + failure.replace('4999', '1234'), 4999, {7}))


class VisibleControlTest(unittest.TestCase):
    def test_labels_match_original_android_ocr_and_pinned_native_contract(self):
        contract = json.loads((FIXTURE / "source-contract.json").read_text())
        self.assertEqual(contract["labels"], {"slower": cases.SLOWER, "stop": cases.STOP, "idle": cases.IDLE})
        rows = json.loads((FIXTURE / "0149-native-move-one-0-ocr.json").read_text())
        self.assertIn(cases.STOP, {row["text"] for row in rows})
        rows = json.loads((FIXTURE / "0116-native-title-3-ocr.json").read_text())
        self.assertIn(cases.IDLE, {row["text"] for row in rows})
        panel = next(item for item in contract["contracts"] if item["path"].endswith("learning_conversation_panel.gd"))
        self.assertEqual(panel["commit"], cases.NATIVE)
        self.assertTrue(any('"Langsamer", func(): requested.emit("", "slower")' in row["text"]
                            for row in panel["exact_source_lines"]))

    def test_slower_requires_its_current_panel_and_shortcut_neighbor(self):
        # Constructed geometry counterexamples; never saved as Android captures.
        panel = (10, 20, 400, 500)
        rows = [{"text": "Langsamer", "bounds": [30, 300, 130, 330]},
                {"text": "Ein Hinweis", "bounds": [150, 300, 250, 330]},
                {"text": "Langsamer", "bounds": [30, 700, 130, 730]}]
        self.assertEqual(cases.slower_target(rows, panel), (30, 300, 130, 330))
        self.assertIsNone(cases.slower_target(rows[:1], panel))
        self.assertIsNone(cases.slower_target(rows[1:], panel))
        wrong = [{**rows[0], "text": "Bitte langsamer sprechen"}, rows[1]]
        self.assertIsNone(cases.slower_target(wrong, panel))
        with self.assertRaisesRegex(RuntimeError, "Ambiguous"):
            cases.slower_target(rows + [{"text": "Langsamer", "bounds": [30, 400, 130, 430]}], panel)

    def test_actual_video_gate_stays_positive_and_bounded(self):
        value = {"duration_seconds": 1.5, "whole_block_within_recording_limit": True}
        self.assertEqual(cases.retained_video(SimpleNamespace(recordings=[value])), value)
        for value in ({"duration_seconds": 0, "whole_block_within_recording_limit": True},
                      {"duration_seconds": 1.5, "whole_block_within_recording_limit": False}):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                cases.retained_video(SimpleNamespace(recordings=[value]))


class Clock:
    def __init__(self):
        self.now = 0.0

    def monotonic(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


class SimulatedProbe:
    """Explicit fake ADB/clock boundary, never an Android success fixture."""
    def __init__(self, clock, mode="success"):
        self.clock, self.mode = clock, mode
        self.counter, self.reads = 0, 0
        self.inputs, self.saved = [], {}
        self.base = SimpleNamespace(adb=self.adb)

    def fresh(self, label):
        self.counter += 1
        return f"{self.counter:04d}-{label}"

    def save(self, name, value):
        self.saved[name] = copy.deepcopy(value)

    def adb(self, *args, **kwargs):
        self.clock.sleep(.05)
        if args[1] == "pidof":
            return "5000" if self.mode == "wrong-pid" else "4999"
        if args[1:3] == ("input", "swipe"):
            self.inputs.append(args)
            return ""
        raise AssertionError("Unexpected UI action: " + repr(args))

    def speech_log(self, **kwargs):
        self.reads += 1
        self.clock.sleep(.1)
        value = start(7) + complete(7) + start()
        if self.mode == "completion-before-touch" and self.reads >= 4:
            value += complete()
        if self.inputs and self.mode == "late-segment":
            value += start(22)
        if self.inputs and self.mode == "completion-after-touch":
            value += complete()
        return value


class DirectStopTimingTest(unittest.TestCase):
    def execute(self, mode="success"):
        clock = Clock()
        probe = SimulatedProbe(clock, mode)

        def target(_probe, label, deadline, guard=lambda: None):
            guard()
            clock.sleep(.2)
            guard()
            if mode == "late-target":
                clock.sleep(46)
            return {"label": label, "bounds": [100, 200, 400, 240], "capture": {"file": "synthetic-host-only"},
                    "source_sha256": "0" * 64, "stable_observed_target": True}

        with patch.object(cases.time, "monotonic", clock.monotonic), patch.object(cases.time, "sleep", clock.sleep), \
                patch.object(cases, "observed_voice_target", target):
            try:
                result = cases.stop_active_playback(probe, 4999, {7})
                return probe, result, None
            except RuntimeError as error:
                return probe, None, error

    def test_exactly_one_direct_input_and_five_seconds_without_new_events(self):
        probe, result, error = self.execute()
        self.assertIsNone(error)
        self.assertEqual(result["status"], "PASS_WITH_LIMITATIONS")
        self.assertEqual(len(probe.inputs), 1)
        self.assertEqual(result["stop_touch"]["label"], "Stimme stoppen")
        self.assertEqual(result["returned_voice_control"]["label"], "Schritt anhören")
        self.assertGreaterEqual(result["observation_seconds"], 5)
        self.assertFalse(result["question_menu_opened_during_active_window"])
        self.assertFalse(result["stop_event_available_in_host_log"])
        self.assertFalse(result["mouth_gesture_stop_verified"])

    def test_fresh_completion_or_expired_target_prevents_any_input(self):
        for mode in ("wrong-pid", "completion-before-touch", "late-target"):
            with self.subTest(mode=mode):
                probe, result, error = self.execute(mode)
                self.assertIsNotNone(error)
                self.assertIsNone(result)
                self.assertEqual(probe.inputs, [])
                self.assertEqual(next(iter(probe.saved.values()))["status"], "FAIL")

    def test_unexpected_after_stop_segment_or_completion_remains_failure(self):
        for mode in ("late-segment", "completion-after-touch"):
            with self.subTest(mode=mode):
                probe, result, error = self.execute(mode)
                self.assertIsNotNone(error)
                self.assertIsNone(result)
                self.assertEqual(len(probe.inputs), 1)
                self.assertEqual(next(iter(probe.saved.values()))["status"], "FAIL")


def synthetic_result():
    """Gate input only; never written into a captured Android evidence directory."""
    candidate = {"sha256": cases.APK_SHA, "flutter_source_commit": cases.SOURCE, "versionCode": 2031,
        "versionName": "0.13.19", "package": cases.learning.PACKAGE, "signingCertificateSha256": cases.reference.CERTIFICATE,
        "godot": {"revision": cases.NATIVE, "pck_sha256": cases.PCK_SHA}}
    common = {"status": "PASS_WITH_LIMITATIONS", "native_answer_submitted": False,
        "preservation": {"profile_id": "synthetic-fixture", "same_task_checkpoint": True},
        "video": {"file": "synthetic.mp4", "duration_seconds": 1.5, "sha256": "0" * 64,
                  "whole_block_within_recording_limit": True},
        "before_screenshot": {"file": "synthetic-before.png"}, "after_screenshot": {"file": "synthetic-after.png"},
        "returned_to_academy": {"file": "synthetic-academy.png"}}
    banana_model = {"kind": "syllables", "word": "Banane", "placed": 0, "total": 3, "visible_label": "0 / 3 bewegt"}
    bridge_model = {"kind": "bridge_ten", "a": 8, "b": 5, "placed": 2, "visible_label": "2 / 5 bewegt"}
    banana = {**copy.deepcopy(common), "current_task": cases.reference.BANANA_TITLE,
        "model_before": banana_model, "model_after": dict(banana_model), "action": "slower", "control": "Frag Lumo / Langsamer",
        "segment_order_source_contract": ["Banane", "Ba", "na", "ne"], "previous_ids": [1],
        "playback": {"pid": 4999, "profile": cases.PROFILE, "segments": 4, "utterance_ids": [3, 4, 5, 6]},
        "actual_rate_in_log": False, "acoustic_speed_verified": False, "segment_words_verified_acoustically": False}
    bridge = {**copy.deepcopy(common), "current_task": "Acht und fünf", "model_before": bridge_model,
        "model_after": dict(bridge_model), "previous_ids": [7], "stop_control": cases.STOP,
        "active_before_stop": {"pid": 4999, "utterance_id": 21, "profile": cases.PROFILE,
                               "started_observed": True, "completed_observed": False},
        "stop_touch": {"label": cases.STOP, "stable_observed_target": True, "capture": {"file": "synthetic-stop.png"}},
        "returned_voice_control": {"label": cases.IDLE, "stable_observed_target": True, "capture": {"file": "synthetic-idle.png"}},
        "observation_seconds": 5.2, "minimum_observation_seconds": 5, "no_late_new_segments": True,
        "active_id_completed_after_stop": False, "question_menu_opened_during_active_window": False,
        "stop_event_available_in_host_log": False, "acoustic_stop_verified": False,
        "mouth_gesture_stop_verified": False, "millisecond_stop_verified": False}
    return {"schema": "lumo.nextgen.native.runtime.cases", "version": 1, "status": "PASS_WITH_LIMITATIONS",
        "candidate": candidate, "module_sha256": cases.digest(Path(cases.__file__)), "installation_or_reset_performed": False,
        "final_screen": "LUMO AKADEMIE", "banana_slower": banana, "bridge_active_stop": bridge}


class SharedResultGateTest(unittest.TestCase):
    def test_both_real_case_shapes_required_and_synthetic_input_is_not_mutated(self):
        result = synthetic_result()
        before = copy.deepcopy(result)
        self.assertEqual(cases.verify_native_cases(result, candidate=result["candidate"]), before)
        self.assertEqual(result, before)
        for field, value in (("module_sha256", "f" * 64), ("installation_or_reset_performed", True),
                             ("status", "DIAGNOSTIC_ONLY"), ("version", True), ("final_screen", "other"),
                             ("banana_slower", {}), ("bridge_active_stop", {})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                cases.verify_native_cases({**result, field: value}, candidate=result["candidate"])

    def test_missing_segments_stale_ids_unconfirmed_stop_and_overclaims_are_rejected(self):
        original = synthetic_result()
        changes = (("banana_slower", "previous_ids", [3]),
            ("banana_slower", "playback", {**original["banana_slower"]["playback"], "utterance_ids": [3, 4, 5]}),
            ("banana_slower", "acoustic_speed_verified", True), ("banana_slower", "action", "repeat"),
            ("banana_slower", "model_after", {}), ("banana_slower", "video", {}),
            ("bridge_active_stop", "previous_ids", [21]), ("bridge_active_stop", "observation_seconds", 4.9),
            ("bridge_active_stop", "active_id_completed_after_stop", True),
            ("bridge_active_stop", "no_late_new_segments", False), ("bridge_active_stop", "returned_voice_control", {}),
            ("bridge_active_stop", "question_menu_opened_during_active_window", True),
            ("bridge_active_stop", "mouth_gesture_stop_verified", True),
            ("bridge_active_stop", "native_answer_submitted", True), ("bridge_active_stop", "preservation", {}))
        for block, field, value in changes:
            result = copy.deepcopy(original)
            result[block][field] = value
            with self.subTest(block=block, field=field), self.assertRaises(RuntimeError):
                cases.verify_native_cases(result, candidate=result["candidate"])


PANEL_SUPPORT_SPEC = importlib.util.spec_from_file_location("panel_fixture_test_support",
    Path(__file__).with_name("test_nextgen_reference_android_probe.py"))
panel_support = importlib.util.module_from_spec(PANEL_SUPPORT_SPEC)
PANEL_SUPPORT_SPEC.loader.exec_module(panel_support)


class SlowerPanelReadinessTest(unittest.TestCase):
    def execute(self, sequence):
        with patch.object(cases.time, "monotonic", lambda: sequence.now), \
                patch.object(cases.time, "sleep", sequence.sleep):
            return cases.question_slower_target(sequence.instance)

    def test_original_no_panel_then_open_panel_is_observed_after_only_one_question_tap(self):
        sequence = panel_support.PanelFixtureSequence([
            {"file": panel_support.PANEL_BEFORE}, {"file": panel_support.PANEL_AFTER},
            {"file": panel_support.PANEL_AFTER}])
        target = self.execute(sequence)
        self.assertEqual(target, (480, 1700, 740, 1740))
        self.assertEqual(sequence.captures, 3)
        self.assertEqual(sequence.inputs, [("question", ("Lumo fragen", "runtime-banana-open-question"))])
        self.assertEqual(next(iter(sequence.saved.values()))["state"], "PANEL_NOT_YET_OBSERVED")

    def test_missing_panel_never_passes_or_extends_the_original_ninety_seconds(self):
        sequence = panel_support.PanelFixtureSequence([{"file": panel_support.PANEL_BEFORE, "seconds": 30}])
        with self.assertRaisesRegex(RuntimeError, "deadline expired"):
            self.execute(sequence)
        self.assertEqual(sequence.now, 90)
        self.assertEqual(sequence.captures, 3)
        self.assertEqual(sequence.ocr_reads, 0)
        self.assertEqual(len(sequence.inputs), 1)

    def test_panel_or_ocr_arriving_after_deadline_never_returns_a_target(self):
        for frames in (
            [{"file": panel_support.PANEL_BEFORE, "seconds": 45},
             {"file": panel_support.PANEL_AFTER, "seconds": 45}],
            [{"file": panel_support.PANEL_AFTER},
             {"file": panel_support.PANEL_AFTER, "ocr_seconds": 90}],
        ):
            with self.subTest(frames=frames):
                sequence = panel_support.PanelFixtureSequence(frames)
                with self.assertRaisesRegex(RuntimeError, "deadline expired"):
                    self.execute(sequence)
                self.assertEqual(sequence.captures, 2)
                self.assertEqual(len(sequence.inputs), 1)

    def test_scattered_pixels_and_changed_geometry_remain_hard_failures(self):
        for answers, message, captures in (
            ([RuntimeError("Ambiguous scattered question-panel pixels")], "Ambiguous scattered", 1),
            ([(40, 606, 1040, 1803), (60, 606, 1060, 1803)], "panel moved", 2),
        ):
            with self.subTest(message=message):
                sequence = panel_support.PanelFixtureSequence([{"file": panel_support.PANEL_AFTER}])
                with patch.object(cases.reference, "observed_panel_background", side_effect=answers), \
                        self.assertRaisesRegex(RuntimeError, message):
                    self.execute(sequence)
                self.assertEqual(sequence.captures, captures)
                self.assertEqual(len(sequence.inputs), 1)

    def test_panel_disappearance_after_first_observation_fails_without_reopening(self):
        sequence = panel_support.PanelFixtureSequence([
            {"file": panel_support.PANEL_AFTER}, {"file": panel_support.PANEL_BEFORE},
            {"file": panel_support.PANEL_AFTER}])
        with self.assertRaisesRegex(RuntimeError, "panel disappeared"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 2)
        self.assertEqual(len(sequence.inputs), 1)

    def test_partial_transition_invalidates_old_header_and_old_target(self):
        sequence = panel_support.PanelFixtureSequence([
            {"file": panel_support.PANEL_AFTER}, {"file": panel_support.PANEL_AFTER, "partial": True},
            {"file": panel_support.PANEL_AFTER}, {"file": panel_support.PANEL_AFTER}])
        self.assertEqual(self.execute(sequence), (480, 1700, 740, 1740))
        self.assertEqual(sequence.captures, 4)
        sequence = panel_support.PanelFixtureSequence([
            {"file": panel_support.PANEL_AFTER}, {"file": panel_support.PANEL_AFTER, "partial": True},
            {"file": panel_support.PANEL_AFTER}])
        sequence.frames[-1]["rows"] = sequence.rows[2:]
        with self.assertRaisesRegex(RuntimeError, "header were not observed"):
            self.execute(sequence)
        self.assertEqual(sequence.captures, 3)
        self.assertEqual(len(sequence.inputs), 1)

    def test_missing_real_header_or_shortcut_sibling_never_authorizes_slow_action(self):
        sequence = panel_support.PanelFixtureSequence([{"file": panel_support.PANEL_AFTER}])
        sequence.frames[0]["rows"] = sequence.rows[2:]
        with self.assertRaisesRegex(RuntimeError, "header were not observed"):
            self.execute(sequence)
        self.assertEqual(len(sequence.inputs), 1)
        sequence = panel_support.PanelFixtureSequence([{"file": panel_support.PANEL_AFTER, "seconds": 30}])
        sequence.frames[0]["rows"] = sequence.rows[:2] + [sequence.rows[3]]
        with self.assertRaisesRegex(RuntimeError, "deadline expired"):
            self.execute(sequence)
        self.assertEqual(sequence.now, 90)
        self.assertEqual(sum(kind == "question" for kind, _ in sequence.inputs), 1)


if __name__ == "__main__":
    unittest.main()
