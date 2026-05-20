// ════════════════════════════════════════════════════════════════════════
// LUMO SCHREIBCOACH — Logic Layer
// ════════════════════════════════════════════════════════════════════════
// Enthaelt:
//   - LetterTemplate: Vorlage fuer jeden Buchstaben (Strokes als Punkte)
//   - LetterShapeAnalyzer: prueft ob Strokes zur Vorlage passen
//   - WritingFeedback: kindgerechte Korrektur-Nachrichten
//   - WritingFeedbackEngine: entscheidet welches Feedback gegeben wird
//
// MVP 1: 10 Buchstaben (A, E, I, O, U, M, L, S, N, H)
// Phase 2 (deferred): ML Kit Digital Ink Recognition fuer freies Schreiben.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';

/// Ein Stroke = eine zusammenhaengende Stiftbewegung.
class WritingStroke {
  WritingStroke(this.points);
  final List<Offset> points;

  /// Bounding-Box des Strokes.
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool get isVertical {
    final b = bounds;
    return b.height > b.width * 1.5;
  }

  bool get isHorizontal {
    final b = bounds;
    return b.width > b.height * 1.5;
  }

  bool get isDiagonal {
    final b = bounds;
    return !isVertical && !isHorizontal && b.width > 20 && b.height > 20;
  }
}

/// Ein Buchstaben-Template mit Demo-Strokes.
class LetterTemplate {
  const LetterTemplate({
    required this.letter,
    required this.expectedStrokes,
    required this.minStrokes,
    required this.maxStrokes,
    required this.demoStrokes,
    required this.description,
  });
  final String letter;
  /// Beschreibung der erwarteten Stroke-Eigenschaften
  final List<_ExpectedStroke> expectedStrokes;
  /// Min/Max Anzahl Strokes (Toleranz!)
  final int minStrokes;
  final int maxStrokes;
  /// Demo-Strokes in einem 100x100-Koordinatensystem
  final List<List<Offset>> demoStrokes;
  /// Beschreibung wie der Buchstabe gezeichnet wird
  final String description;
}

class _ExpectedStroke {
  const _ExpectedStroke({required this.type, this.position});
  final _StrokeType type;
  /// 'left', 'right', 'middle', 'top', 'bottom' - optional
  final String? position;
}

enum _StrokeType { vertical, horizontal, diagonal, curve, circle, any }

/// Lexikon der 10 MVP-Buchstaben.
class LetterTemplates {
  LetterTemplates._();

  static const Map<String, LetterTemplate> all = {
    'A': LetterTemplate(
      letter: 'A',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.horizontal),
      ],
      minStrokes: 2,
      maxStrokes: 3,
      demoStrokes: [
        [Offset(20, 90), Offset(50, 10)],
        [Offset(50, 10), Offset(80, 90)],
        [Offset(30, 60), Offset(70, 60)],
      ],
      description: 'A wie Apfel - zwei schraege Striche und ein Querstrich!',
    ),
    'E': LetterTemplate(
      letter: 'E',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'middle'),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'bottom'),
      ],
      minStrokes: 3,
      maxStrokes: 4,
      demoStrokes: [
        [Offset(25, 10), Offset(25, 90)],
        [Offset(25, 10), Offset(75, 10)],
        [Offset(25, 50), Offset(65, 50)],
        [Offset(25, 90), Offset(75, 90)],
      ],
      description: 'E wie Eis - ein Strich runter und drei Querstriche!',
    ),
    'I': LetterTemplate(
      letter: 'I',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 1,
      maxStrokes: 3,
      demoStrokes: [
        [Offset(50, 10), Offset(50, 90)],
      ],
      description: 'I wie Igel - ein einfacher Strich von oben nach unten!',
    ),
    'O': LetterTemplate(
      letter: 'O',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle),
      ],
      minStrokes: 1,
      maxStrokes: 2,
      demoStrokes: [
        [
          Offset(50, 10), Offset(75, 20), Offset(85, 50), Offset(75, 80),
          Offset(50, 90), Offset(25, 80), Offset(15, 50), Offset(25, 20),
          Offset(50, 10),
        ],
      ],
      description: 'O wie Oma - rund wie ein Kreis!',
    ),
    'U': LetterTemplate(
      letter: 'U',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 1,
      maxStrokes: 3,
      demoStrokes: [
        [
          Offset(20, 15), Offset(20, 60), Offset(25, 80), Offset(50, 90),
          Offset(75, 80), Offset(80, 60), Offset(80, 15),
        ],
      ],
      description: 'U wie Uhr - runter, herum und wieder rauf!',
    ),
    'M': LetterTemplate(
      letter: 'M',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical, position: 'left'),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.vertical, position: 'right'),
      ],
      minStrokes: 1,
      maxStrokes: 4,
      demoStrokes: [
        [
          Offset(15, 90), Offset(15, 10), Offset(50, 60),
          Offset(85, 10), Offset(85, 90),
        ],
      ],
      description: 'M wie Mama - rauf, runter zur Mitte, rauf, runter!',
    ),
    'L': LetterTemplate(
      letter: 'L',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'bottom'),
      ],
      minStrokes: 1,
      maxStrokes: 2,
      demoStrokes: [
        [Offset(25, 10), Offset(25, 90), Offset(80, 90)],
      ],
      description: 'L wie Loewe - ein Strich runter und einer nach rechts!',
    ),
    'S': LetterTemplate(
      letter: 'S',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 1,
      maxStrokes: 2,
      demoStrokes: [
        [
          Offset(80, 20), Offset(60, 12), Offset(35, 15), Offset(25, 30),
          Offset(35, 45), Offset(60, 50), Offset(75, 65), Offset(70, 80),
          Offset(50, 88), Offset(25, 80),
        ],
      ],
      description: 'S wie Sonne - eine geschwungene Schlange!',
    ),
    'N': LetterTemplate(
      letter: 'N',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical, position: 'left'),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.vertical, position: 'right'),
      ],
      minStrokes: 1,
      maxStrokes: 3,
      demoStrokes: [
        [
          Offset(20, 90), Offset(20, 10), Offset(80, 90), Offset(80, 10),
        ],
      ],
      description: 'N wie Nase - rauf, schraeg runter, wieder rauf!',
    ),
    'H': LetterTemplate(
      letter: 'H',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical, position: 'left'),
        _ExpectedStroke(type: _StrokeType.vertical, position: 'right'),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'middle'),
      ],
      minStrokes: 3,
      maxStrokes: 4,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(80, 10), Offset(80, 90)],
        [Offset(20, 50), Offset(80, 50)],
      ],
      description: 'H wie Haus - zwei Striche und eine Bruecke!',
    ),
  };

  static List<String> get availableLetters => all.keys.toList();
}

