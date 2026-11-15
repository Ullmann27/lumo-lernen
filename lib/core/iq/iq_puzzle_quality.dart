import '../../domain/iq/iq_puzzle.dart';

/// Checks the visible givens independently of the stored answer index.
/// Each of the eight existing levels has its declared, deterministic rule.
abstract final class IqPuzzleQuality {
  static List<String> problems(IqPuzzle puzzle) {
    final errors = <String>[];
    if (puzzle.id.isEmpty ||
        puzzle.question.trim().isEmpty ||
        puzzle.explanation.trim().isEmpty ||
        puzzle.level < 1 ||
        puzzle.level > 8) {
      errors.add('invalid_metadata');
    }
    if (puzzle is IqChoicePuzzle &&
        (puzzle.answer < 0 ||
            puzzle.answer >= puzzle.optionCount ||
            puzzle.optionCount < 4)) {
      errors.add('invalid_answer_index');
      return errors;
    }
    List<int> matching = [];
    switch (puzzle) {
      case IqMatrixPuzzle p:
        if (p.columns < 2 ||
            p.cells.length != p.columns * p.columns ||
            p.cells.where((cell) => cell == null).length != 1 ||
            p.cells.last != null) {
          errors.add('invalid_matrix');
          break;
        }
        _figures([...p.cells.whereType<IqFigure>(), ...p.options], errors);
        _unique(p.options.map((f) => f.key), errors);
        matching = [
          for (var i = 0; i < p.options.length; i++)
            if (_matrixFits(p, p.options[i])) i
        ];
      case IqSeriesPuzzle p:
        _figures([...p.shown, ...p.options], errors);
        _unique(p.options.map((f) => f.key), errors);
        if (p.shown.length < 4) {
          errors.add('insufficient_series');
          break;
        }
        matching = [
          for (var i = 0; i < p.options.length; i++)
            if (_seriesFits(p, p.options[i])) i
        ];
      case IqOddOnePuzzle p:
        _figures(p.figures, errors);
        final singledOut = <int>{};
        final attributes = <Object Function(IqFigure)>[
          (f) => f.shape,
          (f) => f.tint,
          (f) => f.count,
          (f) => f.shape.directional ? f.turns % 8 : 0,
          (f) => f.size,
          (f) => f.filled,
        ];
        for (final attribute in attributes) {
          final values = p.figures.map(attribute).toList();
          for (var i = 0; i < values.length; i++) {
            final others = [...values]..removeAt(i);
            if (others.isNotEmpty &&
                others.toSet().length == 1 &&
                others.first != values[i]) {
              singledOut.add(i);
            }
          }
        }
        matching = singledOut.toList();
      case IqRotationPuzzle p:
        for (final piece in [p.target, ...p.options]) {
          if (!_connected(piece)) errors.add('invalid_rotation_piece');
        }
        _unique(p.options.map((piece) => piece.key), errors);
        matching = [
          for (var i = 0; i < p.options.length; i++)
            if (p.options[i].sameAsRotationOf(p.target)) i
        ];
      case IqNumberPuzzle p:
        _unique(p.options, errors);
        if (p.numbers.where((n) => n == null).length != 1 ||
            p.numbers.length < 5 ||
            p.options.any((n) => n <= 0)) {
          errors.add('invalid_number_sequence');
          break;
        }
        matching = [
          for (var i = 0; i < p.options.length; i++)
            if (_numberRule(
                p.level, [for (final n in p.numbers) n ?? p.options[i]]))
              i
        ];
      case IqMemoryPuzzle p:
        if (p.gridSize < 3 ||
            p.gridSize > 4 ||
            p.sequence.length < 2 ||
            p.sequence.length > 7 ||
            p.sequence.toSet().length != p.sequence.length ||
            p.sequence
                .any((cell) => cell < 0 || cell >= p.gridSize * p.gridSize) ||
            p.showMs <= 0 ||
            p.gapMs < 0) {
          errors.add('invalid_memory_sequence');
        }
    }
    if (puzzle is IqChoicePuzzle &&
        (matching.length != 1 || matching.single != puzzle.answer)) {
      errors.add('answer_not_uniquely_supported');
    }
    return errors;
  }

  static void _unique(Iterable<Object> values, List<String> errors) {
    final list = values.toList();
    if (list.toSet().length != list.length) errors.add('duplicate_options');
  }

  static void _figures(Iterable<IqFigure> values, List<String> errors) {
    if (values
        .any((f) => f.count < 1 || f.count > 6 || f.size < 0 || f.size > 2)) {
      errors.add('unrenderable_figure');
    }
  }

