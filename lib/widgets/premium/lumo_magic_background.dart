// ════════════════════════════════════════════════════════════════════════
// LUMO MAGIC BACKGROUND — Lebendiger Premium-Hintergrund
// ════════════════════════════════════════════════════════════════════════
// Heinz' Auftrag: 'warmer Verlauf, dezente Stern-/Wolkenformen,
//                  minimale schwebende Deko, leichte Parallax-Bewegung'.
//
// Performance: CustomPainter ohne Bild-Assets, RepaintBoundary,
//              reduceMotion beachtet.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';

class LumoMagicBackground extends StatefulWidget {
  const LumoMagicBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.starCount = 18,
  });

  final Widget child;

  /// 0.0 = sehr ruhig, 1.0 = normal, 1.5 = lebhafter.
  final double intensity;

  /// Anzahl der Sterne. Default 18, fuer Performance reduzierbar.
  final int starCount;

  @override
  State<LumoMagicBackground> createState() => _LumoMagicBackgroundState();
}

class _LumoMagicBackgroundState extends State<LumoMagicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;
  late final List<_Cloud> _clouds;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final rng = math.Random(42); // Seed fuer konsistente Sterne
    _stars = List.generate(
      widget.starCount,
      (_) => _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2 + rng.nextDouble() * 4,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 0.3 + rng.nextDouble() * 0.7,
      ),
    );
    _clouds = List.generate(
      4,
      (i) => _Cloud(
        x: rng.nextDouble(),
        y: 0.1 + rng.nextDouble() * 0.4,
        size: 60 + rng.nextDouble() * 80,
        drift: 0.05 + rng.nextDouble() * 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LumoTokens.colors.bgMagic),
      child: Stack(
        children: [
          // Sterne + Wolken Layer
          if (!reduceMotion)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _MagicPainter(
                        stars: _stars,
                        clouds: _clouds,
                        progress: _ctrl.value,
                        intensity: widget.intensity,
                      ),
                    );
                  },
                ),
              ),
            )
          else
            // Static fallback bei reduceMotion
            Positioned.fill(
              child: CustomPaint(
                painter: _MagicPainter(
                  stars: _stars,
                  clouds: _clouds,
                  progress: 0,
                  intensity: widget.intensity * 0.5,
                ),
              ),
            ),
          // Eigentlicher Content
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });
  final double x; // 0..1 (relative position)
  final double y;
  final double size;
  final double phase;
  final double speed;
}

class _Cloud {
  _Cloud({
    required this.x,
    required this.y,
    required this.size,
    required this.drift,
  });
  final double x;
  final double y;
  final double size;
  final double drift;
}

class _MagicPainter extends CustomPainter {
  _MagicPainter({
    required this.stars,
    required this.clouds,
    required this.progress,
    required this.intensity,
  });
  final List<_Star> stars;
  final List<_Cloud> clouds;
  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Wolken zuerst (hinten)
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.35 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    for (final c in clouds) {
      final driftX = math.sin(progress * 2 * math.pi + c.x * 10) * c.drift;
      final cx = (c.x + driftX) * size.width;
      final cy = c.y * size.height;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy), width: c.size * 1.5, height: c.size * 0.6),
        cloudPaint,
      );
    }

    // Sterne (vorne, twinkling)
    for (final s in stars) {
      final twinkle =
          (math.sin(progress * 2 * math.pi * s.speed + s.phase) + 1) / 2;
      final opacity = (0.3 + twinkle * 0.5) * intensity;
      final size_ = s.size * (0.8 + twinkle * 0.4);
      final paint = Paint()
        ..color = LumoTokens.colors.gold.withOpacity(opacity);
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      _drawStar(canvas, Offset(cx, cy), size_, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = (i % 2 == 0) ? radius : radius * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MagicPainter old) => old.progress != progress;
}
