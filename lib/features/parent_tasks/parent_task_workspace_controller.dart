import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';
import '../../core/parent_task_repository.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/learning/parent_authored_task.dart';
import '../../domain/learning/reward_engine.dart';
import '../../domain/school/attempt.dart';
import '../learning/renderers/adaptive_task_renderer.dart';

/// One profile-bound adapter for editor, Home and the real exercise renderer.
/// Only standard AttemptLog and RewardEngine/Wallet handle accepted results.
class ParentTaskWorkspaceController extends ChangeNotifier {
  ParentTaskWorkspaceController(this.appState) {
    appState.addListener(_profileChanged);
    ParentTaskRepository.changes.addListener(_tasksChanged);
    _profileChanged();
  }

  final LumoAppState appState;
  LearningProfileLease? lease;
  ParentTaskRepository? _repository;
  ParentTaskWorkspace? workspace;
  String profileName = '';
  String? error;
  bool loading = true;
  bool busy = false;
  bool _disposed = false;
  int _loadRevision = 0;
  int _generation = -1;
  bool _wasResetting = false;
  final Map<String, ParentTaskAttempt> _pendingAnswers = {};

  bool get current => lease != null && appState.isCurrentLearningLease(lease!);
  bool get ready => current && !loading && !busy && workspace != null;
  ParentTaskAttempt? get activeAttempt => current
      ? _pendingAnswers[lease!.studentId] ?? workspace?.activeAttempt
      : null;
  bool get hasPendingResult =>
      activeAttempt?.answered == true && activeAttempt?.completed == false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _profileChanged() {
    if (_generation == appState.profileGeneration &&
        _wasResetting == appState.resetting) {
      return;
    }
    _generation = appState.profileGeneration;
    _wasResetting = appState.resetting;
    // Clear synchronously: not even one frame may show the other child's text.
    lease = null;
    workspace = null;
    _repository = null;
    profileName = '';
    error = null;
    _loadRevision++;
    if (appState.resetting) {
      _pendingAnswers.clear();
      loading = true;
      _notify();
      return;
    }
    unawaited(reload());
  }

  void _tasksChanged() {
    if (!busy &&
        lease != null &&
        ParentTaskRepository.changes.value == lease!.studentId) {
      unawaited(reload());
    }
  }

  Future<void> reload() async {
    final revision = ++_loadRevision;
    loading = true;
    error = null;
    _notify();
    try {
      final owner = await appState.captureLearningProfile();
      await appState.prepareLearningLease(owner);
      final repository = ParentTaskRepository(
          studentId: owner.studentId,
          mayWrite: () => appState.canUseLearningLease(owner));
      final data = await repository.load();
      final name = await appState.school.studentName(owner.studentId);
      if (_disposed ||
          revision != _loadRevision ||
          !appState.isCurrentLearningLease(owner)) {
        return;
      }
      lease = owner;
      _repository = repository;
      workspace = data;
      profileName = name ??
          (owner.logStudentId == 'self'
              ? appState.state.childName
              : 'dieses Kinderprofil');
    } catch (failure) {
      if (_disposed || revision != _loadRevision) return;
      error = _message(failure);
    } finally {
      if (!_disposed && revision == _loadRevision) {
        loading = false;
        _notify();
      }
    }
  }

  Future<bool> _operate(
      Future<ParentTaskWorkspace> Function(
              LearningProfileLease, ParentTaskRepository)
          operation) async {
    if (!ready) return false;
    final owner = lease!;
    final repository = _repository!;
    final action = appState.beginLearningAction();
    busy = true;
    error = null;
    _notify();
    try {
      final actionOwner = await action.resolve();
      if (actionOwner.studentId != owner.studentId || action.invalidated) {
        throw StateError(
            'Das Kinderprofil wurde gewechselt. Bitte erneut öffnen.');
      }
      final data = await operation(owner, repository);
      if (!_disposed && appState.isCurrentLearningLease(owner)) {
        workspace = data;
      }
      return true;
    } catch (failure) {
      if (!_disposed && appState.isCurrentLearningLease(owner)) {
        error = _message(failure);
      }
      return false;
    } finally {
      action.close();
      busy = false;
      _notify();
    }
  }

