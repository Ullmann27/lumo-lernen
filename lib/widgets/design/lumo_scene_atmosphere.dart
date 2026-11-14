import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/lumo_visual_tokens.dart';
import 'lumo_motion.dart';

enum LumoEffectProfile { low, medium, high }

/// Conservative, session-local budget. Screen size is not a hardware rating.
/// HIGH requires two measured smooth windows; repeated expensive frames fall
/// back to a static scene. Never persisted as a claim about the device.
class LumoEffectBudget {
  LumoEffectProfile profile = LumoEffectProfile.medium;
  final List<int> _samples = [];
  int _smoothWindows = 0;

  bool record(Duration build, Duration raster) {
    _samples.add(math.max(build.inMicroseconds, raster.inMicroseconds));
    if (_samples.length < 60) return false;
    _samples.sort();
    final p95 = _samples[56];
    _samples.clear();
    final previous = profile;
    if (p95 > 20000) {
      profile = LumoEffectProfile.low;
      _smoothWindows = 0;
    } else if (p95 < 12000 && profile != LumoEffectProfile.low) {
      if (++_smoothWindows >= 2) profile = LumoEffectProfile.high;
    } else {
      _smoothWindows = 0;
      if (profile == LumoEffectProfile.high) {
        profile = LumoEffectProfile.medium;
      }
    }
    return previous != profile;
  }
}

/// Original scene art drifts behind independently painted depth layers.
/// Labels, hit targets and the original Lumo character remain stationary.
/// Decorative clocks stop offscreen, on inactive routes and in the background;
/// reduced effects never stop an in-content progress or interaction animation.
class LumoSceneAtmosphere extends StatefulWidget {
  const LumoSceneAtmosphere({
    super.key,
    required this.child,
    this.reduceMotion = false,
    this.scenery,
    this.accent = LumoVisualTokens.cyanBright,
    this.compact = false,
  });

  final Widget child;
  final bool reduceMotion;

  /// Existing original landscape; no controls or labels belong in this layer.
  final Widget? scenery;
  final Color accent;
  final bool compact;

  @override
  State<LumoSceneAtmosphere> createState() => _LumoSceneAtmosphereState();
}

class _LumoSceneAtmosphereState extends State<LumoSceneAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  final _budget = LumoEffectBudget();
  ScrollPosition? _scroll;
  bool _visible = true;
  bool _foreground = true;
  bool _parentEnabled = true;
  bool _sampling = false;
  bool _quiet = false;

  bool get _animate =>
      !_quiet &&
      _visible &&
      _foreground &&
      _parentEnabled &&
      _budget.profile != LumoEffectProfile.low;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parentEnabled = TickerMode.of(context);
    _quiet = widget.reduceMotion || LumoMotion.reduced(context);
    final scroll = Scrollable.maybeOf(context)?.position;
    if (_scroll != scroll) {
      _scroll?.removeListener(_checkVisibility);
      _scroll = scroll;
      if (_scroll == null) _visible = true;
      _scroll?.addListener(_checkVisibility);
    }
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant LumoSceneAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    _quiet = widget.reduceMotion || LumoMotion.reduced(context);
    _sync();
  }

  void _checkVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null || _scroll == null) return;
    final start = viewport.getOffsetToReveal(box, 0).offset;
    final extent = axisDirectionToAxis(_scroll!.axisDirection) == Axis.vertical
        ? box.size.height
        : box.size.width;
    final visible = _scroll!.pixels < start + extent &&
        _scroll!.pixels + _scroll!.viewportDimension > start;
    if (visible == _visible) return;
    setState(() => _visible = visible);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    setState(() => _foreground = foreground);
    _sync();
  }

  void _sync() {
    if (_animate) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
    if (_animate != _sampling) {
      _sampling = _animate;
      if (_sampling) {
        SchedulerBinding.instance.addTimingsCallback(_onTimings);
      } else {
        SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      }
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || !_animate) return;
    var changed = false;
    for (final timing in timings) {
      changed = _budget.record(timing.buildDuration, timing.rasterDuration) ||
          changed;
    }
    if (changed) {
      setState(() {});
      _sync();
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_checkVisibility);
    if (_sampling) SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _animate ? _budget.profile : LumoEffectProfile.low;
    final decoration = Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              key: const ValueKey('lumo-dream-atmosphere'),
              painter: _DreamAtmosphere(
                clock: _clock,
                profile: profile,
                accent: widget.accent,
                compact: widget.compact,
              ),
            ),
          ),
        ),
      ),
    );
    return ClipRect(
      child: Stack(
        children: [
          if (widget.scenery != null) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _clock,
                      child: RepaintBoundary(child: widget.scenery!),
                      builder: (context, child) {
                        final t = _clock.value * math.pi * 2;
                        final active = profile != LumoEffectProfile.low;
                        return Transform.translate(
                          key: const ValueKey('lumo-scenery-drift'),
                          offset: active
                              ? Offset(math.sin(t) * 3, math.sin(t * 2) * 1.5)
                              : Offset.zero,
                          child: Transform.scale(scale: 1.045, child: child),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            decoration,
          ],
          TickerMode(
            enabled: _visible && _foreground && _parentEnabled,
            child: RepaintBoundary(
              child: SizedBox(width: double.infinity, child: widget.child),
            ),
          ),
          if (widget.scenery == null) decoration,
        ],
      ),
    );
  }
}

