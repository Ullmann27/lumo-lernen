// ════════════════════════════════════════════════════════════════════════
//                    LUMO KART ADVENTURE - Flame Game
// ════════════════════════════════════════════════════════════════════════
//
// Kindgerechtes 2.5D-Racing-Spiel im Lumo-Universum.
// Top-Down-View mit Pixar-gerenderten Sprites aus Heinz' Asset-Pack.
//
// Spielprinzip:
//   - Lumo faehrt in seinem Kart eine endlose Strecke nach oben (vertikal)
//   - Spieler steuert links/rechts mit Virtual-Joystick oder Tap-Steuerung
//   - Sterne sammeln (+XP)
//   - Kisten ausweichen (Slowdown bei Berührung)
//   - Boost-Pads geben Speed-Schub
//   - Frageblöcke öffnen Lernfragen (Lernintegration mit AppState)
//   - Nach X Sekunden: Ziel erreicht, Belohnung
//
// Inspiriert von Top-Mobile-Racers (Subway Surfers, Mario Kart Tour),
// aber NICHT kopiert. Eigenes Design, eigene Assets.

import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';

// ── Tuning-Konstanten ────────────────────────────────────────────────
const double _kartMaxSpeed   = 320;
const double _kartAccel      = 360;
const double _kartTurnSpeed  = 280;
const double _boostMul       = 1.7;
const double _boostDuration  = 1.8;
const double _crashSlowdown  = 0.45;
const double _crashDuration  = 0.6;
const double _trackWidth     = 360;  // Spielfeld-Breite
const double _kartW          = 90;
const double _kartH          = 120;
const double _starSize       = 50;
const double _crateSize      = 56;
const double _padSize        = 80;
const double _qBlockSize     = 64;
const double _raceDuration   = 90;   // 90 Sekunden Ziel

// ════════════════════════════════════════════════════════════════════════
// HAUPT-SCREEN
// ════════════════════════════════════════════════════════════════════════

class LumoKartScreen extends StatefulWidget {
  const LumoKartScreen({
    super.key,
    required this.appState,
  });

  final LumoAppState appState;

  @override
  State<LumoKartScreen> createState() => _LumoKartScreenState();
}

class _LumoKartScreenState extends State<LumoKartScreen> {
  late final LumoKartGame _game;

  @override
  void initState() {
    super.initState();
    _game = LumoKartGame(
      onFinish: _onFinish,
      onStar: _onStar,
    );
  }

