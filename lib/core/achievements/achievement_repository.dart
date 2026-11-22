import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../daily_mission_repository.dart';
import '../legacy_learning_data.dart';
import '../lumo_quest_library.dart';
import 'lumo_achievement.dart';

enum AchievementParticipation { question, live }

/// Confirmed unlocks only. Payout receipts live atomically with the money in
/// RewardWallet. The old device-wide achievement keys remain untouched.
class AchievementSnapshot {
  AchievementSnapshot({
    required this.studentId,
    Map<AchievementMetric, int> counters = const {},
    Map<String, DateTime> unlocked = const {},
    Set<String> quests = const {},
    Set<String> pendingClaims = const {},
    Map<String, Object?>? mission,
  })  : counters = Map.unmodifiable(counters),
        unlocked = Map.unmodifiable(unlocked),
        quests = Set.unmodifiable(quests),
        pendingClaims = Set.unmodifiable(pendingClaims),
        mission = mission == null ? null : Map.unmodifiable(mission);

  final String studentId;
  final Map<AchievementMetric, int> counters;
  final Map<String, DateTime> unlocked;
  final Set<String> quests;
  final Set<String> pendingClaims;
  final Map<String, Object?>? mission;

  Map<String, Object?> toJson() => {
        'version': 2,
        'studentId': studentId,
        'counters': {for (final e in counters.entries) e.key.name: e.value},
        'unlocked': {
          for (final e in unlocked.entries)
            e.key: e.value.toUtc().toIso8601String()
        },
        'quests': quests.toList()..sort(),
        'pendingClaims': pendingClaims.toList()..sort(),
        'mission': mission,
      };
}

class AchievementRepository {
  AchievementRepository(
      {required String studentId,
      bool Function()? mayWrite,
      DateTime Function()? now})
      : studentId = studentId.trim(),
        _mayWrite = mayWrite,
        _now = now ?? DateTime.now {
    if (this.studentId.isEmpty || this.studentId.length > 160) {
      throw ArgumentError('Auszeichnungen benötigen ein Kinderprofil.');
    }
  }

  static const baseKey = 'lumo_achievements_v2';
  static final ValueNotifier<int> changes = ValueNotifier(0);
  final String studentId;
  final bool Function()? _mayWrite;
  final DateTime Function() _now;
  String get storageKey => LearningDataNamespace.keyFor(baseKey, studentId);

  Future<AchievementSnapshot> load() => LearningStorage.run((prefs) async {
        final raw = prefs.getString(storageKey);
        return raw == null
            ? AchievementSnapshot(studentId: studentId)
            : _read(raw);
      });

  Future<bool> hasUnassignedLegacy() => LearningStorage.run((prefs) async =>
      prefs.containsKey('lumo.achievements.unlocked') ||
      prefs.containsKey('lumo.achievements.counters'));

  /// SharedPreferences can expose a failed native write in its memory cache.
  /// This durable intent therefore precedes any wallet call and is removed
  /// only after the same idempotent wallet receipt is positively persisted.
  Future<AchievementSnapshot> beginClaim(String id) => _claimPending(id, true);
  Future<AchievementSnapshot> confirmClaim(String id) =>
      _claimPending(id, false);

  Future<AchievementSnapshot> _claimPending(String id, bool pending) =>
      _change((saved) {
        if (!saved.unlocked.containsKey(id)) {
          throw StateError('Diese Auszeichnung ist noch gesperrt.');
        }
        final claims = {...saved.pendingClaims};
        pending ? claims.add(id) : claims.remove(id);
        return AchievementSnapshot(
            studentId: studentId,
            counters: saved.counters,
            unlocked: saved.unlocked,
            quests: saved.quests,
            pendingClaims: claims,
            mission: saved.mission);
      });

  /// Totals from existing durable, owned learning records and owned wallet
  /// credits. Missing history never becomes invented achievement progress.
  Future<AchievementSnapshot> syncDurableProgress({
    required int totalTasks,
    required int correctTasks,
    required int mathCorrect,
    required int germanCorrect,
    required int longestLearningStreak,
    required int earnedStars,
  }) {
    final values = <AchievementMetric, int>{
      AchievementMetric.totalTasks: totalTasks,
      AchievementMetric.correctTasks: correctTasks,
      AchievementMetric.mathCorrect: mathCorrect,
      AchievementMetric.germanCorrect: germanCorrect,
      AchievementMetric.streakDays: longestLearningStreak,
      AchievementMetric.loginsConsecutive: longestLearningStreak,
      AchievementMetric.starsTotal: earnedStars,
    };
    if (values.values.any((v) => v < 0 || v > 999999999)) {
      throw ArgumentError('Ungültiger gespeicherter Lernfortschritt.');
    }
    return _change((saved) => _withMetrics(saved, values));
  }

