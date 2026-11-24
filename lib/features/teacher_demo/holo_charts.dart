import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'holo_widgets.dart';

/// Lässt einen Diagrammwert von 0 auf 1 einblenden.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.builder});
  final Widget Function(double t) builder;

  @override
  Widget build(BuildContext context) {
    if (holoAnimationsOff(context)) return builder(1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => builder(t),
    );
  }
}

TextPainter _label(String text, Color color, TextStyle base,
        {double size = 11}) =>
    TextPainter(
      text: TextSpan(
        text: text,
        style: base.copyWith(
            color: color, fontSize: size, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 96);

void _glowStroke(Canvas canvas, Path path, Color color, double width) {
  canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round);
}

/// Untere Grenze der Diagramm-Skala. Trefferquoten unter 40 % liegen am
/// Rand; dadurch werden Unterschiede zwischen 60 und 100 % gut sichtbar.
const double chartFloor = .4;

double _scaled(double v) =>
    ((v.clamp(0.0, 1.0) - chartFloor) / (1 - chartFloor)).clamp(0.0, 1.0);

/// Kompetenz-Radar: ein Strahl je Fach oder Untergruppe, Wert 0..1.
class HoloRadarChart extends StatelessWidget {
  const HoloRadarChart({
    super.key,
    required this.values,
    this.color = HoloPalette.cyan,
    this.size = 260,
  });

  final Map<String, double> values;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kompetenz-Radar: ${values.entries.map((e) => '${e.key} ${(e.value * 100).round()} Prozent').join(', ')}',
      child: SizedBox(
        height: size,
        child: _Reveal(
          builder: (t) => CustomPaint(
            size: Size.infinite,
            painter: _RadarPainter(
                values, color, t, DefaultTextStyle.of(context).style),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.values, this.color, this.t, this.base);
  final Map<String, double> values;
  final Color color;
  final double t;
  final TextStyle base;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 3) return;
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 38;
    Offset at(int i, double v) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return center + Offset(math.cos(a), math.sin(a)) * r * v;
    }

    final grid = Paint()
      ..color = HoloPalette.cyan.withValues(alpha: .18)
      ..style = PaintingStyle.stroke;
    for (final ring in [.25, .5, .75, 1.0]) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final o = at(i, ring);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p..close(), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, at(i, 1), grid);
    }

    final entries = values.entries.toList();
    final shape = Path();
    for (var i = 0; i < n; i++) {
      final o = at(i, _scaled(entries[i].value) * t);
      i == 0 ? shape.moveTo(o.dx, o.dy) : shape.lineTo(o.dx, o.dy);
    }
    shape.close();
    canvas.drawPath(
        shape,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: .45),
            HoloPalette.blue.withValues(alpha: .12),
          ]).createShader(Rect.fromCircle(center: center, radius: r)));
    _glowStroke(canvas, shape, color, 2);

    for (var i = 0; i < n; i++) {
      final v = entries[i].value.clamp(0.0, 1.0);
      final o = at(i, _scaled(v) * t);
      canvas.drawCircle(o, 4, Paint()..color = Colors.white);
      canvas.drawCircle(o, 7, Paint()..color = color.withValues(alpha: .35));
      final tp = _label('${entries[i].key}\n${(v * 100).round()} %',
          HoloPalette.text, base);
      final lo = at(i, 1.18);
      tp.paint(canvas, lo - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.values != values;
}

/// Verlauf über vier Wochen, eine Leuchtlinie je Fach.
class HoloTrendChart extends StatelessWidget {
  const HoloTrendChart({super.key, required this.series, this.height = 200});

  final Map<String, List<double>> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: _Reveal(
            builder: (t) => CustomPaint(
              size: Size.infinite,
              painter: _TrendPainter(
                  series, t, DefaultTextStyle.of(context).style),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final s in series.keys)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 14,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HoloPalette.subject(s),
                    boxShadow: [
                      BoxShadow(color: HoloPalette.subject(s), blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(s,
                    style: const TextStyle(
                        color: HoloPalette.muted, fontSize: 12)),
              ]),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.series, this.t, this.base);
  final Map<String, List<double>> series;
  final double t;
  final TextStyle base;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, bottom = 22.0;
    final w = size.width - left - 8;
    final h = size.height - bottom - 6;
    final grid = Paint()..color = HoloPalette.cyan.withValues(alpha: .12);
    for (final v in [40, 55, 70, 85, 100]) {
      final y = 6 + h * (1 - _scaled(v / 100));
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      final tp = _label('$v %', HoloPalette.muted, base, size: 10);
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    for (var i = 0; i < 4; i++) {
      final x = left + w * i / 3;
      final tp = _label('Woche ${i + 1}', HoloPalette.muted, base, size: 10);
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottom + 6));
    }
    for (final e in series.entries) {
      final color = HoloPalette.subject(e.key);
      final pts = [
        for (var i = 0; i < e.value.length; i++)
          Offset(left + w * i / (e.value.length - 1),
              6 + h * (1 - _scaled(e.value[i]))),
      ];
      if (pts.length < 2) continue;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        final mid = (a.dx + b.dx) / 2;
        path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
      }
      final metric = path.computeMetrics().first;
      final visible = metric.extractPath(0, metric.length * t);
      _glowStroke(canvas, visible, color, 2.4);
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.t != t;
}

/// Balken für Genauigkeit mit Bearbeitungszeit je Fach.
class HoloAccuracyBars extends StatelessWidget {
  const HoloAccuracyBars({
    super.key,
    required this.accuracy,
    required this.seconds,
  });

  final Map<String, double> accuracy;
  final Map<String, double> seconds;

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      builder: (t) => Column(
        children: [
          for (final e in accuracy.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(e.key,
                        style: const TextStyle(
                            color: HoloPalette.text,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withValues(alpha: .06),
                            ),
                          ),
                          Container(
                            height: 16,
                            width: c.maxWidth * e.value.clamp(0, 1) * t,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(colors: [
                                HoloPalette.subject(e.key)
                                    .withValues(alpha: .5),
                                HoloPalette.subject(e.key),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: HoloPalette.subject(e.key)
                                        .withValues(alpha: .6),
                                    blurRadius: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 104,
                    child: Text(
                      '${(e.value * 100).round()} % · ${(seconds[e.key] ?? 0).toStringAsFixed(0)} s',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: HoloPalette.muted,
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Leuchtring für einen Anteil 0..1, z. B. Hilfenutzung.
class HoloRing extends StatelessWidget {
  const HoloRing({
    super.key,
    required this.value,
    required this.label,
    this.color = HoloPalette.cyan,
    this.size = 86,
  });

  final double value;
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: _Reveal(
            builder: (t) => CustomPaint(
              painter: _RingPainter(value.clamp(0, 1) * t, color),
              child: Center(
                child: Text(
                  '${(value * 100).round()} %',
                  style: const TextStyle(
                      color: HoloPalette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 17),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: HoloPalette.muted, fontSize: 12)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(8);
    canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8);
    final arc = Path()..addArc(rect, -math.pi / 2, 2 * math.pi * value);
    _glowStroke(canvas, arc, color, 8);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
