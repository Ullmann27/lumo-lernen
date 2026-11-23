import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/logic/logic_games.dart';

Map<int, String> _solution(LogicPuzzle puzzle) => {
  for (final cell in puzzle.editableCells) cell.index: cell.answer,
};

String _signature(LogicPuzzle puzzle) =>
    '${puzzle.rows}/${puzzle.columns}/'
    '${puzzle.cells.map((c) => '${c.answer}:${c.given}').join('|')}';

void main() {
  test('catalog has 144 stable, distinct, nontrivial school-grade puzzles', () {
    final ids = <String>{};
    for (final kind in LogicGameKind.values) {
      for (var grade = 1; grade <= 4; grade++) {
        final levels = LogicCatalog.levels(kind, grade);
        expect(levels, hasLength(12));
        final signatures = <String>{};
        for (var i = 0; i < levels.length; i++) {
          final puzzle = levels[i];
          expect(ids.add(puzzle.id), isTrue, reason: puzzle.id);
          expect(
            signatures.add(_signature(puzzle)),
            isTrue,
            reason: 'Repeated board: ${puzzle.id}',
          );
          expect(puzzle.grade, grade);
          expect(puzzle.level, i + 1);
          expect(puzzle.kind, kind);
          expect(puzzle.editableCells, isNotEmpty);
          expect(puzzle.isComplete({}), isFalse);
          expect(puzzle.isComplete(_solution(puzzle)), isTrue);
          final wrong = _solution(puzzle);
          wrong[puzzle.editableCells.first.index] = '?';
          expect(puzzle.isComplete(wrong), isFalse);
          expect(puzzle.cells, hasLength(puzzle.rows * puzzle.columns));
          expect(
            _signature(LogicCatalog.puzzle(kind, grade, i + 1)),
            _signature(puzzle),
          );
        }
      }
    }
    expect(ids, hasLength(144));
    expect(
      () => LogicCatalog.levels(LogicGameKind.sudoku, 0),
      throwsArgumentError,
    );
    expect(
      () => LogicCatalog.levels(LogicGameKind.sudoku, 5),
      throwsArgumentError,
    );
    expect(
      () => LogicCatalog.puzzle(LogicGameKind.words, 1, 0),
      throwsArgumentError,
    );
    expect(
      () => LogicCatalog.puzzle(LogicGameKind.words, 1, 13),
      throwsArgumentError,
    );
  });

  for (var grade = 1; grade <= 4; grade++) {
    test(
      'grade $grade: all Sudoku have exactly one solution without guesses',
      () {
        var previousHoles = 0;
        for (final puzzle in LogicCatalog.levels(LogicGameKind.sudoku, grade)) {
          final initial = [
            for (final cell in puzzle.cells)
              cell.given ? int.parse(cell.answer) : 0,
          ];
          final solved = [
            for (final cell in puzzle.cells) int.parse(cell.answer),
          ];
          expect(
            LogicSudokuSolver.validGrid(
              solved,
              puzzle.columns,
              puzzle.blockRows!,
              puzzle.blockColumns!,
            ),
            isTrue,
            reason: puzzle.id,
          );
          expect(
            LogicSudokuSolver.countSolutions(
              initial,
              puzzle.columns,
              puzzle.blockRows!,
              puzzle.blockColumns!,
            ),
            1,
            reason: puzzle.id,
          );
          expect(
            LogicSudokuSolver.solvableBySingles(
              initial,
              puzzle.columns,
              puzzle.blockRows!,
              puzzle.blockColumns!,
            ),
            isTrue,
            reason: puzzle.id,
          );
          expect(
            puzzle.editableCells.length,
            greaterThanOrEqualTo(previousHoles),
          );
          previousHoles = puzzle.editableCells.length;
          final filled = <int, String>{};
          while (!puzzle.isComplete(filled)) {
            final next = puzzle.suggestedHintIndex(filled)!;
            final candidates = puzzle.sudokuCandidates(next, filled);
            expect(candidates, hasLength(1), reason: puzzle.id);
            expect('${candidates.single}', puzzle.cells[next].answer);
            filled[next] = '${candidates.single}';
          }
          expect(puzzle.suggestedHintIndex(filled), isNull);
        }
      },
    );

    test(
      'grade $grade: crossword clues form real, connected, consistent words',
      () {
        for (final puzzle in LogicCatalog.levels(LogicGameKind.words, grade)) {
          expect(puzzle.clues.length, greaterThanOrEqualTo(3));
          expect(puzzle.rows, lessThanOrEqualTo(10));
          expect(puzzle.columns, lessThanOrEqualTo(10));
          final words = <String>{};
          final membership = <int, int>{};
          for (final clue in puzzle.clues) {
            expect(words.add(clue.answer), isTrue);
            expect(clue.text, isNotEmpty);
            expect(
              clue.cells.map((i) => puzzle.cells[i].answer).join(),
              clue.answer,
              reason: '${puzzle.id}/${clue.id}',
            );
            expect(clue.cells.length, clue.answer.length);
            for (final index in clue.cells) {
              expect(puzzle.cells[index].blocked, isFalse);
              membership.update(index, (value) => value + 1, ifAbsent: () => 1);
            }
          }
          expect(membership.values.any((count) => count == 2), isTrue);
          expect(membership.values.every((count) => count <= 2), isTrue);

          final visited = <int>{puzzle.clues.first.cells.first};
          var changed = true;
          while (changed) {
            changed = false;
            for (final clue in puzzle.clues) {
              if (clue.cells.any(visited.contains)) {
                final previous = visited.length;
                visited.addAll(clue.cells);
                changed = changed || previous != visited.length;
              }
            }
          }
          expect(
            puzzle.cells
                .where((cell) => !cell.blocked)
                .every((cell) => visited.contains(cell.index)),
            isTrue,
            reason: 'Disconnected crossword ${puzzle.id}',
          );

          // Adjacent words must not accidentally create un-clued letter runs.
          for (final across in [true, false]) {
            final outer = across ? puzzle.rows : puzzle.columns;
            final inner = across ? puzzle.columns : puzzle.rows;
            for (var a = 0; a < outer; a++) {
              var run = <int>[];
              void checkRun() {
                if (run.length <= 1) return;
                expect(
                  puzzle.clues.any(
                    (clue) => clue.cells.join(',') == run.join(','),
                  ),
                  isTrue,
                  reason: '${puzzle.id}: unintended run $run',
                );
              }

              for (var b = 0; b < inner; b++) {
                final index = across
                    ? a * puzzle.columns + b
                    : b * puzzle.columns + a;
                if (puzzle.cells[index].blocked) {
                  checkRun();
                  run = [];
                } else {
                  run.add(index);
                }
              }
              checkRun();
            }
          }
        }
      },
    );

    test(
      'grade $grade: every math crossword is exact and uniquely inferable',
      () {
        for (final puzzle in LogicCatalog.levels(LogicGameKind.maths, grade)) {
          final solution = {
            for (final cell in puzzle.cells)
              if (!cell.blocked && !cell.isOperator)
                cell.index: int.parse(cell.answer),
          };
          final givens = {
            for (final cell in puzzle.cells)
              if (cell.given && !cell.isOperator)
                cell.index: int.parse(cell.answer),
          };
          expect(solution.values.every((value) => value >= 0), isTrue);
          if (grade == 1)
            expect(solution.values, everyElement(lessThanOrEqualTo(20)));
          if (grade == 2)
            expect(solution.values, everyElement(lessThanOrEqualTo(100)));
          if (grade == 3)
            expect(solution.values, everyElement(lessThanOrEqualTo(1000)));
          expect(
            puzzle.equations.every((e) => e.isSatisfied(solution)),
            isTrue,
            reason: puzzle.id,
          );
          final derived = LogicCatalog.inferMathValues(
            givens,
            puzzle.equations,
          );
          expect(derived, solution, reason: 'Underdetermined ${puzzle.id}');
          // Changing any editable number breaks at least one visible equation.
          for (final cell in puzzle.editableCells) {
            final changed = {
              ...solution,
              cell.index: int.parse(cell.answer) + 1,
            };
            expect(
              puzzle.equations.every((e) => e.isSatisfied(changed)),
              isFalse,
            );
          }
        }
      },
    );
  }

  test('Sudoku solver rejects invalid givens and detects ambiguous boards', () {
    final invalid = List<int>.filled(16, 0)
      ..[0] = 1
      ..[1] = 1;
    expect(LogicSudokuSolver.countSolutions(invalid, 4, 2, 2), 0);
    expect(LogicSudokuSolver.countSolutions(List.filled(16, 0), 4, 2, 2), 2);
    expect(LogicSudokuSolver.countSolutions(List.filled(15, 0), 4, 2, 2), 0);
    expect(LogicSudokuSolver.validGrid(List.filled(16, 0), 4, 2, 3), isFalse);
    expect(
      () => LogicSudokuSolver.countSolutions(
        List.filled(16, 0),
        4,
        2,
        2,
        limit: 0,
      ),
      throwsArgumentError,
    );
  });

  test(
    'exact math inverses do not manufacture answers for division by zero',
    () {
      const multiply = LogicMathEquation(
        first: 0,
        second: 1,
        result: 2,
        operation: LogicMathOperation.multiply,
        label: 'multiply',
      );
      const divide = LogicMathEquation(
        first: 0,
        second: 1,
        result: 2,
        operation: LogicMathOperation.divide,
        label: 'divide',
      );
      expect(multiply.infer({0: 0, 2: 0}), isNull);
      expect(multiply.infer({0: 3, 2: 10}), isNull);
      expect(divide.infer({1: 0, 2: 3}), isNull);
      expect(divide.infer({0: 0, 2: 0}), isNull);
      expect(divide.infer({0: 12, 2: 3}), (1, 4));
      expect(divide.infer({1: 4, 2: 3}), (0, 12));
      expect(divide.infer({0: 12, 1: 4}), (2, 3));
      expect(LogicMathOperation.divide.apply(7, 2), isNull);
    },
  );

  test('letter normalization preserves umlauts and accepts lower case', () {
    expect(LogicPuzzle.normalize(' straße '), 'STRASSE');
    expect(LogicPuzzle.normalize('äöü'), 'ÄÖÜ');
    final puzzle = LogicCatalog.puzzle(LogicGameKind.words, 2, 1);
    final solution = _solution(
      puzzle,
    ).map((key, value) => MapEntry(key, ' ${value.toLowerCase()} '));
    expect(puzzle.isComplete(solution), isTrue);
    expect(puzzle.isCorrectCell(-1, 'A'), isFalse);
    expect(puzzle.isCorrectCell(puzzle.cells.length, 'A'), isFalse);
    final blocked = puzzle.cells.where((cell) => cell.blocked);
    if (blocked.isNotEmpty)
      expect(puzzle.isCorrectCell(blocked.first.index, ''), isFalse);
  });

  test('givens cannot be overwritten through the answers map', () {
    final puzzle = LogicCatalog.puzzle(LogicGameKind.sudoku, 1, 1);
    final given = puzzle.cells.firstWhere((cell) => cell.given);
    expect(puzzle.visibleValue(given.index, {given.index: '9'}), given.answer);
    expect(puzzle.hintFor(given.index), contains('freies Feld'));
    expect(() => puzzle.cells.clear(), throwsUnsupportedError);
    expect(
      () => LogicCatalog.levels(LogicGameKind.words, 1).clear(),
      throwsUnsupportedError,
    );
  });
}