/// Bounded layers: three mist ribbons, at most eighteen light motes and two
/// small winged lights. No blur filters, image decodes or widget rebuilds in
/// the particle animation. All trajectories close at the clock's loop point.
class _DreamAtmosphere extends CustomPainter {
  _DreamAtmosphere({
    required this.clock,
    required this.profile,
    required this.accent,
    required this.compact,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final LumoEffectProfile profile;
  final Color accent;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final moving = profile != LumoEffectProfile.low;
    final t = moving ? clock.value * math.pi * 2 : 0.0;
    final count = compact
        ? (moving ? 6 : 3)
        : (profile == LumoEffectProfile.high ? 18 : (moving ? 10 : 4));
    final color = Color.lerp(accent, Colors.white, .35)!;
    final light = Paint();
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Separated mist depths move gently through the original floating islands.
    // Radial gradients keep the edges soft without a full-screen blur pass.
    for (var i = 0; i < (compact ? 1 : 3); i++) {
      final depth = (i + 1) / 3;
      final x = size.width * (.62 + .12 * i) + math.sin(t + i * 2) * 8 * depth;
      final y = size.height * (.36 + .20 * i) + math.sin(t * 2 + i) * 3;
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: size.width * (.55 + .15 * depth),
        height: size.height * (.16 + .05 * depth),
      );
      light.shader = RadialGradient(
        colors: [color.withValues(alpha: .055), color.withValues(alpha: 0)],
      ).createShader(rect);
      canvas.drawOval(rect, light);
    }
    light.shader = null;

    for (var i = 0; i < count; i++) {
      final depth = .35 + (i % 3) * .32;
      final phase = i * 2.399963229728653;
      // Keep foreground glints away from the left-aligned reading area.
      final center = Offset(
        size.width * (.54 + .42 * ((i * .618) % 1)) +
            math.sin(t + phase) * 9 * depth,
        size.height * (.12 + .66 * ((i * .382) % 1)) +
            math.cos(t * 2 + phase) * 6 * depth,
      );
      final alpha = .31 + .12 * math.sin(t * 2 + phase);
      final radius = (compact ? 1.0 : 1.4) * depth;
      light.color = (i.isEven ? LumoVisualTokens.goldLight : color)
          .withValues(alpha: alpha * .20);
      canvas.drawCircle(center, radius * 3.6, light);
      light.color = (i.isEven ? LumoVisualTokens.goldLight : color)
          .withValues(alpha: alpha);
      canvas.drawCircle(center, radius, light);
      if (i % 4 == 0) {
        light.strokeWidth = .65;
        canvas.drawLine(center - Offset(radius * 2.8, 0),
            center + Offset(radius * 2.8, 0), light);
        canvas.drawLine(center - Offset(0, radius * 2.8),
            center + Offset(0, radius * 2.8), light);
      }
    }

    if (!compact) {
      for (var i = 0; i < 2; i++) {
        final phase = t + i * math.pi;
        final center = Offset(
          size.width * (.67 + i * .19) + math.sin(phase) * 12,
          size.height * (.24 + i * .32) + math.sin(phase * 2) * 7,
        );
        final wing = 1.5 + 2 * (math.sin(t * 12 + i).abs());
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.sin(phase) * .25);
        light.color = (i.isEven ? color : LumoVisualTokens.goldLight)
            .withValues(alpha: .48);
        canvas.drawOval(Rect.fromCenter(center: Offset(-wing / 2, -1),
            width: wing, height: 4.5), light);
        canvas.drawOval(Rect.fromCenter(center: Offset(wing / 2, -1),
            width: wing, height: 4.5), light);
        light.color = Colors.white.withValues(alpha: .55);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero,
            width: .8, height: 3.5), light);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DreamAtmosphere oldDelegate) =>
      profile != oldDelegate.profile ||
      clock != oldDelegate.clock ||
      accent != oldDelegate.accent ||
      compact != oldDelegate.compact;
}
