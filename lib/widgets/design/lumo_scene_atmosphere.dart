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

/// A handful of slow lights, isolated from text and images by repaint boundaries.
/// Stops all scene tickers offscreen, on inactive routes and in the background.
class LumoSceneAtmosphere extends StatefulWidget {
  const LumoSceneAtmosphere({
    super.key,
    required this.child,
    this.reduceMotion = false,
  });

  final Widget child;
  final bool reduceMotion;

  @override
  State<LumoSceneAtmosphere> createState() => _LumoSceneAtmosphereState();
}

class _LumoSceneAtmosphereState extends State<LumoSceneAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
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
    final visible = _scroll!.pixels < start + box.size.height &&
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
  Widget build(BuildContext context) => TickerMode(
        enabled: _animate,
        child: Stack(
          children: [
            RepaintBoundary(
                child: SizedBox(width: double.infinity, child: widget.child)),
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _Starlight(
                        clock: _clock,
                        profile:
                            _animate ? _budget.profile : LumoEffectProfile.low,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Starlight extends CustomPainter {
  _Starlight({required this.clock, required this.profile})
      : super(repaint: clock);
  final Animation<double> clock;
  final LumoEffectProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    if (profile == LumoEffectProfile.low) return;
    final count = profile == LumoEffectProfile.high ? 14 : 8;
    final t = clock.value * math.pi * 2;
    // Keep light points in the illustration's right half, away from labels.
    for (var i = 0; i < count; i++) {
      final x = size.width * (.53 + .43 * ((i * .618) % 1));
      final y = size.height * (.10 + .72 * ((i * .382) % 1));
      final alpha = .26 + .18 * math.sin(t + i * 1.7);
      final center = Offset(x + math.sin(t + i) * 2, y + math.cos(t + i) * 3);
      final paint = Paint()
        ..color = (i.isEven
                ? LumoVisualTokens.goldLight
                : LumoVisualTokens.cyanBright)
            .withValues(alpha: alpha);
      canvas.drawCircle(center, i % 3 == 0 ? 1.8 : 1, paint);
      if (i % 3 == 0) {
        paint.strokeWidth = .7;
        canvas.drawLine(
            center - const Offset(4, 0), center + const Offset(4, 0), paint);
        canvas.drawLine(
            center - const Offset(0, 4), center + const Offset(0, 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Starlight oldDelegate) =>
      profile != oldDelegate.profile || clock != oldDelegate.clock;
}