// ════════════════════════════════════════════════════════════════════════
// SHAPE ANALYZER
// ════════════════════════════════════════════════════════════════════════

class _AnalysisResult {
  const _AnalysisResult({
    required this.score,
    required this.matched,
    required this.issue,
  });
  final double score; // 0.0 - 1.0
  final bool matched;
  /// Welcher Stroke-Typ fehlt? null wenn alles passt.
  final _Issue? issue;
}

enum _Issue {
  zuWenigStrokes,
  zuVieleStrokes,
  vertikalFehlt,
  horizontalFehlt,
  rundungFehlt,
  diagonaleFehlt,
  unklar,
}

class LetterShapeAnalyzer {
  LetterShapeAnalyzer._();

  /// Analysiert die User-Strokes gegen die Template-Anforderungen.
  static _AnalysisResult analyze({
    required List<WritingStroke> userStrokes,
    required LetterTemplate template,
  }) {
    if (userStrokes.isEmpty) {
      return const _AnalysisResult(
        score: 0,
        matched: false,
        issue: _Issue.zuWenigStrokes,
      );
    }

    // Stroke-Anzahl pruefen (mit Toleranz)
    final n = userStrokes.length;
    if (n < template.minStrokes) {
      return _AnalysisResult(
        score: 0.3,
        matched: false,
        issue: _Issue.zuWenigStrokes,
      );
    }

    // Stroke-Typen analysieren
    int verticalCount = 0;
    int horizontalCount = 0;
    int diagonalCount = 0;
    int curveCount = 0;
    int circleCount = 0;
    double totalLen = 0;
    for (final s in userStrokes) {
      if (s.points.length < 2) continue;
      final b = s.bounds;
      totalLen += _strokeLength(s);
      if (b.width < 5 && b.height < 5) continue; // Punkt
      if (_isCircleish(s)) {
        circleCount++;
      } else if (s.isVertical) {
        verticalCount++;
      } else if (s.isHorizontal) {
        horizontalCount++;
      } else if (s.isDiagonal) {
        diagonalCount++;
      } else {
        curveCount++;
      }
    }

    // Erforderliche Stroke-Typen aus Template zaehlen
    int reqVertical = 0, reqHorizontal = 0, reqDiagonal = 0, reqCurve = 0, reqCircle = 0;
    for (final e in template.expectedStrokes) {
      switch (e.type) {
        case _StrokeType.vertical:
          reqVertical++;
          break;
        case _StrokeType.horizontal:
          reqHorizontal++;
          break;
        case _StrokeType.diagonal:
          reqDiagonal++;
          break;
        case _StrokeType.curve:
          reqCurve++;
          break;
        case _StrokeType.circle:
          reqCircle++;
          break;
        case _StrokeType.any:
          break;
      }
    }

    // Score-Berechnung
    double score = 0;
    int checks = 0;

    if (reqVertical > 0) {
      checks++;
      // Bei einem Strich der vertikal UND diagonal wirkt (z.B. fuer M, N, A schreibt das Kind oft frei)
      // wir akzeptieren auch diagonale Strokes als 'vertikalish'
      if (verticalCount + diagonalCount >= reqVertical) score++;
      else if (verticalCount >= reqVertical - 1) score += 0.5;
    }
    if (reqHorizontal > 0) {
      checks++;
      if (horizontalCount >= reqHorizontal) score++;
      else if (horizontalCount >= reqHorizontal - 1) score += 0.5;
    }
    if (reqDiagonal > 0) {
      checks++;
      if (diagonalCount + verticalCount >= reqDiagonal) score++;
      else if (diagonalCount >= reqDiagonal - 1) score += 0.5;
    }
    if (reqCurve > 0) {
      checks++;
      if (curveCount + circleCount >= reqCurve) score++;
    }
    if (reqCircle > 0) {
      checks++;
      if (circleCount > 0) score++;
      else if (curveCount > 0) score += 0.5;
    }

    final normalized = checks > 0 ? score / checks : 0.0;
    final matched = normalized >= 0.6;

    _Issue? issue;
    if (!matched) {
      if (reqVertical > 0 && verticalCount + diagonalCount < reqVertical) {
        issue = _Issue.vertikalFehlt;
      } else if (reqHorizontal > 0 && horizontalCount < reqHorizontal) {
        issue = _Issue.horizontalFehlt;
      } else if (reqCircle > 0 && circleCount == 0) {
        issue = _Issue.rundungFehlt;
      } else if (reqDiagonal > 0 && diagonalCount == 0) {
        issue = _Issue.diagonaleFehlt;
      } else {
        issue = _Issue.unklar;
      }
    }

    return _AnalysisResult(
      score: normalized,
      matched: matched,
      issue: issue,
    );
  }