  /// Only the first real question/LIVE interaction is needed by this catalog.
  /// No question text, photo, audio, or child text is retained here.
  Future<AchievementSnapshot> recordParticipation(
          AchievementParticipation kind) =>
      _change((saved) => _withMetrics(saved, {
            (kind == AchievementParticipation.question
                ? AchievementMetric.kiQuestions
                : AchievementMetric.liveSnaps): 1,
          }));

  Future<AchievementSnapshot> recordQuestCompleted(String questId) {
    if (!LumoQuestLibrary.all().any((q) => q.id == questId)) {
      throw ArgumentError('Nur vorhandene Lumo Quests zählen.');
    }
    return _change((saved) {
      final quests = {...saved.quests, questId};
      return _withMetrics(
          AchievementSnapshot(
              studentId: studentId,
              counters: saved.counters,
              unlocked: saved.unlocked,
              quests: quests,
              pendingClaims: saved.pendingClaims,
              mission: saved.mission),
          {AchievementMetric.questsCompleted: quests.length});
    });
  }

  /// Start at zero, observe every persisted station increment, and accept no
  /// wrong answer before completion. An old partial mission is not proof.
  Future<AchievementSnapshot> recordMissionAnswer({
    required String taskId,
    required String subject,
    required bool correct,
    required DailyMissionSnapshot before,
    required DailyMissionSnapshot after,
  }) {
    if (taskId.isEmpty ||
        taskId.length > 160 ||
        before.studentId != studentId ||
        after.studentId != studentId) {
      throw ArgumentError('Die Mission gehört zu einem anderen Lernprofil.');
    }
    if (before.dayKey != after.dayKey ||
        before.clockUncertain ||
        after.clockUncertain ||
        !before.stations.any((s) => s.subject == subject)) {
      return load();
    }
    return _change((saved) {
      if (saved.counters[AchievementMetric.perfectMissions] == 1) return saved;
      final previous = saved.mission;
      final sameDay = previous?['dayKey'] == before.dayKey;
      var completeEvidence = sameDay
          ? previous!['completeEvidence'] == true
          : before.completedCount == 0;
      final wrong = (sameDay && previous!['wrong'] == true) || !correct;
      final known =
          sameDay ? previous!['completed'] as int : before.completedCount;
      final repeated = sameDay &&
          previous!['lastTaskId'] == taskId &&
          previous['lastCorrect'] == correct &&
          known == after.completedCount;
      if (repeated) return saved;
      if (known != before.completedCount ||
          after.completedCount < before.completedCount ||
          after.completedCount > before.completedCount + 1 ||
          after.targetCount != before.targetCount) completeEvidence = false;
      final mission = <String, Object?>{
        'dayKey': after.dayKey,
        'completeEvidence': completeEvidence,
        'wrong': wrong,
        'completed': after.completedCount,
        'lastTaskId': taskId,
        'lastCorrect': correct,
      };
      final next = AchievementSnapshot(
          studentId: studentId,
          counters: saved.counters,
          unlocked: saved.unlocked,
          quests: saved.quests,
          pendingClaims: saved.pendingClaims,
          mission: mission);
      return completeEvidence &&
              !wrong &&
              after.isComplete &&
              after.completedCount > before.completedCount
          ? _withMetrics(next, {AchievementMetric.perfectMissions: 1})
          : next;
    });
  }

  AchievementSnapshot _withMetrics(
      AchievementSnapshot saved, Map<AchievementMetric, int> incoming) {
    final counters = {...saved.counters};
    for (final entry in incoming.entries) {
      counters[entry.key] = math.max(counters[entry.key] ?? 0, entry.value);
    }
    final unlocked = {...saved.unlocked};
    for (final a in LumoAchievementCatalog.all) {
      if ((counters[a.metric] ?? 0) >= a.target) {
        unlocked.putIfAbsent(a.id, () => _now().toUtc());
      }
    }
    return AchievementSnapshot(
        studentId: studentId,
        counters: counters,
        unlocked: unlocked,
        quests: saved.quests,
        pendingClaims: saved.pendingClaims,
        mission: saved.mission);
  }

