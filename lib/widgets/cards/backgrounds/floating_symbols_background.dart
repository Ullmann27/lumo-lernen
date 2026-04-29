import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hintergrund-Engine: lässt eine Liste von Symbolen (Zeichen oder Emojis)
/// langsam durch die Karte schweben.
///
/// Jedes Symbol hat eigene Position, Größe, Drift-Geschwindigkeit, Rotation, Opacity.
/// Wird ausschließlich von den Card-Background-Wrappern genutzt.
class FloatingSymbolsBackground extends StatefulWidget {
  const FloatingSymbolsBackground({
    super.key,
    required this.symbols,
    required this.color,
    this.density = 8,
    this.minSize = 18.0,
    this.maxSize = 44.0,
    this.driftSeconds = 14,
    this.opacity = 0.18,
  });

  /// Symbole, die zufällig ausgewählt werden (Buchstaben, Zahlen, Emojis).
  final List<String> symbols;

  /// Farbe für nicht-Emoji-Zeichen.
  final Color color;

  /// Wie viele Symbole gleichzeitig sichtbar sind.
  final int density;

  final double minSize;
  final double maxSize;
  final int driftSeconds;
  final double opacity;

  @override
  State<FloatingSymbolsBackground> createState() =>
      _FloatingSymbolsBackgroundState();
}

class _FloatingSymbolsBackgroundState extends State<FloatingSymbolsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.driftSeconds),
  )..repeat();

  late final List<_Floater> _items;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42); // deterministisch -> stabile Animation
    _items = List.generate(widget.density, (i) {
      return _Floater(
        symbol: widget.symbols[rng.nextInt(widget.symbols.length)],
        startX: rng.nextDouble(),
        startY: rng.nextDouble(),
        amplitudeX: 0.10 + rng.nextDouble() * 0.20,
        amplitudeY: 0.10 + rng.nextDouble() * 0.20,
        size: widget.minSize +
            rng.nextDouble() * (widget.maxSize - widget.minSize),
        phase: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 1.6,
        freqX: 0.6 + rng.nextDouble() * 0.7,
        freqY: 0.5 + rng.nextDouble() * 0.6,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _FloatingPainter(
              items: _items,
              t: _ctrl.value,
              color: widget.color,
              opacity: widget.opacity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Floater {
  _Floater({
    required this.symbol,
    required this.startX,
    required this.startY,
    required this.amplitudeX,
    required this.amplitudeY,
    required this.size,
    required this.phase,
    required this.rotationSpeed,
    required this.freqX,
    required this.freqY,
  });
  final String symbol;
  final double startX;
  final double startY;
  final double amplitudeX;
  final double amplitudeY;
  final double size;
  final double phase;
  final double rotationSpeed;
  final double freqX;
  final double freqY;
}

class _FloatingPainter extends CustomPainter {
  _FloatingPainter({
    required this.items,
    required this.t,
    required this.color,
    required this.opacity,
  });

  final List<_Floater> items;
  final double t;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * math.pi * 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (final f in items) {
      final dx = (f.startX + f.amplitudeX * math.sin(phase * f.freqX + f.phase))
              .clamp(0.0, 1.0) *
          size.width;
      final dy = (f.startY +
                  f.amplitudeY * math.cos(phase * f.freqY + f.phase * 0.7))
              .clamp(0.0, 1.0) *
          size.height;
      final rot = phase * f.rotationSpeed * 0.10;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rot);

      final tp = TextPainter(
        text: TextSpan(
          text: f.symbol,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: f.size,
            color: color.withOpacity(opacity),
            // shadows entfernt — Performance + nicht nötig durch Color-Tinting
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FloatingPainter old) => old.t != t;
}
