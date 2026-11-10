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

/// Foreground leaves and lanterns that frame the board without stealing taps.
class LumoMemoryGardenFrame extends StatelessWidget {
  const LumoMemoryGardenFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        key: ValueKey('memory-garden-frame'),
        painter: LumoMemoryGardenFramePainter(),
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
            Color(0xFF8FD0F0),
            Color(0xFFD8F0A8),
            Color(0xFF5E9A52),
            Color(0xFF2E5A32),
          ],
          stops: [0, .32, .68, 1],
        ).createShader(bounds),
    );

    canvas.drawCircle(
      Offset(w * .86, h * .10),
      math.min(w, h) * .11,
      Paint()
        ..color = const Color(0x88FFE08A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
    canvas.drawCircle(
      Offset(w * .86, h * .10),
      math.min(w, h) * .055,
      Paint()..color = const Color(0xFFFFE7A0),
    );

    // Light shafts from the sun.
    for (final angle in <double>[-.35, -.12, .08]) {
      final beam = Path()
        ..moveTo(w * .86, h * .10)
        ..lineTo(w * (.40 + angle), h)
        ..lineTo(w * (.52 + angle), h)
        ..close();
      canvas.drawPath(
        beam,
        Paint()..color = const Color(0x22FFF3C0),
      );
    }

    final hills = Path()
      ..moveTo(0, h * .42)
      ..quadraticBezierTo(w * .22, h * .28, w * .44, h * .40)
      ..quadraticBezierTo(w * .66, h * .52, w, h * .36)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF4E8A48));

    final nearHills = Path()
      ..moveTo(0, h * .58)
      ..quadraticBezierTo(w * .3, h * .46, w * .55, h * .60)
      ..quadraticBezierTo(w * .78, h * .72, w, h * .54)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(nearHills, Paint()..color = const Color(0xFF2F6A38));

    for (final x in <double>[w * .07, w * .11, w * .15]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, h * .34, w * .022, h * .38),
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0xAAD8F4FF),
      );
    }

    void tree(double x, double base, double scale) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, base),
            width: 14 * scale,
            height: 52 * scale,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF6A3E22),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, base - 40 * scale),
          width: 78 * scale,
          height: 70 * scale,
        ),
        Paint()..color = const Color(0xFF245A30),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - 10 * scale, base - 52 * scale),
          width: 50 * scale,
          height: 40 * scale,
        ),
        Paint()..color = const Color(0xFF4C8A46),
      );
    }

    tree(w * .10, h * .74, 1.45);
    tree(w * .90, h * .70, 1.65);
    tree(w * .78, h * .80, 1.05);
    tree(w * .20, h * .84, .95);

    void lantern(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 20, height: 28),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF5A3A1C),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 12, height: 14),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFD978),
      );
      canvas.drawCircle(
        Offset(x, y),
        22,
        Paint()
          ..color = const Color(0x77FFD27A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    lantern(w * .15, h * .52);
    lantern(w * .85, h * .50);
  }

  @override
  bool shouldRepaint(covariant LumoMemoryGardenPainter oldDelegate) => false;
}

class LumoMemoryGardenFramePainter extends CustomPainter {
  const LumoMemoryGardenFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    void leaf(Offset c, double s, double rot, Color color) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 34 * s),
        Paint()..color = color,
      );
      canvas.restore();
    }

    // Corner foliage frames the table but stays out of the score chips.
    for (var i = 0; i < 5; i++) {
      leaf(Offset(10 + i * 5.0, 12 + i * 6.0), 1.15 + i * .06, -.7 + i * .1,
          Color.lerp(const Color(0xFF245A30), const Color(0xFF4C8A46), i / 4)!);
      leaf(Offset(w - 10 - i * 5.0, 14 + i * 6.0), 1.15 + i * .06, .7 - i * .1,
          Color.lerp(const Color(0xFF245A30), const Color(0xFF4C8A46), i / 4)!);
      leaf(Offset(12 + i * 7.0, h - 14 - i * 6.0), 1.35, .85,
          const Color(0xCC2F6A38));
      leaf(Offset(w - 12 - i * 7.0, h - 12 - i * 5.0), 1.35, -.85,
          const Color(0xCC2F6A38));
    }

    const flowers = <(double, double, Color)>[
      (.06, .90, Color(0xFFE878C0)),
      (.12, .94, Color(0xFFFFE08A)),
      (.88, .93, Color(0xFFE878C0)),
      (.94, .89, Color(0xFF7EA4E8)),
      (.08, .84, Color(0xFF7EA4E8)),
      (.92, .84, Color(0xFFFFE08A)),
    ];
    for (final (ux, uy, color) in flowers) {
      final p = Offset(w * ux, h * uy);
      canvas.drawCircle(p, 7, Paint()..color = color);
      canvas.drawCircle(p, 2.6, Paint()..color = const Color(0xFFFFF3C0));
    }
  }

  @override
  bool shouldRepaint(covariant LumoMemoryGardenFramePainter oldDelegate) =>
      false;
}
