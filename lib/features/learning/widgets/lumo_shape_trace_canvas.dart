import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// 2026-06-05 Iter 20: Form-Nachzeichnen-Canvas mit Demo + Trace Phase.
///
/// Phase 1 (Demo): Strich fuer Strich animierte Vorzeichnung der Form,
/// 2.5 s Lauflaenge. Nochmal-Button zum Wiederholen.
/// Phase 2 (Trace): leerer Canvas, das Kind zeichnet die Form nach.
/// Submit erkennt die Form simpel ueber Bounding-Box + Ecken-Zahl.

enum ShapeTracePhase { demo, trace }

class ShapeTraceResult {
  const ShapeTraceResult({
    required this.correct,
    required this.shape,
    required this.feedback,
  });
  final bool correct;
  final String shape;
  final String feedback;
}

class LumoShapeTraceCanvas extends StatefulWidget {
  const LumoShapeTraceCanvas({
    super.key,
    required this.shape,
    this.height = 320,
    this.onSubmitted,
  });

  /// Eine von: square, rectangle, circle, triangle, star
  final String shape;
  final double height;
  final ValueChanged<ShapeTraceResult>? onSubmitted;

  @override
  State<LumoShapeTraceCanvas> createState() => _LumoShapeTraceCanvasState();
}