  void _onStar(int total) => setState(() {});
  void _onFinish(int stars, double timeUsed) {
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 8);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        stars: stars,
        timeUsed: timeUsed,
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Stack(
        children: [
          // Game-Layer
          GameWidget<LumoKartGame>(game: _game),
          // HUD-Overlay (oben)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: _KartHud(game: _game),
            ),
          ),
          // Steuerung links
          Positioned(
            left: 28, bottom: 32,
            child: _SteeringJoystick(
              onChanged: (vec) => _game.kart.stickX = vec.dx,
            ),
          ),
          // Boost-Button rechts
          Positioned(
            right: 28, bottom: 40,
            child: _BoostButton(onTap: _game.kart.tryManualBoost),
          ),
          // Zurueck oben links
          Positioned(
            top: 0, left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// FLAME GAME
// ════════════════════════════════════════════════════════════════════════

class LumoKartGame extends FlameGame {
  LumoKartGame({required this.onFinish, required this.onStar});

  final void Function(int stars, double timeUsed) onFinish;
  final void Function(int starsTotal) onStar;

  late KartPlayerComponent kart;
  double totalTime    = 0;
  double cameraY      = 0;
  int    stars        = 0;
  int    boostsUsed   = 0;
  bool   finished     = false;

  /// Spawn-Spawn-Tracker: y-Position bis zu der schon gespawnt wurde
  double _spawnedUpTo = 0;
  final math.Random _rng = math.Random(42);

  @override
  Color backgroundColor() => const Color(0xFF65A30D);  // Wiesen-Gruen

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = '';

    // Kart-Spieler
    kart = KartPlayerComponent(game: this);
    await add(kart);

    // Erstmal vor-spawnen
    _populateAhead(800);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (finished) return;
    totalTime += dt;

    // Kamera scrollt mit Kart (kart bewegt sich relativ konstant nach oben)
    // Wir nutzen cameraY damit Welt-Objekte richtig positioniert sind
    cameraY = kart.distance;

    // Mehr Objekte spawnen wenn noetig
    if (kart.distance > _spawnedUpTo - 600) {
      _populateAhead(600);
    }

    // Aufraeumen: Objekte hinter Kamera entfernen
    for (final c in children.whereType<_WorldObject>().toList()) {
      if (c.worldY < kart.distance - 400) {
        c.removeFromParent();
      }
    }

    // Ziel erreicht?
    if (totalTime >= _raceDuration && !finished) {
      finished = true;
      onFinish(stars, totalTime);
    }
  }

  void _populateAhead(double distance) {
    final startY = _spawnedUpTo + 120.0;
    final endY = _spawnedUpTo + distance;
    var y = startY;
    while (y < endY) {
      // Wahl pro 100-180px
      final pick = _rng.nextDouble();
      if (pick < 0.45) {
        // Stern
        final lane = _rng.nextInt(3);  // 0=L, 1=M, 2=R
        add(KartStarComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      } else if (pick < 0.65) {
        // Kiste
        final lane = _rng.nextInt(3);
        add(KartCrateComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      } else if (pick < 0.78) {
        // Boost-Pad
        final lane = _rng.nextInt(3);
        add(KartBoostPadComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      } else if (pick < 0.85) {
        // Frageblock
        final lane = _rng.nextInt(3);
        add(KartQuestionBlockComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      }
      y += 110 + _rng.nextDouble() * 80;
    }
    _spawnedUpTo = endY;
  }

  double _laneToX(int lane) {
    final laneW = _trackWidth / 3;
    return -_trackWidth / 2 + laneW * (lane + 0.5);
  }

  void collectStar() {
    stars++;
    onStar(stars);
  }

  /// Konvertiert Welt-Y in Bildschirm-Y (kart bleibt bei 70% unten zentriert)
  double worldToScreenY(double worldY) =>
      (size.y * 0.75) - (worldY - kart.distance);

  double worldToScreenX(double worldX) => size.x / 2 + worldX;
}

// ════════════════════════════════════════════════════════════════════════
// WORLD-OBJECT BASIS
// ════════════════════════════════════════════════════════════════════════

abstract class _WorldObject extends PositionComponent {
  _WorldObject({required this.game, required this.worldX, required this.worldY});
  final LumoKartGame game;
  final double worldX;
  double worldY;
  bool consumed = false;

  /// Wenn true: Element wurde getroffen und ist deaktiviert.
  bool get isActive => !consumed;

  Rect get worldRect => Rect.fromCenter(
      center: Offset(worldX, worldY),
      width: size.x,
      height: size.y);
}

// ════════════════════════════════════════════════════════════════════════
// KART PLAYER COMPONENT
// ════════════════════════════════════════════════════════════════════════

class KartPlayerComponent extends PositionComponent {
  KartPlayerComponent({required this.game})
      : super(size: Vector2(_kartW, _kartH), anchor: Anchor.center);
  final LumoKartGame game;

  Sprite? _kartSprite;
  double  speed         = 0;
  double  laneX         = 0;  // -1..+1
  double  stickX        = 0;  // Joystick-Input
  double  distance      = 0;  // Welt-Y (steigt)
  double  boostTimer    = 0;
  double  crashTimer    = 0;
  double  tilt          = 0;  // visuell

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final img = await game.images
          .load('assets/lumo_kart/kart/lumo_kart_360_vehicle_sheet_asset_001.png');
      _kartSprite = Sprite(img);
    } catch (_) {
      _kartSprite = null;
    }
  }

  void tryManualBoost() {
    if (boostTimer <= 0 && crashTimer <= 0) {
      boostTimer = 1.2;
      HapticFeedback.mediumImpact();
      game.boostsUsed++;
    }
  }

  void applyBoost(double duration) {
    boostTimer = math.max(boostTimer, duration);
  }

  void applyCrash() {
    crashTimer = _crashDuration;
    HapticFeedback.heavyImpact();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Speed-Logik
    final targetMax = (boostTimer > 0 ? _kartMaxSpeed * _boostMul
                                       : _kartMaxSpeed) *
                      (crashTimer > 0 ? _crashSlowdown : 1.0);
    if (speed < targetMax) {
      speed = math.min(targetMax, speed + _kartAccel * dt);
    } else {
      speed = math.max(targetMax, speed - _kartAccel * 0.5 * dt);
    }

    // Vorwaerts-Bewegung
    distance += speed * dt;

    // Lenken (Stick hat Prio)
    final inputX = stickX.abs() > 0.05 ? stickX.clamp(-1.0, 1.0) : 0.0;
    laneX = (laneX + inputX * _kartTurnSpeed * dt / (_trackWidth / 2))
        .clamp(-0.95, 0.95);

    // Visuelle Neigung beim Lenken
    tilt = tilt * 0.85 + inputX * 0.15 * 0.15;

    if (boostTimer > 0) boostTimer -= dt;
    if (crashTimer > 0) crashTimer -= dt;

    // Position auf Bildschirm
    position.x = game.size.x / 2 + laneX * (_trackWidth / 2);
    position.y = game.size.y * 0.75;

    // Kollisionspruefung
    _checkCollisions();
  }

  void _checkCollisions() {
    final kartWorldRect = Rect.fromCenter(
        center: Offset(laneX * (_trackWidth / 2), distance),
        width: _kartW * 0.7,
        height: _kartH * 0.7);
    for (final obj in game.children.whereType<_WorldObject>()) {
      if (obj.consumed) continue;
      if (kartWorldRect.overlaps(obj.worldRect)) {
        if (obj is KartStarComponent) {
          obj.consumed = true;
          obj.removeFromParent();
          game.collectStar();
          HapticFeedback.selectionClick();
        } else if (obj is KartCrateComponent) {
          obj.consumed = true;
          obj.removeFromParent();
          applyCrash();
        } else if (obj is KartBoostPadComponent) {
          obj.consumed = true;
          obj.removeFromParent();
          applyBoost(_boostDuration);
          HapticFeedback.mediumImpact();
        } else if (obj is KartQuestionBlockComponent) {
          obj.consumed = true;
          obj.removeFromParent();
          // Question = auto-correct fuer V1 (Belohnung) - spaeter Lernfrage
          applyBoost(_boostDuration * 0.6);
          game.collectStar();
          game.collectStar();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(tilt);
    // Schatten
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(2, h * 0.4),
            width: w * 0.8,
            height: h * 0.15),
        Paint()..color = Colors.black.withOpacity(0.32));
    canvas.translate(-w / 2, -h / 2);
    // Kart-Sprite
    if (_kartSprite != null) {
      _kartSprite!.render(canvas, size: Vector2(w, h));
    } else {
      // Fallback: bunter Kart-Block
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, w, h), const Radius.circular(12)),
          Paint()..color = const Color(0xFFF97316));
    }
    canvas.restore();

    // Boost-Flammen hinten
    if (boostTimer > 0) {
      final flicker = 0.7 + math.sin(game.totalTime * 30) * 0.3;
      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFF97316), Color(0xFFDC2626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(w * 0.3, h, w * 0.4, 30 * flicker));
      canvas.drawPath(
          Path()
            ..moveTo(w * 0.3, h)
            ..lineTo(w * 0.5, h + 30 * flicker)
            ..lineTo(w * 0.7, h)
            ..close(),
          paint);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// COLLECTIBLES
// ════════════════════════════════════════════════════════════════════════

class KartStarComponent extends _WorldObject {
  KartStarComponent(
      {required super.game, required super.worldX, required super.worldY});

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_starSize, _starSize);
    try {
      final img = await game.images.load(
          'assets/lumo_kart/collectibles/collectibles_obstacles_rewards_asset_001.png');
      _sprite = Sprite(img);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    final t = game.totalTime + worldX * 0.01;
    final pulse = 0.9 + math.sin(t * 3) * 0.1;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(pulse, pulse);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Glow
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.6,
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.28));

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x * 0.45,
          Paint()..color = const Color(0xFFFCD34D));
    }
    canvas.restore();
  }
}

