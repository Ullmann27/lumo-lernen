import '../../../domain/iq/iq_puzzle.dart';

/// Sterne und XP für einen Knobel-Test.
class IqReward {
  const IqReward({required this.stars, required this.xp});

  static const none = IqReward(stars: 0, xp: 0);

  final int stars;
  final int xp;

  bool get isEmpty => stars == 0 && xp == 0;
}

/// Regeln für die Belohnung: ein Stern je vier gelöste Rätsel, die XP sind die
/// Denkpunkte – und das höchstens einmal pro Kalendertag. So lohnt es sich
/// nicht, den Test immer wieder nur für Sterne zu machen.
class IqRewardPolicy {
  const IqRewardPolicy();

  static const solvedPerStar = 4;

  IqReward forResult(IqTestResult result) => IqReward(
        stars: result.solved ~/ solvedPerStar,
        xp: result.thinkingPoints,
      );

  /// Gab es an diesem Tag schon einen gespeicherten Test?
  bool alreadyDoneOn(Iterable<IqTestResult> earlier, DateTime day) => earlier.any(
        (result) =>
            result.finishedAt.year == day.year &&
            result.finishedAt.month == day.month &&
            result.finishedAt.day == day.day,
      );
}
