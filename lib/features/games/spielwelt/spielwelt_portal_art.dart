import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Original painted Spielwelt architecture: stone/gold arches, plaza,
/// stairs and emblems. Nothing here is a raster copied from the Referenzmappe.
class SpielweltGround extends StatelessWidget {
  const SpielweltGround({super.key, required this.portrait});

  final bool portrait;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PlazaStairsPainter(portrait: portrait),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlazaStairsPainter extends CustomPainter {
  const _PlazaStairsPainter({required this.portrait});
  final bool portrait;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * (portrait ? 0.528 : 0.530);
    final plaza = Rect.fromCenter(
      center: Offset(cx, cy),
      width: size.width * (portrait ? 0.64 : 0.56),
      height: size.height * (portrait ? 0.145 : 0.185),
    );

    final shadow = Paint()
      ..color = const Color(0x66010A22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(plaza.translate(0, 10), shadow);

    final stone = Paint()
      ..shader = ui.Gradient.radial(
        plaza.center,
        plaza.shortestSide * 0.62,
        const [
          Color(0xFFD8C29A),
          Color(0xFF9A7548),
          Color(0xFF5C3C24),
        ],
        const [0.0, 0.62, 1.0],
      );
    canvas.drawOval(plaza, stone);

    final ring = plaza.deflate(plaza.shortestSide * 0.10);
    canvas.drawOval(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = plaza.shortestSide * 0.055
        ..shader = ui.Gradient.linear(
          ring.topLeft,
          ring.bottomRight,
          const [Color(0xFFFFE7A8), Color(0xFFB8860B), Color(0xFFFFD86B)],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawOval(
      ring.deflate(plaza.shortestSide * 0.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0x66FFF6D8),
    );
    canvas.drawOval(
      plaza.deflate(plaza.shortestSide * 0.18),
      Paint()..color = const Color(0x3324A0E0),
    );

    // Stairs from the plaza down toward the featured row.
    final top = plaza.bottom - plaza.height * 0.18;
    final bottom = size.height * (portrait ? 0.662 : 0.712);
    final topHalf = size.width * 0.075;
    final botHalf = size.width * 0.155;
    const steps = 7;
    for (var i = 0; i < steps; i++) {
      final t0 = i / steps;
      final t1 = (i + 1) / steps;
      final y0 = ui.lerpDouble(top, bottom, t0)!;
      final y1 = ui.lerpDouble(top, bottom, t1)!;
      final w0 = ui.lerpDouble(topHalf, botHalf, t0)!;
      final w1 = ui.lerpDouble(topHalf, botHalf, t1)!;
      final path = Path()
        ..moveTo(cx - w0, y0)
        ..lineTo(cx + w0, y0)
        ..lineTo(cx + w1, y1)
        ..lineTo(cx - w1, y1)
        ..close();
      final shade = i.isEven ? const Color(0xFFB08958) : const Color(0xFF8A6238);
      canvas.drawPath(path, Paint()..color = shade);
      canvas.drawLine(
        Offset(cx - w0, y0),
        Offset(cx + w0, y0),
        Paint()
          ..color = const Color(0x66FFE7A8)
          ..strokeWidth = 1.2,
      );
    }
    final rail = Paint()
      ..color = const Color(0xCCFFD86B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - topHalf, top), Offset(cx - botHalf, bottom), rail);
    canvas.drawLine(Offset(cx + topHalf, top), Offset(cx + botHalf, bottom), rail);
  }

  @override
  bool shouldRepaint(_PlazaStairsPainter old) => old.portrait != portrait;
}

/// Stone/gold arch with a glowing blue field and a painted game emblem.
class SpielweltPortalArch extends StatelessWidget {
  const SpielweltPortalArch({super.key, required this.identity});

  final String identity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArchPainter(identity: identity),
      child: const SizedBox.expand(),
    );
  }
}

