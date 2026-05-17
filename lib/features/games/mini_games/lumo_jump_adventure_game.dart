import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../domain/games/game_level_model.dart';

abstract class _JumpAssets {
  static const lumoIdle = 'assets/images/lumo/lumo_idle.png';
  static const lumoRun = 'assets/images/lumo/lumo_run.png';
  static const lumoJump = 'assets/images/lumo/lumo_jump.png';
  static const platform = 'assets/images/game/platform_mid.png';
  static const star = 'assets/images/game/star_gold.png';
  static const question = 'assets/images/game/question_block.png';
  static const chest = 'assets/images/game/chest.png';
}

abstract class _Grid {
  static const tile = 64.0;
  static const half = 32.0;
  static const playerW = 48.0;
  static const playerH = 56.0;
  static const floorY = 320.0;
}

abstract class _Palette {
  static const skyTop = Color(0xFFAEDFF7);
  static const skyBottom = Color(0xFFFFE8BA);
  static const hill = Color(0xFF84B97A);
  static const forest = Color(0xFF3F7D4C);
  static const grass = Color(0xFF4E9A57);
  static const grassLight = Color(0xFFA7D986);
  static const earth = Color(0xFF8B6B4A);
  static const star = Color(0xFFFFC857);
  static const question = Color(0xFFEAA047);
  static const solved = Color(0xFF68B684);
}

enum _LumoState { idle, run, jump, fall, hit }
enum _ObjectType { star, question, chest }

class LumoJumpAdventureGame extends StatefulWidget {
  const LumoJumpAdventureGame({super.key, required this.appState, required this.level});
  final LumoAppState appState;
  final GameLevel level;

  @override
  State<LumoJumpAdventureGame> createState() => _LumoJumpAdventureGameState();
}

class _LumoJumpAdventureGameState extends State<LumoJumpAdventureGame> with SingleTickerProviderStateMixin {
  static const gravity = 1800.0;
  static const jumpPower = -700.0;
  static const runSpeed = 250.0;
  static const terminalVelocity = 900.0;
  static const coyoteTime = 0.15;
  static const jumpBuffer = 0.16;

  late final Ticker _ticker;
  late final _World world;
  Duration _lastTick = Duration.zero;
  DateTime? _lastGroundedAt;
  DateTime? _jumpPressedAt;

  double playerX = _Grid.tile * 1.5;
  double playerY = _Grid.floorY - _Grid.playerH;
  double velocityY = 0;
  double viewportX = 0;
  double screenWidth = 390;
  double landSquash = 0;
  bool leftHeld = false;
  bool rightHeld = false;
  bool jumpHeld = false;
  bool grounded = false;
  bool wasGrounded = false;
  _LumoState lumoState = _LumoState.idle;

  Rect get playerRect => Rect.fromLTWH(playerX, playerY, _Grid.playerW, _Grid.playerH);

  @override
  void initState() {
    super.initState();
    world = _LevelGenerator.generate(seed: _dailySeed(widget.level.id));
    _ticker = createTicker(_onTick)..start();
  }

  int _dailySeed(int levelId) {
    final d = DateTime.now();
    return d.year * 10000 + d.month * 100 + d.day + levelId * 97;
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
    _updateLumoState();
    setState(() {});
  }

  void _updatePhysics(double dt) {
    final now = DateTime.now();
    final previous = playerRect;
    wasGrounded = grounded;
    if (leftHeld && !rightHeld) playerX -= runSpeed * dt;
    if (rightHeld && !leftHeld) playerX += runSpeed * dt;
    playerX = playerX.clamp(_Grid.tile, world.width - _Grid.tile);

    var appliedGravity = gravity;
    if (velocityY.abs() < 50) appliedGravity *= 0.5; // Apex-Float.
    if (jumpHeld && velocityY.abs() < 80) appliedGravity *= 0.75;
    velocityY = (velocityY + appliedGravity * dt).clamp(-terminalVelocity, terminalVelocity);
    playerY += velocityY * dt;
    grounded = false;

    for (final platform in world.platforms) {
      if (playerRect.overlaps(platform) && velocityY >= 0 && previous.bottom <= platform.top + 12) {
        playerY = platform.top - _Grid.playerH;
        velocityY = 0;
        grounded = true;
        _lastGroundedAt = now;
        if (!wasGrounded) landSquash = 1;
      }
    }

    if (grounded && _jumpPressedAt != null && now.difference(_jumpPressedAt!).inMilliseconds / 1000 <= jumpBuffer) {
      _performJump(now);
    }

    if (playerY > _Grid.floorY + _Grid.tile * 3) {
      playerX = math.max(_Grid.tile, viewportX + _Grid.tile);
      playerY = _Grid.floorY - _Grid.playerH;
      velocityY = 0;
      lumoState = _LumoState.hit;
    }

    for (final object in world.objects) {
      if (object.active && playerRect.overlaps(object.rect)) object.active = false;
    }
  }

