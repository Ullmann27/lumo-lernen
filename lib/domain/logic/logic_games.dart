/// Deterministic, offline logic adventures for primary school.
///
/// The catalog contains authored vocabulary and reproducible mathematical
/// constructions. No random reward, opponent, timer or intelligence score is
/// involved. Levels describe game content, never population norms.
library;

enum LogicGameKind { sudoku, words, maths }

extension LogicGameKindText on LogicGameKind {
  String get title => switch (this) {
    LogicGameKind.sudoku => 'Sudoku-Insel',
    LogicGameKind.words => 'Wörterwerkstatt',
    LogicGameKind.maths => 'Zahlenbrücken',
  };

  String get subtitle => switch (this) {
    LogicGameKind.sudoku => 'Finde für jede Zahl ihren Platz.',
    LogicGameKind.words => 'Löse Hinweise und verbinde Wörter.',
    LogicGameKind.maths => 'Verbinde Rechnungen zu einem Rätsel.',
  };

  String get skill => switch (this) {
    LogicGameKind.sudoku => 'Regeln prüfen und logisch ausschließen',
    LogicGameKind.words => 'Wortschatz und Rechtschreibung',
    LogicGameKind.maths => 'Rechnen und Umkehraufgaben',
  };
}

/// One row-major grid cell. `answer` also contains fixed operator labels.
/// Blocked cells are visual gaps; they are never buttons or answer targets.
class LogicCell {
  const LogicCell({
    required this.index,
    this.answer = '',
    this.given = false,
    this.blocked = false,
    this.isOperator = false,
    this.clueNumber,
  });

  final int index;
  final String answer;
  final bool given;
  final bool blocked;
  final bool isOperator;
  final String? clueNumber;

  bool get editable => !given && !blocked && !isOperator;
  int get maxLength => answer.length;
}

/// A crossword clue or a mathematical rule, with its ordered grid cells.
class LogicClue {
  LogicClue({
    required this.id,
    required this.label,
    required this.text,
    required Iterable<int> cells,
    this.answer = '',
  }) : cells = List<int>.unmodifiable(cells);

  final String id;
  final String label;
  final String text;
  final List<int> cells;

  /// Authored solution for validation, never an instruction shown in play.
  final String answer;
}

enum LogicMathOperation { add, subtract, multiply, divide }

extension LogicMathOperationText on LogicMathOperation {
  String get symbol => switch (this) {
    LogicMathOperation.add => '+',
    LogicMathOperation.subtract => '−',
    LogicMathOperation.multiply => '×',
    LogicMathOperation.divide => '÷',
  };

  String get instruction => switch (this) {
    LogicMathOperation.add => 'Die beiden Zahlen ergeben zusammen die Summe.',
    LogicMathOperation.subtract => 'Ziehe die zweite Zahl von der ersten ab.',
    LogicMathOperation.multiply => 'Rechne die erste Zahl mal die zweite.',
    LogicMathOperation.divide => 'Teile die erste Zahl durch die zweite.',
  };

  /// Division is exact; fractional and undefined results are not puzzle values.
  int? apply(int first, int second) => switch (this) {
    LogicMathOperation.add => first + second,
    LogicMathOperation.subtract => first - second,
    LogicMathOperation.multiply => first * second,
    LogicMathOperation.divide =>
      second != 0 && first % second == 0 ? first ~/ second : null,
  };
}

class LogicMathEquation {
  const LogicMathEquation({
    required this.first,
    required this.second,
    required this.result,
    required this.operation,
    required this.label,
  });

  final int first;
  final int second;
  final int result;
  final LogicMathOperation operation;
  final String label;

  List<int> get numberCells => [first, second, result];

  bool isSatisfied(Map<int, int> values) {
    final a = values[first];
    final b = values[second];
    final c = values[result];
    return a != null && b != null && c != null && operation.apply(a, b) == c;
  }

  /// Finds a missing value from two known values using an exact inverse.
  /// Returns null for insufficient information or a non-unique inverse.
  (int, int)? infer(Map<int, int> values) {
    final missing = numberCells.where((i) => !values.containsKey(i)).toList();
    if (missing.length != 1) return null;
    final index = missing.single;
    final a = values[first];
    final b = values[second];
    final c = values[result];
    int? value;
    if (index == result) {
      value = operation.apply(a!, b!);
    } else if (index == first) {
      value = switch (operation) {
        LogicMathOperation.add => c! - b!,
        LogicMathOperation.subtract => c! + b!,
        LogicMathOperation.multiply => _exactDivide(c!, b!),
        LogicMathOperation.divide => b != 0 ? c! * b! : null,
      };
    } else {
      value = switch (operation) {
        LogicMathOperation.add => c! - a!,
        LogicMathOperation.subtract => a! - c!,
        LogicMathOperation.multiply => _exactDivide(c!, a!),
        LogicMathOperation.divide => _exactDivide(a!, c!),
      };
    }
    if (value == null || value < 0) return null;
    final check = {...values, index: value};
    return isSatisfied(check) ? (index, value) : null;
  }

  static int? _exactDivide(int numerator, int denominator) =>
      denominator != 0 && numerator % denominator == 0
      ? numerator ~/ denominator
      : null;
}

/// Shared API for the three visual boards.
///
/// `answers` maps editable cell indices to user input. Givens are immutable and
/// ignored if present in that map. Completion validates every editable cell.
class LogicPuzzle {
  LogicPuzzle({
    required this.id,
    required this.kind,
    required this.grade,
    required this.level,
    required this.title,
    required this.instruction,
    required this.rows,
    required this.columns,
    required Iterable<LogicCell> cells,
    Iterable<LogicClue> clues = const [],
    Iterable<String> inputChoices = const [],
    Iterable<LogicMathEquation> equations = const [],
    this.blockRows,
    this.blockColumns,
  }) : cells = List<LogicCell>.unmodifiable(cells),
       clues = List<LogicClue>.unmodifiable(clues),
       inputChoices = List<String>.unmodifiable(inputChoices),
       equations = List<LogicMathEquation>.unmodifiable(equations) {
    if (rows <= 0 || columns <= 0 || this.cells.length != rows * columns) {
      throw ArgumentError('The grid dimensions and cells must agree.');
    }
    for (var i = 0; i < this.cells.length; i++) {
      if (this.cells[i].index != i) {
        throw ArgumentError('Cells must use contiguous row-major indices.');
      }
    }
  }

