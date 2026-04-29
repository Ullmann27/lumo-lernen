import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// Radialer Stern-Burst — kleine Sterne fliegen aus einem Punkt nach außen.
/// Ideal beim Tap auf ein Element, um eine Reaktion zu visualisieren.
class StarBurst extends StatefulWidget {
  const StarBurst({
    super.key,
    required this.origin,
    required this.onDone,
    this.starCount = 7,
    this.color = LumoColors.gold,
    this.spreadRadius = 90,
  });

  final Offset origin;
  final VoidCallback onDone;
  final int starCount;
  final Color color;
  final double spreadRadius;

  static void show(
    BuildContext context, {
    required Offset origin,
    int starCount = 7,
    Color color = LumoColors.gold,
    double spreadRadius = 90,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: StarBurst(
          origin: origin,
          starCount: starCount,
          color: color,
          spreadRadius: spreadRadius,
          onDone: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  late final List<double> _angles;

  @override
  void initState() {
    super.initState();
    _angles = List.generate(
      widget.starCount,
      (i) => -math.pi / 2 + (i / widget.starCount) * 2 * math.pi,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _StarBurstPainter(
            origin: widget.origin,
            t: _ctrl.value,
            angles: _angles,
            color: widget.color,
            spreadRadius: widget.spreadRadius,
          ),
        ),
      ),
    );
  }
}

class _StarBurstPainter extends CustomPainter {
  _StarBurstPainter({
    required this.origin,
    required this.t,
    required this.angles,
    required this.color,
    required this.spreadRadius,
  });

  final Offset origin;
  final double t;
  final List<double> angles;
  final Color color;
  final double spreadRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final distance = Curves.easeOutCubic.transform(t) * spreadRadius;
    // Größe wächst kurz, dann schrumpft
    final sizeT = t < 0.4 ? t / 0.4 : 1.0 - ((t - 0.4) / 0.6);
    final starSize = 8.0 + 12.0 * sizeT;
    final opacity = 1.0 - Curves.easeIn.transform(t);

    if (opacity <= 0.01) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (final angle in angles) {
      final x = origin.dx + math.cos(angle) * distance;
      final y = origin.dy + math.sin(angle) * distance;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + t * math.pi);
      _drawStar(canvas, paint, starSize);
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    const points = 5;
    final outer = size / 2;
    final inner = outer * 0.42;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final px = math.cos(a) * r;
      final py = math.sin(a) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarBurstPainter old) => old.t != t;
}
