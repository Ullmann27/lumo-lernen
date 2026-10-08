import 'dart:math';

import '../../domain/iq/iq_puzzle.dart';

/// Erzeugt IQ-Rätsel in acht Stufen je Bereich. Jedes Rätsel hat genau eine
/// richtige Antwort; alle Antwortmöglichkeiten sehen verschieden aus.
class IqPuzzleGenerator {
  IqPuzzleGenerator(this._random);

  final Random _random;

  static const maxLevel = 8;

  static const basicShapes = <IqShape>[
    IqShape.circle,
    IqShape.square,
    IqShape.triangle,
    IqShape.diamond,
    IqShape.star,
    IqShape.hexagon,
    IqShape.plus,
  ];
  static const directionalShapes = <IqShape>[IqShape.arrow, IqShape.notch];

  /// Farbdreiergruppen mit deutlich verschiedenen Farbtönen.
  static const _tintTriples = <List<IqTint>>[
    [IqTint.orange, IqTint.cyan, IqTint.violet],
    [IqTint.pink, IqTint.green, IqTint.gold],
    [IqTint.orange, IqTint.green, IqTint.violet],
    [IqTint.gold, IqTint.cyan, IqTint.pink],
  ];

  /// Händige Bauteile (Spiegelbild ist keine Drehung) nach Blockzahl. Alle
  /// sind zusammenhängend, höchstens 4×4 groß und paarweise verschieden
  /// (Drehen und Spiegeln eingerechnet); der Test prüft das.
  static final chiralPieces = <int, List<IqPolyomino>>{
    4: [
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2)]),
      IqPolyomino(const [(1, 0), (2, 0), (0, 1), (1, 1)]),
    ],
    5: [
      IqPolyomino(const [(1, 0), (2, 0), (0, 1), (1, 1), (1, 2)]),
      IqPolyomino(const [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (1, 2), (1, 3)]),
      IqPolyomino(const [(1, 0), (0, 1), (1, 1), (1, 2), (1, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)]),
    ],
    6: [
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (2, 1), (3, 1), (2, 2)]),
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2), (2, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2), (2, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (2, 1), (1, 2), (2, 2)]),
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2), (1, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (1, 2), (1, 3), (2, 3)]),
    ],
    7: [
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (2, 1), (1, 2), (1, 3), (2, 3)]),
      IqPolyomino(const [(0, 0), (1, 0), (1, 1), (0, 2), (1, 2), (2, 2), (1, 3)]),
      IqPolyomino(const [(0, 0), (1, 0), (0, 1), (1, 1), (2, 1), (1, 2), (1, 3)]),
      IqPolyomino(const [(0, 0), (1, 0), (1, 1), (2, 1), (0, 2), (1, 2), (1, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2), (3, 2), (1, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (0, 2), (1, 2), (2, 2), (0, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (1, 1), (2, 1), (1, 2), (0, 3), (1, 3)]),
      IqPolyomino(const [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2), (3, 2), (3, 3)]),
    ],
  };

  /// Andere Bauteile gleicher Größe für die leichten Stufen.
  static final otherPieces = <IqPolyomino>[
    IqPolyomino(const [(0, 0), (1, 0), (2, 0), (1, 1)]),
    IqPolyomino(const [(0, 0), (1, 0), (0, 1), (1, 1)]),
    IqPolyomino(const [(0, 0), (0, 1), (0, 2), (0, 3)]),
    IqPolyomino(const [(0, 0), (1, 0), (1, 1), (2, 1)]),
    IqPolyomino(const [(0, 0), (1, 0), (2, 0), (0, 1)]),
  ];

  IqPuzzle generate(IqArea area, int level, String id) {
    final l = level.clamp(1, maxLevel);
    return switch (area) {
      IqArea.matrix => _matrix(l, id),
      IqArea.series => _series(l, id),
      IqArea.oddOneOut => _oddOne(l, id),
      IqArea.rotation => _rotation(l, id),
      IqArea.numbers => _numbers(l, id),
      IqArea.memory => _memory(l, id),
    };
  }

  // ---------------------------------------------------------------- Matrix

  IqMatrixPuzzle _matrix(int level, String id) {
    final shapes = _distinct(3, basicShapes);
    final tints = _shuffled(_tintTriples[_random.nextInt(_tintTriples.length)]);
    late final int n;
    late final IqFigure Function(int r, int c) cell;
    late final String rule;
    switch (level) {
      case 1:
        n = 2;
        cell = (r, c) => IqFigure(shapes[r], tint: tints[0]);
        rule = 'In jeder Reihe steht zweimal dieselbe Figur.';
      case 2:
        n = 2;
        cell = (r, c) => IqFigure(shapes[c], tint: tints[r]);
        rule = 'Jede Spalte hat ihre Form, jede Reihe ihre Farbe.';
      case 3:
        n = 3;
        cell = (r, c) => IqFigure(shapes[c], tint: tints[r]);
        rule = 'Jede Spalte hat ihre Form, jede Reihe ihre Farbe.';
      case 4:
        n = 3;
        cell = (r, c) => IqFigure(shapes[r], tint: tints[r], count: c + 1);
        rule = 'Nach rechts kommt jedes Mal eine Form dazu. Jede Reihe hat ihre Form.';
      case 5:
        n = 3;
        final shape = directionalShapes[_random.nextInt(2)];
        final starts = [for (var r = 0; r < 3; r++) _random.nextInt(8)];
        cell = (r, c) => IqFigure(shape, tint: tints[r], turns: starts[r] + 2 * c);
        rule = 'In jeder Reihe dreht sich die Figur nach rechts um eine Vierteldrehung weiter.';
      case 6:
        n = 3;
        cell = (r, c) => IqFigure(shapes[(r + c) % 3], tint: tints[c]);
        rule = 'Jede Form kommt in jeder Reihe und Spalte genau einmal vor. Jede Spalte hat ihre Farbe.';
      case 7:
        n = 3;
        cell = (r, c) =>
            IqFigure(shapes[(r + c) % 3], tint: tints[(r + 2 * c) % 3]);
        rule = 'Jede Form und jede Farbe kommt in jeder Reihe und Spalte genau einmal vor.';
      default:
        n = 3;
        cell = (r, c) => IqFigure(shapes[(r + c) % 3],
            tint: tints[r], count: (r + 2 * c) % 3 + 1);
        rule = 'Formen und Anzahlen kommen in jeder Reihe und Spalte genau einmal vor. Jede Reihe hat ihre Farbe.';
    }
    final cells = <IqFigure?>[
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++) cell(r, c),
    ];
    final correct = cells.last!;
    cells[cells.length - 1] = null;
    final optionCount = level <= 4 ? 4 : 6;
    final (options, answer) = _figureOptions(
      correct,
      [...cells.whereType<IqFigure>()],
      optionCount,
      mutateShape: level != 5,
      mutateTurns: level == 5,
      mutateCount: level == 4 || level == 8,
      tints: tints,
      shapes: shapes,
    );
    return IqMatrixPuzzle(
      id: id,
      level: level,
      question: 'Welche Figur passt ins leere Feld?',
      explanation: rule,
      answer: answer,
      columns: n,
      cells: cells,
      options: options,
    );
  }

  // ---------------------------------------------------------------- Folgen

  IqSeriesPuzzle _series(int level, String id) {
    final shapes = _distinct(3, basicShapes);
    final tints = _shuffled(_tintTriples[_random.nextInt(_tintTriples.length)]);
    final directional = directionalShapes[_random.nextInt(2)];
    final start = _random.nextInt(8);
    final shownCount = level <= 4 ? 4 : 5;
    late final IqFigure Function(int i) item;
    late final String rule;
    var mutateShape = false, mutateTurns = false, mutateCount = false;
    var mutateFill = false;
    switch (level) {
      case 1:
        item = (i) => IqFigure(shapes[i % 2], tint: tints[0]);
        rule = 'Zwei Figuren wechseln sich ab.';
        mutateShape = true;
      case 2:
        item = (i) => IqFigure(shapes[0], tint: tints[i % 3]);
        rule = 'Drei Farben kommen immer in derselben Reihenfolge.';
      case 3:
        item = (i) => IqFigure(shapes[0], tint: tints[0], count: i + 1);
        rule = 'Bei jedem Schritt kommt eine Form dazu.';
        mutateCount = true;
      case 4:
        item = (i) => IqFigure(directional, tint: tints[0], turns: start + 2 * i);
        rule = 'Die Figur dreht sich jedes Mal um eine Vierteldrehung nach rechts.';
        mutateTurns = true;
      case 5:
        item = (i) => IqFigure(shapes[i % 3], tint: tints[i % 2]);
        rule = 'Drei Formen wiederholen sich, und zwei Farben wechseln sich ab.';
        mutateShape = true;
      case 6:
        item = (i) => IqFigure(directional,
            tint: tints[0], turns: start + i, count: i % 2 + 1);
        rule = 'Die Figur dreht sich jedes Mal um eine Achteldrehung nach rechts, und die Anzahl wechselt zwischen 1 und 2.';
        mutateTurns = true;
        mutateCount = true;
      case 7:
        item = (i) => IqFigure(shapes[0], tint: tints[i % 3], count: 6 - i);
        rule = 'Jedes Mal ist es eine Form weniger, und drei Farben wiederholen sich.';
        mutateCount = true;
      default:
        item = (i) => IqFigure(directional,
            tint: tints[i % 3], turns: start + 3 * i, filled: i.isEven);
        rule = 'Die Figur dreht sich um drei Achteldrehungen weiter, drei Farben wiederholen sich, und voll und leer wechseln sich ab.';
        mutateTurns = true;
        mutateFill = true;
    }
    final shown = [for (var i = 0; i < shownCount; i++) item(i)];
    final correct = item(shownCount);
    final (options, answer) = _figureOptions(
      correct,
      shown,
      level <= 4 ? 4 : 5,
      mutateShape: mutateShape,
      mutateTurns: mutateTurns,
      mutateCount: mutateCount,
      mutateFill: mutateFill,
      tints: tints,
      shapes: shapes,
    );
    return IqSeriesPuzzle(
      id: id,
      level: level,
      question: 'Welche Figur kommt als Nächstes?',
      explanation: rule,
      answer: answer,
      shown: shown,
      options: options,
    );
  }

  // ---------------------------------------------------- Was passt nicht?

  IqOddOnePuzzle _oddOne(int level, String id) {
    final n = level <= 3 ? 4 : 5;
    final odd = _random.nextInt(n);
    final shapes = _distinct(n, basicShapes);
    final tints = _distinct(n, IqTint.values);
    final baseShape = shapes[0];
    final baseTint = tints[0];
    // Ablenkende Werte ohne 4:1-Verteilung (höchstens zweimal derselbe Wert).
    final counts = _shuffled([1, 1, 2, 2, 3]).take(n).toList();
    late final List<IqFigure> figures;
    late final String rule;
    switch (level) {
      case 1:
        final other = shapes[1];
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(i == odd ? other : baseShape, tint: baseTint),
        ];
        rule = 'Alle anderen haben dieselbe Form.';
      case 2:
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(baseShape, tint: i == odd ? tints[1] : baseTint),
        ];
        rule = 'Alle anderen haben dieselbe Farbe.';
      case 3:
        final other = shapes[1];
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(i == odd ? other : baseShape, tint: tints[i]),
        ];
        rule = 'Die Farben sind egal: Alle anderen haben dieselbe Form.';
      case 4:
        final other = _distinct(2, IqTint.values.where((t) => t != baseTint).toList())[0];
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(shapes[i], tint: i == odd ? other : baseTint),
        ];
        rule = 'Die Formen sind egal: Alle anderen haben dieselbe Farbe.';
      case 5:
        final common = 1 + _random.nextInt(3);
        final different = common == 1 ? 2 : (_random.nextBool() ? common - 1 : common + 1);
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(shapes[i], tint: tints[i], count: i == odd ? different : common),
        ];
        rule = 'Form und Farbe sind egal: Bei allen anderen ist die Anzahl gleich.';
      case 6:
        final commonFilled = _random.nextBool();
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(shapes[i],
                tint: tints[i],
                count: counts[i],
                filled: i == odd ? !commonFilled : commonFilled),
        ];
        rule = commonFilled
            ? 'Alle anderen sind ausgemalt.'
            : 'Alle anderen sind nur umrandet.';
      case 7:
        final shape = directionalShapes[_random.nextInt(2)];
        final common = _random.nextInt(8);
        final different = common + 2 + _random.nextInt(5);
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(shape,
                tint: tints[i],
                count: counts[i],
                turns: i == odd ? different : common),
        ];
        rule = 'Farbe und Anzahl sind egal: Alle anderen zeigen in dieselbe Richtung.';
      default:
        final common = _random.nextBool() ? 0 : 2;
        figures = [
          for (var i = 0; i < n; i++)
            IqFigure(shapes[i],
                tint: tints[i],
                count: counts[i],
                size: i == odd ? (common == 0 ? 2 : 0) : common),
        ];
        rule = common == 0
            ? 'Form, Farbe und Anzahl sind egal: Alle anderen sind klein.'
            : 'Form, Farbe und Anzahl sind egal: Alle anderen sind groß.';
    }
    return IqOddOnePuzzle(
      id: id,
      level: level,
      question: 'Welche Figur passt nicht zu den anderen?',
      explanation: rule,
      answer: odd,
      figures: figures,
    );
  }

  // ---------------------------------------------------------------- Drehen

  IqRotationPuzzle _rotation(int level, String id) {
    final blocks = switch (level) { <= 4 => 4, 5 => 5, 6 => 5, 7 => 6, _ => 7 };
    final pool = chiralPieces[blocks]!;
    final base = pool[_random.nextInt(pool.length)];
    final target = base.rotated(_random.nextInt(4));
    var turn = switch (level) { 1 => 1, 2 => 2, _ => 1 + _random.nextInt(3) };
    // Bei Teilen mit Halbdrehungs-Symmetrie sähe 180° aus wie vorher.
    if (target.rotated(turn).key == target.key) turn = 1;
    final correct = target.rotated(turn);
    final mirror = target.mirrored();
    final mirrorCount = switch (level) { 1 || 2 => 0, 3 => 1, 4 => 2, 5 || 6 => 3, 7 => 3, _ => 4 };
    final optionCount = level >= 7 ? 5 : 4;
    final used = <String>{correct.key};
    final distractors = <IqPolyomino>[];
    for (final t in _shuffled([0, 1, 2, 3])) {
      if (distractors.length >= mirrorCount) break;
      final candidate = mirror.rotated(t);
      if (used.add(candidate.key)) distractors.add(candidate);
    }
    final others = _shuffled(blocks == 4
        ? otherPieces
        : [
            for (final piece in chiralPieces[blocks]!)
              if (!piece.sameAsRotationOf(base) &&
                  !piece.sameAsRotationOf(base.mirrored()))
                piece,
          ]);
    for (final piece in others) {
      if (distractors.length >= optionCount - 1) break;
      final candidate = piece.rotated(_random.nextInt(4));
      if (candidate.sameAsRotationOf(target) ||
          candidate.sameAsRotationOf(mirror)) {
        continue;
      }
      if (used.add(candidate.key)) distractors.add(candidate);
    }
    // Reichen die anderen Formen nicht, füllen weitere Spiegelbilder auf.
    for (final t in [0, 1, 2, 3]) {
      if (distractors.length >= optionCount - 1) break;
      final candidate = mirror.rotated(t);
      if (used.add(candidate.key)) distractors.add(candidate);
    }
    final answer = _random.nextInt(distractors.length + 1);
    final options = [...distractors]..insert(answer, correct);
    return IqRotationPuzzle(
      id: id,
      level: level,
      question: 'Welches Bauteil ist dasselbe, nur gedreht?',
      explanation: mirrorCount == 0
          ? 'Nur dieses Teil hat dieselbe Form – es ist bloß gedreht.'
          : 'Die anderen Teile sind umgeklappt (gespiegelt) oder haben eine andere Form. Dreh das Teil im Kopf, ohne es umzudrehen.',
      answer: answer,
      target: target,
      options: options,
      tint: IqTint.values[_random.nextInt(IqTint.values.length)],
    );
  }

  // ---------------------------------------------------------------- Zahlen

  IqNumberPuzzle _numbers(int level, String id) {
    late final List<int> sequence;
    late final String rule;
    switch (level) {
      case 1:
        final a = 1 + _random.nextInt(6);
        sequence = [for (var i = 0; i < 5; i++) a + i];
        rule = 'Jede Zahl ist um 1 größer.';
      case 2:
        final step = [2, 5, 10][_random.nextInt(3)];
        final a = step * (1 + _random.nextInt(3));
        sequence = [for (var i = 0; i < 5; i++) a + i * step];
        rule = 'Jede Zahl ist um $step größer.';
      case 3:
        final step = 2 + _random.nextInt(2);
        final a = 20 + _random.nextInt(11);
        sequence = [for (var i = 0; i < 5; i++) a - i * step];
        rule = 'Jede Zahl ist um $step kleiner.';
      case 4:
        final a = 1 + _random.nextInt(3);
        sequence = [for (var i = 0; i < 5; i++) a * (1 << i)];
        rule = 'Jede Zahl wird verdoppelt.';
      case 5:
        final up = 3 + _random.nextInt(3);
        final down = 1 + _random.nextInt(2);
        final a = 1 + _random.nextInt(5);
        sequence = [a];
        for (var i = 1; i < 6; i++) {
          sequence.add(sequence.last + (i.isOdd ? up : -down));
        }
        rule = 'Abwechselnd kommen $up dazu und $down weg.';
      case 6:
        final a = 1 + _random.nextInt(5);
        sequence = [a];
        for (var i = 1; i < 6; i++) {
          sequence.add(sequence.last + i);
        }
        rule = 'Der Abstand wird jedes Mal um 1 größer: +1, +2, +3 …';
      case 7:
        final a = 1 + _random.nextInt(3);
        final b = 10 * (1 + _random.nextInt(2));
        sequence = [
          for (var i = 0; i < 7; i++) i.isEven ? a + i ~/ 2 : b * (i ~/ 2 + 1),
        ];
        rule = 'Zwei Reihen sind ineinander verschachtelt: Jede zweite Zahl gehört zusammen.';
      default:
        if (_random.nextBool()) {
          final starts = [(1, 1), (1, 2), (2, 3), (1, 3)][_random.nextInt(4)];
          sequence = [starts.$1, starts.$2];
          while (sequence.length < 7) {
            sequence.add(sequence[sequence.length - 1] + sequence[sequence.length - 2]);
          }
          rule = 'Jede Zahl ist die Summe der beiden Zahlen davor.';
        } else {
          sequence = [for (var i = 1; i <= 6; i++) i * i];
          rule = 'Es sind Quadratzahlen: 1·1, 2·2, 3·3 …';
        }
    }
    // Ab Stufe 6 fehlt manchmal eine Zahl in der Mitte.
    final missing = level >= 6 && _random.nextBool()
        ? 2 + _random.nextInt(sequence.length - 3)
        : sequence.length - 1;
    final correct = sequence[missing];
    final numbers = <int?>[...sequence]..[missing] = null;
    // Typischer Fehler: den letzten Abstand einfach weiterführen.
    final left = sequence[missing - 1];
    final linear = left + (left - sequence[missing - 2]);
    final candidates = <int>[
      linear,
      correct + 1,
      correct - 1,
      correct + 2,
      correct - 2,
      correct + 10,
    ];
    final distractors = <int>[];
    for (final value in _shuffled(candidates.sublist(1))..insert(0, linear)) {
      if (distractors.length >= 3) break;
      if (value > 0 && value != correct && !distractors.contains(value)) {
        distractors.add(value);
      }
    }
    var extra = correct + 3;
    while (distractors.length < 3) {
      if (!distractors.contains(extra)) distractors.add(extra);
      extra++;
    }
    final answer = _random.nextInt(4);
    final options = [...distractors]..insert(answer, correct);
    return IqNumberPuzzle(
      id: id,
      level: level,
      question: 'Welche Zahl fehlt?',
      explanation: rule,
      answer: answer,
      numbers: numbers,
      options: options,
    );
  }

  // ----------------------------------------------------------- Merk-Blitz

  IqMemoryPuzzle _memory(int level, String id) {
    final grid = switch (level) { 1 || 2 || 4 => 3, _ => 4 };
    final length = switch (level) { 1 => 2, 2 || 3 => 3, 4 || 5 => 4, 6 => 5, 7 => 6, _ => 7 };
    final cells = _shuffled([for (var i = 0; i < grid * grid; i++) i]);
    return IqMemoryPuzzle(
      id: id,
      level: level,
      question: 'Tippe die Felder in derselben Reihenfolge an.',
      explanation: 'Die Reihenfolge hatte $length Felder.',
      gridSize: grid,
      sequence: cells.take(length).toList(growable: false),
      showMs: level <= 3 ? 750 : 620,
      gapMs: 260,
    );
  }

  // ---------------------------------------------------------------- Hilfen

  /// Richtige Figur plus plausible Ablenker, die sich in genau den
  /// Merkmalen unterscheiden, um die es in der Regel geht.
  (List<IqFigure>, int) _figureOptions(
    IqFigure correct,
    List<IqFigure> seen,
    int count, {
    required List<IqTint> tints,
    required List<IqShape> shapes,
    bool mutateShape = true,
    bool mutateTurns = false,
    bool mutateCount = false,
    bool mutateFill = false,
  }) {
    final used = <String>{correct.key};
    final distractors = <IqFigure>[];
    void offer(IqFigure figure) {
      if (distractors.length < count - 1 && used.add(figure.key)) {
        distractors.add(figure);
      }
    }

    // Ein Ablenker aus dem Rätsel selbst wirkt am glaubwürdigsten.
    for (final figure in _shuffled(seen)) {
      if (distractors.length >= (count - 1) ~/ 2) break;
      offer(figure);
    }
    final mutations = <IqFigure Function()>[
      for (final tint in tints) () => correct.copyWith(tint: tint),
      if (mutateShape)
        for (final shape in shapes) () => correct.copyWith(shape: shape),
      if (mutateTurns) ...[
        () => correct.copyWith(turns: correct.turns + 1),
        () => correct.copyWith(turns: correct.turns + 2),
        () => correct.copyWith(turns: correct.turns + 4),
        () => correct.copyWith(turns: correct.turns + 6),
        () => correct.copyWith(turns: correct.turns + 7),
      ],
      if (mutateCount) ...[
        () => correct.copyWith(count: (correct.count % 6) + 1),
        () => correct.copyWith(count: correct.count > 1 ? correct.count - 1 : 3),
      ],
      if (mutateFill) () => correct.copyWith(filled: !correct.filled),
    ];
    for (final mutation in _shuffled(mutations)) {
      offer(mutation());
    }
    // Zur Sicherheit: zwei Merkmale gleichzeitig ändern.
    var guard = 0;
    while (distractors.length < count - 1 && guard++ < 50) {
      offer(correct.copyWith(
        tint: IqTint.values[_random.nextInt(IqTint.values.length)],
        shape: mutateShape
            ? basicShapes[_random.nextInt(basicShapes.length)]
            : null,
        turns: mutateTurns ? correct.turns + 1 + _random.nextInt(7) : null,
      ));
    }
    final answer = _random.nextInt(distractors.length + 1);
    return ([...distractors]..insert(answer, correct), answer);
  }

  List<T> _shuffled<T>(List<T> list) => [...list]..shuffle(_random);

  List<T> _distinct<T>(int n, List<T> pool) => _shuffled(pool).take(n).toList();
}
