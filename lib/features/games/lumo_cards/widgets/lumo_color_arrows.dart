// ════════════════════════════════════════════════════════════════════════
// LUMO COLOR ARROWS — kleine farbige Dreiecke um den Discard-Pile
// ════════════════════════════════════════════════════════════════════════
// Nach Heinz' Mockup: 4 kleine farbige Dreiecke (links / rechts / oben /
// unten) um die Spielfeld-Arena zeigen die aktive Farbe an. Die Pfeile
// in der aktiven Farbe leuchten, die anderen sind gedimmt.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';

class LumoColorArrows extends StatelessWidget {
  const LumoColorArrows({
    super.key,
    required this.activeColor,
    this.size = 280,
    required this.child,
  });

  final LumoCardColor activeColor;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Auf knappen Geraeten skaliert FittedBox die ganze Arena herunter,
    // damit nichts overflowt. Heinz Crash-Report 2026-05-22: 'BOTTOM
    // OVERFLOWED BY 82 PIXELS' bei fixer 320x320-Arena.
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
          // 4 Pfeile aussen herum
          Positioned(
            top: 4,
            child: _arrow(
              direction: 0, // 0° = oben (Spitze zeigt nach unten/ins Zentrum)
              color: _colorFor(LumoCardColor.purple),
              isActive: activeColor == LumoCardColor.purple,
            ),
          ),
          Positioned(
            bottom: 4,
            child: _arrow(
              direction: 2, // 180° = unten
              color: _colorFor(LumoCardColor.orange),
              isActive: activeColor == LumoCardColor.orange,
            ),
          ),
          Positioned(
            left: 4,
            child: _arrow(
              direction: 3, // 270° = links
              color: _colorFor(LumoCardColor.blue),
              isActive: activeColor == LumoCardColor.blue,
            ),
          ),
          Positioned(
            right: 4,
            child: _arrow(
              direction: 1, // 90° = rechts
              color: _colorFor(LumoCardColor.green),
              isActive: activeColor == LumoCardColor.green,
            ),
          ),
            // Mittelteil (Draw + Discard)
            child,
          ],
        ),
      ),
    );
  }

  Widget _arrow({
    required int direction,
    required Color color,
    required bool isActive,
  }) {
    final opacity = isActive ? 1.0 : 0.32;
    final glow = isActive
        ? [
            BoxShadow(
              color: color.withOpacity(0.65),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ]
        : <BoxShadow>[];
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: glow,
        ),
        child: Transform.rotate(
          angle: direction * 1.5708, // 90° steps
          child: CustomPaint(
            painter: _ArrowPainter(color: color),
          ),
        ),
      ),
    );
  }

  static Color _colorFor(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return const Color(0xFFFF7A2F);
      case LumoCardColor.purple:
        return const Color(0xFF7C3AED);
      case LumoCardColor.blue:
        return const Color(0xFF2563EB);
      case LumoCardColor.green:
        return const Color(0xFF059669);
    }
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height * 0.20)
      ..lineTo(size.width * 0.85, size.height * 0.80)
      ..lineTo(size.width * 0.15, size.height * 0.80)
      ..close();
    canvas.drawPath(path, paint);

    // Weisser Rand fuer Premium-Look
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
