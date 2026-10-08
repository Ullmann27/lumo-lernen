import 'dart:math';

import '../../domain/iq/iq_puzzle.dart';
import 'iq_puzzle_generator.dart';

/// Ablauf eines IQ-Rätsel-Tests: sechs Bereiche nacheinander, je
/// [itemsPerArea] Rätsel. Die Stufe passt sich an: gelöst → eine Stufe
/// schwerer, nicht gelöst → eine Stufe leichter.
class IqTestSession {
  IqTestSession({
    required int grade,
    int? seed,
    this.itemsPerArea = 4,
  })  : grade = grade.clamp(1, 4),
        seed = seed ?? DateTime.now().microsecondsSinceEpoch & 0x7fffffff {
    _generator = IqPuzzleGenerator(Random(this.seed));
    for (final area in IqArea.values) {
      _levels[area] = startLevelFor(this.grade);
    }
    _current = _generate();
  }

  static const version = 'lumo-iq-v1-2026-10-08';

  final int grade;
  final int seed;
  final int itemsPerArea;
  late final IqPuzzleGenerator _generator;
  final Map<IqArea, int> _levels = {};
  final List<IqItemRecord> _records = [];
  final List<IqPuzzle> _puzzles = [];
  final List<List<int>> _responses = [];
  int _index = 0;
  late IqPuzzle _current;

  /// Startstufe nach Schulstufe: 1. Klasse → 2, 4. Klasse → 5.
  static int startLevelFor(int grade) => grade.clamp(1, 4) + 1;

  int get totalItems => IqArea.values.length * itemsPerArea;
  int get index => _index;
  bool get finished => _index >= totalItems;
  IqPuzzle get current => _current;
  IqArea get area => IqArea.values[(_index ~/ itemsPerArea).clamp(0, IqArea.values.length - 1)];
  int get areaNumber => _index ~/ itemsPerArea + 1;
  int get itemInArea => _index % itemsPerArea + 1;
  bool get atAreaStart => !finished && _index % itemsPerArea == 0;
  List<IqItemRecord> get records => List.unmodifiable(_records);

  /// Gestellte Rätsel mit den gegebenen Antworten (für den Rückblick).
  List<(IqPuzzle, List<int>)> get answered => [
        for (var i = 0; i < _puzzles.length; i++) (_puzzles[i], _responses[i]),
      ];

  /// Speichert die Antwort, passt die Stufe an und stellt das nächste Rätsel.
  bool answer(List<int> response, {required int durationMs}) {
    if (finished) throw StateError('Der Test ist schon fertig.');
    final puzzle = _current;
    final correct = puzzle.isCorrect(response);
    _puzzles.add(puzzle);
    _responses.add(List.unmodifiable(response));
    _records.add(IqItemRecord(
      puzzleId: puzzle.id,
      area: puzzle.area,
      level: puzzle.level,
      correct: correct,
      durationMs: durationMs.clamp(0, 3600000),
      given: puzzle.describeResponse(response),
      expected: puzzle.describeExpected(),
    ));
    final level = _levels[puzzle.area]!;
    _levels[puzzle.area] =
        (correct ? level + 1 : level - 1).clamp(1, IqPuzzleGenerator.maxLevel);
    _index++;
    if (!finished) _current = _generate();
    return correct;
  }

  IqTestResult result({
    required String id,
    required String studentId,
    required DateTime finishedAt,
    required int durationMs,
  }) =>
      IqTestResult(
        id: id,
        studentId: studentId,
        grade: grade,
        version: version,
        seed: seed,
        finishedAt: finishedAt,
        durationMs: durationMs.clamp(0, 86400000),
        items: List.unmodifiable(_records),
      );

  IqPuzzle _generate() {
    final area = this.area;
    return _generator.generate(
      area,
      _levels[area]!,
      'iq_${area.name}_${_index % itemsPerArea + 1}',
    );
  }
}
