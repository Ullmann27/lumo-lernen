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
    this.height = 285,
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
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat(reverse: true);
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4300),
  )..repeat(reverse: true);
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat(reverse: true);
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 135),
  );
  late final AnimationController _tapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  late final AnimationController _moodCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final AnimationController _jaw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );

  late final Ticker _ticker;
  double _animTime = 0;
  Duration _lastTick = Duration.zero;

  static const Duration _talkFallbackDuration = Duration(seconds: 5);
  static const Duration _tapSpeechCooldown = Duration(seconds: 4);
  bool _isSpeaking = false;
  Timer? _talkStopTimer;
  Timer? _blinkTimer;
  String _lastMessage = '';
  LumoMood _lastMood = LumoMood.greet;
  DateTime? _lastTapSpeech;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _lastMood = widget.appState.state.mood;
    _lastMessage = widget.appState.state.lumoMessage;
    widget.appState.addListener(_onStateChange);
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
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = elapsed;
    setState(() => _animTime += dt);
  }

  void _onStateChange() {
    final st = widget.appState.state;
    if (st.mood != _lastMood) {
      _lastMood = st.mood;
      _moodCtrl.forward(from: 0);
    }
    if (st.lumoMessage != _lastMessage) {
      _lastMessage = st.lumoMessage;
      if (!_isSpeaking && widget.appState.state.settings.voiceEnabled) {
        _startTalking();
      }
    }
  }

  void _startTalking() {
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    _jaw.forward(from: 0);
    _talkStopTimer?.cancel();
    _talkStopTimer = Timer(_talkFallbackDuration, _stopTalking);
  }

  void _stopTalking() {
    if (!mounted) return;
    _talkStopTimer?.cancel();
    setState(() => _isSpeaking = false);
    _jaw.stop();
    _jaw.value = 0;
  }

  void _onJawStatus(AnimationStatus status) {
    if (!_isSpeaking) return;
    if (status == AnimationStatus.completed) {
      _jaw.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _jaw.forward();
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: 2600 + _rng.nextInt(4200)), () {
      if (!mounted) return;
      _blink.forward(from: 0).then((_) {
        if (mounted) _blink.reverse();
      });
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
    final now = DateTime.now();
    if (_lastTapSpeech == null || now.difference(_lastTapSpeech!) >= _tapSpeechCooldown) {
      _lastTapSpeech = now;
      unawaited(LumoVoice.instance.speak(
        _tapPhrase(),
        style: VoiceStyle.greeting,
      ));
    }
  }

  String _tapPhrase() {
    const phrases = <String>[
      'Ich bin da. Womit starten wir?',
      'Tippe eine Aufgabe an, dann lernen wir zusammen.',
      'Super, ich begleite dich ruhig Schritt fuer Schritt.',
      'Bereit? Wir schaffen das gemeinsam.',
    ];
    return phrases[_rng.nextInt(phrases.length)];
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _breath,
            _float,
            _sway,
            _blink,
            _tapCtrl,
            _moodCtrl,
            _jaw,
          ]),
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

    final scaleY = 1.02 + breath * 0.032 - _blink.value * 0.035;
    final scaleX = 1.06 + breath * 0.012;
    final floatY = reduced ? 0.0 : (floating - 0.5) * 9.0;
    final swayRot = reduced ? 0.0 : (sway - 0.5) * 0.075;
    final tapJump = tap == 0 ? 0.0 : -math.sin(tap * math.pi) * 26.0;
    final tapScale = tap == 0 ? 1.0 : 1.0 - math.sin(tap * math.pi) * 0.045;
    final speakingNod = _isSpeaking && !reduced ? math.sin(_animTime * 10) * 0.025 : 0.0;
    final pose = _poseFor(mood, moodT);
    final auraColor = _moodAuraColor(mood);
    final mouthOpen = _isSpeaking
        ? math.sin(_jaw.value * math.pi).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final responsiveHeight = widget.height.clamp(190.0, 300.0).toDouble();

    return SizedBox(
      width: responsiveHeight * 1.22,
      height: responsiveHeight + 72,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: 0.95 + breath * 0.30,
            child: Container(
              width: responsiveHeight * 1.12,
              height: responsiveHeight * 1.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    auraColor.withOpacity(.34),
                    auraColor.withOpacity(.11),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.58, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            child: Container(
              width: responsiveHeight * 0.56,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: RadialGradient(
                  colors: [Colors.black.withOpacity(.22), Colors.transparent],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(pose.dx, floatY + tapJump + pose.dy),
            child: Transform.rotate(
              angle: swayRot + speakingNod + pose.rotation,
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(widget.facing * tapScale * scaleX, scaleY),
                alignment: Alignment.center,
                child: SizedBox(
                  width: responsiveHeight * 0.88,
                  height: responsiveHeight,
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
          if (mood == LumoMood.celebrate) ..._sparkles(moodT, responsiveHeight),
          if (mood == LumoMood.think) _thought(moodT),
        ],
      ),
    );
  }

  _Pose _poseFor(LumoMood mood, double t) {
    final e = Curves.easeOut.transform(t.clamp(0.0, 1.0).toDouble());
    switch (mood) {
      case LumoMood.point:
        return _Pose(dx: widget.facing * 8 * e, rotation: widget.facing * 0.11 * e);
      case LumoMood.celebrate:
        return _Pose(dy: -math.sin(t * math.pi) * 40, rotation: t * math.pi * 2);
      case LumoMood.comfort:
        return _Pose(dy: -2, rotation: -0.075 * e);
      case LumoMood.think:
        return _Pose(dy: -5 * e, rotation: 0.075 * e);
      case LumoMood.wave:
        return _Pose(rotation: math.sin(t * math.pi * 4) * 0.09 * (1 - t));
      case LumoMood.greet:
        return _Pose(
          dy: -math.sin(t * math.pi) * 10,
          rotation: math.sin(t * math.pi * 3) * 0.055 * (1 - t),
        );
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

  List<Widget> _sparkles(double t, double avatarHeight) {
    final widgets = <Widget>[];
    final radius = avatarHeight * 0.50 * t;
    for (var i = 0; i < 7; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3.5 + t * math.pi;
      widgets.add(Positioned(
        left: avatarHeight * 0.58 + math.cos(angle) * radius,
        top: avatarHeight * 0.48 + math.sin(angle) * radius,
        child: Opacity(
          opacity: (1 - t).clamp(0.0, 1.0).toDouble(),
          child: const Icon(Icons.star_rounded, color: LumoColors.gold, size: 24),
        ),
      ));
    }
    return widgets;
  }

  Widget _thought(double t) {
    final v = t.clamp(0.0, 1.0).toDouble();
    return Positioned(
      top: 8,
      right: 18,
      child: Opacity(
        opacity: v,
        child: Transform.scale(
          scale: v,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: LumoColors.gold.withOpacity(.4), blurRadius: 14),
              ],
            ),
            child: const Text('💡', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

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

class _Pose {
  const _Pose({this.dx = 0, this.dy = 0, this.rotation = 0});
  final double dx;
  final double dy;
  final double rotation;
}