  final String id;
  final LogicGameKind kind;
  final int grade;
  final int level;
  final String title;
  final String instruction;
  final int rows;
  final int columns;
  final List<LogicCell> cells;
  final List<LogicClue> clues;
  final List<String> inputChoices;
  final List<LogicMathEquation> equations;
  final int? blockRows;
  final int? blockColumns;

  Iterable<LogicCell> get editableCells => cells.where((cell) => cell.editable);

  static String normalize(String value) =>
      value.trim().replaceAll('ß', 'SS').toUpperCase();

  bool isCorrectCell(int index, String value) {
    if (index < 0 || index >= cells.length || cells[index].blocked)
      return false;
    final expected = cells[index].answer;
    final entered = normalize(value);
    if (kind == LogicGameKind.maths && !cells[index].isOperator) {
      return RegExp(r'^\d+$').hasMatch(entered) &&
          int.tryParse(entered) == int.tryParse(expected);
    }
    return expected == entered;
  }

  bool isComplete(Map<int, String> answers) => editableCells.every(
    (cell) => isCorrectCell(cell.index, answers[cell.index] ?? ''),
  );

  String visibleValue(int index, Map<int, String> answers) {
    final cell = cells[index];
    return cell.given || cell.isOperator
        ? cell.answer
        : normalize(answers[index] ?? '');
  }

  List<LogicClue> checksFor(int index) =>
      clues.where((clue) => clue.cells.contains(index)).toList(growable: false);

  /// A rule explanation, not an automatic answer or a penalty.
  String hintFor(int index, {Map<int, String> answers = const {}}) {
    if (index < 0 || index >= cells.length || !cells[index].editable) {
      return 'Wähle zuerst ein freies Feld aus.';
    }
    if (kind == LogicGameKind.sudoku) {
      final candidates = sudokuCandidates(index, answers);
      if (candidates.isEmpty) {
        return 'Prüfe die eingetragenen Zahlen in dieser Zeile, Spalte und '
            'diesem kleinen Block. Eine Zahl darf dort nur einmal stehen.';
      }
      final rest = candidates.join(', ');
      return 'Vergleiche Zeile ${index ~/ columns + 1}, Spalte '
          '${index % columns + 1} und den kleinen Block. '
          '${candidates.length == 1 ? 'Nur diese Zahl fehlt überall' : 'Diese Zahlen sind dort noch möglich'}: '
          '$rest.';
    }
    if (kind == LogicGameKind.words) {
      final matching = checksFor(index);
      if (matching.isEmpty) return instruction;
      final clue = matching.first;
      return '${clue.label}: ${clue.text} Das Wort hat '
          '${clue.cells.length} Buchstaben. Beachte auch die Kreuzung.';
    }
    final matching = equations.where((eq) => eq.numberCells.contains(index));
    if (matching.isEmpty) return instruction;
    final equation = matching.first;
    String shown(int cell) {
      final value = visibleValue(cell, answers);
      return value.isEmpty ? '□' : value;
    }

    return '${equation.label}: ${shown(equation.first)} '
        '${equation.operation.symbol} ${shown(equation.second)} = '
        '${shown(equation.result)}. ${equation.operation.instruction} '
        'Fehlt eine Zahl vorne, hilft die Umkehraufgabe.';
  }

  /// Candidate computation uses visible entries, with the selected cell empty.
  List<int> sudokuCandidates(int index, Map<int, String> answers) {
    if (kind != LogicGameKind.sudoku || index < 0 || index >= cells.length) {
      return const [];
    }
    final values = List<int>.generate(cells.length, (i) {
      if (i == index) return 0;
      return int.tryParse(visibleValue(i, answers)) ?? 0;
    });
    return LogicSudokuSolver.candidates(
      values,
      columns,
      blockRows!,
      blockColumns!,
      index,
    );
  }

  /// Prefer a logically forced Sudoku cell; otherwise the first unanswered cell.
  int? suggestedHintIndex(Map<int, String> answers) {
    final remaining = editableCells.where(
      (cell) => !isCorrectCell(cell.index, answers[cell.index] ?? ''),
    );
    if (remaining.isEmpty) return null;
    if (kind == LogicGameKind.sudoku) {
      for (final cell in remaining) {
        if (sudokuCandidates(cell.index, answers).length == 1)
          return cell.index;
      }
    }
    return remaining.first.index;
  }
}

/// Small exact solver, also used to verify each removed Sudoku clue.
class LogicSudokuSolver {
  static List<int> candidates(
    List<int> grid,
    int size,
    int blockRows,
    int blockColumns,
    int index,
  ) {
    final row = index ~/ size;
    final column = index % size;
    final used = <int>{};
    for (var i = 0; i < size; i++) {
      if (row * size + i != index) used.add(grid[row * size + i]);
      if (i * size + column != index) used.add(grid[i * size + column]);
    }
    final firstRow = row ~/ blockRows * blockRows;
    final firstColumn = column ~/ blockColumns * blockColumns;
    for (var r = firstRow; r < firstRow + blockRows; r++) {
      for (var c = firstColumn; c < firstColumn + blockColumns; c++) {
        if (r * size + c != index) used.add(grid[r * size + c]);
      }
    }
    return [
      for (var n = 1; n <= size; n++)
        if (!used.contains(n)) n,
    ];
  }

