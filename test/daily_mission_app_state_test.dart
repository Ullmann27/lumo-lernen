import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/core/daily_mission_repository.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RejectStore extends InMemorySharedPreferencesStore {
  _RejectStore() : super.withData({});
  String? rejectedKey;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (rejectedKey != null && key.contains(rejectedKey!)) return false;
    return super.setValue(type, key, value);
  }
}

class _DelayedMission extends DailyMissionRepository {
  _DelayedMission(String id) : super(studentId: id);
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<DailyMissionSnapshot> load({int tasksPerStation = 4}) async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return super.load(tasksPerStation: tasksPerStation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mission requirement defaults off and settings survive a restart', () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    expect(app.canPlayToday, isTrue);
    expect(const AppSettings().requireDailyMissionForGames, isFalse);
    expect(const AppSettings().missionTasksPerStation, 4);
    await SettingsRepository.save(const AppSettings(
        requireDailyMissionForGames: true, missionTasksPerStation: 2));
    final restored = await SettingsRepository.load();
    expect(restored.requireDailyMissionForGames, isTrue);
    expect(restored.missionTasksPerStation, 2);
    expect(restored.dailyGoal, 3);
  });

  test('only explicit assessed task IDs enter the visible mission', () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.loadDailyMission();
    await app.recordLearningAnswer(
        subject: 'Mathematik', unit: 'Plus', correct: true);
    await app.recordLearningAnswer(
        subject: 'Mathematik', unit: 'Plus', correct: false, taskId: 'wrong');
    expect(app.dailyMission!.completedCount, 0);
    await app.recordLearningAnswer(
        subject: 'Mathematik', unit: 'Plus', correct: true,
        hintUsed: true, taskId: 'assisted-solved');
    expect(app.dailyMission!.completedCount, 1);
    await app.recordLearningAnswer(
        subject: 'Mathematik', unit: 'Plus', correct: true,
        taskId: 'assisted-solved');
    expect(app.dailyMission!.completedCount, 1);
    final restarted = LumoAppState();
    addTearDown(restarted.dispose);
    await restarted.loadDailyMission();
    expect(restarted.dailyMission!.completedCount, 1);
  });

  test('enabled requirement needs every station and survives mission reload',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
        requireDailyMissionForGames: true, missionTasksPerStation: 2));
    expect(app.canPlayToday, isFalse);
    await app.loadDailyMission();
    for (final station in app.dailyMission!.stations) {
      for (var i = 0; i < 2; i++) {
        await app.recordLearningAnswer(
            subject: station.subject, unit: 'Aufgabe', correct: true,
            taskId: '${station.subject}-$i');
      }
    }
    expect(app.canPlayToday, isTrue);
    await app.loadDailyMission();
    expect(app.canPlayToday, isTrue);
  });

  test('school-save retry also persists accepted mission evidence exactly once',
      () async {
    final store = _RejectStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.loadLearningProfile();
    await app.loadDailyMission();
    store.rejectedKey = 'lumo_progress_skills';
    await expectLater(
        app.recordLearningAnswer(
            subject: 'Mathematik', unit: 'Plus', correct: true,
            taskId: 'accepted-before-save', requireSaved: true),
        throwsStateError);
    store.rejectedKey = null;
    await app.flushLearningProgress();
    expect(app.dailyMission!.completedCount, 1);
    await app.flushLearningProgress();
    expect(app.dailyMission!.completedCount, 1);
    expect(app.learningDailyDone(), 1);
  });

  test('mission-save failure blocks optional requirement and retries accepted work',
      () async {
    final store = _RejectStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
        requireDailyMissionForGames: true, missionTasksPerStation: 2));
    await app.loadDailyMission();
    final subjects = app.dailyMission!.stations.map((s) => s.subject).toList();
    for (var i = 0; i < 5; i++) {
      await app.recordLearningAnswer(
          subject: subjects[i ~/ 2], unit: 'Aufgabe', correct: true,
          taskId: 'task-$i');
    }
    store.rejectedKey = 'lumo_daily_mission_v1';
    await app.recordLearningAnswer(
        subject: subjects.last, unit: 'Aufgabe', correct: true,
        taskId: 'task-5');
    expect(app.dailyMission!.completedCount, 5);
    expect(app.dailyMissionError, isNotNull);
    expect(app.canPlayToday, isFalse);
    store.rejectedKey = null;
    await app.loadDailyMission();
    expect(app.dailyMission!.completedCount, 6);
    expect(app.dailyMissionError, isNull);
    expect(app.canPlayToday, isTrue);
    expect(app.learningDailyDone(), 6);
  });

  test('an identity read failure is visible without enabling the default gate',
      () async {
    final store = _RejectStore();
    SharedPreferencesStorePlatform.instance = store;
    store.rejectedKey = LegacyLearningDataRepository.localIdKey;
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.loadDailyMission();
    expect(app.dailyMission, isNull);
    expect(app.dailyMissionError, isNotNull);
    expect(app.canPlayToday, isTrue);
    app.updateSettings(const AppSettings(requireDailyMissionForGames: true));
    expect(app.canPlayToday, isFalse);
  });

  test('a stale mission load cannot show the previous child after selection',
      () async {
    final delayed = _DelayedMission('student-a');
    final app = LumoAppState(dailyMissionFactory: (id) => id == 'student-a'
        ? delayed : DailyMissionRepository(studentId: id));
    addTearDown(app.dispose);
    await app.school.setActiveStudent('student-a');
    final first = app.loadDailyMission();
    await delayed.entered.future;
    await app.school.setActiveStudent('student-b');
    await app.loadDailyMission();
    expect(app.dailyMission!.studentId, 'student-b');
    delayed.release.complete();
    await first;
    expect(app.dailyMission!.studentId, 'student-b');
    expect(app.dailyMission!.completedCount, 0);
  });

  test('resetting learning clears that mission and preserves other profiles',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    for (final id in ['student-a', 'student-b']) {
      await app.school.setActiveStudent(id);
      await app.recordLearningAnswer(
          subject: 'Mathematik', unit: 'Plus', correct: true,
          taskId: 'same-id');
    }
    await app.resetLearningProgress();
    await app.loadDailyMission();
    expect(app.dailyMission!.completedCount, 0);
    await app.school.setActiveStudent('student-a');
    await app.loadDailyMission();
    expect(app.dailyMission!.completedCount, 1);
  });

  test('a completed yesterday mission or rollback does not satisfy today',
      () async {
    var now = DateTime.utc(2026, 10, 23, 12);
    final app = LumoAppState(dailyMissionFactory: (id) =>
        DailyMissionRepository(studentId: id, now: () => now));
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
        requireDailyMissionForGames: true, missionTasksPerStation: 2));
    await app.loadDailyMission();
    for (final station in app.dailyMission!.stations) {
      for (var i = 0; i < 2; i++) {
        await app.recordLearningAnswer(
            subject: station.subject, unit: 'Aufgabe', correct: true,
            taskId: '${station.subject}-$i');
      }
    }
    expect(app.canPlayToday, isTrue);
    now = DateTime.utc(2026, 10, 22, 12);
    await app.loadDailyMission();
    expect(app.dailyMission!.clockUncertain, isTrue);
    expect(app.canPlayToday, isFalse);
    now = DateTime.utc(2026, 10, 24, 12);
    await app.loadDailyMission();
    expect(app.dailyMission!.completedCount, 0);
    expect(app.canPlayToday, isFalse);
  });
}
