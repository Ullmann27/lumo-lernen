import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import 'iq_style.dart';

// ---------------------------------------------------------------------------
// Formen
// ---------------------------------------------------------------------------

/// Pfad mit weich gerundeten Ecken durch die Punkte [points].
Path _roundedPolygon(List<Offset> points, double radius) {
  final n = points.length;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final prev = points[(i - 1 + n) % n];
    final cur = points[i];
    final next = points[(i + 1) % n];
    final toPrev = prev - cur;
    final toNext = next - cur;
    final r = math.min(
      radius,
      math.min(toPrev.distance, toNext.distance) / 2,
    );
    final a = cur + toPrev / toPrev.distance * r;
    final b = cur + toNext / toNext.distance * r;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  return path..close();
}

Path _centered(Path path) => path.shift(-path.getBounds().center);

/// Umriss einer Grundform um den Mittelpunkt (0, 0).
///
/// [r] ist ein Radius, der die Formen optisch gleich groß wirken lässt (nicht
/// der Umkreis). Pfeil und Kerbkreis zeigen bei Drehung 0 nach oben.
Path iqShapePath(IqShape shape, double r) {
  switch (shape) {
    case IqShape.circle:
      return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    case IqShape.square:
      final h = r * .84;
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(-h, -h, h, h), Radius.circular(r * .26)));
    case IqShape.triangle:
      final big = r * 1.18;
      return _centered(_roundedPolygon([
        Offset(0, -big),
        Offset(big * .866, big * .5),
        Offset(-big * .866, big * .5),
      ], r * .22));
    case IqShape.diamond:
      return _centered(_roundedPolygon([
        Offset(0, -r * 1.16),
        Offset(r * .88, 0),
        Offset(0, r * 1.16),
        Offset(-r * .88, 0),
      ], r * .18));
    case IqShape.star:
      final points = <Offset>[
        for (var k = 0; k < 10; k++)
          Offset(
            math.cos(-math.pi / 2 + k * math.pi / 5) * (k.isEven ? r * 1.2 : r * .55),
            math.sin(-math.pi / 2 + k * math.pi / 5) * (k.isEven ? r * 1.2 : r * .55),
          ),
      ];
      return _centered(_roundedPolygon(points, r * .12));
    case IqShape.hexagon:
      final big = r * 1.08;
      return _roundedPolygon([
        for (var k = 0; k < 6; k++)
          Offset(math.cos(k * math.pi / 3) * big, math.sin(k * math.pi / 3) * big),
      ], r * .17);
    case IqShape.plus:
      final a = r * 1.02;
      final t = r * .37;
      return _roundedPolygon([
        Offset(-t, -a), Offset(t, -a), Offset(t, -t), Offset(a, -t), //
        Offset(a, t), Offset(t, t), Offset(t, a), Offset(-t, a),
        Offset(-t, t), Offset(-a, t), Offset(-a, -t), Offset(-t, -t),
      ], r * .15);
    case IqShape.arrow:
      return _centered(_roundedPolygon([
        Offset(0, -r * 1.08),
        Offset(r * .82, -r * .1),
        Offset(r * .32, -r * .1),
        Offset(r * .32, r * 1.04),
        Offset(-r * .32, r * 1.04),
        Offset(-r * .32, -r * .1),
        Offset(-r * .82, -r * .1),
      ], r * .13));
    case IqShape.notch:
      final circle = Path()
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 1.02));
      const half = 37 * math.pi / 180;
      final far = r * 1.7;
      final dx = (far + r * .1) * math.tan(half);
      final wedge = Path()
        ..moveTo(0, r * .1)
        ..lineTo(-dx, -far)
        ..lineTo(dx, -far)
        ..close();
      return Path.combine(PathOperation.difference, circle, wedge);
  }
}

// ---------------------------------------------------------------------------
// Figur (Form, Farbe, Anzahl, Drehung, Größe, gefüllt)
// ---------------------------------------------------------------------------

/// Anordnung wie Würfelaugen: Mittelpunkte (in Zellenbreiten) und Formradius.
const _dice = <int, (double, List<Offset>)>{
  1: (.46, [Offset(0, 0)]),
  2: (.25, [Offset(-.23, -.23), Offset(.23, .23)]),
  3: (.165, [Offset(-.30, -.30), Offset(0, 0), Offset(.30, .30)]),
  4: (.20, [Offset(-.25, -.25), Offset(.25, -.25), Offset(-.25, .25), Offset(.25, .25)]),
  5: (
    .165,
    [Offset(-.28, -.28), Offset(.28, -.28), Offset(0, 0), Offset(-.28, .28), Offset(.28, .28)]
  ),
  6: (
    .13,
    [
      Offset(-.22, -.32), Offset(.22, -.32), Offset(-.22, 0), //
      Offset(.22, 0), Offset(-.22, .32), Offset(.22, .32),
    ]
  ),
};

