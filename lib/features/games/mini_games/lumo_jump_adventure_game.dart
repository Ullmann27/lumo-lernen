import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../domain/games/game_level_model.dart';

class LumoJumpAdventureGame extends StatefulWidget {
  const LumoJumpAdventureGame({super.key, required this.appState, required this.level});
  final LumoAppState appState;
  final GameLevel level;

  @override
  State<LumoJumpAdventureGame> createState() => _LumoJumpAdventureGameState();
}

class _LumoJumpAdventureGameState extends State<LumoJumpAdventureGame> with SingleTickerProviderStateMixin {
  static const double gravity = 1800;
  static const double jumpPower = -700;
  static const double runSpeed = 250;
  static const double floorY = 290;
  static const double playerW = 46;
  static const double playerH = 52;
  static const double coyoteTime = 0.15;
  static const double jumpBuffer = 0.16;

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  DateTime? _lastGroundedAt;
  DateTime? _jumpPressedAt;

  double playerX = 48;
  double playerY = floorY - playerH;
  double velocityY = 0;
  double viewportX = 0;
  double screenWidth = 390;
  double landSquash = 0;

  bool leftHeld = false;
  bool rightHeld = false;
  bool jumpHeld = false;
  bool grounded = false;
  bool wasGrounded = false;

  final List<Rect> platforms = List<Rect>.generate(
    14,
    (i) => Rect.fromLTWH(40 + i * 145.0, floorY - (i % 3) * 22.0, 112, 28),
  );
  final List<_Collectible> stars = List<_Collectible>.generate(
    5,
    (i) => _Collectible(Rect.fromLTWH(250 + i * 290.0, floorY - 72 - (i % 2) * 22.0, 34, 34)),
  );
  final List<_Gate> gates = List<_Gate>.generate(
    3,
    (i) => _Gate(Rect.fromLTWH(480 + i * 430.0, floorY - 92, 48, 48)),
  );

