"""Pure identity/evidence gates and real Bash ordering; no Android acceptance."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[3]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


probe = module("current_probe_test", ".github/probes/lumo_nextgen_current_reference_android_probe.py")
release = module("current_release_test", "tools/nextgen/prepare_current_learning_release.py")
SOURCE, NATIVE, SHA, CERT = "a" * 40, "b" * 40, "c" * 64, "d" * 64
RESULT_SHA = "e" * 64
VERSION, VERSION_NAME, RUN = 2028, "0.13.16", 123456


def identity():
    return {"sha256": SHA, "flutter_source_commit": SOURCE, "versionCode": VERSION,
            "versionName": VERSION_NAME, "package": probe.learning.PACKAGE,
            "signingCertificateSha256": CERT, "abis": ["x86_64"], "tracked_source_clean": True,
            "godot": {"revision": NATIVE, "pck_sha256": "f" * 64}}


def inputs():
    profile = {"id": "fictional-id", "name": probe.learning.PROFILE_NAME, "grade": 1}
    original = {"schema": "lumo.nextgen.learning.android.probe", "status": "PASS_WITH_LIMITATIONS",
                "run_id": "fictional-original-run", "candidate": identity(), "installed": identity(),
                "probe_sha256": probe.digest(probe.HERE / "lumo_nextgen_learning_android_probe.py"),
                "historical_tour_pass_used": False, "private_app_data_written_by_probe": False,
                "final_profile": profile,
                "device": {"serial": "emulator-5554", "api": 35, "abi": "x86_64",
                           "physical_device": False, "package_absent_before_install": True},
                "native_learning": {"why_question": {"question": "Warum zuerst zwei?",
                    "input_method": "observed Godot input plus real Android keyboard text",
                    "observed_initial_moved": 0, "observed_final_moved": 2,
                    "manual_move_buttons_pressed_after_question": False, "answer_or_score_api_called": False,
                    "response": {"text": "Bis zur Zehn fehlen 2: zehn minus 8 ist 2. Von den 5 bleiben 3."},
                    "playback": {"utterance_ids": [11]}, "video": {"whole_block_within_recording_limit": True}},
                  "performance": {"capture_status": "MEASURED", "scene_observed_seconds": 12,
                    "window_count": 2, "sample_count": 200, "combined_audio_figure_effect_windows": [3],
                    "current_step_replay_playback": {"utterance_ids": [12]},
                    "video": {"whole_block_within_recording_limit": True}}}}
    extra = {"schema": "lumo.nextgen.reference.android.probe", "status": "PASS_WITH_LIMITATIONS",
             "mode": "current-build", "candidate": identity(), "installed": identity(),
             "qa_commit": SOURCE, "apk_source": SOURCE, "native_source": NATIVE, "source_workflow_run": RUN,
             "probe_sha256": probe.digest(probe.HERE / "lumo_nextgen_current_reference_android_probe.py"),
             "reference_probe_sha256": probe.digest(probe.HERE / "lumo_nextgen_reference_android_probe.py"),
             "historical_tour_pass_used": False, "private_app_data_written_by_probe": False,
             "apk_rebuilt_by_probe": False, "fullModernizationComplete": False,
             "previous_complete_probe": {"original_run_id": original["run_id"], "original_status": original["status"],
                 "original_result_sha256": RESULT_SHA, "installed_before_reset": identity(),
                 "synthetic_profile_before_reset": profile}, "device": copy.deepcopy(original["device"]),
             "banana": {"word": "Banane", "syllables": ["Ba", "na", "ne"], "steps": [{}, {}, {}],
                 "repeat_playback": {"segments": 4, "utterance_ids": [20, 21, 22, 23]},
                 "repeat_video": {"whole_block_within_recording_limit": True}, "native_answer_submitted": False,
                 "preservation": {"profile_id": "second-fictional-id"}},
             "pattern": {"task": {"prompt": "fixture"}, "returned_task": {"prompt": "fixture"},
                 "native_confirmation_performed": False, "hint_playback": {"utterance_ids": [24]},
                 "observed_group_hint": "fixture group", "preservation": {"profile_id": "second-fictional-id"},
                 "core_answer_submitted": False}}
    return original, extra


class CurrentIdentityTest(unittest.TestCase):
    def test_actual_file_digest_and_build_outputs_must_agree(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            apk = root / "Lumo-Lernen-Neu.apk"
            apk.write_bytes(b"checker fixture only; not an APK or runtime result")
            sha = hashlib.sha256(apk.read_bytes()).hexdigest()
            proof = {**identity(), "sha256": sha}
            (root / "BUILD-PROVENANCE.json").write_text(json.dumps(proof))
            args = SimpleNamespace(candidate=root, expected_version=VERSION, expected_version_name=VERSION_NAME,
                expected_sha256=sha, expected_source=SOURCE, expected_native=NATIVE, expected_certificate=CERT,
                qa_commit=SOURCE)
            self.assertEqual(probe.current_candidate(args), proof)
            for field, value in (("expected_version", 2027), ("expected_version_name", "old"),
                                  ("qa_commit", "1" * 40), ("expected_source", "2" * 40),
                                  ("expected_native", "3" * 40), ("expected_certificate", "4" * 64),
                                  ("expected_sha256", "5" * 64)):
                with self.subTest(field=field), self.assertRaises(RuntimeError):
                    probe.current_candidate(SimpleNamespace(**{**vars(args), field: value}))
            apk.write_bytes(b"changed after provenanced download")
            with self.assertRaisesRegex(RuntimeError, "hash mismatch"):
                probe.current_candidate(args)

    def test_current_source_and_workflow_are_required(self):
        args = SimpleNamespace(workflow_run_id=RUN, qa_commit=SOURCE, expected_source=SOURCE)
        environment = {"GITHUB_REPOSITORY": probe.reference.REPOSITORY, "GITHUB_SHA": SOURCE, "GITHUB_RUN_ID": str(RUN)}
        probe.verify_ci_context(args, environment)
        for key in environment:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_ci_context(args, {**environment, key: "another"})
        with self.assertRaises(RuntimeError):
            probe.verify_ci_context(SimpleNamespace(**{**vars(args), "workflow_run_id": True}), environment)

    def test_new_identity_cannot_pass_the_immutable_2027_gate(self):
        original, _ = inputs()
        probe.verify_current_original(original, identity(), original["probe_sha256"])
        with self.assertRaisesRegex(RuntimeError, "immutable original"):
            probe.reference.verify_original_success(original, identity())

    def test_current_result_cannot_reuse_a_different_probe_or_missing_performance(self):
        original, _ = inputs()
        for key, value in (("status", "FAIL"), ("installed", {**identity(), "versionCode": 2027}),
                           ("candidate", {**identity(), "flutter_source_commit": probe.reference.SOURCE}),
                           ("probe_sha256", "a" * 64), ("native_learning", {}),
                           ("historical_tour_pass_used", True), ("private_app_data_written_by_probe", True)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_current_original({**original, key: value}, identity(), original["probe_sha256"])

    def test_native_question_requires_actual_input_automatic_movement_and_new_audio(self):
        original, _ = inputs()
        changes = (("question", "something else"), ("input_method", "source fixture"),
                   ("observed_initial_moved", 2), ("observed_final_moved", 0),
                   ("manual_move_buttons_pressed_after_question", True), ("answer_or_score_api_called", True),
                   ("response", {"text": "Okay. Ich passe die Aufgabe an dich an."}),
                   ("playback", {}), ("video", {}))
        for field, value in changes:
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(original)
                changed["native_learning"]["why_question"][field] = value
                probe.verify_current_original(changed, identity(), original["probe_sha256"])

    def test_native_why_reader_cannot_combine_different_frame_variants(self):
        lines = [{"text": "Bis zur Zehn fehlen 2: zehn minus", "bounds": [10, 10, 200, 40], "variant": "raw"},
                 {"text": "8 ist 2. Von den 5 bleiben 3.", "bounds": [10, 50, 200, 80], "variant": "contrast"}]
        self.assertIsNone(probe.learning.native_why_response(lines))
        lines[1]["variant"] = "raw"
        response = probe.learning.native_why_response(lines[::-1])
        self.assertEqual(response["variant"], "raw")
        self.assertTrue(response["text"].startswith("Bis zur Zehn fehlen"))


class ReleaseEvidenceTest(unittest.TestCase):
    def verify(self, original, extra):
        return release.verify_tours(original, extra, source=SOURCE, native=NATIVE, version=VERSION,
            version_name=VERSION_NAME, certificate=CERT, x86_sha256=SHA, workflow_run=RUN,
            original_result_sha256=RESULT_SHA)

    def test_two_same_candidate_tours_return_the_actual_measured_record(self):
        original, extra = inputs()
        self.assertEqual(self.verify(original, extra), original["native_learning"]["performance"])

    def test_stale_diagnostic_incomplete_or_different_source_results_fail(self):
        original, extra = inputs()
        changes = (("status", "DIAGNOSTIC_ONLY"), ("mode", "historical"), ("source_workflow_run", RUN - 1),
                   ("qa_commit", "1" * 40), ("apk_source", "1" * 40), ("native_source", "1" * 40),
                   ("candidate", {**identity(), "sha256": "1" * 64}), ("installed", {}),
                   ("probe_sha256", "1" * 64), ("reference_probe_sha256", "1" * 64),
                   ("historical_tour_pass_used", True), ("private_app_data_written_by_probe", True),
                   ("apk_rebuilt_by_probe", True), ("fullModernizationComplete", True),
                   ("previous_complete_probe", {}), ("banana", {}), ("pattern", {}),
                   ("device", {**extra["device"], "serial": "another"}))
        for key, value in changes:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify(original, {**extra, key: value})

    def test_reference_reset_requires_the_exact_full_original_result_and_profile(self):
        original, extra = inputs()
        for field, value in (("original_run_id", "old"), ("original_status", "FAIL"),
                              ("original_result_sha256", "1" * 64), ("installed_before_reset", {}),
                              ("synthetic_profile_before_reset", {"name": "another"})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(extra)
                changed["previous_complete_probe"][field] = value
                self.verify(original, changed)

    def test_missing_joint_audio_figure_effect_window_or_native_repeat_is_rejected(self):
        original, extra = inputs()
        for field, value in (("capture_status", "UNMEASURED"), ("scene_observed_seconds", 9),
                             ("scene_observed_seconds", 61), ("window_count", 1), ("sample_count", 0),
                             ("combined_audio_figure_effect_windows", []), ("current_step_replay_playback", {}),
                             ("video", {"whole_block_within_recording_limit": False})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(original)
                changed["native_learning"]["performance"][field] = value
                self.verify(changed, extra)
        for field, value in (("steps", [{}, {}]), ("repeat_playback", {"segments": 3, "utterance_ids": [1, 2, 3]}),
                             ("repeat_video", {}), ("native_answer_submitted", True), ("preservation", {})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                changed = copy.deepcopy(extra)
                changed["banana"][field] = value
                self.verify(original, changed)

    def test_ungraded_pattern_is_distinct_from_a_claimed_core_submission(self):
        original, extra = inputs()
        self.verify(original, extra)
        extra["pattern"]["core_answer_submitted"] = True
        with self.assertRaises(RuntimeError):
            self.verify(original, extra)
        extra["pattern"]["core_submission"] = {"status": "PASS"}
        self.verify(original, extra)


class ShellOrderTest(unittest.TestCase):
    def test_shell_wrapper_runs_current_probe_only_after_complete_original_success(self):
        wrapper = ROOT / ".github/probes/run_lumo_nextgen_current_android.sh"
        for first_code in (0, 9):
            with self.subTest(first_code=first_code), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                executable = root / ".probe-venv/bin/python"
                executable.parent.mkdir(parents=True)
                executable.write_text("#!/usr/bin/env python3\nimport json,os,sys\n"
                    "with open(os.environ['PROBE_CALLS'],'a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')\n"
                    "sys.exit(int(os.environ['FIRST_CODE']) if sys.argv[1].endswith('lumo_nextgen_learning_android_probe.py') else 0)\n")
                executable.chmod(0o755)
                calls = root / "calls.jsonl"
                env = {**os.environ, "PROBE_CALLS": str(calls), "FIRST_CODE": str(first_code),
                       "LUMO_EXPECTED_SHA256": SHA, "LUMO_EXPECTED_SOURCE": SOURCE, "LUMO_EXPECTED_NATIVE": NATIVE,
                       "LUMO_EXPECTED_VERSION": str(VERSION), "LUMO_EXPECTED_VERSION_NAME": VERSION_NAME,
                       "LUMO_CERTIFICATE": CERT, "GITHUB_SHA": SOURCE, "GITHUB_RUN_ID": str(RUN)}
                result = subprocess.run(["sh", "-c", 'bash "$1"', "runner", str(wrapper)],
                                        cwd=root, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, first_code, result.stderr)
                rows = [json.loads(line) for line in calls.read_text().splitlines()]
                self.assertEqual(len(rows), 1 if first_code else 2)
                self.assertEqual(rows[0][rows[0].index("--expected-version") + 1], str(VERSION))
                if not first_code:
                    self.assertTrue(rows[1][0].endswith("lumo_nextgen_current_reference_android_probe.py"))
                    self.assertEqual(rows[1][rows[1].index("--expected-version") + 1], str(VERSION))
                    self.assertEqual(rows[1][rows[1].index("--workflow-run-id") + 1], str(RUN))
                    self.assertIn("evidence/android/original-android", rows[1])


if __name__ == "__main__":
    unittest.main()
