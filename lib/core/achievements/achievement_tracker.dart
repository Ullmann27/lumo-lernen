import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';
import '../progress_repository.dart';
import '../reward_wallet_repository.dart';
import 'achievement_claim.dart';
import 'achievement_repository.dart';
import 'lumo_achievement.dart';

/// A view session for one AppState. There is no device-global child singleton.
/// Reads use canonical persisted sources; claims use the shared durable wallet.
class AchievementTracker extends ChangeNotifier {
  AchievementTracker(this.appState) {
    appState.addListener(_stateChanged);
    AchievementRepository.changes.addListener(_evidenceChanged);
    _stateChanged();
  }

  final LumoAppState appState;
  final _unlocks = StreamController<LumoAchievement>.broadcast();
  Stream<LumoAchievement> get unlockStream => _unlocks.stream;
  AchievementSnapshot? snapshot;
  LearningProfileLease? lease;
  RewardWallet? wallet;
  String? error;
  bool loading = true;
  bool busy = false;
  bool legacyUnassigned = false;
  bool _disposed = false;
  int _generation = -1;
  bool _again = false;
  Future<void>? _refreshing;
  String? _loadedOwner;

  bool get current => lease != null && appState.isCurrentLearningLease(lease!);
  bool get ready =>
      current &&
      snapshot != null &&
      !loading &&
      !busy &&
      !appState.resetting &&
      !appState.backupBusy;
  bool get hydrated => snapshot != null;
  bool isClaimed(String id) =>
      current &&
      snapshot?.pendingClaims.contains(id) != true &&
      (wallet?.achievementClaims.any((claim) =>
              claim.ownerId == lease!.studentId && claim.achievementId == id) ??
          false);
  int unlockedCount() => snapshot?.unlocked.length ?? 0;
  int counter(AchievementMetric metric) => snapshot?.counters[metric] ?? 0;

  List<LumoAchievementProgress> progressList() => [
        for (final a in LumoAchievementCatalog.all)
          LumoAchievementProgress(
            achievement: a,
            current: counter(a.metric),
            unlocked: snapshot?.unlocked.containsKey(a.id) ?? false,
            unlockedAt: snapshot?.unlocked[a.id],
            claimed: isClaimed(a.id),
          ),
      ];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _stateChanged() {
    if (_disposed) return;
    if (_generation != appState.profileGeneration || appState.resetting) {
      _generation = appState.profileGeneration;
      lease = null;
      snapshot = null;
      wallet = null;
      _loadedOwner = null;
      error = null;
      legacyUnassigned = false;
      loading = true;
      _notify();
    }
    if (!appState.resetting && !appState.backupBusy) unawaited(refresh());
  }