class KartCrateComponent extends _WorldObject {
  KartCrateComponent(
      {required super.game, required super.worldX, required super.worldY});

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_crateSize, _crateSize);
    try {
      final img = await game.images.load(
          'assets/lumo_kart/collectibles/collectibles_obstacles_rewards_asset_030.png');
      _sprite = Sprite(img);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    // Schatten
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x / 2, size.y * 0.95),
            width: size.x * 0.8,
            height: 8),
        Paint()..color = Colors.black.withOpacity(0.3));
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.x, size.y),
              const Radius.circular(6)),
          Paint()..color = const Color(0xFFA16207));
    }
  }
}

class KartBoostPadComponent extends _WorldObject {
  KartBoostPadComponent(
      {required super.game, required super.worldX, required super.worldY});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_padSize, _padSize * 0.6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    final t = game.totalTime;
    final pulse = 0.7 + math.sin(t * 6 + worldX * 0.02) * 0.3;

    // Hintergrund-Glow
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-6, -6, size.x + 12, size.y + 12),
            const Radius.circular(12)),
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.25 * pulse));

    // Pad-Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFB923C).withOpacity(0.6 + pulse * 0.4),
              const Color(0xFFEA580C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)));

    // Pfeil nach oben
    final arrowPaint = Paint()..color = Colors.white.withOpacity(0.9);
    for (var i = 0; i < 2; i++) {
      final yOff = i * 14.0 + (game.totalTime * 30 % 14);
      canvas.drawPath(
          Path()
            ..moveTo(size.x / 2, size.y * 0.15 + yOff)
            ..lineTo(size.x / 2 - 14, size.y * 0.5 + yOff)
            ..lineTo(size.x / 2 + 14, size.y * 0.5 + yOff)
            ..close(),
          arrowPaint);
    }
  }
}

