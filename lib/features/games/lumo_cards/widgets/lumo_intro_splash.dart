// ════════════════════════════════════════════════════════════════════════
// LUMO INTRO SPLASH — Logo-Intro beim Spielstart
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-05-22: "Lumo Logo am Anfang des Spieles gross als Intro
// wenn man in das Spiel hineinswiped".
//
// Ablauf:
//  1. Logo faded + scaled rein (0..0.55 s, easeOutBack)
//  2. Logo bleibt kurz stehen mit pulsierendem Glow (0.55..1.5 s)
//  3. Faded raus (1.5..2.0 s)
//  4. onComplete() -> Screen zeigt das normale Spiel
//
// Per Tap kann der Splash uebersprungen werden.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_assets.dart';

class LumoIntroSplash extends StatefulWidget {
  const LumoIntroSplash({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<LumoIntroSplash> createState() => _LumoIntroSplashState();
}

class _LumoIntroSplashState extends State<LumoIntroSplash>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final AnimationController _glowCtrl;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_ctrl);
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_ctrl);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _ctrl.forward().whenComplete(() {
      if (!_completed && mounted) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _skip() {
    if (_completed) return;
    _completed = true;
    _ctrl.stop();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Color(0xFF3D2270),
                Color(0xFF1E1240),
                Color(0xFF0A0420),
              ],
              radius: 1.2,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ctrl, _glowCtrl]),
              builder: (_, __) {
                final glow = 0.45 + _glowCtrl.value * 0.45;
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFCD34D)
                                    .withOpacity(glow * 0.5),
                                blurRadius: 60,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: const Color(0xFF7C3AED)
                                    .withOpacity(glow * 0.35),
                                blurRadius: 90,
                                spreadRadius: 14,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              LumoCardsAssets.cardBack,
                              width: 220,
                              height: 308,
                              fit: BoxFit.cover,
                              cacheWidth: 440,
                              errorBuilder: (_, __, ___) => _fallbackCard(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'LUMO CARDS',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFCD34D),
                            letterSpacing: 2.4,
                            shadows: [
                              Shadow(
                                color:
                                    const Color(0xFF7C3AED).withOpacity(0.8),
                                blurRadius: 18,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: 0.7,
                          child: const Text(
                            'Tippe zum Starten',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackCard() {
    return Container(
      width: 220,
      height: 308,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF1E1240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          '🦊',
          style: TextStyle(fontSize: 110),
        ),
      ),
    );
  }
}
