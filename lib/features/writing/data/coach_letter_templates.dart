// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - BUCHSTABEN-TEMPLATES
// ════════════════════════════════════════════════════════════════════════
//
// Vorlagen fuer das Vorzeichnen durch Lumo (Phase 3).
// Koordinaten sind in einem normalisierten 100x140-Koordinatensystem
// (entspricht ungefaehr einer Schreibheft-Zelle). Phase-1+2 nutzt die
// Templates auch fuer minimale Plausibilitaetspruefung (Mittellinie etc.).

import 'package:flutter/foundation.dart';

@immutable
class CoachStrokeTemplate {
  const CoachStrokeTemplate({
    required this.order,
    required this.points,
  });

  /// Reihenfolge: 0 = erster Strich, 1 = zweiter, usw.
  final int order;

  /// Punkte des Strichs in lokalen 100x140-Koordinaten.
  final List<(double, double)> points;
}

@immutable
class CoachLetterTemplate {
  const CoachLetterTemplate({
    required this.letter,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.strokes,
    required this.expectedStrokeCount,
  });

  final String letter;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final List<CoachStrokeTemplate> strokes;

  /// Erwartete Mindest-Stroke-Zahl (Toleranz: +/-1).
  final int expectedStrokeCount;
}

/// Statischer Katalog der unterstuetzten Buchstaben.
/// Phase 2: I, L, O, H. Erweiterung in Phase 4.
class CoachLetterTemplates {
  const CoachLetterTemplates._();

  static const double _w = 100;
  static const double _h = 140;

  // Buchstabe I: ein vertikaler Strich von oben nach unten.
  static const _templateI = CoachLetterTemplate(
    letter: 'I',
    viewBoxWidth: _w,
    viewBoxHeight: _h,
    expectedStrokeCount: 1,
    strokes: [
      CoachStrokeTemplate(order: 0, points: [
        (50.0, 18.0),
        (50.0, 35.0),
        (50.0, 55.0),
        (50.0, 75.0),
        (50.0, 95.0),
        (50.0, 122.0),
      ]),
    ],
  );

  // Buchstabe L: vertikal nach unten, dann nach rechts.
  static const _templateL = CoachLetterTemplate(
    letter: 'L',
    viewBoxWidth: _w,
    viewBoxHeight: _h,
    expectedStrokeCount: 1,
    strokes: [
      CoachStrokeTemplate(order: 0, points: [
        (32.0, 18.0),
        (32.0, 40.0),
        (32.0, 60.0),
        (32.0, 80.0),
        (32.0, 100.0),
        (32.0, 122.0),
        (50.0, 122.0),
        (70.0, 122.0),
        (85.0, 122.0),
      ]),
    ],
  );

  // Buchstabe O: geschlossener Kreis.
  static const _templateO = CoachLetterTemplate(
    letter: 'O',
    viewBoxWidth: _w,
    viewBoxHeight: _h,
    expectedStrokeCount: 1,
    strokes: [
      CoachStrokeTemplate(order: 0, points: [
        (50.0, 22.0),
        (35.0, 28.0),
        (25.0, 42.0),
        (20.0, 60.0),
        (20.0, 80.0),
        (25.0, 100.0),
        (35.0, 114.0),
        (50.0, 120.0),
        (65.0, 114.0),
        (75.0, 100.0),
        (80.0, 80.0),
        (80.0, 60.0),
        (75.0, 42.0),
        (65.0, 28.0),
        (50.0, 22.0),
      ]),
    ],
  );

  // Buchstabe H: zwei Vertikale + Querstrich.
  static const _templateH = CoachLetterTemplate(
    letter: 'H',
    viewBoxWidth: _w,
    viewBoxHeight: _h,
    expectedStrokeCount: 3,
    strokes: [
      CoachStrokeTemplate(order: 0, points: [
        (25.0, 18.0),
        (25.0, 45.0),
        (25.0, 70.0),
        (25.0, 100.0),
        (25.0, 122.0),
      ]),
      CoachStrokeTemplate(order: 1, points: [
        (75.0, 18.0),
        (75.0, 45.0),
        (75.0, 70.0),
        (75.0, 100.0),
        (75.0, 122.0),
      ]),
      CoachStrokeTemplate(order: 2, points: [
        (25.0, 70.0),
        (40.0, 70.0),
        (60.0, 70.0),
        (75.0, 70.0),
      ]),
    ],
  );

  static const Map<String, CoachLetterTemplate> _byLetter = {
    'I': _templateI,
    'L': _templateL,
    'O': _templateO,
    'H': _templateH,
  };

  static CoachLetterTemplate? forLetter(String letter) =>
      _byLetter[letter.toUpperCase()];

  static bool isSupported(String letter) =>
      _byLetter.containsKey(letter.toUpperCase());

  static List<String> get supportedLetters => _byLetter.keys.toList();
}
