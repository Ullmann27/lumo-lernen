import 'dart:math';

import 'lumo_cards_models.dart';
import 'lumo_cards_rules.dart';

enum LumoCardsDifficulty { relaxed, clever, expert }

enum LumoCardsStyle { planner, adventurous, collector }

extension LumoCardsDifficultyLabel on LumoCardsDifficulty {
  String get label => switch (this) {
    LumoCardsDifficulty.relaxed => 'Entspannt',
    LumoCardsDifficulty.clever => 'Schlau',
    LumoCardsDifficulty.expert => 'Knifflig',
  };

  String get description => switch (this) {
    LumoCardsDifficulty.relaxed =>
      'Lumo probiert verschiedene passende Karten.',
    LumoCardsDifficulty.clever => 'Lumo plant Farben und besondere Karten.',
    LumoCardsDifficulty.expert => 'Lumo plant auch mehrere Sprünge voraus.',
  };
}

extension LumoCardsStyleLabel on LumoCardsStyle {
  String get label => switch (this) {
    LumoCardsStyle.planner => 'Taktiker',
    LumoCardsStyle.adventurous => 'Wirbelwind',
    LumoCardsStyle.collector => 'Farbenfreund',
  };

  String get description => switch (this) {
    LumoCardsStyle.planner => 'Hebt Farbzauber auf und plant den nächsten Zug.',
    LumoCardsStyle.adventurous =>
      'Setzt Sternenregen und Wirbelwind früher ein.',
    LumoCardsStyle.collector => 'Spielt gern längere Reihen derselben Farbe.',
  };
}

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
    LumoCardsDifficulty difficulty = LumoCardsDifficulty.clever,
    LumoCardsStyle style = LumoCardsStyle.planner,
  }) {
    final playable = [
      for (final card in ownHand)
        if (LumoCardsRules.isPlayable(
          card: card,
          topCard: topCard,
          selectedColor: selectedColor,
        ))
          card,
    ];
    if (playable.isEmpty) return null;
    if (playable.length == 1) return playable.single;

    // School year belongs to the learning questions. Playing strength is an
    // explicit choice and never changes the deal or the opponent's cards.
    final explore = switch (difficulty) {
      LumoCardsDifficulty.relaxed => .65,
      LumoCardsDifficulty.clever => .12,
      LumoCardsDifficulty.expert => .0,
    };
    if (rng.nextDouble() < explore) {
      return playable[rng.nextInt(playable.length)];
    }
    final depth = switch (difficulty) {
      LumoCardsDifficulty.relaxed => 0,
      LumoCardsDifficulty.clever => 1,
      LumoCardsDifficulty.expert => 3,
    };
    final scores = {
      for (final card in playable)
        card: _score(card, ownHand, opponentCardCount, style, depth),
    };
    final best = scores.values.reduce(max);
    final slack = switch (difficulty) {
      LumoCardsDifficulty.relaxed => 32.0,
      LumoCardsDifficulty.clever => 10.0,
      LumoCardsDifficulty.expert => 0.001,
    };
    final candidates = playable
        .where((c) => best - scores[c]! <= slack)
        .toList();
    return candidates[rng.nextInt(candidates.length)];
  }

  static double _score(
    LumoCard card,
    List<LumoCard> hand,
    int opponentCount,
    LumoCardsStyle style,
    int depth,
  ) {
    final remaining = hand.where((c) => c.id != card.id).toList();
    if (remaining.isEmpty) return 10000;
    final danger = opponentCount <= 2;
    final offensive = style == LumoCardsStyle.adventurous;
    final collector = style == LumoCardsStyle.collector;
    final color = card.isWild ? _strongestColor(remaining) : card.color;
    final colorCount = remaining
        .where((c) => !c.isWild && c.color == color)
        .length;
    final followUps = remaining
        .where(
          (c) => LumoCardsRules.isPlayable(
            card: c,
            topCard: card,
            selectedColor: color,
          ),
        )
        .toList();
    // Keeping a connected hand is a possibility for the next turn, not a
    // prediction of hidden opponent cards. Only Skip guarantees another turn.
    var score = 20.0 + colorCount * (collector ? 13 : 5) + followUps.length * 3;
    score += switch (card.type) {
      LumoCardType.number => (card.number ?? 0) * .35,
      LumoCardType.lumoJump => danger ? 55 : 28,
      LumoCardType.starRain => danger ? 85 : (offensive ? 55 : 12),
      LumoCardType.whirlwind => danger ? 52 : (offensive ? 38 : 8),
      LumoCardType.thinkPause => 5,
      LumoCardType.colorMagic => -24,
      LumoCardType.superRain => danger ? 105 : (offensive ? 42 : -30),
    };
    if (followUps.isEmpty) score -= 30;
    if (card.type == LumoCardType.lumoJump &&
        depth > 0 &&
        followUps.isNotEmpty) {
      // In this game's actual two-player rules only Lumo-Sprung keeps the
      // turn. StarRain and Whirlwind do not; do not assume UNO rules here.
      final continuation = followUps
          .map(
            (next) => _score(next, remaining, opponentCount, style, depth - 1),
          )
          .reduce(max);
      score += continuation >= 10000 ? 10000 : 35 + continuation * .65;
    }
    return score;
  }

  static LumoCardColor _strongestColor(List<LumoCard> hand) {
    var best = LumoCardColor.values.first;
    var bestCount = -1;
    for (final color in LumoCardColor.values) {
      final count = hand
          .where((card) => !card.isWild && card.color == color)
          .length;
      if (count > bestCount) {
        best = color;
        bestCount = count;
      }
    }
    return best;
  }

  static LumoCardColor selectColor({
    required List<LumoCard> ownHand,
    required Random rng,
  }) {
    final counts = {
      for (final color in LumoCardColor.values)
        color: ownHand
            .where((card) => !card.isWild && card.color == color)
            .length,
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