  Future<bool> save(ParentTaskDraft draft, {ParentAuthoredTask? previous}) =>
      _operate(
          (owner, repository) => repository.save(draft, previous: previous));

  Future<bool> remove(ParentAuthoredTask task) =>
      _operate((owner, repository) => repository.remove(task));

  Future<bool> start(String taskId) =>
      _operate((owner, repository) => repository.begin(taskId));

  Future<bool> leaveAttempt() {
    final active = activeAttempt;
    if (active == null || hasPendingResult) return Future.value(false);
    return _operate((owner, repository) => repository.leaveAttempt(active.id));
  }

  Future<bool> answer(AdaptiveTaskAnswer value) {
    final active = activeAttempt;
    if (!ready ||
        active == null ||
        active.answered ||
        value.task.taskInstanceId != active.id ||
        value.task.childId != lease!.studentId ||
        !active.task.content.options.contains('${value.answer}')) {
      return Future.value(false);
    }
    final now = DateTime.now().toUtc();
    final duration =
        now.difference(active.startedAt).inMilliseconds.clamp(0, 86400000);
    // Correctness is supplied by AdaptiveTaskRenderer, exactly as in lessons.
    final reward = const RewardEngine().calculateAnswerReward(
        result: TaskResult(
            taskInstanceId: active.id,
            childId: active.task.studentId,
            skillId: value.task.skillId,
            correct: value.correct,
            helpUsed: value.hintUsed,
            responseTimeMs: duration));
    final accepted = ParentTaskAttempt(
        id: active.id,
        task: active.task,
        startedAt: active.startedAt,
        answer: '${value.answer}',
        correct: value.correct,
        hintUsed: value.hintUsed,
        answeredAt: now,
        durationMs: duration,
        stars: reward.stars,
        xp: reward.xp);
    _pendingAnswers[lease!.studentId] = accepted;
    return _operate((owner, repository) async {
      final saved = await repository.accept(accepted);
      _pendingAnswers.remove(owner.studentId);
      if (!_disposed && appState.isCurrentLearningLease(owner)) {
        workspace = saved;
      }
      return _finish(owner, repository, saved.activeAttempt!);
    });
  }

  Future<bool> retryResult() {
    final attempt = activeAttempt;
    if (attempt == null || !attempt.answered || attempt.completed) {
      return Future.value(false);
    }
    return _operate((owner, repository) async {
      final saved = await repository.accept(attempt);
      _pendingAnswers.remove(owner.studentId);
      if (!_disposed && appState.isCurrentLearningLease(owner)) {
        workspace = saved;
      }
      return _finish(owner, repository, saved.activeAttempt!);
    });
  }

  Future<ParentTaskWorkspace> _finish(LearningProfileLease owner,
      ParentTaskRepository repository, ParentTaskAttempt attempt) async {
    if (attempt.completed) return repository.load();
    if (!appState.isCurrentLearningLease(owner)) {
      throw StateError(
          'Das Ergebnis wird beim Öffnen dieses Kinderprofils fortgesetzt.');
    }
    await appState.attemptLog.append(Attempt(
      id: attempt.id,
      studentId: owner.logStudentId,
      subject: 'Elternaufgaben',
      unit: '${parentTaskSubjectLabel(attempt.task.content.subject)} · '
          'Klasse ${attempt.task.content.grade}',
      competency: 'Elternaufgabe',
      correct: attempt.correct!,
      at: attempt.answeredAt!,
      hintUsed: attempt.hintUsed,
      prompt: attempt.task.content.prompt,
      given: attempt.answer!,
      expected: attempt.task.content.correctAnswer,
      durationMs: attempt.durationMs,
      score: attempt.correct! ? 1 : 0,
    ));
    await appState.awardParentTaskResult(
        lease: owner,
        resultId: attempt.id,
        stars: attempt.stars,
        xp: attempt.xp);
    return repository.complete(attempt.id);
  }

  static String _message(Object failure) => switch (failure) {
        FormatException() => failure.message,
        StateError() => failure.message,
        _ => 'Speichern ist gerade nicht möglich. Bitte erneut versuchen.',
      };

  @override
  void dispose() {
    _disposed = true;
    _loadRevision++;
    appState.removeListener(_profileChanged);
    ParentTaskRepository.changes.removeListener(_tasksChanged);
    super.dispose();
  }
}
