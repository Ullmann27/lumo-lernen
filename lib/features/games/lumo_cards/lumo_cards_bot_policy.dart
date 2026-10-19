import 'dart:math';

import 'lumo_cards_models.dart';
import 'lumo_cards_rules.dart';

/// Fair opponent: decides only from its own cards, the visible discard/colour
/// and the public count of opponent cards. Never observes human card values,
/// peeks into the deck or forces the winner.
class LumoCardsBotPolicy {
  const LumoCardsBotPolicy._();

  static LumoCard? select({
    required List<LumoCard> ownHand,
    required LumoCard topCard,
    required LumoCardColor selectedColor,
    required int opponentCardCount,
    required int grade,
    required Random rng,
  }) {
    final playable = [
      for (final card in ownHand)
        if (LumoCardsRules.isPlayable(
          card: card, topCard: topCard, selectedColor: selectedColor,
        ))
          card,
    ];
    if (playable.isEmpty) return null;
    if (playable.length == 1) return playable.single;

    // A grade affects tactical consistency, not the deck, legal moves,
    // player's own choices, scoring or the definition of victory.
    final schoolYear = grade.clamp(1, 4);
    int score(LumoCard card) {
      final sameColor = ownHand.where((item) => item.color == card.color).length;
      final humanAlmostDone = opponentCardCount <= 2;
      return switch (card.type) {
        LumoCardType.number => 30 + (card.number ?? 0) + sameColor * 3,
        LumoCardType.lumoJump => humanAlmostDone ? 90 : 60,
        LumoCardType.starRain => humanAlmostDone ? 90 : 59,
        LumoCardType.whirlwind => humanAlmostDone ? 84 : 53,
        LumoCardType.thinkPause => 43,
        LumoCardType.colorMagic =>
          playable.any((item) => !item.isWild) ? 18 : 79,
        LumoCardType.superRain => humanAlmostDone ? 89 : 13,
      };
    }

    // Variation is deliberately visible between equally legal games.
    // Even class four is beatable: the opponent never runs a perfect solver.
    final explore = switch (schoolYear) {
      1 => 0.32,
      2 => 0.23,
      3 => 0.15,
      _ => 0.10,
    };
    if (rng.nextDouble() < explore) {
      return playable[rng.nextInt(playable.length)];
    }

    // Weighted choices among credible alternatives; do not always prefer
    // the same card type or the same fixed tie-breaking order.
    final best = playable.map(score).reduce(max);
    final slack = switch (schoolYear) { 1 => 24, 2 => 18, 3 => 12, _ => 8 };
    final candidates = playable.where((c) => best - score(c) <= slack).toList();
    final weights = [
      for (final card in candidates)
        max(1, 16 + score(card) - best),
    ];
    var ticket = rng.nextInt(weights.fold<int>(0, (sum, n) => sum + n));
    for (var i = 0; i < candidates.length; i++) {
      ticket -= weights[i];
      if (ticket < 0) return candidates[i];
    }
    return candidates.last;
  }

  static LumoCardColor selectColor({
    required List<LumoCard> ownHand,
    required Random rng,
  }) {
    final counts = {
      for (final color in LumoCardColor.values)
        color: ownHand.where((card) => !card.isWild && card.color == color).length,
    };
    final highest = counts.values.reduce(max);
    final tied = [
      for (final color in LumoCardColor.values)
        if (counts[color] == highest) color,
    ];
    return tied[rng.nextInt(tied.length)];
  }

  /// The learning challenge is deliberately separate from the winner logic.
  static double answerProbability(int grade) => switch (grade.clamp(1, 4)) {
    1 => .55,
    2 => .64,
    3 => .72,
    _ => .80,
  };
}
