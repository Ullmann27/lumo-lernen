import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';
import '../../core/recognized_task_repository.dart';
import '../../domain/learning/recognized_task.dart';
import '../../domain/school/attempt.dart';
import '../learning/renderers/adaptive_task_renderer.dart';

class RecognizedTaskController extends ChangeNotifier {
  RecognizedTaskController(this.appState) {
    appState.addListener(_profileChanged);
    _profileChanged();
  }
  final LumoAppState appState;
  LearningProfileLease? lease;
  RecognizedTaskRepository? _repository;
  RecognizedTaskAttempt? _saved;
  final Map<String, RecognizedTaskAttempt> _pending = {};
  RecognizedTask? preview;
  String? error;
  bool loading = true, busy = false;
  int _generation = -1, _loadRevision = 0;
  bool _wasResetting = false, _disposed = false;

  bool get current => lease != null && appState.isCurrentLearningLease(lease!);
  bool get ready => current && !loading && !busy && _repository != null;
  RecognizedTaskAttempt? get active =>
      current ? _pending[lease!.studentId] ?? _saved : null;
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
    lease = null;
    _repository = null;
    _saved = null;
    preview = null;
    error = null;
    loading = true;
    _loadRevision++;
    _notify();
    if (appState.resetting) {
      _pending.clear();
      return;
    }
    unawaited(reload());
  }

  Future<void> reload() async {
    final revision = ++_loadRevision;
    loading = true;
    error = null;
    _notify();
    try {
      final owner = await appState.captureLearningProfile();
      await appState.prepareLearningLease(owner);
      final repository = RecognizedTaskRepository(
          ownerId: owner.studentId,
          mayWrite: () => appState.canUseLearningLease(owner));
      final saved = await repository.load();
      if (_disposed ||
          revision != _loadRevision ||
          !appState.isCurrentLearningLease(owner)) {
        return;
      }
      lease = owner;
      _repository = repository;
      _saved = saved;
    } catch (failure) {
      if (!_disposed && revision == _loadRevision) error = _message(failure);
    } finally {
      if (!_disposed && revision == _loadRevision) {
        loading = false;
        _notify();
      }
    }
  }

  void inputChanged() {
    if (preview == null && error == null) return;
    preview = null;
    error = null;
    _notify();
  }

  bool recognize(String input) {
    if (!ready || active != null) return false;
    preview = null;
    error = null;
    try {
      preview = RecognizedTask.parse(input);
    } catch (failure) {
      error = _message(failure);
    }
    _notify();
    return preview != null;
  }

  Future<bool> _operate(
      Future<RecognizedTaskAttempt?> Function(
              LearningProfileLease, RecognizedTaskRepository)
          operation) async {
    if (!ready) return false;
    final owner = lease!, repository = _repository!;
    final action = appState.beginLearningAction();
    busy = true;
    error = null;
    _notify();
    try {
      final acceptedOwner = await action.resolve();
      if (acceptedOwner.studentId != owner.studentId || action.invalidated) {
        throw StateError(
            'Das Kinderprofil wurde gewechselt. Bitte erneut öffnen.');
      }
      final saved = await operation(owner, repository);
      if (!_disposed && appState.isCurrentLearningLease(owner)) {
        _saved = saved;
        preview = null;
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

  Future<bool> startPreview() {
    final task = preview;
    if (task == null || active != null) return Future.value(false);
    return _operate((owner, repository) => repository.begin(task));
  }

  Future<bool> answer(AdaptiveTaskAnswer value) {
    final attempt = active;
    if (!ready ||
        attempt == null ||
        attempt.answered ||
        value.task.taskInstanceId != attempt.id ||
        value.task.childId != attempt.ownerId ||
        value.task.prompt != attempt.task.prompt ||
        !attempt.task.options.contains('${value.answer}') ||
        value.correct != ('${value.answer}' == attempt.task.answer)) {
      return Future.value(false);
    }
    final accepted =
        attempt.accept('${value.answer}', hintUsed: value.hintUsed);
    _pending[attempt.ownerId] = accepted;
    return _operate((owner, repository) async {
      final saved = (await repository.accept(accepted))!;
      _pending.remove(owner.studentId);
      if (!_disposed && appState.isCurrentLearningLease(owner)) _saved = saved;
      return _finish(owner, repository, saved);
    });
  }

  Future<bool> retryResult() {
    final attempt = active;
    if (attempt == null || !attempt.answered || attempt.completed) {
      return Future.value(false);
    }
    return _operate((owner, repository) async {
      final saved = (await repository.accept(attempt))!;
      _pending.remove(owner.studentId);
      if (!_disposed && appState.isCurrentLearningLease(owner)) _saved = saved;
      return _finish(owner, repository, saved);
    });
  }

  Future<RecognizedTaskAttempt?> _finish(
      LearningProfileLease owner,
      RecognizedTaskRepository repository,
      RecognizedTaskAttempt attempt) async {
    if (attempt.completed) return repository.load();
    if (!appState.isCurrentLearningLease(owner)) {
      throw StateError(
          'Dieses Ergebnis wird beim Öffnen seines Kinderprofils fortgesetzt.');
    }
    await appState.attemptLog.append(Attempt(
        id: attempt.id,
        studentId: owner.logStudentId,
        subject: 'Eigene Textaufgaben',
        unit: attempt.task.label,
        competency: 'Freie Texteingabe',
        correct: attempt.correct,
        at: attempt.answeredAt!,
        hintUsed: attempt.hintUsed,
        prompt: attempt.task.prompt,
        given: attempt.answer!,
        expected: attempt.task.answer,
        durationMs: attempt.durationMs,
        score: attempt.correct ? 1 : 0));
    await appState.awardRecognizedTaskResult(
        lease: owner,
        resultId: attempt.id,
        stars: attempt.stars,
        xp: attempt.xp);
    return repository.complete(attempt.id);
  }

  Future<bool> leave() {
    final attempt = active;
    if (attempt == null || (attempt.answered && !attempt.completed)) {
      return Future.value(false);
    }
    return _operate((owner, repository) => repository.leave(attempt.id));
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
    super.dispose();
  }
}
