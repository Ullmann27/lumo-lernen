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
    'B': LetterTemplate(
      letter: 'B',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical, position: 'left'),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 2, maxStrokes: 4,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(20, 10), Offset(65, 25), Offset(65, 45), Offset(20, 50)],
        [Offset(20, 50), Offset(70, 65), Offset(70, 85), Offset(20, 90)],
      ],
      description: 'B wie Ball - Strich runter, dann zwei Baeuche!',
    ),
    'C': LetterTemplate(
      letter: 'C',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.curve)],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(75, 25), Offset(45, 12), Offset(20, 40), Offset(20, 70), Offset(45, 88), Offset(75, 78)],
      ],
      description: 'C wie Computer - eine Kurve wie ein offener Mond!',
    ),
    'D': LetterTemplate(
      letter: 'D',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical, position: 'left'),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(20, 10), Offset(70, 30), Offset(75, 60), Offset(20, 90)],
      ],
      description: 'D wie Dackel - Strich runter, dann ein grosser Bauch!',
    ),
    'F': LetterTemplate(
      letter: 'F',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'middle'),
      ],
      minStrokes: 3, maxStrokes: 4,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(20, 10), Offset(75, 10)],
        [Offset(20, 50), Offset(60, 50)],
      ],
      description: 'F wie Fisch - Strich runter und zwei Querstriche!',
    ),
    'G': LetterTemplate(
      letter: 'G',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.curve)],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(75, 25), Offset(45, 12), Offset(20, 40), Offset(20, 70), Offset(45, 88), Offset(75, 78), Offset(75, 55), Offset(55, 55)],
      ],
      description: 'G wie Garten - Kurve wie ein C mit einem Haken!',
    ),
    'J': LetterTemplate(
      letter: 'J',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(60, 10), Offset(60, 75), Offset(40, 90), Offset(20, 82)],
      ],
      description: 'J wie Junge - Strich runter und unten ein Haekchen!',
    ),
    'K': LetterTemplate(
      letter: 'K',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 2, maxStrokes: 4,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(20, 50), Offset(75, 10)],
        [Offset(20, 50), Offset(75, 90)],
      ],
      description: 'K wie Katze - Strich runter und zwei schraege Striche!',
    ),
    'P': LetterTemplate(
      letter: 'P',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(20, 10), Offset(70, 25), Offset(70, 45), Offset(20, 55)],
      ],
      description: 'P wie Papa - Strich runter und oben ein Bauch!',
    ),
    'Q': LetterTemplate(
      letter: 'Q',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(50, 10), Offset(82, 30), Offset(82, 70), Offset(50, 90), Offset(18, 70), Offset(18, 30), Offset(50, 10)],
        [Offset(65, 70), Offset(90, 95)],
      ],
      description: 'Q wie Quark - ein Kreis mit einem Schwaenzchen!',
    ),
    'R': LetterTemplate(
      letter: 'R',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 2, maxStrokes: 4,
      demoStrokes: [
        [Offset(20, 10), Offset(20, 90)],
        [Offset(20, 10), Offset(70, 25), Offset(70, 45), Offset(20, 55)],
        [Offset(20, 55), Offset(80, 90)],
      ],
      description: 'R wie Rose - wie P, aber mit einem Bein nach rechts!',
    ),
    'T': LetterTemplate(
      letter: 'T',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(15, 15), Offset(85, 15)],
        [Offset(50, 15), Offset(50, 90)],
      ],
      description: 'T wie Tisch - oben quer und in der Mitte runter!',
    ),
    'V': LetterTemplate(
      letter: 'V',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(15, 10), Offset(50, 90), Offset(85, 10)],
      ],
      description: 'V wie Vogel - schraeg runter und schraeg wieder hoch!',
    ),
    'W': LetterTemplate(
      letter: 'W',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 1, maxStrokes: 4,
      demoStrokes: [
        [Offset(10, 10), Offset(30, 90), Offset(50, 40), Offset(70, 90), Offset(90, 10)],
      ],
      description: 'W wie Wasser - zwei V nebeneinander!',
    ),
    'X': LetterTemplate(
      letter: 'X',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(15, 10), Offset(85, 90)],
        [Offset(85, 10), Offset(15, 90)],
      ],
      description: 'X wie Xylophon - ein Kreuz aus zwei schraegen Strichen!',
    ),
    'Y': LetterTemplate(
      letter: 'Y',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 2, maxStrokes: 4,
      demoStrokes: [
        [Offset(15, 10), Offset(50, 50)],
        [Offset(85, 10), Offset(50, 50)],
        [Offset(50, 50), Offset(50, 90)],
      ],
      description: 'Y wie Yacht - zwei Striche oben und einer runter!',
    ),
    'Z': LetterTemplate(
      letter: 'Z',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 4,
      demoStrokes: [
        [Offset(15, 10), Offset(85, 10), Offset(15, 90), Offset(85, 90)],
      ],
      description: 'Z wie Zebra - oben quer, schraeg runter, unten quer!',
    ),

    // ────────────────────────────────────────────────────────────────
    // ZAHLEN 0-9 (10 Templates, Klasse 1 Mathe)
    // ────────────────────────────────────────────────────────────────
    '0': LetterTemplate(
      letter: '0',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.circle)],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(50, 10), Offset(20, 30), Offset(20, 70), Offset(50, 90),
         Offset(80, 70), Offset(80, 30), Offset(50, 10)],
      ],
      description: 'Null - ein Oval, oben anfangen!',
    ),
    '1': LetterTemplate(
      letter: '1',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(30, 25), Offset(50, 10), Offset(50, 90)],
      ],
      description: 'Eins - ein kleiner Schraegstrich oben, dann gerade runter!',
    ),
    '2': LetterTemplate(
      letter: '2',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.curve, position: 'top'),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(25, 30), Offset(50, 10), Offset(75, 30), Offset(20, 90),
         Offset(80, 90)],
      ],
      description: 'Zwei - oben einen Bogen, dann schraeg runter, unten quer!',
    ),
    '3': LetterTemplate(
      letter: '3',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.curve, position: 'top'),
        _ExpectedStroke(type: _StrokeType.curve, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(25, 25), Offset(50, 10), Offset(75, 30), Offset(50, 50),
         Offset(75, 70), Offset(50, 90), Offset(25, 75)],
      ],
      description: 'Drei - zwei Boegen rechts!',
    ),
    '4': LetterTemplate(
      letter: '4',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.horizontal),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(25, 10), Offset(25, 60), Offset(80, 60)],
        [Offset(60, 10), Offset(60, 90)],
      ],
      description: 'Vier - schraeg runter, quer, dann gerade runter!',
    ),
    '5': LetterTemplate(
      letter: '5',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(75, 10), Offset(25, 10), Offset(25, 50), Offset(60, 45),
         Offset(80, 65), Offset(60, 90), Offset(25, 85)],
      ],
      description: 'Fuenf - oben quer, runter, dann ein Bogen!',
    ),
    '6': LetterTemplate(
      letter: '6',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.curve),
        _ExpectedStroke(type: _StrokeType.circle, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(70, 15), Offset(40, 30), Offset(25, 60), Offset(30, 85),
         Offset(60, 90), Offset(75, 70), Offset(60, 55), Offset(30, 60)],
      ],
      description: 'Sechs - schraeg runter, dann ein Kreis unten!',
    ),
    '7': LetterTemplate(
      letter: '7',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(20, 15), Offset(80, 15), Offset(35, 90)],
      ],
      description: 'Sieben - oben quer, dann schraeg runter!',
    ),
    '8': LetterTemplate(
      letter: '8',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle, position: 'top'),
        _ExpectedStroke(type: _StrokeType.circle, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(50, 10), Offset(30, 25), Offset(30, 45), Offset(50, 50),
         Offset(70, 60), Offset(70, 80), Offset(50, 90), Offset(30, 80),
         Offset(30, 60), Offset(50, 50), Offset(70, 45), Offset(70, 25),
         Offset(50, 10)],
      ],
      description: 'Acht - zwei Kreise uebereinander!',
    ),
    '9': LetterTemplate(
      letter: '9',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle, position: 'top'),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(50, 10), Offset(30, 20), Offset(25, 40), Offset(40, 55),
         Offset(70, 50), Offset(75, 30), Offset(70, 15), Offset(50, 10)],
        [Offset(70, 50), Offset(60, 90)],
      ],
      description: 'Neun - ein Kreis oben, dann schraeg runter!',
    ),

    // ────────────────────────────────────────────────────────────────
    // KLEINBUCHSTABEN a-z (26 Templates, Klasse 1 zweite Haelfte)
    // ────────────────────────────────────────────────────────────────
    'a': LetterTemplate(
      letter: 'a',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(70, 50), Offset(50, 40), Offset(35, 55), Offset(35, 75),
         Offset(50, 90), Offset(70, 80), Offset(70, 40)],
        [Offset(70, 40), Offset(70, 90)],
      ],
      description: 'a wie Apfel - ein kleiner Kreis, dann Strich runter!',
    ),
    'b': LetterTemplate(
      letter: 'b',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.circle, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(30, 10), Offset(30, 90), Offset(60, 80), Offset(70, 65),
         Offset(60, 50), Offset(30, 50)],
      ],
      description: 'b - langer Strich runter, dann ein Bauch unten rechts!',
    ),
    'c': LetterTemplate(
      letter: 'c',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.curve)],
      minStrokes: 1, maxStrokes: 1,
      demoStrokes: [
        [Offset(75, 50), Offset(60, 40), Offset(40, 45), Offset(30, 65),
         Offset(40, 85), Offset(60, 90), Offset(75, 80)],
      ],
      description: 'c wie Clown - ein offener Bogen!',
    ),
    'd': LetterTemplate(
      letter: 'd',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(70, 50), Offset(50, 45), Offset(35, 60), Offset(40, 80),
         Offset(60, 90), Offset(70, 80), Offset(70, 10)],
        [Offset(70, 10), Offset(70, 90)],
      ],
      description: 'd - ein Kreis, dann langer Strich rauf!',
    ),
    'e': LetterTemplate(
      letter: 'e',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.curve)],
      minStrokes: 1, maxStrokes: 1,
      demoStrokes: [
        [Offset(30, 65), Offset(70, 65), Offset(70, 55), Offset(60, 45),
         Offset(40, 50), Offset(30, 65), Offset(40, 85), Offset(70, 85)],
      ],
      description: 'e wie Esel - ein Strich, dann Bogen!',
    ),
    'f': LetterTemplate(
      letter: 'f',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.horizontal),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(60, 90), Offset(60, 25), Offset(70, 15), Offset(80, 20)],
        [Offset(40, 55), Offset(75, 55)],
      ],
      description: 'f wie Fisch - langer Strich, oben Bogen, Mitte quer!',
    ),
    'g': LetterTemplate(
      letter: 'g',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(70, 60), Offset(50, 50), Offset(35, 60), Offset(40, 75),
         Offset(60, 80), Offset(70, 70), Offset(70, 50)],
        [Offset(70, 50), Offset(70, 90), Offset(50, 95)],
      ],
      description: 'g - Kreis, dann Strich runter mit Schlinge unten!',
    ),
    'h': LetterTemplate(
      letter: 'h',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical, position: 'left'),
        _ExpectedStroke(type: _StrokeType.curve, position: 'right'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(30, 10), Offset(30, 90)],
        [Offset(30, 60), Offset(50, 50), Offset(65, 60), Offset(65, 90)],
      ],
      description: 'h - langer Strich, dann kleiner Bogen rechts!',
    ),
    'i': LetterTemplate(
      letter: 'i',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.any),
      ],
      minStrokes: 2, maxStrokes: 2,
      demoStrokes: [
        [Offset(50, 45), Offset(50, 90)],
        [Offset(50, 25), Offset(50, 30)],
      ],
      description: 'i wie Igel - kurzer Strich runter, Punkt oben!',
    ),
    'j': LetterTemplate(
      letter: 'j',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.any),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(55, 45), Offset(55, 85), Offset(40, 95), Offset(30, 90)],
        [Offset(55, 25), Offset(55, 30)],
      ],
      description: 'j - Strich mit Schlinge unten, Punkt oben!',
    ),
    'k': LetterTemplate(
      letter: 'k',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 2, maxStrokes: 3,
      demoStrokes: [
        [Offset(30, 10), Offset(30, 90)],
        [Offset(70, 45), Offset(30, 65), Offset(70, 90)],
      ],
      description: 'k - Strich runter, dann zwei Striche rechts!',
    ),
    'l': LetterTemplate(
      letter: 'l',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.vertical)],
      minStrokes: 1, maxStrokes: 1,
      demoStrokes: [
        [Offset(50, 10), Offset(50, 90)],
      ],
      description: 'l - einfach ein Strich von oben nach unten!',
    ),
    'm': LetterTemplate(
      letter: 'm',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(20, 90), Offset(20, 45), Offset(35, 45), Offset(45, 55),
         Offset(45, 90)],
        [Offset(45, 55), Offset(55, 45), Offset(70, 45), Offset(80, 55),
         Offset(80, 90)],
      ],
      description: 'm wie Maus - drei Striche mit kleinen Hubbeln!',
    ),
    'n': LetterTemplate(
      letter: 'n',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(25, 90), Offset(25, 45), Offset(45, 45), Offset(65, 55),
         Offset(70, 90)],
      ],
      description: 'n - zwei Striche mit Hubbel oben!',
    ),
    'o': LetterTemplate(
      letter: 'o',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.circle)],
      minStrokes: 1, maxStrokes: 1,
      demoStrokes: [
        [Offset(50, 45), Offset(30, 55), Offset(30, 80), Offset(50, 90),
         Offset(70, 80), Offset(70, 55), Offset(50, 45)],
      ],
      description: 'o wie Oma - ein kleiner Kreis!',
    ),
    'p': LetterTemplate(
      letter: 'p',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.circle, position: 'top'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(30, 95), Offset(30, 45), Offset(55, 45), Offset(70, 55),
         Offset(70, 70), Offset(55, 80), Offset(30, 80)],
      ],
      description: 'p - Strich runter mit Schlinge unten, Bauch oben!',
    ),
    'q': LetterTemplate(
      letter: 'q',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.circle),
        _ExpectedStroke(type: _StrokeType.vertical),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(70, 50), Offset(50, 45), Offset(35, 55), Offset(35, 75),
         Offset(50, 85), Offset(70, 80), Offset(70, 45)],
        [Offset(70, 45), Offset(70, 95), Offset(80, 100)],
      ],
      description: 'q - Kreis, dann Strich runter mit Schwung rechts!',
    ),
    'r': LetterTemplate(
      letter: 'r',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.curve, position: 'top'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(30, 90), Offset(30, 45), Offset(50, 45), Offset(65, 55)],
      ],
      description: 'r - kurzer Strich, dann kleiner Bogen oben!',
    ),
    's': LetterTemplate(
      letter: 's',
      expectedStrokes: [_ExpectedStroke(type: _StrokeType.curve)],
      minStrokes: 1, maxStrokes: 1,
      demoStrokes: [
        [Offset(70, 50), Offset(50, 45), Offset(35, 55), Offset(50, 65),
         Offset(65, 75), Offset(50, 90), Offset(30, 85)],
      ],
      description: 's wie Sonne - ein geschwungener Bogen, S-Form!',
    ),
    't': LetterTemplate(
      letter: 't',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.vertical),
        _ExpectedStroke(type: _StrokeType.horizontal),
      ],
      minStrokes: 2, maxStrokes: 2,
      demoStrokes: [
        [Offset(50, 20), Offset(50, 90)],
        [Offset(35, 45), Offset(70, 45)],
      ],
      description: 't wie Tiger - langer Strich runter, Querstrich mitte!',
    ),
    'u': LetterTemplate(
      letter: 'u',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.curve, position: 'bottom'),
        _ExpectedStroke(type: _StrokeType.vertical, position: 'right'),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(30, 45), Offset(30, 80), Offset(50, 90), Offset(70, 80),
         Offset(70, 45)],
        [Offset(70, 45), Offset(70, 90)],
      ],
      description: 'u wie Uhu - ein Bogen unten, dann gerade hoch!',
    ),
    'v': LetterTemplate(
      letter: 'v',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(25, 45), Offset(50, 90), Offset(75, 45)],
      ],
      description: 'v - zwei schraege Striche die unten zusammentreffen!',
    ),
    'w': LetterTemplate(
      letter: 'w',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 1, maxStrokes: 4,
      demoStrokes: [
        [Offset(15, 45), Offset(35, 90), Offset(50, 65), Offset(65, 90),
         Offset(85, 45)],
      ],
      description: 'w wie Wal - vier schraege Striche, zwei v!',
    ),
    'x': LetterTemplate(
      letter: 'x',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 2, maxStrokes: 2,
      demoStrokes: [
        [Offset(25, 45), Offset(75, 90)],
        [Offset(75, 45), Offset(25, 90)],
      ],
      description: 'x - zwei schraege Striche, kreuzen sich!',
    ),
    'y': LetterTemplate(
      letter: 'y',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.diagonal),
      ],
      minStrokes: 1, maxStrokes: 2,
      demoStrokes: [
        [Offset(25, 45), Offset(50, 75)],
        [Offset(75, 45), Offset(35, 100)],
      ],
      description: 'y - zwei Striche, einer geht bis ganz nach unten!',
    ),
    'z': LetterTemplate(
      letter: 'z',
      expectedStrokes: [
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'top'),
        _ExpectedStroke(type: _StrokeType.diagonal),
        _ExpectedStroke(type: _StrokeType.horizontal, position: 'bottom'),
      ],
      minStrokes: 1, maxStrokes: 3,
      demoStrokes: [
        [Offset(25, 45), Offset(75, 45), Offset(25, 90), Offset(75, 90)],
      ],
      description: 'z wie Zebra - oben quer, schraeg runter, unten quer!',
    ),
  };

  static List<String> get availableLetters => all.keys.toList();

  /// Heinz' Erweiterung: getrennte Buchstaben-Pools pro Modus.
  static List<String> get uppercaseLetters =>
      all.keys.where((k) => k.length == 1 &&
          k.codeUnitAt(0) >= 65 && k.codeUnitAt(0) <= 90).toList();
  static List<String> get lowercaseLetters =>
      all.keys.where((k) => k.length == 1 &&
          k.codeUnitAt(0) >= 97 && k.codeUnitAt(0) <= 122).toList();
  static List<String> get numbers =>
      all.keys.where((k) => k.length == 1 &&
          k.codeUnitAt(0) >= 48 && k.codeUnitAt(0) <= 57).toList();

  /// Lehrplan-Reihenfolge: leichteste Buchstaben zuerst (basierend
  /// auf oesterreichischem Volksschullehrplan Klasse 1).
  /// O,I,A,E,M,L,N,S,T,R sind die ersten 10 Buchstaben im Lehrplan.
  static List<String> get curriculumOrderUppercase => const [
    'O', 'I', 'A', 'E', 'M', 'L', 'N', 'S', 'T', 'R',
    'U', 'P', 'H', 'K', 'D', 'B', 'F', 'G', 'W', 'Z',
    'V', 'J', 'C', 'Y', 'Q', 'X',
  ];
  static List<String> get curriculumOrderLowercase => const [
    'o', 'i', 'a', 'e', 'm', 'l', 'n', 's', 't', 'r',
    'u', 'p', 'h', 'k', 'd', 'b', 'f', 'g', 'w', 'z',
    'v', 'j', 'c', 'y', 'q', 'x',
  ];
  /// Zahlen-Reihenfolge: kleine zuerst.
  static List<String> get curriculumOrderNumbers => const [
    '1', '2', '3', '4', '5', '0', '6', '7', '8', '9',
  ];
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
