import 'dart:math' as math;

enum WritingMode {
  trace,
  guided,
  free,
}

enum WritingHintType {
  startPoint,
  direction,
  coverage,
  linePosition,
  strokeOrder,
  mirrored,
  incomplete,
}

class StrokePoint {
  const StrokePoint({
    required this.x,
    required this.y,
    required this.timestampMs,
    this.pressure = 1,
  });

  final double x;
  final double y;
  final int timestampMs;
  final double pressure;
}

class Stroke {
  const Stroke({
    required this.id,
    required this.points,
  });

  final String id;
  final List<StrokePoint> points;

  bool get isEmpty => points.isEmpty;
  StrokePoint? get start => points.isEmpty ? null : points.first;
  StrokePoint? get end => points.isEmpty ? null : points.last;
}

class WritingTemplateStroke {
  const WritingTemplateStroke({
    required this.order,
    required this.pathData,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.directionLabel,
  });

  final int order;
  final String pathData;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final String? directionLabel;
}

class WritingTemplate {
  const WritingTemplate({
    required this.symbol,
    required this.grade,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.strokes,
  });

  final String symbol;
  final int grade;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final List<WritingTemplateStroke> strokes;
}

class WritingAttempt {
  const WritingAttempt({
    required this.taskInstanceId,
    required this.childId,
    required this.targetSymbol,
    required this.mode,
    required this.strokes,
    required this.startedAt,
    required this.finishedAt,
  });

  final String taskInstanceId;
  final String childId;
  final String targetSymbol;
  final WritingMode mode;
  final List<Stroke> strokes;
  final DateTime startedAt;
  final DateTime finishedAt;
}

class WritingHint {
  const WritingHint({
    required this.type,
    required this.message,
  });

  final WritingHintType type;
  final String message;
}

class WritingEvaluation {
  const WritingEvaluation({
    required this.overallScore,
    required this.startPointScore,
    required this.directionScore,
    required this.coverageScore,
    required this.pathDistanceScore,
    required this.strokeOrderScore,
    required this.mirrored,
    required this.incomplete,
    required this.hints,
  });

  final double overallScore;
  final double startPointScore;
  final double directionScore;
  final double coverageScore;
  final double pathDistanceScore;
  final double strokeOrderScore;
  final bool mirrored;
  final bool incomplete;
  final List<WritingHint> hints;
}

class StrokeSmoother {
  const StrokeSmoother();

  Stroke smooth(Stroke stroke) {
    if (stroke.points.length < 3) return stroke;
    final smoothed = <StrokePoint>[stroke.points.first];
    for (var i = 1; i < stroke.points.length - 1; i++) {
      final prev = stroke.points[i - 1];
      final current = stroke.points[i];
      final next = stroke.points[i + 1];
      smoothed.add(StrokePoint(
        x: (prev.x + current.x + next.x) / 3,
        y: (prev.y + current.y + next.y) / 3,
        timestampMs: current.timestampMs,
        pressure: current.pressure,
      ));
    }
    smoothed.add(stroke.points.last);
    return Stroke(id: stroke.id, points: smoothed);
  }
}

class WritingEvaluator {
  const WritingEvaluator();

  WritingEvaluation evaluate({
    required WritingTemplate template,
    required WritingAttempt attempt,
  }) {
    if (attempt.strokes.isEmpty || attempt.strokes.every((stroke) => stroke.points.isEmpty)) {
      return const WritingEvaluation(
        overallScore: 0,
        startPointScore: 0,
        directionScore: 0,
        coverageScore: 0,
        pathDistanceScore: 0,
        strokeOrderScore: 0,
        mirrored: false,
        incomplete: true,
        hints: <WritingHint>[
          WritingHint(type: WritingHintType.incomplete, message: 'Versuche die Spur einmal nachzufahren.'),
        ],
      );
    }

    final startScore = _startPointScore(template, attempt);
    final directionScore = _directionScore(template, attempt);
    final coverageScore = _coverageScore(template, attempt);
    final pathDistanceScore = _pathDistanceScore(template, attempt);
    final strokeOrderScore = _strokeOrderScore(template, attempt);
    final mirrored = _looksMirrored(template, attempt);
    final incomplete = coverageScore < 0.55;

    final mirrorPenalty = mirrored ? 0.20 : 0.0;
    final overall = (startScore * 0.18 +
            directionScore * 0.20 +
            coverageScore * 0.24 +
            pathDistanceScore * 0.23 +
            strokeOrderScore * 0.15 -
            mirrorPenalty)
        .clamp(0.0, 1.0);

    return WritingEvaluation(
      overallScore: overall,
      startPointScore: startScore,
      directionScore: directionScore,
      coverageScore: coverageScore,
      pathDistanceScore: pathDistanceScore,
      strokeOrderScore: strokeOrderScore,
      mirrored: mirrored,
      incomplete: incomplete,
      hints: _hints(
        startScore: startScore,
        directionScore: directionScore,
        coverageScore: coverageScore,
        pathDistanceScore: pathDistanceScore,
        strokeOrderScore: strokeOrderScore,
        mirrored: mirrored,
        incomplete: incomplete,
      ),
    );
  }