class KartQuestionBlockComponent extends _WorldObject {
  KartQuestionBlockComponent(
      {required super.game, required super.worldX, required super.worldY});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_qBlockSize, _qBlockSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    final t = game.totalTime;
    final pulse = 0.5 + math.sin(t * 3) * 0.5;

    // Glow-Halo
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-10, -10, size.x + 20, size.y + 20),
            const Radius.circular(16)),
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.25 + pulse * 0.15));

    // Block-Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFCD34D), Color(0xFFF59E0B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)));

    // ? Symbol
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: 36,
          color: Color(0xFF92400E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2));
  }
}

// ════════════════════════════════════════════════════════════════════════
// HUD-OVERLAY
// ════════════════════════════════════════════════════════════════════════

class _KartHud extends StatelessWidget {
  const _KartHud({required this.game});
  final LumoKartGame game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 12, 16, 0),
      child: Row(
        children: [
          // Stern-Counter
          _HudPill(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFCD34D),
            valueBuilder: () => '${game.stars}',
          ),
          const Spacer(),
          // Zeit / Distanz
          _HudPill(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF38BDF8),
            valueBuilder: () {
              final remaining = (_raceDuration - game.totalTime).clamp(0, _raceDuration);
              return '${remaining.toInt()}s';
            },
          ),
        ],
      ),
    );
  }
}

