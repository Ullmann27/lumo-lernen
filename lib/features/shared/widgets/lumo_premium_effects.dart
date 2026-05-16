import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';

/// Echte Glassmorphism-Karte mit BackdropFilter Blur.
/// Wie Apple iOS Control Center, aber kindgerecht warm.
class LumoGlassCard extends StatelessWidget {
  const LumoGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.blur = 18,
    this.tintColor,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? Colors.white;
    return Container(
      decoration: elevated
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: tint.withOpacity(0.20),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withOpacity(0.55),
                  tint.withOpacity(0.30),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 3D-Tilt-Karte: neigt sich basierend auf der Touch-Position.
/// Loest bei Kindern dieses "Wow ich kann es bewegen"-Gefuehl aus.
class LumoTiltCard extends StatefulWidget {
  const LumoTiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.08,
    this.onTap,
  });

  final Widget child;
  /// Maximale Neigung in Radians (~0.08 = etwa 4.6 Grad)
  final double maxTilt;
  final VoidCallback? onTap;

  @override
  State<LumoTiltCard> createState() => _LumoTiltCardState();
}

class _LumoTiltCardState extends State<LumoTiltCard> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _pressed = false;

  void _updateTilt(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    // Normalisierte Position (-1 bis +1)
    final nx = (localPos.dx / size.width) * 2 - 1;
    final ny = (localPos.dy / size.height) * 2 - 1;
    setState(() {
      _tiltY = nx * widget.maxTilt;
      _tiltX = -ny * widget.maxTilt;
    });
  }

  void _reset() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final size = context.size;
        if (size != null) _updateTilt(event.localPosition, size);
      },
      onExit: (_) => _reset(),
      child: GestureDetector(
        onTapDown: (details) {
          HapticFeedback.selectionClick();
          setState(() => _pressed = true);
          final size = context.size;
          if (size != null) _updateTilt(details.localPosition, size);
        },
        onTapUp: (_) {
          _reset();
          widget.onTap?.call();
        },
        onTapCancel: _reset,
        onPanUpdate: (details) {
          final size = context.size;
          if (size != null) _updateTilt(details.localPosition, size);
        },
        onPanEnd: (_) => _reset(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(_tiltX)
            ..rotateY(_tiltY)
            ..scale(_pressed ? 0.97 : 1.0),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Confetti-Burst mit Newton-Physik.
/// Beim richtigen Antworten spuckt das Widget Confetti-Stuecke,
/// die echter Schwerkraft + Luftwiderstand folgen.
class LumoConfettiBurst extends StatefulWidget {
  const LumoConfettiBurst({
    super.key,
    required this.trigger,
    this.particleCount = 40,
    this.duration = const Duration(milliseconds: 2400),
  });

  /// Aenderung dieses Werts loest neuen Burst aus.
  final int trigger;
  final int particleCount;
  final Duration duration;

  @override
  State<LumoConfettiBurst> createState() => _LumoConfettiBurstState();
}

class _LumoConfettiBurstState extends State<LumoConfettiBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();
  List<_ConfettiParticle> _particles = const [];
  int _lastTrigger = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(LumoConfettiBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger != _lastTrigger) {
      _lastTrigger = widget.trigger;
      _fire();
    }
  }

  void _fire() {
    // 40 Confetti-Stuecke mit zufaelliger Geschwindigkeit + Rotation.
    HapticFeedback.lightImpact();
    _particles = List.generate(widget.particleCount, (i) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * math.pi;
      final speed = 400 + _random.nextDouble() * 500;
      return _ConfettiParticle(
        startX: 0,
        startY: 0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        rotationSpeed: (_random.nextDouble() - 0.5) * 12,
        size: 6 + _random.nextDouble() * 10,
        color: _vibrantColor(i),
        shape: _ConfettiShape.values[i % _ConfettiShape.values.length],
      );
    });
    _controller.forward(from: 0);
  }

  Color _vibrantColor(int i) {
    const colors = [
      Color(0xFFFF7A2F), // orange
      Color(0xFFFFB800), // gold
      Color(0xFFF472B6), // pink
      Color(0xFF60A5FA), // blue
      Color(0xFF34D399), // green
      Color(0xFFA78BFA), // purple
      Color(0xFFFF6B6B), // coral
    ];
    return colors[i % colors.length];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            t: _controller.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double rotationSpeed;
  final double size;
  final Color color;
  final _ConfettiShape shape;
}

