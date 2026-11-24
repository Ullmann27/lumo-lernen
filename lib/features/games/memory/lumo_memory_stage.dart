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

/// Felt card mat in a wooden rim, matching the native 3D Memory table.
class _MemoryStagePainter extends CustomPainter {
  const _MemoryStagePainter();

  static const _rim = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = Offset.zero & size;
    final table = RRect.fromRectAndRadius(outer.deflate(2), const Radius.circular(30));
    canvas.drawRRect(
      table.shift(const Offset(3, 8)),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // Wooden rim: warm base, soft grain bands and a lit upper bevel.
    canvas.drawRRect(
      table,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD68D47), Color(0xFF9A5A2A), Color(0xFFC57A3A), Color(0xFF7A4320)],
          stops: [0, .38, .7, 1],
        ).createShader(outer),
    );
    canvas.save();
    canvas.clipRRect(table);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x2E3A1A08);
    for (var y = table.top + 3; y < table.bottom; y += 5.5) {
      final wave = math.sin(y * .07) * 6;
      canvas.drawLine(Offset(table.left, y + wave), Offset(table.right, y - wave), grain);
    }
    canvas.restore();
    canvas.drawRRect(
      table.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99FFE3B8), Color(0x00FFE3B8), Color(0x55301606)],
        ).createShader(outer),
    );
    // Felt inlay with a soft vignette, dot pattern and golden stitching.
    final felt = RRect.fromRectAndRadius(
        table.outerRect.deflate(_rim), const Radius.circular(22));
    canvas.drawRRect(
      felt.inflate(1.5),
      Paint()..color = const Color(0xFF3E2210),
    );
    canvas.drawRRect(
      felt,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.2),
          radius: .95,
          colors: const [Color(0xFF236C66), Color(0xFF184E50), Color(0xFF0D3138)],
          stops: const [0, .62, 1],
        ).createShader(felt.outerRect),
    );
    canvas.save();
    canvas.clipRRect(felt);
    final dot = Paint()..color = const Color(0x2E9AD9C4);
    const step = 22.0;
    for (var y = felt.top + step / 2; y < felt.bottom; y += step) {
      for (var x = felt.left + step / 2; x < felt.right; x += step) {
        canvas.drawCircle(Offset(x, y), 1.4, dot);
      }
    }
    canvas.restore();
    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xB3EED39A);
    final path = Path()..addRRect(felt.deflate(6));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 11) {
        canvas.drawPath(metric.extractPath(d, d + 6), stitch);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MemoryStagePainter oldDelegate) => false;
}
