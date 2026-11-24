import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/learning/lumo_learning_domain.dart';

/// The second outline is the geometric reflection of the actual first outline.
class SymmetryWorkbench extends StatefulWidget {
  const SymmetryWorkbench(
      {super.key,
      required this.shape,
      required this.turnable,
      required this.enabled});
  final String shape;
  final bool turnable;
  final bool enabled;
  static const _shapes = {
    'ein Quadrat': 'square',
    'ein Rechteck, das kein Quadrat ist': 'rectangle',
    'ein gleichseitiges Dreieck': 'three',
    'ein gleichschenkliges Dreieck, das nicht gleichseitig ist': 'isosceles',
    'ein Dreieck mit drei verschieden langen Seiten': 'scalene',
    'eine Raute, die kein Quadrat ist': 'diamond',
    'ein Parallelogramm, das weder Rechteck noch Raute ist': 'slanted',
    'ein gleichschenkliges Trapez': 'trapezoid',
    'ein Drachenviereck, das keine Raute ist': 'kite',
    'ein regelmäßiges Fünfeck': 'five',
    'ein regelmäßiges Sechseck': 'six',
    'ein regelmäßiges Achteck': 'eight',
    'ein Halbkreis': 'half',
    'ein Herz': 'heart',
    'ein Stern mit fünf gleichen Zacken': 'star',
    'ein Herz aus Papier': 'heart',
    'einen Schmetterling aus Papier': 'butterfly',
    'einen Kreis aus Papier': 'circle',
    'ein Quadrat aus Papier': 'square',
  };
  static String? shapeFor(TaskInstance task) {
    if (task.subject != LearningSubject.mathematik ||
        task.parameters['visual'] != 'symmetry') {
      return null;
    }
    final match = RegExp(
            r'^Wie viele Symmetrieachsen hat (.+)\?$|^Kannst du (.+) so falten, dass beide Hälften genau aufeinanderpassen\?$')
        .firstMatch(task.prompt);
    return match == null ? null : _shapes[match[1] ?? match[2]];
  }

  @override
  State<SymmetryWorkbench> createState() => _SymmetryWorkbenchState();
}

class _SymmetryWorkbenchState extends State<SymmetryWorkbench> {
  double angle = 90;
  bool reflect = false;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: const Color(0xff143d53),
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            widget.turnable
                ? 'Teste deine Spiegelachse'
                : 'Probiere die Faltlinie aus',
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        SizedBox(
            height: 155,
            child: CustomPaint(
                painter: _Reflection(widget.shape, angle, reflect))),
        if (widget.turnable)
          Slider(
              value: angle,
              min: 0,
              max: 180,
              divisions: 360,
              label: '${angle.toStringAsFixed(1)}°',
              semanticFormatterCallback: (v) =>
                  'Spiegelachse ${v.round()} Grad',
              onChanged:
                  widget.enabled ? (v) => setState(() => angle = v) : null),
        Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
                key: const ValueKey('mirror-preview'),
                label: const Text('Spiegelbild darüberlegen'),
                selected: reflect,
                onSelected: widget.enabled
                    ? (v) => setState(() => reflect = v)
                    : null)),
        if (reflect)
          const Text('Decken sich die beiden Umrisse?',
              style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
      ]));
}

class _Reflection extends CustomPainter {
  const _Reflection(this.shape, this.angle, this.reflect);
  final String shape;
  final double angle;
  final bool reflect;
  Path _polygon(List<Offset> pts) => Path()..addPolygon(pts, true);
  Path _regular(int corners, {bool star = false}) {
    final count = star ? 2 * corners : corners;
    return _polygon([
      for (var i = 0; i < count; i++)
        Offset.fromDirection(
            i * 2 * math.pi / count - math.pi / 2, star && i.isOdd ? .45 : 1)
    ]);
  }

  Path _path() {
    switch (shape) {
      case 'square':
        return Path()..addRect(const Rect.fromLTRB(-.8, -.8, .8, .8));
      case 'rectangle':
        return Path()..addRect(const Rect.fromLTRB(-1, -.55, 1, .55));
      case 'three':
        return _regular(3);
      case 'five':
        return _regular(5);
      case 'six':
        return _regular(6);
      case 'eight':
        return _regular(8);
      case 'star':
        return _regular(5, star: true);
      case 'isosceles':
        return _polygon(
            const [Offset(0, -.95), Offset(.6, .8), Offset(-.6, .8)]);
      case 'scalene':
        return _polygon(
            const [Offset(-.7, -.95), Offset(1, .65), Offset(-.9, .85)]);
      case 'diamond':
        return _polygon(
            const [Offset(0, -.7), Offset(1, 0), Offset(0, .7), Offset(-1, 0)]);
      case 'slanted':
        return _polygon(const [
          Offset(-.45, -.55),
          Offset(1, -.55),
          Offset(.45, .55),
          Offset(-1, .55)
        ]);
      case 'trapezoid':
        return _polygon(const [
          Offset(-.5, -.65),
          Offset(.5, -.65),
          Offset(1, .65),
          Offset(-1, .65)
        ]);
      case 'kite':
        return _polygon(const [
          Offset(0, -.85),
          Offset(.62, -.32),
          Offset(0, .95),
          Offset(-.62, -.32)
        ]);
      case 'circle':
        return Path()..addOval(const Rect.fromLTRB(-.85, -.85, .85, .85));
      case 'half':
        return Path()
          ..moveTo(-1, .4)
          ..arcTo(const Rect.fromLTRB(-1, -.6, 1, 1.4), math.pi, math.pi, false)
          ..close();
      case 'heart':
        return Path()
          ..moveTo(0, .9)
          ..cubicTo(-1.8, -.24, -.65, -1.42, 0, -.55)
          ..cubicTo(.65, -1.42, 1.8, -.24, 0, .9)
          ..close();
      default:
        return Path()
          ..moveTo(0, -.18)
          ..cubicTo(-1.45, -1.8, -1.43, .36, -.37, .13)
          ..cubicTo(-.98, .27, -.65, 1.48, 0, .36)
          ..cubicTo(.65, 1.48, .98, .27, .37, .13)
          ..cubicTo(1.43, .36, 1.45, -1.8, 0, -.18)
          ..close();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width * .35, size.height * .42);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    final path = _path();
    canvas.drawPath(path, Paint()..color = const Color(0xff29788f));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 / scale
      ..color = const Color(0xff92f7ee);
    canvas.drawPath(path, line);
    final theta = angle * math.pi / 180;
    final delta = Offset.fromDirection(theta, 1.5);
    canvas.drawLine(
        -delta,
        delta,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5 / scale);
    if (reflect) {
      canvas.rotate(theta);
      canvas.scale(1, -1);
      canvas.rotate(-theta);
      line.color = const Color(0xffffc05c);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_Reflection old) =>
      old.shape != shape || old.angle != angle || old.reflect != reflect;
}