  double _startPointScore(WritingTemplate template, WritingAttempt attempt) {
    final expected = template.strokes.isEmpty ? null : template.strokes.first;
    final actual = attempt.strokes.first.start;
    if (expected == null || actual == null) return 0;
    final distance = _distance(actual.x, actual.y, expected.startX, expected.startY);
    return (1 - distance / 50).clamp(0.0, 1.0);
  }

  double _directionScore(WritingTemplate template, WritingAttempt attempt) {
    final count = math.min(template.strokes.length, attempt.strokes.length);
    if (count == 0) return 0;
    var sum = 0.0;
    for (var i = 0; i < count; i++) {
      final expected = template.strokes[i];
      final actual = attempt.strokes[i];
      final start = actual.start;
      final end = actual.end;
      if (start == null || end == null) continue;
      final expectedDx = expected.endX - expected.startX;
      final expectedDy = expected.endY - expected.startY;
      final actualDx = end.x - start.x;
      final actualDy = end.y - start.y;
      sum += _cosineSimilarity(expectedDx, expectedDy, actualDx, actualDy).clamp(0.0, 1.0);
    }
    return (sum / count).clamp(0.0, 1.0);
  }

  double _coverageScore(WritingTemplate template, WritingAttempt attempt) {
    final expected = template.strokes.length;
    if (expected == 0) return 0;
    final nonEmpty = attempt.strokes.where((stroke) => stroke.points.length >= 2).length;
    return (nonEmpty / expected).clamp(0.0, 1.0);
  }

  double _pathDistanceScore(WritingTemplate template, WritingAttempt attempt) {
    final expectedCount = template.strokes.length;
    if (expectedCount == 0) return 0;
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i < math.min(expectedCount, attempt.strokes.length); i++) {
      final expected = template.strokes[i];
      final actual = attempt.strokes[i];
      final start = actual.start;
      final end = actual.end;
      if (start == null || end == null) continue;
      final startDistance = _distance(start.x, start.y, expected.startX, expected.startY);
      final endDistance = _distance(end.x, end.y, expected.endX, expected.endY);
      final avg = (startDistance + endDistance) / 2;
      sum += (1 - avg / 60).clamp(0.0, 1.0);
      count++;
    }
    if (count == 0) return 0;
    return (sum / count).clamp(0.0, 1.0);
  }

  double _strokeOrderScore(WritingTemplate template, WritingAttempt attempt) {
    if (template.strokes.length <= 1) return 1;
    if (attempt.strokes.length < template.strokes.length) {
      return (attempt.strokes.length / template.strokes.length).clamp(0.0, 1.0);
    }
    return 1;
  }

  bool _looksMirrored(WritingTemplate template, WritingAttempt attempt) {
    if (template.strokes.isEmpty || attempt.strokes.isEmpty) return false;
    final expected = template.strokes.first;
    final actual = attempt.strokes.first;
    final start = actual.start;
    final end = actual.end;
    if (start == null || end == null) return false;
    final expectedDx = expected.endX - expected.startX;
    final actualDx = end.x - start.x;
    return expectedDx.sign != 0 && actualDx.sign != 0 && expectedDx.sign != actualDx.sign;
  }

  List<WritingHint> _hints({
    required double startScore,
    required double directionScore,
    required double coverageScore,
    required double pathDistanceScore,
    required double strokeOrderScore,
    required bool mirrored,
    required bool incomplete,
  }) {
    final hints = <WritingHint>[];
    if (startScore < 0.55) {
      hints.add(const WritingHint(type: WritingHintType.startPoint, message: 'Starte naeher am Anfangspunkt.'));
    }
    if (directionScore < 0.55) {
      hints.add(const WritingHint(type: WritingHintType.direction, message: 'Achte auf die Richtung des Strichs.'));
    }
    if (coverageScore < 0.65 || incomplete) {
      hints.add(const WritingHint(type: WritingHintType.incomplete, message: 'Fahre die ganze Form bis zum Ende nach.'));
    }
    if (pathDistanceScore < 0.55) {
      hints.add(const WritingHint(type: WritingHintType.linePosition, message: 'Bleib noch etwas naeher auf der Spur.'));
    }
    if (strokeOrderScore < 0.75) {
      hints.add(const WritingHint(type: WritingHintType.strokeOrder, message: 'Versuche die Striche in der richtigen Reihenfolge.'));
    }
    if (mirrored) {
      hints.add(const WritingHint(type: WritingHintType.mirrored, message: 'Das sieht gespiegelt aus. Schau auf die Richtung.'));
    }
    if (hints.isEmpty) {
      hints.add(const WritingHint(type: WritingHintType.coverage, message: 'Sehr gut. Du bist nah an der Vorlage.'));
    }
    return hints;
  }

  double _distance(double ax, double ay, double bx, double by) {
    final dx = ax - bx;
    final dy = ay - by;
    return math.sqrt(dx * dx + dy * dy);
  }

  double _cosineSimilarity(double ax, double ay, double bx, double by) {
    final dot = ax * bx + ay * by;
    final magA = math.sqrt(ax * ax + ay * ay);
    final magB = math.sqrt(bx * bx + by * by);
    if (magA == 0 || magB == 0) return 0;
    return dot / (magA * magB);
  }
}

