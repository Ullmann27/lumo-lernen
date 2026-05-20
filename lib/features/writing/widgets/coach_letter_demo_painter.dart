// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - LETTER DEMO PAINTER (Phase 3)
// ════════════════════════════════════════════════════════════════════════
//
// Zeichnet einen Buchstaben animiert nach dem Template. Wird vom
// Canvas im Demo-Modus aufgerufen (progress 0..1).
//
// Phase 3: nur fuer die in CoachLetterTemplates definierten Buchstaben.
// Bei unbekanntem Buchstaben wird nichts gezeichnet (silent skip).

import 'package:flutter/material.dart';

import '../data/coach_letter_templates.dart';

class CoachLetterDemoPainter {
  const CoachLetterDemoPainter();

  /// Zeichnet `letter` in `size` mit Fortschritt `progress` (0..1).
  void paintLetter({
    required Canvas canvas,
    required Size size,
    required String letter,
    required double progress,
  }) {
    final tpl = CoachLetterTemplates.forLetter(letter);
    if (tpl == null) return;
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    // Skalierung: Template-Koordinaten -> Canvas-Koordinaten.
    // Wir nutzen einen zentrierten 65%-Bereich der Canvas.
    final scaleX = size.width * 0.6 / tpl.viewBoxWidth;
    final scaleY = size.height * 0.7 / tpl.viewBoxHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - tpl.viewBoxWidth * scale) / 2;
    final offsetY = (size.height - tpl.viewBoxHeight * scale) / 2;

    final paint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Strokes nacheinander malen.
    final totalStrokes = tpl.strokes.length;
    final strokeShare = 1.0 / totalStrokes;

    for (var i = 0; i < totalStrokes; i++) {
      final strokeStart = i * strokeShare;
      final strokeEnd = (i + 1) * strokeShare;
      if (clamped <= strokeStart) break;
      final localProgress = clamped >= strokeEnd
          ? 1.0
          : (clamped - strokeStart) / strokeShare;
      _drawStroke(
        canvas,
        paint,
        tpl.strokes[i].points,
        localProgress,
        scale,
        offsetX,
        offsetY,
      );
    }
  }

  void _drawStroke(
    Canvas canvas,
    Paint paint,
    List<(double, double)> points,
    double progress,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    if (points.length < 2) return;
    final segments = points.length - 1;
    final visibleSegments = (segments * progress).clamp(0.0, segments.toDouble());
    final fullCount = visibleSegments.floor();
    final partial = visibleSegments - fullCount;

    final path = Path();
    final first = points.first;
    path.moveTo(first.$1 * scale + offsetX, first.$2 * scale + offsetY);
    for (var i = 1; i <= fullCount && i < points.length; i++) {
      path.lineTo(
        points[i].$1 * scale + offsetX,
        points[i].$2 * scale + offsetY,
      );
    }
    if (partial > 0 && fullCount + 1 < points.length) {
      final a = points[fullCount];
      final b = points[fullCount + 1];
      final px = a.$1 + (b.$1 - a.$1) * partial;
      final py = a.$2 + (b.$2 - a.$2) * partial;
      path.lineTo(px * scale + offsetX, py * scale + offsetY);
    }
    canvas.drawPath(path, paint);

    // Startpunkt-Pfeil (kleine Markierung am Anfang)
    if (progress > 0 && progress < 0.95) {
      final startPaint = Paint()
        ..color = const Color(0xFFF97316).withOpacity(0.7);
      canvas.drawCircle(
        Offset(first.$1 * scale + offsetX, first.$2 * scale + offsetY),
        6,
        startPaint,
      );
    }
  }
}
