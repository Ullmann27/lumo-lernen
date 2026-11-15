// ════════════════════════════════════════════════════════════════════════
// LUMO COMPANION REQUEST BUS
// ════════════════════════════════════════════════════════════════════════
// Heinz-Auftrag: 'Tap-to-move via Parent-Listener, keine Fullscreen-
// Overlay-GestureDetector die Buttons frisst'.
//
// Architektur:
//   1. App-Shell hat ein Listener-Widget (NICHT GestureDetector).
//      Listener ist passiv - es konsumiert KEINE Pointer-Events.
//      Buttons/Cards funktionieren weiterhin normal.
//   2. Listener.onPointerDown gibt die GLOBAL-Position weiter.
//   3. App-Shell ruft requestMoveTo(globalPosition) auf.
//   4. LumoFreeCompanion lauscht auf den Notifier und laeuft hin
//      - aber nur wenn die Position in einer Safe-Zone liegt.
//   5. So bleiben Buttons komplett bedienbar und Lumo wandert frei.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/widgets.dart';
import '../../core/tutor_coordination_engine.dart';
import '../../core/learning_journey.dart';
import '../../core/learning_attempt_id.dart';
import '../../core/lumo_learning_session_contract.dart';

enum LumoInteractionKind {
  taskOpened,
  answerChecked,
  helpRequested,
  readingStarted,
  gameRequested,
  lockedGameTapped,
}

/// Explicit app actions only. No microphone, camera or pointer surveillance.
enum LumoLearningEventKind {
  taskStarted('task_started'),
  answerSubmitted('answer_submitted'),
  answerCorrect('answer_correct'),
  answerIncorrect('answer_incorrect'),
  hintRequested('hint_requested'),
  hintAccepted('hint_accepted'),
  hintDeclined('hint_declined'),
  taskRepeated('task_repeated'),
  lessonCompleted('lesson_completed'),
  childAskedQuestion('child_asked_question'),
  exploreTopicRequested('explore_topic_requested');

  const LumoLearningEventKind(this.wireName);
  final String wireName;
}

/// Short-lived local metadata. Deliberately excludes answers, task text,
/// child identity, audio, timestamps and touch coordinates.
class LumoLearningEvent {
  const LumoLearningEvent({
    required this.kind,
    required this.taskId,
    required this.subject,
    required this.unit,
    required this.attempt,
    required this.helpLevel,
  });

  final LumoLearningEventKind kind;
  final String taskId;
  final String subject;
  final String unit;
  final int attempt;
  final int helpLevel;
}

/// Local visible task. Never carries the correct answer or child identity.
class LumoCompanionTaskContext {
  const LumoCompanionTaskContext({
    required this.subject,
    required this.unit,
    required this.prompt,
    this.isExam = false,
    this.answering = true,
    this.taskId = '',
    this.attempts = 0,
    this.helpLevel = 0,
    this.lastAnswer,
    this.lastCorrect,
    this.previousHelp,
    this.localHelp,
    this.activity = 'learning',
    this.ownerSection = 'exercises',
    this.profileGeneration,
    this.stepId,
    this.objectIds = const [],
    this.explanation,
    this.errorType,
    this.answerChoices = const [],
    this.allowedActions = lumoDefaultLearningActions,
    this.isExplanation = false,
  });

  final String subject;
  final String unit;
  final String prompt;
  final bool isExam;
  final bool answering;
  final String taskId;
  final int attempts;
  final int helpLevel;
  final String? lastAnswer;
  final bool? lastCorrect;
  final String? previousHelp;
  final String? localHelp;
  final String activity;
  final String ownerSection;
  final int? profileGeneration;
  final String? stepId;
  final List<String> objectIds;
  final String? explanation;
  final String? errorType;
  final List<String> answerChoices;
  final Set<LumoLearningAction> allowedActions;
  final bool isExplanation;

  String get conversationKey =>
      jsonEncode([profileGeneration, ownerSection, taskId, subject, unit]);

  /// Republishing an unchanged snapshot does not discard useful context.
  String get semanticKey => jsonEncode([
        conversationKey, prompt, isExam, answering, attempts, helpLevel,
        lastAnswer, lastCorrect, previousHelp, localHelp, activity, stepId,
        objectIds, explanation, errorType, answerChoices,
        (allowedActions.map((action) => action.name).toList()..sort()),
        isExplanation,
      ]);

  TutorTaskScope get tutorScope => TutorTaskScope(
      generation: profileGeneration ?? 0,
      taskId: taskId,
      problemId: TutorTaskScope.problemIdentity(subject, unit, prompt),
      subject: subject,
      unit: unit,
      isExam: isExam,
      ownerSection: ownerSection);

  bool belongsTo({required String section, required int generation}) =>
      ownerSection == section &&
      (profileGeneration == null || profileGeneration == generation);
}

class LumoCompanionRequests {
  LumoCompanionRequests._() {
    taskContext.addListener(_synchronizeLearningIdentity);
  }
  static final LumoCompanionRequests instance = LumoCompanionRequests._();

