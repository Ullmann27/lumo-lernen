import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

/// Lumo Living Avatar.
///
/// Wraps the fox image with a multi-layer animation system to make Lumo
/// feel alive without rebuilding him from scratch.
///
/// Permanent life states (always active):
///   - Breath:        Y-scale 1.00 → 1.025  (3.5 s/cycle)
///   - Float:         Y-translate ±4 px     (4 s/cycle, phase-offset)
///   - Sway:          rotation ±2.5°        (5 s/cycle)
///   - Aura pulse:    radial glow scaling   (locked to breath)
///   - Tail wag:      X-skew on lower half  (2 s/cycle)
///   - Blink:         eye-area squish       (every 3-7 s, 140 ms)
///   - Idle hop:      every 8-15 s a tiny bounce
///
/// Mood-driven (one-shot when [mood] changes):
///   - greet     → wave-tilt left-right
///   - point     → lean toward focusedAccent direction
///   - celebrate → big jump + spin
///   - comfort   → slow tilt left, longer
///   - think     → tilt up-right, hold
///   - wave      → energetic swing
///   - idle      → permanent only
///
/// Reactive:
///   - tap on body  → squish + jump (elasticOut)
///   - focusedAccent → head turn toward card (max ±20°)
class LumoLivingAvatar extends StatefulWidget {
  const LumoLivingAvatar({
    super.key,
    required this.appState,
    required this.onTap,
    this.height = 230,
    this.facing = 1.0,
  });

  final LumoAppState appState;
  final VoidCallback onTap;
  final double height;
  final double facing; // 1 = right, -1 = left

  @override
  State<LumoLivingAvatar> createState() => _LumoLivingAvatarState();
}

