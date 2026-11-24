import 'dart:math';

enum ConnectPiece { empty, child, lumo }

enum ConnectPhase { playing, won, draw }

/// Kid-friendly Lumo strengths. [mittel] is the historical beginner bot.
enum ConnectLumoLevel { leicht, mittel, schlau }

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

  /// Fair opponents see only the public board. Search uses a private scratch
  /// board, so a suggestion never changes the real turn, pieces or result.
  ///
  /// [level] defaults to [ConnectLumoLevel.mittel], the historical behaviour
  /// (always take a win, always block, 30 % random otherwise).
  int? chooseLumoColumn(
    Random random, {
    ConnectLumoLevel level = ConnectLumoLevel.mittel,
  }) {
    if (phase != ConnectPhase.playing || turn != ConnectPiece.lumo) return null;
    final valid = validColumns;
    if (valid.isEmpty) return null;
    if (level == ConnectLumoLevel.schlau) {
      return _ConnectFourSearch(_board).choose();
    }
    for (final c in valid) {
      if (findWinningLine(_simulation(c, ConnectPiece.lumo), ConnectPiece.lumo)
          .isNotEmpty) {
        return c;
      }
    }
    final blockChance = switch (level) {
      ConnectLumoLevel.leicht => 0.35,
      ConnectLumoLevel.mittel || ConnectLumoLevel.schlau => 1.0,
    };
    if (random.nextDouble() < blockChance) {
      for (final c in valid) {
        if (findWinningLine(
                _simulation(c, ConnectPiece.child), ConnectPiece.child)
            .isNotEmpty) {
          return c;
        }
      }
    }
    final wander = switch (level) {
      ConnectLumoLevel.leicht => 0.65,
      ConnectLumoLevel.mittel => 0.30,
      ConnectLumoLevel.schlau => 0.0,
    };
    if (wander > 0 && random.nextDouble() < wander) {
      return valid[random.nextInt(valid.length)];
    }
    var best = valid.first;
    var bestScore = -100000;
    for (final c in valid) {
      var score = _potential(_simulation(c, ConnectPiece.lumo)) -
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

/// Bounded six-ply alpha-beta search for the existing "Schlau" setting.
/// Iterative deepening keeps only a fully examined root iteration. The node
/// budget bounds synchronous mobile work independently of the board position.
/// Only this private copy is changed; no profile, timer or random seed is read.
class _ConnectFourSearch {
  _ConnectFourSearch(List<List<ConnectPiece>> board)
      : _cells = [
          for (final row in board)
            for (final piece in row)
              piece == ConnectPiece.lumo
                  ? 1
                  : piece == ConnectPiece.child
                      ? -1
                      : 0,
        ] {
    for (var c = 0; c < 7; c++) {
      var row = 5;
      while (row >= 0 && _cells[row * 7 + c] != 0) {
        row--;
      }
      _nextRow[c] = row;
    }
  }

  static const _order = [3, 2, 4, 1, 5, 0, 6];
  static const _win = 100000;
  static const _nodeLimit = 18000;
  static const _weights = [0, 2, 12, 72, 0];
  static final _windows = <List<int>>[
    for (var r = 0; r < 6; r++)
      for (var c = 0; c < 7; c++)
        for (final (dr, dc) in ConnectFourEngine.directions)
          if (r + dr * 3 >= 0 &&
              r + dr * 3 < 6 &&
              c + dc * 3 >= 0 &&
              c + dc * 3 < 7)
            [for (var k = 0; k < 4; k++) (r + dr * k) * 7 + c + dc * k],
  ];

  final List<int> _cells;
  final List<int> _nextRow = List.filled(7, 5);
  int _nodes = 0;
  bool _exhausted = false;

  int choose() {
    var best = _order.firstWhere((c) => _nextRow[c] >= 0);
    for (var depth = 1; depth <= 6; depth++) {
      var iterationBest = best;
      var iterationScore = -_win * 2;
      for (final c in _order) {
        final row = _nextRow[c];
        if (row < 0) continue;
        _place(c, 1);
        final score = _wonAt(row, c, 1)
            ? _win
            : _search(depth - 1, iterationScore, _win * 2, -1, 1);
        _undo(c);
        if (_exhausted) break;
        if (score > iterationScore) {
          iterationScore = score;
          iterationBest = c;
        }
      }
      if (_exhausted) break;
      best = iterationBest;
      if (iterationScore >= _win - 6) break;
    }
    return best;
  }

  int _search(int depth, int alpha, int beta, int who, int ply) {
    if (++_nodes > _nodeLimit) {
      _exhausted = true;
      return 0;
    }
    var hasMove = false;
    for (final row in _nextRow) {
      if (row >= 0) hasMove = true;
    }
    if (!hasMove) return 0;
    if (depth == 0) return _evaluate();
    var best = who == 1 ? -_win * 2 : _win * 2;
    for (final c in _order) {
      final row = _nextRow[c];
      if (row < 0) continue;
      _place(c, who);
      final score = _wonAt(row, c, who)
          ? who * (_win - ply)
          : _search(depth - 1, alpha, beta, -who, ply + 1);
      _undo(c);
      if (_exhausted) return 0;
      if (who == 1) {
        if (score > best) best = score;
        if (best > alpha) alpha = best;
      } else {
        if (score < best) best = score;
        if (best < beta) beta = best;
      }
      if (alpha >= beta) break;
    }
    return best;
  }

  void _place(int column, int who) {
    _cells[_nextRow[column] * 7 + column] = who;
    _nextRow[column]--;
  }

  void _undo(int column) {
    _nextRow[column]++;
    _cells[_nextRow[column] * 7 + column] = 0;
  }

  bool _wonAt(int row, int column, int who) {
    for (final (dr, dc) in ConnectFourEngine.directions) {
      var length = 1;
      for (final sign in const [-1, 1]) {
        var r = row + dr * sign;
        var c = column + dc * sign;
        while (r >= 0 && r < 6 && c >= 0 && c < 7 && _cells[r * 7 + c] == who) {
          length++;
          r += dr * sign;
          c += dc * sign;
        }
      }
      if (length >= 4) return true;
    }
    return false;
  }

  int _evaluate() {
    var score = 0;
    for (var r = 0; r < 6; r++) {
      score += _cells[r * 7 + 3] * 5;
    }
    for (final line in _windows) {
      var mine = 0;
      var theirs = 0;
      var empty = -1;
      for (final cell in line) {
        switch (_cells[cell]) {
          case 1:
            mine++;
          case -1:
            theirs++;
          default:
            empty = cell;
        }
      }
      if (mine != 0 && theirs != 0) continue;
      score += _weights[mine] - _weights[theirs];
      if (empty >= 0 && _nextRow[empty % 7] == empty ~/ 7) {
        if (mine == 3) score += 90;
        if (theirs == 3) score -= 90;
      }
    }
    return score;
  }
}
