"""Regression probes for the independent LUMO NextGen v1 reference gate.

The tests exercise ownership and serialization decisions, NOT the actual
Flutter-Godot-JNI bridge or physical Android audio/video output.
"""
import unittest

from contract_reference import ContractViolation, RoundReferenceGate


class LearningRoundReferenceTests(unittest.TestCase):
    def setUp(self):
        self.gate = RoundReferenceGate(
            session_id="s-1",
            owner_generation=7,
            task_id="existing-task-8-plus-5",
            task_revision=12,
            turn_id="turn-1",
            object_ids=frozenset(
                ["ten.slot." + str(i) for i in range(10)]
                + ["extra." + str(i) for i in range(5)]
            ),
            allowed_hint_levels=frozenset((1, 2, 3)),
        )

    def message(self, kind, sequence, *, payload=None, **updates):
        msg = {
            "protocol": "lumo.learning.round",
            "version": 1,
            "messageId": "m-" + str(sequence),
            "sessionId": "s-1",
            "ownerGeneration": 7,
            "taskId": self.gate.task_id,
            "taskRevision": self.gate.task_revision,
            "turnId": self.gate.turn_id,
            "sequence": sequence,
            "kind": kind,
            "payload": payload or {},
        }
        msg.update(updates)
        return msg

    def test_child_question_actor_cue_and_flutter_only_assessment(self):
        self.assertTrue(self.gate.accept(self.message(
            "speech.transcript", 1, payload={
                "recognitionId": "recognition-1",
                "text": "Warum zuerst zwei?",
                "isFinal": True,
                "locale": "de-AT",
            }), origin="speech"))
        self.assertTrue(self.gate.accept(self.message(
            "conversation.reply", 2, payload={
                "text": "Weil zur Zehn noch zwei fehlen. Dann bleiben drei übrig.",
                "contextRevision": 12,
                "requestAction": "focusObject",
            }), origin="assistant"))
        self.assertTrue(self.gate.accept(self.message(
            "avatar.cue", 3, payload={
                "gazeObjectId": "extra.0",
                "gesture": "point",
                "expression": "thoughtful",
                "animationState": "explain",
            }), origin="godot"))
        self.assertTrue(self.gate.accept(self.message(
            "answer.proposed", 4, payload={
                "inputId": "finger-1", "inputKind": "touch", "raw": "13",
            }), origin="godot"))
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "answer.assessed", 5, payload={
                    "inputId": "finger-1", "correct": True, "errorKind": "none",
                }), origin="assistant")
        self.assertTrue(self.gate.accept(self.message(
            "answer.assessed", 5, payload={
                "inputId": "finger-1", "correct": True, "errorKind": "none",
            }), origin="flutter"))

    def test_old_task_response_cannot_mutate_next_task(self):
        old = self.message(
            "answer.proposed", 3, payload={
                "inputId": "old-ans", "inputKind": "voice", "raw": "13",
            })
        replacement = self.message(
            "task.activated", 2, payload={
                "taskType": "syllables",
                "objectIds": ["word.syllable.0", "word.syllable.1",
                              "word.syllable.2"],
                "stepId": "start",
                "allowedHints": [1, 2],
            }, taskId="banane-task", taskRevision=13, turnId="turn-2",
        )
        self.assertTrue(self.gate.accept(replacement, origin="flutter"))
        with self.assertRaises(ContractViolation):
            self.gate.accept(old, origin="speech")
        self.assertEqual("banane-task", self.gate.task_id)
        self.assertEqual(13, self.gate.task_revision)

    def test_stop_and_late_audio_never_reanimate_fox(self):
        self.assertTrue(self.gate.accept(self.message(
            "turn.cancel", 1, payload={"reason": "stop"}), origin="android"))
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "audio.status", 2, payload={
                    "playbackId": "audio-old",
                    "state": "playing",
                    "audible": True,
                    "offsetMs": 30,
                    "durationMs": 1500,
                    "subtitle": "Banane",
                }), origin="speech")
        self.assertTrue(self.gate.accept(self.message(
            "turn.cancelled", 3, payload={
                "playbackId": "audio-old", "stopped": True,
            }), origin="android"))
        self.assertTrue(self.gate.cancelled)

    def test_resumed_requires_fresh_revision_and_turn(self):
        self.gate.accept(self.message(
            "turn.cancel", 1, payload={"reason": "lifecycle"}), origin="android")
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "session.resumed", 2,
                taskRevision=12, turnId="turn-2",
                payload={"taskId": "existing-task-8-plus-5", "stepId": "bridge"},
            ), origin="flutter")
        self.assertTrue(self.gate.accept(self.message(
            "session.resumed", 2,
            taskRevision=13, turnId="turn-2",
            payload={"taskId": "existing-task-8-plus-5", "stepId": "bridge"},
        ), origin="flutter"))
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "answer.proposed", 3,
                taskRevision=12, turnId="turn-1",
                payload={"inputId": "late", "inputKind": "voice", "raw": "13"},
            ), origin="speech")

    def test_unsafe_action_cannot_be_forwarded_to_learning_authority(self):
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "conversation.reply", 1, payload={
                    "text": "Erledigt",
                    "contextRevision": 12,
                    "requestAction": "grantReward",
                }), origin="assistant")
        self.assertEqual(-1, self.gate.last_sequence)

    def test_undeclared_scene_object_rejected(self):
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "avatar.cue", 1, payload={
                    "gazeObjectId": "other.task.token",
                    "gesture": "point",
                    "expression": "thoughtful",
                    "animationState": "explain",
                }), origin="godot")

    def test_audible_flag_only_after_real_playing_event(self):
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "audio.status", 1, payload={
                    "playbackId": "voice-1", "state": "preparing",
                    "audible": True, "offsetMs": 0, "durationMs": 900,
                    "subtitle": "Ba–na–ne",
                }), origin="android")
        self.assertTrue(self.gate.accept(self.message(
            "audio.status", 1, payload={
                "playbackId": "voice-1", "state": "playing",
                "audible": True, "offsetMs": 50, "durationMs": 900,
                "subtitle": "Ba–na–ne",
                "mouthFrames": [[50, 0.7]],
            }), origin="android"))

    def test_identical_message_replay_is_idempotent(self):
        msg = self.message("speech.transcript", 1, payload={
            "recognitionId": "asr", "text": "dreizehn",
            "isFinal": True, "locale": "de-AT",
        })
        self.assertTrue(self.gate.accept(msg, origin="speech"))
        self.assertFalse(self.gate.accept(msg, origin="speech"))

    def test_unspecified_hint_or_unintended_score_is_rejected(self):
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "hint.requested", 1,
                payload={"level": 4, "objectId": "extra.1", "reason": "error"},
            ), origin="assistant")
        with self.assertRaises(ContractViolation):
            self.gate.accept(self.message(
                "answer.assessed", 2,
                payload={"inputId": "a", "correct": "yes", "errorKind": "none"},
            ), origin="flutter")

    def test_owner_bool_and_old_generation_rejected(self):
        for owner in (True, 6, 8):
            with self.subTest(owner=owner), self.assertRaises(ContractViolation):
                self.gate.accept(self.message(
                    "speech.transcript", 1, ownerGeneration=owner,
                    payload={"recognitionId": "a", "isFinal": True},
                ), origin="speech")

    def test_unknown_version_and_missing_fields_fail_closed(self):
        invalid = self.message("session.started", 1)
        invalid["version"] = 2
        with self.assertRaises(ContractViolation):
            self.gate.accept(invalid, origin="flutter")
        invalid = self.message("session.started", 1)
        del invalid["sessionId"]
        with self.assertRaises(ContractViolation):
            self.gate.accept(invalid, origin="flutter")


if __name__ == "__main__":
    unittest.main()
