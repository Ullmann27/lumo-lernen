import 'dart:math' as math;

import 'writing_path_geometry.dart';

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

  WritingEvaluation evaluate({required WritingTemplate template, required WritingAttempt attempt}) {
    final expected = template.strokes
        .map((stroke) => WritingPathGeometry.resample(WritingPathGeometry.sample(stroke.pathData)))
        .toList();
    final actual = attempt.strokes.where((stroke) => stroke.points.length >= 2)
        .map((stroke) => WritingPathGeometry.resample(stroke.points
            .map((point) => math.Point<double>(point.x, point.y)).toList()))
        .toList();
    if (expected.isEmpty || expected.any((path) => path.isEmpty)) {
      return _ungraded;
    }
    if (actual.isEmpty) return _empty;

    // Trace tolerance is 8% of the normalized 100x100 writing area.
    // Both directions are measured: covering the template alone is not enough
    // if most of the child's ink is unrelated scribbling elsewhere.
    const tolerance = 8.0;
    var coverage = 0.0;
    var precision = 0.0;
    var direction = 0.0;
    var start = 0.0;
    var reflectedCoverage = 0.0;
    for (var i = 0; i < expected.length; i++) {
      if (i >= actual.length) continue;
      final reference = expected[i];
      final drawn = actual[i];
      coverage += _fractionNear(reference, drawn, tolerance);
      precision += _fractionNear(drawn, reference, tolerance);
      final pairedDistance = List.generate(reference.length,
        (j) => reference[j].distanceTo(drawn[j])).reduce((a, b) => a + b) / reference.length;
      direction += (1 - pairedDistance / 24).clamp(0.0, 1.0);
      start += (1 - reference.first.distanceTo(drawn.first) / 20).clamp(0.0, 1.0);
      reflectedCoverage += _fractionNear(reference.map((p) =>
        math.Point<double>(template.viewBoxWidth - p.x, p.y)).toList(), drawn, tolerance);
    }
    coverage /= expected.length;
    precision /= expected.length;
    direction /= expected.length;
    start /= expected.length;
    reflectedCoverage /= expected.length;
    final order = (math.min(expected.length, actual.length) /
        math.max(expected.length, actual.length)).toDouble();
    final mirrored = coverage < .60 && reflectedCoverage > .82;
    final incomplete = coverage < .80 || precision < .75 || direction < .60 || actual.length < expected.length;
    final score = ((coverage * .45 + precision * .35 + direction * .15 + start * .05) *
        math.min(coverage, precision) * order).clamp(0.0, 1.0).toDouble();
    final hints = <WritingHint>[];
    if (mirrored) {
      hints.add(const WritingHint(type: WritingHintType.mirrored, message: 'Die Spur ist gespiegelt. Schau noch einmal auf die Vorlage.'));
    } else if (coverage < .80) {
      hints.add(const WritingHint(type: WritingHintType.coverage, message: 'Fahre die ganze Vorlage nach. Ein Teil der Spur fehlt noch.'));
    } else if (precision < .75) {
      hints.add(const WritingHint(type: WritingHintType.linePosition, message: 'Bleib mit deinen Strichen näher an der gezeichneten Spur.'));
    } else if (direction < .60) {
      hints.add(const WritingHint(type: WritingHintType.direction, message: 'Starte beim markierten Punkt und folge der Strichrichtung.'));
    } else if (order < .8) {
      hints.add(const WritingHint(type: WritingHintType.strokeOrder, message: 'Fahre jeden nummerierten Strich einmal nach.'));
    } else {
      hints.add(const WritingHint(type: WritingHintType.coverage, message: 'Du bist nah an der Vorlage.'));
    }
    return WritingEvaluation(
      overallScore: score, startPointScore: start, directionScore: direction,
      coverageScore: coverage, pathDistanceScore: precision, strokeOrderScore: order,
      mirrored: mirrored, incomplete: incomplete, hints: hints,
    );
  }

  double _fractionNear(List<math.Point<double>> source, List<math.Point<double>> target, double tolerance) {
    if (source.isEmpty || target.isEmpty) return 0;
    return source.where((point) => target.any((other) => point.distanceTo(other) <= tolerance)).length / source.length;
  }

  static const _ungraded = WritingEvaluation(
    overallScore: 0, startPointScore: 0, directionScore: 0, coverageScore: 0,
    pathDistanceScore: 0, strokeOrderScore: 0, mirrored: false, incomplete: true,
    hints: [WritingHint(type: WritingHintType.coverage,
      message: 'Freie Schreibübung ohne automatische Bewertung. Bitte gemeinsam mit einer erwachsenen Person ansehen.')],
  );
  static const _empty = WritingEvaluation(
    overallScore: 0, startPointScore: 0, directionScore: 0, coverageScore: 0,
    pathDistanceScore: 0, strokeOrderScore: 0, mirrored: false, incomplete: true,
    hints: [WritingHint(type: WritingHintType.incomplete, message: 'Fahre die markierte Spur einmal nach.')],
  );
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
