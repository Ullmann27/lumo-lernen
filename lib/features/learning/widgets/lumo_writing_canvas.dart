import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/writing/writing_domain.dart';

class LumoWritingCanvas extends StatefulWidget {
  const LumoWritingCanvas({
    super.key,
    required this.template,
    this.mode = WritingMode.trace,
    this.height = 300,
    this.onChanged,
    this.onEvaluated,
  });

  final WritingTemplate template;
  final WritingMode mode;
  final double height;
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
    if (active.points.isNotEmpty && _distance(active.points.last, point) > 32) {
      _finishStroke();
      return;
    }

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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: (details) => _startStroke(details.localPosition, size),
              onPanUpdate: (details) => _appendPoint(details.localPosition, size),
              onPanEnd: (_) => _finishStroke(),
              onPanCancel: _finishStroke,
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
            ),
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
    final guidePaint = Paint()
      ..color = mode == WritingMode.guided
          ? LumoColors.orange.withOpacity(.34)
          : LumoColors.ink300.withOpacity(.22)
      ..strokeWidth = mode == WritingMode.guided ? 18 : 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final startPaint = Paint()..color = LumoColors.orange.withOpacity(.75);

    for (final stroke in template.strokes) {
      final start = _map(stroke.startX, stroke.startY, size);
      final end = _map(stroke.endX, stroke.endY, size);
      canvas.drawLine(start, end, guidePaint);
      canvas.drawCircle(start, 6, startPaint);
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
