// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - LETTER SHAPE ANALYZER
// ════════════════════════════════════════════════════════════════════════
//
// Regelbasierte, tolerante Analyse von Buchstaben-Versuchen.
// Keine ML, keine Cloud, deterministisch.
//
// Idee: Wir verwenden die Bounding-Box ALLER Strokes, normieren die
// Strokes auf 0..1 und prüfen einfache geometrische Eigenschaften.
//
// Tolerant: lieber "fast richtig" als "falsch".
// Phase 2: nur I, L, O, H.

import 'dart:math' as math;

import '../models/coach_writing_models.dart';

class LetterShapeAnalyzer {
  const LetterShapeAnalyzer();

  /// Analysiert die uebergebenen Strokes gegen den erwarteten Buchstaben.
  /// Liefert nie null - wenn keine Strokes vorhanden sind, kommt ein
  /// "unclear"-Resultat zurueck.
  CoachLetterAnalysisResult analyze({
    required String expectedLetter,
    required List<CoachStroke> strokes,
  }) {
    final letter = expectedLetter.toUpperCase();
    if (strokes.isEmpty) {
      return CoachLetterAnalysisResult(
        expectedLetter: letter,
        recognizedLetter: '?',
        isCorrect: false,
        confidence: 0,
        shapeScore: 0,
        lineScore: 0,
        sizeScore: 0,
        issues: const [CoachLetterIssue.unclear],
        showDemo: true,
        messageKey: 'unclear',
      );
    }

    final summary = _summarize(strokes);
    if (summary == null) {
      // Punkte aber kein nutzbarer Strich (alle auf gleichem Punkt).
      return CoachLetterAnalysisResult(
        expectedLetter: letter,
        recognizedLetter: '?',
        isCorrect: false,
        confidence: 0,
        shapeScore: 0,
        lineScore: 0,
        sizeScore: 0,
        issues: const [CoachLetterIssue.unclear, CoachLetterIssue.tooSmall],
        showDemo: true,
        messageKey: 'tooSmall',
      );
    }

    switch (letter) {
      case 'I':
        return _analyzeI(letter, strokes, summary);
      case 'L':
        return _analyzeL(letter, strokes, summary);
      case 'O':
        return _analyzeO(letter, strokes, summary);
      case 'H':
        return _analyzeH(letter, strokes, summary);
    }
    // Nicht unterstuetzter Buchstabe -> default "unclear"
    return CoachLetterAnalysisResult(
      expectedLetter: letter,
      recognizedLetter: '?',
      isCorrect: false,
      confidence: 0,
      shapeScore: 0,
      lineScore: 0,
      sizeScore: 0,
      issues: const [CoachLetterIssue.unclear],
      showDemo: true,
      messageKey: 'unclear',
    );
  }

  // ─── I: ein vertikaler Strich von oben nach unten ────────────────────
  CoachLetterAnalysisResult _analyzeI(
    String letter,
    List<CoachStroke> strokes,
    _StrokeSummary s,
  ) {
    // I sollte: 1-2 Strokes (Toleranz fuer Doppelstriche), hoehe > breite.
    final tallEnough = s.height >= s.width * 1.4 || s.width < 12;
    final sizeOk = s.height >= 30;
    final issues = <CoachLetterIssue>[];

    if (!sizeOk) issues.add(CoachLetterIssue.tooSmall);
    if (!tallEnough) issues.add(CoachLetterIssue.wrongLetter);

    final correct = tallEnough && sizeOk;
    final shape = tallEnough ? 0.9 : 0.3;
    final line = _lineScore(s);
    return CoachLetterAnalysisResult(
      expectedLetter: letter,
      recognizedLetter: correct ? 'I' : '?',
      isCorrect: correct,
      confidence: correct ? 0.85 : 0.4,
      shapeScore: shape,
      lineScore: line,
      sizeScore: sizeOk ? 1.0 : 0.4,
      issues: issues,
      showDemo: !correct,
      messageKey: correct
          ? 'correct'
          : (issues.contains(CoachLetterIssue.tooSmall)
              ? 'tooSmall'
              : 'wrongLetter'),
    );
  }