/// Maßstab der ganzen Figur: klein, mittel, groß.
const _clusterScale = <double>[.50, .74, .94];

/// Malt eine Form mit Verlauf, Glanzkante, dünner heller Kontur und Leuchten.
///
/// [path] liegt schon an seinem Platz auf der Zeichenfläche. [unit] ist der
/// Formradius in Pixeln und steuert Randstärke und Weichzeichner.
void paintIqShape(
  Canvas canvas,
  Path path,
  IqTintColors colors, {
  required bool filled,
  required double unit,
}) {
  final bounds = path.getBounds();
  final soft = unit >= 5;
  if (filled) {
    if (soft) {
      canvas.drawPath(
        path.shift(Offset(0, unit * .14)),
        Paint()
          ..color = const Color(0x66000814)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * .18),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.base.withValues(alpha: .34)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * .32),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [colors.light, colors.base, colors.dark],
          const [0, .52, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(path);
    final gloss = Rect.fromLTWH(
        bounds.left - 1, bounds.top - 1, bounds.width + 2, bounds.height * .5);
    canvas.drawRect(
      gloss,
      Paint()
        ..shader = ui.Gradient.linear(
          gloss.topCenter,
          gloss.bottomCenter,
          [Colors.white.withValues(alpha: .58), Colors.white.withValues(alpha: .02)],
        ),
    );
    final low = Rect.fromLTWH(bounds.left - 1, bounds.top + bounds.height * .56,
        bounds.width + 2, bounds.height * .45);
    canvas.drawRect(
      low,
      Paint()
        ..shader = ui.Gradient.linear(
          low.topCenter,
          low.bottomCenter,
          [colors.dark.withValues(alpha: 0), colors.dark.withValues(alpha: .6)],
        ),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.9, unit * .07)
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [
            Colors.white.withValues(alpha: .95),
            Colors.white.withValues(alpha: .4),
            Colors.white.withValues(alpha: .12),
          ],
          const [0, .5, 1],
        ),
    );
    return;
  }

  // Nur umrandet: Leuchtröhre, innen fast leer.
  final width = math.max(1.9, unit * .15);
  canvas.drawPath(path, Paint()..color = colors.base.withValues(alpha: .09));
  if (soft) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = colors.base.withValues(alpha: .46)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * .22),
    );
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
          bounds.topLeft, bounds.bottomRight, [colors.light, colors.base]),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, width * .28)
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: .62),
  );
}

class IqFigurePainter extends CustomPainter {
  const IqFigurePainter(this.figure);

  final IqFigure figure;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    final k = _clusterScale[figure.size.clamp(0, 2)];
    final (radius, slots) = _dice[figure.count.clamp(1, 6)]!;
    final r = radius * side * k;
    final colors = iqTintColors(figure.tint);
    final angle = figure.shape.directional ? (figure.turns % 8) * math.pi / 4 : 0.0;
    final base = iqShapePath(figure.shape, r);
    final shape = angle == 0
        ? base
        : base.transform(Matrix4.rotationZ(angle).storage);
    for (final slot in slots) {
      paintIqShape(
        canvas,
        shape.shift(center + slot * side * k),
        colors,
        filled: figure.filled,
        unit: r,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IqFigurePainter oldDelegate) =>
      oldDelegate.figure != figure;
}

/// Eine gezeichnete Figur. Ohne [size] füllt sie die vorhandene Fläche.
class IqFigureView extends StatelessWidget {
  const IqFigureView(this.figure, {super.key, this.size});

  final IqFigure figure;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(
      child: CustomPaint(
        painter: IqFigurePainter(figure),
        size: Size.infinite,
      ),
    );
    final side = size;
    return Semantics(
      image: true,
      label: figure.describe(),
      child: side == null
          ? AspectRatio(aspectRatio: 1, child: paint)
          : SizedBox.square(dimension: side, child: paint),
    );
  }
}

// ---------------------------------------------------------------------------
// Bauteile (Block-Gruppen)
// ---------------------------------------------------------------------------

