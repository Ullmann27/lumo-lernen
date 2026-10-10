import 'dart:math';

enum ConnectPiece { empty, child, lumo }

enum ConnectPhase { playing, won, draw }

typedef ConnectPosition = ({int row, int column});

/// Rules only: no widgets, timers, plugins, wallet or mutable search moves.
class ConnectFourEngine {
  static const rows = 6;
  static const columns = 7;
  static const directions = [(0, 1), (1, 0), (1, 1), (1, -1)];

  final List<List<ConnectPiece>> _board =
      List.generate(rows, (_) => List.filled(columns, ConnectPiece.empty));
  ConnectPiece turn = ConnectPiece.child;
  ConnectPhase phase = ConnectPhase.playing;
  List<ConnectPosition> winningLine = const [];
  int moves = 0;

  ConnectPiece at(int row, int column) => _board[row][column];
  List<int> get validColumns => [
        for (var c = 0; c < columns; c++)
          if (_board[0][c] == ConnectPiece.empty) c,
      ];

  /// Invalid input and completed games never change the board or turn.
  ConnectPosition? drop(int column) {
    if (phase != ConnectPhase.playing ||
        column < 0 ||
        column >= columns ||
        _board[0][column] != ConnectPiece.empty) {
      return null;
    }
    final row = _landingRow(column);
    _board[row][column] = turn;
    moves++;
    winningLine = findWinningLine(_board, turn);
    if (winningLine.isNotEmpty) {
      phase = ConnectPhase.won;
    } else if (moves == rows * columns) {
      phase = ConnectPhase.draw;
    } else {
      turn =
          turn == ConnectPiece.child ? ConnectPiece.lumo : ConnectPiece.child;
    }
    return (row: row, column: column);
  }

  int _landingRow(int column) {
    for (var row = rows - 1; row >= 0; row--) {
      if (_board[row][column] == ConnectPiece.empty) return row;
    }
    throw StateError('Column has no empty cell');
  }

  static List<ConnectPosition> findWinningLine(
      List<List<ConnectPiece>> board, ConnectPiece who) {
    if (who == ConnectPiece.empty) return const [];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        for (final (dr, dc) in directions) {
          final endR = r + dr * 3;
          final endC = c + dc * 3;
          if (endR < 0 || endR >= rows || endC < 0 || endC >= columns) continue;
          if (List.generate(4, (k) => board[r + dr * k][c + dc * k])
              .every((cell) => cell == who)) {
            return [
              for (var k = 0; k < 4; k++) (row: r + dr * k, column: c + dc * k),
            ];
          }
        }
      }
    }
    return const [];
  }

  /// Fair beginner bot. Simulations use copies, so suggestions never mutate
  /// real state and cannot erase a piece after an interrupted turn.
  int? chooseLumoColumn(Random random) {
    if (phase != ConnectPhase.playing || turn != ConnectPiece.lumo) return null;
    final valid = validColumns;
    if (valid.isEmpty) return null;
    for (final who in [ConnectPiece.lumo, ConnectPiece.child]) {
      for (final c in valid) {
        final board = _simulation(c, who);
        if (findWinningLine(board, who).isNotEmpty) return c;
      }
    }
    if (random.nextDouble() < .30) return valid[random.nextInt(valid.length)];
    var best = valid.first;
    var bestScore = -100000;
    for (final c in valid) {
      final score = _potential(_simulation(c, ConnectPiece.lumo)) -
          (c - columns ~/ 2).abs() * 2;
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    return best;
  }

  List<List<ConnectPiece>> _simulation(int c, ConnectPiece who) {
    final copy = _board.map((row) => row.toList()).toList();
    copy[_landingRow(c)][c] = who;
    return copy;
  }

  int _potential(List<List<ConnectPiece>> board) {
    var score = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        for (final (dr, dc) in directions) {
          final endR = r + dr * 3;
          final endC = c + dc * 3;
          if (endR < 0 || endR >= rows || endC < 0 || endC >= columns) continue;
          final line = List.generate(4, (k) => board[r + dr * k][c + dc * k]);
          if (!line.contains(ConnectPiece.child)) {
            final mine = line.where((cell) => cell == ConnectPiece.lumo).length;
            score += mine * mine;
          }
        }
      }
    }
    return score;
  }
}