  static bool _matrixFits(IqMatrixPuzzle p, IqFigure candidate) {
    final n = p.columns;
    final cells = [for (final f in p.cells) f ?? candidate];
    final first = cells.first;
    final lastRow = cells[(n - 1) * n];
    IqFigure? expected;
    switch (p.level) {
      case 1:
        expected = lastRow;
      case 2:
      case 3:
        expected = lastRow.copyWith(shape: cells[n - 1].shape);
      case 4:
        expected = lastRow.copyWith(count: n);
      case 5:
        if (!lastRow.shape.directional) return false;
        expected = lastRow.copyWith(turns: lastRow.turns + 2 * (n - 1));
      case 6:
      case 7:
      case 8:
        bool latin(Object Function(IqFigure) attribute) {
          final all = cells.take(n).map(attribute).toSet();
          if (all.length != n) return false;
          for (var r = 0; r < n; r++) {
            if (cells.skip(r * n).take(n).map(attribute).toSet().length != n ||
                cells
                    .skip(r * n)
                    .take(n)
                    .any((f) => !all.contains(attribute(f)))) {
              return false;
            }
            final column = [
              for (var c = 0; c < n; c++) attribute(cells[c * n + r])
            ];
            if (column.toSet().length != n ||
                column.any((v) => !all.contains(v))) {
              return false;
            }
          }
          return true;
        }
        if (!latin((f) => f.shape)) return false;
        if (p.level == 7 && !latin((f) => f.tint)) return false;
        if (p.level == 8 && !latin((f) => f.count)) return false;
        expected = candidate.copyWith(
          tint: p.level == 6
              ? cells[n - 1].tint
              : p.level == 8
                  ? lastRow.tint
                  : candidate.tint,
          count: p.level == 8 ? candidate.count : first.count,
          size: first.size,
          filled: first.filled,
          turns: 0,
        );
    }
    if (expected == null || expected.key != candidate.key) return false;
    // The non-Latin rules must hold in every visible row, not just the gap.
    if (p.level <= 5) {
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          final row = cells[r * n];
          final f = cells[r * n + c];
          final reference = switch (p.level) {
            1 => row,
            2 || 3 => row.copyWith(shape: cells[c].shape),
            4 => row.copyWith(count: c + 1),
            _ => row.copyWith(turns: row.turns + 2 * c),
          };
          if (f.key != reference.key) return false;
        }
      }
    }
    return true;
  }

  static bool _seriesFits(IqSeriesPuzzle p, IqFigure candidate) {
    final values = [...p.shown, candidate];
    final first = values.first;
    for (var i = 0; i < values.length; i++) {
      final expected = switch (p.level) {
        1 => first.copyWith(shape: p.shown[i % 2].shape),
        2 => first.copyWith(tint: p.shown[i % 3].tint),
        3 => first.copyWith(count: first.count + i),
        4 => first.copyWith(turns: first.turns + 2 * i),
        5 => first.copyWith(
            shape: p.shown[i % 3].shape, tint: p.shown[i % 2].tint),
        6 =>
          first.copyWith(turns: first.turns + i, count: p.shown[i % 2].count),
        7 => first.copyWith(count: first.count - i, tint: p.shown[i % 3].tint),
        8 => first.copyWith(
            turns: first.turns + 3 * i,
            tint: p.shown[i % 3].tint,
            filled: i.isEven ? first.filled : !first.filled),
        _ => null,
      };
      if (expected == null || expected.key != values[i].key) return false;
    }
    return true;
  }

  static bool _numberRule(int level, List<int> n) {
    final d = [for (var i = 1; i < n.length; i++) n[i] - n[i - 1]];
    bool all(bool Function(int) predicate) => d.every(predicate);
    switch (level) {
      case 1:
        return all((v) => v == 1);
      case 2:
        return [2, 5, 10].contains(d.first) && all((v) => v == d.first);
      case 3:
        return [-2, -3].contains(d.first) && all((v) => v == d.first);
      case 4:
        return [2, 3].any((factor) => [
              for (var i = 1; i < n.length; i++) n[i] == n[i - 1] * factor
            ].every((v) => v));
      case 5:
        return d[0] >= 3 &&
            d[0] <= 5 &&
            [-1, -2].contains(d[1]) &&
            [for (var i = 0; i < d.length; i++) d[i] == d[i % 2]]
                .every((v) => v);
      case 6:
        return [1, 2].contains(d.first) &&
            [for (var i = 0; i < d.length; i++) d[i] == (i + 1) * d.first]
                .every((v) => v);
      case 7:
        if (n.length < 7) return false;
        final step = n[2] - n[0];
        return step >= 1 &&
            step <= 3 &&
            [10, 20].contains(n[1]) &&
            [
              for (var i = 0; i < n.length; i++)
                n[i] ==
                    (i.isEven ? n[0] + (i ~/ 2) * step : n[1] * (i ~/ 2 + 1))
            ].every((v) => v);
      case 8:
        return [for (var i = 2; i < n.length; i++) n[i] == n[i - 1] + n[i - 2]]
                .every((v) => v) ||
            [for (var i = 0; i < n.length; i++) n[i] == (i + 1) * (i + 1)]
                .every((v) => v);
    }
    return false;
  }

  static bool _connected(IqPolyomino piece) {
    final cells = piece.cells.toSet();
    if (cells.isEmpty ||
        cells.length != piece.cells.length ||
        piece.width > 4 ||
        piece.height > 4) {
      return false;
    }
    final seen = <(int, int)>{cells.first}, pending = [cells.first];
    while (pending.isNotEmpty) {
      final (x, y) = pending.removeLast();
      for (final next in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (cells.contains(next) && seen.add(next)) pending.add(next);
      }
    }
    return seen.length == cells.length;
  }
}