  void _updateCamera() {
    final lookAhead = rightHeld ? _Grid.tile * 1.4 : leftHeld ? -_Grid.half : _Grid.tile;
    final target = (playerX + lookAhead - screenWidth * 0.36).clamp(0.0, math.max(0.0, world.width - screenWidth));
    viewportX += (target - viewportX) * 0.10;
  }

  void _updateLumoState() {
    if (!grounded) {
      lumoState = velocityY < 0 ? _LumoState.jump : _LumoState.fall;
    } else if (leftHeld || rightHeld) {
      lumoState = _LumoState.run;
    } else if (lumoState != _LumoState.hit) {
      lumoState = _LumoState.idle;
    }
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
    lumoState = _LumoState.jump;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.skyTop,
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
                    painter: _JumpPainter(world: world, viewportX: viewportX, playerX: playerX, playerY: playerY, velocityY: velocityY, landSquash: landSquash, lumoState: lumoState),
                  ),
                ),
              ),
              _Controls(onLeft: (v) => setState(() => leftHeld = v), onRight: (v) => setState(() => rightHeld = v), onJump: _jumpButton),
            ],
          ),
        );
      }),
    );
  }
}

class _World {
  const _World(this.platforms, this.objects, this.width);
  final List<Rect> platforms;
  final List<_WorldObject> objects;
  final double width;
}

class _WorldObject {
  _WorldObject(this.type, this.rect, {this.active = true});
  final _ObjectType type;
  final Rect rect;
  bool active;
}

class _LevelGenerator {
  const _LevelGenerator._();

  static double get maxJumpDistance {
    final airTime = (_LumoJumpAdventureGameState.jumpPower.abs() / _LumoJumpAdventureGameState.gravity) * 2;
    return _LumoJumpAdventureGameState.runSpeed * airTime * 0.72;
  }

  static _World generate({required int seed}) {
    final random = math.Random(seed);
    final platforms = <Rect>[Rect.fromLTWH(0, _Grid.floorY, _Grid.tile * 8, _Grid.half)];
    final objects = <_WorldObject>[];
    var current = platforms.first;
    for (var i = 0; i < 12; i++) {
      final width = _Grid.tile * (2 + random.nextInt(3));
      var next = Rect.fromLTWH(current.right + _Grid.tile * (1 + random.nextInt(2)), (current.top + (random.nextInt(3) - 1) * _Grid.half).clamp(_Grid.floorY - _Grid.tile * 2, _Grid.floorY + _Grid.half).toDouble(), width, _Grid.half);
      if (!isJumpPossible(current, next)) next = Rect.fromLTWH(current.right + _Grid.tile, current.top, width, _Grid.half);
      platforms.add(next);
      if (i > 2) {
        final cx = next.left + next.width / 2 - _Grid.half / 2;
        final type = i % 3 == 2 ? _ObjectType.question : _ObjectType.star;
        objects.add(_WorldObject(type, Rect.fromLTWH(cx, next.top - _Grid.tile, _Grid.half, _Grid.half)));
      }
      current = next;
    }
    final end = Rect.fromLTWH(current.right + _Grid.tile, current.top, _Grid.tile * 5, _Grid.half);
    platforms.add(end);
    objects.add(_WorldObject(_ObjectType.chest, Rect.fromLTWH(end.left + _Grid.tile * 2, end.top - _Grid.tile, _Grid.tile, _Grid.tile)));
    return _World(platforms, objects, end.right + _Grid.tile * 2);
  }

  static bool isJumpPossible(Rect from, Rect to) {
    final horizontalGap = math.max(0.0, to.left - from.right);
    final verticalUp = math.max(0.0, from.top - to.top);
    final maxRise = (_LumoJumpAdventureGameState.jumpPower * _LumoJumpAdventureGameState.jumpPower) / (2 * _LumoJumpAdventureGameState.gravity);
    return horizontalGap <= maxJumpDistance && verticalUp <= maxRise * 0.75;
  }
}

