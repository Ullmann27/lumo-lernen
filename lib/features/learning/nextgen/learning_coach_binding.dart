import 'dart:async';

import '../../../core/lumo_learning_session_contract.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';

/// Lesson-side consumer of the canonical Chat-1/Chat-4 request bus. This class
/// has no answer evaluator, microphone, progress store, navigation or rewards.
/// A spoken candidate can only reach [onProposeAnswer], never an answer check.
class LearningCoachBinding {
  LearningCoachBinding({
    required this.isActive,
    required this.onHint,
    required this.onExplain,
    required this.onRepeat,
    required this.onSlower,
    required this.onStop,
    required this.onCancel,
    required this.onTryMyself,
    this.onProposeAnswer,
    this.onFocus,
    LumoCompanionRequests? requests,
  }) : requests = requests ?? LumoCompanionRequests.instance {
    this.requests.learningAction.addListener(_actionChanged);
    this.requests.learningCancellation.addListener(_cancelled);
  }

  final LumoCompanionRequests requests;
  final bool Function() isActive;
  final FutureOr<void> Function() onHint, onExplain, onRepeat, onSlower;
  final FutureOr<void> Function() onStop, onCancel, onTryMyself;
  final void Function(String value)? onProposeAnswer;
  final void Function(String id, LumoLearningAction action)? onFocus;
  LumoCompanionTaskContext? _context;
  LumoLearningIdentity? _activeIdentity;
  bool _disposed = false;
  int _lastRequestId = -1;
  int _lastCancelSequence = -1;

  bool get ownsCurrentTask =>
      !_disposed &&
      isActive() &&
      _context != null &&
      identical(requests.taskContext.value, _context);

  LumoLearningIdentity? get identity =>
      ownsCurrentTask ? requests.learningIdentity.value : null;

  LumoLearningIdentity? publish(LumoCompanionTaskContext context) {
    if (_disposed || !isActive()) return null;
    _context = context;
    requests.publishTask(context);
    _activeIdentity = identity;
    return _activeIdentity;
  }

  bool matches(LumoLearningIdentity captured) =>
      ownsCurrentTask && requests.isCurrentLearningIdentity(captured);

  bool request(LumoLearningAction action,
      {LumoLearningIdentity? captured, String? objectId, String? candidate}) {
    final current = captured ?? identity;
    return current != null &&
        requests.requestLearningAction(action,
            identity: current, objectId: objectId, candidate: candidate);
  }

  /// A local equivalent of declining help. Existing protocol stop also leaves
  /// the child free to work; it never erases previously used assistance.
  bool tryMyself(LumoLearningIdentity captured) {
    if (!matches(captured)) return false;
    _run(onTryMyself);
    return true;
  }

  bool present({String? objectId, bool point = false, String state = 'idle'}) {
    final current = identity;
    return current != null &&
        requests.publishLearningPresentation(LumoLearningPresentation(
          identity: current,
          gazeObjectId: objectId,
          pointObjectId: point ? objectId : null,
          expression: point ? 'explaining' : 'attentive',
          animationState: state,
        ));
  }

  void interrupt(String reason) {
    if (ownsCurrentTask) requests.cancelLearningInteraction(reason: reason);
  }

  void _actionChanged() {
    final action = requests.learningAction.value;
    if (action == null ||
        action.requestId == _lastRequestId ||
        !matches(action.identity)) {
      return;
    }
    _lastRequestId = action.requestId;
    switch (action.action) {
      case LumoLearningAction.hint:
        _run(onHint);
      case LumoLearningAction.explain:
        _run(onExplain);
      case LumoLearningAction.repeat:
        _run(onRepeat);
      case LumoLearningAction.slower:
        _run(onSlower);
      case LumoLearningAction.stop:
        _run(onStop);
      case LumoLearningAction.proposeAnswer:
        final value = action.candidate;
        if (value != null) onProposeAnswer?.call(value);
      case LumoLearningAction.highlight:
      case LumoLearningAction.point:
      case LumoLearningAction.look:
        final id = action.objectId;
        if (id != null) onFocus?.call(id, action.action);
    }
  }

  void _cancelled() {
    final event = requests.learningCancellation.value;
    if (_disposed || event == null || event.sequence == _lastCancelSequence) {
      return;
    }
    _lastCancelSequence = event.sequence;
    if (_activeIdentity != null) _run(onCancel);
    _activeIdentity = identity;
  }

  void _run(FutureOr<void> Function() callback) {
    // All callbacks enter synchronously, before a later action can supersede
    // the captured identity. Their own I/O keeps the lesson's cancellation guard.
    final result = callback();
    if (result is Future<void>) unawaited(result);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    requests.learningAction.removeListener(_actionChanged);
    requests.learningCancellation.removeListener(_cancelled);
    _activeIdentity = null;
  }
}
