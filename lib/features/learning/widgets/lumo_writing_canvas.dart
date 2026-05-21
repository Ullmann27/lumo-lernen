import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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
  ScrollHoldController? _scrollHold;

  @override
  void dispose() {
    _releaseParentScroll();
    super.dispose();
  }

  void _holdParentScroll() {
    if (_scrollHold != null) return;
    final scrollable = Scrollable.maybeOf(context);
    _scrollHold = scrollable?.position.hold(() {});
  }

  void _releaseParentScroll() {
    final hold = _scrollHold;
    _scrollHold = null;
    hold?.cancel();
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
    if (active == null) {
      _releaseParentScroll();
      return;
    }
    final smoothed = active.points.length >= 2 ? _smoother.smooth(active) : active;
    setState(() {
      if (smoothed.points.length >= 2) _strokes.add(smoothed);
      _activeStroke = null;
    });
    _releaseParentScroll();
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
      _useLooseEvaluation
          ? _evaluateLooseWriting(attempt)
          : _evaluator.evaluate(template: widget.template, attempt: attempt),
    );
  }

  bool get _isFreeWordMode => widget.mode == WritingMode.free && widget.template.strokes.isEmpty;

  bool get _useLooseEvaluation {
    final target = widget.template.symbol.trim();
    if (_isFreeWordMode) return true;
    return RegExp(r'^[A-ZÄÖÜ0-9]{1,2}$').hasMatch(target);
  }

  WritingEvaluation _evaluateLooseWriting(WritingAttempt attempt) {
    final usableStrokes = attempt.strokes.where((stroke) => stroke.points.length >= 2).toList(growable: false);
    if (usableStrokes.isEmpty) {
      return const WritingEvaluation(
        overallScore: 0,
        startPointScore: 0,
        directionScore: 0,
        coverageScore: 0,
        pathDistanceScore: 0,
        strokeOrderScore: 0,
        mirrored: false,
        incomplete: true,
        hints: <WritingHint>[
          WritingHint(type: WritingHintType.incomplete, message: 'Schreibe langsam auf die Linien.'),
        ],
      );
    }

    // Erwartete Strichanzahl: bevorzugt die Template-Striche (echte Buchstaben-Form),
    // sonst grob 2 Striche pro Buchstabe als Heuristik fuer Woerter.
    final symbolLength = widget.template.symbol.replaceAll(RegExp(r'\s+'), '').length.clamp(1, 12);
    final templateStrokeCount = widget.template.strokes.length;
    final expectedStrokes = templateStrokeCount > 0
        ? templateStrokeCount
        : (symbolLength * 2).clamp(2, 24);

    final strokeCoverage = (usableStrokes.length / expectedStrokes).clamp(0.0, 1.0).toDouble();
    final boundsCoverage = _boundsCoverage(usableStrokes).clamp(0.0, 1.0).toDouble();
    final pointCount = usableStrokes.fold<int>(0, (sum, s) => sum + s.points.length);

    // Mindestpunktzahl pro erwartetem Strich, damit ein einzelner Wischer nicht
    // 100% Coverage bekommt. Erwartet werden mindestens ~12 Punkte pro Strich.
    final minPoints = expectedStrokes * 8;
    final pointDensity = (pointCount / minPoints).clamp(0.0, 1.0).toDouble();

    // Neue strengere Formel:
    //  - kein freier Basisbonus mehr
    //  - alle drei Faktoren muessen erreicht sein
    //  - Multiplikative Penalty, wenn ein Faktor sehr niedrig ist
    final base = (strokeCoverage * .42 + boundsCoverage * .32 + pointDensity * .26)
        .clamp(0.0, 1.0)
        .toDouble();

    // Harte Penalty: nur 1 Strich auf einem Mehr-Strich-Symbol = klar falsch.
    final tooFewStrokes = usableStrokes.length < (expectedStrokes / 2).ceil();
    final score = (tooFewStrokes ? base * .55 : base).clamp(0.0, 1.0).toDouble();

    final String hintMessage;
    if (score >= .80) {
      hintMessage = 'Gut. Du hast das Ziel sauber geschrieben.';
    } else if (tooFewStrokes) {
      hintMessage = 'Zu wenig Striche. Schreibe das Zeichen vollstaendig nach.';
    } else if (boundsCoverage < .45) {
      hintMessage = 'Schreibe groesser, so dass das Feld gut ausgefuellt ist.';
    } else {
      hintMessage = 'Achte auf die Form. Schreibe langsam ueber die Vorlage.';
    }

    return WritingEvaluation(
      overallScore: score,
      startPointScore: 1,
      directionScore: score,
      coverageScore: boundsCoverage,
      pathDistanceScore: score,
      strokeOrderScore: tooFewStrokes ? .4 : 1,
      mirrored: false,
      incomplete: score < .60,
      hints: <WritingHint>[
        WritingHint(type: WritingHintType.coverage, message: hintMessage),
      ],
    );
  }

  double _boundsCoverage(List<Stroke> strokes) {
    final points = strokes.expand((stroke) => stroke.points).toList(growable: false);
    if (points.isEmpty) return 0;
    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final width = ((maxX - minX) / widget.template.viewBoxWidth).clamp(0.0, 1.0);
    final height = ((maxY - minY) / widget.template.viewBoxHeight).clamp(0.0, 1.0);
    return ((width + height) / 2).toDouble();
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
            child: Listener(
              onPointerDown: (_) => _holdParentScroll(),
              onPointerUp: (_) => _releaseParentScroll(),
              onPointerCancel: (_) => _releaseParentScroll(),
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
    final symbol = template.symbol.trim().isEmpty ? 'A' : template.symbol.trim();
    final symbolLength = symbol.replaceAll(RegExp(r'\s+'), '').length.clamp(1, 12);
    final fontSize = symbolLength <= 1
        ? size.height * .72
        : symbolLength <= 2
            ? size.height * .56
            : size.height * .30;
    final painter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: (mode == WritingMode.guided ? LumoColors.orange : LumoColors.ink900).withOpacity(.13),
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * .92);
    final offset = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );
    painter.paint(canvas, offset);
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
