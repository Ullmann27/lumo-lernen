// ════════════════════════════════════════════════════════════════════════
// LUMO COLOR PICKER — Farbwahl nach Farbzauber-Karte
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';

class LumoColorPicker extends StatelessWidget {
  const LumoColorPicker({super.key, required this.onPick});
  final void Function(LumoCardColor) onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF12203C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8C45A), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌈', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'Waehle eine Farbe',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFF3C4),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in LumoCardColor.values) _colorButton(c),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorButton(LumoCardColor c) {
    final colors = _gradientOf(c);
    return GestureDetector(
      onTap: () => onPick(c),
      child: SizedBox(
        width: 84,
        height: 84,
        child: CustomPaint(
          painter: _ColorChoicePainter(c, colors),
          child: Center(
            child: Text(
              c.displayName,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Color(0x88000000), blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<Color> _gradientOf(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange: // -> Rot (Mockup-Palette)
        return const [Color(0xFFFF7779), Color(0xFFFF4D4F)];
      case LumoCardColor.purple: // -> Gelb
        return const [Color(0xFFFFD970), Color(0xFFFFC83D)];
      case LumoCardColor.blue: // -> Blau
        return const [Color(0xFF6FA4FF), Color(0xFF2D7BFF)];
      case LumoCardColor.green: // -> Gruen
        return const [Color(0xFF6BD98A), Color(0xFF35C759)];
    }
  }
}

class _ColorChoicePainter extends CustomPainter {
  const _ColorChoicePainter(this.color, this.fills);
  final LumoCardColor color;
  final List<Color> fills;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _shapePath(rect.deflate(3));
    canvas.drawShadow(path, fills.last.withOpacity(0.55), 8, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: fills,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFE8C45A),
    );
  }

  Path _shapePath(Rect rect) {
    switch (color) {
      case LumoCardColor.orange: // Rot = Raute
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case LumoCardColor.purple: // Gelb = Dreieck
        return Path()
          ..moveTo(rect.center.dx, rect.top + 4)
          ..lineTo(rect.right - 2, rect.bottom - 4)
          ..lineTo(rect.left + 2, rect.bottom - 4)
          ..close();
      case LumoCardColor.blue: // Blau = Kreis
        return Path()..addOval(rect.deflate(2));
      case LumoCardColor.green: // Grün = abgerundetes Quadrat
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              rect.deflate(4), const Radius.circular(10)));
    }
  }

  @override
  bool shouldRepaint(covariant _ColorChoicePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fills != fills;
}