class _ArchPainter extends CustomPainter {
  const _ArchPainter({required this.identity});
  final String identity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide < 8) return;
    final outer = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.04,
      size.width * 0.84,
      size.height * 0.92,
    );
    final opening = outer.deflate(math.min(outer.width, outer.height) * 0.11);
    final outerPath = _archPath(outer);
    final innerPath = _archPath(opening);

    canvas.drawPath(
      outerPath.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0x66010A22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = ui.Gradient.linear(
          outer.topLeft,
          outer.bottomRight,
          const [Color(0xFFE6C98A), Color(0xFF8A5A30), Color(0xFFC4A066)],
          const [0.0, 0.5, 1.0],
        ),
    );

    final rim = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(
      rim,
      Paint()
        ..shader = ui.Gradient.linear(
          outer.topCenter,
          outer.bottomCenter,
          const [Color(0xFFFFF1C2), Color(0xFFB8860B), Color(0xFFE0B85A)],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFFFFE08A),
    );

    canvas.save();
    canvas.clipPath(innerPath);
    final glow = Paint()
      ..shader = ui.Gradient.radial(
        opening.center,
        opening.longestSide * 0.62,
        const [
          Color(0xFFB8F4FF),
          Color(0xFF37D2FD),
          Color(0xFF0B4A9A),
          Color(0xFF061A48),
        ],
        const [0.0, 0.38, 0.78, 1.0],
      );
    canvas.drawRect(opening.inflate(8), glow);
    canvas.drawCircle(
      opening.center.translate(0, -opening.height * 0.08),
      opening.width * 0.18,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    paintSpielweltEmblem(canvas, opening.deflate(opening.shortestSide * 0.12), identity);
    canvas.restore();

    // Gold capstone.
    final cap = Path()
      ..moveTo(outer.center.dx - outer.width * 0.14, outer.top + 2)
      ..lineTo(outer.center.dx + outer.width * 0.14, outer.top + 2)
      ..lineTo(outer.center.dx + outer.width * 0.09, outer.top - outer.height * 0.015)
      ..lineTo(outer.center.dx - outer.width * 0.09, outer.top - outer.height * 0.015)
      ..close();
    canvas.drawPath(cap, Paint()..color = const Color(0xFFFFD86B));
  }

  Path _archPath(Rect rect) {
    final radius = rect.width / 2;
    final pillarTop = rect.top + radius * 0.92;
    return Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, pillarTop)
      ..arcToPoint(
        Offset(rect.right, pillarTop),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(rect.right, rect.bottom)
      ..quadraticBezierTo(rect.center.dx, rect.bottom + rect.height * 0.04, rect.left, rect.bottom)
      ..close();
  }

  @override
  bool shouldRepaint(_ArchPainter old) => old.identity != identity;
}