  static bool validGrid(
    List<int> grid,
    int size,
    int blockRows,
    int blockColumns,
  ) {
    if (size <= 0 ||
        blockRows <= 0 ||
        blockColumns <= 0 ||
        blockRows * blockColumns != size ||
        size % blockRows != 0 ||
        size % blockColumns != 0 ||
        grid.length != size * size)
      return false;
    for (var i = 0; i < grid.length; i++) {
      final value = grid[i];
      if (value < 0 || value > size) return false;
      if (value != 0 &&
          !candidates(grid, size, blockRows, blockColumns, i).contains(value)) {
        return false;
      }
    }
    return true;
  }

  static int countSolutions(
    List<int> source,
    int size,
    int blockRows,
    int blockColumns, {
    int limit = 2,
  }) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit');
    if (!validGrid(source, size, blockRows, blockColumns)) return 0;
    final grid = List<int>.of(source);
    var found = 0;
    void search() {
      if (found >= limit) return;
      var chosen = -1;
      var options = <int>[];
      for (var i = 0; i < grid.length; i++) {
        if (grid[i] != 0) continue;
        final next = candidates(grid, size, blockRows, blockColumns, i);
        if (next.isEmpty) return;
        if (chosen == -1 || next.length < options.length) {
          chosen = i;
          options = next;
          if (next.length == 1) break;
        }
      }
      if (chosen == -1) {
        found++;
        return;
      }
      for (final value in options) {
        grid[chosen] = value;
        search();
        grid[chosen] = 0;
        if (found >= limit) return;
      }
    }

    search();
    return found;
  }

  /// Pedagogical guard: all released Sudoku levels have a sequence of singles.
  static bool solvableBySingles(
    List<int> source,
    int size,
    int blockRows,
    int blockColumns,
  ) {
    if (!validGrid(source, size, blockRows, blockColumns)) return false;
    final grid = List<int>.of(source);
    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < grid.length; i++) {
        if (grid[i] != 0) continue;
        final next = candidates(grid, size, blockRows, blockColumns, i);
        if (next.isEmpty) return false;
        if (next.length == 1) {
          grid[i] = next.single;
          changed = true;
        }
      }
    }
    return !grid.contains(0);
  }
}

class LogicCatalog {
  static const contentVersion = 'logic-2026-11-v1';
  static const levelsPerGrade = 12;
  static final Map<String, List<LogicPuzzle>> _cache = {};

  /// Returns immutable authored levels. Invalid grades fail explicitly.
  static List<LogicPuzzle> levels(LogicGameKind kind, int grade) {
    if (grade < 1 || grade > 4) throw ArgumentError.value(grade, 'grade');
    return _cache.putIfAbsent(
      '${kind.name}/$grade',
      () => List<LogicPuzzle>.unmodifiable([
        for (var level = 1; level <= levelsPerGrade; level++)
          switch (kind) {
            LogicGameKind.sudoku => _sudoku(grade, level),
            LogicGameKind.words => _crossword(grade, level),
            LogicGameKind.maths => _maths(grade, level),
          },
      ]),
    );
  }

  static LogicPuzzle puzzle(LogicGameKind kind, int grade, int level) {
    if (level < 1 || level > levelsPerGrade) {
      throw ArgumentError.value(level, 'level');
    }
    return levels(kind, grade)[level - 1];
  }

  static String _id(LogicGameKind kind, int grade, int level) =>
      '${kind.name}-g$grade-l$level-v1';

  static LogicPuzzle _sudoku(int grade, int level) {
    final size = grade == 1 || (grade == 2 && level <= 6) ? 4 : 6;
    const blockRows = 2;
    final blockColumns = size ~/ blockRows;
    // These row/column permutations preserve the rectangular sub-blocks.
    final rowOrder = <int>[
      for (var band = 0; band < size ~/ blockRows; band++)
        for (var offset = 0; offset < blockRows; offset++)
          ((band + level ~/ 3) % (size ~/ blockRows)) * blockRows +
              (offset + level + grade) % blockRows,
    ];
    final columnOrder = <int>[
      for (var stack = 0; stack < size ~/ blockColumns; stack++)
        for (var offset = 0; offset < blockColumns; offset++)
          ((stack + level ~/ 2) % (size ~/ blockColumns)) * blockColumns +
              (offset + grade + level ~/ 4) % blockColumns,
    ];
    final solution = <int>[
      for (final row in rowOrder)
        for (final column in columnOrder)
          (row * blockColumns + row ~/ blockRows + column + level + grade) %
                  size +
              1,
    ];
    final board = List<int>.of(solution);
    final targetHoles = size == 4
        ? (grade == 1 ? 4 + (level - 1) ~/ 2 : 7 + (level - 1) ~/ 2)
        : (grade == 2
              ? 10 + (level - 7)
              : (grade == 3 ? 12 : 16) + (level - 1) ~/ 2);
    var removed = 0;
    // A coprime step visits every cell once and makes the catalog reproducible.
    final order = List<int>.generate(
      board.length,
      (i) => (i * (size + 1) + level * 3 + grade) % board.length,
    );
    for (final index in order) {
      if (removed == targetHoles) break;
      final saved = board[index];
      board[index] = 0;
      if (LogicSudokuSolver.solvableBySingles(
            board,
            size,
            blockRows,
            blockColumns,
          ) &&
          LogicSudokuSolver.countSolutions(
                board,
                size,
                blockRows,
                blockColumns,
              ) ==
              1) {
        removed++;
      } else {
        board[index] = saved;
      }
    }
    return LogicPuzzle(
      id: _id(LogicGameKind.sudoku, grade, level),
      kind: LogicGameKind.sudoku,
      grade: grade,
      level: level,
      title: '${size}×$size · Insel $level',
      instruction:
          'Jede Zahl von 1 bis $size steht genau einmal in jeder '
          'Zeile, Spalte und jedem kleinen ${blockRows}×$blockColumns-Block.',
      rows: size,
      columns: size,
      cells: [
        for (var i = 0; i < board.length; i++)
          LogicCell(index: i, answer: '${solution[i]}', given: board[i] != 0),
      ],
      inputChoices: [for (var i = 1; i <= size; i++) '$i'],
      blockRows: blockRows,
      blockColumns: blockColumns,
    );
  }

