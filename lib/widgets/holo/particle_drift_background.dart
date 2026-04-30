import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// Partikel-Drift fuer schwebende Hologramm-Flaechen und die Lumo-Buehne.
///
/// Erzeugt eine Wolke von kleinen, weich leuchtenden Lichtpunkten, die
/// langsam und organisch durch den Bereich treiben. Die Partikel sind
/// deterministisch positioniert (gleicher Seed = gleiche Bahn), damit
/// das Bild ueber App-Sessions hinweg konsistent wirkt.
///
/// Standalone-Primitiv. Wird in dieser Phase nirgends importiert.
/// Spaetere Commits koennen es als Hintergrund-Layer in HoloSurface
/// und in der Lumo-Buehne einbinden.
class ParticleDriftBackground extends StatefulWidget {
  const ParticleDriftBackground({
    super.key,
    this.particleCount = 14,
    this.color = LumoColors.gold,
    this.size = const Size(280, 320),
    this.opacity = 0.45,
    this.minDotSize = 1.5,
    this.maxDotSize = 3.5,
    this.driftSeconds = 12,
    this.seed = 7,
  });

  /// Anzahl der Partikel. Mehr als 20 ist auf Mid-Range-Android nicht
  /// ratsam.
  final int particleCount;

  /// Grundfarbe der Partikel. Variation entsteht durch Helligkeit und
  /// Opazitaet pro Partikel.
  final Color color;

  /// Bezugsgroesse fuer Partikel-Verteilung.
  final Size size;

  /// Maximale Opazitaet pro Partikel. Die tatsaechliche Opazitaet wird
  /// pro Partikel zufaellig zwischen 0.3 und diesem Wert gewaehlt.
  final double opacity;

  final double minDotSize;
  final double maxDotSize;

  /// Zyklus-Dauer der Drift-Bewegung.
  final int driftSeconds;

  /// Random-Seed fuer deterministische Verteilung.
  final int seed;

  @override
  State<ParticleDriftBackground> createState() =>
      _ParticleDriftBackgroundState();
}

class _ParticleDriftBackgroundState extends State<ParticleDriftBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.driftSeconds),
    )..repeat();

    final rng = math.Random(widget.seed);
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        startX: rng.nextDouble(),
        startY: rng.nextDouble(),
        amplitudeX: 0.05 + rng.nextDouble() * 0.15,
        amplitudeY: 0.06 + rng.nextDouble() * 0.18,
        size: widget.minDotSize +
            rng.nextDouble() * (widget.maxDotSize - widget.minDotSize),
        opacity: 0.3 + rng.nextDouble() * (widget.opacity - 0.3),
        phase: rng.nextDouble() * math.pi * 2,
        speedX: 0.5 + rng.nextDouble() * 0.7,
        speedY: 0.4 + rng.nextDouble() * 0.5,
      );
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          return CustomPaint(
            size: widget.size,
            painter: _ParticlePainter(
              particles: _particles,
              t: reduced ? 0.0 : _drift.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.startX,
    required this.startY,
    required this.amplitudeX,
    required this.amplitudeY,
    required this.size,
    required this.opacity,
    required this.phase,
    required this.speedX,
    required this.speedY,
  });

  final double startX;
  final double startY;
  final double amplitudeX;
  final double amplitudeY;
  final double size;
  final double opacity;
  final double phase;
  final double speedX;
  final double speedY;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.t,
    required this.color,
  });

  final List<_Particle> particles;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final basePhase = t * 2 * math.pi;

    for (final p in particles) {
      final dx = (p.startX +
              p.amplitudeX * math.sin(basePhase * p.speedX + p.phase))
          .clamp(0.0, 1.0);
      final dy = (p.startY +
              p.amplitudeY * math.cos(basePhase * p.speedY + p.phase * 0.7))
          .clamp(0.0, 1.0);

      final cx = dx * size.width;
      final cy = dy * size.height;

      // Inner solid dot
      final corePaint = Paint()
        ..color = color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), p.size, corePaint);

      // Soft outer halo
      final haloPaint = Paint()
        ..color = color.withOpacity(p.opacity * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx, cy), p.size * 2.2, haloPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