class _LumoLivingAvatarState extends State<LumoLivingAvatar>
    with TickerProviderStateMixin {
  // Permanent loops
  late final AnimationController _breath;
  late final AnimationController _float;
  late final AnimationController _sway;
  late final AnimationController _tail;
  late final AnimationController _blink;
  late final AnimationController _idleHop;

  // Mood transitions
  late final AnimationController _moodCtrl;
  LumoMood _lastMood = LumoMood.greet;

  // Tap reaction
  late final AnimationController _tapCtrl;

  // Focus reaction (head-turn)
  late final AnimationController _focusCtrl;
  double _targetHeadTurn = 0.0; // -1..1
  double _currentHeadTurn = 0.0;

  // Random timers
  Timer? _blinkTimer;
  Timer? _idleHopTimer;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    // Breath - 3.5s, in/out
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    // Float - 4s, phase-offset from breath
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // Sway - 5s, gentle
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);

    // Tail wag - 2s, fast
    _tail = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Blink - one-shot triggered by timer
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // Idle hop
    _idleHop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Mood transition - 800ms
    _moodCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Tap reaction
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Focus head-turn
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scheduleBlink();
    _scheduleIdleHop();

    widget.appState.addListener(_onAppStateChange);
    _lastMood = widget.appState.state.mood;
  }

  void _scheduleBlink() {
    final wait = 3000 + _rng.nextInt(4000);
    _blinkTimer = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      _blink.forward(from: 0).then((_) => _blink.reverse());
      _scheduleBlink();
    });
  }

  void _scheduleIdleHop() {
    final wait = 8000 + _rng.nextInt(7000);
    _idleHopTimer = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      if (widget.appState.state.mood == LumoMood.idle ||
          widget.appState.state.mood == LumoMood.greet) {
        _idleHop.forward(from: 0).then((_) => _idleHop.reverse());
      }
      _scheduleIdleHop();
    });
  }

  void _onAppStateChange() {
    final st = widget.appState.state;

    // Mood changed?
    if (st.mood != _lastMood) {
      _lastMood = st.mood;
      _moodCtrl.forward(from: 0);
    }

    // Focus accent → head turn target
    final accent = st.focusedAccent;
    final newTarget = accent != null ? widget.facing.sign * 1.0 : 0.0;
    if (newTarget != _targetHeadTurn) {
      _targetHeadTurn = newTarget;
      _focusCtrl.forward(from: 0);
    }
  }

  void _handleTap() {
    _tapCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChange);
    _blinkTimer?.cancel();
    _idleHopTimer?.cancel();
    _breath.dispose();
    _float.dispose();
    _sway.dispose();
    _tail.dispose();
    _blink.dispose();
    _idleHop.dispose();
    _moodCtrl.dispose();
    _tapCtrl.dispose();
    _focusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breath, _float, _sway, _tail, _blink, _idleHop,
            _moodCtrl, _tapCtrl, _focusCtrl,
          ]),
          builder: (context, _) {
            return _buildAnimated(reduced);
          },
        ),
      ),
    );
  }

  Widget _buildAnimated(bool reduced) {
    final mood = widget.appState.state.mood;

    // ── Breath: Y-scale (subtle ±2.5%)
    final breathT = Curves.easeInOutSine.transform(_breath.value);
    final breathScale = 1.0 + breathT * 0.025;

    // ── Float: ±4 px Y bounce
    final floatT = Curves.easeInOutSine.transform(_float.value);
    final floatY = (floatT - 0.5) * 8.0;

    // ── Sway: ±2.5° rotation
    final swayT = Curves.easeInOutSine.transform(_sway.value);
    final swayRot = (swayT - 0.5) * (2.5 * math.pi / 180) * 2;

    // ── Blink: eye-squish (we don't have eye access, so we squish whole upper)
    final blinkAmount = _blink.value; // 0..1
    final eyeYScale = 1.0 - blinkAmount * 0.06;

    // ── Idle hop
    final idleT = _idleHop.value;
    final idleHopY = idleT > 0
        ? -math.sin(idleT * math.pi) * 12.0
        : 0.0;

    // ── Mood gesture (one-shot 0..1 after mood change)
    final moodT = _moodCtrl.value;
    final moodPose = _moodPose(mood, moodT);

    // ── Tap reaction (squish + jump with elasticOut)
    final tapT = _tapCtrl.value;
    double tapY = 0;
    double tapScale = 1.0;
    if (tapT > 0) {
      // First 30%: squish down. Then 70%: jump up with elastic
      if (tapT < 0.3) {
        final p = tapT / 0.3;
        tapScale = 1.0 - p * 0.08; // squish to 0.92
        tapY = p * 6;
      } else {
        final p = (tapT - 0.3) / 0.7;
        final elastic = Curves.elasticOut.transform(p);
        tapY = -elastic * 24 + 6;
        tapScale = 0.92 + (1.0 - 0.92) * elastic;
      }
    }

    // ── Focus head-turn (smoothly toward target)
    final focusT = Curves.easeOut.transform(_focusCtrl.value);
    _currentHeadTurn = _currentHeadTurn +
        (_targetHeadTurn - _currentHeadTurn) * focusT;
    final focusRot = _currentHeadTurn * 0.18; // ~10°

    // ── Compose all transforms (reduced motion: only breath)
    final totalScaleY = reduced ? breathScale : breathScale * eyeYScale * tapScale;
    final totalScaleX = reduced ? 1.0 : tapScale;
    final totalY = reduced ? 0.0 : floatY + idleHopY + tapY + moodPose.translateY;
    final totalRot = reduced ? 0.0 : swayRot + focusRot + moodPose.rotation;

    // ── Aura color (focus accent overrides mood)
    final st = widget.appState.state;
    final auraColor = st.focusedAccent ?? _moodAuraColor(mood);
    final auraPulse = 0.8 + breathT * 0.4; // 0.8..1.2

    return SizedBox(
      width: widget.height * 1.1,
      height: widget.height + 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── 1. Aura glow (back, pulses with breath)
          Positioned(
            child: Transform.scale(
              scale: auraPulse,
              child: Container(
                width: widget.height * 0.95,
                height: widget.height * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      auraColor.withOpacity(.30),
                      auraColor.withOpacity(.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // ── 2. Shadow (squishes when tap-bounced up)
          Positioned(
            bottom: 0,
            child: Transform.scale(
              scaleX: 1.0 - (tapY.abs() / 60).clamp(0, 0.4),
              child: Container(
                width: widget.height * 0.45,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: RadialGradient(colors: [
                    Colors.black.withOpacity(
                      .22 - (tapY.abs() / 200).clamp(0, .15),
                    ),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          // ── 3. The fox itself, with full transform stack
          Positioned(
            child: Transform.translate(
              offset: Offset(moodPose.translateX, totalY),
              child: Transform.rotate(
                angle: totalRot,
                child: Transform(
                  transform: Matrix4.identity()
                    ..scale(widget.facing * totalScaleX, totalScaleY),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/lumo_fox.png',
                    height: widget.height,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _FallbackFox(
                      height: widget.height,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── 4. Mood overlay (sparkles for celebrate, etc.)
          if (mood == LumoMood.celebrate && moodT > 0)
            ..._buildCelebrateSparkles(moodT),
          if (mood == LumoMood.think && moodT > 0)
            _buildThoughtBubble(moodT),
        ],
      ),
    );
  }

  // ── Mood pose definitions ──────────────────────────────────
  _MoodPose _moodPose(LumoMood mood, double t) {
    if (t == 0) return _MoodPose.zero();
    final eased = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    switch (mood) {
      case LumoMood.greet:
        // Lean forward + bob
        return _MoodPose(
          rotation: math.sin(t * math.pi * 3) * 0.06 * (1 - t),
          translateY: -math.sin(t * math.pi) * 8,
        );
      case LumoMood.point:
        // Lean toward facing direction
        return _MoodPose(
          rotation: widget.facing.sign * 0.10 * eased,
          translateX: widget.facing.sign * 6 * eased,
        );
      case LumoMood.celebrate:
        // Big jump with rotation
        final jump = math.sin(t * math.pi);
        return _MoodPose(
          rotation: t * math.pi * 2, // full spin
          translateY: -jump * 40,
        );
      case LumoMood.comfort:
        // Soft tilt
        return _MoodPose(
          rotation: -0.10 * eased,
          translateY: -2,
        );
      case LumoMood.think:
        // Tilt up-right
        return _MoodPose(
          rotation: 0.08 * eased,
          translateY: -4 * eased,
        );
      case LumoMood.wave:
        // Energetic swing
        return _MoodPose(
          rotation: math.sin(t * math.pi * 4) * 0.08 * (1 - t),
        );
      case LumoMood.idle:
        return _MoodPose.zero();
    }
  }

  Color _moodAuraColor(LumoMood mood) {
    switch (mood) {
      case LumoMood.celebrate: return LumoColors.gold;
      case LumoMood.comfort:   return LumoColors.purpleLight;
      case LumoMood.think:     return LumoColors.blue;
      case LumoMood.wave:      return LumoColors.tealLight;
      case LumoMood.point:     return LumoColors.orange;
      case LumoMood.greet:     return LumoColors.orange;
      case LumoMood.idle:      return LumoColors.orangeLight;
    }
  }

  // ── Sparkles around fox during celebrate ────────────────────
  List<Widget> _buildCelebrateSparkles(double t) {
    final widgets = <Widget>[];
    final radius = widget.height * 0.55 * t;
    for (int i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3 + t * math.pi;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      widgets.add(Positioned(
        left: widget.height * 0.55 + x,
        top: widget.height * 0.5 + y,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.star_rounded,
            color: LumoColors.gold,
            size: 24 - i.toDouble() * 1.5,
          ),
        ),
      ));
    }
    return widgets;
  }

  Widget _buildThoughtBubble(double t) {
    return Positioned(
      top: 8,
      right: 18,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: t,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LumoColors.gold.withOpacity(.4),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Text('💡', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _MoodPose {
  const _MoodPose({
    this.rotation = 0,
    this.translateX = 0,
    this.translateY = 0,
  });
  factory _MoodPose.zero() => const _MoodPose();
  final double rotation;
  final double translateX;
  final double translateY;
}

/// Fallback if image fails to load
class _FallbackFox extends StatelessWidget {
  const _FallbackFox({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: height * 0.7,
      height: height,
      decoration: BoxDecoration(
        color: LumoColors.orange,
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Center(
        child: Text('🦊', style: TextStyle(fontSize: 80)),
      ),
    );
  }
}