  static LogicPuzzle _crossword(int grade, int level) {
    final bank = _wordBanks[grade - 1];
    final target = 3 + (grade - 1) ~/ 2 + (level - 1) ~/ 4;
    final first = bank[((level - 1) * 5) % bank.length];
    final placements = <_WordPlacement>[
      _WordPlacement(first, 0, 0, level.isOdd),
    ];
    final letters = <(int, int), String>{};
    final directions = <(int, int), Set<bool>>{};
    void place(_WordPlacement placement) {
      for (var i = 0; i < placement.word.answer.length; i++) {
        final p = placement.at(i);
        letters[p] = placement.word.answer[i];
        directions.putIfAbsent(p, () => <bool>{}).add(placement.across);
      }
    }

    place(placements.first);
    final used = {first.answer};
    while (placements.length < target) {
      _WordPlacement? best;
      var bestScore = -1000000;
      for (var offset = 0; offset < bank.length; offset++) {
        final word = bank[(offset + level * 5) % bank.length];
        if (used.contains(word.answer)) continue;
        for (var i = 0; i < word.answer.length; i++) {
          for (final entry in letters.entries) {
            if (entry.value != word.answer[i]) continue;
            for (final across in [true, false]) {
              final candidate = _WordPlacement(
                word,
                entry.key.$1 - (across ? 0 : i),
                entry.key.$2 - (across ? i : 0),
                across,
              );
              final score = _placementScore(candidate, letters, directions);
              if (score != null && score > bestScore) {
                best = candidate;
                bestScore = score;
              }
            }
          }
        }
      }
      if (best == null) break;
      placements.add(best);
      used.add(best.word.answer);
      place(best);
    }
    if (placements.length < 3) {
      throw StateError('Crossword vocabulary does not form a connected grid.');
    }
    final minRow = letters.keys.map((p) => p.$1).reduce(_min);
    final minColumn = letters.keys.map((p) => p.$2).reduce(_min);
    final maxRow = letters.keys.map((p) => p.$1).reduce(_max);
    final maxColumn = letters.keys.map((p) => p.$2).reduce(_max);
    final rows = maxRow - minRow + 1;
    final columns = maxColumn - minColumn + 1;
    int cellIndex((int, int) p) => (p.$1 - minRow) * columns + p.$2 - minColumn;
    placements.sort(
      (a, b) => a.row != b.row
          ? a.row.compareTo(b.row)
          : a.column.compareTo(b.column),
    );
    final numbers = <int, String>{};
    for (final word in placements) {
      final index = cellIndex(word.at(0));
      numbers.putIfAbsent(index, () => '${numbers.length + 1}');
    }
    final givens = <int>{};
    // The first school year starts with initial letters; later levels fade them.
    if (grade == 1 && level <= 4) {
      for (final word in placements) {
        givens.add(cellIndex(word.at(0)));
      }
    } else if (level <= 3) {
      givens.add(cellIndex(placements.first.at(0)));
    }
    final byIndex = {
      for (final entry in letters.entries) cellIndex(entry.key): entry.value,
    };
    return LogicPuzzle(
      id: _id(LogicGameKind.words, grade, level),
      kind: LogicGameKind.words,
      grade: grade,
      level: level,
      title: 'Wörterpfad $level',
      instruction:
          'Löse die Hinweise und schreibe die Wörter ins Gitter. '
          'Kreuzungen teilen einen Buchstaben. Ä, Ö und Ü haben ein Feld; '
          'für ß schreibst du SS.',
      rows: rows,
      columns: columns,
      cells: [
        for (var i = 0; i < rows * columns; i++)
          LogicCell(
            index: i,
            answer: byIndex[i] ?? '',
            blocked: !byIndex.containsKey(i),
            given: givens.contains(i),
            clueNumber: numbers[i],
          ),
      ],
      clues: [
        for (final word in placements)
          LogicClue(
            id: '${numbers[cellIndex(word.at(0))]}${word.across ? 'a' : 'd'}',
            label:
                '${numbers[cellIndex(word.at(0))]} ${word.across ? '→' : '↓'}',
            text: word.word.clue,
            cells: [
              for (var i = 0; i < word.word.answer.length; i++)
                cellIndex(word.at(i)),
            ],
            answer: word.word.answer,
          ),
      ],
      inputChoices: 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ'.split(''),
    );
  }

  static int? _placementScore(
    _WordPlacement candidate,
    Map<(int, int), String> letters,
    Map<(int, int), Set<bool>> directions,
  ) {
    if (letters.containsKey(candidate.at(-1)) ||
        letters.containsKey(candidate.at(candidate.word.answer.length)))
      return null;
    var crossings = 0;
    for (var i = 0; i < candidate.word.answer.length; i++) {
      final p = candidate.at(i);
      final existing = letters[p];
      if (existing != null) {
        if (existing != candidate.word.answer[i] ||
            directions[p]!.contains(candidate.across))
          return null;
        crossings++;
      } else {
        final before = candidate.across ? (p.$1 - 1, p.$2) : (p.$1, p.$2 - 1);
        final after = candidate.across ? (p.$1 + 1, p.$2) : (p.$1, p.$2 + 1);
        if (letters.containsKey(before) || letters.containsKey(after))
          return null;
      }
    }
    if (crossings == 0) return null;
    final allPoints = [
      ...letters.keys,
      candidate.at(0),
      candidate.at(candidate.word.answer.length - 1),
    ];
    final rows =
        allPoints.map((p) => p.$1).reduce(_max) -
        allPoints.map((p) => p.$1).reduce(_min) +
        1;
    final columns =
        allPoints.map((p) => p.$2).reduce(_max) -
        allPoints.map((p) => p.$2).reduce(_min) +
        1;
    if (rows > 10 || columns > 10) return null;
    return crossings * 1000 - rows * columns * 4 - rows - columns;
  }

