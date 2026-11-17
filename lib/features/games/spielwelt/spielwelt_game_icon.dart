import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Individual game symbols, not miniature screenshots with baked-in UI.
/// Existing transparent Lumo artwork is combined with resolution-independent
/// toy shapes. The icons stay readable when the Fold changes its width.
class SpielweltGameIcon extends StatelessWidget {
  const SpielweltGameIcon({super.key, required this.identity});

  final String identity;

  static String? assetFor(String identity) => switch (identity) {
        'kart' => 'assets/lumo_design/characters/kart_side.webp',
        'village' => 'assets/lumo_design/spielwelt/portal_bauwelt.png',
        'treasure' => 'assets/lumo_design/icons/treasure_chest.png',
        'quizShow' => 'assets/lumo_design/icons/trophy_gold.png',
        'jumpRun' => 'assets/lumo_design/characters/fox_trophy_jump.webp',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(identity);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            if (asset != null) {
              return Padding(
                padding: EdgeInsets.all(size * .035),
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              );
            }
            return Center(
              child: SizedBox(
                width: size * 1.16,
                height: size,
                child: Stack(fit: StackFit.expand, children: [
                  CustomPaint(painter: _ToyIconPainter(identity)),
                  if (identity == 'memory')
                    Positioned(
                      left: size * 1.16 * .5,
                      top: size * 38 / 140,
                      width: size * 1.16 * 50 / 160,
                      height: size * 74 / 140,
                      child: Transform.rotate(
                        angle: .16,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Image.asset(
                              'assets/lumo_design/fox/fox_avatar.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium),
                        ),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToyIconPainter extends CustomPainter {
  const _ToyIconPainter(this.identity);

  final String identity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 140);
    switch (identity) {
      case 'cards':
        _cards(canvas);
      case 'memory':
        _memory(canvas);
      case 'build':
        _blocks(canvas);
      case 'puzzle':
        _puzzle(canvas);
      case 'rhythm':
        _rhythm(canvas);
      case 'connectFour':
        _connectFour(canvas);
    }
    canvas.restore();
  }

  void _surface(
    Canvas canvas,
    Path path,
    Color top,
    Color bottom, {
    double depth = 5,
    Color? edge,
  }) {
    // A translated silhouette is stable at every raster scale. The card
    // already casts its own soft shadow; no concave shadow tessellation is
    // needed for the tiny toy symbol inside it.
    canvas.drawPath(path.shift(Offset(1, depth + 2)),
        Paint()..color = const Color(0x55000716));
    canvas.drawPath(
      path.shift(Offset(0, depth)),
      Paint()..color = edge ?? Color.lerp(bottom, Colors.black, .35)!,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ).createShader(path.getBounds()),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(top, Colors.white, .55)!,
    );
  }

  Path _rounded(Rect rect, double radius) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  Path _star(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * .46;
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  void _card(
    Canvas canvas,
    double angle,
    Offset offset,
    Color top,
    Color bottom, {
    bool star = true,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    const rect = Rect.fromLTWH(-32, -45, 64, 90);
    _surface(canvas, _rounded(rect, 10), top, bottom, depth: 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xCCFFF3BD),
    );
    if (star) {
      _surface(
        canvas,
        _star(Offset.zero, 21),
        const Color(0xFFFFE78F),
        const Color(0xFFFFAD18),
        depth: 2,
      );
    }
    canvas.drawLine(
      const Offset(-21, -31),
      const Offset(-4, -31),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = 2.5,
    );
    canvas.restore();
  }

  void _cards(Canvas canvas) {
    _card(
      canvas,
      -.34,
      const Offset(48, 73),
      const Color(0xFF70F7C7),
      const Color(0xFF0C9D8F),
    );
    _card(
      canvas,
      -.1,
      const Offset(71, 67),
      const Color(0xFF72CDFF),
      const Color(0xFF2357DD),
    );
    _card(
      canvas,
      .13,
      const Offset(96, 67),
      const Color(0xFFFF9C80),
      const Color(0xFFE74368),
    );
    _card(
      canvas,
      .34,
      const Offset(116, 77),
      const Color(0xFFC49BFF),
      const Color(0xFF6F3ED0),
    );
  }

  void _memory(Canvas canvas) {
    _card(
      canvas,
      -.21,
      const Offset(56, 72),
      const Color(0xFF99EAFF),
      const Color(0xFF2464C7),
    );
    canvas.save();
    canvas.translate(105, 75);
    canvas.rotate(.16);
    _surface(
      canvas,
      _rounded(const Rect.fromLTWH(-31, -43, 62, 86), 10),
      const Color(0xFFFFE27A),
      const Color(0xFFF9AD2D),
    );
    final inset = _rounded(const Rect.fromLTWH(-25, -37, 50, 74), 7);
    canvas.drawPath(inset, Paint()..color = const Color(0xFF255299));
    canvas.restore();
  }

  void _block(Canvas canvas, Offset p, double w, double h, Color color) {
    final front = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(p.dx + w, p.dy + 6)
      ..lineTo(p.dx + w, p.dy + h)
      ..lineTo(p.dx, p.dy + h - 6)
      ..close();
    _surface(
      canvas,
      front,
      color,
      Color.lerp(color, Colors.black, .2)!,
      depth: 3,
    );
    final right = Path()
      ..moveTo(p.dx + w, p.dy + 6)
      ..lineTo(p.dx + w + 17, p.dy - 8)
      ..lineTo(p.dx + w + 17, p.dy + h - 14)
      ..lineTo(p.dx + w, p.dy + h)
      ..close();
    canvas.drawPath(
      right,
      Paint()..color = Color.lerp(color, const Color(0xFF102347), .33)!,
    );
    final lid = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(p.dx + 17, p.dy - 14)
      ..lineTo(p.dx + w + 17, p.dy - 8)
      ..lineTo(p.dx + w, p.dy + 6)
      ..close();
    canvas.drawPath(lid, Paint()..color = Color.lerp(color, Colors.white, .3)!);
    for (var i = 0; i < 2; i++) {
      final c = p + Offset(16 + i * (w - 20) / 2, -5);
      final rect = Rect.fromCenter(center: c, width: 15, height: 8);
      canvas.drawOval(rect.shift(const Offset(0, 4)), Paint()..color = color);
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top + 4, 15, 4),
        Paint()..color = color,
      );
      canvas.drawOval(
        rect,
        Paint()..color = Color.lerp(color, Colors.white, .45)!,
      );
    }
  }

  void _blocks(Canvas canvas) {
    _block(canvas, const Offset(24, 71), 48, 40, const Color(0xFF419AFF));
    _block(canvas, const Offset(81, 80), 46, 36, const Color(0xFFFFC43E));
    _block(canvas, const Offset(29, 41), 45, 34, const Color(0xFFFF5B67));
    _block(canvas, const Offset(82, 27), 40, 49, const Color(0xFF49D9BD));
  }

  Path _piece() => Path()
    ..moveTo(-27, -27)
    ..lineTo(-8, -27)
    ..cubicTo(-13, -42, 14, -42, 9, -27)
    ..lineTo(27, -27)
    ..lineTo(27, -8)
    ..cubicTo(12, -13, 12, 14, 27, 9)
    ..lineTo(27, 27)
    ..lineTo(8, 27)
    ..cubicTo(13, 12, -14, 12, -9, 27)
    ..lineTo(-27, 27)
    ..lineTo(-27, 8)
    ..cubicTo(-42, 13, -42, -14, -27, -9)
    ..close();

  void _puzzle(Canvas canvas) {
    for (final entry in [
      (
        const Offset(53, 51),
        -.22,
        const Color(0xFFFFD665),
        const Color(0xFFFFA227),
      ),
      (
        const Offset(44, 101),
        -.1,
        const Color(0xFF6FEAFF),
        const Color(0xFF188DDB),
      ),
      (
        const Offset(108, 83),
        .24,
        const Color(0xFFFF97C2),
        const Color(0xFFE44788),
      ),
    ]) {
      canvas.save();
      canvas.translate(entry.$1.dx, entry.$1.dy);
      canvas.rotate(entry.$2);
      _surface(canvas, _piece(), entry.$3, entry.$4, depth: 5);
      canvas.restore();
    }
  }

  void _rhythm(Canvas canvas) {
    final note = Path()
      ..moveTo(60, 34)
      ..lineTo(127, 17)
      ..lineTo(127, 95)
      ..cubicTo(125, 117, 88, 125, 88, 105)
      ..cubicTo(88, 93, 104, 85, 113, 88)
      ..lineTo(113, 48)
      ..lineTo(74, 59)
      ..lineTo(74, 113)
      ..cubicTo(72, 135, 33, 140, 33, 118)
      ..cubicTo(33, 106, 49, 99, 60, 102)
      ..close();
    _surface(
      canvas,
      note,
      const Color(0xFFCDA6FF),
      const Color(0xFF7750E9),
      depth: 5,
    );
    _surface(
      canvas,
      _star(const Offset(31, 38), 14),
      const Color(0xFFFFEE95),
      const Color(0xFFFFBA30),
      depth: 2,
    );
    canvas.drawArc(
      const Rect.fromLTWH(117, 44, 32, 35),
      -.8,
      1.6,
      false,
      Paint()
        ..color = const Color(0xFF70E3FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _connectFour(Canvas canvas) {
    _surface(
      canvas,
      _rounded(const Rect.fromLTWH(18, 24, 124, 90), 12),
      const Color(0xFF76CBFF),
      const Color(0xFF2868E6),
      depth: 6,
    );
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        final center = Offset(34 + col * 23, 41 + row * 20);
        final filled = row >= 2 || (row == 1 && col == 2);
        final color = (row + col).isEven
            ? const Color(0xFFFFCC4E)
            : const Color(0xFFFF6272);
        canvas.drawCircle(
          center,
          8.5,
          Paint()..color = const Color(0xFF113D8D),
        );
        if (filled) {
          canvas.drawCircle(
            center.translate(0, -1),
            7,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-.4, -.5),
                colors: [Color.lerp(color, Colors.white, .4)!, color],
              ).createShader(Rect.fromCircle(center: center, radius: 8)),
          );
        }
      }
    }
    for (final x in [26.0, 120.0]) {
      _surface(
        canvas,
        _rounded(Rect.fromLTWH(x - 9, 112, 27, 10), 4),
        const Color(0xFF77C5FF),
        const Color(0xFF2651B8),
        depth: 3,
      );
    }
  }

  @override
  bool shouldRepaint(_ToyIconPainter oldDelegate) =>
      oldDelegate.identity != identity;
}