  void _evidenceChanged() {
    if (!_disposed && !appState.resetting && !appState.backupBusy) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() {
    if (_disposed || appState.resetting || appState.backupBusy)
      return Future.value();
    if (_refreshing != null) {
      _again = true;
      return _refreshing!;
    }
    final completer = Completer<void>();
    _refreshing = completer.future;
    unawaited(() async {
      try {
        do {
          _again = false;
          await _refreshOnce();
        } while (_again &&
            !_disposed &&
            !appState.resetting &&
            !appState.backupBusy);
      } finally {
        _refreshing = null;
        completer.complete();
      }
    }());
    return completer.future;
  }

  Future<void> _refreshOnce() async {
    final generation = appState.profileGeneration;
    try {
      final owner = await appState.captureLearningProfile();
      if (!appState.isCurrentLearningLease(owner) || !owner.profile.isLoaded) {
        await appState.prepareLearningLease(owner);
      }
      if (_disposed || !appState.isCurrentLearningLease(owner)) return;
      final repository = AchievementRepository(
          studentId: owner.studentId,
          mayWrite: () =>
              appState.canUseLearningLease(owner) && !appState.backupBusy);
      final progress = ProgressRepository(studentId: owner.studentId);
      final skills = await progress.loadSkills();
      final daily = await progress.loadDaily();
      final attempts =
          await appState.attemptLog.load(studentId: owner.logStudentId);
      final savedWallet = await appState.loadRewardShopWallet(lease: owner);
      if (_disposed || !appState.isCurrentLearningLease(owner)) return;
      final standard =
          attempts.where((a) => a.subject != 'Elternaufgaben').toList();
      final parent =
          attempts.where((a) => a.subject == 'Elternaufgaben').toList();
      final skillTotal = skills.values
          .fold(0, (sum, skill) => sum + skill.correct + skill.wrong);
      final skillCorrect =
          skills.values.fold(0, (sum, skill) => sum + skill.correct);
      int subjectCorrect(String subject) => math.max(
          skills.values
              .where((s) => s.subject == subject)
              .fold(0, (sum, skill) => sum + skill.correct),
          standard.where((a) => a.subject == subject && a.correct).length);
      final learningDays = <String>{
        for (final e in daily.entries)
          if (e.value > 0) e.key,
        for (final attempt in attempts) dayKey(attempt.at.toLocal()),
      };
      final saved = await repository.syncDurableProgress(
        totalTasks: math.max(skillTotal, standard.length) + parent.length,
        correctTasks:
            math.max(skillCorrect, standard.where((a) => a.correct).length) +
                parent.where((a) => a.correct).length,
        mathCorrect: subjectCorrect('Mathematik'),
        germanCorrect: subjectCorrect('Deutsch'),
        longestLearningStreak: longestStreak(learningDays),
        earnedStars: savedWallet.earnedStarsByOwner[owner.studentId] ?? 0,
      );
      final legacy = await repository.hasUnassignedLegacy();
      if (_disposed || !appState.isCurrentLearningLease(owner)) return;
      final announce = _loadedOwner == owner.studentId;
      final previous = snapshot?.unlocked.keys.toSet() ?? <String>{};
      lease = owner;
      wallet = savedWallet;
      snapshot = saved;
      _loadedOwner = owner.studentId;
      legacyUnassigned = legacy;
      error = null;
      loading = false;
      _notify();
      if (announce) {
        for (final id
            in saved.unlocked.keys.where((id) => !previous.contains(id))) {
          _unlocks.add(LumoAchievementCatalog.byId(id)!);
        }
      }
    } catch (_) {
      if (!_disposed &&
          generation == appState.profileGeneration &&
          !appState.resetting) {
        loading = false;
        error =
            'Deine Auszeichnungen konnten noch nicht sicher geladen werden. Bitte erneut versuchen.';
        _notify();
      }
    }
  }

  /// A deterministic receipt survives retry, close, restart and profile switch.
  /// True is returned only after a positively confirmed wallet transaction.
  Future<bool> claim(String achievementId) async {
    if (!ready ||
        isClaimed(achievementId) ||
        snapshot?.unlocked.containsKey(achievementId) != true) return false;
    final owner = lease!;
    busy = true;
    error = null;
    _notify();
    try {
      final repository = AchievementRepository(
          studentId: owner.studentId,
          mayWrite: () =>
              appState.canUseLearningLease(owner) && !appState.backupBusy);
      final pending = await repository.beginClaim(achievementId);
      if (_disposed || !appState.isCurrentLearningLease(owner)) return false;
      snapshot = pending;
      final result = await appState.claimAchievement(
          lease: owner,
          claim: AchievementClaim(
              ownerId: owner.studentId, achievementId: achievementId));
      final confirmed = await repository.confirmClaim(achievementId);
      if (_disposed || !appState.isCurrentLearningLease(owner)) return false;
      snapshot = confirmed;
      wallet = result;
      if (!isClaimed(achievementId))
        throw StateError('Auszahlungsbeleg fehlt.');
      return true;
    } catch (_) {
      if (!_disposed && appState.isCurrentLearningLease(owner)) {
        error =
            'Die Sterne sind noch nicht sicher bestätigt. Bitte erneut abholen; derselbe Bonus wird nur einmal gebucht.';
      }
      return false;
    } finally {
      busy = false;
      _notify();
      if (!_disposed) unawaited(refresh());
    }
  }

  /// Longest proven run of local learning dates, not guessed app-open days.
  static int longestStreak(Iterable<String> keys, {DateTime? now}) {
    final today = DateTime.parse('${dayKey(now ?? DateTime.now())}T00:00:00Z');
    final dates = <DateTime>{};
    for (final key in keys) {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) continue;
      final date = DateTime.tryParse('${key}T00:00:00Z');
      if (date == null ||
          dayKey(date) != key ||
          date.year < 2000 ||
          date.isAfter(today)) continue;
      dates.add(date);
    }
    final sorted = dates.toList()..sort();
    var longest = 0, run = 0;
    DateTime? previous;
    for (final date in sorted) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      longest = math.max(longest, run);
      previous = date;
    }
    return longest;
  }

  static String dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _disposed = true;
    appState.removeListener(_stateChanged);
    AchievementRepository.changes.removeListener(_evidenceChanged);
    _unlocks.close();
    super.dispose();
  }
}
