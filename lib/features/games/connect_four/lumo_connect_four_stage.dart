import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cozy night playroom behind the playable 7x6 board.
/// Painted at runtime so it never intercepts taps or depend on a shared
/// games-scene photograph that Memory and Cards also used.
class LumoConnectFourRoom extends StatelessWidget {
  const LumoConnectFourRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        key: ValueKey('connect-four-room'),
        painter: LumoConnectFourRoomPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class LumoConnectFourRoomPainter extends CustomPainter {
  const LumoConnectFourRoomPainter();

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
            Color(0xFF07122C),
            Color(0xFF12244A),
            Color(0xFF1A1840),
            Color(0xFF0B1028),
          ],
          stops: [0, .35, .72, 1],
        ).createShader(bounds),
    );

    // Window with moonlight, matching the bedroom/telescope mood.
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .58, h * .06, w * .36, h * .32),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      window.inflate(10),
      Paint()..color = const Color(0xFF3A2A18),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15224A), Color(0xFF0A1433), Color(0xFF1A2858)],
        ).createShader(window.outerRect),
    );
    canvas.drawCircle(
      Offset(w * .86, h * .13),
      math.min(w, h) * .055,
      Paint()..color = const Color(0xFFE8F0FF),
    );
    canvas.drawCircle(
      Offset(w * .86, h * .13),
      math.min(w, h) * .09,
      Paint()
        ..color = const Color(0x66D0E4FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    const stars = <(double, double)>[
      (.62, .10),
      (.70, .16),
      (.78, .09),
      (.84, .22),
      (.66, .24),
      (.90, .18),
      (.73, .30),
    ];
    for (final (ux, uy) in stars) {
      canvas.drawCircle(
        Offset(w * ux, h * uy),
        1.4,
        Paint()..color = const Color(0xCCFFF6D0),
      );
    }
    final mullion = Paint()
      ..color = const Color(0xFF5A3E24)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * .76, h * .06),
      Offset(w * .76, h * .38),
      mullion,
    );
    canvas.drawLine(
      Offset(w * .58, h * .22),
      Offset(w * .94, h * .22),
      mullion,
    );

    // Warm wall lamps.
    for (final x in <double>[w * .12, w * .88]) {
      canvas.drawCircle(
        Offset(x, h * .18),
        18,
        Paint()
          ..color = const Color(0x55FFD27A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
      canvas.drawCircle(
          Offset(x, h * .18), 5, Paint()..color = const Color(0xFFFFE7A8));
    }

    // Simple telescope silhouette (decoration only).
    final scope = Path()
      ..moveTo(w * .10, h * .42)
      ..lineTo(w * .26, h * .28)
      ..lineTo(w * .29, h * .31)
      ..lineTo(w * .13, h * .45)
      ..close();
    canvas.drawPath(scope, Paint()..color = const Color(0xFF2A2438));
    canvas.drawCircle(
        Offset(w * .27, h * .29), 7, Paint()..color = const Color(0xFF3A3450));
    canvas.drawLine(
      Offset(w * .14, h * .44),
      Offset(w * .10, h * .58),
      Paint()
        ..color = const Color(0xFF2A2438)
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(w * .14, h * .44),
      Offset(w * .20, h * .58),
      Paint()
        ..color = const Color(0xFF2A2438)
        ..strokeWidth = 4,
    );

    // Floor and warm rug under the board.
    canvas.drawRect(
      Rect.fromLTWH(0, h * .78, w, h * .22),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14102A), Color(0xFF0A0818)],
        ).createShader(Rect.fromLTWH(0, h * .78, w, h * .22)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .92),
        width: w * .82,
        height: h * .14,
      ),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x883A2460), Color(0x00080818)],
        ).createShader(Rect.fromCenter(
          center: Offset(w * .5, h * .92),
          width: w * .82,
          height: h * .14,
        )),
    );

    // Soft cyan/gold ambient so the glass board feels at home here.
    canvas.drawCircle(
      Offset(w * .5, h * .48),
      math.min(w, h) * .42,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x3326C6FF),
            Color(0x11FFD166),
            Color(0x0007122C)
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(w * .5, h * .48),
          radius: math.min(w, h) * .42,
        )),
    );
  }

  @override
  bool shouldRepaint(covariant LumoConnectFourRoomPainter oldDelegate) => false;
}

/// Translucent cyan plate with circular wells. Disc widgets stay underneath
/// so gameplay, keys and the drop animation remain unchanged.
class LumoConnectFourGlassPlate extends CustomPainter {
  const LumoConnectFourGlassPlate({
    required this.columns,
    required this.rows,
    required this.diameterFactor,
  });

  final int columns;
  final int rows;
  final double diameterFactor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cellW = size.width / columns;
    final cellH = size.height / rows;
    final diameter = math.min(cellW, cellH) * diameterFactor;
    final radius = diameter / 2;

    final holes = Path();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        holes.addOval(Rect.fromCircle(
          center: Offset(c * cellW + cellW / 2, r * cellH + cellH / 2),
          radius: radius,
        ));
      }
    }

    final plate = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(18),
      ))
      ..addPath(holes, Offset.zero)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xD21C7AD4),
            Color(0xE10B3E86),
            Color(0xD4166CC4),
            Color(0xE0082C68),
          ],
          stops: [0, .38, .72, 1],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.clipPath(plate);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 14),
      Paint()..color = const Color(0x66B8F6FF),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 18, size.width, 18),
      Paint()..color = const Color(0x66000A20),
    );
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..color = const Color(0xAA7AECFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = const Color(0xFFB8F6FF),
    );

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = const Color(0xDD8AF0FF);
    final innerShade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xAA000A20);
    final innerLight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x66FFFFFF);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final center = Offset(c * cellW + cellW / 2, r * cellH + cellH / 2);
        canvas.drawCircle(center, radius + 1.6, rim);
        canvas.drawCircle(center.translate(0, -1.1), radius + 0.4, innerShade);
        canvas.drawCircle(center.translate(0, 1.4), radius + 0.2, innerLight);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LumoConnectFourGlassPlate oldDelegate) =>
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows ||
      oldDelegate.diameterFactor != diameterFactor;
}