  static double _strokeLength(WritingStroke s) {
    double len = 0;
    for (int i = 1; i < s.points.length; i++) {
      len += (s.points[i] - s.points[i - 1]).distance;
    }
    return len;
  }

  /// Heuristik: ist der Stroke ein geschlossener Kreis?
  static bool _isCircleish(WritingStroke s) {
    if (s.points.length < 8) return false;
    final start = s.points.first;
    final end = s.points.last;
    final b = s.bounds;
    if (b.width < 20 || b.height < 20) return false;
    final closeness = (start - end).distance;
    // Kreis: Start nah am Ende, und Breite ~ Hoehe
    final aspect = b.width / b.height;
    return closeness < (b.width + b.height) * 0.2 && aspect > 0.5 && aspect < 2.0;
  }
}

// ════════════════════════════════════════════════════════════════════════
// FEEDBACK ENGINE
// ════════════════════════════════════════════════════════════════════════

class WritingFeedback {
  const WritingFeedback({
    required this.type,
    required this.message,
    required this.showDemo,
    required this.matched,
  });
  final FeedbackType type;
  final String message;
  final bool showDemo;
  final bool matched;
}

enum FeedbackType { correct, almost, missingStroke, retry, demo }

class WritingFeedbackEngine {
  WritingFeedbackEngine._();
  static final _rng = math.Random();

  static const _lobMessages = [
    'Super gemacht! ⭐',
    'Wow, das ist toll!',
    'Lumo ist stolz auf dich!',
    'Genau richtig!',
    'Klasse geschrieben!',
  ];

  static WritingFeedback generate({
    required LetterTemplate template,
    required List<WritingStroke> userStrokes,
  }) {
    final result = LetterShapeAnalyzer.analyze(
      userStrokes: userStrokes,
      template: template,
    );

    if (result.matched && result.score >= 0.85) {
      return WritingFeedback(
        type: FeedbackType.correct,
        message: _lobMessages[_rng.nextInt(_lobMessages.length)],
        showDemo: false,
        matched: true,
      );
    }
    if (result.matched && result.score >= 0.6) {
      return WritingFeedback(
        type: FeedbackType.almost,
        message: 'Fast! Das sieht schon gut aus. Probier es nochmal!',
        showDemo: false,
        matched: true,
      );
    }
    // Nicht matched - spezifischer Hinweis
    String msg;
    switch (result.issue) {
      case _Issue.zuWenigStrokes:
        msg = 'Da fehlt noch etwas. Schreib das ${template.letter} ganz - '
            '${template.description}';
        break;
      case _Issue.vertikalFehlt:
        msg = 'Da fehlt ein gerader Strich von oben nach unten. '
            '${template.description}';
        break;
      case _Issue.horizontalFehlt:
        msg = 'Da fehlt ein Querstrich. ${template.description}';
        break;
      case _Issue.rundungFehlt:
        msg = 'Versuch es runder zu zeichnen! ${template.description}';
        break;
      case _Issue.diagonaleFehlt:
        msg = 'Da fehlt ein schraeger Strich. ${template.description}';
        break;
      default:
        msg = 'Schau nochmal: ${template.description}';
    }
    return WritingFeedback(
      type: FeedbackType.missingStroke,
      message: msg,
      showDemo: true,
      matched: false,
    );
  }
}
