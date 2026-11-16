/// Additive local contract shared by the existing lesson, conversation and
/// figure adapters. These requests never grade an answer or grant a reward.
library;

enum LumoLearningAction {
  explain,
  repeat,
  slower,
  hint,
  highlight,
  point,
  look,
  stop,
  proposeAnswer,
}

const lumoDefaultLearningActions = <LumoLearningAction>{
  LumoLearningAction.explain,
  LumoLearningAction.repeat,
  LumoLearningAction.slower,
  LumoLearningAction.hint,
  LumoLearningAction.stop,
};

/// A captured lease on one semantic task snapshot. A response is usable only
/// while every field still matches, including an intervening stop operation.
class LumoLearningIdentity {
  const LumoLearningIdentity({
    required this.sessionId,
    required this.taskId,
    required this.revision,
    required this.cancelEpoch,
    this.stepId,
  });

  static const protocolVersion = 1;
  final String sessionId;
  final String taskId;
  final int revision;
  final int cancelEpoch;
  final String? stepId;

  bool matches(LumoLearningIdentity? other) =>
      other != null &&
      sessionId == other.sessionId &&
      taskId == other.taskId &&
      revision == other.revision &&
      cancelEpoch == other.cancelEpoch &&
      stepId == other.stepId;

  Map<String, Object?> toJson() => {
        'protocolVersion': protocolVersion,
        'sessionId': sessionId,
        'taskId': taskId,
        'revision': revision,
        'cancelEpoch': cancelEpoch,
        if (stepId != null) 'stepId': stepId,
      };
}

class LumoLearningActionRequest {
  const LumoLearningActionRequest({
    required this.identity,
    required this.requestId,
    required this.action,
    this.turnId,
    this.objectId,
    this.candidate,
  });

  final LumoLearningIdentity identity;
  final int requestId;
  final LumoLearningAction action;
  final int? turnId;
  final String? objectId;

  /// A visible, editable proposal, never an evaluation result.
  final String? candidate;
}

class LumoLearningCancellation {
  const LumoLearningCancellation({
    required this.sequence,
    required this.reason,
    this.identity,
  });
  final int sequence;
  final String reason;
  final LumoLearningIdentity? identity;
}

/// Only renderer-owned object IDs cross this seam; a model cannot supply
/// world coordinates or select an object from a previous task.
class LumoLearningPresentation {
  const LumoLearningPresentation({
    required this.identity,
    this.turnId,
    this.utteranceId,
    this.gazeObjectId,
    this.pointObjectId,
    this.expression = 'attentive',
    this.animationState = 'idle',
  });

  final LumoLearningIdentity identity;
  final int? turnId;
  final int? utteranceId;
  final String? gazeObjectId;
  final String? pointObjectId;
  final String expression;
  final String animationState;
}

/// Measurements from the real player. Envelope data describes amplitude,
/// never phonemes or invented word boundaries.
class LumoLearningAudioFrame {
  const LumoLearningAudioFrame({
    required this.identity,
    required this.turnId,
    required this.utteranceId,
    required this.state,
    required this.subtitle,
    this.positionMs = 0,
    this.durationMs = 0,
    this.audible = false,
    this.envelopeAvailable = false,
    this.envelope = 0,
  });

  final LumoLearningIdentity identity;
  final int turnId;
  final int utteranceId;
  final String state;
  final String subtitle;
  final int positionMs;
  final int durationMs;
  final bool audible;
  final bool envelopeAvailable;
  final double envelope;
  String get mouthTiming => envelopeAvailable ? 'envelope' : 'none';
  bool get wordTimingAvailable => false;
  bool get phonemeTimingAvailable => false;
}
