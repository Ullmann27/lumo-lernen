// Lumo Jump Adventure - Fox animation integration
// Place this file for example at: lib/lumo_jump/fox_sprite.dart
// Then import it in your Lumo Jump game screen.

import 'dart:async';
import 'dart:math' as math;

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
  const FoxSprite({
    super.key,
    required this.action,
    this.size = 120,
    this.facingLeft = false,
    this.showShadow = true,
  });

  final FoxAction action;
  final double size;
  final bool facingLeft;
  final bool showShadow;

  @override
  State<FoxSprite> createState() => _FoxSpriteState();
}

class _FoxSpriteState extends State<FoxSprite> {
  Timer? _timer;
  int _frameIndex = 0;
  bool _assetFailed = false;

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
      _assetFailed = false;
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

  void _markAssetFailed(Object _, StackTrace? __) {
    if (!mounted || _assetFailed) return;
    setState(() => _assetFailed = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty || _assetFailed) {
      return _FoxFallbackSprite(
        action: widget.action,
        size: widget.size,
        facingLeft: widget.facingLeft,
        showShadow: widget.showShadow,
      );
    }
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
                  errorBuilder: (_, __, ___) => _FallbackShadow(width: widget.size * 0.50),
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
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markAssetFailed(error, stackTrace);
                });
                return _FoxFallbackSprite(
                  action: widget.action,
                  size: widget.size,
                  facingLeft: widget.facingLeft,
                  showShadow: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackShadow extends StatelessWidget {
  const _FallbackShadow({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.16,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.24),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FoxFallbackSprite extends StatelessWidget {
  const _FoxFallbackSprite({
    required this.action,
    required this.size,
    required this.facingLeft,
    required this.showShadow,
  });

  final FoxAction action;
  final double size;
  final bool facingLeft;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showShadow)
            Positioned(
              bottom: size * 0.08,
              child: _FallbackShadow(width: size * 0.58),
            ),
          Transform.scale(
            scaleX: facingLeft ? -1 : 1,
            child: CustomPaint(
              size: Size.square(size),
              painter: _FoxFallbackPainter(action),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoxFallbackPainter extends CustomPainter {
  const _FoxFallbackPainter(this.action);
  final FoxAction action;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final orange = Paint()..color = const Color(0xFFF97316);
    final orangeDark = Paint()..color = const Color(0xFFC2410C);
    final cream = Paint()..color = const Color(0xFFFEDBA4);
    final ink = Paint()..color = const Color(0xFF1F2937);
    final gold = Paint()..color = const Color(0xFFFCD34D);
    final purple = Paint()..color = const Color(0xFF7C3AED);

    if (action == FoxAction.roll) {
      canvas.drawCircle(Offset(w * .5, h * .54), w * .28, purple);
      canvas.drawCircle(Offset(w * .4, h * .45), w * .06, gold);
      canvas.drawCircle(Offset(w * .6, h * .62), w * .05, gold);
      return;
    }

    final duck = action == FoxAction.duck;
    final jump = action == FoxAction.jump || action == FoxAction.fall;
    final bodyY = h * (duck ? .64 : jump ? .56 : .62);
    final headY = h * (duck ? .42 : .33);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, bodyY),
        width: w * .46,
        height: h * (duck ? .25 : .36),
      ),
      orange,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .52, bodyY + h * .04), width: w * .24, height: h * .20),
      cream,
    );

    final tail = Path()
      ..moveTo(w * .66, bodyY - h * .02)
      ..quadraticBezierTo(w * .92, bodyY - h * .18, w * .82, bodyY + h * .12)
      ..quadraticBezierTo(w * .74, bodyY + h * .08, w * .66, bodyY + h * .04)
      ..close();
    canvas.drawPath(tail, orangeDark);

    canvas.drawCircle(Offset(w * .46, headY), w * .22, orange);
    final leftEar = Path()
      ..moveTo(w * .32, headY - w * .12)
      ..lineTo(w * .26, headY - w * .32)
      ..lineTo(w * .42, headY - w * .22)
      ..close();
    final rightEar = Path()
      ..moveTo(w * .56, headY - w * .13)
      ..lineTo(w * .64, headY - w * .32)
      ..lineTo(w * .70, headY - w * .08)
      ..close();
    canvas.drawPath(leftEar, orangeDark);
    canvas.drawPath(rightEar, orangeDark);
    canvas.drawCircle(Offset(w * .38, headY - h * .02), w * .025, ink);
    canvas.drawCircle(Offset(w * .52, headY - h * .02), w * .025, ink);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .46, headY + h * .07), width: w * .20, height: h * .10), cream);
    canvas.drawCircle(Offset(w * .46, headY + h * .04), w * .025, ink);

    if (action == FoxAction.run) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .34, h * .78, w * .08, h * .14), Radius.circular(w * .03)),
        orangeDark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .56, h * .76, w * .08, h * .14), Radius.circular(w * .03)),
        orangeDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FoxFallbackPainter oldDelegate) => oldDelegate.action != action;
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
