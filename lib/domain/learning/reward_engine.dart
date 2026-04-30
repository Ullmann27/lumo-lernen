import 'lumo_learning_domain.dart';

enum RewardReason {
  correctAnswer,
  completedTask,
  usedHelpAndFinished,
  improvedMastery,
  completedWriting,
  completedTest,
  tutoringSessionFinished,
}

enum VoucherCategory {
  freeTime,
  creative,
  family,
  sport,
  food,
  smallWish,
  lumoDigital,
}

class RewardDelta {
  const RewardDelta({
    required this.stars,
    required this.xp,
    this.reasons = const <RewardReason>[],
  });

  final int stars;
  final int xp;
  final List<RewardReason> reasons;

  bool get isEmpty => stars == 0 && xp == 0 && reasons.isEmpty;
}

class RewardState {
  const RewardState({
    required this.childId,
    this.stars = 0,
    this.xp = 0,
    this.level = 1,
    this.badges = const <String>[],
    this.lastRewardAt,
  });

  final String childId;
  final int stars;
  final int xp;
  final int level;
  final List<String> badges;
  final DateTime? lastRewardAt;

  RewardState apply(RewardDelta delta, {DateTime? now}) {
    final nextXp = xp + delta.xp;
    return RewardState(
      childId: childId,
      stars: stars + delta.stars,
      xp: nextXp,
      level: _levelForXp(nextXp),
      badges: badges,
      lastRewardAt: delta.isEmpty ? lastRewardAt : now ?? DateTime.now(),
    );
  }

  static int _levelForXp(int xp) => xp ~/ 400 + 1;
}

class Voucher {
  const Voucher({
    required this.id,
    required this.familyId,
    required this.title,
    required this.category,
    required this.starPrice,
    required this.minLevel,
    this.dailyLimit,
    this.requiresParentPin = true,
    this.active = true,
  });

  final String id;
  final String familyId;
  final String title;
  final VoucherCategory category;
  final int starPrice;
  final int minLevel;
  final int? dailyLimit;
  final bool requiresParentPin;
  final bool active;
}

class VoucherRedemption {
  const VoucherRedemption({
    required this.id,
    required this.voucherId,
    required this.childId,
    required this.redeemedAt,
    required this.approvedByParent,
    required this.starsSpent,
  });

  final String id;
  final String voucherId;
  final String childId;
  final DateTime redeemedAt;
  final bool approvedByParent;
  final int starsSpent;
}

class VoucherVisibilityResult {
  const VoucherVisibilityResult({
    required this.visible,
    required this.redeemable,
    this.reason,
  });

  final bool visible;
  final bool redeemable;
  final String? reason;
}

class RewardEngine {
  const RewardEngine();

  RewardDelta calculateTaskReward({
    required TaskResult result,
    required SkillState before,
    required SkillState after,
    LearningMode mode = LearningMode.practice,
    bool completedSession = false,
  }) {
    var stars = 0;
    var xp = 0;
    final reasons = <RewardReason>[];

    // Completion is rewarded to avoid pure correctness pressure.
    stars += 1;
    xp += 5;
    reasons.add(RewardReason.completedTask);

    if (result.correct) {
      stars += 3;
      xp += 20;
      reasons.add(RewardReason.correctAnswer);
    }

    if (result.helpUsed) {
      stars += 1;
      xp += 8;
      reasons.add(RewardReason.usedHelpAndFinished);
    }

    if (after.masteryScore > before.masteryScore + 0.02) {
      stars += 2;
      xp += 12;
      reasons.add(RewardReason.improvedMastery);
    }

    if (result.handwritingScore != null) {
      xp += 10;
      if (result.handwritingScore! >= 0.72) stars += 2;
      reasons.add(RewardReason.completedWriting);
    }

    if (completedSession && mode == LearningMode.tutoring) {
      stars += 3;
      xp += 15;
      reasons.add(RewardReason.tutoringSessionFinished);
    }

    if (mode == LearningMode.exam || mode == LearningMode.subjectTest || mode == LearningMode.blitzTest || mode == LearningMode.weaknessTest) {
      xp += 10;
      reasons.add(RewardReason.completedTest);
    }

    return RewardDelta(
      stars: stars.clamp(0, 12),
      xp: xp.clamp(0, 70),
      reasons: reasons,
    );
  }

  VoucherVisibilityResult voucherState({
    required Voucher voucher,
    required RewardState rewardState,
    required int redemptionsToday,
  }) {
    if (!voucher.active) {
      return const VoucherVisibilityResult(visible: false, redeemable: false, reason: 'Gutschein ist deaktiviert.');
    }

    if (rewardState.level < voucher.minLevel) {
      return VoucherVisibilityResult(
        visible: false,
        redeemable: false,
        reason: 'Mindestlevel ${voucher.minLevel} noch nicht erreicht.',
      );
    }

    final visibleThreshold = (voucher.starPrice * 0.6).floor();
    if (rewardState.stars < visibleThreshold) {
      return const VoucherVisibilityResult(
        visible: false,
        redeemable: false,
        reason: 'Noch nicht sichtbar.',
      );
    }

    if (rewardState.stars < voucher.starPrice) {
      return VoucherVisibilityResult(
        visible: true,
        redeemable: false,
        reason: 'Noch ${voucher.starPrice - rewardState.stars} Sterne sammeln.',
      );
    }

    final dailyLimit = voucher.dailyLimit;
    if (dailyLimit != null && redemptionsToday >= dailyLimit) {
      return const VoucherVisibilityResult(
        visible: true,
        redeemable: false,
        reason: 'Tageslimit erreicht.',
      );
    }

    return const VoucherVisibilityResult(visible: true, redeemable: true);
  }

  RewardState redeemVoucher({
    required Voucher voucher,
    required RewardState rewardState,
    required bool parentPinApproved,
  }) {
    if (voucher.requiresParentPin && !parentPinApproved) {
      throw StateError('Parent PIN required for voucher redemption.');
    }
    if (rewardState.stars < voucher.starPrice) {
      throw StateError('Not enough stars for voucher redemption.');
    }

    return RewardState(
      childId: rewardState.childId,
      stars: rewardState.stars - voucher.starPrice,
      xp: rewardState.xp,
      level: rewardState.level,
      badges: rewardState.badges,
      lastRewardAt: rewardState.lastRewardAt,
    );
  }
}
