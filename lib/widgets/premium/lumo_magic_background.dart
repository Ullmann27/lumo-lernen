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
    // 2026-06-03 Modernisierung (Heinz: 'sehe keine Veraenderungen'):
    // Wolken-Opacity 0.35 -> 0.60 + leichter Pink-Tint damit sie gegen
    // den neuen Sunset-Verlauf sichtbar sind statt verschwimmen.
    final cloudPaint = Paint()
      ..color = const Color(0xFFFFF0F5).withOpacity(0.60 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
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
    // 2026-06-03 Modernisierung: Sterne deutlich aufgedreht.
    //   Farbe: gold (0xFFFCD34D) -> weiss + warm-gelber Halo damit sie
    //   gegen den neuen Magenta-Lila-Verlauf knackig hervorstechen.
    //   Opacity 0.3-0.8 -> 0.7-1.0.
    //   Groesse 0.8x-1.2x -> 1.4x-2.4x.
    //   Plus: weicher Halo-Pass davor fuer Glow-Effekt.
    for (final s in stars) {
      final twinkle =
          (math.sin(progress * 2 * math.pi * s.speed + s.phase) + 1) / 2;
      final opacity = (0.7 + twinkle * 0.3).clamp(0.0, 1.0) * intensity;
      final size_ = s.size * (1.4 + twinkle * 1.0);
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      // Halo-Pass (weicher gelber Glow drumherum)
      final haloPaint = Paint()
        ..color = const Color(0xFFFCD34D).withOpacity(opacity * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), size_ * 1.6, haloPaint);
      // Stern selbst in Weiss fuer maximalen Kontrast
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity);
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
