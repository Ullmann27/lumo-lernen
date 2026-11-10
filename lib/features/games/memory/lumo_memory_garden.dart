import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Forest/garden world for Memory. Daylight and plants, never the shared
/// night-castle photograph used by the generic games scene.
class LumoMemoryGarden extends StatelessWidget {
  const LumoMemoryGarden({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        key: ValueKey('memory-garden-backdrop'),
        painter: LumoMemoryGardenPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class LumoMemoryGardenPainter extends CustomPainter {
  const LumoMemoryGardenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7EC8E8),
            Color(0xFFB8E0A8),
            Color(0xFF6FA86A),
            Color(0xFF3E6A3A),
          ],
          stops: [0, .38, .72, 1],
        ).createShader(bounds),
    );

    // Warm sun.
    canvas.drawCircle(
      Offset(w * .84, h * .12),
      math.min(w, h) * .09,
      Paint()
        ..color = const Color(0x66FFE08A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawCircle(
      Offset(w * .84, h * .12),
      math.min(w, h) * .045,
      Paint()..color = const Color(0xFFFFE7A0),
    );

    // Distant hills.
    final hills = Path()
      ..moveTo(0, h * .46)
      ..quadraticBezierTo(w * .22, h * .32, w * .44, h * .44)
      ..quadraticBezierTo(w * .66, h * .56, w, h * .40)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF4E8A52));

    final nearHills = Path()
      ..moveTo(0, h * .62)
      ..quadraticBezierTo(w * .3, h * .50, w * .55, h * .64)
      ..quadraticBezierTo(w * .78, h * .76, w, h * .58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(nearHills, Paint()..color = const Color(0xFF3A6C3C));

    // Waterfall streaks on the left.
    for (final x in <double>[w * .08, w * .11, w * .14]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, h * .38, w * .018, h * .34),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0x88D8F4FF),
      );
    }

    // Stylized trees.
    void tree(double x, double base, double scale) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, base),
            width: 10 * scale,
            height: 36 * scale,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF6A3E22),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, base - 28 * scale),
          width: 52 * scale,
          height: 46 * scale,
        ),
        Paint()..color = const Color(0xFF2F6A38),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 6 * scale, base - 36 * scale),
          width: 34 * scale,
          height: 28 * scale,
        ),
        Paint()..color = const Color(0xFF4C8A46),
      );
    }

    tree(w * .12, h * .78, 1.15);
    tree(w * .88, h * .74, 1.3);
    tree(w * .78, h * .82, .85);
    tree(w * .22, h * .86, .7);

    // Flower clumps and lantern glows around the table area.
    const flowers = <(double, double, Color)>[
      (.10, .90, Color(0xFFE878C0)),
      (.18, .93, Color(0xFF7EA4E8)),
      (.82, .91, Color(0xFFE878C0)),
      (.90, .88, Color(0xFFFFE08A)),
      (.08, .84, Color(0xFFFFE08A)),
      (.92, .94, Color(0xFF7EA4E8)),
    ];
    for (final (ux, uy, color) in flowers) {
      final p = Offset(w * ux, h * uy);
      canvas.drawCircle(p, 5.5, Paint()..color = color);
      canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFFFFF3C0));
    }

    // Garden lanterns (warm, not the night-castle lamps).
    void lantern(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 16, height: 22),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF5A3A1C),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 10, height: 12),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFD978),
      );
      canvas.drawCircle(
        Offset(x, y),
        16,
        Paint()
          ..color = const Color(0x55FFD27A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    lantern(w * .16, h * .58);
    lantern(w * .84, h * .56);

    // Soft vignette so the sandstone table stays readable.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x00000000), Color(0x33061810)],
          radius: 0.95,
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant LumoMemoryGardenPainter oldDelegate) => false;
}