class _LumoShapeTraceCanvasState extends State<LumoShapeTraceCanvas>
    with SingleTickerProviderStateMixin {
  ShapeTracePhase _phase = ShapeTracePhase.demo;
  late final AnimationController _demoCtrl;
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _active;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _demoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDemo());
  }

  @override
  void dispose() {
    _demoCtrl.dispose();
    super.dispose();
  }

  void _startDemo() {
    _demoCtrl.forward(from: 0);
  }

  void _toTracePhase() {
    setState(() => _phase = ShapeTracePhase.trace);
  }

  void _start(Offset p) {
    if (_phase != ShapeTracePhase.trace || _submitted) return;
    setState(() => _active = <Offset>[p]);
  }

  void _move(Offset p) {
    if (_active == null) return;
    if (_active!.isNotEmpty &&
        (_active!.last - p).distance < 1.5) {
      return;
    }
    setState(() => _active = <Offset>[..._active!, p]);
  }

  void _end() {
    if (_active == null) return;
    setState(() {
      if (_active!.length >= 2) _strokes.add(_active!);
      _active = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _active = null;
    });
  }

  void _submit() {
    if (_submitted) return;
    final result = _evaluate();
    setState(() => _submitted = true);
    widget.onSubmitted?.call(result);
  }

  /// Simpel-Evaluator: prueft ob die Form gemalt wurde.
  /// - Mindestlaenge (Summe Strecken aller Strokes)
  /// - Bounding-Box-Verhaeltnis nahe dem erwarteten
  /// - Ecken-Zahl: angularer Wechsel >70 Grad zaehlt als Ecke
  /// Permissiv fuer K1-K2 - Effort ist das Wichtigste.
  ShapeTraceResult _evaluate() {
    final pts = _allPoints();
    if (pts.length < 8) {
      return ShapeTraceResult(
        correct: false,
        shape: widget.shape,
        feedback: 'Probier es nochmal. Zeichne langsam und groesser.',
      );
    }
    final bbox = _boundingBox(pts);
    if (bbox.width < 60 || bbox.height < 60) {
      return ShapeTraceResult(
        correct: false,
        shape: widget.shape,
        feedback: 'Versuch es groesser - nutze die ganze Flaeche.',
      );
    }
    final aspect = bbox.width / bbox.height;
    final corners = _detectCorners(pts);
    final totalLen = _totalLength(pts);

    // Form-spezifische Toleranzen.
    final ok = switch (widget.shape) {
      'circle' => corners <= 2 && totalLen > 200 && (aspect > 0.7 && aspect < 1.4),
      'square' => corners >= 3 && (aspect > 0.7 && aspect < 1.4),
      'rectangle' => corners >= 3,
      'triangle' => corners >= 2 && corners <= 4,
      'star' => corners >= 5,
      _ => true,
    };
    return ShapeTraceResult(
      correct: ok,
      shape: widget.shape,
      feedback: ok
          ? 'Super gezeichnet!'
          : 'Schau nochmal hin und versuch es genauer.',
    );
  }

  List<Offset> _allPoints() {
    final out = <Offset>[];
    for (final s in _strokes) {
      out.addAll(s);
    }
    if (_active != null) out.addAll(_active!);
    return out;
  }

  Rect _boundingBox(List<Offset> pts) {
    var minX = pts.first.dx, minY = pts.first.dy;
    var maxX = pts.first.dx, maxY = pts.first.dy;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _totalLength(List<Offset> pts) {
    var sum = 0.0;
    for (var i = 1; i < pts.length; i++) {
      sum += (pts[i] - pts[i - 1]).distance;
    }
    return sum;
  }

  int _detectCorners(List<Offset> pts) {
    if (pts.length < 6) return 0;
    var corners = 0;
    // Sample alle ~6 Punkte zur Winkelberechnung
    const step = 6;
    var lastDir = math.atan2(pts[step].dy - pts[0].dy, pts[step].dx - pts[0].dx);
    for (var i = step; i + step < pts.length; i += step) {
      final dir = math.atan2(
          pts[i + step].dy - pts[i].dy, pts[i + step].dx - pts[i].dx);
      var diff = (dir - lastDir).abs();
      if (diff > math.pi) diff = 2 * math.pi - diff;
      if (diff > 1.22) corners++; // ~70 Grad
      lastDir = dir;
    }
    return corners;
  }

  @override
  Widget build(BuildContext context) {
    final shapeLabel = _shapeLabelDe(widget.shape);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFAF0), Color(0xFFFFF7E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFFFD68A), width: 1.4),
      ),
      child: Column(
        children: [
          _PhaseHeader(phase: _phase, shapeLabel: shapeLabel),
          SizedBox(
            height: widget.height,
            child: _phase == ShapeTracePhase.demo
                ? _DemoStage(
                    shape: widget.shape,
                    progress: _demoCtrl,
                  )
                : _TraceStage(
                    strokes: _strokes,
                    active: _active,
                    onStart: _start,
                    onMove: _move,
                    onEnd: _end,
                    submitted: _submitted,
                  ),
          ),
          const SizedBox(height: 8),
          _ActionBar(
            phase: _phase,
            submitted: _submitted,
            hasStrokes: _strokes.isNotEmpty,
            onReplayDemo: _startDemo,
            onToTrace: _toTracePhase,
            onUndo: _undo,
            onClear: _clear,
            onSubmit: _submit,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _shapeLabelDe(String s) {
    return switch (s) {
      'square' => 'Quadrat',
      'rectangle' => 'Rechteck',
      'circle' => 'Kreis',
      'triangle' => 'Dreieck',
      'star' => 'Stern',
      _ => 'Form',
    };
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({required this.phase, required this.shapeLabel});
  final ShapeTracePhase phase;
  final String shapeLabel;

  @override
  Widget build(BuildContext context) {
    final isDemo = phase == ShapeTracePhase.demo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDemo
                  ? const Color(0xFFFFEDD5)
                  : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              border: Border.all(
                color: isDemo
                    ? const Color(0xFFFB923C)
                    : const Color(0xFF22C55E),
                width: 1.3,
              ),
            ),
            child: Text(
              isDemo ? '👀 Schau zu' : '✏️ Jetzt du',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isDemo
                    ? const Color(0xFF9A3412)
                    : const Color(0xFF14532D),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDemo
                  ? 'So malt Lumo das $shapeLabel'
                  : 'Zeichne jetzt das $shapeLabel selbst',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7C2D12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStage extends StatelessWidget {
  const _DemoStage({required this.shape, required this.progress});
  final String shape;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => CustomPaint(
          painter: _ShapeDemoPainter(shape: shape, t: progress.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _TraceStage extends StatelessWidget {
  const _TraceStage({
    required this.strokes,
    required this.active,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.submitted,
  });
  final List<List<Offset>> strokes;
  final List<Offset>? active;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onMove;
  final VoidCallback onEnd;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              EagerHorizontalDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      EagerHorizontalDragRecognizer>(
                () => EagerHorizontalDragRecognizer(),
                (instance) {},
              ),
            },
            child: Listener(
              onPointerDown: (e) =>
                  onStart(_clamp(e.localPosition, size)),
              onPointerMove: (e) =>
                  onMove(_clamp(e.localPosition, size)),
              onPointerUp: (_) => onEnd(),
              onPointerCancel: (_) => onEnd(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB), width: 1.4),
                ),
                child: CustomPaint(
                  painter: _TracePainter(strokes: strokes, active: active),
                  size: Size.infinite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _clamp(Offset p, Size s) {
    return Offset(
      p.dx.clamp(0.0, s.width),
      p.dy.clamp(0.0, s.height),
    );
  }
}

/// Eager-Drag-Recognizer um den Scrollable-Parent zu blockieren,
/// damit das Trace-Canvas nicht mit dem Eltern-Scroll konkurriert.
class EagerHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.phase,
    required this.submitted,
    required this.hasStrokes,
    required this.onReplayDemo,
    required this.onToTrace,
    required this.onUndo,
    required this.onClear,
    required this.onSubmit,
  });
  final ShapeTracePhase phase;
  final bool submitted;
  final bool hasStrokes;
  final VoidCallback onReplayDemo;
  final VoidCallback onToTrace;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (phase == ShapeTracePhase.demo) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        child: Row(
          children: [
            _PillButton(
              icon: Icons.replay_rounded,
              label: 'Nochmal',
              color: const Color(0xFFFB923C),
              onTap: onReplayDemo,
            ),
            const Spacer(),
            _PillButton(
              icon: Icons.arrow_forward_rounded,
              label: 'Jetzt ich!',
              color: const Color(0xFF22C55E),
              onTap: onToTrace,
              filled: true,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Row(
        children: [
          _PillButton(
            icon: Icons.undo_rounded,
            label: 'Zurueck',
            color: const Color(0xFF6366F1),
            onTap: hasStrokes && !submitted ? onUndo : null,
          ),
          const SizedBox(width: 8),
          _PillButton(
            icon: Icons.refresh_rounded,
            label: 'Neu',
            color: const Color(0xFFEF4444),
            onTap: hasStrokes && !submitted ? onClear : null,
          ),
          const Spacer(),
          _PillButton(
            icon: Icons.check_circle_rounded,
            label: 'Fertig',
            color: const Color(0xFF22C55E),
            onTap: hasStrokes && !submitted ? onSubmit : null,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = filled ? color : Colors.white;
    final fg = filled ? Colors.white : color;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            border: Border.all(color: color, width: 1.6),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter der die Form progressiv zeichnet je nach t (0..1).
class _ShapeDemoPainter extends CustomPainter {
  _ShapeDemoPainter({required this.shape, required this.t});
  final String shape;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 24.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final origin = Offset(pad, pad);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFB923C);

    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFDE68A);

    final path = _buildPath(shape, origin, w, h);
    // Voll-Guide-Pfad (sehr blass) als Orientierung
    canvas.drawPath(path, guide);

    // Bis t den Pfad partial zeichnen
    final metrics = path.computeMetrics().toList(growable: false);
    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    var consumed = totalLen * t;
    for (final m in metrics) {
      if (consumed <= 0) break;
      final len = math.min(consumed, m.length);
      final sub = m.extractPath(0, len);
      canvas.drawPath(sub, paint);
      consumed -= m.length;
    }

    // Stift-Spitze als kleiner Kreis am aktuellen Punkt
    if (t > 0 && t < 1) {
      double headLen = totalLen * t;
      for (final m in metrics) {
        if (headLen <= m.length) {
          final tan = m.getTangentForOffset(headLen);
          if (tan != null) {
            canvas.drawCircle(
                tan.position, 7,
                Paint()..color = const Color(0xFFFB923C));
            canvas.drawCircle(
                tan.position, 3.5,
                Paint()..color = Colors.white);
          }
          break;
        }
        headLen -= m.length;
      }
    }
  }

  Path _buildPath(String shape, Offset o, double w, double h) {
    final p = Path();
    switch (shape) {
      case 'square':
        final side = math.min(w, h);
        final cx = o.dx + (w - side) / 2;
        final cy = o.dy + (h - side) / 2;
        p.moveTo(cx, cy);
        p.lineTo(cx + side, cy);
        p.lineTo(cx + side, cy + side);
        p.lineTo(cx, cy + side);
        p.close();
        break;
      case 'rectangle':
        final rw = w;
        final rh = h * 0.65;
        final cx = o.dx;
        final cy = o.dy + (h - rh) / 2;
        p.moveTo(cx, cy);
        p.lineTo(cx + rw, cy);
        p.lineTo(cx + rw, cy + rh);
        p.lineTo(cx, cy + rh);
        p.close();
        break;
      case 'circle':
        final r = math.min(w, h) / 2;
        final cx = o.dx + w / 2;
        final cy = o.dy + h / 2;
        p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        break;
      case 'triangle':
        final cx = o.dx + w / 2;
        final top = o.dy;
        final bottomY = o.dy + h;
        p.moveTo(cx, top);
        p.lineTo(o.dx + w, bottomY);
        p.lineTo(o.dx, bottomY);
        p.close();
        break;
      case 'star':
        final cx = o.dx + w / 2;
        final cy = o.dy + h / 2;
        final r1 = math.min(w, h) / 2;
        final r2 = r1 * 0.45;
        const points = 5;
        for (var i = 0; i < points * 2; i++) {
          final r = i.isEven ? r1 : r2;
          final ang = -math.pi / 2 + i * math.pi / points;
          final x = cx + r * math.cos(ang);
          final y = cy + r * math.sin(ang);
          if (i == 0) {
            p.moveTo(x, y);
          } else {
            p.lineTo(x, y);
          }
        }
        p.close();
        break;
    }
    return p;
  }

  @override
  bool shouldRepaint(_ShapeDemoPainter old) =>
      old.t != t || old.shape != shape;
}

class _TracePainter extends CustomPainter {
  _TracePainter({required this.strokes, required this.active});
  final List<List<Offset>> strokes;
  final List<Offset>? active;

  @override
  void paint(Canvas canvas, Size size) {
    // Sanfter Hintergrund-Hint: ein helles Quadrat-Grid?
    // Bewusst weglassen damit der Fokus auf der Zeichnung bleibt.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2563EB);
    for (final s in strokes) {
      _drawStroke(canvas, s, paint);
    }
    if (active != null) {
      _drawStroke(canvas, active!, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.isEmpty) return;
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.strokes != strokes || old.active != active;
}
