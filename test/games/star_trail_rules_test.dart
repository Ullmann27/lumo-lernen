import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/star_trail/star_trail_rules.dart';

void main() {
  test('Same seed and move sequence produce the same card offers', () {
    var a = StarTrailState.begin(seed: 20261103);
    var b = StarTrailState.begin(seed: 20261103);
    for (var step = 0; step < 8; step++) {
      expect(a.choices.map((c) => c.kind),
          b.choices.map((c) => c.kind));
      final safeA = a.choices.indexWhere((c) => c.kind == TrailKind.lantern);
      final safeB = b.choices.indexWhere((c) => c.kind == TrailKind.lantern);
      expect(safeA, safeB);
      a = a.play(safeA);
      b = b.play(safeB);
      expect(a.distance, b.distance);
      expect(a.stars, b.stars);
      expect(a.light, b.light);
    }
  });

  test('Every seed has a safe route without adversarial randomness', () {
    for (var seed = 0; seed < 150; seed++) {
      var state = StarTrailState.begin(seed: seed);
      while (!state.finished) {
        final lantern = state.choices.indexWhere(
            (card) => card.kind == TrailKind.lantern);
        expect(lantern, greaterThanOrEqualTo(0));
        expect(state.canPlay(lantern), isTrue);
        state = state.play(lantern);
      }
      expect(state.won, isTrue);
      expect(state.turn, StarTrailState.goalDistance);
      expect(state.distance, StarTrailState.goalDistance);
      expect(state.stars, greaterThanOrEqualTo(StarTrailState.goalStars));
    }
  });

  test('Invalid and unaffordable choices consume neither turn nor light', () {
    final start = StarTrailState.begin(seed: 7);
    expect(identical(start.play(-1), start), isTrue);
    expect(identical(start.play(100), start), isTrue);
    for (var seed = 0; seed < 200; seed++) {
      var state = StarTrailState.begin(seed: seed);
      // Spend or preserve a bounded amount of light until a costly option
      // eventually becomes unaffordable; no invalid move may mutate state.
      for (var turn = 0; turn < 12 && !state.finished; turn++) {
        for (var i = 0; i < state.choices.length; i++) {
          if (!state.canPlay(i)) {
            expect(identical(state.play(i), state), isTrue);
          }
        }
        final lantern =
            state.choices.indexWhere((c) => c.kind == TrailKind.lantern);
        state = state.play(lantern);
      }
    }
  });

  test('No moves or extra stars after the winning turn', () {
    var state = StarTrailState.begin(seed: 42);
    while (!state.finished) {
      final safe = state.choices.indexWhere(
          (card) => card.kind == TrailKind.lantern);
      state = state.play(safe);
    }
    expect(state.won, isTrue);
    expect(state.choices, isEmpty);
    expect(identical(state.play(0), state), isTrue);
  });

  test('All costs and progress stay bounded for many choices', () {
    for (var seed = 0; seed < 80; seed++) {
      var state = StarTrailState.begin(seed: seed);
      while (!state.finished) {
        final playable = <int>[
          for (var i = 0; i < state.choices.length; i++)
            if (state.canPlay(i)) i,
        ];
        expect(playable, isNotEmpty);
        final index = playable[(state.turn + seed) % playable.length];
        state = state.play(index);
        expect(state.light, inInclusiveRange(0, StarTrailState.maxLight));
        expect(state.distance,
            inInclusiveRange(0, StarTrailState.goalDistance));
        expect(state.turn,
            inInclusiveRange(1, StarTrailState.maxTurns));
      }
      expect(state.won || state.turn == StarTrailState.maxTurns, isTrue);
    }
  });
}