  final TutorCoordinationEngine tutor = TutorCoordinationEngine();

  /// Position auf die der Companion hinwandern soll (in GLOBAL coords).
  /// Wenn null = keine aktive Anfrage. Nach Verarbeitung wieder auf null.
  final ValueNotifier<Offset?> moveTarget = ValueNotifier<Offset?>(null);

  /// Ephemeral activity only: no coordinates, child identity or progress.
  /// A touch/scroll always resets quiet pacing, even at the same position.
  final ValueNotifier<int> activity = ValueNotifier<int>(0);
  void noteActivity() => activity.value++;

  /// The active lesson handles this request in place, keeping its answer state.
  final ValueNotifier<int> helpRequested = ValueNotifier<int>(0);
  final ValueNotifier<LumoCompanionTaskContext?> taskContext =
      ValueNotifier<LumoCompanionTaskContext?>(null);

  final ValueNotifier<LumoLearningIdentity?> learningIdentity =
      ValueNotifier<LumoLearningIdentity?>(null);
  final ValueNotifier<LumoLearningActionRequest?> learningAction =
      ValueNotifier<LumoLearningActionRequest?>(null);
  final ValueNotifier<LumoLearningCancellation?> learningCancellation =
      ValueNotifier<LumoLearningCancellation?>(null);
  final ValueNotifier<LumoLearningPresentation?> learningPresentation =
      ValueNotifier<LumoLearningPresentation?>(null);
  final ValueNotifier<LumoLearningAudioFrame?> learningAudio =
      ValueNotifier<LumoLearningAudioFrame?>(null);
  String _learningSessionId = newLearningAttemptId();
  String? _semanticKey;
  String? _conversationKey;
  int? _learningProfile;
  int _learningRevision = 0;
  int _cancelEpoch = 0;
  int _actionSequence = 0;

  bool isCurrentLearningIdentity(LumoLearningIdentity identity) =>
      identity.matches(learningIdentity.value);

  void _synchronizeLearningIdentity() {
    final task = taskContext.value;
    final key = task?.semanticKey;
    if (_semanticKey == key) return;
    final scopeChanged = _conversationKey != task?.conversationKey;
    if (_learningProfile != task?.profileGeneration) {
      _learningSessionId = newLearningAttemptId();
      _learningProfile = task?.profileGeneration;
    }
    _semanticKey = key;
    _conversationKey = task?.conversationKey;
    _learningRevision++;
    _cancelEpoch++;
    learningIdentity.value = task == null || task.taskId.isEmpty
        ? null
        : LumoLearningIdentity(
            sessionId: _learningSessionId,
            taskId: task.taskId,
            revision: _learningRevision,
            cancelEpoch: _cancelEpoch,
            stepId: task.stepId,
          );
    learningAction.value = null;
    learningPresentation.value = null;
    learningAudio.value = null;
    learningCancellation.value = LumoLearningCancellation(
        sequence: ++_actionSequence,
        reason: scopeChanged ? 'task_changed' : 'context_changed',
        identity: learningIdentity.value);
  }

  /// One semantic stop cancels the old lease and its figure/audio metadata.
  /// Actual players and recognizers subscribe through their owning controller.
  void cancelLearningInteraction({String reason = 'stop'}) {
    _cancelEpoch++;
    final old = learningIdentity.value;
    final current = old == null
        ? null
        : LumoLearningIdentity(
            sessionId: old.sessionId,
            taskId: old.taskId,
            revision: old.revision,
            cancelEpoch: _cancelEpoch,
            stepId: old.stepId,
          );
    learningIdentity.value = current;
    learningPresentation.value = null;
    learningAudio.value = null;
    learningAction.value = current == null
        ? null
        : LumoLearningActionRequest(
            identity: current,
            requestId: ++_actionSequence,
            action: LumoLearningAction.stop,
          );
    learningCancellation.value = LumoLearningCancellation(
        sequence: ++_actionSequence, reason: reason, identity: current);
  }

  bool requestLearningAction(
    LumoLearningAction action, {
    required LumoLearningIdentity identity,
    int? turnId,
    String? objectId,
    String? candidate,
  }) {
    if (!isCurrentLearningIdentity(identity)) return false;
    final task = taskContext.value;
    if (task == null) return false;
    if (action == LumoLearningAction.stop) {
      cancelLearningInteraction();
      return true;
    }
    if (task.isExam || !task.allowedActions.contains(action)) return false;
    if (objectId != null && !task.objectIds.contains(objectId)) return false;
    if (const {LumoLearningAction.look, LumoLearningAction.point,
            LumoLearningAction.highlight}.contains(action) && objectId == null) {
      return false;
    }
    final answer = candidate?.trim();
    if (action == LumoLearningAction.proposeAnswer &&
        (!task.answering || answer == null || answer.isEmpty || answer.length > 160)) {
      return false;
    }
    learningAction.value = LumoLearningActionRequest(
      identity: identity,
      requestId: ++_actionSequence,
      action: action,
      turnId: turnId,
      objectId: objectId,
      candidate: action == LumoLearningAction.proposeAnswer ? answer : null,
    );
    return true;
  }