/// Ein Block mit Kantenfacetten (Bevel), Mittelfläche und Glanzpunkt.
void paintIqBlock(Canvas canvas, Rect rect, IqTintColors colors) {
  final radius = rect.width * .2;
  final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  canvas.drawRRect(
    outer,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [colors.light, colors.base, colors.dark],
        const [0, .5, 1],
      ),
  );
  final inset = rect.width * .18;
  final inner = rect.deflate(inset);
  final innerR = RRect.fromRectAndRadius(inner, Radius.circular(radius * .55));
  canvas.save();
  canvas.clipRRect(outer);
  final frame = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(rect)
    ..addRRect(innerR);
  canvas.save();
  canvas.clipPath(frame);
  final c = rect.center;
  void facet(Offset a, Offset b, Color color) => canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close(),
      Paint()..color = color);
  facet(rect.topLeft, rect.topRight, Colors.white.withValues(alpha: .46));
  facet(rect.topLeft, rect.bottomLeft, Colors.white.withValues(alpha: .24));
  facet(rect.bottomLeft, rect.bottomRight, Colors.black.withValues(alpha: .34));
  facet(rect.topRight, rect.bottomRight, Colors.black.withValues(alpha: .22));
  canvas.restore();
  canvas.drawRRect(
    innerR,
    Paint()
      ..shader = ui.Gradient.linear(
        inner.topLeft,
        inner.bottomRight,
        [
          Color.lerp(colors.base, Colors.white, .22)!,
          colors.base,
          Color.lerp(colors.base, colors.dark, .35)!,
        ],
        const [0, .5, 1],
      ),
  );
  final shine = Rect.fromLTWH(
      inner.left + inner.width * .1, inner.top + inner.height * .08,
      inner.width * .55, inner.height * .26);
  canvas.drawRRect(
    RRect.fromRectAndRadius(shine, Radius.circular(shine.height / 2)),
    Paint()..color = Colors.white.withValues(alpha: .3),
  );
  canvas.restore();
  canvas.drawRRect(
    outer,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = Colors.white.withValues(alpha: .34),
  );
}

class IqPolyominoPainter extends CustomPainter {
  const IqPolyominoPainter(this.piece, this.tint, {required this.span});

  final IqPolyomino piece;
  final IqTint tint;

  /// Wie viele Blöcke in die Fläche passen (für gleich große Blöcke bei
  /// allen Bauteilen eines Rätsels).
  final int span;

  @override
  void paint(Canvas canvas, Size size) {
    if (piece.cells.isEmpty) return;
    final side = math.min(size.width, size.height);
    final cs = side * .92 / math.max(span, math.max(piece.width, piece.height));
    final origin = Offset(
      (size.width - cs * piece.width) / 2,
      (size.height - cs * piece.height) / 2,
    );
    final gap = cs * .04;
    final colors = iqTintColors(tint);
    final rects = [
      for (final (x, y) in piece.cells)
        Rect.fromLTWH(origin.dx + x * cs, origin.dy + y * cs, cs, cs).deflate(gap),
    ];
    final union = Path();
    for (final rect in rects) {
      union.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cs * .2)));
    }
    canvas.drawPath(
      union.shift(Offset(0, cs * .12)),
      Paint()
        ..color = const Color(0x66000814)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cs * .16),
    );
    canvas.drawPath(
      union,
      Paint()
        ..color = colors.base.withValues(alpha: .3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cs * .3),
    );
    for (final rect in rects) {
      paintIqBlock(canvas, rect, colors);
    }
  }

  @override
  bool shouldRepaint(covariant IqPolyominoPainter oldDelegate) =>
      oldDelegate.piece != piece ||
      oldDelegate.tint != tint ||
      oldDelegate.span != span;
}

/// Ein gezeichnetes Bauteil.
class IqPolyominoView extends StatelessWidget {
  const IqPolyominoView(
    this.piece,
    this.tint, {
    super.key,
    this.span = 4,
    this.size,
    this.label,
  });

  final IqPolyomino piece;
  final IqTint tint;
  final int span;
  final double? size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(
      child: CustomPaint(
        painter: IqPolyominoPainter(piece, tint, span: span),
        size: Size.infinite,
      ),
    );
    final side = size;
    return Semantics(
      image: true,
      label: label ?? 'Bauteil aus ${piece.cells.length} Blöcken',
      child: side == null
          ? AspectRatio(aspectRatio: 1, child: paint)
          : SizedBox.square(dimension: side, child: paint),
    );
  }
}
