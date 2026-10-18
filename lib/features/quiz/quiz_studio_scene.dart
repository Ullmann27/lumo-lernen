import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive, self-contained game-show scenery.
/// Drawn at runtime so every size stays crisp; no flattened screenshot,
/// network asset, tap interception or dependence on image generation.
class QuizStudioScene extends StatelessWidget {
  const QuizStudioScene({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _QuizStudioPainter()),
    );
  }
}

class _QuizStudioPainter extends CustomPainter {
  const _QuizStudioPainter();

  static const _cyan = Color(0xFF36DFFF);
  static const _gold = Color(0xFFFFC85B);
  static const _navy = Color(0xFF040C27);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);

    canvas.drawRect(
      bounds,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF06102E),
          Color(0xFF102963),
          Color(0xFF05235A),
          Color(0xFF030B22),
        ],
        stops: [0, .32, .73, 1],
      ).createShader(bounds),
    );

    final halo = Rect.fromCenter(
      center: Offset(w * .5, h * .39),
      width: w * .88, height: h * .78,
    );
    canvas.drawOval(
      halo,
      Paint()..shader = const RadialGradient(
        colors: [
          Color(0x885ACBFF),
          Color(0x441C68CD),
          Color(0x00001850),
        ],
        stops: [0, .45, 1],
      ).createShader(halo),
    );

    // Ceiling tubes and moving-stage-light cones have real translucency;
    // they remain static for accessibility and predictable screenshots.
    for (var i = 0; i < 5; i++) {
      final left = (i + .5) / 5 * w;
      final target = w * (.2 + .6 * ((i * 3 % 5) / 4));
      final beam = Path()
        ..moveTo(left - 4, 1)
        ..lineTo(left + 4, 1)
        ..lineTo(target + w * .12, h * .81)
        ..lineTo(target - w * .12, h * .81)
        ..close();
      canvas.drawPath(
        beam,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            i.isEven ? const Color(0x663BD6FF) : const Color(0x55FFD678),
            const Color(0x002EBFFF),
          ],
        ).createShader(bounds),
      );
      canvas.drawCircle(
        Offset(left, 7), math.max(2.4, w * .010),
        Paint()..color = i.isEven ? _cyan : _gold,
      );
      canvas.drawCircle(
        Offset(left, 7), math.max(5, w * .025),
        Paint()
          ..color = (i.isEven ? _cyan : _gold).withOpacity(.48)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // The audience is abstract scenery and never pretends to be interactive.
    for (var row = 0; row < 3; row++) {
      final y = h * (.48 + row * .095);
      for (var i = 0; i < 15; i++) {
        final x = w * ((i + .35 + (row.isEven ? .25 : 0)) / 15);
        final r = math.max(2.2, w * (.011 + .003 * row));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: r * 2,
              height: r * 2.25),
          Paint()..color = Color.lerp(
            const Color(0xFF0D2254), const Color(0xFF091437),
            row / 2)!,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y + r * 2),
              width: r * 3.1, height: r * 2.9,
            ),
            Radius.circular(r),
          ),
          Paint()..color = const Color(0xFF091736),
        );
      }
    }

    // Bright golden architectural edges framing the television set.
    for (final side in <double>[0, 1]) {
      final x = side == 0 ? w * .045 : w * .955;
      final rail = Path()
        ..moveTo(x, h * .26)
        ..lineTo(x, h * .67)
        ..lineTo(w * .5, h * .77);
      canvas.drawPath(
        rail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, w * .012)
          ..color = _gold.withOpacity(.78)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        rail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFFFE7A8),
      );
    }

    final stage = Rect.fromCenter(
      center: Offset(w * .5, h * .835),
      width: w * .93, height: h * .20,
    );
    canvas.drawOval(
      stage.shift(Offset(0, h * .025)),
      Paint()..shader = const RadialGradient(
        colors: [Color(0xFF1B7FDB), Color(0xFF071A52), _navy],
      ).createShader(stage),
    );
    canvas.drawOval(
      stage,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3, w * .016)
        ..color = const Color(0xAA2CF3FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawOval(
      stage,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * .008)
        ..color = const Color(0xFFFFD779),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .824),
        width: w * .60, height: h * .10,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _cyan.withOpacity(.92),
    );

    final floor = Rect.fromLTWH(0, h * .85, w, h * .15);
    canvas.drawRect(
      floor,
      Paint()..shader = const LinearGradient(
        colors: [Color(0xAA026AC2), Color(0xBB071542)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(floor),
    );
    for (var i = 0; i <= 4; i++) {
      final xx = w * (i / 4);
      canvas.drawLine(
        Offset(w * .5, h * .83), Offset(xx, h),
        Paint()
          ..strokeWidth = .75
          ..color = _cyan.withOpacity(.32),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QuizStudioPainter oldDelegate) => false;
}