class _JumpPainter extends CustomPainter {
  _JumpPainter({required this.world, required this.viewportX, required this.playerX, required this.playerY, required this.velocityY, required this.landSquash, required this.lumoState});
  final _World world;
  final double viewportX;
  final double playerX;
  final double playerY;
  final double velocityY;
  final double landSquash;
  final _LumoState lumoState;
  final Paint cloudPaint = Paint()..color = Colors.white.withOpacity(.82);
  final Paint hillPaint = Paint()..color = _Palette.hill.withOpacity(.60);
  final Paint forestPaint = Paint()..color = _Palette.forest.withOpacity(.55);
  final Paint shadowPaint = Paint()..color = Colors.black.withOpacity(.22);
  final Paint grassPaint = Paint()..color = _Palette.grass;
  final Paint grassTopPaint = Paint()..color = _Palette.grassLight;
  final Paint earthPaint = Paint()..color = _Palette.earth;
  final Paint starPaint = Paint()..color = _Palette.star;
  final Paint questionPaint = Paint()..color = _Palette.question;
  final Paint lumoPaint = Paint()..color = LumoColors.orange;

  @override
  void paint(Canvas canvas, Size size) {
    _background(canvas, size);
    _midground(canvas, size);
    canvas.save();
    canvas.translate(-viewportX, 0);
    _playground(canvas);
    renderLumo(canvas, const Size(_Grid.playerW, _Grid.playerH));
    canvas.restore();
  }

  void _background(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(colors: [_Palette.skyTop, _Palette.skyBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Offset.zero & size));
    for (var i = 0; i < 7; i++) {
      final x = (i * _Grid.tile * 2.5 - viewportX * .12) % (size.width + _Grid.tile * 4) - _Grid.tile * 2;
      canvas.drawOval(Rect.fromLTWH(x, _Grid.half + (i % 3) * _Grid.half, _Grid.tile * 1.5, _Grid.half), cloudPaint);
    }
  }

  void _midground(Canvas canvas, Size size) {
    final path = Path()..moveTo(-_Grid.tile, size.height);
    for (var x = -_Grid.tile; x <= size.width + _Grid.tile * 2; x += _Grid.tile) {
      path.lineTo(x, size.height - _Grid.tile * 1.4 - math.sin((x + viewportX * .24) / 130) * 18);
    }
    path..lineTo(size.width + _Grid.tile, size.height)..close();
    canvas.drawPath(path, hillPaint);
    for (var i = 0; i < 9; i++) {
      final x = (i * _Grid.tile * 3 - viewportX * .46) % (size.width + _Grid.tile * 4) - _Grid.tile;
      final y = size.height - _Grid.tile * 2.4 - (i % 2) * 18;
      canvas.drawCircle(Offset(x, y), _Grid.half, forestPaint);
      canvas.drawCircle(Offset(x + _Grid.half, y + 10), _Grid.half * .9, forestPaint);
    }
  }

  void _playground(Canvas canvas) {
    for (final platform in world.platforms) _platform(canvas, platform);
    for (final obj in world.objects) {
      if (!obj.active) continue;
      if (obj.type == _ObjectType.star) _star(canvas, obj.rect.center);
      if (obj.type == _ObjectType.question) _block(canvas, obj.rect);
      if (obj.type == _ObjectType.chest) _text(canvas, 'T', obj.rect, 30, _Palette.earth);
    }
  }

  void _platform(Canvas canvas, Rect rect) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), earthPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, rect.top, rect.width, _Grid.half), const Radius.circular(12)), grassPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, rect.top, rect.width, 8), const Radius.circular(8)), grassTopPaint);
  }

  void _star(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 15, starPaint);
    _text(canvas, 'S', Rect.fromCenter(center: center, width: 32, height: 32), 16, Colors.white);
  }

  void _block(Canvas canvas, Rect rect) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), questionPaint);
    _text(canvas, '?', rect, 26, Colors.white);
  }

  void renderLumo(Canvas canvas, Size size) {
    final jumpHeight = (_Grid.floorY - playerY).clamp(0, _Grid.tile * 3).toDouble();
    canvas.drawOval(Rect.fromCenter(center: Offset(playerX + size.width / 2, _Grid.floorY + 5), width: 48 + jumpHeight * .08, height: 12), shadowPaint);
    final stretch = lumoState == _LumoState.jump ? .09 : 0.0;
    final squash = landSquash * .14;
    canvas.save();
    canvas.translate(playerX + size.width / 2, playerY + size.height / 2);
    canvas.scale(1 + squash - stretch * .45, 1 - squash + stretch);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height), lumoPaint);
    _text(canvas, 'L', Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height), 26, Colors.white);
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
