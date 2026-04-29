import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// Animierter Mesh-Gradient-Hintergrund.
///
/// 4 farbige "Wolken" treiben extrem langsam (60s/Zyklus).
/// Subtil aber lebendig — gibt der App den Premium-Touch.
class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  final Widget child;
  final List<Color>? colors;

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        const [
          Color(0xFFFFE4C0), // peach
          Color(0xFFFFF4DC), // vanilla
          Color(0xFFFFD9B5), // light apricot
          Color(0xFFFFEED5), // cream
        ];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MeshPainter(t: _ctrl.value, colors: colors),
                ),
              ),
              if (child != null) child,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.t, required this.colors});
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Basis-Farbe als Hintergrund
    final bgPaint = Paint()..color = LumoColors.appBg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 4 Blobs, jeder mit eigener Drift-Bahn (Lissajous-artig)
    final blobs = [
      _BlobPath(0, 0.4, 0.7, 1.1, 0.55),
      _BlobPath(1, 0.6, 0.3, 0.9, 0.45),
      _BlobPath(2, 0.7, 0.6, 1.3, 0.50),
      _BlobPath(3, 0.3, 0.5, 0.7, 0.50),
    ];

    final w = size.width;
    final h = size.height;
    final radius = math.max(w, h) * 0.55;

    for (int i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      final phase = t * 2 * math.pi;

      // Lissajous-Bewegung
      final x = w * (b.cx + b.ax * math.sin(phase * b.fx + i * 1.7));
      final y = h * (b.cy + b.ay * math.cos(phase * b.fy + i * 2.3));

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i % colors.length].withValues(alpha: 0.85),
            colors[i % colors.length].withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(x, y),
          radius: radius,
        ));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}

class _BlobPath {
  /// cx, cy = Mittelpunkt der Bahn (relativ zur Canvas, 0..1)
  /// ax, ay = Amplitude der Bewegung
  /// fx, fy = Frequenzen (für Lissajous)
  const _BlobPath(
    int seed,
    this.cx,
    this.cy,
    this.fx,
    this.fy, {
    this.ax = 0.20,
    this.ay = 0.18,
  });
  final double cx;
  final double cy;
  final double fx;
  final double fy;
  final double ax;
  final double ay;
}
