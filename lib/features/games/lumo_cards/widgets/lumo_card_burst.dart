// ════════════════════════════════════════════════════════════════════════
// LUMO CARD BURST — Partikel-Schwarm zentral ueber einer Stelle
// ════════════════════════════════════════════════════════════════════════
// Tier 6 aus dem approvten Plan (Heinz 2026-05-23).
//
// Wird ueber dem Discard-Pile gespawnt wenn +2 oder +4 gespielt wird.
// 24 farbige Partikel platzen radial nach aussen, drehen sich und
// faden raus. Bei +2 (storm) blau-lila, bei +4 (thunder) regenbogen.
//
// Architektur:
//   - SingleTickerProviderStateMixin (ein AnimationController, dispose-
//     stabil)
//   - CustomPainter fuer die Partikel (keine Layout-Aktualisierung)
//   - IgnorePointer + onDone-Callback fuer Auto-Remove im Parent
//   - Kein AnimatedSwitcher (frueher Crash-Quelle)
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Farb-Palette des Burst.
enum LumoBurstStyle {
  /// +2 Sternenregen - blau/lila Sturm
  storm,

  /// +4 Super-Sternenregen - regenbogen
  thunder,

  /// Generischer Klatsch beim Karten-Legen
  cardSlap,
}

class LumoCardBurst extends StatefulWidget {
  const LumoCardBurst({
    super.key,
    this.style = LumoBurstStyle.thunder,
    this.duration = const Duration(milliseconds: 900),
    this.particleCount = 24,
    this.onDone,
  });

  final LumoBurstStyle style;
  final Duration duration;
  final int particleCount;
  final VoidCallback? onDone;

  @override
  State<LumoCardBurst> createState() => _LumoCardBurstState();
}

class _LumoCardBurstState extends State<LumoCardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  bool _completedSignaled = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final rng = math.Random();
    _particles = List<_Particle>.generate(
      widget.particleCount,
      (_) => _Particle.random(rng, _paletteFor(widget.style)),
    );
    _ctrl.forward().whenComplete(() {
      if (_completedSignaled || !mounted) return;
      _completedSignaled = true;
      widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              painter: _BurstPainter(_ctrl.value, _particles),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  static List<Color> _paletteFor(LumoBurstStyle style) {
    switch (style) {
      case LumoBurstStyle.storm:
        return const [
          Color(0xFF38BDF8),
          Color(0xFF2D7BFF),
          Color(0xFF7C3AED),
          Color(0xFFFFFFFF),
        ];
      case LumoBurstStyle.thunder:
        return const [
          Color(0xFFFF4D4F),
          Color(0xFFFFC83D),
          Color(0xFF35C759),
          Color(0xFF2D7BFF),
          Color(0xFF7C3AED),
          Color(0xFFFFFFFF),
        ];
      case LumoBurstStyle.cardSlap:
        return const [
          Color(0xFFFFE0B8),
          Color(0xFFFFFFFF),
        ];
    }
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.color,
    required this.size,
    required this.spinSpeed,
    required this.shape,
  });

  factory _Particle.random(math.Random rng, List<Color> palette) {
    return _Particle(
      // Voll-Kreis (0..2pi)
      angle: rng.nextDouble() * math.pi * 2,
      // Reichweite 60..140 px - kleiner Burst, nicht uebertrieben
      distance: 60 + rng.nextDouble() * 80,
      color: palette[rng.nextInt(palette.length)],
      size: 6.0 + rng.nextDouble() * 8.0,
      spinSpeed: -4 + rng.nextDouble() * 8,
      shape: rng.nextInt(3), // 0=rect, 1=circle, 2=diamond
    );
  }

  final double angle;
  final double distance;
  final Color color;
  final double size;
  final double spinSpeed;
  final int shape;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.particles);

  final double t; // 0..1
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // easeOutCubic: Partikel schiessen schnell raus, verlangsamen am Ende.
    final eased = 1 - math.pow(1 - t, 3).toDouble();
    final fadeOut = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    final paint = Paint();
    for (final p in particles) {
      final dist = p.distance * eased;
      final x = cx + math.cos(p.angle) * dist;
      final y = cy + math.sin(p.angle) * dist;
      paint.color = p.color.withOpacity(fadeOut.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spinSpeed);
      switch (p.shape) {
        case 0:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          );
          canvas.drawRect(rect, paint);
          break;
        case 1:
          canvas.drawCircle(Offset.zero, p.size * 0.40, paint);
          break;
        case 2:
          final s = p.size * 0.5;
          final path = Path()
            ..moveTo(0, -s)
            ..lineTo(s, 0)
            ..lineTo(0, s)
            ..lineTo(-s, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
