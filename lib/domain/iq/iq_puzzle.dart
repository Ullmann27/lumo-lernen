/// IQ-Rätsel für Kinder: gezeichnete Aufgaben in sechs Denkbereichen.
///
/// Reines Dart ohne Flutter, damit Erzeugung, Auswertung und Speicherung
/// ohne Oberfläche geprüft werden können.
library;

enum IqArea { matrix, series, oddOneOut, rotation, numbers, memory }

extension IqAreaText on IqArea {
  /// Name für Kinder.
  String get title => switch (this) {
        IqArea.matrix => 'Muster-Matrix',
        IqArea.series => 'Figurenfolge',
        IqArea.oddOneOut => 'Was passt nicht?',
        IqArea.rotation => 'Drehen im Kopf',
        IqArea.numbers => 'Zahlenrätsel',
        IqArea.memory => 'Merk-Blitz',
      };

  /// Was der Bereich anspricht (für Eltern).
  String get skill => switch (this) {
        IqArea.matrix => 'Logisches Schließen',
        IqArea.series => 'Regeln erkennen',
        IqArea.oddOneOut => 'Vergleichen und Ordnen',
        IqArea.rotation => 'Räumliches Vorstellen',
        IqArea.numbers => 'Zahlendenken',
        IqArea.memory => 'Arbeitsgedächtnis',
      };

  /// Kurze Anleitung, die vor dem ersten Rätsel des Bereichs erscheint.
  String get instruction => switch (this) {
        IqArea.matrix =>
          'In jedem Feld steht eine Figur. Finde die Regel und tippe auf die Figur, die ins leere Feld passt.',
        IqArea.series =>
          'Die Figuren verändern sich Schritt für Schritt. Welche Figur kommt als Nächstes?',
        IqArea.oddOneOut =>
          'Alle Figuren haben etwas gemeinsam – nur eine nicht. Tippe auf die Figur, die nicht dazupasst.',
        IqArea.rotation =>
          'Schau dir das Bauteil oben genau an. Welches Bauteil unten ist dasselbe, nur gedreht? Umgeklappte Teile zählen nicht.',
        IqArea.numbers =>
          'Die Zahlen folgen einer Regel. Welche Zahl fehlt?',
        IqArea.memory =>
          'Felder leuchten nacheinander auf. Merke dir die Reihenfolge und tippe die Felder danach genauso an.',
      };

  /// Ehrentitel, wenn der Bereich die größte Stärke war.
  String get badge => switch (this) {
        IqArea.matrix => 'Muster-Meister',
        IqArea.series => 'Folgen-Finder',
        IqArea.oddOneOut => 'Formen-Detektiv',
        IqArea.rotation => 'Dreh-Profi',
        IqArea.numbers => 'Zahlen-Zauberer',
        IqArea.memory => 'Merk-Champion',
      };
}

enum IqShape {
  circle,
  square,
  triangle,
  diamond,
  star,
  hexagon,
  plus,
  arrow,
  notch;

  /// Nur Formen mit erkennbarer Richtung dürfen sich drehen.
  bool get directional => this == IqShape.arrow || this == IqShape.notch;
}

enum IqTint { orange, cyan, violet, green, pink, gold }

/// Eine gezeichnete Figur: Form, Farbe, Anzahl, Drehung, Größe, gefüllt.
class IqFigure {
  const IqFigure(
    this.shape, {
    this.tint = IqTint.cyan,
    this.count = 1,
    this.turns = 0,
    this.size = 1,
    this.filled = true,
  });

  final IqShape shape;
  final IqTint tint;

  /// 1–6 gleiche Formen, angeordnet wie Würfelaugen.
  final int count;

  /// Drehung im Uhrzeigersinn in Achteldrehungen (45°).
  final int turns;

  /// 0 klein, 1 mittel, 2 groß.
  final int size;
  final bool filled;

  /// Sichtbare Identität: Drehung zählt nur bei Formen mit Richtung.
  String get key =>
      '${shape.name}/${tint.name}/$count/${shape.directional ? turns % 8 : 0}/$size/${filled ? 1 : 0}';

  IqFigure copyWith({
    IqShape? shape,
    IqTint? tint,
    int? count,
    int? turns,
    int? size,
    bool? filled,
  }) =>
      IqFigure(
        shape ?? this.shape,
        tint: tint ?? this.tint,
        count: count ?? this.count,
        turns: turns ?? this.turns,
        size: size ?? this.size,
        filled: filled ?? this.filled,
      );

