import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../lumo_jump/fox_sprite.dart' as fox;

/// Lebendiger Lumo am Home-Screen.
///
/// Heinz' Anforderung: Lumo soll das Kind individuell begruessen,
/// sich drehen, winken, smile - aber NICHT erkennbar links/rechts
/// wandern (wirkt abgehakt).
///
/// Stattdessen: Persoenlichkeitsbasierte Mini-Aktionen die abwechselnd
/// abgespielt werden - mit Sprechblasen, Drehung, sanften Reaktionen.
class LumoHomeFoxAvatar extends StatefulWidget {
  const LumoHomeFoxAvatar({
    super.key,
    this.size = 220,
    this.facingLeft = false,
    this.childName = 'Freund',
    this.onTap,
  });

  final double size;
  final bool facingLeft;
  final String childName;
  final VoidCallback? onTap;

  @override
  State<LumoHomeFoxAvatar> createState() => _LumoHomeFoxAvatarState();
}

enum _Behavior { greet, wave, spin, cheer, wonder, nap }

class _LumoHomeFoxAvatarState extends State<LumoHomeFoxAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _hopCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _bubbleCtrl;

  fox.FoxAction _action = fox.FoxAction.idle;
  bool _facingLeft = false;
  String? _speech;
  Timer? _behaviorTimer;
  Timer? _bubbleHideTimer;
  Timer? _resetTimer;
  bool _spritesPreloaded = false;
  final math.Random _rng = math.Random();

  static const List<String> _greetings = <String>[
    'Hallo {name}!',
    'Schön, dass du da bist!',
    'Bist du bereit?',
    'Lass uns lernen!',
    'Was möchtest du heute?',
    'Du schaffst das!',
    'Heute wirst du super!',
  ];
  static const List<String> _wonderTexts = <String>[
    'Hmm…',
    'Was machen wir heute?',
    'Ich überleg grad…',
  ];
  static const List<String> _cheerTexts = <String>[
    'Juhuuu!',
    'Suuuper!',
    'Tolle Sache!',
    'Yay!',
  ];
  static const List<String> _waveTexts = <String>[
    'Hier bin ich!',
    'Heyhey!',
    'Schau mal!',
  ];

  @override
  void initState() {
    super.initState();
    _facingLeft = widget.facingLeft;
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _hopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _behaviorTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _performBehavior(_Behavior.greet);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_spritesPreloaded) return;
    _spritesPreloaded = true;
    for (final action in fox.FoxAction.values) {
      final frames = fox.FoxAssets.frames[action];
      if (frames == null) continue;
      for (final path in frames) {
        precacheImage(AssetImage(path), context);
      }
    }
    precacheImage(const AssetImage(fox.FoxAssets.shadow), context);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _hopCtrl.dispose();
    _spinCtrl.dispose();
    _bubbleCtrl.dispose();
    _behaviorTimer?.cancel();
    _bubbleHideTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _scheduleNext() {
    _behaviorTimer?.cancel();
    final delay = Duration(seconds: 6 + _rng.nextInt(7));
    _behaviorTimer = Timer(delay, () {
      if (!mounted) return;
      final pick = _rng.nextDouble();
      _Behavior b;
      if (pick < 0.30) {
        b = _Behavior.greet;
      } else if (pick < 0.50) {
        b = _Behavior.wave;
      } else if (pick < 0.65) {
        b = _Behavior.cheer;
      } else if (pick < 0.78) {
        b = _Behavior.spin;
      } else if (pick < 0.92) {
        b = _Behavior.wonder;
      } else {
        b = _Behavior.nap;
      }
      _performBehavior(b);
    });
  }

  void _showSpeech(String text,
      {Duration duration = const Duration(seconds: 3)}) {
    _bubbleHideTimer?.cancel();
    setState(() => _speech = text.replaceAll('{name}', widget.childName));
    _bubbleCtrl.forward(from: 0);
    _bubbleHideTimer = Timer(duration, () {
      if (!mounted) return;
      _bubbleCtrl.reverse();
      Timer(const Duration(milliseconds: 320), () {
        if (mounted) setState(() => _speech = null);
      });
    });
  }

  void _performBehavior(_Behavior b) {
    if (!mounted) return;
    _resetTimer?.cancel();
    switch (b) {
      case _Behavior.greet:
        _hopCtrl.forward(from: 0);
        setState(() => _action = fox.FoxAction.jump);
        _showSpeech(_greetings[_rng.nextInt(_greetings.length)]);
        _resetTimer = Timer(const Duration(milliseconds: 520), () {
          if (mounted) setState(() => _action = fox.FoxAction.idle);
          _scheduleNext();
        });
        break;
      case _Behavior.wave:
        setState(() => _action = fox.FoxAction.roll);
        _showSpeech(_waveTexts[_rng.nextInt(_waveTexts.length)]);
        _resetTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _action = fox.FoxAction.idle);
          _scheduleNext();
        });
        break;
      case _Behavior.cheer:
        _hopCtrl.forward(from: 0);
        setState(() => _action = fox.FoxAction.jump);
        _showSpeech(_cheerTexts[_rng.nextInt(_cheerTexts.length)]);
        _resetTimer = Timer(const Duration(milliseconds: 540), () {
          if (!mounted) return;
          _hopCtrl.forward(from: 0);
          _resetTimer = Timer(const Duration(milliseconds: 520), () {
            if (mounted) setState(() => _action = fox.FoxAction.idle);
            _scheduleNext();
          });
        });
        break;
      case _Behavior.spin:
        _spinCtrl.forward(from: 0);
        setState(() => _action = fox.FoxAction.roll);
        _resetTimer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            _action = fox.FoxAction.idle;
            _facingLeft = !_facingLeft;
          });
          _scheduleNext();
        });
        break;
      case _Behavior.wonder:
        setState(() => _action = fox.FoxAction.duck);
        _showSpeech(_wonderTexts[_rng.nextInt(_wonderTexts.length)],
            duration: const Duration(seconds: 2));
        _resetTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _action = fox.FoxAction.idle);
          _scheduleNext();
        });
        break;
      case _Behavior.nap:
        _resetTimer = Timer(const Duration(seconds: 3), _scheduleNext);
        break;
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _hopCtrl.forward(from: 0);
    setState(() => _action = fox.FoxAction.jump);
    _showSpeech('Hihi! 🦊');
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 520), () {
      if (mounted) setState(() => _action = fox.FoxAction.idle);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_floatCtrl, _hopCtrl, _spinCtrl]),
          builder: (_, __) {
            final floatY = (_floatCtrl.value - 0.5) * 6;
            final hopY = -math.sin(_hopCtrl.value * math.pi) * 22;
            final spin = _spinCtrl.value * math.pi * 2;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              child: Transform.translate(
                offset: Offset(0, floatY + hopY),
                child: Transform.rotate(
                  angle: spin,
                  child: fox.FoxSprite(
                    action: _action,
                    size: widget.size,
                    facingLeft: _facingLeft,
                    showShadow: true,
                  ),
                ),
              ),
            );
          },
        ),
        if (_speech != null)
          Positioned(
            top: -8,
            child: AnimatedBuilder(
              animation: _bubbleCtrl,
              builder: (_, child) {
                final scale = Curves.easeOutBack
                    .transform(_bubbleCtrl.value.clamp(0.0, 1.0));
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(opacity: _bubbleCtrl.value, child: child),
                );
              },
              child: _SpeechBubble(text: _speech ?? ''),
            ),
          ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF97316).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color(0xFF1F2937),
          height: 1.2,
        ),
      ),
    );
  }
}
