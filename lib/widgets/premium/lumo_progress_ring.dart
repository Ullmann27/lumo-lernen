// ════════════════════════════════════════════════════════════════════════
// LUMO PROGRESS RING — Animierter Fortschritt
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_design_tokens.dart';

class LumoProgressRing extends StatefulWidget {
  const LumoProgressRing({
    super.key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.gradient,
    this.center,
    this.animate = true,
  })  : assert(value >= 0 && value <= 1);

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Gradient? gradient;
  final Widget? center;
  final bool animate;

  @override
  State<LumoProgressRing> createState() => _LumoProgressRingState();
}

class _LumoProgressRingState extends State<LumoProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _animation;
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _displayed = _animation.value);
      });
    if (widget.animate) {
      _ctrl.forward();
    } else {
      _displayed = widget.value;
    }
  }

  @override
  void didUpdateWidget(LumoProgressRing old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animation = Tween(begin: _displayed, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      )..addListener(() {
          setState(() => _displayed = _animation.value);
        });
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingPainter(
              value: _displayed,
              strokeWidth: widget.strokeWidth,
              color: widget.color ?? LumoTokens.colors.lumoOrange,
              trackColor: widget.trackColor ??
                  LumoTokens.colors.outline.withOpacity(0.5),
              gradient: widget.gradient,
            ),
          ),
          if (widget.center != null) widget.center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    this.gradient,
  });
  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = (size.width - strokeWidth) / 2;
    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, trackPaint);
    // Progress arc
    final rect = Rect.fromCircle(center: c, radius: r);
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (gradient != null) {
      fillPaint.shader = gradient!.createShader(rect);
    } else {
      fillPaint.color = color;
    }
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, fillPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
