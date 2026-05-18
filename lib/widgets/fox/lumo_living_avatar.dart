import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/lumo_voice.dart';
import '../../features/games/mini_games/fox_sprite.dart';

class LumoLivingAvatar extends StatefulWidget {
  const LumoLivingAvatar({
    super.key,
    required this.appState,
    required this.onTap,
    /// Standardhöhe erhöht: 230 → 265 für mehr Präsenz.
    this.height = 265,
    this.facing = 1.0,
  });

  final LumoAppState appState;
  final VoidCallback onTap;
  final double height;
  final double facing;

  @override
  State<LumoLivingAvatar> createState() => _LumoLivingAvatarState();
}

class _LumoLivingAvatarState extends State<LumoLivingAvatar>
    with TickerProviderStateMixin {
  // ── Animations-Controller ─────────────────────────────────
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))
        ..repeat(reverse: true);
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
        ..repeat(reverse: true);
  late final AnimationController _sway =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))
        ..repeat(reverse: true);
  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  late final AnimationController _tapCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _moodCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  /// Mundbewegung beim Sprechen: 0→1→0 im 180ms-Takt.
  late final AnimationController _jaw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180));

  // ── Ticker für absoluten animTime-Zähler ─────────────────
  late final Ticker _ticker;
  double _animTime = 0;
  Duration _lastTick = Duration.zero;

  // ── Sprechen-Zustand ──────────────────────────────────────
  /// Fallback-Dauer wenn VoiceStatus nicht kommt (z.B. kein TTS-Event).
  static const Duration _talkFallbackDuration = Duration(seconds: 5);
  bool _isSpeaking = false;
  Timer? _talkStopTimer;
  String _lastMessage = '';

  Timer? _blinkTimer;
  final _rng = math.Random();
  LumoMood _lastMood = LumoMood.greet;

  @override
  void initState() {
    super.initState();
    _lastMood = widget.appState.state.mood;
    _lastMessage = widget.appState.state.lumoMessage;
    widget.appState.addListener(_onStateChange);
    // Echtzeit VoiceStatus-Listener: Mund bleibt offen, solange Lumo spricht.
    LumoVoice.instance.status.addListener(_onVoiceStatus);
    _jaw.addStatusListener(_onJawStatus);
    _scheduleBlink();
    _ticker = createTicker(_onTick)..start();
  }

  void _onVoiceStatus() {
    final speaking = LumoVoice.instance.status.value == VoiceStatus.speaking;
    if (speaking && !_isSpeaking) {
      _startTalking();
    } else if (!speaking && _isSpeaking) {
      _stopTalking();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    setState(() => _animTime += dt);
  }

  void _onStateChange() {
    final st = widget.appState.state;
    if (st.mood != _lastMood) {
      _lastMood = st.mood;
      _moodCtrl.forward(from: 0);
    }
    // Fallback: Nachricht geändert aber VoiceStatus kam nicht → Mund kurz öffnen
    if (st.lumoMessage != _lastMessage) {
      _lastMessage = st.lumoMessage;
      if (!_isSpeaking) {
        _startTalking();
      }
    }
  }

  void _startTalking() {
    if (!mounted) return;
    _isSpeaking = true;
    _jaw.forward(from: 0);
    // Fallback-Timer: falls VoiceStatus.idle nie kommt
    _talkStopTimer?.cancel();
    _talkStopTimer = Timer(_talkFallbackDuration, _stopTalking);
  }

  void _stopTalking() {
    if (!mounted) return;
    setState(() => _isSpeaking = false);
    _jaw.stop();
  }

  void _onJawStatus(AnimationStatus status) {
    if (!_isSpeaking) return;
    // Mund auf/zu im Pendel-Rhythmus
    if (status == AnimationStatus.completed) {
      _jaw.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _jaw.forward();
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
    LumoVoice.instance.status.removeListener(_onVoiceStatus);
    _blinkTimer?.cancel();
    _talkStopTimer?.cancel();
    _ticker.dispose();
    _breath.dispose();
    _float.dispose();
    _sway.dispose();
    _blink.dispose();
    _tapCtrl.dispose();
    _moodCtrl.dispose();
    _jaw.removeStatusListener(_onJawStatus);
    _jaw.dispose();
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
          animation: Listenable.merge([
            _breath, _float, _sway, _blink, _tapCtrl, _moodCtrl, _jaw,
          ]),
          builder: (context, _) => _buildAvatar(reduced),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool reduced) {
    final mood = widget.appState.state.mood;
    final breath  = Curves.easeInOut.transform(_breath.value);
    final floating = Curves.easeInOut.transform(_float.value);
    final sway    = Curves.easeInOut.transform(_sway.value);
    final tap     = _tapCtrl.value;
    final moodT   = _moodCtrl.value;

    final scaleY   = 1.0 + breath * 0.025 - _blink.value * 0.04;
    final floatY   = reduced ? 0.0 : (floating - 0.5) * 8.0;
    final swayRot  = reduced ? 0.0 : (sway - 0.5) * 0.08;
    final tapJump  = tap == 0 ? 0.0 : -math.sin(tap * math.pi) * 24.0;
    final tapScale = tap == 0 ? 1.0 : 1.0 - math.sin(tap * math.pi) * 0.06;
    final pose     = _poseFor(mood, moodT);
    final auraColor = _moodAuraColor(mood);

    // Mund-Öffnung: sinusförmige Kurve für natürlichere Lippenbewegung
    final mouthOpen = _isSpeaking
        ? math.sin(_jaw.value * math.pi).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: widget.height * 1.1,
      height: widget.height + 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Aura-Glow
          Transform.scale(
            scale: 0.90 + breath * 0.28,
            child: Container(
              width: widget.height * 1.05,
              height: widget.height * 1.05,
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
          // Boden-Schatten
          Positioned(
            bottom: 0,
            child: Container(
              width: widget.height * 0.45,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: RadialGradient(
                    colors: [Colors.black.withOpacity(.20), Colors.transparent]),
              ),
            ),
          ),
          // Fuchs (animierter Vektor)
          Transform.translate(
            offset: Offset(pose.dx, floatY + tapJump + pose.dy),
            child: Transform.rotate(
              angle: swayRot + pose.rotation,
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(widget.facing * tapScale, scaleY),
                alignment: Alignment.center,
                child: SizedBox(
                  width: widget.height * 0.82,
                  height: widget.height,
                  child: CustomPaint(
                    painter: _AvatarFoxPainter(
                      animTime: _animTime,
                      mouthOpen: mouthOpen,
                      facingRight: widget.facing >= 0,
                    ),
                  ),
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
        return _Pose(
            rotation: math.sin(t * math.pi * 4) * 0.08 * (1 - t));
      case LumoMood.greet:
        return _Pose(
            dy: -math.sin(t * math.pi) * 8,
            rotation: math.sin(t * math.pi * 3) * 0.05 * (1 - t));
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
          child:
              const Icon(Icons.star_rounded, color: LumoColors.gold, size: 22),
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
              boxShadow: [
                BoxShadow(
                    color: LumoColors.gold.withOpacity(.4), blurRadius: 14)
              ],
            ),
            child: const Text('💡', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────

/// Malt den Lumo-Fuchs als Ganzkörper-Avatar (Idle-State) mit
/// Mundbewegung wenn Lumo spricht.
class _AvatarFoxPainter extends CustomPainter {
  const _AvatarFoxPainter({
    required this.animTime,
    required this.mouthOpen,
    required this.facingRight,
  });

  final double animTime;
  final double mouthOpen;
  final bool facingRight;

  @override
  void paint(Canvas canvas, Size size) {
    FoxSprite.paint(
      canvas,
      rect: Offset.zero & size,
      state: FoxAnimationState.idle,
      facingRight: facingRight,
      animTime: animTime,
      mouthOpen: mouthOpen,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarFoxPainter old) =>
      animTime != old.animTime ||
      mouthOpen != old.mouthOpen ||
      facingRight != old.facingRight;
}

// ── Hilfsklassen ──────────────────────────────────────────────────

class _Pose {
  const _Pose({this.dx = 0, this.dy = 0, this.rotation = 0});
  final double dx;
  final double dy;
  final double rotation;
}

