import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_motion.dart';

/// A quiet, segmented light rail. Its value always comes from the lesson;
/// the short fill transition cannot award points or advance an exercise.
class LumoLessonProgress extends StatelessWidget {
  const LumoLessonProgress({
    super.key,
    required this.value,
    required this.totalTasks,
    this.reduceMotion = false,
  });

  final double value;
  final int totalTasks;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final quiet = reduceMotion || LumoMotion.reduced(context);
    return Semantics(
      label: 'Lernfortschritt',
      value: '${(target * 100).round()} Prozent',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(quiet),
          tween: Tween(end: target),
          duration: quiet ? Duration.zero : LumoMotion.value,
          curve: LumoMotion.enter,
          builder: (context, progress, _) => SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: _LessonRailPainter(
                value: progress,
                segments: totalTasks.clamp(1, 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonRailPainter extends CustomPainter {
  const _LessonRailPainter({required this.value, required this.segments});

  final double value;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const gap = 3.0;
    final count = math.min(segments, math.max(1, (size.width / 12).floor()));
    final width = (size.width - gap * (count - 1)) / count;
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(i * (width + gap), 0, width, size.height);
      final cell = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(cell, paint..color = const Color(0xFF142F54));
      canvas.drawRRect(
        cell.deflate(.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF315677),
      );
      final fill = (value * count - i).clamp(0.0, 1.0);
      if (fill <= 0) continue;
      canvas.save();
      canvas.clipRRect(cell);
      final filled = Rect.fromLTWH(rect.left, 0, width * fill, size.height);
      canvas.drawRect(
        filled,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB8F6FF),
              LumoVisualTokens.cyan,
              Color(0xFF218FC6),
            ],
          ).createShader(rect),
      );
      canvas.drawLine(
        Offset(rect.left + 2, 2),
        Offset(filled.right, 2),
        Paint()
          ..color = const Color(0xBFFFFFFF)
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LessonRailPainter oldDelegate) =>
      value != oldDelegate.value || segments != oldDelegate.segments;
}
