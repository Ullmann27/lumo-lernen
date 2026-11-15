"""Pure evidence gates for the current learning probe; no Android mutation."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "nextgen_learning_android_probe",
    ROOT / ".github/probes/lumo_nextgen_learning_android_probe.py",
)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class ArtifactIdentityTest(unittest.TestCase):
    def setUp(self):
        self.expected = {"sha256": "a" * 64, "source": "b" * 40, "native": "c" * 40,
                         "version": 2027, "certificate": "d" * 64}
        self.proof = {"sha256": "a" * 64, "flutter_source_commit": "b" * 40,
                      "versionCode": 2027, "versionName": "2.0.27", "package": probe.PACKAGE,
                      "signingCertificateSha256": "d" * 64, "tracked_source_clean": True,
                      "abis": ["x86_64"], "godot": {"revision": "c" * 40, "pck_sha256": "e" * 64}}

    def test_exact_current_identity_is_accepted(self):
        result = probe.verify_provenance(self.proof, **self.expected)
        self.assertEqual(result["flutter_source_commit"], "b" * 40)
        self.assertEqual(result["versionCode"], 2027)

    def test_each_mismatched_source_or_binary_fact_is_rejected(self):
        for key, value in (("sha256", "f" * 64), ("flutter_source_commit", "f" * 40),
                           ("versionCode", 2018), ("versionCode", "2027"),
                           ("package", "another.package"), ("signingCertificateSha256", "f" * 64),
                           ("tracked_source_clean", False), ("tracked_source_clean", 1),
                           ("abis", ["arm64-v8a"]), ("abis", ["x86_64", "arm64-v8a"]),
                           ("versionName", ""), ("godot", {"revision": "f" * 40, "pck_sha256": "e" * 64}),
                           ("godot", {"revision": "c" * 40, "pck_sha256": "short"})):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                probe.verify_provenance({**self.proof, key: value}, **self.expected)

    def test_short_mutable_and_historical_pins_are_rejected(self):
        for key, value in (("source", "main"), ("native", "c" * 7), ("sha256", "a" * 63),
                           ("certificate", "D" * 64), ("version", 2018), ("version", True)):
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_provenance(self.proof, **{**self.expected, key: value})

    def test_duplicate_json_keys_cannot_hide_an_identity(self):
        for value in ('{"sha256":"a","sha256":"b"}',
                      '{"godot":{"revision":"a","revision":"b"}}', '[]'):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                probe.read_json(value)

    def test_actual_manifest_and_signer_must_match(self):
        identity = probe.verify_provenance(self.proof, **self.expected)
        badging = f"package: name='{probe.PACKAGE}' versionCode='2027' versionName='2.0.27' platformBuildVersionName='16'\n"
        signer = "Signer #1 certificate SHA-256 digest: " + "d" * 64 + "\n"
        probe.verify_manifest_and_signer(badging, signer, identity)
        for actual_manifest, actual_signer in ((badging.replace("2027", "2018"), signer),
                                               (badging.replace("2.0.27", "2.0.18"), signer),
                                               (badging, signer.replace("d" * 64, "e" * 64)),
                                               (badging, signer + signer.replace("#1", "#2")),
                                               (badging + badging, signer), (badging, "")):
            with self.subTest(manifest=actual_manifest, signer=actual_signer), self.assertRaises(RuntimeError):
                probe.verify_manifest_and_signer(actual_manifest, actual_signer, identity)

    def test_installed_bytes_and_packagemanager_must_match(self):
        identity = probe.verify_provenance(self.proof, **self.expected)
        dump = f"Package [{probe.PACKAGE}] (abc):\n    versionCode=2027 minSdk=24 targetSdk=36\n    versionName=2.0.27\n"
        result = probe.verify_installed_metadata(dump, "a" * 64, identity)
        self.assertEqual(result["signingCertificateSha256"], "d" * 64)
        for actual, actual_hash in ((dump.replace("2027", "2018"), "a" * 64),
                                    (dump.replace(probe.PACKAGE, "other.package"), "a" * 64),
                                    (dump + "versionCode=2018\n", "a" * 64),
                                    (dump, "f" * 64)):
            with self.subTest(actual=actual, actual_hash=actual_hash), self.assertRaises(RuntimeError):
                probe.verify_installed_metadata(actual, actual_hash, identity)


class ObservationTest(unittest.TestCase):
    def node(self, **changes):
        return {"text": "Stopp", "bounds": "[10,20][210,120]", "enabled": "true",
                "clickable": "true", "package": probe.PACKAGE, **changes}

    def test_only_live_enabled_actionable_bounds_are_accepted(self):
        self.assertEqual(probe.observed_control([self.node()], "Stopp"), (10, 20, 210, 120))
        for changes in ({"enabled": "false"}, {"clickable": "false"}, {"package": "other.package"},
                        {"bounds": "[-1,20][210,120]"}, {"bounds": "[10,20][210,21]"},
                        {"bounds": "[10,20][9,120]"}, {"bounds": "guessed"}, {"text": "Stopp später"}):
            with self.subTest(changes=changes):
                self.assertIsNone(probe.observed_control([self.node(**changes)], "Stopp"))

    def test_ambiguous_controls_are_rejected(self):
        with self.assertRaises(RuntimeError):
            probe.observed_control([self.node(), self.node(bounds="[10,200][210,300]")], "Stopp")

    def test_duplicate_semantics_on_same_observed_rectangle_are_one_target(self):
        self.assertEqual(probe.observed_control([self.node(), self.node()], "Stopp"), (10, 20, 210, 120))

    def test_equivalent_navigation_exception_is_restricted_to_reviewed_route(self):
        nodes = [self.node(text="Spielen"), self.node(text="Spielen", bounds="[10,200][410,400]")]
        self.assertEqual(probe.observed_control(nodes, "Spielen", equivalent_navigation=True), (10, 20, 210, 120))
        with self.assertRaises(RuntimeError):
            probe.observed_control([self.node()], "Stopp", equivalent_navigation=True)

    def test_question_prompt_or_generic_reply_is_not_why_evidence(self):
        for labels in ([probe.BRIDGE_PROMPT], ["Warum zuerst zwei?"], ["Du schaffst das!"],
                       ["Bis 10 fehlen 2."], ["8 und 2 und 10."]):
            with self.subTest(labels=labels):
                self.assertIsNone(probe.why_response(labels))
        response = "Weil von acht bis zehn zwei freie Plätze fehlen."
        self.assertEqual(probe.why_response([response]), response)
        visible = "Im Zehnerfeld liegen 8 Plättchen. Es sind noch 2 Plätze frei. Darum brauchen wir zuerst 2 aus dem Vorrat."
        self.assertEqual(probe.why_response([visible]), visible)


class PreservationTest(unittest.TestCase):
    def setUp(self):
        self.profile = {"id": "fictional-unique-child", "name": probe.PROFILE_NAME,
                        "age": 7, "grade": 1, "createdAt": "2026-11-15", "lastActiveAt": "first"}
        self.task = {"topicId": "bridge", "problemId": "bridge-8-5", "sessionId": "session-one",
                     "phase": "example", "moved": 1, "seed": 0}
        self.prefs = {"flutter.lumo_active_profile": json.dumps(self.profile),
                      "flutter.lumo_progress::fictional-unique-child": '{"level":1}',
                      "flutter.lumo_reward_wallet_v1": '{"stars":0}',
                      probe.CHECKPOINT_PREFIX + "::fictional-unique-child": json.dumps(
                          {"version": 1, "sessions": {"bridge:0": self.task}})}

    def test_learning_snapshot_excludes_only_independently_compared_checkpoint(self):
        snapshot = probe.learning_snapshot(self.prefs)
        self.assertEqual(len(snapshot["learning"]), 2)
        self.assertEqual(probe.checkpoint(self.prefs, "bridge"), self.task)
        self.assertIsNone(probe.checkpoint(self.prefs, "words"))
        result = probe.require_preserved(snapshot, copy.deepcopy(snapshot), self.task, copy.deepcopy(self.task))
        self.assertTrue(result["same_task_checkpoint"])

    def test_lost_progress_reward_or_profile_fails(self):
        snapshot = probe.learning_snapshot(self.prefs)
        changed = copy.deepcopy(snapshot)
        changed["learning"]["flutter.lumo_reward_wallet_v1"] = '{"stars":1}'
        missing = copy.deepcopy(snapshot)
        missing["learning"].pop("flutter.lumo_progress::fictional-unique-child")
        other_profile = copy.deepcopy(snapshot)
        other_profile["profile"]["id"] = "other-child"
        for after in (changed, missing, other_profile):
            with self.subTest(after=after), self.assertRaises(RuntimeError):
                probe.require_preserved(snapshot, after)

    def test_task_switch_reset_or_lost_checkpoint_fails(self):
        snapshot = probe.learning_snapshot(self.prefs)
        for after in (None, {**self.task, "moved": 0}, {**self.task, "problemId": "bridge-9-4"},
                      {**self.task, "phase": "build"}, {**self.task, "sessionId": "recreated"}):
            with self.subTest(after=after), self.assertRaises(RuntimeError):
                probe.require_preserved(snapshot, snapshot, self.task, after)

    def test_profile_activity_timestamp_does_not_change_learning_identity(self):
        later = {**self.prefs, "flutter.lumo_active_profile": json.dumps({**self.profile, "lastActiveAt": "later"})}
        self.assertEqual(probe.learning_snapshot(self.prefs), probe.learning_snapshot(later))

    def test_unknown_or_duplicate_checkpoint_fails_closed(self):
        key = probe.CHECKPOINT_PREFIX + "::fictional-unique-child"
        for value in ({"version": 2, "sessions": {}}, {"version": 1, "sessions": []},
                      {"version": 1, "sessions": {"bridge:0": self.task, "bridge:1": self.task}}):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                probe.checkpoint({**self.prefs, key: json.dumps(value)}, "bridge")

    def test_real_or_missing_profile_is_rejected(self):
        for value in ({}, {**self.profile, "name": "Someone else"}, {**self.profile, "id": None}):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                probe.learning_snapshot({**self.prefs, "flutter.lumo_active_profile": json.dumps(value)})


class NativePlaybackTest(unittest.TestCase):
    def events(self, pid=1234, turn=4):
        return (f"I/LumoLearningSpeech( {pid}): started id={turn} profile=lumo-free-supertonic-de-v1\n"
                f"I/LumoLearningSpeech( {pid}): completed id={turn}\n")

    def test_current_process_and_turn_playback(self):
        result = probe.speech_completion(self.events(), 1234)
        self.assertEqual(result["utterance_ids"], [4])
        self.assertFalse(result["audible_quality_verified"])

    def test_old_process_old_turn_and_missing_native_completion_are_rejected(self):
        for log, pid, previous in ((self.events(), 5678, ()), (self.events(), 1234, (4,)),
                                   (self.events().splitlines()[0], 1234, ()),
                                   (self.events().splitlines()[1], 1234, ()),
                                   (self.events(turn=0), 1234, ()),
                                   (self.events().replace("lumo-free-supertonic-de-v1", "unverified-voice"), 1234, ())):
            with self.subTest(log=log, pid=pid, previous=previous), self.assertRaises(RuntimeError):
                probe.speech_completion(log, pid, previous_ids=previous)

    def test_completion_before_start_is_not_playback_evidence(self):
        lines = self.events().splitlines()
        with self.assertRaises(RuntimeError):
            probe.speech_completion("\n".join(reversed(lines)), 1234)

    def test_second_playback_is_new_in_same_native_process(self):
        log = self.events() + self.events(turn=8)
        self.assertEqual(probe.speech_completion(log, 1234, previous_ids=(4,))["utterance_ids"], [8])


if __name__ == "__main__":
    unittest.main()