/// Featured Quizshow tile: original buzzer, not a photo crop.
class SpielweltQuizBuzzer extends StatelessWidget {
  const SpielweltQuizBuzzer({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _QuizBuzzerPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _QuizBuzzerPainter extends CustomPainter {
  const _QuizBuzzerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide * 0.16)),
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const [Color(0xFF1A4FA0), Color(0xFF2A1780), Color(0xFF071433)],
          const [0.0, 0.5, 1.0],
        ),
    );
    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final r = size.shortestSide * 0.28;
    canvas.drawCircle(
      Offset(cx, cy + 4),
      r * 1.15,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.08,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          r * 1.08,
          const [Color(0xFFFFF1C2), Color(0xFFC9A227)],
        ),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - r * 0.25, cy - r * 0.3),
          r,
          const [Color(0xFFFF6B6B), Color(0xFFC21818), Color(0xFF7A0B0B)],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      Offset(cx - r * 0.22, cy - r * 0.28),
      r * 0.22,
      Paint()..color = const Color(0x66FFFFFF),
    );
    // Tiny stage lights.
    for (final dx in [-0.32, 0.0, 0.32]) {
      canvas.drawCircle(
        Offset(size.width * (0.5 + dx), size.height * 0.16),
        size.shortestSide * 0.045,
        Paint()..color = const Color(0xFFFFE08A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Lumo Kart as a ramp tile (original vehicle, no licensed silhouette).
class SpielweltKartRamp extends StatelessWidget {
  const SpielweltKartRamp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _KartRampPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _KartRampPainter extends CustomPainter {
  const _KartRampPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ramp = Path()
      ..moveTo(rect.width * 0.04, rect.height * 0.78)
      ..lineTo(rect.width * 0.38, rect.height * 0.70)
      ..lineTo(rect.width * 0.96, rect.height * 0.22)
      ..lineTo(rect.width * 0.96, rect.height * 0.42)
      ..lineTo(rect.width * 0.40, rect.height * 0.92)
      ..lineTo(rect.width * 0.04, rect.height * 0.88)
      ..close();

    canvas.drawPath(
      ramp.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x66010A22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      ramp,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(rect.width * 0.2, rect.height * 0.9),
          Offset(rect.width * 0.9, rect.height * 0.2),
          const [Color(0xFF2A6A38), Color(0xFF3FA0C8), Color(0xFF87D4F2)],
          const [0.0, 0.45, 1.0],
        ),
    );
    final rail = Paint()
      ..color = const Color(0xFFFFD86B)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(rect.width * 0.38, rect.height * 0.70),
      Offset(rect.width * 0.96, rect.height * 0.22),
      rail,
    );
    canvas.drawLine(
      Offset(rect.width * 0.40, rect.height * 0.92),
      Offset(rect.width * 0.96, rect.height * 0.42),
      rail,
    );
    // Dashed center line.
    final dash = Paint()
      ..color = const Color(0xCCFFF6D8)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final t0 = i / 6;
      final t1 = (i + 0.45) / 6;
      canvas.drawLine(
        Offset(
          ui.lerpDouble(rect.width * 0.22, rect.width * 0.88, t0)!,
          ui.lerpDouble(rect.height * 0.80, rect.height * 0.34, t0)!,
        ),
        Offset(
          ui.lerpDouble(rect.width * 0.22, rect.width * 0.88, t1)!,
          ui.lerpDouble(rect.height * 0.80, rect.height * 0.34, t1)!,
        ),
        dash,
      );
    }

    // Simple original LUMO family kart: rounded cyan body, gold canopy, two wheels.
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.width * 0.58, rect.height * 0.52),
        width: rect.width * 0.34,
        height: rect.height * 0.22,
      ),
      Radius.circular(rect.shortestSide * 0.08),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF1FA8D8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.width * 0.61, rect.height * 0.48),
          width: rect.width * 0.16,
          height: rect.height * 0.12,
        ),
        Radius.circular(rect.shortestSide * 0.05),
      ),
      Paint()..color = const Color(0xFFFFD86B),
    );
    final wheel = Paint()..color = const Color(0xFF1A1A28);
    canvas.drawCircle(Offset(rect.width * 0.46, rect.height * 0.62), rect.shortestSide * 0.07, wheel);
    canvas.drawCircle(Offset(rect.width * 0.70, rect.height * 0.58), rect.shortestSide * 0.07, wheel);
    canvas.drawCircle(
      Offset(rect.width * 0.46, rect.height * 0.62),
      rect.shortestSide * 0.03,
      Paint()..color = const Color(0xFFFFE08A),
    );
    canvas.drawCircle(
      Offset(rect.width * 0.70, rect.height * 0.58),
      rect.shortestSide * 0.03,
      Paint()..color = const Color(0xFFFFE08A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void paintSpielweltEmblem(Canvas canvas, Rect bounds, String identity) {
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  final s = bounds.shortestSide;
  switch (identity) {
    case 'memory':
      _card(canvas, Rect.fromCenter(center: Offset(cx - s * 0.10, cy + s * 0.04), width: s * 0.42, height: s * 0.56), -0.18, const Color(0xFF163A86), star: false);
      _card(canvas, Rect.fromCenter(center: Offset(cx + s * 0.12, cy - s * 0.02), width: s * 0.42, height: s * 0.56), 0.16, const Color(0xFFFFF6E8), star: true);
    case 'cards':
      _card(canvas, Rect.fromCenter(center: Offset(cx - s * 0.16, cy), width: s * 0.34, height: s * 0.50), -0.28, const Color(0xFF2B6BD4), star: true);
      _card(canvas, Rect.fromCenter(center: Offset(cx, cy - s * 0.02), width: s * 0.34, height: s * 0.50), 0.0, const Color(0xFFFFF6E8), star: true);
      _card(canvas, Rect.fromCenter(center: Offset(cx + s * 0.16, cy), width: s * 0.34, height: s * 0.50), 0.28, const Color(0xFFFFD86B), star: true);
    case 'puzzle':
      _puzzlePiece(canvas, bounds.deflate(s * 0.08));
    case 'jumpRun':
      _jumpBlocks(canvas, bounds);
    case 'rhythm':
      _notes(canvas, bounds);
    case 'treasure':
      _chest(canvas, bounds);
    case 'build':
      _cubes(canvas, bounds);
    default:
      break;
  }
}

void _card(Canvas canvas, Rect rect, double tilt, Color fill, {required bool star}) {
  canvas.save();
  canvas.translate(rect.center.dx, rect.center.dy);
  canvas.rotate(tilt);
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
    Radius.circular(rect.width * 0.14),
  );
  canvas.drawRRect(body, Paint()..color = fill);
  canvas.drawRRect(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFF1C2),
  );
  if (star) {
    _star(canvas, Offset.zero, rect.width * 0.22, const Color(0xFFFFC94A));
  } else {
    for (final p in [Offset(-rect.width * 0.16, -rect.height * 0.18), Offset(rect.width * 0.16, 0), Offset(-rect.width * 0.08, rect.height * 0.20)]) {
      canvas.drawCircle(p, 3.2, Paint()..color = const Color(0xFFFFD86B));
    }
  }
  canvas.restore();
}