enum _ConfettiShape { square, circle, triangle, ribbon }

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.t});
  final List<_ConfettiParticle> particles;
  final double t;

  // Schwerkraft (px/s^2)
  static const double _gravity = 800;
  // Luftwiderstand
  static const double _drag = 0.92;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    final centerX = size.width / 2;
    final centerY = size.height * 0.40;
    final time = t * 2.4; // duration

    for (final p in particles) {
      // Velocity-Verlet-Integration (vereinfacht analytisch)
      // x(t) = x0 + vx0 * (1-drag^t)/(1-drag) - vereinfacht: linear * decay
      final decay = math.pow(_drag, time * 60).toDouble();
      final px = centerX + p.vx * time * decay;
      final py = centerY + p.vy * time * decay + 0.5 * _gravity * time * time;

      // Konfetti das ausserhalb der Sichtbarkeit ist, nicht zeichnen.
      if (py > size.height + 20) continue;

      final rotation = time * p.rotationSpeed;
      final alpha = (1.0 - t).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);
      final paint = Paint()..color = p.color.withOpacity(alpha);

      switch (p.shape) {
        case _ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
          break;
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ConfettiShape.triangle:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case _ConfettiShape.ribbon:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size * 0.4),
            paint,
          );
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.particles != particles;
}

/// Schwebende "Floating" Animation: Element wackelt sanft auf und ab.
/// Fuer Avatare oder Buttons - gibt Leben.
class LumoFloating extends StatefulWidget {
  const LumoFloating({
    super.key,
    required this.child,
    this.amplitude = 6.0,
    this.duration = const Duration(seconds: 3),
  });

  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<LumoFloating> createState() => _LumoFloatingState();
}

class _LumoFloatingState extends State<LumoFloating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final offset = math.sin(_controller.value * math.pi * 2) * widget.amplitude;
        return Transform.translate(
          offset: Offset(0, offset),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulsierender Glow um ein Widget.
/// Fuer Call-to-Action-Buttons: pulsiert sanft.
class LumoGlowPulse extends StatefulWidget {
  const LumoGlowPulse({
    super.key,
    required this.child,
    required this.color,
    this.minBlur = 8,
    this.maxBlur = 24,
  });

  final Widget child;
  final Color color;
  final double minBlur;
  final double maxBlur;

  @override
  State<LumoGlowPulse> createState() => _LumoGlowPulseState();
}

class _LumoGlowPulseState extends State<LumoGlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final blur = widget.minBlur + (widget.maxBlur - widget.minBlur) * _controller.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.45),
                blurRadius: blur,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Haptic-Wrapper: Tap mit smartem Feedback.
class LumoHapticTap extends StatelessWidget {
  const LumoHapticTap({
    super.key,
    required this.child,
    required this.onTap,
    this.strength = HapticStrength.light,
  });

  final Widget child;
  final VoidCallback onTap;
  final HapticStrength strength;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (strength) {
          case HapticStrength.selection:
            HapticFeedback.selectionClick();
            break;
          case HapticStrength.light:
            HapticFeedback.lightImpact();
            break;
          case HapticStrength.medium:
            HapticFeedback.mediumImpact();
            break;
          case HapticStrength.heavy:
            HapticFeedback.heavyImpact();
            break;
        }
        onTap();
      },
      child: child,
    );
  }
}

enum HapticStrength { selection, light, medium, heavy }