  // ─── L: vertikal + horizontal (entweder 1 Stroke mit Knick oder 2) ───
  CoachLetterAnalysisResult _analyzeL(
    String letter,
    List<CoachStroke> strokes,
    _StrokeSummary s,
  ) {
    // L: Bounding-Box-Hoehe > Breite, untere rechte Region muss befuellt
    // sein (horizontaler Anteil unten).
    final tallEnough = s.height >= s.width * 0.9;
    final sizeOk = s.height >= 30 && s.width >= 12;

    // Pruefe ob untere rechte Region befuellt ist (relative Koordinaten)
    var bottomRightPoints = 0;
    var topLeftPoints = 0;
    var totalPoints = 0;
    for (final stroke in strokes) {
      for (final p in stroke.points) {
        totalPoints++;
        final relX = (p.x - s.minX) / (s.width == 0 ? 1 : s.width);
        final relY = (p.y - s.minY) / (s.height == 0 ? 1 : s.height);
        if (relY > 0.7 && relX > 0.35) bottomRightPoints++;
        if (relY < 0.4 && relX < 0.45) topLeftPoints++;
      }
    }
    final hasBottomRight = totalPoints == 0
        ? false
        : bottomRightPoints / totalPoints > 0.08;
    final hasTopLeft = totalPoints == 0
        ? false
        : topLeftPoints / totalPoints > 0.08;

    final issues = <CoachLetterIssue>[];
    if (!sizeOk) issues.add(CoachLetterIssue.tooSmall);
    if (!hasBottomRight) issues.add(CoachLetterIssue.missingStroke);
    if (!hasTopLeft) issues.add(CoachLetterIssue.missingStroke);

    final correct = tallEnough && sizeOk && hasBottomRight && hasTopLeft;
    return CoachLetterAnalysisResult(
      expectedLetter: letter,
      recognizedLetter: correct ? 'L' : '?',
      isCorrect: correct,
      confidence: correct ? 0.8 : 0.4,
      shapeScore: correct ? 0.85 : 0.4,
      lineScore: _lineScore(s),
      sizeScore: sizeOk ? 1.0 : 0.4,
      issues: issues,
      showDemo: !correct,
      messageKey: correct
          ? 'correct'
          : (issues.contains(CoachLetterIssue.missingStroke)
              ? 'missingStroke'
              : (issues.contains(CoachLetterIssue.tooSmall)
                  ? 'tooSmall'
                  : 'wrongLetter')),
    );
  }

  // ─── O: geschlossener oder fast geschlossener Kreis ──────────────────
  CoachLetterAnalysisResult _analyzeO(
    String letter,
    List<CoachStroke> strokes,
    _StrokeSummary s,
  ) {
    // Aspect ratio nahe 1:1
    final aspect = s.width == 0 ? 0.0 : s.height / s.width;
    final aspectOk = aspect > 0.6 && aspect < 1.8;
    final sizeOk = s.height >= 30 && s.width >= 30;

    // Ist der Stroke geschlossen? Start- und End-Punkt nahe beieinander.
    var closed = false;
    if (strokes.length == 1) {
      final stroke = strokes.first;
      if (stroke.points.length >= 4) {
        final start = stroke.points.first;
        final end = stroke.points.last;
        final dx = end.x - start.x;
        final dy = end.y - start.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        final ref = math.min(s.width, s.height);
        if (ref > 0 && dist < ref * 0.45) closed = true;
      }
    } else if (strokes.length >= 2) {
      // Zwei Strokes koennen auch ein O ergeben (linke/rechte Haelfte).
      closed = true;
    }

    final issues = <CoachLetterIssue>[];
    if (!sizeOk) issues.add(CoachLetterIssue.tooSmall);
    if (!aspectOk) issues.add(CoachLetterIssue.wrongLetter);
    if (!closed) issues.add(CoachLetterIssue.notClosed);

    final correct = aspectOk && sizeOk && closed;
    return CoachLetterAnalysisResult(
      expectedLetter: letter,
      recognizedLetter: correct ? 'O' : '?',
      isCorrect: correct,
      confidence: correct ? 0.8 : 0.4,
      shapeScore: correct ? 0.85 : 0.45,
      lineScore: _lineScore(s),
      sizeScore: sizeOk ? 1.0 : 0.4,
      issues: issues,
      showDemo: !correct,
      messageKey: correct
          ? 'correct'
          : (issues.contains(CoachLetterIssue.notClosed)
              ? 'notClosed'
              : (issues.contains(CoachLetterIssue.tooSmall)
                  ? 'tooSmall'
                  : 'wrongLetter')),
    );
  }