  Rect get playerRect => Rect.fromLTWH(playerX, playerY, playerW, playerH);
  double get worldWidth => 2200;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = ((elapsed - _lastTick).inMicroseconds / 1000000).clamp(0.001, 0.033).toDouble();
    _lastTick = elapsed;
    _updatePhysics(dt);
    _updateCamera();
    landSquash = math.max(0, landSquash - dt * 5);
    setState(() {});
  }

  void _updatePhysics(double dt) {
    final now = DateTime.now();
    final previous = playerRect;
    wasGrounded = grounded;

    if (leftHeld && !rightHeld) playerX -= runSpeed * dt;
    if (rightHeld && !leftHeld) playerX += runSpeed * dt;
    playerX = playerX.clamp(12, worldWidth - 90);

    var usedGravity = gravity;
    if (jumpHeld && velocityY.abs() < 80) usedGravity *= 0.55;
    velocityY = (velocityY + usedGravity * dt).clamp(-900, 900);
    playerY += velocityY * dt;
    grounded = false;

    for (final platform in platforms) {
      if (playerRect.overlaps(platform) && velocityY >= 0 && previous.bottom <= platform.top + 12) {
        playerY = platform.top - playerH;
        velocityY = 0;
        grounded = true;
        _lastGroundedAt = now;
        if (!wasGrounded) landSquash = 1;
      }
    }

    if (grounded && _jumpPressedAt != null && now.difference(_jumpPressedAt!).inMilliseconds / 1000 <= jumpBuffer) {
      _performJump(now);
    }

    if (playerY > floorY + 180) {
      playerX = math.max(48, viewportX + 56);
      playerY = floorY - playerH;
      velocityY = 0;
    }

    for (final star in stars) {
      if (!star.collected && playerRect.overlaps(star.rect)) star.collected = true;
    }
    for (final gate in gates) {
      if (!gate.solved && playerRect.overlaps(gate.rect)) gate.solved = true;
    }
  }

  void _updateCamera() {
    final lookAhead = rightHeld ? 90.0 : leftHeld ? -35.0 : 45.0;
    final target = (playerX + lookAhead - screenWidth * 0.36).clamp(0.0, math.max(0.0, worldWidth - screenWidth));
    viewportX += (target - viewportX) * 0.10;
  }

  void _jumpButton(bool down) {
    jumpHeld = down;
    if (!down) return;
    final now = DateTime.now();
    _jumpPressedAt = now;
    final canCoyote = _lastGroundedAt != null && now.difference(_lastGroundedAt!).inMilliseconds / 1000 <= coyoteTime;
    if (grounded || canCoyote) _performJump(now);
  }

  void _performJump(DateTime now) {
    velocityY = jumpPower;
    grounded = false;
    _jumpPressedAt = null;
    _lastGroundedAt = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBEEBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Lumo Jump: ${widget.level.title}', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: LumoColors.ink900)),
      ),
      body: LayoutBuilder(builder: (context, c) {
        screenWidth = c.maxWidth;
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ClipRect(
                  child: CustomPaint(
                    size: Size(c.maxWidth, c.maxHeight),
                    painter: _JumpPainter(
                      viewportX: viewportX,
                      playerX: playerX,
                      playerY: playerY,
                      velocityY: velocityY,
                      landSquash: landSquash,
                      platforms: platforms,
                      stars: stars,
                      gates: gates,
                    ),
                  ),
                ),
              ),
              _Controls(
                onLeft: (v) => setState(() => leftHeld = v),
                onRight: (v) => setState(() => rightHeld = v),
                onJump: _jumpButton,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Collectible {
  _Collectible(this.rect);
  final Rect rect;
  bool collected = false;
}

class _Gate {
  _Gate(this.rect);
  final Rect rect;
  bool solved = false;
}

class _JumpPainter extends CustomPainter {
  _JumpPainter({required this.viewportX, required this.playerX, required this.playerY, required this.velocityY, required this.landSquash, required this.platforms, required this.stars, required this.gates});
  final double viewportX;
  final double playerX;
  final double playerY;
  final double velocityY;
  final double landSquash;
  final List<Rect> platforms;
  final List<_Collectible> stars;
  final List<_Gate> gates;

  final Paint cloudPaint = Paint()..color = Colors.white.withOpacity(.86);
  final Paint hillPaint = Paint()..color = const Color(0xFF8AD47E).withOpacity(.58);
  final Paint shadowPaint = Paint()..color = Colors.black.withOpacity(.22);
  final Paint gatePaint = Paint()..color = const Color(0xFFFFB347);
  final Paint solvedPaint = Paint()..color = const Color(0xFF10B981);

  @override
  void paint(Canvas canvas, Size size) {
    _background(canvas, size);
    _midground(canvas, size);
    canvas.save();
    canvas.translate(-viewportX, 0);
    _playground(canvas);
    _lumo(canvas);
    canvas.restore();
  }

  void _background(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(colors: [Color(0xFFBEEBFF), Color(0xFFFFF3CF)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Offset.zero & size));
    for (var i = 0; i < 7; i++) {
      final x = (i * 150.0 - viewportX * .18) % (size.width + 190) - 90;
      final y = 34.0 + (i % 3) * 40;
      canvas.drawOval(Rect.fromLTWH(x, y, 92, 24), cloudPaint);
      canvas.drawOval(Rect.fromLTWH(x + 28, y - 13, 58, 34), cloudPaint);
    }
  }

  void _midground(Canvas canvas, Size size) {
    final path = Path()..moveTo(-80, size.height);
    for (var x = -80.0; x <= size.width + 120; x += 60) {
      path.lineTo(x, size.height - 88 - math.sin((x + viewportX * .38) / 90) * 18);
    }
    path..lineTo(size.width + 120, size.height)..close();
    canvas.drawPath(path, hillPaint);
  }

  void _playground(Canvas canvas) {
    for (final r in platforms) _platform(canvas, r);
    for (final s in stars) if (!s.collected) _text(canvas, 'S', s.rect, 26, const Color(0xFFFFC928));
    for (final g in gates) _gate(canvas, g.rect, g.solved);
  }

  void _platform(Canvas canvas, Rect rect) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), Paint()..color = const Color(0xFF24A85A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, rect.top, rect.width, 8), const Radius.circular(14)), Paint()..color = const Color(0xFFB9F7A8));
  }

  void _gate(Canvas canvas, Rect rect, bool solved) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), solved ? solvedPaint : gatePaint);
    _text(canvas, solved ? 'OK' : '?', rect, solved ? 16 : 26, Colors.white);
  }

  void _lumo(Canvas canvas) {
    final height = (_LumoJumpAdventureGameState.floorY - playerY).clamp(0, 180).toDouble();
    final shadowW = 50 + height * .08;
    canvas.drawOval(Rect.fromCenter(center: Offset(playerX + 24, _LumoJumpAdventureGameState.floorY + 4), width: shadowW, height: 12), shadowPaint);
    final stretch = velocityY < -50 ? .08 : 0.0;
    final squash = landSquash * .13;
    canvas.save();
    canvas.translate(playerX + 24, playerY + 27);
    canvas.scale(1 + squash - stretch * .45, 1 - squash + stretch);
    _text(canvas, 'L', const Rect.fromLTWH(-23, -27, 46, 54), 32, LumoColors.orange);
    canvas.restore();
  }

  void _text(Canvas canvas, String text, Rect rect, double fontSize, Color color) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout(maxWidth: rect.width + 20);
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _JumpPainter oldDelegate) => true;
}

class _Controls extends StatelessWidget {
  const _Controls({required this.onLeft, required this.onRight, required this.onJump});
  final ValueChanged<bool> onLeft;
  final ValueChanged<bool> onRight;
  final ValueChanged<bool> onJump;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.white.withOpacity(.92),
      child: Row(children: [
        Expanded(child: _HoldButton(icon: Icons.arrow_back_rounded, onHold: onLeft)),
        const SizedBox(width: 12),
        Expanded(child: _HoldButton(icon: Icons.keyboard_double_arrow_up_rounded, onHold: onJump, orange: true)),
        const SizedBox(width: 12),
        Expanded(child: _HoldButton(icon: Icons.arrow_forward_rounded, onHold: onRight)),
      ]),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.icon, required this.onHold, this.orange = false});
  final IconData icon;
  final ValueChanged<bool> onHold;
  final bool orange;

  @override
  Widget build(BuildContext context) {
    final color = orange ? LumoColors.orange : LumoColors.purple;
    return GestureDetector(
      onTapDown: (_) => onHold(true),
      onTapUp: (_) => onHold(false),
      onTapCancel: () => onHold(false),
      child: Container(
        height: 72,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: Icon(icon, size: 42, color: Colors.white),
      ),
    );
  }
}
