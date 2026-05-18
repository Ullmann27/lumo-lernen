// Lumo Jump Adventure - Fox animation integration
// Place this file for example at: lib/lumo_jump/fox_sprite.dart
// Then import it in your Lumo Jump game screen.

import 'dart:async';
import 'package:flutter/material.dart';

enum FoxAction { idle, run, jump, fall, duck, roll }

class FoxAssets {
  static const Map<FoxAction, List<String>> frames = {
    FoxAction.idle: [
      'assets/lumo_jump/fox/idle/fox_idle_01.png',
      'assets/lumo_jump/fox/idle/fox_idle_02.png',
      'assets/lumo_jump/fox/idle/fox_idle_03.png',
      'assets/lumo_jump/fox/idle/fox_idle_04.png',
      'assets/lumo_jump/fox/idle/fox_idle_05.png',
      'assets/lumo_jump/fox/idle/fox_idle_06.png',
      'assets/lumo_jump/fox/idle/fox_idle_07.png',
      'assets/lumo_jump/fox/idle/fox_idle_08.png',
    ],
    FoxAction.run: [
      'assets/lumo_jump/fox/run/fox_run_01.png',
      'assets/lumo_jump/fox/run/fox_run_02.png',
      'assets/lumo_jump/fox/run/fox_run_03.png',
      'assets/lumo_jump/fox/run/fox_run_04.png',
      'assets/lumo_jump/fox/run/fox_run_05.png',
      'assets/lumo_jump/fox/run/fox_run_06.png',
      'assets/lumo_jump/fox/run/fox_run_07.png',
      'assets/lumo_jump/fox/run/fox_run_08.png',
      'assets/lumo_jump/fox/run/fox_run_09.png',
      'assets/lumo_jump/fox/run/fox_run_10.png',
      'assets/lumo_jump/fox/run/fox_run_11.png',
      'assets/lumo_jump/fox/run/fox_run_12.png',
    ],
    FoxAction.jump: [
      'assets/lumo_jump/fox/jump/fox_jump_01.png',
      'assets/lumo_jump/fox/jump/fox_jump_02.png',
      'assets/lumo_jump/fox/jump/fox_jump_03.png',
      'assets/lumo_jump/fox/jump/fox_jump_04.png',
    ],
    FoxAction.fall: [
      'assets/lumo_jump/fox/fall/fox_fall_01.png',
      'assets/lumo_jump/fox/fall/fox_fall_02.png',
      'assets/lumo_jump/fox/fall/fox_fall_03.png',
      'assets/lumo_jump/fox/fall/fox_fall_04.png',
    ],
    FoxAction.duck: [
      'assets/lumo_jump/fox/duck/fox_duck_01.png',
      'assets/lumo_jump/fox/duck/fox_duck_02.png',
      'assets/lumo_jump/fox/duck/fox_duck_03.png',
    ],
    FoxAction.roll: [
      'assets/lumo_jump/fox/roll/fox_roll_01.png',
      'assets/lumo_jump/fox/roll/fox_roll_02.png',
      'assets/lumo_jump/fox/roll/fox_roll_03.png',
      'assets/lumo_jump/fox/roll/fox_roll_04.png',
      'assets/lumo_jump/fox/roll/fox_roll_05.png',
      'assets/lumo_jump/fox/roll/fox_roll_06.png',
      'assets/lumo_jump/fox/roll/fox_roll_07.png',
      'assets/lumo_jump/fox/roll/fox_roll_08.png',
    ],
  };

  static const Map<FoxAction, double> fps = {
    FoxAction.idle: 8,
    FoxAction.run: 16,
    FoxAction.jump: 10,
    FoxAction.fall: 10,
    FoxAction.duck: 6,
    FoxAction.roll: 16,
  };

  static const String shadow = 'assets/lumo_jump/fox/shadow/fox_shadow.png';
}

class FoxSprite extends StatefulWidget {
  final FoxAction action;
  final double size;
  final bool facingLeft;
  final bool showShadow;

  const FoxSprite({
    super.key,
    required this.action,
    this.size = 120,
    this.facingLeft = false,
    this.showShadow = true,
  });

  @override
  State<FoxSprite> createState() => _FoxSpriteState();
}

class _FoxSpriteState extends State<FoxSprite> {
  Timer? _timer;
  int _frameIndex = 0;

  List<String> get _frames => FoxAssets.frames[widget.action] ?? const [];
  double get _fps => FoxAssets.fps[widget.action] ?? 8;

  @override
  void initState() {
    super.initState();
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant FoxSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action != widget.action) {
      _frameIndex = 0;
      _restartAnimation();
    }
  }

  void _restartAnimation() {
    _timer?.cancel();
    if (_frames.length <= 1) return;
    final duration = Duration(milliseconds: (1000 / _fps).round());
    _timer = Timer.periodic(duration, (_) {
      if (!mounted) return;
      setState(() => _frameIndex = (_frameIndex + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) return const SizedBox.shrink();
    final currentFrame = _frames[_frameIndex.clamp(0, _frames.length - 1)];

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showShadow)
            Positioned(
              bottom: widget.size * 0.06,
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  FoxAssets.shadow,
                  width: widget.size * 0.50,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(widget.facingLeft ? -1.0 : 1.0, 1.0, 1.0),
            child: Image.asset(
              currentFrame,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

FoxAction resolveFoxAction({
  required bool isRolling,
  required bool isDucking,
  required bool isOnGround,
  required double velocityX,
  required double velocityY,
}) {
  if (isRolling) return FoxAction.roll;
  if (isDucking) return FoxAction.duck;
  if (!isOnGround && velocityY < 0) return FoxAction.jump;
  if (!isOnGround && velocityY >= 0) return FoxAction.fall;
  if (velocityX.abs() > 5) return FoxAction.run;
  return FoxAction.idle;
}