  // ─── H: zwei Vertikale + Querstrich ──────────────────────────────────
  CoachLetterAnalysisResult _analyzeH(
    String letter,
    List<CoachStroke> strokes,
    _StrokeSummary s,
  ) {
    final tallEnough = s.height >= s.width * 0.7;
    final sizeOk = s.height >= 30 && s.width >= 25;

    // Pruefe Querstrich-Anteil: Strokes deren Breite > 2x Hoehe und die
    // grob in der mittleren Hoehe liegen.
    var hasCrossbar = false;
    var verticalStrokes = 0;
    for (final stroke in strokes) {
      final sb = stroke.bounds;
      final strokeW = sb.maxX - sb.minX;
      final strokeH = sb.maxY - sb.minY;
      if (strokeW > strokeH * 1.6 && strokeW > s.width * 0.35) {
        // Querstrich-Kandidat - liegt er in der Mitte?
        final midY = (sb.minY + sb.maxY) / 2;
        final relY = (midY - s.minY) / (s.height == 0 ? 1 : s.height);
        if (relY > 0.25 && relY < 0.75) {
          hasCrossbar = true;
        }
      }
      if (strokeH > strokeW * 1.4 && strokeH > s.height * 0.5) {
        verticalStrokes++;
      }
    }

    final issues = <CoachLetterIssue>[];
    if (!sizeOk) issues.add(CoachLetterIssue.tooSmall);
    if (!tallEnough) issues.add(CoachLetterIssue.wrongLetter);
    if (verticalStrokes < 2) issues.add(CoachLetterIssue.missingStroke);
    if (!hasCrossbar) issues.add(CoachLetterIssue.missingCrossbar);

    final correct = tallEnough && sizeOk && verticalStrokes >= 2 && hasCrossbar;
    return CoachLetterAnalysisResult(
      expectedLetter: letter,
      recognizedLetter: correct ? 'H' : '?',
      isCorrect: correct,
      confidence: correct ? 0.75 : 0.4,
      shapeScore: correct ? 0.85 : 0.5,
      lineScore: _lineScore(s),
      sizeScore: sizeOk ? 1.0 : 0.4,
      issues: issues,
      showDemo: !correct,
      messageKey: correct
          ? 'correct'
          : (issues.contains(CoachLetterIssue.missingCrossbar)
              ? 'missingCrossbar'
              : (issues.contains(CoachLetterIssue.missingStroke)
                  ? 'missingStroke'
                  : (issues.contains(CoachLetterIssue.tooSmall)
                      ? 'tooSmall'
                      : 'wrongLetter'))),
    );
  }

  /// Score wie gut der Versuch zur Schreiblinie passt (Phase 1+2: simple
  /// Naeherung -- immer 1.0 wenn Strokes vorhanden, weil wir die Linie
  /// noch nicht aus Pixel-Koordinaten kennen). Reserviert fuer Phase 6.
  double _lineScore(_StrokeSummary s) => 1.0;

  /// Bounding-Box ueber alle Strokes.
  _StrokeSummary? _summarize(List<CoachStroke> strokes) {
    var hasPoint = false;
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final stroke in strokes) {
      for (final p in stroke.points) {
        hasPoint = true;
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }
    if (!hasPoint) return null;
    final width = maxX - minX;
    final height = maxY - minY;
    if (width <= 0 && height <= 0) return null;
    return _StrokeSummary(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      width: width,
      height: height,
    );
  }
}

class _StrokeSummary {
  const _StrokeSummary({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.width,
    required this.height,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final double width;
  final double height;
}
