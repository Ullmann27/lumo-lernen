import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/writing/writing_domain.dart';
import '../../../domain/writing/writing_path_geometry.dart';

class LumoWritingCanvas extends StatefulWidget {
  const LumoWritingCanvas({
    super.key,
    required this.template,
    this.mode = WritingMode.trace,
    this.height = 300,
    this.onChanged,
    this.onEvaluated,
    this.initialStrokes = const <Stroke>[],
  });

  final WritingTemplate template;
  final WritingMode mode;
  final double height;
  final List<Stroke> initialStrokes;
  final ValueChanged<List<Stroke>>? onChanged;
  final ValueChanged<WritingEvaluation>? onEvaluated;

  @override
  State<LumoWritingCanvas> createState() => _LumoWritingCanvasState();
}

class _LumoWritingCanvasState extends State<LumoWritingCanvas> {
  final _smoother = const StrokeSmoother();
  final _evaluator = const WritingEvaluator();
  final List<Stroke> _strokes = <Stroke>[];
  Stroke? _activeStroke;
  DateTime? _startedAt;
  // Frueher: Scrollable.maybeOf(context) im PointerDown-Handler, um den
  // Eltern-Scroll wegen Pan-Konflikt festzuhalten. Das registrierte eine
  // Inherited-Dependency zur Laufzeit; beim Disposal des Canvas konnte
  // das den "_dependents.isEmpty"-Assert in Flutter framework.dart aus-
  // loesen. Jetzt rendert das Canvas nur noch im Vollbild-Modal ohne
  // Scrollable-Parent, sodass dieser Hack nicht mehr noetig ist.

  @override
  void initState() {
    super.initState();
    _strokes.addAll(widget.initialStrokes);
    if (_strokes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emitEvaluation();
      });
    }
  }

  void _startStroke(Offset localPosition, Size size) {
    final point = _pointFromLocalPosition(localPosition, size);
    if (point == null) return;

    _startedAt ??= DateTime.now();
    setState(() {
      _activeStroke = Stroke(
        id: 'stroke_${DateTime.now().microsecondsSinceEpoch}',
        points: <StrokePoint>[point],
      );
    });
  }

  void _appendPoint(Offset localPosition, Size size) {
    final active = _activeStroke;
    if (active == null) return;
    final point = _pointFromLocalPosition(localPosition, size);
    if (point == null) return;
    if (active.points.isNotEmpty && _distance(active.points.last, point) < .65) return;

    final next = <StrokePoint>[...active.points, point];
    setState(() => _activeStroke = Stroke(id: active.id, points: next));
  }

  void _finishStroke() {
    final active = _activeStroke;
    if (active == null) return;
    final smoothed = active.points.length >= 2 ? _smoother.smooth(active) : active;
    setState(() {
      if (smoothed.points.length >= 2) _strokes.add(smoothed);
      _activeStroke = null;
    });
    widget.onChanged?.call(List<Stroke>.unmodifiable(_strokes));
    _emitEvaluation();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onChanged?.call(List<Stroke>.unmodifiable(_strokes));
    _emitEvaluation();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
      _startedAt = null;
    });
    widget.onChanged?.call(const <Stroke>[]);
    _emitEvaluation();
  }

  void _emitEvaluation() {
    final started = _startedAt ?? DateTime.now();
    final attempt = WritingAttempt(
      taskInstanceId: 'preview',
      childId: 'preview',
      targetSymbol: widget.template.symbol,
      mode: widget.mode,
      strokes: List<Stroke>.unmodifiable(_strokes),
      startedAt: started,
      finishedAt: DateTime.now(),
    );
    widget.onEvaluated?.call(
      _evaluator.evaluate(template: widget.template, attempt: attempt),
    );
  }

  StrokePoint? _pointFromLocalPosition(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (localPosition.dx < 0 || localPosition.dy < 0 || localPosition.dx > size.width || localPosition.dy > size.height) {
      return null;
    }
    final x = (localPosition.dx / size.width * widget.template.viewBoxWidth)
        .clamp(0.0, widget.template.viewBoxWidth);
    final y = (localPosition.dy / size.height * widget.template.viewBoxHeight)
        .clamp(0.0, widget.template.viewBoxHeight);
    return StrokePoint(
      x: x,
      y: y,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      pressure: 1,
    );
  }

  double _distance(StrokePoint a, StrokePoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        final size = Size(width, widget.height);
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LumoRadius.xl),
            border: Border.all(color: LumoColors.orange.withOpacity(.28), width: 2),
            boxShadow: [
              BoxShadow(
                color: LumoColors.orange.withOpacity(.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.xl - 2),
            // Heinz 2026-05-22: 'Schreibflaeche bewegt sich beim Schreiben,
            // touchflaeche nicht benutzbar'. Ursache: GestureDetector mit
            // onPan* konkurriert in der Gesture-Arena mit jedem moeglichen
            // Scroll-Vorfahren. Loesung: Listener (Raw-Pointer-Events)
            // statt GestureDetector. Listener feuert sofort auf jeden
            // Touch, keine Arena-Konkurrenz.
            //
            // 2026-06-04 Heinz: 'Bildschirm geht beim Schreiben mit'.
            // Listener allein reichte NICHT - das Scrollable im Eltern-
            // Widget bekam die Pan-Events trotzdem und scrollte. Fix:
            // zusaetzlich RawGestureDetector mit EagerGestureRecognizer
            // drumherum - der gewinnt die Gesture-Arena sofort und
            // blockt damit den Scrollable-Parent.
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                  (EagerGestureRecognizer instance) {},
                ),
              },
              child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                _startStroke(event.localPosition, size);
              },
              onPointerMove: (event) {
                _appendPoint(event.localPosition, size);
              },
              onPointerUp: (_) => _finishStroke(),
              onPointerCancel: (_) => _finishStroke(),
              child: CustomPaint(
                painter: _WritingCanvasPainter(
                  template: widget.template,
                  mode: widget.mode,
                  strokes: _activeStroke == null
                      ? _strokes
                      : <Stroke>[..._strokes, _activeStroke!],
                ),
                child: const SizedBox.expand(),
              ),
              ), // close inner Listener
            ), // close RawGestureDetector
          ),
        );
      }),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _CanvasButton(
            label: 'Zurueck',
            icon: Icons.undo_rounded,
            onTap: _strokes.isEmpty ? null : _undo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CanvasButton(
            label: 'Neu starten',
            icon: Icons.refresh_rounded,
            onTap: (_strokes.isEmpty && _activeStroke == null) ? null : _clear,
          ),
        ),
      ]),
    ]);
  }
}

