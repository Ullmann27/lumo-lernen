import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Indoor night parlor for Lumo Cards. Warm wood, lamps and a moonlit
/// window — deliberately not the outdoor garden used by Memory, and not
/// the shared night-castle games photograph.
class LumoCardsParlorPainter extends CustomPainter {
  const LumoCardsParlorPainter();

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
            Color(0xFF1A1020),
            Color(0xFF2A1A28),
            Color(0xFF3A241C),
            Color(0xFF1C1014),
          ],
          stops: [0, .32, .7, 1],
        ).createShader(bounds),
    );

    // Wood panel stripes.
    final panel = Paint()
      ..color = const Color(0x22301010)
      ..strokeWidth = 18;
    for (var i = 0; i < 8; i++) {
      final x = (i + .5) / 8 * w;
      canvas.drawLine(Offset(x, 0), Offset(x, h * .72), panel);
    }

    // Moonlit window.
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .62, h * .05, w * .28, h * .28),
      const Radius.circular(14),
    );
    canvas.drawRRect(
        window.inflate(8), Paint()..color = const Color(0xFF4A3020));
    canvas.drawRRect(
      window,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2458), Color(0xFF0A1028)],
        ).createShader(window.outerRect),
    );
    canvas.drawCircle(
      Offset(w * .84, h * .12),
      math.min(w, h) * .04,
      Paint()..color = const Color(0xFFE8EEFF),
    );
    canvas.drawLine(
      Offset(w * .76, h * .05),
      Offset(w * .76, h * .33),
      Paint()
        ..color = const Color(0xFF5A3A24)
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(w * .62, h * .19),
      Offset(w * .90, h * .19),
      Paint()
        ..color = const Color(0xFF5A3A24)
        ..strokeWidth = 4,
    );

    // Bookshelf on the left.
    final shelf = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .04, h * .10, w * .18, h * .32),
      const Radius.circular(8),
    );
    canvas.drawRRect(shelf, Paint()..color = const Color(0xFF3A2418));
    const bookColors = [
      Color(0xFF8B3A3A),
      Color(0xFF3A5A8B),
      Color(0xFFC4A04A),
      Color(0xFF3A7A5A),
      Color(0xFF7A4A8B),
    ];
    for (var row = 0; row < 3; row++) {
      for (var i = 0; i < 5; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * .055 + i * w * .028,
              h * .13 + row * h * .09,
              w * .022,
              h * .07,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = bookColors[i],
        );
      }
    }

    // Warm hanging lamps.
    for (final x in <double>[w * .28, w * .50]) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h * .10),
        Paint()
          ..color = const Color(0xFF4A3020)
          ..strokeWidth = 2,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, h * .13), width: 28, height: 16),
        Paint()..color = const Color(0xFFC48A3A),
      );
      canvas.drawCircle(
        Offset(x, h * .16),
        22,
        Paint()
          ..color = const Color(0x66FFD27A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    // Floorboards.
    canvas.drawRect(
      Rect.fromLTWH(0, h * .74, w, h * .26),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1810), Color(0xFF140C0A)],
        ).createShader(Rect.fromLTWH(0, h * .74, w, h * .26)),
    );

    // Table spotlight — Cards is candlelit, Memory is sunlit.
    canvas.drawCircle(
      Offset(w * .5, h * .52),
      math.min(w, h) * .38,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x55FFD27A),
            Color(0x22C48A3A),
            Color(0x001A1020),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(w * .5, h * .52),
          radius: math.min(w, h) * .38,
        )),
    );
  }

  @override
  bool shouldRepaint(covariant LumoCardsParlorPainter oldDelegate) => false;
}
