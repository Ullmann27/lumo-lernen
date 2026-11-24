import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/parent_task_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/learning/parent_authored_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

ParentTaskDraft _draft(
        {String question = 'Was ergibt zwei plus drei?',
        List<String> options = const ['5', '4', '6'],
        String correct = '5'}) =>
    ParentTaskDraft(
        subject: LearningSubject.mathematik,
        grade: 1,
        prompt: question,
        correctAnswer: correct,
        options: options,
        explanation: 'Zwei und drei zusammen sind fünf.');

ParentTaskAttempt _accepted(ParentTaskAttempt active,
        {String answer = '5', bool correct = true}) =>
    ParentTaskAttempt(
      id: active.id,
      task: active.task,
      startedAt: active.startedAt,
      answer: answer,
      correct: correct,
      answeredAt: DateTime.now().toUtc(),
      durationMs: 4200,
      stars: correct ? 6 : 0,
      xp: correct ? 25 : 0,
    );

class _RejectTaskStore extends InMemorySharedPreferencesStore {
  _RejectTaskStore() : super.withData({});
  bool reject = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (reject && key.contains(ParentTaskRepository.storageBase)) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'accepts only 2–6 distinct options including the explicit correct answer',
      () {
    expect(() => _draft(options: ['5']), throwsFormatException);
    expect(() => _draft(options: ['1', '2', '3', '4', '5', '6', '7']),
        throwsFormatException);
    expect(() => _draft(options: ['5', ' 5 ']), throwsFormatException);
    expect(() => _draft(options: ['5', 'x  y', 'x y']), throwsFormatException);
    expect(() => _draft(options: ['4', '6']), throwsFormatException);
    expect(() => _draft(question: '  '), throwsFormatException);
    expect(
        () => ParentTaskDraft(
            subject: LearningSubject.deutsch,
            grade: 5,
            prompt: 'Wort?',
            correctAnswer: 'Haus',
            options: ['Haus', 'haus']),
        throwsFormatException);
    // Case differences can be the point of a spelling question.
    expect(_draft(options: ['Haus', 'haus'], correct: 'Haus').options,
        ['Haus', 'haus']);
    expect(_draft(options: ['1', '2', '3', '4', '5', '6']).options.length, 6);
  });

  test('create, restart, edit and remove preserve stable owner-bound identity',
      () async {
    final first = ParentTaskRepository(studentId: 'child-a');
    final created = (await first.save(_draft())).tasks.single;
    final restored = ParentTaskRepository(studentId: 'child-a');
    expect((await restored.load()).tasks.single.toJson(), created.toJson());
    final changed = (await restored
            .save(_draft(question: 'Wie viel ist 2 + 3?'), previous: created))
        .tasks
        .single;
    expect(changed.id, created.id);
    expect(changed.createdAt, created.createdAt);
    expect(changed.revision, 2);
    expect(changed.content.prompt, 'Wie viel ist 2 + 3?');
    await restored.remove(changed);
    expect((await first.load()).tasks, isEmpty);
  });

  test('profiles stay isolated and stale/foreign edits never overwrite',
      () async {
    final a = ParentTaskRepository(studentId: 'child-a');
    final b = ParentTaskRepository(studentId: 'child-b');
    final task = (await a.save(_draft())).tasks.single;
    expect((await b.load()).hasChildContent, isFalse);
    await expectLater(b.save(_draft(), previous: task), throwsStateError);
    await a.save(_draft(question: 'Neue Frage'), previous: task);
    await expectLater(
        a.save(_draft(question: 'Veraltete Frage'), previous: task),
        throwsStateError);
    await expectLater(a.remove(task), throwsStateError);
    expect((await a.load()).tasks.single.content.prompt, 'Neue Frage');
  });

  test('concurrent repository instances merge additions instead of losing one',
      () async {
    final a = ParentTaskRepository(studentId: 'child-a');
    final b = ParentTaskRepository(studentId: 'child-a');
    await Future.wait([
      a.save(_draft(question: 'Erste Frage')),
      b.save(_draft(question: 'Zweite Frage'))
    ]);
    expect((await a.load()).tasks.map((task) => task.content.prompt),
        ['Erste Frage', 'Zweite Frage']);
  });

  test('unreadable and newer data is preserved on reads and attempted writes',
      () async {
    final repo = ParentTaskRepository(studentId: 'child-a');
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      '{broken',
      jsonEncode({'version': 99, 'studentId': 'child-a', 'tasks': []})
    ]) {
      await prefs.setString(repo.storageKey, raw);
      await expectLater(repo.load(), throwsFormatException);
      await expectLater(repo.save(_draft()), throwsFormatException);
      expect(prefs.getString(repo.storageKey), raw);
    }
  });

  test('begun attempt and authored snapshot survive edits and restart',
      () async {
    final repo = ParentTaskRepository(studentId: 'child-a');
    final task = (await repo.save(_draft())).tasks.single;
    final started = (await repo.begin(task.id)).activeAttempt!;
    await repo.save(_draft(question: 'Eine spätere Frage'), previous: task);
    final resumed = (await ParentTaskRepository(studentId: 'child-a').load())
        .activeAttempt!;
    expect(resumed.toJson(), started.toJson());
    final first = resumed.task
        .toTaskInstance(attemptId: resumed.id, startedAt: resumed.startedAt);
    final second = resumed.task
        .toTaskInstance(attemptId: resumed.id, startedAt: resumed.startedAt);
    expect(first.prompt, task.content.prompt);
    expect(first.options.map((option) => option.label),
        second.options.map((option) => option.label));
    expect(
        first.options
            .where((option) => option.payload == first.correctAnswer)
            .length,
        1);
    expect(first.parameters['source'], 'parent');
  });

  test(
      'first accepted answer cannot be overwritten or discarded before completion',
      () async {
    final repo = ParentTaskRepository(studentId: 'child-a');
    final task = (await repo.save(_draft())).tasks.single;
    final active = (await repo.begin(task.id)).activeAttempt!;
    await repo.accept(_accepted(active));
    final duplicate =
        await repo.accept(_accepted(active, answer: '4', correct: false));
    expect(duplicate.activeAttempt!.answer, '5');
    await expectLater(repo.leaveAttempt(active.id), throwsStateError);
    await repo.remove(task);
    expect((await repo.load()).activeAttempt!.task.id, task.id);
    await repo.complete(active.id);
    await repo.leaveAttempt(active.id);
    expect((await repo.load()).hasChildContent, isFalse);
  });

  test('explicit next round has new ID while repeat begin keeps current ID',
      () async {
    final repo = ParentTaskRepository(studentId: 'child-a');
    final task = (await repo.save(_draft())).tasks.single;
    final active = (await repo.begin(task.id)).activeAttempt!;
    expect((await repo.begin(task.id)).activeAttempt!.id, active.id);
    await repo.accept(_accepted(active));
    await repo.complete(active.id);
    expect((await repo.begin(task.id)).activeAttempt!.id, active.id);
    await repo.leaveAttempt(active.id);
    expect((await repo.begin(task.id)).activeAttempt!.id, isNot(active.id));
  });

  test('deleting an unanswered task removes its resumable presentation',
      () async {
    final repo = ParentTaskRepository(studentId: 'child-a');
    final task = (await repo.save(_draft())).tasks.single;
    await repo.begin(task.id);
    await repo.remove(task);
    expect((await repo.load()).hasChildContent, isFalse);
  });

  test(
      'failed write keeps prior durable content and invalidated leases cannot write',
      () async {
    final store = _RejectTaskStore();
    SharedPreferencesStorePlatform.instance = store;
    var allowed = true;
    final repo =
        ParentTaskRepository(studentId: 'child-a', mayWrite: () => allowed);
    final initial = await repo.save(_draft());
    store.reject = true;
    await expectLater(
        repo.save(_draft(question: 'Nicht gespeichert')), throwsStateError);
    expect((await repo.load()).toJson(), initial.toJson());
    store.reject = false;
    allowed = false;
    await expectLater(repo.save(_draft()), throwsStateError);
    expect((await repo.load()).tasks.length, 1);
  });
}
