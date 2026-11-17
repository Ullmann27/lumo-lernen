import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static premium tabletop behind the existing, playable Memory cards.
///
/// No animation ticker, textures, network access or new dependencies. The
/// board still owns the card layout and gestures; this layer never receives
/// touch events. Painting complexity stays constant across difficulty levels.
class LumoMemoryStage extends StatelessWidget {
  const LumoMemoryStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: ValueKey('memory-2027-stage'),
                painter: _MemoryStagePainter(),
              ),
            ),
          ),
          child,
        ],
      );
}

class _MemoryStagePainter extends CustomPainter {
  const _MemoryStagePainter();

  static const _starMarks = <(double, double)>[
    (0.18, 0.20),
    (0.82, 0.18),
    (0.12, 0.48),
    (0.88, 0.52),
    (0.22, 0.80),
    (0.78, 0.84),
    (0.50, 0.12),
    (0.50, 0.90),
    (0.34, 0.16),
    (0.66, 0.14),
  ];

  static const _moss = <(double, double, double)>[
    (0.16, 0.22, 0.055),
    (0.86, 0.26, 0.05),
    (0.12, 0.72, 0.06),
    (0.90, 0.70, 0.048),
    (0.28, 0.90, 0.045),
    (0.74, 0.92, 0.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .5, h * .51);
    final rx = w * .485;
    final ry = h * .465;
    final table =
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    canvas.drawOval(
      table.shift(const Offset(0, 7)).inflate(4),
      Paint()
        ..color = const Color(0x73000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    canvas.drawOval(
      table,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.38),
          radius: 1.08,
          colors: const [
            Color(0xFFF3E4C4),
            Color(0xFFDCC28C),
            Color(0xFFC4A66C),
            Color(0xFFA07C48),
          ],
          stops: const [0.0, .42, .76, 1.0],
        ).createShader(table),
    );

    // Soft light band across the upper half, like sun on sandstone.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - ry * .18),
        width: rx * 1.55,
        height: ry * 1.05,
      ),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55FFF6DC), Color(0x00F3E4C4)],
        ).createShader(table),
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..color = const Color(0x59A67C3A);
    for (final scale in <double>[.93, .80, .64, .46]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: rx * 2 * scale,
          height: ry * 2 * scale,
        ),
        ring,
      );
    }

    canvas.drawOval(
      table,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF7A5A30),
    );
    canvas.drawOval(
      table.deflate(3.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFF0DCA8),
            Color(0xFFC4963C),
            Color(0xFFF0DCA8),
          ],
        ).createShader(Rect.fromLTWH(table.left, table.top, table.width, 1)),
    );

    final mossPaint = Paint()..color = const Color(0x665E7A3A);
    for (final (ux, uy, ur) in _moss) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
              table.left + ux * table.width, table.top + uy * table.height),
          width: table.width * ur * 2.1,
          height: table.height * ur,
        ),
        mossPaint,
      );
    }

    const flower = Color(0xAA7EA4E8);
    const flowerCore = Color(0xDDE8D48A);
    for (final (ux, uy, _) in _moss) {
      final p = Offset(
        table.left + ux * table.width,
        table.top + uy * table.height,
      );
      canvas.drawCircle(p, 2.4, Paint()..color = flower);
      canvas.drawCircle(p, 1.0, Paint()..color = flowerCore);
    }

    for (final (ux, uy) in _starMarks) {
      _drawStar(
        canvas,
        Offset(table.left + ux * table.width, table.top + uy * table.height),
        math.min(rx, ry) * .034,
        const Color(0x99E6C25A),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    if (radius <= 0) return;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .42;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MemoryStagePainter oldDelegate) => false;
}