class WritingTemplateRepository {
  const WritingTemplateRepository();

  WritingTemplate? find(String symbol, {int grade = 1}) {
    return _templates[symbol];
  }

  static const Map<String, WritingTemplate> _templates = <String, WritingTemplate>{
    'A': WritingTemplate(
      symbol: 'A',
      grade: 1,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: <WritingTemplateStroke>[
        WritingTemplateStroke(order: 1, pathData: 'M20 90 L50 10', startX: 20, startY: 90, endX: 50, endY: 10, directionLabel: 'up-right'),
        WritingTemplateStroke(order: 2, pathData: 'M50 10 L80 90', startX: 50, startY: 10, endX: 80, endY: 90, directionLabel: 'down-right'),
        WritingTemplateStroke(order: 3, pathData: 'M35 55 L65 55', startX: 35, startY: 55, endX: 65, endY: 55, directionLabel: 'right'),
      ],
    ),
    'M': WritingTemplate(
      symbol: 'M',
      grade: 1,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: <WritingTemplateStroke>[
        WritingTemplateStroke(order: 1, pathData: 'M18 90 L18 15', startX: 18, startY: 90, endX: 18, endY: 15, directionLabel: 'up'),
        WritingTemplateStroke(order: 2, pathData: 'M18 15 L50 55', startX: 18, startY: 15, endX: 50, endY: 55, directionLabel: 'down-right'),
        WritingTemplateStroke(order: 3, pathData: 'M50 55 L82 15', startX: 50, startY: 55, endX: 82, endY: 15, directionLabel: 'up-right'),
        WritingTemplateStroke(order: 4, pathData: 'M82 15 L82 90', startX: 82, startY: 15, endX: 82, endY: 90, directionLabel: 'down'),
      ],
    ),
    '0': WritingTemplate(
      symbol: '0',
      grade: 1,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: <WritingTemplateStroke>[
        WritingTemplateStroke(order: 1, pathData: 'M50 12 C25 12 20 35 20 50 C20 75 35 90 50 90 C75 90 80 65 80 50 C80 25 65 12 50 12', startX: 50, startY: 12, endX: 50, endY: 12, directionLabel: 'round'),
      ],
    ),
    '1': WritingTemplate(
      symbol: '1',
      grade: 1,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: <WritingTemplateStroke>[
        WritingTemplateStroke(order: 1, pathData: 'M50 18 L50 90', startX: 50, startY: 18, endX: 50, endY: 90, directionLabel: 'down'),
      ],
    ),
    '5': WritingTemplate(
      symbol: '5',
      grade: 1,
      viewBoxWidth: 100,
      viewBoxHeight: 100,
      strokes: <WritingTemplateStroke>[
        WritingTemplateStroke(order: 1, pathData: 'M75 18 L32 18', startX: 75, startY: 18, endX: 32, endY: 18, directionLabel: 'left'),
        WritingTemplateStroke(order: 2, pathData: 'M32 18 L28 48', startX: 32, startY: 18, endX: 28, endY: 48, directionLabel: 'down'),
        WritingTemplateStroke(order: 3, pathData: 'M28 48 C72 42 82 90 40 88', startX: 28, startY: 48, endX: 40, endY: 88, directionLabel: 'curve'),
      ],
    ),
  };
}