class _CanvasButton extends StatelessWidget {
  const _CanvasButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : .45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? LumoColors.orangeSurface : LumoColors.ink100,
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            border: Border.all(color: enabled ? LumoColors.orange.withOpacity(.28) : LumoColors.ink100),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: enabled ? LumoColors.orange : LumoColors.ink300),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: enabled ? LumoColors.orange : LumoColors.ink300,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WritingCanvasPainter extends CustomPainter {
  const _WritingCanvasPainter({
    required this.template,
    required this.mode,
    required this.strokes,
  });

  final WritingTemplate template;
  final WritingMode mode;
  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGuideGrid(canvas, size);
    if (mode != WritingMode.free) _drawTemplate(canvas, size);
    _drawChildStrokes(canvas, size);
  }

  void _drawGuideGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LumoColors.orange.withOpacity(.07)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * .25), Offset(size.width, size.height * .25), paint);
    canvas.drawLine(Offset(0, size.height * .50), Offset(size.width, size.height * .50), paint);
    canvas.drawLine(Offset(0, size.height * .75), Offset(size.width, size.height * .75), paint);
  }

  void _drawTemplate(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (mode == WritingMode.guided ? LumoColors.orange : LumoColors.ink900).withOpacity(.20)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in template.strokes) {
      final points = WritingPathGeometry.sample(stroke.pathData);
      if (points.isEmpty) continue;
      final first = _map(points.first.x, points.first.y, size);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final point in points.skip(1)) {
        final mapped = _map(point.x, point.y, size);
        path.lineTo(mapped.dx, mapped.dy);
      }
      canvas.drawPath(path, paint);
      // The number and short arrow describe the same path the evaluator uses.
      final label = TextPainter(
        text: TextSpan(text: '${stroke.order}', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: LumoColors.orange)),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, first + const Offset(-14, -18));
      if (points.length > 4) {
        final index = (points.length * .22).round().clamp(1, points.length - 1);
        final tip = _map(points[index].x, points[index].y, size);
        final previous = _map(points[index - 1].x, points[index - 1].y, size);
        final angle = math.atan2(tip.dy - previous.dy, tip.dx - previous.dx);
        final arrow = Path()
          ..moveTo(tip.dx - 9 * math.cos(angle - .5), tip.dy - 9 * math.sin(angle - .5))
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - 9 * math.cos(angle + .5), tip.dy - 9 * math.sin(angle + .5));
        canvas.drawPath(arrow, Paint()..color = LumoColors.orange.withOpacity(.65)
          ..strokeWidth = 2 ..style = PaintingStyle.stroke);
      }
    }
  }

  void _drawChildStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LumoColors.orange
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final first = _mapPoint(stroke.points.first, size);
      final path = Path()..moveTo(first.dx, first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final point = _mapPoint(stroke.points[i], size);
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  Offset _mapPoint(StrokePoint point, Size size) => _map(point.x, point.y, size);

  Offset _map(double x, double y, Size size) {
    return Offset(
      x / template.viewBoxWidth * size.width,
      y / template.viewBoxHeight * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant _WritingCanvasPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.mode != mode ||
        oldDelegate.strokes != strokes;
  }
}