void _star(Canvas canvas, Offset c, double r, Color color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rad = i.isEven ? r : r * 0.42;
    final p = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

void _puzzlePiece(Canvas canvas, Rect bounds) {
  final w = bounds.width;
  final h = bounds.height;
  final x = bounds.left;
  final y = bounds.top;
  final tab = math.min(w, h) * 0.16;
  final path = Path()
    ..moveTo(x + w * 0.22, y + h * 0.28)
    ..lineTo(x + w * 0.38, y + h * 0.28)
    ..arcToPoint(
      Offset(x + w * 0.62, y + h * 0.28),
      radius: Radius.circular(tab),
      clockwise: true,
    )
    ..lineTo(x + w * 0.78, y + h * 0.28)
    ..lineTo(x + w * 0.78, y + h * 0.40)
    ..arcToPoint(
      Offset(x + w * 0.78, y + h * 0.62),
      radius: Radius.circular(tab),
      clockwise: true,
    )
    ..lineTo(x + w * 0.78, y + h * 0.78)
    ..lineTo(x + w * 0.62, y + h * 0.78)
    ..arcToPoint(
      Offset(x + w * 0.38, y + h * 0.78),
      radius: Radius.circular(tab),
      clockwise: false,
    )
    ..lineTo(x + w * 0.22, y + h * 0.78)
    ..lineTo(x + w * 0.22, y + h * 0.62)
    ..arcToPoint(
      Offset(x + w * 0.22, y + h * 0.40),
      radius: Radius.circular(tab),
      clockwise: false,
    )
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        const [Color(0xFF7DE0FF), Color(0xFF2F7AE0)],
      ),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFFFFF1C2),
  );
}

void _jumpBlocks(Canvas canvas, Rect bounds) {
  final s = bounds.shortestSide;
  final origin = Offset(bounds.left + s * 0.10, bounds.bottom - s * 0.18);
  void block(Offset o, double w, double h, Color c) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(o.dx, o.dy - h, w, h),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(r, Paint()..color = c);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x66FFF6D8)
        ..strokeWidth = 1.4,
    );
  }
  block(origin, s * 0.28, s * 0.16, const Color(0xFF3FA36A));
  block(origin.translate(s * 0.26, -s * 0.14), s * 0.28, s * 0.16, const Color(0xFF57C984));
  block(origin.translate(s * 0.52, -s * 0.30), s * 0.28, s * 0.16, const Color(0xFFFFD86B));
  final arc = Path()
    ..moveTo(origin.dx + s * 0.12, origin.dy - s * 0.22)
    ..quadraticBezierTo(
      origin.dx + s * 0.42, origin.dy - s * 0.62,
      origin.dx + s * 0.66, origin.dy - s * 0.38,
    );
  canvas.drawPath(
    arc,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFF1C2),
  );
  canvas.drawCircle(
    Offset(origin.dx + s * 0.66, origin.dy - s * 0.38),
    s * 0.055,
    Paint()..color = const Color(0xFFFF9A3C),
  );
}

