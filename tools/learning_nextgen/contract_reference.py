"""Strict, additive v1 envelope reference for cross-team adapter tests.

This intentionally does NOT send native messages or evaluate children's answers:
production Flutter and Godot peers must implement the same checks in their
existing launch/bridge lifecycle before claiming integration.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping

PROTOCOL = "lumo.learning.round"
VERSION = 1
ACTIONS = frozenset({
    "focusObject", "showAllowedHint", "repeatExplanation",
    "slowExplanation", "pause", "stop",
})
ERROR_KINDS = frozenset({
    "none", "placeValue", "counting", "numberTranscription",
    "syllableOrder", "patternRule", "other",
})
GESTURES = frozenset({
    "idle", "look", "point", "count", "think",
    "encourage", "celebrate", "stop",
})
EXPRESSIONS = frozenset({
    "attentive", "thoughtful", "encouraging", "joyful", "neutral",
})
AUDIO_STATES = frozenset({
    "preparing", "playing", "completed", "stopped", "error",
})
RECOGNIZED_KINDS = frozenset({
    "session.started", "task.activated", "presentation.step",
    "answer.proposed", "answer.assessed", "hint.requested",
    "speech.transcript", "conversation.reply", "avatar.cue",
    "audio.status", "turn.cancel", "turn.cancelled", "session.resumed",
})
FLUTTER_ONLY = frozenset({
    "session.started", "task.activated", "answer.assessed",
    "session.resumed",
})


class ContractViolation(ValueError):
    """Reject a stale, malformed or unauthorized cross-team envelope."""


def _nonempty(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip()) and len(value) <= 256


def _integer(value: Any, *, minimum: int = 0) -> bool:
    return type(value) is int and value >= minimum


def _payload_field(payload: Mapping[str, Any], key: str) -> str:
    value = payload.get(key)
    if not _nonempty(value):
        raise ContractViolation(f"invalid payload.{key}")
    return value


@dataclass
class RoundReferenceGate:
    """Reference implementation of message ownership, never learning scoring.

    A Flutter production adapter must bind its existing app/lease owner before
    forwarding anything. Native work may suggest an answer or movement but
    cannot forge the authoritative assessed event.
    """

    session_id: str
    owner_generation: int
    task_id: str
    task_revision: int
    turn_id: str
    object_ids: frozenset[str] = field(default_factory=frozenset)
    allowed_hint_levels: frozenset[int] = field(default_factory=frozenset)
    cancelled: bool = False
    last_sequence: int = -1
    message_ids: set[str] = field(default_factory=set)

    def __post_init__(self) -> None:
        if not _nonempty(self.session_id) or not _nonempty(self.task_id):
            raise ContractViolation("session/task identity required")
        if not _nonempty(self.turn_id):
            raise ContractViolation("turn identity required")
        if not _integer(self.owner_generation) or not _integer(self.task_revision):
            raise ContractViolation("owner/revision must be nonnegative integers")

    def accept(self, envelope: Mapping[str, Any], *, origin: str) -> bool:
        """Return False on exact duplicate message IDs; otherwise accept or raise.

        The method mutates only its reference gate. It never grants learning
        progress, books rewards or invokes a player/renderer.
        """
        if not isinstance(envelope, Mapping):
            raise ContractViolation("envelope must be an object")
        required = (
            "protocol", "version", "messageId", "sessionId",
            "ownerGeneration", "taskId", "taskRevision", "turnId",
            "sequence", "kind", "payload",
        )
        if any(key not in envelope for key in required):
            raise ContractViolation("missing envelope field")
        if envelope["protocol"] != PROTOCOL or type(envelope["version"]) is not int or envelope["version"] != VERSION:
            raise ContractViolation("protocol/version mismatch")
        if not _nonempty(envelope["messageId"]):
            raise ContractViolation("invalid message id")
        kind = envelope["kind"]
        if kind not in RECOGNIZED_KINDS:
            raise ContractViolation("unknown kind")
        if origin not in {"flutter", "godot", "speech", "assistant", "android"}:
            raise ContractViolation("unknown producer")
        if kind in FLUTTER_ONLY and origin != "flutter":
            raise ContractViolation("Flutter-only event from another producer")
        if envelope["sessionId"] != self.session_id or envelope["ownerGeneration"] != self.owner_generation:
            raise ContractViolation("wrong session or child owner")
        if not _integer(envelope["taskRevision"]):
            raise ContractViolation("invalid task revision")
        if not _integer(envelope["sequence"]):
            raise ContractViolation("invalid sequence")
        if not _nonempty(envelope["turnId"]):
            raise ContractViolation("invalid turn id")
        if not isinstance(envelope["payload"], Mapping):
            raise ContractViolation("payload must be an object")

        revision = envelope["taskRevision"]
        task_id = envelope["taskId"]
        turn = envelope["turnId"]
        if kind == "task.activated":
            if not _nonempty(task_id) or revision <= self.task_revision:
                raise ContractViolation("new task must increment revision")
            payload = envelope["payload"]
            objects = payload.get("objectIds")
            if not isinstance(objects, list) or any(not _nonempty(obj) for obj in objects):
                raise ContractViolation("activation requires stable object ids")
            if len(objects) != len(set(objects)) or len(objects) > 128:
                raise ContractViolation("duplicate/too many object ids")
            allowed = payload.get("allowedHints", [])
            if not isinstance(allowed, list) or any(not _integer(i) or i > 5 for i in allowed):
                raise ContractViolation("invalid allowed hint levels")
        elif task_id != self.task_id or revision != self.task_revision:
            raise ContractViolation("stale/wrong task")
        if kind not in {"task.activated", "session.resumed"} and turn != self.turn_id:
            raise ContractViolation("stale conversation turn")
        if self.cancelled and kind not in {"task.activated", "turn.cancelled", "session.resumed"}:
            raise ContractViolation("turn already cancelled")

        msg_id = envelope["messageId"]
        if msg_id in self.message_ids:
            return False
        if envelope["sequence"] <= self.last_sequence:
            raise ContractViolation("out-of-order sequence")
        payload = envelope["payload"]
        self._validate_kind(kind, payload, origin)

        self.message_ids.add(msg_id)
        self.last_sequence = envelope["sequence"]
        if kind == "task.activated":
            self.task_id = task_id
            self.task_revision = revision
            self.turn_id = turn
            self.object_ids = frozenset(payload["objectIds"])
            self.allowed_hint_levels = frozenset(payload.get("allowedHints", []))
            self.cancelled = False
        elif kind == "turn.cancel":
            self.cancelled = True
        elif kind == "session.resumed":
            # Same stored task, fresh revision + turn. A closed old turn cannot
            # mutate the resumed one even if its native callback completes.
            self.task_revision = revision
            self.turn_id = turn
            self.cancelled = False
        return True

    def _validate_kind(self, kind: str, payload: Mapping[str, Any], origin: str) -> None:
        if kind == "avatar.cue":
            target = payload.get("gazeObjectId")
            if target is not None and target not in self.object_ids:
                raise ContractViolation("gaze target absent from task")
            if payload.get("gesture") not in GESTURES or payload.get("expression") not in EXPRESSIONS:
                raise ContractViolation("invalid actor movement")
            _payload_field(payload, "animationState")
        elif kind == "conversation.reply":
            _payload_field(payload, "text")
            action = payload.get("requestAction")
            if action is not None and action not in ACTIONS:
                raise ContractViolation("assistant requested unauthorized action")
            if not _integer(payload.get("contextRevision")):
                raise ContractViolation("invalid context revision")
        elif kind == "audio.status":
            _payload_field(payload, "playbackId")
            state = payload.get("state")
            if state not in AUDIO_STATES or type(payload.get("audible")) is not bool:
                raise ContractViolation("invalid player state")
            if payload["audible"] and state != "playing":
                raise ContractViolation("cannot claim audible before verified playback")
            if not _integer(payload.get("offsetMs")):
                raise ContractViolation("invalid media offset")
            if not _integer(payload.get("durationMs")):
                raise ContractViolation("invalid media duration")
            frames = payload.get("mouthFrames", [])
            if not isinstance(frames, list) or len(frames) > 1200:
                raise ContractViolation("invalid mouth frame data")
            if frames and not payload["audible"]:
                raise ContractViolation("silent audio cannot move the mouth")
        elif kind == "answer.assessed":
            if origin != "flutter" or type(payload.get("correct")) is not bool:
                raise ContractViolation("score requires Flutter authority")
            if payload.get("errorKind") not in ERROR_KINDS:
                raise ContractViolation("invalid error classification")
            _payload_field(payload, "inputId")
        elif kind == "answer.proposed":
            _payload_field(payload, "inputId")
            _payload_field(payload, "inputKind")
        elif kind == "hint.requested":
            if payload.get("level") not in self.allowed_hint_levels:
                raise ContractViolation("unapproved help level")
            target = payload.get("objectId")
            if target is not None and target not in self.object_ids:
                raise ContractViolation("hint refers to missing object")
        elif kind == "presentation.step":
            target = payload.get("objectId")
            if target is not None and target not in self.object_ids:
                raise ContractViolation("step refers to missing object")
            _payload_field(payload, "stepId")
            _payload_field(payload, "operation")
        elif kind == "turn.cancel":
            if payload.get("reason") not in {
                "stop", "taskChange", "profileChange", "lifecycle", "dispose",
            }:
                raise ContractViolation("invalid cancellation reason")
        elif kind == "speech.transcript":
            _payload_field(payload, "recognitionId")
            if type(payload.get("isFinal")) is not bool:
                raise ContractViolation("ASR final must be explicit")
        elif kind == "session.resumed":
            if payload.get("taskId") != self.task_id:
                raise ContractViolation("resumed wrong task")
        # Non-authoritative messages intentionally cannot grant rewards.
