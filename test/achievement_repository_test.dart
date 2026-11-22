import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/achievements/achievement_claim.dart';
import 'package:lumo_lernen/core/achievements/achievement_repository.dart';
import 'package:lumo_lernen/core/achievements/achievement_tracker.dart';
import 'package:lumo_lernen/core/achievements/lumo_achievement.dart';
import 'package:lumo_lernen/core/daily_mission_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RejectAchievementStore extends InMemorySharedPreferencesStore {
  _RejectAchievementStore() : super.withData({});
  bool reject = false;
  @override
  Future<bool> setValue(String type, String key, Object value) =>
      reject && key.contains(AchievementRepository.baseKey)
          ? Future.value(false)
          : super.setValue(type, key, value);
}

Future<AchievementSnapshot> _progress(AchievementRepository repo,
        {int tasks = 0,
        int math = 0,
        int german = 0,
        int days = 0,
        int stars = 0}) =>
    repo.syncDurableProgress(
        totalTasks: tasks,
        correctTasks: tasks,
        mathCorrect: math,
        germanCorrect: german,
        longestLearningStreak: days,
        earnedStars: stars);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps all fourteen catalog identities and the full 150-star reward',
      () {
    expect(LumoAchievementCatalog.all.map((a) => a.id).toSet(), {
      'first_steps',
      'ten_tasks',
      'first_ki_chat',
      'login_3days',
      'live_first',
      'math_master_25',
      'german_master_25',
      'streak_7',
      'first_quest',
      'stars_100',
      'perfect_mission',
      'streak_30',
      'all_quests',
      'stars_500',
    });
    const claim =
        AchievementClaim(ownerId: 'child-a', achievementId: 'streak_30');
    expect(claim.stars, 150);
    expect(AchievementClaim.fromJson(claim.toJson()).claimId, claim.claimId);
    final corrupt = {...claim.toJson(), 'stars': 151};
    expect(() => AchievementClaim.fromJson(corrupt), throwsFormatException);
    expect(
        () => const AchievementClaim(
                ownerId: 'child-a', achievementId: 'invented')
            .validate(),
        throwsArgumentError);
  });

  test('old device badges remain unchanged and are never assigned to a child',
      () async {
    final prefs = await SharedPreferences.getInstance();
    const old = '{"streak_30":"2026-01-01T12:00:00Z"}';
    await prefs.setString('lumo.achievements.unlocked', old);
    await prefs.setString('lumo.achievements.counters', '{"starsTotal":900}');
    for (final owner in ['child-a', 'child-b']) {
      final repo = AchievementRepository(studentId: owner);
      expect(await repo.hasUnassignedLegacy(), isTrue);
      expect((await repo.load()).unlocked, isEmpty);
      expect((await _progress(repo)).counters[AchievementMetric.starsTotal], 0);
    }
    expect(prefs.getString('lumo.achievements.unlocked'), old);
  });

  test(
      'concurrent repository instances merge genuine participation and quest evidence',
      () async {
    final a = AchievementRepository(studentId: 'child-a');
    final otherA = AchievementRepository(studentId: 'child-a');
    await Future.wait([
      a.recordParticipation(AchievementParticipation.question),
      otherA.recordParticipation(AchievementParticipation.live),
      a.recordQuestCompleted('q1_apfelgarten'),
      otherA.recordQuestCompleted('q2_baeckerei'),
    ]);
    final saved = await a.load();
    expect(saved.unlocked.keys,
        containsAll(['first_ki_chat', 'live_first', 'first_quest']));
    expect(saved.quests, {'q1_apfelgarten', 'q2_baeckerei'});
    await otherA.recordQuestCompleted('q1_apfelgarten');
    expect(
        (await otherA.load()).counters[AchievementMetric.questsCompleted], 2);
    expect((await AchievementRepository(studentId: 'child-b').load()).unlocked,
        isEmpty);
    expect(() => a.recordQuestCompleted('not-a-quest'), throwsArgumentError);
  });

  test('all four actual quests unlock once, including across class changes',
      () async {
    final repo = AchievementRepository(studentId: 'child-a');
    for (final id in [
      'q1_apfelgarten',
      'q2_baeckerei',
      'q3_schatzhoehle',
      'q4_sternenflug'
    ]) {
      await repo.recordQuestCompleted(id);
    }
    final saved = await AchievementRepository(studentId: 'child-a').load();
    expect(saved.counters[AchievementMetric.questsCompleted], 4);
    expect(saved.unlocked, contains('all_quests'));
  });

  test('durable projections keep earned badges when an old log is trimmed',
      () async {
    final repo = AchievementRepository(studentId: 'child-a');
    final first = await _progress(repo,
        tasks: 50, math: 25, german: 25, days: 30, stars: 500);
    final later = await _progress(repo, tasks: 1);
    expect(later.unlocked, first.unlocked);
    expect(later.counters[AchievementMetric.totalTasks], 50);
    expect(
        later.unlocked.keys,
        containsAll(
            ['math_master_25', 'german_master_25', 'streak_30', 'stars_500']));
  });

  test('failed persistence emits no unlock; retry succeeds from original bytes',
      () async {
    final store = _RejectAchievementStore();
    SharedPreferencesStorePlatform.instance = store;
    final repo = AchievementRepository(studentId: 'child-a');
    store.reject = true;
    final before = AchievementRepository.changes.value;
    await expectLater(
        repo.recordParticipation(AchievementParticipation.question),
        throwsStateError);
    expect((await repo.load()).unlocked, isEmpty);
    expect(AchievementRepository.changes.value, before);
    store.reject = false;
    expect(
        (await repo.recordParticipation(AchievementParticipation.question))
            .unlocked,
        contains('first_ki_chat'));
  });

  test(
      'corrupt and newer-format records are preserved and cannot be overwritten',
      () async {
    final repo = AchievementRepository(studentId: 'child-a');
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      'broken-json',
      jsonEncode({'version': 999, 'studentId': 'child-a'})
    ]) {
      await prefs.setString(repo.storageKey, raw);
      await expectLater(repo.load(), throwsFormatException);
      await expectLater(_progress(repo, tasks: 10), throwsFormatException);
      expect(prefs.getString(repo.storageKey), raw);
    }
  });

  test(
      'consecutive days use real calendar dates, exclude future and duplicate days',
      () {
    expect(
        AchievementTracker.longestStreak([
          '2026-10-31',
          '2026-11-01',
          '2026-11-02',
          '2026-11-02',
          '2026-11-04',
          '2026-11-05',
          '2027-01-01',
          '2026-02-30',
          'garbage',
        ], now: DateTime(2026, 11, 4)),
        3);
  });

  for (final scenario in ['perfect', 'wrong', 'partial-old', 'missing-step']) {
    test('mission evidence $scenario grants only a complete error-free mission',
        () async {
      final now = DateTime(2026, 11, 22, 12);
      final mission =
          DailyMissionRepository(studentId: 'child-a', now: () => now);
      final repo = AchievementRepository(studentId: 'child-a', now: () => now);
      var before = await mission.load(tasksPerStation: 2);
      if (scenario == 'wrong') {
        await repo.recordMissionAnswer(
            taskId: 'wrong',
            subject: before.stations.first.subject,
            correct: false,
            before: before,
            after: before);
      }
      var index = 0;
      for (final station in before.stations) {
        for (var i = 0; i < 2; i++) {
          final id = 'task-${index++}';
          final after = await mission.recordAnswer(
              taskId: id,
              subject: station.subject,
              correct: true,
              tasksPerStation: 2);
          final skip = scenario == 'partial-old' && index == 1 ||
              scenario == 'missing-step' && index == 3;
          if (!skip) {
            final restarted =
                AchievementRepository(studentId: 'child-a', now: () => now);
            await restarted.recordMissionAnswer(
                taskId: id,
                subject: station.subject,
                correct: true,
                before: before,
                after: after);
            // A retry of exactly this persisted transition never increments twice.
            await restarted.recordMissionAnswer(
                taskId: id,
                subject: station.subject,
                correct: true,
                before: before,
                after: after);
          }
          before = after;
        }
      }
      expect(before.isComplete, isTrue);
      expect((await repo.load()).unlocked.containsKey('perfect_mission'),
          scenario == 'perfect');
    });
  }
}
