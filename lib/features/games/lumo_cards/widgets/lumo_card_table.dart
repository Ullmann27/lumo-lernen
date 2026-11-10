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

import 'lumo_cards_parlor.dart';

class LumoCardTable extends StatefulWidget {
  const LumoCardTable({
    super.key,
    required this.child,
    this.reduceMotion = false,
  });
  final Widget child;
  final bool reduceMotion;

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
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant LumoCardTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.reduceMotion || MediaQuery.disableAnimationsOf(context)) {
      _dustCtrl.stop();
      _dustCtrl.value = 0;
    } else if (!_dustCtrl.isAnimating) {
      _dustCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _dustCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nachtwelt wie in der Referenz: Szene im Hintergrund, darüber ein runder
    // Holztisch in der Mitte.
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              key: ValueKey('cards-parlor-backdrop'),
              painter: LumoCardsParlorPainter(),
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
                    const Color(0xFFFFE08A).withOpacity(0.22),
                    const Color(0xFFE8C45A).withOpacity(0.08),
                    const Color(0xFFE8C45A).withOpacity(0.0),
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
    );
  }
}

/// Runder Holztisch (Draufsicht leicht schräg) mit warmen Holzringen,
/// auf dem Nachzieh- und Ablagestapel liegen.
class LumoRoundTablePainter extends CustomPainter {
  const LumoRoundTablePainter();

  Path _top(
      Offset center, double nearW, double farW, double topY, double botY) {
    return Path()
      ..moveTo(center.dx - farW / 2, topY)
      ..quadraticBezierTo(center.dx, topY - 10, center.dx + farW / 2, topY)
      ..cubicTo(
        center.dx + farW / 2 + 6,
        (topY + botY) / 2,
        center.dx + nearW / 2 + 4,
        botY - 8,
        center.dx + nearW / 2,
        botY,
      )
      ..quadraticBezierTo(center.dx, botY + 16, center.dx - nearW / 2, botY)
      ..cubicTo(
        center.dx - nearW / 2 - 4,
        botY - 8,
        center.dx - farW / 2 - 6,
        (topY + botY) / 2,
        center.dx - farW / 2,
        topY,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height * .52);
    final nearW =
        math.min(math.min(size.width * .98, 640.0), size.height * 1.7);
    final farW = nearW * 0.70;
    final topY = center.dy - nearW * 0.16;
    final botY = center.dy + nearW * 0.22;
    final top = _top(center, nearW, farW, topY, botY);
    final rim = _top(
      center.translate(0, 16),
      nearW * 1.02,
      farW * 1.01,
      topY + 8,
      botY + 18,
    );

    canvas.drawPath(
      rim,
      Paint()
        ..color = const Color(0x99020A24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(rim, Paint()..color = const Color(0xFF2A160C));
    canvas.drawPath(
      top,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.12, -0.45),
          radius: 1.05,
          colors: const [
            Color(0xFF8A5A32),
            Color(0xFF6A3E22),
            Color(0xFF4A2814),
            Color(0xFF2A160C),
          ],
          stops: const [0, .42, .78, 1],
        ).createShader(Rect.fromLTRB(
          center.dx - nearW / 2,
          topY - 12,
          center.dx + nearW / 2,
          botY + 18,
        )),
    );
    canvas.drawPath(
      top,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 0.55,
          colors: const [Color(0x55FFD27A), Color(0x004A2814)],
        ).createShader(Rect.fromLTRB(
          center.dx - farW / 2,
          topY,
          center.dx + farW / 2,
          botY,
        )),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x668A5A28);
    for (final scale in <double>[.86, .70, .52, .34]) {
      canvas.drawPath(
        _top(center, nearW * scale, farW * scale, topY + (1 - scale) * 10,
            botY - (1 - scale) * 12),
        ring,
      );
    }
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xFF2A160C),
    );
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xE6C4963C),
    );
  }

  @override
  bool shouldRepaint(LumoRoundTablePainter oldDelegate) => false;
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
