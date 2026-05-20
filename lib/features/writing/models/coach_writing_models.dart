// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - DATENMODELLE
// ════════════════════════════════════════════════════════════════════════
//
// Eigene Modelle fuer den neuen Schreibcoach, getrennt von der
// bestehenden domain/writing/. Praefix "Coach" verhindert Namens-
// kollisionen, wenn beide Welten mal nebeneinander importiert werden.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Modus des Schreibcoaches.
enum CoachWritingMode {
  singleLetter,
  wordBoxes,
  freeWord,
  sentenceLater,
}

/// Ein einzelner Punkt eines Strokes (relativ zur Zeichenflaeche).
@immutable
class CoachStrokePoint {
  const CoachStrokePoint({
    required this.x,
    required this.y,
    required this.timestampMs,
    this.pressure = 1.0,
  });

  final double x;
  final double y;
  final int timestampMs;
  final double pressure;
}

/// Ein zusammenhaengender Strich aus mehreren Punkten.
@immutable
class CoachStroke {
  const CoachStroke({
    required this.id,
    required this.points,
    required this.startedAtMs,
    required this.endedAtMs,
  });

  final String id;
  final List<CoachStrokePoint> points;
  final int startedAtMs;
  final int endedAtMs;

  bool get isEmpty => points.isEmpty;
  int get durationMs => endedAtMs - startedAtMs;

  /// Bounding-Box als (minX, minY, maxX, maxY). Wenn leer: alles 0.
  ({double minX, double minY, double maxX, double maxY}) get bounds {
    if (points.isEmpty) {
      return (minX: 0, minY: 0, maxX: 0, maxY: 0);
    }
    var minX = points.first.x;
    var minY = points.first.y;
    var maxX = points.first.x;
    var maxY = points.first.y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  /// Geschaetzte Stroke-Laenge (Summe der Punkt-zu-Punkt-Distanzen).
  double get totalLength {
    if (points.length < 2) return 0;
    var sum = 0.0;
    for (var i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      sum += math.sqrt(dx * dx + dy * dy);
    }
    return sum;
  }
}

/// Welche Art von Fehler wurde erkannt?
enum CoachLetterIssue {
  wrongLetter,
  missingStroke,
  missingCrossbar,
  notClosed,
  mirrored,
  tooSmall,
  tooLarge,
  offLine,
  unclear,
}

/// Ergebnis der Heuristik-Analyse fuer einen Buchstaben-Versuch.
@immutable
class CoachLetterAnalysisResult {
  const CoachLetterAnalysisResult({
    required this.expectedLetter,
    required this.recognizedLetter,
    required this.isCorrect,
    required this.confidence,
    required this.shapeScore,
    required this.lineScore,
    required this.sizeScore,
    required this.issues,
    required this.showDemo,
    this.messageKey = 'unclear',
  });

  final String expectedLetter;
  final String recognizedLetter;
  final bool isCorrect;

  /// 0..1
  final double confidence;
  final double shapeScore;
  final double lineScore;
  final double sizeScore;

  final List<CoachLetterIssue> issues;
  final bool showDemo;
  final String messageKey;
}

/// Welche Emotion soll Lumo beim Feedback zeigen?
enum CoachLumoEmotion {
  idle,
  think,
  point,
  cheer,
  comfort,
  talk,
}

/// Antwort des FeedbackEngines: was sagt Lumo, soll er vorzeichnen?
@immutable
class CoachWritingFeedback {
  const CoachWritingFeedback({
    required this.message,
    required this.allowRetry,
    required this.showDemo,
    required this.lumoEmotion,
    this.isCorrect = false,
    this.messageKey = 'unclear',
  });

  final String message;
  final bool allowRetry;
  final bool showDemo;
  final CoachLumoEmotion lumoEmotion;
  final bool isCorrect;
  final String messageKey;
}

/// Aufgabe fuer einen Einzelbuchstaben (Phase 2).
@immutable
class CoachLetterTask {
  const CoachLetterTask({
    required this.id,
    required this.letter,
    required this.uppercase,
    required this.prompt,
    this.allowedAttempts = 3,
  });

  final String id;
  final String letter;
  final bool uppercase;
  final String prompt;
  final int allowedAttempts;
}