  static LogicPuzzle _maths(int grade, int level) {
    final answers = <int, int>{};
    final operators = <int, String>{};
    final equations = <LogicMathEquation>[];
    void addEquation(
      int first,
      int second,
      int result,
      LogicMathOperation operation,
      String label,
      int operatorIndex,
      int equalsIndex,
    ) {
      equations.add(
        LogicMathEquation(
          first: first,
          second: second,
          result: result,
          operation: operation,
          label: label,
        ),
      );
      operators[operatorIndex] = operation.symbol;
      operators[equalsIndex] = '=';
    }

    if (grade >= 3 && level.isEven) {
      // Three linked equations introduce times tables and exact division.
      final factor = 2 + level % 7;
      final other = 2 + (level ~/ 2) % 6;
      if (level % 4 == 0) {
        answers.addAll({0: factor * other, 2: factor, 4: other});
        addEquation(0, 2, 4, LogicMathOperation.divide, 'Oben', 1, 3);
      } else {
        answers.addAll({0: factor, 2: other, 4: factor * other});
        addEquation(0, 2, 4, LogicMathOperation.multiply, 'Oben', 1, 3);
      }
      final bridge = grade == 3 ? 11 + level : 100 + level * 7;
      answers[14] = bridge;
      answers[24] = answers[4]! + bridge;
      final step = 3 + level;
      answers[20] = answers[24]! + step;
      answers[22] = step;
      addEquation(
        4,
        14,
        24,
        LogicMathOperation.add,
        'Rechts nach unten',
        9,
        19,
      );
      addEquation(20, 22, 24, LogicMathOperation.subtract, 'Unten', 21, 23);
    } else {
      final unit = switch (grade) {
        1 => 1,
        2 => 7,
        3 => 31,
        _ => 173,
      };
      final b = unit + level % 3;
      final e = unit + (level ~/ 3) % 3;
      final x = unit + (level ~/ 2) % 3;
      final y = unit + (level ~/ 4) % 3;
      final subtraction = level >= 5;
      final a = subtraction ? b + x : x;
      final d = subtraction ? e + y : y;
      final rowOperation = subtraction
          ? LogicMathOperation.subtract
          : LogicMathOperation.add;
      final c = rowOperation.apply(a, b)!;
      final f = rowOperation.apply(d, e)!;
      answers.addAll({
        0: a,
        2: b,
        4: c,
        10: d,
        12: e,
        14: f,
        20: a + d,
        22: b + e,
        24: c + f,
      });
      addEquation(0, 2, 4, rowOperation, 'Oben', 1, 3);
      addEquation(10, 12, 14, rowOperation, 'Mitte', 11, 13);
      addEquation(20, 22, 24, rowOperation, 'Unten', 21, 23);
      addEquation(0, 10, 20, LogicMathOperation.add, 'Links nach unten', 5, 15);
      addEquation(2, 12, 22, LogicMathOperation.add, 'Mitte nach unten', 7, 17);
      addEquation(
        4,
        14,
        24,
        LogicMathOperation.add,
        'Rechts nach unten',
        9,
        19,
      );
    }
    final givens = Map<int, int>.of(answers);
    final ordered = answers.keys.toList()..sort();
    final targetHoles = equations.length == 3
        ? 2 + (level >= 8 ? 1 : 0)
        : 3 + (level - 1) ~/ 5;
    var removed = 0;
    for (var offset = 0; offset < ordered.length; offset++) {
      if (removed == targetHoles) break;
      final index = ordered[(offset + level + grade) % ordered.length];
      final value = givens.remove(index)!;
      final derived = inferMathValues(givens, equations);
      if (answers.keys.every((key) => derived[key] == answers[key])) {
        removed++;
      } else {
        givens[index] = value;
      }
    }
    return LogicPuzzle(
      id: _id(LogicGameKind.maths, grade, level),
      kind: LogicGameKind.maths,
      grade: grade,
      level: level,
      title: 'Zahlenbrücke $level',
      instruction:
          'Jede Rechnung muss stimmen – von links nach rechts und '
          'von oben nach unten. Geteilte Felder gehören zu beiden Rechnungen.',
      rows: 5,
      columns: 5,
      cells: [
        for (var i = 0; i < 25; i++)
          LogicCell(
            index: i,
            answer: answers.containsKey(i)
                ? '${answers[i]}'
                : operators[i] ?? '',
            given: givens.containsKey(i) || operators.containsKey(i),
            blocked: !answers.containsKey(i) && !operators.containsKey(i),
            isOperator: operators.containsKey(i),
          ),
      ],
      clues: [
        for (var i = 0; i < equations.length; i++)
          LogicClue(
            id: 'equation-$i',
            label: equations[i].label,
            text: equations[i].operation.instruction,
            cells: equations[i].numberCells,
          ),
      ],
      equations: equations,
      inputChoices: [for (var i = 0; i <= 9; i++) '$i'],
    );
  }

  /// Propagates only exact single-unknown equations. A complete result proves
  /// that all missing number cells are determined without guessing.
  static Map<int, int> inferMathValues(
    Map<int, int> givens,
    Iterable<LogicMathEquation> equations,
  ) {
    final values = Map<int, int>.of(givens);
    var changed = true;
    while (changed) {
      changed = false;
      for (final equation in equations) {
        final inferred = equation.infer(values);
        if (inferred == null) continue;
        values[inferred.$1] = inferred.$2;
        changed = true;
      }
    }
    return values;
  }

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;
}

class _Word {
  const _Word(this.answer, this.clue);
  final String answer;
  final String clue;
}

class _WordPlacement {
  const _WordPlacement(this.word, this.row, this.column, this.across);
  final _Word word;
  final int row;
  final int column;
  final bool across;
  (int, int) at(int offset) =>
      (row + (across ? 0 : offset), column + (across ? offset : 0));
}

