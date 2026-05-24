// ════════════════════════════════════════════════════════════════════════
// LUMO CARD TABLE — Premium-Edition (hochmodern)
// ════════════════════════════════════════════════════════════════════════
// Hochwertiger Spieltisch mit:
//  • Tiefem Velvet-Gradient (warm Amber zu deepem Bordeaux)
//  • Sanfte Vignette an den Raendern fuer Buehnen-Effekt
//  • Animierte Light-Dust-Partikel (sehr subtil, langsam schwebend)
//  • Noise/Texture-Overlay fuer Stoff-Optik
//  • Deterministische Sterne (kein Flackern bei Rebuild)
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LumoCardTable extends StatefulWidget {
  const LumoCardTable({super.key, required this.child});
  final Widget child;

  @override
  State<LumoCardTable> createState() => _LumoCardTableState();
}

class _LumoCardTableState extends State<LumoCardTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _dustCtrl;

  @override
  void initState() {
    super.initState();
    // Sehr langsame Animation - dust schwebt 20 Sekunden lang.
    _dustCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _dustCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // ── LUMO CARDS Arena (lila, nach Mockup Bild 3) ──
      // Radialer Verlauf: warmes Zentrum (Spotlight) -> tiefes Lila Rand.
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(0xFF6B3FA0), // warmes Lila-Zentrum
            Color(0xFF3D2270), // mittleres Lila
            Color(0xFF1E1240), // tiefes Lila Rand
          ],
          stops: [0.0, 0.5, 1.0],
          radius: 1.1,
          center: Alignment(0, -0.10),
        ),
      ),
      child: Stack(
        children: [
          // ── Layer 1: Noise/Texture-Overlay (Stoff-Optik) ──
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TableNoisePainter(),
              ),
            ),
          ),

          // ── Layer 2: Vignette an den Raendern ──
          // Dunkler werden zu den Ecken hin - macht den Tisch zur "Buehne".
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.32),
                    ],
                    stops: const [0.55, 0.85, 1.0],
                    radius: 1.2,
                    center: Alignment.center,
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3: Animierte Lichtpartikel (Dust) ──
          // Langsam schwebende warme Punkte - wie Sonnenstaub im Licht.
          // RepaintBoundary (Tier 1 Foundation 2026-05-23) isoliert die
          // permanente Repaint-Loop vom Rest des Tischs.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _dustCtrl,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _LightDustPainter(_dustCtrl.value),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Layer 4: Deterministisches Sterne-Muster (statisch) ──
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _StaticSparklesPainter(),
              ),
            ),
          ),

          // ── Layer 5: Spotlight um die Tisch-Mitte (Tier 4 3D-Optik) ──
          // Statisches warmes Glow das Draw + Discard aus dem dunkleren
          // Tisch heraushebt - macht das Spielfeld zur 'Buehne'. Reine
          // BoxDecoration mit RadialGradient, keine Animation, kein
          // CustomPainter -> null Performance-Kosten.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFE0B8).withOpacity(0.22),
                      const Color(0xFFFFE0B8).withOpacity(0.08),
                      const Color(0xFFFFE0B8).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.25, 0.55],
                    radius: 0.42,
                    center: const Alignment(0, -0.05),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          widget.child,
        ],
      ),
    );
  }
}

/// Sehr feines Noise-Pattern fuer Stoff-Optik.
class _TableNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Sehr fein - kaum sichtbar, aber gibt der Flaeche Charakter.
    // Pseudo-random aber deterministisch (kein flicker).
    final rng = math.Random(42);
    for (int i = 0; i < 280; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final opacity = 0.02 + rng.nextDouble() * 0.04;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(_TableNoisePainter old) => false;
}

/// Statische warme Sparkles - wie Kerzenlicht-Reflexe auf dem Tisch.
class _StaticSparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFE0B8).withOpacity(0.22);
    // Deterministische Positionen.
    const points = [
      Offset(60, 80),
      Offset(220, 140),
      Offset(380, 90),
      Offset(140, 260),
      Offset(310, 320),
      Offset(420, 240),
      Offset(80, 460),
      Offset(260, 520),
      Offset(390, 560),
      Offset(180, 720),
      Offset(450, 380),
      Offset(120, 610),
    ];
    for (final p in points) {
      final cx = (p.dx % size.width).clamp(8.0, size.width - 8);
      final cy = (p.dy % size.height).clamp(8.0, size.height - 8);
      canvas.drawCircle(Offset(cx, cy), 2.8, paint);
    }
  }

  @override
  bool shouldRepaint(_StaticSparklesPainter old) => false;
}

/// Animierte Lichtpartikel - schweben langsam diagonal nach oben rechts.
class _LightDustPainter extends CustomPainter {
  _LightDustPainter(this.t);
  final double t; // 0..1 - aktueller Animations-Fortschritt

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFF8E8).withOpacity(0.40);
    // 18 Partikel, langsam schwebend.
    final rng = math.Random(1337);
    for (int i = 0; i < 18; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      // Diagonale Schwebebewegung - nach oben + leicht rechts.
      final phase = rng.nextDouble();
      final localT = (t + phase) % 1.0;
      final driftY = -localT * size.height * 0.25;
      final driftX = math.sin(localT * math.pi * 2) * 14;
      final x = (baseX + driftX).clamp(2.0, size.width - 2);
      final y = (baseY + driftY).clamp(2.0, size.height - 2);
      // Fade in/out an den Enden.
      final fade = math.sin(localT * math.pi); // 0 → 1 → 0
      paint.color = const Color(0xFFFFF8E8).withOpacity(0.10 + fade * 0.35);
      final radius = 1.2 + fade * 1.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_LightDustPainter old) => old.t != t;
}
