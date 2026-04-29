import 'package:flutter/material.dart';

/// Animierter Zahlen-Counter.
///
/// Zählt smooth vom alten Wert zum neuen, wenn sich [value] ändert.
/// Beim ersten Erscheinen zählt von 0 hoch.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
    this.curve = Curves.easeOutCubic,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final String prefix;
  final String suffix;
  final Curve curve;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    _previous = 0; // Beim ersten Erscheinen von 0 hochzählen
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _previous = old.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, t, _) {
        final current =
            (_previous + (widget.value - _previous) * t).round();
        return Text(
          '${widget.prefix}$current${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
