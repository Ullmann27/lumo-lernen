import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/iq/iq_puzzle_generator.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';

bool _connected(IqPolyomino piece) {
  final cells = piece.cells.toSet();
  final seen = <(int, int)>{cells.first};
  final queue = [cells.first];
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeLast();
    for (final next in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
      if (cells.contains(next) && seen.add(next)) queue.add(next);
    }
  }
  return seen.length == cells.length;
}

void main() {
  group('Bauteile für Drehen im Kopf', () {
    test('alle Bauteile sind zusammenhängend, händig und verschieden', () {
      for (final entry in IqPuzzleGenerator.chiralPieces.entries) {
        for (final piece in entry.value) {
          expect(piece.cells.length, entry.key);
          expect(_connected(piece), isTrue, reason: piece.key);
          expect(piece.chiral, isTrue, reason: 'Spiegelbild ist Drehung: ${piece.key}');
        }
        for (var a = 0; a < entry.value.length; a++) {
          for (var b = a + 1; b < entry.value.length; b++) {
            final pa = entry.value[a], pb = entry.value[b];
            expect(pa.sameAsRotationOf(pb) || pa.sameAsRotationOf(pb.mirrored()),
                isFalse,
                reason: '${pa.key} und ${pb.key} sind dasselbe Teil');
          }
        }
      }
      for (final piece in IqPuzzleGenerator.otherPieces) {
        expect(_connected(piece), isTrue);
      }
    });

    test('vier Vierteldrehungen ergeben wieder das Teil', () {
      final piece = IqPuzzleGenerator.chiralPieces[5]!.first;
      expect(piece.rotated(4).key, piece.key);
      expect(piece.rotated(1).rotated(3).key, piece.key);
      expect(piece.mirrored().mirrored().key, piece.key);
    });
  });

  group('Rätselgenerator', () {
    test('jede Stufe jedes Bereichs: genau eine richtige, lauter verschiedene Antworten',
        () {
      for (var seed = 0; seed < 120; seed++) {
        final generator = IqPuzzleGenerator(Random(seed));
        for (final area in IqArea.values) {
          for (var level = 1; level <= IqPuzzleGenerator.maxLevel; level++) {
            final puzzle = generator.generate(area, level, 'p');
            final where = '${area.name} Stufe $level Seed $seed';
            expect(puzzle.level, level, reason: where);
            switch (puzzle) {
              case IqMatrixPuzzle p:
                expect(p.cells.where((c) => c == null).length, 1, reason: where);
                expect(p.cells.length, p.columns * p.columns, reason: where);
                expect(p.options.length, level <= 4 ? 4 : 6, reason: where);
                expect(p.options.map((o) => o.key).toSet().length,
                    p.options.length,
                    reason: '$where: doppelte Antwort');
              case IqSeriesPuzzle p:
                expect(p.options.length, level <= 4 ? 4 : 5, reason: where);
                expect(p.options.map((o) => o.key).toSet().length,
                    p.options.length,
                    reason: '$where: doppelte Antwort');
              case IqOddOnePuzzle p:
                // Genau eine Figur weicht in genau dem Regelmerkmal ab; in
                // keinem Merkmal stehen vier gleiche gegen eine andere,
                // außer bei der richtigen Figur.
                final attributes = <String Function(IqFigure)>[
                  (f) => f.shape.name,
                  (f) => f.tint.name,
                  (f) => '${f.count}',
                  (f) => '${f.shape.directional ? f.turns % 8 : 0}',
                  (f) => '${f.size}',
                  (f) => '${f.filled}',
                ];
                final singledOut = <int>{};
                for (final attribute in attributes) {
                  final values = p.figures.map(attribute).toList();
                  for (var i = 0; i < values.length; i++) {
                    final others = [...values]..removeAt(i);
                    if (others.toSet().length == 1 && others.first != values[i]) {
                      singledOut.add(i);
                    }
                  }
                }
                expect(singledOut, {p.answer}, reason: where);
              case IqRotationPuzzle p:
                expect(p.options.length, level >= 7 ? 5 : 4, reason: where);
                final rotations = p.options
                    .where((o) => o.sameAsRotationOf(p.target))
                    .length;
                expect(rotations, 1, reason: '$where: nur eine echte Drehung');
                expect(p.options[p.answer].sameAsRotationOf(p.target), isTrue,
                    reason: where);
                expect(p.options.map((o) => o.key).toSet().length,
                    p.options.length,
                    reason: '$where: doppelte Antwort');
                expect(p.options[p.answer].key == p.target.key, isFalse,
                    reason: '$where: Antwort darf nicht ungedreht sein');
                if (level >= 3) {
                  expect(
                      p.options.any((o) => o.sameAsRotationOf(p.target.mirrored())),
                      isTrue,
                      reason: '$where: Spiegelbild als Falle');
                }
              case IqNumberPuzzle p:
                expect(p.numbers.where((n) => n == null).length, 1, reason: where);
                expect(p.options.length, 4, reason: where);
                expect(p.options.toSet().length, 4, reason: '$where: doppelte Antwort');
                expect(p.options.every((o) => o > 0), isTrue, reason: where);
              case IqMemoryPuzzle p:
                expect(p.sequence.toSet().length, p.sequence.length, reason: where);
                expect(p.sequence.every((i) => i >= 0 && i < p.gridSize * p.gridSize),
                    isTrue,
                    reason: where);
                expect(p.isCorrect(p.sequence), isTrue);
                expect(p.isCorrect(p.sequence.reversed.toList()), isFalse);
            }
            if (puzzle is IqChoicePuzzle) {
              expect(puzzle.answer, inInclusiveRange(0, puzzle.optionCount - 1),
                  reason: where);
              expect(puzzle.isCorrect([puzzle.answer]), isTrue, reason: where);
              for (var i = 0; i < puzzle.optionCount; i++) {
                if (i != puzzle.answer) {
                  expect(puzzle.isCorrect([i]), isFalse, reason: where);
                }
              }
            }
          }
        }
      }
    });

    test('Matrix-Lösung folgt der Regel (Stufe 3: Spalte = Form, Reihe = Farbe)', () {
      final generator = IqPuzzleGenerator(Random(7));
      final puzzle = generator.generate(IqArea.matrix, 3, 'm') as IqMatrixPuzzle;
      final solution = puzzle.options[puzzle.answer];
      expect(solution.shape, puzzle.cells[2]!.shape);
      expect(solution.tint, puzzle.cells[6]!.tint);
    });

    test('Zahlenrätsel Stufe 4 verdoppelt', () {
      final generator = IqPuzzleGenerator(Random(3));
      final puzzle = generator.generate(IqArea.numbers, 4, 'n') as IqNumberPuzzle;
      final shown = puzzle.numbers.whereType<int>().toList();
      expect(puzzle.options[puzzle.answer], shown.last * 2);
    });
  });

  group('Ablauf und Auswertung', () {
    test('Startstufe nach Schulstufe, Anpassung nach oben und unten', () {
      expect(IqTestSession.startLevelFor(1), 2);
      expect(IqTestSession.startLevelFor(4), 5);
      final session = IqTestSession(grade: 2, seed: 11);
      expect(session.totalItems, 24);
      expect(session.current.area, IqArea.matrix);
      expect(session.current.level, 3);
      // Richtig → Stufe 4, falsch → wieder Stufe 3.
      session.answer(_correctResponse(session.current), durationMs: 900);
      expect(session.current.level, 4);
      session.answer(_wrongResponse(session.current), durationMs: 900);
      expect(session.current.level, 3);
    });

    test('kompletter Durchlauf liefert ehrliche Auswertung und JSON-Rundreise', () {
      final session = IqTestSession(grade: 3, seed: 99);
      var expectedSolved = 0;
      var index = 0;
      while (!session.finished) {
        expect(session.area, IqArea.values[index ~/ 4]);
        final good = index % 3 != 0;
        if (good) expectedSolved++;
        session.answer(
          good ? _correctResponse(session.current) : _wrongResponse(session.current),
          durationMs: 1000 + index,
        );
        index++;
      }
      expect(index, 24);
      final result = session.result(
        id: 'iq-1',
        studentId: 'kind',
        finishedAt: DateTime(2026, 10, 8, 12),
        durationMs: 600000,
      );
      expect(result.solved, expectedSolved);
      expect(result.total, 24);
      expect(result.areaScores.length, 6);
      for (final score in result.areaScores) {
        expect(score.total, 4);
        expect(score.startLevel, 4);
        expect(score.bestLevel, inInclusiveRange(0, 8));
      }
      expect(result.thinkingPoints,
          result.items.where((i) => i.correct).fold<int>(0, (s, i) => s + i.level));
      final copy = IqTestResult.fromJson(result.toJson())!;
      expect(copy.solved, result.solved);
      expect(copy.thinkingPoints, result.thinkingPoints);
      expect(copy.items.first.expected, result.items.first.expected);
      expect(copy.seed, 99);
      expect(() => session.answer(const [0], durationMs: 1), throwsStateError);
    });

    test('gleicher Startwert ergibt dieselben Rätsel', () {
      final a = IqTestSession(grade: 1, seed: 5);
      final b = IqTestSession(grade: 1, seed: 5);
      expect(a.current.describeExpected(), b.current.describeExpected());
    });
  });
}

List<int> _correctResponse(IqPuzzle puzzle) => switch (puzzle) {
      IqChoicePuzzle p => [p.answer],
      IqMemoryPuzzle p => p.sequence,
    };

List<int> _wrongResponse(IqPuzzle puzzle) => switch (puzzle) {
      IqChoicePuzzle p => [(p.answer + 1) % p.optionCount],
      IqMemoryPuzzle p => p.sequence.reversed.toList(),
    };
