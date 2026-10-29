import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'learning_attempt_id.dart';
import 'learning_journey.dart';
import '../domain/learning_intelligence/lesson_scene_engine.dart';

/// Local task scope. Generation is a session token, never a child's name.
class TutorTaskScope {
  const TutorTaskScope(
      {required this.generation,
      required this.taskId,
      required this.problemId,
      required this.subject,
      required this.unit,
      this.isExam = false,
      this.ownerSection = 'exercises'});
  final int generation;
  final String taskId;
  final String problemId;
  final String subject;
  final String unit;
  final bool isExam;
  final String ownerSection;

  static String problemIdentity(String subject, String unit, String prompt) =>
      'problem-${sha256.convert(utf8.encode(jsonEncode([
            subject,
            unit,
            prompt
          ])))}';
}

enum TutorEventKind {
  taskOpened,
  helpOffered,
  helpAccepted,
  helpDeclined,
  answerIncorrect,
  assistedSuccess,
  independentSuccess,
  transferChecked
}

/// Bounded semantic trace only: no answers, prompts, names, audio or touches.
class TutorEvent {
  const TutorEvent(this.kind, this.helpLevel);
  final TutorEventKind kind;
  final int helpLevel;
}

/// Deterministic orchestration shared by the real task/companion request bus.
/// It never speaks, accesses a microphone, calls an API or grants rewards.
class TutorCoordinationEngine {
  int? _generation;
  TutorTaskScope? _scope;
  int _mistakes = 0;
  int _helpLevel = 0;
  bool _resolvedOffer = false;
  bool _solved = false;
  final Set<int> _attempts = {};
  final Set<String> _transfers = {};
  final List<TutorEvent> _events = [];

  TutorTaskScope? get scope => _scope;
  int get mistakes => _mistakes;
  int get helpLevel => _helpLevel;
  bool get shouldOffer =>
      _scope != null &&
      !_scope!.isExam &&
      !_solved &&
      !_resolvedOffer &&
      _mistakes >= 2;
  List<TutorEvent> get events => List.unmodifiable(_events);

  void activateProfile(int generation) {
    if (_generation == generation) return;
    _generation = generation;
    clearTask();
    _events.clear();
  }

  void clearTask() {
    _scope = null;
    _mistakes = 0;
    _helpLevel = 0;
    _resolvedOffer = false;
    _solved = false;
    _attempts.clear();
    _transfers.clear();
  }

  bool matches(TutorTaskScope task) =>
      _scope != null &&
      _generation == task.generation &&
      _scope!.generation == task.generation &&
      _scope!.taskId == task.taskId &&
      _scope!.ownerSection == task.ownerSection &&
      _scope!.isExam == task.isExam;

  bool enterTask(TutorTaskScope task) {
    if (task.taskId.trim().isEmpty ||
        task.problemId.trim().isEmpty ||
        (_generation != null && task.generation != _generation)) return false;
    _generation ??= task.generation;
    if (matches(task)) return true;
    clearTask();
    _scope = task;
    _emit(TutorEventKind.taskOpened);
    return true;
  }

  /// Levels select TaskHintService's different explanation methods. Explicit
  /// requests alone advance them; unsuccessful answers do not reveal help.
  int? requestHelp({int? level}) {
    if (_scope == null || _scope!.isExam || _solved) return null;
    _helpLevel = (level ?? _helpLevel + 1).clamp(1, 3);
    _resolvedOffer = true;
    _emit(TutorEventKind.helpAccepted);
    return _helpLevel;
  }

  void declineHelp() {
    _resolvedOffer = true;
    _emit(TutorEventKind.helpDeclined);
  }

  LearningEvidence? answer(
      {required int attempt,
      required bool correct,
      bool assisted = false,
      String? errorTag}) {
    final task = _scope;
    if (task == null || _solved || attempt < 1 || !_attempts.add(attempt))
      return null;
    if (assisted && !task.isExam && _helpLevel == 0) _helpLevel = 1;
    if (correct) {
      _solved = true;
      _emit(_helpLevel > 0
          ? TutorEventKind.assistedSuccess
          : TutorEventKind.independentSuccess);
    } else {
      _mistakes++;
      _emit(TutorEventKind.answerIncorrect);
      if (shouldOffer && _mistakes == 2) _emit(TutorEventKind.helpOffered);
    }
    return LearningEvidence(
        taskId: newLearningAttemptId(),
        problemId: task.problemId,
        correct: correct,
        helpLevel: task.isExam ? 0 : _helpLevel,
        errorTag: errorTag);
  }

  /// Only a different, actually assessed construction + comprehension check
  /// qualifies. Counting or viewing the worked example never calls this.
  @Deprecated('Use checkSceneTransfer with a validated scoped receipt')
  LearningEvidence? checkTransfer(
      {required String problemId,
      required bool correct,
      required bool independent}) {
    final task = _scope;
    if (task == null ||
        task.isExam ||
        _helpLevel == 0 ||
        problemId == task.problemId ||
        !_transfers.add(problemId)) return null;
    _emit(TutorEventKind.transferChecked);
    return LearningEvidence(
        taskId: newLearningAttemptId(),
        problemId: problemId,
        correct: correct,
        helpLevel: 3,
        transferCheck: false);
  }

  LearningEvidence? checkSceneTransfer(SceneCompletion proof) {
    final task = _scope;
    if (task == null ||
        task.isExam ||
        _helpLevel == 0 ||
        proof.sourceProblemId != task.problemId ||
        proof.sourceTaskId != task.taskId ||
        proof.generation != task.generation ||
        proof.number == proof.sourceNumber ||
        !_transfers.add(proof.evidence.problemId!)) return null;
    _emit(TutorEventKind.transferChecked);
    return proof.evidence;
  }

  void _emit(TutorEventKind kind) {
    _events.add(TutorEvent(kind, _helpLevel));
    if (_events.length > 24) _events.removeAt(0);
  }
}
