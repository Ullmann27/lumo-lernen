import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_engine.dart';

void main() {
  test('all 69 winning lines, both players; empty board is not a win', () {
    var lines = 0;
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 7; c++) {
        for (final (dr, dc) in ConnectFourEngine.directions) {
          if (r + 3 * dr < 0 ||
              r + 3 * dr >= 6 ||
              c + 3 * dc < 0 ||
              c + 3 * dc >= 7) {
            continue;
          }
          lines++;
          for (final player in [ConnectPiece.child, ConnectPiece.lumo]) {
            final board =
                List.generate(6, (_) => List.filled(7, ConnectPiece.empty));
            for (var k = 0; k < 4; k++) {
              board[r + k * dr][c + k * dc] = player;
            }
            expect(
                ConnectFourEngine.findWinningLine(board, player), hasLength(4));
            board[r + 2 * dr][c + 2 * dc] = ConnectPiece.empty;
            expect(ConnectFourEngine.findWinningLine(board, player), isEmpty);
          }
        }
      }
    }
    expect(lines, 69);
    expect(
        ConnectFourEngine.findWinningLine(
            List.generate(6, (_) => List.filled(7, ConnectPiece.empty)),
            ConnectPiece.empty),
        isEmpty);
  });

  test('gravity, full column and invalid input do not consume a turn', () {
    final game = ConnectFourEngine();
    expect(game.drop(-1), isNull);
    expect(game.drop(7), isNull);
    for (var row = 5; row >= 0; row--) {
      expect(game.drop(0), (row: row, column: 0));
    }
    final before = game.turn;
    expect(game.drop(0), isNull);
    expect(game.turn, before);
    expect(game.moves, 6);
  });

  test('completed game blocks further moves and retains winner', () {
    final game = ConnectFourEngine();
    for (final c in [0, 6, 1, 6, 2, 5, 3]) {
      expect(game.drop(c), isNotNull);
    }
    expect(game.phase, ConnectPhase.won);
    expect(game.turn, ConnectPiece.child);
    expect(game.drop(4), isNull);
    expect(game.moves, 7);
  });

  test('bot blocks immediate wins without changing real state', () {
    final game = ConnectFourEngine();
    for (final c in [0, 6, 1, 6, 2]) {
      game.drop(c);
    }
    final before = [
      for (var r = 0; r < 6; r++) [for (var c = 0; c < 7; c++) game.at(r, c)],
    ];
    expect(game.chooseLumoColumn(Random(1)), 3);
    expect(game.moves, 5);
    expect([
      for (var r = 0; r < 6; r++) [for (var c = 0; c < 7; c++) game.at(r, c)],
    ], before);
  });

  test('reachable 42-move draw has no earlier win', () {
    // Alternating pairs tiled across the board avoid fours in all directions.
    final target = [
      [1, 1, 2, 2, 1, 1, 2],
      [2, 2, 1, 1, 2, 2, 1],
      [1, 1, 2, 2, 1, 1, 2],
      [2, 2, 1, 1, 2, 2, 1],
      [1, 1, 2, 2, 1, 1, 2],
      [2, 2, 1, 1, 2, 2, 1],
    ];
    final game = ConnectFourEngine();
    final heights = List.filled(7, 5);
    for (var move = 0; move < 42; move++) {
      final player = game.turn == ConnectPiece.child ? 1 : 2;
      final c = List.generate(7, (i) => i).firstWhere(
          (c) => heights[c] >= 0 && target[heights[c]][c] == player);
      expect(game.drop(c), isNotNull);
      heights[c]--;
      expect(game.phase, move == 41 ? ConnectPhase.draw : ConnectPhase.playing);
    }
    expect(game.drop(0), isNull);
  });
}
