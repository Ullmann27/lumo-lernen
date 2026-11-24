import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_motion.dart';

/// Holografische Effekte des Lumo-Design-Systems.
///
/// Alle Effekte liegen in eigenen [RepaintBoundary]-Ebenen über bzw. hinter
/// dem Inhalt, fangen keine Eingaben ab und besitzen höchstens einen Ticker.
/// Zwischen zwei Lichtimpulsen wird nichts neu gezeichnet. Meldet das System
/// „Animationen entfernen“ (oder die App den Ruhemodus), bleibt alles statisch.
abstract final class LumoHolo {
  /// Kühles Hologramm-Licht für Schimmer und Kanten.
  static const Color light = Color(0xFF8FEBFF);

  /// Kantenleuchten für Glas-Flächen in Akzentfarbe [accent].
  static List<BoxShadow> edgeGlow(Color accent, {double strength = 1}) => [
        BoxShadow(
          color: accent.withValues(alpha: .22 * strength),
          blurRadius: 22,
          spreadRadius: -6,
          offset: const Offset(0, 6),
        ),
        const BoxShadow(
          color: Color(0x6600081C),
          blurRadius: 20,
          spreadRadius: -4,
          offset: Offset(0, 12),
        ),
      ];
}

/// Ein feiner blauer Lichtstreifen, der in zufälligen Abständen schräg über
/// das Kind läuft (Shimmer-Sweep).
///
/// Ein Ticker pro Widget; der Streifen zeichnet nur während des Durchlaufs.
/// Bei reduzierter Bewegung oder [enabled] = false wird kein Durchlauf
/// geplant und nichts gezeichnet. Die Baumstruktur bleibt in allen Zuständen
/// gleich, damit laufende Gesten des Kindes nicht verloren gehen.
class LumoHoloShimmer extends StatefulWidget {
  const LumoHoloShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.radius = 22,
    this.color = LumoHolo.light,
    this.minInterval = const Duration(milliseconds: 3800),
    this.maxInterval = const Duration(milliseconds: 9500),
    this.sweepDuration = const Duration(milliseconds: 1150),
    this.random,
  });

  final Widget child;
  final bool enabled;
  final double radius;
  final Color color;
  final Duration minInterval;
  final Duration maxInterval;
  final Duration sweepDuration;

  /// Optionale Zufallsquelle (für reproduzierbare Tests).
  final math.Random? random;

  @override
  State<LumoHoloShimmer> createState() => LumoHoloShimmerState();
}

