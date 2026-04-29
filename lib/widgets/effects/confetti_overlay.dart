import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Konfetti-Explosion bei richtigen Antworten / Erfolgen.
///
/// Wirft 60 Partikel (Sterne, Herzen, Kreise) vom Ursprungspunkt nach oben/außen,
/// Schwerkraft zieht sie nach unten, Rotation läuft, Alpha fadet aus.
/// Selbst-zerstörend nach Animation-Ende.
///
/// Aufruf via [ConfettiOverlay.fire]:
/// ```
/// ConfettiOverlay.fire(context, origin: Offset(300, 400));
/// ```
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.origin,
    required this.onDone,
    this.particleCount = 60,
    this.duration = const Duration(milliseconds: 1600),
    this.colors,
  });

  final Offset origin;
  final VoidCallback onDone;
  final int particleCount;
  final Duration duration;
  final List<Color>? colors;

  /// Feuert eine Konfetti-Salve über die gesamte App ab.
  /// Verwendet einen OverlayEntry, der sich nach Ende selbst entfernt.
  static void fire(
    BuildContext context, {
    required Offset origin,
    int particleCount = 60,
    List<Color>? colors,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: ConfettiOverlay(
          origin: origin,
          particleCount: particleCount,
          colors: colors,
          onDone: () {
            entry.remove();
          },
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rng = math.Random();

  static const _defaultColors = [
    Color(0xFFFF7A2F), // orange
    Color(0xFFFFB800), // gold
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // purple
    Color(0xFF10A894), // teal
    Color(0xFFFFD166), // light gold
  ];

  @override
  void initState() {
    super.initState();
    final colors = widget.colors ?? _defaultColors;
    _particles = List.generate(widget.particleCount, (i) {
      // Streuwinkel nach oben, ±90° vom Vertikal
      final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * math.pi * 1.4;
      final speed = 380.0 + _rng.nextDouble() * 280.0;
      return _Particle(
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: colors[_rng.nextInt(colors.length)],
        shape: _Shape.values[_rng.nextInt(_Shape.values.length)],
        size: 8.0 + _rng.nextDouble() * 10.0,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 8.0,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDone();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            t: _controller.value,
            origin: widget.origin,
          ),
        ),
      ),
    );
  }
}

enum _Shape { star, heart, circle, square }

class _Particle {
  _Particle({
    required this.velocity,
    required this.color,
    required this.shape,
    required this.size,
    required this.rotationSpeed,
  });
  final Offset velocity;
  final Color color;
  final _Shape shape;
  final double size;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.t,
    required this.origin,
  });

  final List<_Particle> particles;
  final double t; // 0..1
  final Offset origin;

  static const _gravity = 1100.0; // px/s²

  @override
  void paint(Canvas canvas, Size size) {
    // Approximation: t maps to seconds based on duration ~1.6s
    final timeSec = t * 1.6;

    for (final p in particles) {
      // Position via classical physics: x = x0 + v*t, y = y0 + v*t + 0.5*g*t²
      final dx = origin.dx + p.velocity.dx * timeSec;
      final dy = origin.dy + p.velocity.dy * timeSec + 0.5 * _gravity * timeSec * timeSec;

      // Fade out in second half
      final opacity = (1.0 - (t - 0.4).clamp(0.0, 0.6) / 0.6).clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;

      final paint = Paint()..color = p.color.withOpacity(opacity);
      final rotation = p.rotationSpeed * timeSec;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);

      switch (p.shape) {
        case _Shape.star:
          _drawStar(canvas, paint, p.size);
          break;
        case _Shape.heart:
          _drawHeart(canvas, paint, p.size);
          break;
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _Shape.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
              const Radius.circular(2),
            ),
            paint,
          );
          break;
      }
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
      final angle = -math.pi / 2 + i * math.pi / points;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Paint paint, double size) {
    final s = size / 2;
    final path = Path()
      ..moveTo(0, s * 0.4)
      ..cubicTo(-s * 1.1, -s * 0.3, -s * 0.9, -s * 0.95, 0, -s * 0.3)
      ..cubicTo(s * 0.9, -s * 0.95, s * 1.1, -s * 0.3, 0, s * 0.4)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