void _notes(Canvas canvas, Rect bounds) {
  final s = bounds.shortestSide;
  final paint = Paint()..color = const Color(0xFFFFF1C2);
  void note(Offset head, double stem) {
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.22, height: s * 0.16),
      paint,
    );
    canvas.restore();
    canvas.drawLine(
      Offset(head.dx + s * 0.09, head.dy - s * 0.02),
      Offset(head.dx + s * 0.09, head.dy - stem),
      Paint()
        ..color = const Color(0xFFFFF1C2)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }
  final a = Offset(bounds.center.dx - s * 0.16, bounds.center.dy + s * 0.12);
  final b = Offset(bounds.center.dx + s * 0.12, bounds.center.dy + s * 0.02);
  note(a, s * 0.42);
  note(b, s * 0.42);
  canvas.drawLine(
    Offset(a.dx + s * 0.09, a.dy - s * 0.42),
    Offset(b.dx + s * 0.09, b.dy - s * 0.42),
    Paint()
      ..color = const Color(0xFFFFD86B)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round,
  );
}

void _chest(Canvas canvas, Rect bounds) {
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: bounds.center.translate(0, bounds.height * 0.10),
      width: bounds.width * 0.72,
      height: bounds.height * 0.42,
    ),
    Radius.circular(bounds.shortestSide * 0.08),
  );
  canvas.drawRRect(body, Paint()..color = const Color(0xFF8A4B1F));
  canvas.drawRRect(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFFFFD86B),
  );
  final lid = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: bounds.center.translate(0, -bounds.height * 0.16),
      width: bounds.width * 0.76,
      height: bounds.height * 0.22,
    ),
    Radius.circular(bounds.shortestSide * 0.10),
  );
  canvas.drawRRect(lid, Paint()..color = const Color(0xFFB8682A));
  canvas.drawRRect(
    lid,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFFFE08A),
  );
  canvas.drawCircle(
    bounds.center.translate(0, bounds.height * 0.04),
    bounds.shortestSide * 0.07,
    Paint()..color = const Color(0xFFFFE08A),
  );
  canvas.drawCircle(
    bounds.center.translate(0, -bounds.height * 0.02),
    bounds.shortestSide * 0.16,
    Paint()
      ..color = const Color(0x55FFE08A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
}

void _cubes(Canvas canvas, Rect bounds) {
  final s = bounds.shortestSide;
  void cube(Offset o, double a, Color c) {
    final top = Path()
      ..moveTo(o.dx, o.dy - a * 0.5)
      ..lineTo(o.dx + a * 0.5, o.dy - a * 0.25)
      ..lineTo(o.dx, o.dy)
      ..lineTo(o.dx - a * 0.5, o.dy - a * 0.25)
      ..close();
    final left = Path()
      ..moveTo(o.dx - a * 0.5, o.dy - a * 0.25)
      ..lineTo(o.dx, o.dy)
      ..lineTo(o.dx, o.dy + a * 0.5)
      ..lineTo(o.dx - a * 0.5, o.dy + a * 0.25)
      ..close();
    final right = Path()
      ..moveTo(o.dx + a * 0.5, o.dy - a * 0.25)
      ..lineTo(o.dx, o.dy)
      ..lineTo(o.dx, o.dy + a * 0.5)
      ..lineTo(o.dx + a * 0.5, o.dy + a * 0.25)
      ..close();
    canvas.drawPath(top, Paint()..color = c);
    canvas.drawPath(left, Paint()..color = Color.lerp(c, const Color(0xFF000000), 0.22)!);
    canvas.drawPath(right, Paint()..color = Color.lerp(c, const Color(0xFFFFFFFF), 0.12)!);
  }
  cube(bounds.center.translate(-s * 0.16, s * 0.12), s * 0.36, const Color(0xFF3FA36A));
  cube(bounds.center.translate(s * 0.18, s * 0.16), s * 0.32, const Color(0xFF37D2FD));
  cube(bounds.center.translate(0, -s * 0.10), s * 0.34, const Color(0xFFFFD86B));
}