class LumoHoloShimmerState extends State<LumoHoloShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: widget.sweepDuration)
        ..addStatusListener(_onStatus);
  late final math.Random _random = widget.random ?? math.Random();
  Timer? _next;
  bool _reduced = false;

  /// Ob gerade ein Durchlauf geplant ist oder läuft.
  @visibleForTesting
  bool get isActive => _next != null || _sweep.isAnimating;

  bool get _allowed => widget.enabled && !_reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = LumoMotion.reduced(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant LumoHoloShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sweepDuration != widget.sweepDuration) {
      _sweep.duration = widget.sweepDuration;
    }
    _sync();
  }

  void _sync() {
    if (!_allowed) {
      _next?.cancel();
      _next = null;
      if (_sweep.value != 0) _sweep.value = 0;
      _sweep.stop();
      return;
    }
    if (_next == null && !_sweep.isAnimating) _schedule();
  }

  void _schedule() {
    final span =
        widget.maxInterval.inMilliseconds - widget.minInterval.inMilliseconds;
    final wait = widget.minInterval.inMilliseconds +
        (span <= 0 ? 0 : _random.nextInt(span + 1));
    _next = Timer(Duration(milliseconds: wait), () {
      _next = null;
      if (!mounted || !_allowed) return;
      _sweep.forward(from: 0);
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _sweep.value = 0;
    if (_allowed) _schedule();
  }

  @override
  void dispose() {
    _next?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // passthrough: das Kind erhält exakt die Constraints wie ohne Schimmer
    // (straffe Raster-Zellen bleiben straff, Layout ändert sich nicht).
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('lumo-holo-shimmer-layer'),
                painter: _ShimmerPainter(
                  progress: _sweep,
                  radius: widget.radius,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.radius,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1 || size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    // Der Streifen wandert diagonal von links oben nach rechts unten und
    // blendet an beiden Enden weich ein und aus.
    final eased = Curves.easeInOutSine.transform(t);
    final centre = -.35 + 1.7 * eased;
    final fade = math.sin(math.pi * t);
    const band = .16;
    Paint paint(double alpha, double width) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [
          (centre - width).clamp(0.0, 1.0),
          centre.clamp(0.0, 1.0),
          (centre + width).clamp(0.0, 1.0),
        ],
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha * fade),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint(.24, band));
    canvas.drawRect(rect, paint(.32, band * .28));
    // Kurzes Aufleuchten der Kante, während der Streifen vorbeizieht.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.9), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: .38 * fade),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.radius != radius || old.color != color || old.progress != progress;
}

/// Ruhiges, tiefes Lichtfeld für Hintergründe: feste Lichtpunkte, ein
/// weicher Nebel und gelegentlich ein langsamer Lichtatem.
///
/// Zwischen den Lichtatem-Phasen steht das Feld still (keine Dauer-Frames).
/// Bei reduzierter Bewegung bleibt es vollständig statisch.
class LumoHoloField extends StatefulWidget {
  const LumoHoloField({
    super.key,
    this.seed = 7,
    this.density = 34,
    this.color = LumoVisualTokens.cyanBright,
    this.minInterval = const Duration(seconds: 7),
    this.maxInterval = const Duration(seconds: 14),
    this.pulseDuration = const Duration(milliseconds: 3200),
  });

  final int seed;
  final int density;
  final Color color;
  final Duration minInterval;
  final Duration maxInterval;
  final Duration pulseDuration;

  @override
  State<LumoHoloField> createState() => LumoHoloFieldState();
}

class LumoHoloFieldState extends State<LumoHoloField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: widget.pulseDuration)
        ..addStatusListener(_onStatus);
  late final math.Random _random = math.Random(widget.seed);
  late final List<_Mote> _motes = List.generate(widget.density, (_) {
    return _Mote(
      Offset(_random.nextDouble(), _random.nextDouble()),
      .7 + _random.nextDouble() * 1.9,
      .10 + _random.nextDouble() * .28,
      _random.nextDouble(),
    );
  });
  Timer? _next;
  bool _reduced = false;

  @visibleForTesting
  bool get isActive => _next != null || _pulse.isAnimating;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = LumoMotion.reduced(context);
    if (_reduced) {
      _next?.cancel();
      _next = null;
      _pulse
        ..stop()
        ..value = 0;
    } else if (_next == null && !_pulse.isAnimating) {
      _schedule();
    }
  }

  void _schedule() {
    final span =
        widget.maxInterval.inMilliseconds - widget.minInterval.inMilliseconds;
    _next = Timer(
        Duration(
            milliseconds: widget.minInterval.inMilliseconds +
                (span <= 0 ? 0 : _random.nextInt(span + 1))), () {
      _next = null;
      if (mounted && !_reduced) _pulse.forward(from: 0);
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _pulse.value = 0;
    if (!_reduced) _schedule();
  }

  @override
  void dispose() {
    _next?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('lumo-holo-field'),
            size: Size.infinite,
            painter: _FieldPainter(
                pulse: _pulse, motes: _motes, color: widget.color),
          ),
        ),
      );
}

@immutable
class _Mote {
  const _Mote(this.position, this.radius, this.alpha, this.phase);
  final Offset position;
  final double radius;
  final double alpha;
  final double phase;
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({required this.pulse, required this.motes, required this.color})
      : super(repaint: pulse);

  final Animation<double> pulse;
  final List<_Mote> motes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final t = pulse.value;
    final breath = t <= 0 ? 0.0 : math.sin(math.pi * t);
    // Tiefer Nebel: zwei weiche Lichtquellen, oben links kühl, unten rechts
    // violett-blau. Sehr niedrige Deckkraft, damit Text-Kontrast bleibt.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.75, -.85),
          radius: 1.1,
          colors: [
            color.withValues(alpha: .10 + .06 * breath),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.9, .95),
          radius: 1.0,
          colors: [
            const Color(0xFF5B6CFF).withValues(alpha: .09 + .05 * breath),
            const Color(0x005B6CFF),
          ],
        ).createShader(rect),
    );
    final dot = Paint();
    for (final mote in motes) {
      final twinkle =
          breath * (.5 + .5 * math.sin(2 * math.pi * (mote.phase + t * 1.5)));
      final drift = Offset(0, -6 * breath * mote.radius);
      final centre = Offset(
              mote.position.dx * size.width, mote.position.dy * size.height) +
          drift;
      dot
        ..color =
            color.withValues(alpha: (mote.alpha + .35 * twinkle).clamp(0.0, .7))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, mote.radius * .9);
      canvas.drawCircle(centre, mote.radius, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.pulse != pulse || old.motes != motes || old.color != color;
}
