"""Constructed Python/ET.Element fixtures only; no Android run or fake original XML."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("runtime_cases_under_test",
    ROOT / ".github/probes/lumo_nextgen_2031_runtime_cases_android_probe.py")
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
QA, RUN = "1" * 40, 987654
PROFILE = {"id": "constructed-child", "name": probe.learning.PROFILE_NAME, "grade": 1}
JOURNEY_KEY = "flutter.lumo_progress_journey_v1.constructed-child"


def config():
    return {"schemaVersion": 1, "apkSource": probe.immutable.SOURCE, "nativeSource": probe.immutable.NATIVE,
            "sourceBuildRun": probe.immutable.SOURCE_RUN, "versionName": probe.immutable.VERSION_NAME,
            "versionCode": probe.immutable.VERSION, "caseAttempt": 1, "cases": list(probe.CASES)}


def identity():
    return {"sha256": probe.immutable.APK_SHA, "flutter_source_commit": probe.immutable.SOURCE,
            "versionCode": probe.immutable.VERSION, "versionName": probe.immutable.VERSION_NAME,
            "package": probe.learning.PACKAGE, "signingCertificateSha256": probe.immutable.CERTIFICATE,
            "abis": ["x86_64"], "tracked_source_clean": True,
            "godot": {"revision": probe.immutable.NATIVE, "pck_sha256": probe.immutable.PCK_SHA}}


def skill(number):
    return {"subject": "Mathematik", "unit": "Plus bis 20", "attempts": number,
            "assistedCorrect": 2 if number == 3 else 1, "independentCorrect": 0, "transferCorrect": 0,
            "errorCounts": {"one_off": 1} if number > 1 else {},
            "recentTaskIds": [f"lab-fixture-{index}" for index in range(1, number + 1)],
            "independentProblemIds": []}


def checkpoint(number=1):
    return {"topicId": "bridge", "seed": 0, "sessionId": "lab-fixture", "problemId": "bridge-9-7",
            "phase": "recall", "support": 0, "hint": 0, "attempt": number, "pendingAttemptId": None,
            "lastSavedAttemptId": None if number == 1 else f"lab-fixture-{number}",
            "answer": "" if number == 1 else "15" if number == 2 else "16",
            "wrongBefore": number > 1, "done": number == 3}


def attempt(correct):
    value = {"id": "constructed-log-correct" if correct else "constructed-log-wrong", "sid": "self",
             "sub": "Mathematik", "unit": "Plus bis 20", "q": probe.RECALL_PROMPT,
             "a": "16" if correct else "15", "e": "16", "ok": correct}
    if correct:
        value["hint"] = True
    return value


def snapshot(number):
    entries = [] if number == 1 else [attempt(False)] if number == 2 else [attempt(False), attempt(True)]
    return {"profile": dict(PROFILE), "learning": {
        "flutter.lumo_attempt_log_v1": json.dumps(entries),
        JOURNEY_KEY: json.dumps({"version": 1, "records": {"mathematik::plus bis 20": skill(number)}}),
        "flutter.lumo_reward_wallet_v1": '{"stars":0,"xp":0}',
    }}


def video():
    return {"file": "constructed-no-real-video.mp4", "sha256": "2" * 64, "duration_seconds": 2.0,
            "whole_block_within_recording_limit": True, "audio_recorded": False}


def word_case():
    before = snapshot(3)
    journey = json.loads(before["learning"][JOURNEY_KEY])
    journey["records"]["deutsch::silben"] = {"subject": "Deutsch", "unit": "Silben",
        "assistedCorrect": 1, "recentTaskIds": ["word-fixture-1"]}
    before["learning"][JOURNEY_KEY] = json.dumps(journey)
    old = {"topicId": "words", "seed": 0, "sessionId": "word-fixture", "problemId": "word-banane",
           "phase": "build", "tokens": [2, 3, 0], "done": True, "attempt": 1,
           "lastSavedAttemptId": "word-fixture-1", "pendingAttemptId": None}
    new = {**old, "problemId": "word-rakete", "phase": "recall", "tokens": [], "done": False,
           "answer": "", "lastSavedAttemptId": None}
    return {"status": "PASS", "before": before, "after": copy.deepcopy(before),
            "checkpoint_before": old, "checkpoint_after": new, "explicit_stop_before_switch": False,
            "old_active_marker_absent": True, "capture_to_touch_seconds": .101,
            "observation": {"active_label": "Silbe 2: na, gerade aktiv", "next_label": probe.NEXT,
                            "xml": "constructed.xml", "xml_sha256": "3" * 64,
                            "capture_started_monotonic": 10.0, "capture_finished_monotonic": 10.1,
                            "touch_requested_monotonic": 10.101}, "video": video(),
            "verification": probe.verify_word_switch(before, before, old, new)}


def complete_result():
    numeric = {"status": "PASS", "submission_control": "Antwort prüfen",
               "input_method": "real Android text input", "spoken_recognition_exercised": False}
    for number, correct, stage in ((2, False, "wrong"), (3, True, "corrected")):
        before, after, old, new = snapshot(number - 1), snapshot(number), checkpoint(number - 1), checkpoint(number)
        numeric[stage] = {"before": before, "after": after, "checkpoint_before": old, "checkpoint_after": new,
            "verification": probe.verify_numeric_submission(before, after, old, new, correct=correct), "video": video()}
    proof = identity()
    # Use the real metadata parser's result shape, not the fuller candidate dict.
    installed = probe.learning.verify_installed_metadata(
        f"Package [{probe.learning.PACKAGE}]\n versionCode=2031\n versionName=0.13.19\n", proof["sha256"], proof)
    return {"schema": "lumo.nextgen.runtime_cases.android", "version": 1, "status": "PASS_WITH_LIMITATIONS",
        "mode": "immutable-runtime-cases", "release_eligible": False, "original_probe_requirement_satisfied": False,
        "qa_commit": QA, "qa_workflow_run": RUN, "apk_source": probe.immutable.SOURCE,
        "native_source": probe.immutable.NATIVE, "source_build_run": probe.immutable.SOURCE_RUN,
        "historical_tour_pass_used": False, "private_app_data_written_by_probe": False, "apk_rebuilt_by_probe": False,
        "fullModernizationComplete": False, "config": config(), "candidate": proof, "installed": installed,
        "device": {"api": 35, "abi": "x86_64", "physical_device": False, "package_absent_before_install": True},
        "onboarding": {"synthetic": True, "profile": PROFILE}, "final_profile": PROFILE,
        "auto_read_restored_before_native": True, "numeric_wrong_then_correct": numeric,
        "runtime_auto_read_ui_changes": [{"control": "Automatisch vorlesen", "private_preferences_written": False,
            "before": {"autoReadEnabled": True}, "after": {"autoReadEnabled": False}}],
        "local_voice_settings": {"auto_read": True},
        "flutter_switch_during_syllable_playback": word_case(),
        "native_runtime_cases": {"schema": "lumo.nextgen.native.runtime.cases", "version": 1,
            "status": "PASS_WITH_LIMITATIONS", "candidate": proof,
            "banana_slower": {"status": "PASS_WITH_LIMITATIONS"}, "bridge_active_stop": {"status": "PASS_WITH_LIMITATIONS"}}}


def ui(active="Silbe 2: na, gerade aktiv", *, next_enabled=True):
    # ET.Element is the actual runtime representation. These nodes are explicitly
    # constructed; they are not represented as recorded Android evidence.
    root = ET.Element("hierarchy")
    for caption, box, clickable, enabled in (
        ("Die Wortwerkstatt", "[0,0][400,60]", False, True),
        (active, "[10,120][300,180]", False, False),
        (probe.NEXT, "[10,400][390,460]", True, next_enabled),
    ):
        ET.SubElement(root, "node", {"package": probe.learning.PACKAGE, "content-desc": caption, "bounds": box,
            "visible-to-user": "true", "clickable": str(clickable).lower(), "enabled": str(enabled).lower()})
    return list(ET.fromstring(ET.tostring(root)).iter("node"))


class RuntimeCaseGates(unittest.TestCase):
    def test_configuration_is_exact_and_attempt_is_positive_integer(self):
        probe.verify_runtime_config(config())
        for key, value in (("schemaVersion", True), ("apkSource", QA), ("nativeSource", QA),
                           ("sourceBuildRun", 1), ("versionName", "old"), ("versionCode", True),
                           ("caseAttempt", True), ("caseAttempt", 0), ("cases", probe.CASES[::-1])):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                probe.verify_runtime_config({**config(), key: value})
        with self.assertRaises(RuntimeError):
            probe.verify_runtime_config({**config(), "skipOriginal": True})

    def test_wrong_and_corrected_attempts_keep_distinct_ids_and_assistance(self):
        wrong = probe.verify_numeric_submission(snapshot(1), snapshot(2), checkpoint(1), checkpoint(2), correct=False)
        corrected = probe.verify_numeric_submission(snapshot(2), snapshot(3), checkpoint(2), checkpoint(3), correct=True)
        self.assertNotEqual(wrong["lab_attempt_id"], corrected["lab_attempt_id"])
        self.assertNotEqual(wrong["stored_attempt"]["id"], corrected["stored_attempt"]["id"])
        self.assertFalse(wrong["support"]["stored_hint_used"])
        self.assertTrue(corrected["support"]["stored_hint_used"])
        self.assertEqual(corrected["support"]["checkpoint_support"], 0)

    def test_merely_edited_answer_or_wrong_expected_prompt_is_not_assessment(self):
        with self.assertRaisesRegex(RuntimeError, "exactly one new"):
            probe.verify_numeric_submission(snapshot(1), snapshot(1), checkpoint(1), checkpoint(2), correct=False)
        for key, value in (("q", "8 + 5 = ?"), ("a", "16"), ("e", "15"), ("ok", True), ("sid", "other")):
            after = snapshot(2)
            record = attempt(False)
            record[key] = value
            after["learning"]["flutter.lumo_attempt_log_v1"] = json.dumps([record])
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_numeric_submission(snapshot(1), after, checkpoint(1), checkpoint(2), correct=False)

    def test_duplicate_rewritten_or_unassisted_correction_is_rejected(self):
        for entries in ([attempt(False)], [attempt(False), attempt(True), {**attempt(True), "id": "extra"}],
                        [{**attempt(False), "a": "edited"}, attempt(True)],
                        [attempt(False), {**attempt(True), "hint": False}]):
            after = snapshot(3)
            after["learning"]["flutter.lumo_attempt_log_v1"] = json.dumps(entries)
            with self.subTest(entries=entries), self.assertRaises(RuntimeError):
                probe.verify_numeric_submission(snapshot(2), after, checkpoint(2), checkpoint(3), correct=True)

    def test_pending_reused_foreign_checkpoint_or_journey_cannot_pass(self):
        for key, value in (("pendingAttemptId", "still-saving"), ("lastSavedAttemptId", "lab-fixture-2"),
                           ("sessionId", "other"), ("problemId", "bridge-8-5"), ("attempt", 4), ("support", 3)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_numeric_submission(snapshot(2), snapshot(3), checkpoint(2), {**checkpoint(3), key: value}, correct=True)
        after = snapshot(3)
        raw = json.loads(after["learning"][JOURNEY_KEY])
        raw["records"]["mathematik::plus bis 20"]["independentCorrect"] = 1
        after["learning"][JOURNEY_KEY] = json.dumps(raw)
        with self.assertRaisesRegex(RuntimeError, "persisted journey delta"):
            probe.verify_numeric_submission(snapshot(2), after, checkpoint(2), checkpoint(3), correct=True)

    def test_actual_element_representation_accepts_same_view_active_and_next(self):
        nodes = ui()
        self.assertIsInstance(nodes[0], ET.Element)
        target = probe.observed_active_next(nodes)
        self.assertEqual(target["active_label"], "Silbe 2: na, gerade aktiv")
        self.assertEqual(target["next_bounds"], (10, 400, 390, 460))

    def test_inactive_missing_disabled_hidden_or_foreign_cue_is_not_playback(self):
        self.assertIsNone(probe.observed_active_next(ui("Silbe 2: na")))
        self.assertIsNone(probe.observed_active_next(ui(next_enabled=False)))
        self.assertIsNone(probe.observed_active_next(ui()[:2]))
        for key, value in (("visible-to-user", "false"), ("package", "com.other"), ("bounds", "[0,0][100,0]")):
            nodes = ui()
            nodes[1].set(key, value)
            with self.subTest(key=key):
                self.assertIsNone(probe.observed_active_next(nodes))

    def test_ambiguous_syllable_or_next_cannot_be_selected(self):
        nodes = ui()
        second = copy.deepcopy(nodes[1])
        second.set("content-desc", "Silbe 3: ne, gerade aktiv")
        with self.assertRaisesRegex(RuntimeError, "simultaneous active"):
            probe.observed_active_next(nodes + [second])
        self.assertIsNotNone(probe.observed_active_next(nodes + [copy.deepcopy(nodes[2])]))
        other = copy.deepcopy(nodes[2])
        other.set("bounds", "[10,500][390,560]")
        with self.assertRaisesRegex(RuntimeError, "Ambiguous"):
            probe.observed_active_next(nodes + [other])
        with self.assertRaisesRegex(RuntimeError, "Contradictory"):
            probe.observed_active_next(ui("Silbe 2: Ba, gerade aktiv"))

    def test_switch_preserves_actual_learning_and_changes_to_unanswered_rakete(self):
        case = word_case()
        self.assertTrue(case["verification"]["no_new_attempt_or_reward"])
        for key, value in (("problemId", "word-banane"), ("sessionId", "other"), ("attempt", 2), ("answer", "Rakete"),
                           ("done", True), ("lastSavedAttemptId", "new-attempt")):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_word_switch(case["before"], case["after"], case["checkpoint_before"],
                                         {**case["checkpoint_after"], key: value})
        changed = copy.deepcopy(case["after"])
        changed["learning"]["flutter.lumo_reward_wallet_v1"] = '{"stars":1,"xp":0}'
        with self.assertRaisesRegex(RuntimeError, "data changed"):
            probe.verify_word_switch(case["before"], changed, case["checkpoint_before"], case["checkpoint_after"])

    def test_actual_switch_reader_taps_once_from_its_new_xml_and_rejects_missed_or_late_playback(self):
        for scenario in ("active", "missed", "late-observation", "slow-capture", "stale-before-touch"):
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as directory:
                clock, touches = [0.0], []
                item = object.__new__(probe.RuntimeCasesProbe)
                item.out, item.counter = Path(directory), 0

                def observe(out, name):
                    clock[0] += 2.0 if scenario == "late-observation" else 1.1 if scenario == "slow-capture" else .1
                    root = ET.Element("hierarchy")
                    root.extend(ui("Silbe 2: na" if scenario == "missed" else "Silbe 2: na, gerade aktiv"))
                    text = ET.tostring(root, encoding="unicode")
                    (out / (name + ".xml")).write_text(text)
                    return list(ET.fromstring(text).iter("node"))

                def hashed(path):
                    if scenario == "stale-before-touch":
                        clock[0] += 1.1
                    return probe.immutable.digest(path)

                item.live = SimpleNamespace(live_nodes=observe)
                item.touch = lambda *args: touches.append(args)
                item.scroll = lambda *_: self.fail("Next is visible in these constructed observations")
                with patch.object(probe.time, "monotonic", side_effect=lambda: clock[0]), \
                     patch.object(probe.time, "sleep", side_effect=lambda seconds: clock.__setitem__(0, clock[0] + seconds)), \
                     patch.object(probe, "digest", side_effect=hashed):
                    if scenario == "active":
                        result = item.switch_on_active_syllable(timeout=.5)
                        self.assertEqual(len(touches), 1)
                        self.assertEqual(touches[0][0], (10, 400, 390, 460))
                        self.assertEqual(result["observation"]["xml_sha256"],
                                         probe.immutable.digest(item.out / result["observation"]["xml"]))
                        self.assertEqual(result["capture_to_touch_seconds"], .1)
                        self.assertEqual(result["observation"]["capture_started_monotonic"], 0.0)
                        self.assertEqual(result["observation"]["capture_finished_monotonic"], .1)
                        self.assertEqual(result["observation"]["touch_requested_monotonic"], .1)
                    else:
                        with self.assertRaises(RuntimeError):
                            item.switch_on_active_syllable(timeout=5 if scenario == "slow-capture" else .5)
                        self.assertEqual(touches, [])
                self.assertGreater(len(list(item.out.glob("*.xml"))), 0)

    def test_complete_result_remains_separate_from_release_or_full_tour(self):
        result = complete_result()
        # The native owner tests its concrete four-segment/stop evidence. This
        # isolated orchestration fixture checks that its exact validator is used.
        with patch.object(probe, "native_cases_module") as native:
            self.assertFalse(probe.verify_runtime_cases(result, qa_commit=QA, workflow_run_id=RUN)["release_eligible"])
            native.return_value.verify_native_cases.assert_called_once_with(result["native_runtime_cases"], candidate=identity())
            # Exercise the JSON roundtrip used by an external caller.
            probe.verify_runtime_cases(json.loads(json.dumps(result)), qa_commit=QA, workflow_run_id=RUN)
        for key, value in (("release_eligible", True), ("original_probe_requirement_satisfied", True),
                           ("status", "RUNNING"), ("mode", "immutable-replay"), ("qa_commit", probe.immutable.SOURCE),
                           ("private_app_data_written_by_probe", True), ("auto_read_restored_before_native", False)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_runtime_cases({**result, key: value}, qa_commit=QA, workflow_run_id=RUN)

    def test_native_owner_rejection_is_not_replaced_by_case_statuses(self):
        result = complete_result()
        with patch.object(probe, "native_cases_module") as native:
            native.return_value.verify_native_cases.side_effect = RuntimeError("constructed missing native audio evidence")
            with self.assertRaisesRegex(RuntimeError, "missing native audio evidence"):
                probe.verify_runtime_cases(result, qa_commit=QA, workflow_run_id=RUN)

    def test_pure_gate_rejects_slow_capture_even_with_zero_post_capture_delay(self):
        for scenario in ("slow-capture", "hidden-capture-age", "nonfinite", "reversed"):
            result = complete_result()
            case = result["flutter_switch_during_syllable_playback"]
            case["observation"].update(capture_started_monotonic=10.0,
                                       capture_finished_monotonic=11.1,
                                       touch_requested_monotonic=11.1)
            case["capture_to_touch_seconds"] = 1.1
            if scenario == "hidden-capture-age":
                case["capture_to_touch_seconds"] = 0.0
            elif scenario == "nonfinite":
                case["observation"]["capture_started_monotonic"] = float("nan")
            elif scenario == "reversed":
                case["observation"]["capture_started_monotonic"] = 11.2
                case["capture_to_touch_seconds"] = .1
            with self.subTest(scenario=scenario), self.assertRaisesRegex(RuntimeError, "freshness budget"):
                probe.verify_runtime_cases(result, qa_commit=QA, workflow_run_id=RUN)

    def test_late_switch_truncated_video_or_missing_native_case_never_passes(self):
        for change in ("late", "stopped", "truncated", "native", "installed"):
            result = complete_result()
            if change == "late":
                result["flutter_switch_during_syllable_playback"]["capture_to_touch_seconds"] = 1.01
            elif change == "stopped":
                result["flutter_switch_during_syllable_playback"]["explicit_stop_before_switch"] = True
            elif change == "truncated":
                result["numeric_wrong_then_correct"]["wrong"]["video"]["whole_block_within_recording_limit"] = False
            elif change == "native":
                result["native_runtime_cases"].pop("bridge_active_stop")
            else:
                result["installed"]["sha256"] = "0" * 64
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                probe.verify_runtime_cases(result, qa_commit=QA, workflow_run_id=RUN)

    def test_entry_retains_failure_with_non_release_flags_before_android(self):
        with tempfile.TemporaryDirectory() as directory:
            args = SimpleNamespace(out=Path(directory) / "out", candidate=Path(directory) / "candidate",
                                   download_evidence=Path(directory) / "download", qa_commit=QA, workflow_run_id=RUN, serial=None)
            with patch.object(probe.immutable, "load", side_effect=RuntimeError("constructed missing config")), \
                 patch.object(probe.RuntimeCasesProbe, "__init__", side_effect=AssertionError("must not install")), \
                 patch("sys.stderr"):
                self.assertEqual(probe.run(args), 1)
            result = json.loads((args.out / "runtime-cases-result.json").read_text())
            self.assertEqual(result["status"], "FAIL")
            self.assertFalse(result["release_eligible"])
            self.assertFalse(result["original_probe_requirement_satisfied"])
            self.assertIn("constructed missing config", result["error"])


if __name__ == "__main__":
    unittest.main()