  bool publishLearningPresentation(LumoLearningPresentation presentation) {
    if (!isCurrentLearningIdentity(presentation.identity)) return false;
    final objects = taskContext.value?.objectIds ?? const <String>[];
    if ((presentation.gazeObjectId != null &&
            !objects.contains(presentation.gazeObjectId)) ||
        (presentation.pointObjectId != null &&
            !objects.contains(presentation.pointObjectId))) return false;
    learningPresentation.value = presentation;
    return true;
  }

  bool publishLearningAudio(LumoLearningAudioFrame frame) {
    if (!isCurrentLearningIdentity(frame.identity)) return false;
    learningAudio.value = frame;
    return true;
  }

  final ValueNotifier<int> appExplanationRequested = ValueNotifier<int>(0);

  /// Bounded semantic trace in RAM. Pointer coordinates remain in moveTarget
  /// only and are never copied into this trace or sent to a provider.
  final ValueNotifier<List<LumoInteractionKind>> recentInteractions =
      ValueNotifier<List<LumoInteractionKind>>([]);

  /// Same request bus, bounded in RAM. Not a second progress database and
  /// never included in the existing provider's remote context.
  final ValueNotifier<List<LumoLearningEvent>> learningEvents =
      ValueNotifier<List<LumoLearningEvent>>([]);

  void publishTask(LumoCompanionTaskContext context) {
    if (!tutor.enterTask(context.tutorScope)) return;
    final previous = taskContext.value;
    final isNew = previous?.taskId != context.taskId ||
        previous?.ownerSection != context.ownerSection ||
        previous?.profileGeneration != context.profileGeneration;
    taskContext.value = context;
    if (isNew) {
      recordInteraction(LumoInteractionKind.taskOpened);
      recordLearningEvent(LumoLearningEventKind.taskStarted, context: context);
    }
  }

  LearningEvidence? recordLearningEvent(LumoLearningEventKind kind,
      {LumoCompanionTaskContext? context}) {
    final task = context ?? taskContext.value;
    if (task != null && !tutor.matches(task.tutorScope)) return null;
    LearningEvidence? evidence;
    if (task != null) {
      switch (kind) {
        case LumoLearningEventKind.hintRequested:
          tutor.requestHelp(level: task.helpLevel);
        case LumoLearningEventKind.hintDeclined:
          tutor.declineHelp();
        case LumoLearningEventKind.answerCorrect:
        case LumoLearningEventKind.answerIncorrect:
          evidence = tutor.answer(
              attempt: task.attempts,
              correct: kind == LumoLearningEventKind.answerCorrect,
              assisted: task.helpLevel > 0);
        default:
          break;
      }
    }
    final event = LumoLearningEvent(
      kind: kind,
      taskId: task?.taskId ?? '',
      subject: task?.subject ?? '',
      unit: task?.unit ?? '',
      attempt: (task?.attempts ?? 0).clamp(0, 10000).toInt(),
      helpLevel: (task?.helpLevel ?? 0).clamp(0, 4).toInt(),
    );
    final next = [...learningEvents.value, event];
    learningEvents.value =
        List.unmodifiable(next.skip(next.length > 24 ? next.length - 24 : 0));
    return evidence;
  }

  void clearTask(LumoCompanionTaskContext? owner) {
    if (owner != null && identical(taskContext.value, owner)) {
      taskContext.value = null;
      tutor.clearTask();
    }
  }

  void clearLearningScope() {
    tutor.clearTask();
    taskContext.value = null;
    learningEvents.value = const [];
    recentInteractions.value = const [];
    if (learningIdentity.value != null) cancelLearningInteraction(reason: 'scope_cleared');
  }

  void recordInteraction(LumoInteractionKind kind) {
    final next = [...recentInteractions.value, kind];
    recentInteractions.value =
        List.unmodifiable(next.skip(next.length > 12 ? next.length - 12 : 0));
  }

  void requestTaskHelp() => helpRequested.value++;
  void requestAppExplanation() => appExplanationRequested.value++;

  /// Letzter Zeitpunkt einer Anfrage - fuer Cooldown.
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _cooldown = Duration(milliseconds: 1200);

  /// Fordere den Companion an, zu einer Position zu wandern.
  /// Globale Position (vom Listener.onPointerDown).
  /// Mit eingebautem Cooldown damit Kinder nicht spammen koennen.
  void requestMoveTo(Offset globalPosition) {
    final now = DateTime.now();
    if (now.difference(_lastRequest) < _cooldown) return;
    _lastRequest = now;
    moveTarget.value = globalPosition;
  }

  /// Companion ruft dies nach Verarbeitung auf - setzt Target zurueck.
  void clearRequest() {
    moveTarget.value = null;
  }
}
