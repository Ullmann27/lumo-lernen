import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/daily_mission_repository.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _base = 'lumo_daily_mission_v1';

class _RejectMissionStore extends InMemorySharedPreferencesStore {
  _RejectMissionStore() : super.withData({});
  bool reject = false;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (reject && key.contains(_base)) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  DailyMissionRepository repository([String child = 'child-a']) =>
      DailyMissionRepository(studentId: child, now: () => now);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 23, 12);
  });

  test('creates a durable twelve-task mission without modifying school progress',
      () async {
    SharedPreferences.setMockInitialValues({'lumo_progress_daily': 'legacy'});
    final mission = await repository().load();
    expect(mission.dayKey, '2026-10-23');
    expect(mission.stations.map((station) => station.subject),
        ['Mathematik', 'Deutsch', 'Englisch']);
    expect(mission.stations.map((station) => station.target), [4, 4, 4]);
    expect(mission.completedCount, 0);
    expect(mission.targetCount, 12);
    expect(mission.isComplete, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_progress_daily'), 'legacy');
    expect((await repository().load()).dayKey, '2026-10-23');
  });

  test('only assessed correct answers count and each station must be completed',
      () async {
    final repo = repository();
    await repo.load(tasksPerStation: 2);
    await repo.recordAnswer(
        taskId: 'wrong', subject: 'Mathematik', correct: false);
    await repo.recordAnswer(
        taskId: 'unrelated', subject: 'Logik', correct: true);
    for (var i = 0; i < 6; i++) {
      await repo.recordAnswer(
          taskId: 'math-$i', subject: 'Mathematik', correct: true);
    }
    final mathOnly = await repo.load();
    expect(mathOnly.completedCount, 2);
    expect(mathOnly.isComplete, isFalse);
    for (final subject in ['Deutsch', 'Englisch']) {
      for (var i = 0; i < 2; i++) {
        await repo.recordAnswer(
            taskId: '$subject-$i', subject: subject, correct: true);
      }
    }
    final finished = await repo.load();
    expect(finished.completedCount, 6);
    expect(finished.isComplete, isTrue);
  });

  test('a corrected answer may finish the same task after a wrong attempt',
      () async {
    final repo = repository();
    await repo.recordAnswer(
        taskId: 'same-task', subject: 'Deutsch', correct: false);
    final corrected = await repo.recordAnswer(
        taskId: 'same-task', subject: 'Deutsch', correct: true);
    expect(corrected.completedCount, 1);
  });

  test('accepted IDs cannot count again after restart or day rotation', () async {
    await repository().recordAnswer(
        taskId: 'stable-1', subject: 'Mathematik', correct: true);
    final duplicate = await repository().recordAnswer(
        taskId: 'stable-1', subject: 'Deutsch', correct: true);
    expect(duplicate.completedCount, 1);
    now = DateTime.utc(2026, 10, 24, 12);
    final tomorrow = await repository().recordAnswer(
        taskId: 'stable-1', subject: 'Mathematik', correct: true);
    expect(tomorrow.dayKey, '2026-10-24');
    expect(tomorrow.completedCount, 0);
    expect(tomorrow.stations.last.subject, 'Sachunterricht');
  });

  test('a correct task beyond a full station cannot be replayed tomorrow',
      () async {
    final repo = repository();
    await repo.load(tasksPerStation: 2);
    for (var i = 0; i < 3; i++) {
      await repo.recordAnswer(
          taskId: 'math-$i', subject: 'Mathematik', correct: true);
    }
    now = now.add(const Duration(days: 1));
    final replay = await repository().recordAnswer(
        taskId: 'math-2', subject: 'Mathematik', correct: true);
    expect(replay.completedCount, 0);
  });

  test('profiles keep missions and duplicate identities separate', () async {
    await repository().recordAnswer(
        taskId: 'shared-task', subject: 'Deutsch', correct: true);
    expect((await repository('child-b').load()).completedCount, 0);
    expect(
        (await repository('child-b').recordAnswer(
                taskId: 'shared-task', subject: 'Deutsch', correct: true))
            .completedCount,
        1);
    expect((await repository().load()).completedCount, 1);
  });

  test('a clock rollback preserves the day and refuses new task credit', () async {
    final repo = repository();
    await repo.recordAnswer(
        taskId: 'first', subject: 'Mathematik', correct: true);
    now = DateTime.utc(2026, 10, 22, 12);
    final rolledBack = await repository().recordAnswer(
        taskId: 'blocked', subject: 'Deutsch', correct: true);
    expect(rolledBack.dayKey, '2026-10-23');
    expect(rolledBack.completedCount, 1);
    expect(rolledBack.clockUncertain, isTrue);
    now = DateTime.utc(2026, 10, 23, 12, 1);
    final caughtUp = await repository().recordAnswer(
        taskId: 'blocked', subject: 'Deutsch', correct: true);
    expect(caughtUp.clockUncertain, isFalse);
    expect(caughtUp.completedCount, 2);
  });

  test('a target change takes effect on the next day, preserving today', () async {
    final repo = repository();
    await repo.load(tasksPerStation: 4);
    expect((await repo.load(tasksPerStation: 2)).targetCount, 12);
    now = now.add(const Duration(days: 1));
    expect((await repo.load(tasksPerStation: 2)).targetCount, 6);
  });

  test('two repository instances cannot overwrite concurrent accepted answers',
      () async {
    await Future.wait([
      repository().recordAnswer(
          taskId: 'one', subject: 'Mathematik', correct: true),
      repository().recordAnswer(
          taskId: 'two', subject: 'Deutsch', correct: true),
    ]);
    expect((await repository().load()).completedCount, 2);
  });

  test('a rejected write remains retryable without duplicate credit', () async {
    final store = _RejectMissionStore();
    SharedPreferencesStorePlatform.instance = store;
    final repo = repository();
    await repo.load();
    store.reject = true;
    await expectLater(
        repo.recordAnswer(
            taskId: 'retry', subject: 'Deutsch', correct: true),
        throwsStateError);
    store.reject = false;
    expect((await repository().load()).completedCount, 0);
    await repo.recordAnswer(
        taskId: 'retry', subject: 'Deutsch', correct: true);
    expect(
        (await repository().recordAnswer(
                taskId: 'retry', subject: 'Deutsch', correct: true))
            .completedCount,
        1);
  });

  for (final raw in ['not-json', '{"version":99}', '{"version":1}']) {
    test('unreadable or unsupported saved bytes remain intact: $raw', () async {
      final key = LearningDataNamespace.keyFor(_base, 'child-a');
      SharedPreferences.setMockInitialValues({key: raw});
      await expectLater(repository().load(), throwsFormatException);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), raw);
    });
  }

  test('invalid task identities cannot mutate persisted mission data', () async {
    final repo = repository();
    await repo.load();
    final prefs = await SharedPreferences.getInstance();
    final key = LearningDataNamespace.keyFor(_base, 'child-a');
    final before = prefs.getString(key);
    for (final id in ['', 'raw answer with spaces', 'x' * 161]) {
      await expectLater(
          repo.recordAnswer(taskId: id, subject: 'Deutsch', correct: true),
          throwsArgumentError);
    }
    expect(prefs.getString(key), before);
    expect(jsonDecode(before!)['version'], 1);
  });

  test('a non-integer schema version is preserved instead of normalized',
      () async {
    await repository().load();
    final prefs = await SharedPreferences.getInstance();
    final key = LearningDataNamespace.keyFor(_base, 'child-a');
    final changed = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
    changed['version'] = 1.0;
    final raw = jsonEncode(changed);
    await prefs.setString(key, raw);
    await expectLater(repository().load(), throwsFormatException);
    expect(prefs.getString(key), raw);
  });

  test('full evidence history fails closed without evicting replay identities',
      () async {
    await repository().load();
    final prefs = await SharedPreferences.getInstance();
    final key = LearningDataNamespace.keyFor(_base, 'child-a');
    final changed = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
    changed['acceptedTaskIds'] = [
      for (var i = 0; i < 50000; i++) i.toRadixString(16).padLeft(64, '0'),
    ];
    final raw = jsonEncode(changed);
    await prefs.setString(key, raw);
    await expectLater(
        repository().recordAnswer(
            taskId: 'capacity', subject: 'Mathematik', correct: true),
        throwsStateError);
    expect(prefs.getString(key), raw);
  });
}
