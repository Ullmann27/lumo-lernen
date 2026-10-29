import 'package:flutter/material.dart';

/// Static premium 2.5D tabletop behind the existing, playable Memory cards.
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

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final field = Rect.fromLTWH(0, 0, w, h);
    final radius = Radius.circular(
      (size.shortestSide * .06).clamp(12.0, 26.0).toDouble(),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(field, radius));

    // Understated table reflection: luminous near the upper lip, dark beneath
    // the cards so their artwork and readable symbols remain dominant.
    canvas.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x3639D9FF),
            Color(0x060A274E),
            Color(0x233D6DA6),
            Color(0x08031429),
          ],
          stops: [0.0, .24, .62, 1.0],
        ).createShader(field),
    );

    final perspective = Paint()
      ..color = const Color(0x1738CAFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Receding engraved lines lend depth without a realtime GPU shader.
    for (var i = 0; i <= 6; i++) {
      final x = w * (i / 6);
      canvas.drawLine(
        Offset(w * .5 + (x - w * .5) * .12, h * .08),
        Offset(x, h * .97),
        perspective,
      );
    }
    for (final y in [.18, .34, .57, .86]) {
      final inset = (1 - y) * w * .105;
      canvas.drawLine(Offset(inset, h * y), Offset(w - inset, h * y),
          perspective);
    }

    // Raised metallic tabletop edges are intentionally behind the card grid.
    final lip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = const LinearGradient(
        colors: [Color(0xCCB7F7FF), Color(0x5637D2FD), Color(0xB8FFDA81)],
      ).createShader(Rect.fromLTWH(0, 0, w, 1));
    final outline = Path()
      ..moveTo(w * .08, h * .045)
      ..lineTo(w * .92, h * .045)
      ..lineTo(w * .976, h * .92)
      ..quadraticBezierTo(w * .978, h * .966, w * .92, h * .966)
      ..lineTo(w * .08, h * .966)
      ..quadraticBezierTo(w * .022, h * .966, w * .024, h * .92)
      ..close();
    canvas.drawPath(outline, lip);

    // Four small inlaid lights; no flashing or moving effects for children
    // who choose reduced-motion / calm mode.
    for (final dx in [.075, .925]) {
      for (final dy in [.072, .928]) {
        final center = Offset(w * dx, h * dy);
        canvas.drawCircle(
          center,
          4.7,
          Paint()..color = const Color(0x3FFFDA84),
        );
        canvas.drawCircle(
          center,
          2,
          Paint()..color = const Color(0xFFE7F9FF),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MemoryStagePainter oldDelegate) => false;
}
