"""Publication rejection checks using synthetic metadata, never device evidence."""
import copy
import importlib.util
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location(
    "prepare_learning_replay_release", Path(__file__).with_name("prepare_learning_replay_release.py"))
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


class ReplayPublicationTest(unittest.TestCase):
    def setUp(self):
        self.qa = "f" * 40
        candidate = {"sha256": release.X86_SHA, "flutter_source_commit": release.SOURCE,
                     "package": release.PACKAGE, "signingCertificateSha256": release.CERTIFICATE,
                     "versionCode": 2027, "godot": {"revision": release.NATIVE}}
        self.original = {"status": "PASS_WITH_LIMITATIONS", "run_id": "unit-fixture-not-device",
                         "candidate": candidate, "native_learning": {"performance": {
                             "capture_status": "MEASURED", "scene_observed_seconds": 20,
                             "window_count": 3, "sample_count": 100,
                             "combined_audio_figure_effect_windows": [2],
                             "current_step_replay_playback": {"utterance_ids": [4]},
                             "video": {"whole_block_within_recording_limit": True}}}}
        self.reference = {"status": "PASS_WITH_LIMITATIONS", "qa_commit": self.qa,
                          "candidate": copy.deepcopy(candidate),
                          "previous_complete_probe": {"original_run_id": self.original["run_id"]},
                          "banana": {"repeat_playback": {"segments": 4}, "steps": [1, 2, 3]},
                          "pattern": {"native_confirmation_performed": False}}
        self.replay = {"status": "PASS_WITH_LIMITATIONS", "qa_commit": self.qa,
                       "apk_source": release.SOURCE, "apk_sha256": release.X86_SHA,
                       "original_source_run": release.SOURCE_RUN, "apk_rebuilt": False}

    def verify(self):
        return release.verify_replay_results(self.original, self.reference, self.replay, self.qa)

    def test_same_source_and_both_actual_result_contracts_are_required(self):
        self.assertEqual(self.verify()["window_count"], 3)
        for target in (self.original, self.reference, self.replay):
            old = target["status"]
            for status in ("RUNNING", "FAIL", "SKIPPED", None):
                target["status"] = status
                with self.subTest(status=status), self.assertRaises(RuntimeError):
                    self.verify()
            target["status"] = old

    def test_wrong_or_rebuilt_apk_cannot_be_relabelled(self):
        for key, wrong in (("apk_source", "a" * 40), ("apk_sha256", "a" * 64),
                           ("original_source_run", release.SOURCE_RUN + 1), ("apk_rebuilt", True),
                           ("qa_commit", "a" * 40)):
            old = self.replay[key]
            self.replay[key] = wrong
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify()
            self.replay[key] = old

    def test_additional_tour_cannot_replace_original_performance(self):
        performance = self.original["native_learning"]["performance"]
        for key, wrong in (("capture_status", "NOT_MEASURED"), ("scene_observed_seconds", 9),
                           ("scene_observed_seconds", 61), ("window_count", 1), ("sample_count", 0),
                           ("combined_audio_figure_effect_windows", []),
                           ("current_step_replay_playback", {"utterance_ids": []}),
                           ("video", {"whole_block_within_recording_limit": False})):
            old = performance[key]
            performance[key] = wrong
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.verify()
            performance[key] = old

    def test_missing_banana_or_native_grading_claim_is_rejected(self):
        self.reference["banana"]["steps"] = [1, 2]
        with self.assertRaises(RuntimeError):
            self.verify()
        self.reference["banana"]["steps"] = [1, 2, 3]
        self.reference["pattern"]["native_confirmation_performed"] = True
        with self.assertRaises(RuntimeError):
            self.verify()

    def test_cross_installation_or_different_candidate_is_rejected(self):
        self.reference["previous_complete_probe"]["original_run_id"] = "other"
        with self.assertRaises(RuntimeError):
            self.verify()
        self.reference["previous_complete_probe"]["original_run_id"] = self.original["run_id"]
        self.reference["candidate"]["sha256"] = "a" * 64
        with self.assertRaises(RuntimeError):
            self.verify()

    def test_wrong_expired_or_foreign_artifact_metadata_is_rejected(self):
        expected = release.ARM64_ARTIFACT
        actual = {**expected, "expired": False,
                  "workflow_run": {"id": release.SOURCE_RUN, "head_sha": release.SOURCE}}
        release.verify_artifact_metadata(actual, expected, release.SOURCE_RUN, release.SOURCE)
        for key, wrong in (("id", 1), ("name", "old-apk"), ("size_in_bytes", 1),
                           ("digest", "sha256:" + "0" * 64), ("expired", True),
                           ("workflow_run", {"id": 1, "head_sha": release.SOURCE}),
                           ("workflow_run", {"id": release.SOURCE_RUN, "head_sha": "a" * 40})):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                release.verify_artifact_metadata({**actual, key: wrong}, expected,
                                                 release.SOURCE_RUN, release.SOURCE)


if __name__ == "__main__":
    unittest.main()