  /// Für Rückblick und Protokoll in Worten.
  String describe() {
    final parts = <String>[
      '$count× ${_shapeNames[shape]}',
      _tintNames[tint]!,
      if (!filled) 'leer',
      if (size == 0) 'klein',
      if (size == 2) 'groß',
      if (shape.directional) '${(turns % 8) * 45}°',
    ];
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) => other is IqFigure && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => key;
}

const _shapeNames = <IqShape, String>{
  IqShape.circle: 'Kreis',
  IqShape.square: 'Quadrat',
  IqShape.triangle: 'Dreieck',
  IqShape.diamond: 'Raute',
  IqShape.star: 'Stern',
  IqShape.hexagon: 'Sechseck',
  IqShape.plus: 'Plus',
  IqShape.arrow: 'Pfeil',
  IqShape.notch: 'Kerbkreis',
};

const _tintNames = <IqTint, String>{
  IqTint.orange: 'orange',
  IqTint.cyan: 'türkis',
  IqTint.violet: 'lila',
  IqTint.green: 'grün',
  IqTint.pink: 'rosa',
  IqTint.gold: 'gelb',
};

/// Bauteil aus gleich großen Quadraten (Polyomino) für das Drehen im Kopf.
class IqPolyomino {
  IqPolyomino(Iterable<(int, int)> cells) : cells = _normalize(cells);

  /// Felder (x, y), verschoben auf 0 und sortiert.
  final List<(int, int)> cells;

  int get width => cells.fold(0, (m, c) => c.$1 + 1 > m ? c.$1 + 1 : m);
  int get height => cells.fold(0, (m, c) => c.$2 + 1 > m ? c.$2 + 1 : m);

  /// Vierteldrehung im Uhrzeigersinn (Bildschirmkoordinaten, y nach unten).
  IqPolyomino rotated(int quarterTurns) {
    var result = cells;
    for (var i = 0; i < quarterTurns % 4; i++) {
      result = [for (final c in result) (-c.$2, c.$1)];
    }
    return IqPolyomino(result);
  }

  /// Gespiegelt (umgeklappt) an der senkrechten Achse.
  IqPolyomino mirrored() => IqPolyomino([for (final c in cells) (-c.$1, c.$2)]);

  String get key => cells.map((c) => '${c.$1}:${c.$2}').join(',');

  /// Gleiches Bauteil, wenn eine Drehung (ohne Umklappen) übereinstimmt.
  bool sameAsRotationOf(IqPolyomino other) {
    for (var t = 0; t < 4; t++) {
      if (other.rotated(t).key == key) return true;
    }
    return false;
  }

  /// Händig: das Spiegelbild ist durch keine Drehung erreichbar.
  bool get chiral => !sameAsRotationOf(mirrored());

  static List<(int, int)> _normalize(Iterable<(int, int)> raw) {
    final list = raw.toList();
    if (list.isEmpty) return const [];
    final minX = list.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minY = list.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    final shifted = [for (final c in list) (c.$1 - minX, c.$2 - minY)]
      ..sort((a, b) => a.$2 != b.$2 ? a.$2 - b.$2 : a.$1 - b.$1);
    return List.unmodifiable(shifted);
  }

  @override
  bool operator ==(Object other) => other is IqPolyomino && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Ein Rätsel. Antworten sind immer eine Liste von Indizes: bei Auswahl-
/// rätseln die gewählte Option, beim Merk-Blitz die angetippten Felder.
sealed class IqPuzzle {
  const IqPuzzle({
    required this.id,
    required this.area,
    required this.level,
    required this.question,
    required this.explanation,
  });

  final String id;
  final IqArea area;

  /// Schwierigkeitsstufe 1–8.
  final int level;
  final String question;

  /// Die Regel in Kindersprache (für den Rückblick).
  final String explanation;

  bool isCorrect(List<int> response);

  String describeExpected();

  String describeResponse(List<int> response);
}

/// Gemeinsame Grundlage für Rätsel mit Antwortauswahl.
sealed class IqChoicePuzzle extends IqPuzzle {
  const IqChoicePuzzle({
    required super.id,
    required super.area,
    required super.level,
    required super.question,
    required super.explanation,
    required this.answer,
  });

  /// Index der richtigen Option.
  final int answer;

  int get optionCount;

  String describeOption(int index);

  @override
  bool isCorrect(List<int> response) =>
      response.length == 1 && response.first == answer;

  @override
  String describeExpected() => describeOption(answer);

