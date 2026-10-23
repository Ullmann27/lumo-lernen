import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