  Future<AchievementSnapshot> _change(
      AchievementSnapshot Function(AchievementSnapshot) operation) async {
    var changed = false;
    final result = await LearningStorage.run((prefs) async {
      if (_mayWrite?.call() == false)
        throw StateError('Das Lernprofil ist beendet.');
      final raw = prefs.getString(storageKey);
      final current =
          raw == null ? AchievementSnapshot(studentId: studentId) : _read(raw);
      final next = operation(current);
      final encoded = jsonEncode(next.toJson());
      if (encoded != raw) {
        await LearningStorage.write(prefs, storageKey, encoded);
        changed = true;
      }
      return next;
    });
    if (changed) changes.value++;
    return result;
  }

  AchievementSnapshot _read(String raw) {
    if (raw.length > 32768)
      throw const FormatException('Auszeichnungsdaten zu groß.');
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['version'] != 2 ||
        value['studentId'] != studentId ||
        value['counters'] is! Map ||
        value['unlocked'] is! Map ||
        value['quests'] is! List ||
        value.keys.toSet().difference(const {
          'version',
          'studentId',
          'counters',
          'unlocked',
          'quests',
          'pendingClaims',
          'mission'
        }).isNotEmpty) {
      throw const FormatException('Auszeichnungsdaten nicht sicher lesbar.');
    }
    final counters = <AchievementMetric, int>{};
    for (final e in (value['counters'] as Map).entries) {
      final metrics = AchievementMetric.values.where((m) => m.name == e.key);
      if (metrics.length != 1 ||
          e.value is! int ||
          (e.value as int) < 0 ||
          (e.value as int) > 999999999) {
        throw const FormatException('Ungültiger Auszeichnungszähler.');
      }
      counters[metrics.single] = e.value as int;
    }
    final unlocked = <String, DateTime>{};
    for (final e in (value['unlocked'] as Map).entries) {
      final a =
          e.key is String ? LumoAchievementCatalog.byId(e.key as String) : null;
      final at =
          e.value is String ? DateTime.tryParse(e.value as String) : null;
      if (a == null ||
          at == null ||
          at.year < 2000 ||
          at.year > 2200 ||
          (counters[a.metric] ?? 0) < a.target) {
        throw const FormatException(
            'Freischaltung ohne passenden Fortschritt.');
      }
      unlocked[a.id] = at;
    }
    final quests = <String>{};
    final known = LumoQuestLibrary.all().map((q) => q.id).toSet();
    for (final q in value['quests'] as List) {
      if (q is! String || !known.contains(q) || !quests.add(q)) {
        throw const FormatException('Unbekannter Quest-Beleg.');
      }
    }
    if ((counters[AchievementMetric.questsCompleted] ?? 0) != quests.length) {
      throw const FormatException('Quest-Zähler passt nicht zu Belegen.');
    }
    final mission = value['mission'];
    final pendingClaims = <String>{};
    final rawClaims = value['pendingClaims'] ?? const [];
    if (rawClaims is! List ||
        rawClaims.length > LumoAchievementCatalog.all.length) {
      throw const FormatException('Ungültige offene Auszahlungen.');
    }
    for (final id in rawClaims) {
      if (id is! String ||
          !unlocked.containsKey(id) ||
          !pendingClaims.add(id)) {
        throw const FormatException('Ungültiger offener Auszahlungsbeleg.');
      }
    }
    if (mission != null &&
        (mission is! Map<String, dynamic> ||
            mission['dayKey'] is! String ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$')
                .hasMatch(mission['dayKey'] as String) ||
            mission['completeEvidence'] is! bool ||
            mission['wrong'] is! bool ||
            mission['completed'] is! int ||
            (mission['completed'] as int) < 0 ||
            (mission['completed'] as int) > 18 ||
            mission['lastTaskId'] is! String ||
            (mission['lastTaskId'] as String).length > 160 ||
            mission['lastCorrect'] is! bool)) {
      throw const FormatException('Ungültiger Missionsbeleg.');
    }
    return AchievementSnapshot(
        studentId: studentId,
        counters: counters,
        unlocked: unlocked,
        quests: quests,
        pendingClaims: pendingClaims,
        mission:
            mission == null ? null : Map<String, Object?>.from(mission as Map));
  }
}
