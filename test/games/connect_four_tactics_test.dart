import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_engine.dart';

ConnectFourEngine play(List<int> sequence) {
  final game = ConnectFourEngine();
  for (final column in sequence) {
    expect(game.phase, ConnectPhase.playing);
    expect(game.drop(column), isNotNull);
  }
  return game;
}

List<List<ConnectPiece>> boardOf(ConnectFourEngine game) => [
      for (var r = 0; r < 6; r++) [for (var c = 0; c < 7; c++) game.at(r, c)],
    ];

void main() {
  // Reachable positions where the previous one-move heuristic misses a fork.
  // Each chosen move is checked against EVERY legal child reply below.
  const positions = <List<int>>[
    [6, 5, 2, 2, 6, 1, 6, 1, 4, 0, 5, 6, 3],
    [3, 2, 6, 2, 0, 3, 4, 5, 0, 6, 5, 0, 1, 0, 1, 1, 6, 1, 0, 6, 4],
    [3, 2, 1, 0, 2, 2, 1, 0, 5, 3, 5, 1, 2],
  ];
  for (var fixture = 0; fixture < positions.length; fixture++) {
    for (final mirrored in [false, true]) {
      test('schlau forces fork $fixture, mirrored=$mirrored', () {
        final sequence = [
          for (final c in positions[fixture]) mirrored ? 6 - c : c,
        ];
        final game = play(sequence);
        expect(game.turn, ConnectPiece.lumo);
        final before = boardOf(game);
        final move =
            game.chooseLumoColumn(Random(7), level: ConnectLumoLevel.schlau);
        expect(move, isNotNull);
        expect(boardOf(game), before);
        expect(game.moves, sequence.length);
        expect(game.turn, ConnectPiece.lumo);
        expect(game.phase, ConnectPhase.playing);
        expect(game.winningLine, isEmpty);
        final after = play([...sequence, move!]);
        expect(after.phase, ConnectPhase.playing);
        for (final reply in after.validColumns) {
          final response = play([...sequence, move, reply]);
          expect(response.phase, ConnectPhase.playing,
              reason: 'Child must not win immediately at $reply');
          final winningColumns = <int>[];
          for (final answer in response.validColumns) {
            final result = play([...sequence, move, reply, answer]);
            if (result.phase == ConnectPhase.won &&
                result.turn == ConnectPiece.lumo) {
              winningColumns.add(answer);
            }
          }
          expect(winningColumns, isNotEmpty,
              reason: 'Every reply ($reply) must leave a real winning move');
        }
      });
    }
  }

  test('search terminates legally and preserves 40 reachable public boards',
      () {
    final random = Random(2018);
    var checked = 0;
    for (var trial = 0; trial < 120 && checked < 40; trial++) {
      final game = ConnectFourEngine();
      final count = 1 + random.nextInt(17) * 2;
      for (var i = 0; i < count && game.phase == ConnectPhase.playing; i++) {
        final valid = game.validColumns;
        game.drop(valid[random.nextInt(valid.length)]);
      }
      if (game.phase != ConnectPhase.playing) continue;
      final before = boardOf(game);
      final moves = game.moves;
      final move =
          game.chooseLumoColumn(Random(1), level: ConnectLumoLevel.schlau);
      expect(game.validColumns, contains(move));
      expect(boardOf(game), before);
      expect(game.moves, moves);
      expect(game.turn, ConnectPiece.lumo);
      expect(game.phase, ConnectPhase.playing);
      expect(game.winningLine, isEmpty);
      expect(game.chooseLumoColumn(Random(999), level: ConnectLumoLevel.schlau),
          move);
      checked++;
    }
    expect(checked, 40);
  });
}