// Original short clues, authored for this game; no copied test materials.
const _wordBanks = <List<_Word>>[
  [
    _Word('HAUS', 'Ein Gebäude, in dem Menschen wohnen.'),
    _Word('MAUS', 'Ein kleines Tier mit langem Schwanz. Es piepst.'),
    _Word('HUND', 'Dieses Haustier bellt.'),
    _Word('KATZE', 'Dieses Haustier miaut.'),
    _Word('HASE', 'Dieses Tier hat lange Ohren und hoppelt.'),
    _Word('ROSE', 'Eine Blume mit Dornen am Stängel.'),
    _Word('NASE', 'Damit riechst du. Sie ist mitten im Gesicht.'),
    _Word('HAND', 'An ihr sind fünf Finger.'),
    _Word('MUND', 'Damit sprichst und isst du.'),
    _Word('AUGE', 'Damit siehst du. Du hast zwei davon.'),
    _Word('OHR', 'Damit hörst du. Du hast zwei davon.'),
    _Word('BAUM', 'Eine große Pflanze mit Stamm und Ästen.'),
    _Word('AST', 'Dieser Teil wächst seitlich aus einem Baumstamm.'),
    _Word('BLATT', 'Der flache, meist grüne Teil einer Pflanze.'),
    _Word('GRAS', 'Viele dünne grüne Halme wachsen auf der Wiese.'),
    _Word('BROT', 'Davon schneidest du eine Scheibe und belegst sie.'),
    _Word('MILCH', 'Ein weißes Getränk, das zum Beispiel von Kühen kommt.'),
    _Word(
      'APFEL',
      'Eine runde Frucht mit Kerngehäuse. Sie wächst am Apfelbaum.',
    ),
    _Word('BIRNE', 'Eine Frucht, die unten meist dicker als oben ist.'),
    _Word('EIS', 'Gefrorenes Wasser nennt man so.'),
    _Word('SONNE', 'Dieser Stern leuchtet am Tag an unserem Himmel.'),
    _Word('MOND', 'Er umkreist die Erde und ist oft nachts zu sehen.'),
    _Word(
      'STERN',
      'Die Sonne ist einer. Viele siehst du als Lichtpunkte am Nachthimmel.',
    ),
    _Word('REGEN', 'Wassertropfen fallen aus Wolken.'),
    _Word('WIND', 'Bewegte Luft, die Blätter wehen lässt.'),
    _Word('BOOT', 'Ein kleines Fahrzeug auf dem Wasser.'),
    _Word('BUS', 'In diesem großen Fahrzeug fahren viele Menschen mit.'),
    _Word('AUTO', 'Ein Fahrzeug mit meist vier Rädern für die Straße.'),
    _Word('RAD', 'Dieser runde Teil dreht sich unter einem Fahrrad.'),
    _Word('BALL', 'Ein rundes Spielzeug zum Werfen oder Kicken.'),
    _Word('BUCH', 'Es hat Seiten, die du lesen kannst.'),
    _Word('HEFT', 'Darin schreibst du deine Schulaufgaben.'),
    _Word('STIFT', 'Damit kannst du schreiben oder zeichnen.'),
    _Word('TISCH', 'Ein Möbel, an dem du zum Beispiel isst oder schreibst.'),
    _Word('TÜR', 'Sie wird geöffnet, damit du in ein Zimmer kommst.'),
    _Word('BETT', 'In diesem Möbel schläfst du.'),
    _Word('ENTE', 'Ein Wasservogel, der quakt und einen breiten Schnabel hat.'),
    _Word('ESEL', 'Ein Tier mit langen Ohren, das I-A ruft.'),
    _Word('IGEL', 'Ein kleines Tier mit Stacheln auf dem Rücken.'),
    _Word('FISCH', 'Dieses Tier lebt im Wasser und hat Flossen.'),
    _Word('FUCHS', 'Ein Wildtier mit buschigem Schwanz, oft mit rotem Fell.'),
    _Word('BEIN', 'Darauf stehst du. Du hast zwei davon.'),
  ],
  [
    _Word('SCHULE', 'Hier lernst du in deiner Klasse mit anderen Kindern.'),
    _Word(
      'KLASSE',
      'Eine Gruppe von Kindern, die gemeinsam unterrichtet wird.',
    ),
    _Word(
      'TAFEL',
      'Darauf kann die Lehrperson vorne im Klassenraum schreiben.',
    ),
    _Word(
      'PAUSE',
      'Eine Unterbrechung des Unterrichts zum Ausruhen oder Spielen.',
    ),
    _Word('LINEAL', 'Damit zeichnest du gerade Linien und misst Längen.'),
    _Word('PINSEL', 'Damit malst du mit flüssiger Farbe.'),
    _Word('PAPIER', 'Darauf kannst du zeichnen, schreiben oder etwas falten.'),
    _Word('FARBE', 'Rot, Grün und Blau sind jeweils eine ...'),
    _Word('GARTEN', 'Ein Stück Land am Haus mit Blumen oder Gemüse.'),
    _Word('BLUME', 'Eine Pflanze mit oft bunten Blüten.'),
    _Word('WURZEL', 'Dieser Pflanzenteil nimmt Wasser aus dem Boden auf.'),
    _Word('WIESE', 'Eine Fläche, auf der Gräser und oft Blumen wachsen.'),
    _Word('WASSER', 'Du trinkst es. Es fließt auch in einem Bach.'),
    _Word(
      'WOLKE',
      'Sie besteht aus kleinen Wassertröpfchen oder Eiskristallen am Himmel.',
    ),
    _Word('SCHNEE', 'Weiße Flocken, die im Winter vom Himmel fallen können.'),
    _Word('WINTER', 'Die Jahreszeit nach dem Herbst.'),
    _Word('SOMMER', 'Die Jahreszeit zwischen Frühling und Herbst.'),
    _Word('HERBST', 'Die Jahreszeit zwischen Sommer und Winter.'),
    _Word('VOGEL', 'Ein Tier mit Federn, zwei Beinen und einem Schnabel.'),
    _Word('BIENE', 'Dieses Insekt sammelt Nektar und kann Honig erzeugen.'),
    _Word(
      'AMEISE',
      'Ein kleines Insekt, das mit vielen anderen in einem Staat lebt.',
    ),
    _Word('SPINNE', 'Ein Tier mit acht Beinen, das oft ein Netz baut.'),
    _Word(
      'FROSCH',
      'Ein Tier, das als Kaulquappe beginnt und später hüpfen kann.',
    ),
    _Word('PFERD', 'Ein großes Tier mit Mähne, auf dem Menschen reiten.'),
    _Word(
      'AMPEL',
      'Sie regelt den Verkehr mit roten, gelben und grünen Lichtern.',
    ),
    _Word(
      'BRÜCKE',
      'Sie führt einen Weg über Wasser oder ein anderes Hindernis.',
    ),
    _Word('STRASSE', 'Auf diesem Verkehrsweg fahren Autos. Schreibe ß als SS.'),
    _Word('BAHNHOF', 'Hier halten Züge und Menschen steigen ein und aus.'),
    _Word('KOFFER', 'Darin transportierst du Kleidung auf einer Reise.'),
    _Word('KÜCHE', 'In diesem Raum wird Essen zubereitet.'),
    _Word('TELLER', 'Darauf liegt dein Essen beim Mittagessen.'),
    _Word('GABEL', 'Ein Besteck mit mehreren Zinken.'),
    _Word('LÖFFEL', 'Mit diesem Besteck isst du Suppe.'),
    _Word('TASSE', 'Ein kleines Trinkgefäß mit einem Henkel.'),
    _Word('ZUCKER', 'Weiße, süße Kristalle, die man zum Backen verwendet.'),
    _Word('SALZ', 'Weiße Kristalle, die Speisen salzig machen.'),
    _Word('ZITRONE', 'Eine gelbe Zitrusfrucht, die sehr sauer schmeckt.'),
    _Word('KAROTTE', 'Ein meist oranges Wurzelgemüse.'),
    _Word(
      'TOMATE',
      'Eine oft rote, runde Frucht, die in vielen Salaten steckt.',
    ),
    _Word('FREUND', 'Ein Junge oder Mann, den du magst und dem du vertraust.'),
    _Word('FREUDE', 'Das Gefühl, wenn du dich über etwas freust.'),
    _Word(
      'MUT',
      'Du traust dich an etwas Sinnvolles, obwohl du dich fürchtest.',
    ),
  ],
  [
    _Word('FRÜHLING', 'Die Jahreszeit nach dem Winter.'),
    _Word('KALENDER', 'Er zeigt Tage, Wochen und Monate.'),
    _Word('MINUTE', 'Diese Zeiteinheit hat 60 Sekunden.'),
    _Word('STUNDE', 'Diese Zeiteinheit hat 60 Minuten.'),
    _Word('MORGEN', 'Die Tageszeit nach der Nacht und vor dem Mittag.'),
    _Word('ABEND', 'Die Tageszeit nach dem Nachmittag und vor der Nacht.'),
    _Word('INSEL', 'Ein Stück Land, das ganz von Wasser umgeben ist.'),
    _Word('GEBIRGE', 'Eine Landschaft mit vielen zusammenhängenden Bergen.'),
    _Word(
      'QUELLE',
      'Hier tritt Wasser aus dem Boden und ein Bach kann beginnen.',
    ),
    _Word(
      'MÜNDUNG',
      'Hier fließt ein Fluss in einen anderen Fluss, See oder ins Meer.',
    ),
    _Word('NORDEN', 'Die Himmelsrichtung gegenüber von Süden.'),
    _Word('SÜDEN', 'Die Himmelsrichtung gegenüber von Norden.'),
    _Word('OSTEN', 'In dieser Himmelsrichtung geht die Sonne ungefähr auf.'),
    _Word('WESTEN', 'In dieser Himmelsrichtung geht die Sonne ungefähr unter.'),
    _Word('KOMPASS', 'Ein Gerät, dessen Magnetnadel die Nordrichtung anzeigt.'),
    _Word('PLANET', 'Die Erde ist einer; er umkreist einen Stern.'),
    _Word('ERDE', 'Der Planet, auf dem wir leben.'),
    _Word('LUFT', 'Ein Gemisch von Gasen, das uns umgibt und das wir atmen.'),
    _Word('DAMPF', 'Wasser im gasförmigen Zustand nennt man Wasser...'),
    _Word(
      'KEIMEN',
      'So nennt man es, wenn aus einem Samen eine kleine Pflanze wächst.',
    ),
    _Word('KNOSPE', 'Daraus entwickelt sich eine Blüte oder ein Blatt.'),
    _Word('RINDE', 'Die äußere Schutzschicht eines Baumstamms.'),
    _Word('NADEL', 'Das schmale Blatt einer Tanne nennt man so.'),
    _Word('SPROSS', 'Ein junger Trieb einer Pflanze.'),
    _Word('SILBE', 'Ein Sprechteil eines Wortes, den du beim Klatschen hörst.'),
    _Word('SATZ', 'Eine sprachliche Einheit, die meist mit einem Punkt endet.'),
    _Word(
      'NOMEN',
      'Diese Wortart benennt Dinge, Tiere oder Menschen und wird großgeschrieben.',
    ),
    _Word('VERB', 'Diese Wortart beschreibt zum Beispiel, was jemand tut.'),
    _Word('MEHRZAHL', 'Häuser ist die ... von Haus.'),
    _Word('EINZAHL', 'Haus ist die ... von Häuser.'),
    _Word('VIERECK', 'Eine ebene Figur mit vier Seiten und vier Ecken.'),
    _Word('DREIECK', 'Eine ebene Figur mit drei Seiten und drei Ecken.'),
    _Word(
      'KREIS',
      'Eine runde Linie, deren Punkte gleich weit vom Mittelpunkt entfernt sind.',
    ),
    _Word('METER', 'Diese Längeneinheit hat 100 Zentimeter.'),
    _Word('LITER', 'Diese Maßeinheit hat 1000 Milliliter.'),
    _Word('TEILEN', 'Eine Menge gerecht in gleich große Gruppen aufteilen.'),
    _Word('SUMME', 'So heißt das Ergebnis einer Addition.'),
    _Word('HÄLFTE', 'Einer von zwei gleich großen Teilen eines Ganzen.'),
    _Word('VIERTEL', 'Einer von vier gleich großen Teilen eines Ganzen.'),
    _Word(
      'GEDULD',
      'Ruhig warten und einer Sache Zeit geben: Dafür brauchst du ...',
    ),
    _Word('RESPEKT', 'Andere Menschen achten und fair behandeln zeigt ...'),
    _Word('TEAM', 'Eine Gruppe, die gemeinsam auf ein Ziel hinarbeitet.'),
  ],
  [
    _Word('ARTIKEL', 'Der, die und das heißen in der Grammatik so.'),
    _Word(
      'ADJEKTIV',
      'Diese Wortart beschreibt, wie etwas ist, etwa bunt oder leise.',
    ),
    _Word('PRÄSENS', 'So heißt die Zeitform der Gegenwart.'),
    _Word('SUBJEKT', 'Das Satzglied, nach dem du mit Wer oder was fragst.'),
    _Word('PRÄDIKAT', 'Das Satzglied, das die Aussage mit dem Verb enthält.'),
    _Word(
      'SYNONYM',
      'Ein Wort mit gleicher oder ähnlicher Bedeutung zu einem anderen.',
    ),
    _Word('GEGENTEIL', 'Kalt ist das ... von heiß.'),
    _Word('WÖRTER', 'Ein Satz besteht aus mehreren ...'),
    _Word('UMFANG', 'Die Länge des Randes einer ebenen Figur.'),
    _Word('FLÄCHE', 'Der Bereich innerhalb des Randes einer ebenen Figur.'),
    _Word(
      'QUADRAT',
      'Ein Viereck mit vier gleich langen Seiten und vier rechten Winkeln.',
    ),
    _Word(
      'RECHTECK',
      'Ein Viereck mit vier rechten Winkeln; gegenüberliegende Seiten sind gleich lang.',
    ),
    _Word('PRODUKT', 'So heißt das Ergebnis einer Multiplikation.'),
    _Word('QUOTIENT', 'So heißt das Ergebnis einer Division.'),
    _Word('DIFFERENZ', 'So heißt das Ergebnis einer Subtraktion.'),
    _Word(
      'FAKTOR',
      'Eine Zahl, die in einer Multiplikation mit einer anderen multipliziert wird.',
    ),
    _Word('REST', 'Was bei einer nicht aufgehenden Division übrig bleibt.'),
    _Word('TAUSEND', 'Diese Zahl ist zehnmal so groß wie hundert.'),
    _Word('MILLION', 'Diese Zahl ist tausendmal so groß wie tausend.'),
    _Word('GRAMM', 'Tausend Einheiten dieser Masse ergeben ein Kilogramm.'),
    _Word('TONNE', 'Diese Masseeinheit hat tausend Kilogramm.'),
    _Word(
      'ENERGIE',
      'Sie wird zum Beispiel zum Bewegen, Heizen oder Leuchten benötigt.',
    ),
    _Word('MAGNET', 'Er zieht Gegenstände aus Eisen an und hat zwei Pole.'),
    _Word('STROM', 'Bewegte elektrische Ladungen bilden elektrischen ...'),
    _Word(
      'KREISLAUF',
      'Ein Ablauf, bei dem etwas nach mehreren Schritten wieder zum Ausgang zurückkehrt.',
    ),
    _Word(
      'VERDUNSTEN',
      'So nennt man es, wenn flüssiges Wasser nach und nach in Wasserdampf übergeht.',
    ),
    _Word(
      'RECYCLING',
      'Abfälle werden aufbereitet, damit ihre Stoffe wieder verwendet werden können.',
    ),
    _Word(
      'GEMEINDE',
      'Eine örtliche Verwaltungseinheit; dazu gehören oft ein Ort und seine Umgebung.',
    ),
    _Word(
      'RATHAUS',
      'Ein Gebäude, in dem die Verwaltung einer Stadt arbeitet.',
    ),
    _Word('DONAU', 'Dieser große Fluss fließt durch Wien.'),
    _Word('WIEN', 'Die Hauptstadt von Österreich.'),
    _Word('ALPEN', 'Dieses große Gebirge liegt auch in Österreich.'),
    _Word('EUROPA', 'Der Kontinent, auf dem Österreich liegt.'),
    _Word('GRENZE', 'Sie trennt zum Beispiel das Gebiet zweier Staaten.'),
    _Word(
      'KULTUR',
      'Dazu gehören zum Beispiel Sprache, Kunst und gemeinsame Bräuche.',
    ),
    _Word('HANDEL', 'Der Kauf und Verkauf von Waren heißt so.'),
    _Word(
      'BERUF',
      'Eine auf Dauer ausgeübte Arbeit, für die man oft eine Ausbildung braucht.',
    ),
    _Word(
      'ARGUMENT',
      'Ein begründeter Gedanke, der eine Meinung stützen soll.',
    ),
    _Word(
      'KOMPROMISS',
      'Eine gemeinsame Lösung, bei der beide Seiten etwas nachgeben.',
    ),
    _Word('FAIRNESS', 'Gerechtes Verhalten und gleiche Regeln für alle.'),
    _Word(
      'VERTRAUEN',
      'Das Gefühl, dass du dich auf jemanden verlassen kannst.',
    ),
    _Word('ZUHÖREN', 'Aufmerksam beachten, was ein anderer Mensch sagt.'),
  ],
];
