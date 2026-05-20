// Tests fuer LetterShapeAnalyzer.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/writing/logic/letter_shape_analyzer.dart';
import 'package:lumo_lernen/features/writing/models/coach_writing_models.dart';

CoachStroke _lineStroke({
  required String id,
  required double x1,
  required double y1,
  required double x2,
  required double y2,
  int steps = 14,
}) {
  final pts = <CoachStrokePoint>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    pts.add(CoachStrokePoint(
      x: x1 + (x2 - x1) * t,
      y: y1 + (y2 - y1) * t,
      timestampMs: i * 10,
    ));
  }
  return CoachStroke(
    id: id,
    points: pts,
    startedAtMs: 0,
    endedAtMs: steps * 10,
  );
}

CoachStroke _circleStroke({
  required String id,
  required double cx,
  required double cy,
  required double r,
  int steps = 32,
}) {
  final pts = <CoachStrokePoint>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final ang = t * math.pi * 2;
    pts.add(CoachStrokePoint(
      x: cx + r * math.cos(ang),
      y: cy + r * math.sin(ang),
      timestampMs: i * 10,
    ));
  }
  return CoachStroke(
    id: id,
    points: pts,
    startedAtMs: 0,
    endedAtMs: steps * 10,
  );
}

void main() {
  const analyzer = LetterShapeAnalyzer();

  group('LetterShapeAnalyzer - allgemein', () {
    test('Leere Strokes -> unclear, nicht korrekt', () {
      final r =
          analyzer.analyze(expectedLetter: 'I', strokes: const []);
      expect(r.isCorrect, isFalse);
      expect(r.issues, contains(CoachLetterIssue.unclear));
      expect(r.showDemo, isTrue);
    });
  });

  group('LetterShapeAnalyzer - I', () {
    test('Vertikale Linie wird als I akzeptiert', () {
      final stroke = _lineStroke(
        id: 'a',
        x1: 100,
        y1: 50,
        x2: 102,
        y2: 200,
      );
      final r = analyzer.analyze(expectedLetter: 'I', strokes: [stroke]);
      expect(r.isCorrect, isTrue);
      expect(r.recognizedLetter, 'I');
      expect(r.messageKey, 'correct');
    });

    test('Sehr kleine Strokes -> tooSmall', () {
      final stroke = _lineStroke(
        id: 'a',
        x1: 100,
        y1: 100,
        x2: 101,
        y2: 110,
      );
      final r = analyzer.analyze(expectedLetter: 'I', strokes: [stroke]);
      expect(r.isCorrect, isFalse);
      expect(r.issues, contains(CoachLetterIssue.tooSmall));
    });

    test('Eine horizontale Linie ist KEIN I', () {
      final stroke = _lineStroke(
        id: 'a',
        x1: 30,
        y1: 100,
        x2: 200,
        y2: 102,
      );
      final r = analyzer.analyze(expectedLetter: 'I', strokes: [stroke]);
      expect(r.isCorrect, isFalse);
    });
  });

  group('LetterShapeAnalyzer - H', () {
    test('Zwei Vertikale ohne Querstrich -> missingCrossbar', () {
      final left = _lineStroke(
        id: 'l',
        x1: 50,
        y1: 20,
        x2: 50,
        y2: 180,
      );
      final right = _lineStroke(
        id: 'r',
        x1: 150,
        y1: 20,
        x2: 150,
        y2: 180,
      );
      final r = analyzer.analyze(
          expectedLetter: 'H', strokes: [left, right]);
      expect(r.isCorrect, isFalse);
      expect(r.issues, contains(CoachLetterIssue.missingCrossbar));
      expect(r.messageKey, 'missingCrossbar');
    });

    test('Zwei Vertikale + Querstrich -> korrekt', () {
      final left = _lineStroke(
        id: 'l',
        x1: 50,
        y1: 20,
        x2: 50,
        y2: 180,
      );
      final right = _lineStroke(
        id: 'r',
        x1: 150,
        y1: 20,
        x2: 150,
        y2: 180,
      );
      final bar = _lineStroke(
        id: 'b',
        x1: 50,
        y1: 100,
        x2: 150,
        y2: 100,
      );
      final r = analyzer.analyze(
          expectedLetter: 'H', strokes: [left, right, bar]);
      expect(r.isCorrect, isTrue);
      expect(r.recognizedLetter, 'H');
    });
  });

  group('LetterShapeAnalyzer - L', () {
    test('Vertikal + horizontal (zwei Strokes) -> korrekt', () {
      final vert = _lineStroke(
        id: 'v',
        x1: 50,
        y1: 20,
        x2: 50,
        y2: 180,
      );
      final horiz = _lineStroke(
        id: 'h',
        x1: 50,
        y1: 180,
        x2: 160,
        y2: 180,
      );
      final r = analyzer.analyze(
          expectedLetter: 'L', strokes: [vert, horiz]);
      expect(r.isCorrect, isTrue);
    });

    test('Nur vertikal ohne unteren Fuss -> missingStroke', () {
      final vert = _lineStroke(
        id: 'v',
        x1: 50,
        y1: 20,
        x2: 50,
        y2: 180,
      );
      final r = analyzer.analyze(expectedLetter: 'L', strokes: [vert]);
      expect(r.isCorrect, isFalse);
      expect(r.issues, contains(CoachLetterIssue.missingStroke));
    });
  });

  group('LetterShapeAnalyzer - O', () {
    test('Geschlossener Kreis -> korrekt', () {
      final stroke = _circleStroke(
        id: 'o',
        cx: 100,
        cy: 100,
        r: 50,
      );
      final r = analyzer.analyze(expectedLetter: 'O', strokes: [stroke]);
      expect(r.isCorrect, isTrue);
      expect(r.recognizedLetter, 'O');
    });

    test('Halboffener Bogen -> notClosed', () {
      // Halbkreis (von 0 bis pi)
      final pts = <CoachStrokePoint>[];
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final ang = t * math.pi; // nur halber Kreis
        pts.add(CoachStrokePoint(
          x: 100 + 60 * math.cos(ang),
          y: 100 + 60 * math.sin(ang),
          timestampMs: i * 10,
        ));
      }
      final stroke = CoachStroke(
        id: 'open',
        points: pts,
        startedAtMs: 0,
        endedAtMs: 240,
      );
      final r = analyzer.analyze(expectedLetter: 'O', strokes: [stroke]);
      expect(r.isCorrect, isFalse);
      expect(r.issues, contains(CoachLetterIssue.notClosed));
    });
  });
}