class _HudPill extends StatefulWidget {
  const _HudPill({
    required this.icon,
    required this.iconColor,
    required this.valueBuilder,
  });
  final IconData icon;
  final Color iconColor;
  final String Function() valueBuilder;

  @override
  State<_HudPill> createState() => _HudPillState();
}

class _HudPillState extends State<_HudPill> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.iconColor, size: 20),
          const SizedBox(width: 6),
          Text(
            widget.valueBuilder(),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// STEUERUNG - JOYSTICK + BOOST
// ════════════════════════════════════════════════════════════════════════

class _SteeringJoystick extends StatefulWidget {
  const _SteeringJoystick({required this.onChanged});
  final ValueChanged<Offset> onChanged;

  @override
  State<_SteeringJoystick> createState() => _SteeringJoystickState();
}

class _SteeringJoystickState extends State<_SteeringJoystick> {
  static const double _radius = 60;
  static const double _hitAreaSize = 200;
  Offset _knobOffset = Offset.zero;
  int _activePointerId = -1;
  late Offset _center;

  void _update(Offset localPos) {
    var diff = localPos - _center;
    final dist = diff.distance;
    if (dist > _radius) diff = diff * (_radius / dist);
    setState(() => _knobOffset = diff);
    widget.onChanged(Offset(diff.dx / _radius, diff.dy / _radius));
  }

  void _reset() {
    setState(() {
      _knobOffset = Offset.zero;
      _activePointerId = -1;
    });
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    _center = const Offset(_hitAreaSize / 2, _hitAreaSize / 2);
    return SizedBox(
      width: _hitAreaSize,
      height: _hitAreaSize,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (_activePointerId != -1) return;
          _activePointerId = e.pointer;
          _update(e.localPosition);
        },
        onPointerMove: (e) {
          if (e.pointer != _activePointerId) return;
          _update(e.localPosition);
        },
        onPointerUp: (e) {
          if (e.pointer != _activePointerId) return;
          _reset();
        },
        onPointerCancel: (e) {
          if (e.pointer != _activePointerId) return;
          _reset();
        },
        child: CustomPaint(
          painter: _SteeringPainter(knob: _knobOffset, center: _center),
        ),
      ),
    );
  }
}

class _SteeringPainter extends CustomPainter {
  _SteeringPainter({required this.knob, required this.center});
  final Offset knob;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    // Base
    canvas.drawCircle(center, 60,
        Paint()..color = Colors.white.withOpacity(0.18));
    canvas.drawCircle(center, 60,
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Knob
    final kc = center + knob;
    canvas.drawCircle(kc, 30,
        Paint()..color = Colors.black.withOpacity(0.3));
    canvas.drawCircle(kc, 28,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.white, Color(0xFFE5E7EB)],
          ).createShader(Rect.fromCircle(center: kc, radius: 28)));
  }

  @override
  bool shouldRepaint(covariant _SteeringPainter old) =>
      old.knob != knob || old.center != center;
}

class _BoostButton extends StatefulWidget {
  const _BoostButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<_BoostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onTap();
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFF97316), Color(0xFFDC2626)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withOpacity(0.6),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
          ),
          child: const Icon(Icons.bolt_rounded,
              color: Colors.white, size: 44),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// RESULT-DIALOG
// ════════════════════════════════════════════════════════════════════════

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.stars,
    required this.timeUsed,
    required this.onClose,
  });
  final int stars;
  final double timeUsed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁',
                style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            const Text(
              'Ziel erreicht!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF97316),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFCD34D), size: 32),
                const SizedBox(width: 6),
                Text(
                  '$stars Sterne gesammelt',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '+${stars * 8} XP',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Zurück zur Spielewelt',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
