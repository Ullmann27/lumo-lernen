import 'dart:math';

/// Lumo Sternenpfad: a cooperative route-building card game, not a
/// colour/number matching or take-that shedding game.
///
/// No time pressure, internet, personal data or hidden random rewards.
/// Every choice set contains a Lantern card, so the goal is always reachable
/// in twelve turns by a child who prefers simple, safe decisions.
enum TrailKind { lantern, steppingStone, comet, rainbowBridge, restNest }

class TrailCard {
  const TrailCard(this.kind);

  final TrailKind kind;

  String get name => switch (kind) {
        TrailKind.lantern => 'Sternlaterne',
        TrailKind.steppingStone => 'Trittstein',
        TrailKind.comet => 'Kometensprung',
        TrailKind.rainbowBridge => 'Regenbogen',
        TrailKind.restNest => 'Ruheinsel',
      };

  String get symbol => switch (kind) {
        TrailKind.lantern => '⭐',
        TrailKind.steppingStone => '🪨',
        TrailKind.comet => '☄️',
        TrailKind.rainbowBridge => '🌈',
        TrailKind.restNest => '🌙',
      };

  String get description => switch (kind) {
        TrailKind.lantern => '1 Insel · 1 Stern',
        TrailKind.steppingStone => '2 Inseln',
        TrailKind.comet => '2 Inseln · kostet 1 Licht',
        TrailKind.rainbowBridge => '3 Inseln · 1 Stern · kostet 2 Licht',
        TrailKind.restNest => '2 Licht · 1 Stern',
      };

  int get distance => switch (kind) {
        TrailKind.lantern => 1,
        TrailKind.steppingStone => 2,
        TrailKind.comet => 2,
        TrailKind.rainbowBridge => 3,
        TrailKind.restNest => 0,
      };

  int get lightCost => switch (kind) {
        TrailKind.comet => 1,
        TrailKind.rainbowBridge => 2,
        _ => 0,
      };

  int get lightGain => kind == TrailKind.restNest ? 2 : 0;

  int get stars => switch (kind) {
        TrailKind.lantern || TrailKind.rainbowBridge || TrailKind.restNest => 1,
        _ => 0,
      };
}

class StarTrailState {
  const StarTrailState({
    required this.seed,
    required this.turn,
    required this.distance,
    required this.stars,
    required this.light,
    required this.choices,
    required this.finished,
    required this.won,
  });

  static const int goalDistance = 12;
  static const int goalStars = 6;
  static const int maxTurns = 16;
  static const int maxLight = 5;

  final int seed;
  final int turn;
  final int distance;
  final int stars;
  final int light;
  final List<TrailCard> choices;
  final bool finished;
  final bool won;

  static StarTrailState begin({int seed = 1}) => StarTrailState(
        seed: seed,
        turn: 0,
        distance: 0,
        stars: 0,
        light: 3,
        choices: _draw(seed, 0),
        finished: false,
        won: false,
      );

  /// Deterministic choice generation; the always-present Lantern guarantees
  /// that a calm, twelve-turn winning route exists for every seed.
  static List<TrailCard> _draw(int seed, int turn) {
    final rng = Random(seed ^ (turn + 1) * 7919);
    const others = [
      TrailKind.steppingStone,
      TrailKind.comet,
      TrailKind.rainbowBridge,
      TrailKind.restNest,
    ];
    final choices = <TrailCard>[
      const TrailCard(TrailKind.lantern),
      TrailCard(others[rng.nextInt(others.length)]),
      TrailCard(others[rng.nextInt(others.length)]),
    ];
    choices.shuffle(rng);
    return List.unmodifiable(choices);
  }

  bool canPlay(int index) =>
      !finished &&
      index >= 0 &&
      index < choices.length &&
      light >= choices[index].lightCost;

  /// Immutable transition. Invalid or unaffordable choices leave the
  /// original state untouched and never consume a turn or a reward.
  StarTrailState play(int index) {
    if (!canPlay(index)) return this;
    final card = choices[index];
    final nextTurn = turn + 1;
    final nextDistance =
        min(goalDistance, distance + card.distance);
    final nextStars = stars + card.stars;
    final nextLight =
        (light - card.lightCost + card.lightGain).clamp(0, maxLight).toInt();
    final success =
        nextDistance >= goalDistance && nextStars >= goalStars;
    final over = success || nextTurn >= maxTurns;
    return StarTrailState(
      seed: seed,
      turn: nextTurn,
      distance: nextDistance,
      stars: nextStars,
      light: nextLight,
      choices: over ? const [] : _draw(seed, nextTurn),
      finished: over,
      won: success,
    );
  }
}