  @override
  String describeResponse(List<int> response) =>
      response.length == 1 && response.first >= 0 && response.first < optionCount
          ? describeOption(response.first)
          : '–';
}

class IqMatrixPuzzle extends IqChoicePuzzle {
  const IqMatrixPuzzle({
    required super.id,
    required super.level,
    required super.question,
    required super.explanation,
    required super.answer,
    required this.columns,
    required this.cells,
    required this.options,
  }) : super(area: IqArea.matrix);

  final int columns;

  /// Zeilenweise; genau ein Feld ist `null` (das gesuchte).
  final List<IqFigure?> cells;
  final List<IqFigure> options;

  @override
  int get optionCount => options.length;

  @override
  String describeOption(int index) => options[index].describe();
}

class IqSeriesPuzzle extends IqChoicePuzzle {
  const IqSeriesPuzzle({
    required super.id,
    required super.level,
    required super.question,
    required super.explanation,
    required super.answer,
    required this.shown,
    required this.options,
  }) : super(area: IqArea.series);

  final List<IqFigure> shown;
  final List<IqFigure> options;

  @override
  int get optionCount => options.length;

  @override
  String describeOption(int index) => options[index].describe();
}

class IqOddOnePuzzle extends IqChoicePuzzle {
  const IqOddOnePuzzle({
    required super.id,
    required super.level,
    required super.question,
    required super.explanation,
    required super.answer,
    required this.figures,
  }) : super(area: IqArea.oddOneOut);

  final List<IqFigure> figures;

  @override
  int get optionCount => figures.length;

  @override
  String describeOption(int index) => figures[index].describe();
}

class IqRotationPuzzle extends IqChoicePuzzle {
  const IqRotationPuzzle({
    required super.id,
    required super.level,
    required super.question,
    required super.explanation,
    required super.answer,
    required this.target,
    required this.options,
    required this.tint,
  }) : super(area: IqArea.rotation);

  final IqPolyomino target;
  final List<IqPolyomino> options;
  final IqTint tint;

  @override
  int get optionCount => options.length;

  @override
  String describeOption(int index) {
    final option = options[index];
    if (option.sameAsRotationOf(target)) return 'Bauteil ${index + 1} (gedreht)';
    if (option.sameAsRotationOf(target.mirrored())) {
      return 'Bauteil ${index + 1} (umgeklappt)';
    }
    return 'Bauteil ${index + 1} (andere Form)';
  }
}

class IqNumberPuzzle extends IqChoicePuzzle {
  const IqNumberPuzzle({
    required super.id,
    required super.level,
    required super.question,
    required super.explanation,
    required super.answer,
    required this.numbers,
    required this.options,
  }) : super(area: IqArea.numbers);

  /// Genau ein Eintrag ist `null` (die gesuchte Zahl).
  final List<int?> numbers;
  final List<int> options;

  @override
  int get optionCount => options.length;

  @override
  String describeOption(int index) => '${options[index]}';
}

class IqMemoryPuzzle extends IqPuzzle {
  const IqMemoryPuzzle({
    required super.id,
    required super.level,
    required super.question,
    required super.explanation,
    required this.gridSize,
    required this.sequence,
    required this.showMs,
    required this.gapMs,
  }) : super(area: IqArea.memory);

  /// Felder pro Seite (3 → 3×3).
  final int gridSize;

  /// Reihenfolge der aufleuchtenden Felder (Index zeilenweise).
  final List<int> sequence;
  final int showMs;
  final int gapMs;

  @override
  bool isCorrect(List<int> response) {
    if (response.length != sequence.length) return false;
    for (var i = 0; i < sequence.length; i++) {
      if (response[i] != sequence[i]) return false;
    }
    return true;
  }

  @override
  String describeExpected() => sequence.map((i) => i + 1).join(' → ');

  @override
  String describeResponse(List<int> response) =>
      response.isEmpty ? '–' : response.map((i) => i + 1).join(' → ');
}

/// Ein beantwortetes Rätsel.
class IqItemRecord {
  const IqItemRecord({
    required this.puzzleId,
    required this.area,
    required this.level,
    required this.correct,
    required this.durationMs,
    required this.given,
    required this.expected,
  });

  final String puzzleId;
  final IqArea area;
  final int level;
  final bool correct;
  final int durationMs;
  final String given;
  final String expected;

  Map<String, Object> toJson() => {
        'puzzleId': puzzleId,
        'area': area.name,
        'level': level,
        'correct': correct,
        'durationMs': durationMs,
        'given': given,
        'expected': expected,
      };

