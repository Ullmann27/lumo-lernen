import 'dart:math' as math;

import 'writing_domain.dart';

/// Rules for the child-friendly writing trainer.
///
/// Writing a letter is practice, not an exam. A drawn attempt is accepted
/// as soon as it is a real attempt (visible ink of a reasonable size).
/// Contour scores never block progress and are never shown as percent.
class LetterPracticeRules {
  const LetterPracticeRules._();

  /// Minimum total ink length (in template units, box = 100) for a letter.
  static const double minLetterInk = 22;

  /// Minimum extent of the drawing (width or height) for a letter.
  static const double minLetterExtent = 14;

  /// Words and sentences need a little more ink than a single letter.
  static const double minWordInk = 40;

  /// Total length of all strokes in template units.
  static double inkLength(List<Stroke> strokes) {
    var total = 0.0;
    for (final stroke in strokes) {
      final points = stroke.points;
      for (var i = 1; i < points.length; i++) {
        total += math.sqrt(math.pow(points[i].x - points[i - 1].x, 2) +
            math.pow(points[i].y - points[i - 1].y, 2));
      }
    }
    return total;
  }

  /// Larger side of the bounding box of all ink, in template units.
  static double inkExtent(List<Stroke> strokes) {
    double? minX, maxX, minY, maxY;
    for (final stroke in strokes) {
      for (final p in stroke.points) {
        minX = minX == null ? p.x : math.min(minX, p.x);
        maxX = maxX == null ? p.x : math.max(maxX, p.x);
        minY = minY == null ? p.y : math.min(minY, p.y);
        maxY = maxY == null ? p.y : math.max(maxY, p.y);
      }
    }
    if (minX == null) return 0;
    return math.max(maxX! - minX, maxY! - minY!);
  }

  /// True when the child really tried: enough visible ink, not a stray tap.
  static bool isRealAttempt(List<Stroke> strokes, {bool word = false}) {
    if (strokes.isEmpty) return false;
    final ink = inkLength(strokes);
    if (word) return ink >= minWordInk;
    return ink >= minLetterInk && inkExtent(strokes) >= minLetterExtent;
  }

  /// One gentle, positive tip from the real stroke geometry, or null.
  ///
  /// Only clearly low partial checks produce a tip. Nothing here is a grade.
  static String? gentleTip(WritingEvaluation? evaluation) {
    if (evaluation == null) return null;
    if (evaluation.mirrored) {
      return 'Tipp: Schau, in welche Richtung der Buchstabe zeigt.';
    }
    if (evaluation.startPointScore < .45) {
      return 'Tipp: Beginne beim grünen Startpunkt.';
    }
    if (evaluation.directionScore < .45) {
      return 'Tipp: Folge den kleinen Pfeilen auf der Spur.';
    }
    if (evaluation.coverageScore < .45) {
      return 'Tipp: Fahre die ganze Spur bis zum Ende nach.';
    }
    return null;
  }

  static const _praise = <String>[
    'Super geübt!',
    'Toll gemacht!',
    'Prima, weiter so!',
    'Klasse geschrieben!',
  ];

  /// Rotating praise for a real attempt. [attempt] starts at 0.
  static String praise(int attempt) => _praise[attempt.abs() % _praise.length];
}
