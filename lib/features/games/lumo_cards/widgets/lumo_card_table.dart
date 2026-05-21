// ════════════════════════════════════════════════════════════════════════
// LUMO CARD TABLE — warmer Spieltisch-Hintergrund
// ════════════════════════════════════════════════════════════════════════
// Dunkler warmer Holz/Stoff-Gradient mit dezentem Vignette-Effekt.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class LumoCardTable extends StatelessWidget {
  const LumoCardTable({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFFFFE4C2), Color(0xFFD6841B)],
          radius: 1.05,
          center: Alignment(0, -0.15),
        ),
      ),
      child: Stack(
        children: [
          // Dezentes Sternenmuster im Hintergrund.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TableSparkles(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TableSparkles extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.10);
    // Fixe deterministische Positionen damit es nicht bei jedem Build neu
    // berechnet werden muss und nicht "blinkt".
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
    ];
    for (final p in points) {
      // Innerhalb der Canvas-Groesse halten.
      final cx = (p.dx % size.width).clamp(8.0, size.width - 8);
      final cy = (p.dy % size.height).clamp(8.0, size.height - 8);
      canvas.drawCircle(Offset(cx, cy), 2.4, paint);
    }
  }

  @override
  bool shouldRepaint(_TableSparkles old) => false;
}