  static IqItemRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final area = _areaNamed(raw['area']);
    final puzzleId = raw['puzzleId'];
    final level = raw['level'];
    final correct = raw['correct'];
    final durationMs = raw['durationMs'];
    if (area == null ||
        puzzleId is! String ||
        level is! int ||
        correct is! bool ||
        durationMs is! int) {
      return null;
    }
    return IqItemRecord(
      puzzleId: puzzleId,
      area: area,
      level: level.clamp(1, 8),
      correct: correct,
      durationMs: durationMs.clamp(0, 3600000),
      given: '${raw['given'] ?? ''}',
      expected: '${raw['expected'] ?? ''}',
    );
  }
}

/// Auswertung eines Bereichs.
class IqAreaScore {
  const IqAreaScore({
    required this.area,
    required this.solved,
    required this.total,
    required this.bestLevel,
    required this.startLevel,
  });

  final IqArea area;
  final int solved;
  final int total;

  /// Höchste richtig gelöste Stufe (0 = keine).
  final int bestLevel;
  final int startLevel;

  double get ratio => total <= 0 ? 0 : solved / total;
}

class IqTestResult {
  const IqTestResult({
    required this.id,
    required this.studentId,
    required this.grade,
    required this.version,
    required this.seed,
    required this.finishedAt,
    required this.durationMs,
    required this.items,
  });

  static const maxLevel = 8;

  final String id;
  final String studentId;
  final int grade;
  final String version;
  final int seed;
  final DateTime finishedAt;
  final int durationMs;
  final List<IqItemRecord> items;

  int get solved => items.where((i) => i.correct).length;
  int get total => items.length;

  /// Jedes gelöste Rätsel zählt so viele Punkte wie seine Stufe.
  int get thinkingPoints =>
      items.where((i) => i.correct).fold(0, (sum, i) => sum + i.level);

  List<IqAreaScore> get areaScores => [
        for (final area in IqArea.values)
          () {
            final subset = items.where((i) => i.area == area).toList();
            final solvedLevels =
                subset.where((i) => i.correct).map((i) => i.level);
            return IqAreaScore(
              area: area,
              solved: subset.where((i) => i.correct).length,
              total: subset.length,
              bestLevel: solvedLevels.isEmpty
                  ? 0
                  : solvedLevels.reduce((a, b) => a > b ? a : b),
              startLevel: subset.isEmpty ? 0 : subset.first.level,
            );
          }(),
      ];

  /// Stärkster Bereich: höchste Stufe, bei Gleichstand mehr gelöst.
  IqAreaScore get strongest => areaScores.reduce((a, b) {
        if (b.bestLevel != a.bestLevel) return b.bestLevel > a.bestLevel ? b : a;
        return b.solved > a.solved ? b : a;
      });

  /// Bereich mit dem meisten Übungspotenzial.
  IqAreaScore get practice => areaScores.reduce((a, b) {
        if (b.bestLevel != a.bestLevel) return b.bestLevel < a.bestLevel ? b : a;
        return b.solved < a.solved ? b : a;
      });

  Map<String, Object> toJson() => {
        'id': id,
        'studentId': studentId,
        'grade': grade,
        'version': version,
        'seed': seed,
        'finishedAt': finishedAt.toIso8601String(),
        'durationMs': durationMs,
        'items': [for (final item in items) item.toJson()],
      };

  static IqTestResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final studentId = raw['studentId'];
    final grade = raw['grade'];
    final version = raw['version'];
    final seed = raw['seed'];
    final finishedAt = DateTime.tryParse('${raw['finishedAt']}');
    final durationMs = raw['durationMs'];
    final items = raw['items'];
    if (id is! String ||
        studentId is! String ||
        grade is! int ||
        version is! String ||
        seed is! int ||
        finishedAt == null ||
        durationMs is! int ||
        items is! List) {
      return null;
    }
    final records = items
        .map(IqItemRecord.fromJson)
        .whereType<IqItemRecord>()
        .toList(growable: false);
    if (records.isEmpty) return null;
    return IqTestResult(
      id: id,
      studentId: studentId,
      grade: grade.clamp(1, 4),
      version: version,
      seed: seed,
      finishedAt: finishedAt,
      durationMs: durationMs.clamp(0, 86400000),
      items: records,
    );
  }
}

IqArea? _areaNamed(Object? name) {
  for (final area in IqArea.values) {
    if (area.name == name) return area;
  }
  return null;
}
