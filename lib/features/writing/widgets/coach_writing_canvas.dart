// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - SCHREIBCANVAS
// ════════════════════════════════════════════════════════════════════════
//
// Zeichenflaeche mit:
//   - Schulheft-Linien (Oberlinie, Mittellinie, Grundlinie, Unterlinie)
//   - Live-Strokes des Kindes
//   - optionaler Demo-Overlay (Lumo zeichnet vor, Phase 3)
//
// Nutzt rohes Listener+PointerEvents damit das Schreiben nicht durch
// uebergeordnete Scroll-Container blockiert wird.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../logic/stroke_capture_controller.dart';
import '../models/coach_writing_models.dart';
import 'coach_letter_demo_painter.dart';

class CoachWritingCanvas extends StatefulWidget {
  const CoachWritingCanvas({
    super.key,
    required this.controller,
    this.demoLetter,
    this.demoProgress = 0.0,
    this.aspectRatio = 1.6,
    this.guidelineColor = const Color(0xFFCFD8DC),
    this.strokeColor = const Color(0xFF1F2937),
    this.strokeWidth = 6.0,
  });

  final StrokeCaptureController controller;

  /// Wenn gesetzt: Demo-Letter wird animiert ueberlagert.
  final String? demoLetter;

  /// 0..1 - Fortschritt der Demo-Animation.
  final double demoProgress;

  final double aspectRatio;
  final Color guidelineColor;
  final Color strokeColor;
  final double strokeWidth;

  @override
  State<CoachWritingCanvas> createState() => _CoachWritingCanvasState();
}

class _CoachWritingCanvasState extends State<CoachWritingCanvas> {
  int _activePointerId = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant CoachWritingCanvas old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEAE4D4),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  if (_activePointerId != -1) return;
                  _activePointerId = e.pointer;
                  widget.controller.beginStroke(
                    e.localPosition.dx,
                    e.localPosition.dy,
                  );
                },
                onPointerMove: (e) {
                  if (e.pointer != _activePointerId) return;
                  widget.controller.appendPoint(
                    e.localPosition.dx,
                    e.localPosition.dy,
                  );
                },
                onPointerUp: (e) {
                  if (e.pointer != _activePointerId) return;
                  _activePointerId = -1;
                  widget.controller.endStroke();
                },
                onPointerCancel: (e) {
                  if (e.pointer != _activePointerId) return;
                  _activePointerId = -1;
                  widget.controller.cancelActiveStroke();
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CanvasPainter(
                    guidelineColor: widget.guidelineColor,
                    strokeColor: widget.strokeColor,
                    strokeWidth: widget.strokeWidth,
                    committed: widget.controller.strokes,
                    active: widget.controller.activePoints,
                    demoLetter: widget.demoLetter,
                    demoProgress: widget.demoProgress.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.guidelineColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.committed,
    required this.active,
    required this.demoLetter,
    required this.demoProgress,
  });

  final Color guidelineColor;
  final Color strokeColor;
  final double strokeWidth;
  final List<CoachStroke> committed;
  final List<CoachStrokePoint> active;
  final String? demoLetter;
  final double demoProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGuidelines(canvas, size);

    // Demo-Overlay zuerst (hinter dem Strich des Kindes).
    if (demoLetter != null) {
      const painter = CoachLetterDemoPainter();
      painter.paintLetter(
        canvas: canvas,
        size: size,
        letter: demoLetter!,
        progress: demoProgress,
      );
    }

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in committed) {
      _paintPoints(canvas, paint, stroke.points);
    }
    if (active.isNotEmpty) {
      _paintPoints(canvas, paint, active);
    }
  }

  void _drawGuidelines(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final top = h * 0.18;
    final mid = h * 0.45;
    final base = h * 0.72;
    final bottom = h * 0.92;

    final paint = Paint()
      ..color = guidelineColor
      ..strokeWidth = 1.2;
    // Oberlinie und Unterlinie
    canvas.drawLine(Offset(8, top), Offset(w - 8, top), paint);
    canvas.drawLine(Offset(8, bottom), Offset(w - 8, bottom), paint);
    // Grundlinie (kraeftiger)
    final basePaint = Paint()
      ..color = guidelineColor
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(8, base), Offset(w - 8, base), basePaint);
    // Mittellinie (gestrichelt)
    final dashed = Paint()
      ..color = guidelineColor.withOpacity(0.7)
      ..strokeWidth = 1.0;
    const dash = 8.0;
    const gap = 6.0;
    var x = 8.0;
    while (x < w - 8) {
      canvas.drawLine(Offset(x, mid), Offset(x + dash, mid), dashed);
      x += dash + gap;
    }
  }

  void _paintPoints(Canvas canvas, Paint paint, List<CoachStrokePoint> pts) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      canvas.drawCircle(
        Offset(pts.first.x, pts.first.y),
        strokeWidth / 2,
        Paint()..color = paint.color,
      );
      return;
    }
    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) {
    return old.committed.length != committed.length ||
        old.active.length != active.length ||
        old.demoLetter != demoLetter ||
        (old.demoProgress - demoProgress).abs() > 0.001 ||
        !listEquals(_signature(old.committed), _signature(committed));
  }

  List<int> _signature(List<CoachStroke> strokes) =>
      strokes.map((s) => s.points.length).toList();
}
