import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

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
  final double facing;

  @override
  State<LumoLivingAvatar> createState() => _LumoLivingAvatarState();
}

class _LumoLivingAvatarState extends State<LumoLivingAvatar> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
  late final AnimationController _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat(reverse: true);
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  late final AnimationController _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _moodCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  Timer? _blinkTimer;
  final _rng = math.Random();
  LumoMood _lastMood = LumoMood.greet;

  @override
  void initState() {
    super.initState();
    _lastMood = widget.appState.state.mood;
    widget.appState.addListener(_onStateChange);
    _scheduleBlink();
  }

  void _onStateChange() {
    final mood = widget.appState.state.mood;
    if (mood != _lastMood) {
      _lastMood = mood;
      _moodCtrl.forward(from: 0);
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: 3000 + _rng.nextInt(4000)), () {
      if (!mounted) return;
      _blink.forward(from: 0).then((_) => _blink.reverse());
      _scheduleBlink();
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChange);
    _blinkTimer?.cancel();
    _breath.dispose();
    _float.dispose();
    _sway.dispose();
    _blink.dispose();
    _tapCtrl.dispose();
    _moodCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _float, _sway, _blink, _tapCtrl, _moodCtrl]),
          builder: (context, _) => _buildAvatar(reduced),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool reduced) {
    final mood = widget.appState.state.mood;
    final breath = Curves.easeInOut.transform(_breath.value);
    final floating = Curves.easeInOut.transform(_float.value);
    final sway = Curves.easeInOut.transform(_sway.value);
    final tap = _tapCtrl.value;
    final moodT = _moodCtrl.value;

    final scaleY = 1.0 + breath * 0.025 - _blink.value * 0.04;
    final floatY = reduced ? 0.0 : (floating - 0.5) * 8.0;
    final swayRot = reduced ? 0.0 : (sway - 0.5) * 0.08;
    final tapJump = tap == 0 ? 0.0 : -math.sin(tap * math.pi) * 24.0;
    final tapScale = tap == 0 ? 1.0 : 1.0 - math.sin(tap * math.pi) * 0.06;
    final pose = _poseFor(mood, moodT);
    final auraColor = _moodAuraColor(mood);

    return SizedBox(
      width: widget.height * 1.1,
      height: widget.height + 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: 0.85 + breath * 0.25,
            child: Container(
              width: widget.height * 0.95,
              height: widget.height * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [auraColor.withOpacity(.30), auraColor.withOpacity(.08), Colors.transparent],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: widget.height * 0.45,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: RadialGradient(colors: [Colors.black.withOpacity(.20), Colors.transparent]),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(pose.dx, floatY + tapJump + pose.dy),
            child: Transform.rotate(
              angle: swayRot + pose.rotation,
              child: Transform(
                transform: Matrix4.identity()..scale(widget.facing * tapScale, scaleY),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/lumo_fox.png',
                  height: widget.height,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _FallbackFox(height: widget.height),
                ),
              ),
            ),
          ),
          if (mood == LumoMood.celebrate) ..._sparkles(moodT),
          if (mood == LumoMood.think) _thought(moodT),
        ],
      ),
    );
  }

  _Pose _poseFor(LumoMood mood, double t) {
    final e = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    switch (mood) {
      case LumoMood.point:
        return _Pose(dx: widget.facing * 6 * e, rotation: widget.facing * 0.10 * e);
      case LumoMood.celebrate:
        return _Pose(dy: -math.sin(t * math.pi) * 38, rotation: t * math.pi * 2);
      case LumoMood.comfort:
        return _Pose(dy: -2, rotation: -0.08 * e);
      case LumoMood.think:
        return _Pose(dy: -4 * e, rotation: 0.08 * e);
      case LumoMood.wave:
        return _Pose(rotation: math.sin(t * math.pi * 4) * 0.08 * (1 - t));
      case LumoMood.greet:
        return _Pose(dy: -math.sin(t * math.pi) * 8, rotation: math.sin(t * math.pi * 3) * 0.05 * (1 - t));
      case LumoMood.idle:
        return const _Pose();
    }
  }

  Color _moodAuraColor(LumoMood mood) {
    switch (mood) {
      case LumoMood.celebrate:
        return LumoColors.gold;
      case LumoMood.comfort:
        return LumoColors.purpleLight;
      case LumoMood.think:
        return LumoColors.blue;
      case LumoMood.wave:
        return LumoColors.tealLight;
      case LumoMood.point:
      case LumoMood.greet:
        return LumoColors.orange;
      case LumoMood.idle:
        return LumoColors.orangeLight;
    }
  }

  List<Widget> _sparkles(double t) {
    final widgets = <Widget>[];
    final radius = widget.height * 0.48 * t;
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3 + t * math.pi;
      widgets.add(Positioned(
        left: widget.height * 0.55 + math.cos(angle) * radius,
        top: widget.height * 0.5 + math.sin(angle) * radius,
        child: Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: const Icon(Icons.star_rounded, color: LumoColors.gold, size: 22),
        ),
      ));
    }
    return widgets;
  }

  Widget _thought(double t) {
    return Positioned(
      top: 8,
      right: 18,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: t.clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: LumoColors.gold.withOpacity(.4), blurRadius: 14)],
            ),
            child: const Text('💡', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _Pose {
  const _Pose({this.dx = 0, this.dy = 0, this.rotation = 0});
  final double dx;
  final double dy;
  final double rotation;
}

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
      child: const Center(child: Text('🦊', style: TextStyle(fontSize: 80))),
    );
  }
}
