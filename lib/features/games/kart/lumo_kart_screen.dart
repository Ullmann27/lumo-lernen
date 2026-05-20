// ════════════════════════════════════════════════════════════════════════
//                    LUMO KART ADVENTURE - Flame Game
// ════════════════════════════════════════════════════════════════════════
//
// Premium 2.5D Kart-Racer im Lumo-Universum.
//
// Phase-1-Vertical-Slice:
//   - Menue -> Countdown -> Rennen -> Ergebnis -> Zurueck
//   - Eine sichtbar gekruemmte Strecke ('Blumen-Tal-Runde')
//   - Joystick + Boost-Button
//   - Sterne, Kisten, Boost-Pads, Frageblöcke (Pause-Overlay mit Frage)
//   - Drift-Visualisierung + Staub-Partikel
//   - Screen-Shake bei Kollisionen
//   - Finite Strecke mit Ziellinie
//   - Persistente Sterne/XP via AppState (RewardWallet)
//
// Eigenes Lumo-Spiel, keine kopierten Marken-Assets.

import 'dart:async' as async;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import 'kart_models.dart';
import 'kart_question_pool.dart';
import 'kart_tuning.dart';

// ════════════════════════════════════════════════════════════════════════
// PUBLIC SCREEN
// ════════════════════════════════════════════════════════════════════════

class LumoKartScreen extends StatefulWidget {
  const LumoKartScreen({
    super.key,
    required this.appState,
    this.driver = KartCatalog.lumoDriver,
    this.vehicle = KartCatalog.starterKart,
    this.track = KartCatalog.meadowLap,
  });

  final LumoAppState appState;
  final KartDriverModel driver;
  final KartVehicleModel vehicle;
  final KartTrackModel track;

  @override
  State<LumoKartScreen> createState() => _LumoKartScreenState();
}

class _LumoKartScreenState extends State<LumoKartScreen> {
  late final LumoKartGame _game;
  bool _paused = false;
  bool _showingQuestion = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _game = LumoKartGame(
      driver: widget.driver,
      vehicle: widget.vehicle,
      track: widget.track,
      onFinish: _onFinish,
      onStar: _onStar,
      onQuestion: _onQuestion,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _onStar(int total) {
    if (!_disposed && mounted) setState(() {});
  }

  Future<bool> _onQuestion() async {
    if (!mounted || _showingQuestion) return false;
    _showingQuestion = true;
    _game.pauseEngine();
    final question = KartQuestionPool.random();
    final correct = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MiniQuestionDialog(question: question),
    );
    _showingQuestion = false;
    if (!mounted) return false;
    if (!_paused) _game.resumeEngine();
    return correct ?? false;
  }

  void _onFinish(int stars, double timeUsed) {
    if (!mounted) return;
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 8);

    _game.pauseEngine();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        stars: stars,
        timeUsed: timeUsed,
        onRetry: () {
          Navigator.of(context).pop();
          _restart();
        },
        onClose: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
          if (nav.canPop()) nav.pop();
        },
      ),
    );
  }

  void _restart() {
    setState(() {
      _game.restart();
      _paused = false;
    });
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Stack(
        children: [
          GameWidget<LumoKartGame>(game: _game),
          // HUD oben
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _KartHud(game: _game)),
          ),
          // Steuerung links
          Positioned(
            left: 24,
            bottom: 28,
            child: _SteeringJoystick(
              onChanged: (vec) => _game.setSteering(vec.dx),
            ),
          ),
          // Boost rechts
          Positioned(
            right: 24,
            bottom: 36,
            child: _BoostButton(onTap: _game.triggerBoost),
          ),
          // Zurueck oben links
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30),
                tooltip: 'Schliessen',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Pause oben rechts
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  _paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                tooltip: _paused ? 'Weiter' : 'Pause',
                onPressed: _togglePause,
              ),
            ),
          ),
          // Pause-Overlay
          if (_paused)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePause,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  alignment: Alignment.center,
                  child: const Text(
                    'Pause - antippen um weiterzufahren',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
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
  LumoKartGame({
    this.driver = KartCatalog.lumoDriver,
    this.vehicle = KartCatalog.starterKart,
    this.track = KartCatalog.meadowLap,
    required this.onFinish,
    required this.onStar,
    this.onQuestion,
  }) {
    // Wichtig: kart MUSS im Konstruktor existieren, damit das Flutter-UI
    // sicher darauf zugreifen kann, bevor onLoad() async fertig ist.
    kart = KartPlayerComponent(game: this);
  }

  final KartDriverModel driver;
  final KartVehicleModel vehicle;
  final KartTrackModel track;

  final void Function(int stars, double timeUsed) onFinish;
  final void Function(int starsTotal) onStar;

  /// Optionaler Async-Callback: Wenn das Kart einen Frageblock trifft,
  /// wird das UI nach einer Antwort gefragt. true = richtig.
  final Future<bool> Function()? onQuestion;

  late final KartPlayerComponent kart;
  double totalTime = 0;
  int stars = 0;
  int boostsUsed = 0;
  bool finished = false;
  bool questionLock = false;
  double countdownTimer = 3.0;
  double shakeAmplitude = 0.0;

  double _spawnedUpTo = 0;
  math.Random _rng = math.Random(42);

  bool get isCountingDown => countdownTimer > 0;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = '';

    add(_KartTrackBackdrop(game: this)..priority = -100);
    await add(kart);
    _populateAhead(900);
    add(_FinishLineComponent(game: this)..priority = -50);
  }

  void setSteering(double x) {
    if (isCountingDown || finished || questionLock) {
      kart.stickX = 0;
      return;
    }
    kart.stickX = x.clamp(-1.0, 1.0).toDouble();
  }

  void triggerBoost() {
    if (isCountingDown || finished || questionLock) return;
    kart.tryManualBoost();
  }

  void restart() {
    finished = false;
    questionLock = false;
    totalTime = 0;
    stars = 0;
    boostsUsed = 0;
    countdownTimer = 3.0;
    shakeAmplitude = 0;
    _spawnedUpTo = 0;
    _rng = math.Random(42);

    // Alte Welt-Objekte entfernen
    for (final c in children.whereType<_WorldObject>().toList()) {
      c.removeFromParent();
    }
    // Partikel entfernen
    for (final c in children.whereType<_DustParticle>().toList()) {
      c.removeFromParent();
    }
    // Finish-Line entfernen
    for (final c in children.whereType<_FinishLineComponent>().toList()) {
      c.removeFromParent();
    }

    kart.resetForRestart();
    _populateAhead(900);
    add(_FinishLineComponent(game: this)..priority = -50);
    resumeEngine();
    onStar(0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (finished) return;

    if (countdownTimer > 0) {
      countdownTimer -= dt;
      // Waehrend Countdown: nichts updaten ausser visueller Kart
      return;
    }

    totalTime += dt;

    // Spawn nach
    if (kart.traveled > _spawnedUpTo - 700) {
      _populateAhead(700);
    }

    // Aufraeumen
    for (final c in children.whereType<_WorldObject>().toList()) {
      if (c.worldY < kart.traveled - 500) {
        c.removeFromParent();
      }
    }

    // Screen-Shake abklingen
    if (shakeAmplitude > 0) {
      shakeAmplitude = math.max(
          0, shakeAmplitude - KartTuning.crashShakeDecay * dt * 2);
    }

    // Ziel erreicht?
    if (!finished && kart.traveled >= KartTuning.finishDistance) {
      finished = true;
      kart.stickX = 0;
      onFinish(stars, totalTime);
    }
  }

  void _populateAhead(double distance) {
    final startY = math.max(_spawnedUpTo + 140.0, 320.0);
    final endY = math.min(
      _spawnedUpTo + distance,
      KartTuning.finishDistance - 200,
    );
    var y = startY;
    while (y < endY) {
      final pick = _rng.nextDouble();
      if (pick < 0.45) {
        final lane = _rng.nextInt(3);
        add(KartStarComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      } else if (pick < 0.62) {
        final lane = _rng.nextInt(3);
        add(KartCrateComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      } else if (pick < 0.78) {
        final lane = _rng.nextInt(3);
        add(KartBoostPadComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      } else if (pick < 0.88) {
        final lane = _rng.nextInt(3);
        add(KartQuestionBlockComponent(
            game: this, worldX: _laneToX(lane), worldY: y));
      }
      y += 130 + _rng.nextDouble() * 90;
    }
    _spawnedUpTo = endY;
  }

  double _laneToX(int lane) {
    final laneW = KartTuning.trackWidth / 3;
    return -KartTuning.trackWidth / 2 + laneW * (lane + 0.5);
  }

  /// Visueller seitlicher Versatz der gesamten Strecke an Welt-Y.
  /// Erzeugt die Kurvenillusion (Blumen-Tal-Runde schwingt sanft).
  double trackSwayAt(double worldY) {
    return math.sin(worldY / KartTuning.trackSwayWavelength * math.pi * 2) *
        KartTuning.trackWidth *
        KartTuning.trackSwayAmplitude;
  }

  void collectStar() {
    stars++;
    onStar(stars);
  }

  void triggerShake([double? amplitude]) {
    final amp = amplitude ?? KartTuning.crashShakeAmplitude;
    if (amp > shakeAmplitude) shakeAmplitude = amp;
  }

  Future<void> handleQuestionHit() async {
    if (questionLock || onQuestion == null) return;
    questionLock = true;
    final correct = await onQuestion!.call();
    questionLock = false;
    if (correct) {
      kart.applyBoost(KartTuning.boostPadDuration);
      stars += 2;
      onStar(stars);
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  double get shakeX => shakeAmplitude == 0
      ? 0
      : math.sin(totalTime * 50) * shakeAmplitude;
  double get shakeY => shakeAmplitude == 0
      ? 0
      : math.cos(totalTime * 47) * shakeAmplitude;

  double worldToScreenY(double worldY) =>
      (size.y * 0.75) - (worldY - kart.traveled) + shakeY;

  double worldToScreenX(double worldX, double worldY) =>
      size.x / 2 + worldX + trackSwayAt(worldY) + shakeX;
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

  bool get isActive => !consumed;

  Rect get worldRect => Rect.fromCenter(
      center: Offset(worldX, worldY),
      width: size.x,
      height: size.y);
}

// ════════════════════════════════════════════════════════════════════════
// KART PLAYER
// ════════════════════════════════════════════════════════════════════════

class KartPlayerComponent extends PositionComponent {
  KartPlayerComponent({required this.game})
      : super(
          size: Vector2(KartTuning.kartWidth, KartTuning.kartHeight),
          anchor: Anchor.center,
        );

  final LumoKartGame game;

  Sprite? _kartSprite;
  double speed = 0;
  double laneX = 0;
  double stickX = 0;
  double traveled = 0;
  double boostTimer = 0;
  double crashTimer = 0;
  double manualBoostCooldown = 0;
  double tilt = 0;
  double wheelAngle = 0;
  double driftTimer = 0;

  bool get isDrifting => driftTimer > 0;

  void resetForRestart() {
    speed = 0;
    laneX = 0;
    stickX = 0;
    traveled = 0;
    boostTimer = 0;
    crashTimer = 0;
    manualBoostCooldown = 0;
    tilt = 0;
    wheelAngle = 0;
    driftTimer = 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final img = await game.images.load(game.vehicle.spriteAsset);
      _kartSprite = Sprite(img);
    } catch (_) {
      _kartSprite = null;
    }
  }

  void tryManualBoost() {
    if (boostTimer <= 0 && crashTimer <= 0 && manualBoostCooldown <= 0) {
      boostTimer = KartTuning.manualBoostDuration;
      manualBoostCooldown = KartTuning.manualBoostCooldown;
      HapticFeedback.mediumImpact();
      game.boostsUsed++;
    }
  }

  void applyBoost(double duration) {
    boostTimer = math.max(boostTimer, duration);
  }

  void applyCrash() {
    crashTimer = KartTuning.crashDuration;
    HapticFeedback.heavyImpact();
    game.triggerShake();
    // Speed sofort reduzieren damit Spieler den Crash spuert
    speed *= KartTuning.crashSlowdown;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isCountingDown) {
      // Nur Position aktualisieren, nicht fahren
      _updateScreenPosition();
      return;
    }
    if (game.finished) {
      // Sanft ausrollen
      speed = math.max(0, speed - KartTuning.brakeForce * 0.6 * dt);
      traveled += speed * dt;
      _updateScreenPosition();
      return;
    }

    // ── Speed-Ziel ──
    final boosted = boostTimer > 0;
    final crashed = crashTimer > 0;
    final targetMax = (boosted
            ? KartTuning.maxSpeed * KartTuning.boostMultiplier
            : KartTuning.maxSpeed) *
        (crashed ? KartTuning.crashSlowdown : 1.0);

    if (speed < targetMax) {
      speed = math.min(targetMax, speed + KartTuning.acceleration * dt);
    } else {
      // ueber Ziel -> sanft daempfen
      speed = math.max(
          targetMax, speed - KartTuning.friction * dt);
    }

    traveled += speed * dt;

    // ── Lenken (geschwindigkeitsabhaengig) ──
    final inputX = stickX.abs() > 0.05 ? stickX.clamp(-1.0, 1.0) : 0.0;
    final speedFactor = (speed / KartTuning.maxSpeed).clamp(0.0, 1.0);
    final turnFactor =
        KartTuning.minTurnFactor + (1 - KartTuning.minTurnFactor) * speedFactor;
    laneX = (laneX + inputX * KartTuning.turnRate * turnFactor * dt)
        .clamp(-KartTuning.laneClamp, KartTuning.laneClamp);

    // ── Drift-Erkennung ──
    final driftCandidate = inputX.abs() > KartTuning.driftThreshold &&
        speedFactor > KartTuning.driftMinSpeedFactor &&
        crashTimer <= 0;
    if (driftCandidate) {
      driftTimer = math.min(driftTimer + dt, 2.5);
      _spawnDust(inputX);
    } else {
      driftTimer = math.max(0, driftTimer - dt * 3);
    }

    // ── Tilt-Animation ──
    final driftBonus = isDrifting ? KartTuning.driftTiltBonus : 0.0;
    final targetTilt = inputX * (KartTuning.tiltStrength + driftBonus);
    tilt = tilt * KartTuning.tiltDamping +
        targetTilt * (1 - KartTuning.tiltDamping);

    // ── Timer ──
    if (boostTimer > 0) boostTimer -= dt;
    if (crashTimer > 0) crashTimer -= dt;
    if (manualBoostCooldown > 0) manualBoostCooldown -= dt;

    wheelAngle += speed * dt * 0.025;
    if (wheelAngle > math.pi * 2) wheelAngle -= math.pi * 2;

    _updateScreenPosition();
    _checkCollisions();
  }

  void _updateScreenPosition() {
    position.x = game.size.x / 2 +
        laneX * (KartTuning.trackWidth / 2) +
        game.shakeX;
    position.y = game.size.y * 0.75 + game.shakeY;
  }

  void _spawnDust(double inputX) {
    if (!game.children.contains(this)) return;
    // Maximal 14 aktive Staubpartikel - Performance
    final existing = game.children.whereType<_DustParticle>().length;
    if (existing > 14) return;
    final side = inputX > 0 ? 1.0 : -1.0;
    game.add(_DustParticle(
      startX: position.x + side * KartTuning.kartWidth * 0.18,
      startY: position.y + KartTuning.kartHeight * 0.30,
      driftSide: side,
    ));
  }

  void _checkCollisions() {
    final kartWorldRect = Rect.fromCenter(
      center: Offset(laneX * (KartTuning.trackWidth / 2), traveled),
      width: KartTuning.kartWidth * 0.65,
      height: KartTuning.kartHeight * 0.65,
    );
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
          applyBoost(KartTuning.boostPadDuration);
          HapticFeedback.mediumImpact();
        } else if (obj is KartQuestionBlockComponent) {
          obj.consumed = true;
          obj.removeFromParent();
          // Nicht-blockierend; das Flutter-UI uebernimmt
          game.handleQuestionHit();
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
        center: Offset(2, h * 0.4),
        width: w * 0.8,
        height: h * 0.18,
      ),
      Paint()..color = Colors.black.withOpacity(0.32),
    );
    canvas.translate(-w / 2, -h / 2);
    if (_kartSprite != null) {
      _kartSprite!.render(canvas, size: Vector2(w, h));
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h), const Radius.circular(14)),
        Paint()..color = const Color(0xFFF97316),
      );
    }
    canvas.restore();

    _renderWheels(canvas, w, h);
    _renderSpeedLines(canvas, w, h);
    _renderBoostFlame(canvas, w, h);
  }

  void _renderWheels(Canvas canvas, double w, double h) {
    final wheelOffsetsY = [h * 0.92, h * 0.42];
    final wheelOffsetsX = [w * 0.15, w * 0.85];
    for (int row = 0; row < wheelOffsetsY.length; row++) {
      final radius = row == 0 ? w * 0.13 : w * 0.10;
      for (int col = 0; col < wheelOffsetsX.length; col++) {
        final cx = wheelOffsetsX[col];
        final cy = wheelOffsetsY[row];
        canvas.drawCircle(Offset(cx, cy), radius,
            Paint()..color = const Color(0xFF1F2937));
        canvas.drawCircle(Offset(cx, cy), radius * 0.65,
            Paint()..color = const Color(0xFFD1D5DB));
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(wheelAngle);
        for (int s = 0; s < 3; s++) {
          canvas.rotate(math.pi * 2 / 3);
          canvas.drawLine(
            Offset.zero,
            Offset(radius * 0.55, 0),
            Paint()
              ..color = const Color(0xFF6B7280)
              ..strokeWidth = radius * 0.18,
          );
        }
        canvas.drawCircle(Offset.zero, radius * 0.18,
            Paint()..color = const Color(0xFF374151));
        canvas.restore();
      }
    }
  }

  void _renderSpeedLines(Canvas canvas, double w, double h) {
    final speedRatio = (speed / KartTuning.maxSpeed).clamp(0.0, 1.5);
    if (speedRatio <= 0.4) return;
    final alpha = ((speedRatio - 0.4) * 1.4).clamp(0.0, 0.7);
    final p = Paint()..color = Colors.white.withOpacity(alpha);
    for (int i = 0; i < 4; i++) {
      final offsetY = (game.totalTime * 260 + i * 18) % 40;
      final stripeY = h * 0.10 + offsetY;
      canvas.drawRect(
          Rect.fromLTWH(-w * 0.25, stripeY, w * 0.18, 2.5), p);
      canvas.drawRect(
          Rect.fromLTWH(w + w * 0.07, stripeY, w * 0.18, 2.5), p);
    }
  }

  void _renderBoostFlame(Canvas canvas, double w, double h) {
    if (boostTimer <= 0) return;
    final flicker = 0.7 + math.sin(game.totalTime * 30) * 0.3;
    final rect = Rect.fromLTWH(w * 0.3, h, w * 0.4, 30 * flicker);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFF97316), Color(0xFFDC2626)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, h)
        ..lineTo(w * 0.5, h + 30 * flicker)
        ..lineTo(w * 0.7, h)
        ..close(),
      paint,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COLLECTIBLES
// ════════════════════════════════════════════════════════════════════════

class KartStarComponent extends _WorldObject {
  KartStarComponent({
    required super.game,
    required super.worldX,
    required super.worldY,
  });

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(KartTuning.starSize, KartTuning.starSize);
    try {
      final img = await game.images.load(
          'assets/lumo_kart/collectibles/collectibles_obstacles_rewards_asset_001.png');
      _sprite = Sprite(img);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX, worldY) - size.x / 2;
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
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.6,
      Paint()..color = const Color(0xFFFCD34D).withOpacity(0.32),
    );
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.45,
        Paint()..color = const Color(0xFFFCD34D),
      );
    }
    canvas.restore();
  }
}

class KartCrateComponent extends _WorldObject {
  KartCrateComponent({
    required super.game,
    required super.worldX,
    required super.worldY,
  });

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(KartTuning.crateSize, KartTuning.crateSize);
    try {
      final img = await game.images.load(
          'assets/lumo_kart/collectibles/collectibles_obstacles_rewards_asset_030.png');
      _sprite = Sprite(img);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX, worldY) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y * 0.95),
        width: size.x * 0.8,
        height: 8,
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y),
            const Radius.circular(8)),
        Paint()..color = const Color(0xFFA16207),
      );
    }
  }
}

class KartBoostPadComponent extends _WorldObject {
  KartBoostPadComponent({
    required super.game,
    required super.worldX,
    required super.worldY,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(KartTuning.boostPadSize, KartTuning.boostPadSize * 0.55);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX, worldY) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.7 + math.sin(game.totalTime * 6 + worldX * 0.02) * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-6, -6, size.x + 12, size.y + 12),
          const Radius.circular(12)),
      Paint()..color = const Color(0xFFFCD34D).withOpacity(0.25 * pulse),
    );
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
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );
    final arrowPaint = Paint()..color = Colors.white.withOpacity(0.9);
    for (var i = 0; i < 2; i++) {
      final yOff = i * 14.0 + (game.totalTime * 30 % 14);
      canvas.drawPath(
        Path()
          ..moveTo(size.x / 2, size.y * 0.15 + yOff)
          ..lineTo(size.x / 2 - 14, size.y * 0.5 + yOff)
          ..lineTo(size.x / 2 + 14, size.y * 0.5 + yOff)
          ..close(),
        arrowPaint,
      );
    }
  }
}

class KartQuestionBlockComponent extends _WorldObject {
  KartQuestionBlockComponent({
    required super.game,
    required super.worldX,
    required super.worldY,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(KartTuning.questionBlockSize, KartTuning.questionBlockSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = game.worldToScreenX(worldX, worldY) - size.x / 2;
    position.y = game.worldToScreenY(worldY) - size.y / 2;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.5 + math.sin(game.totalTime * 3) * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-10, -10, size.x + 20, size.y + 20),
          const Radius.circular(16)),
      Paint()
        ..color = const Color(0xFFFCD34D).withOpacity(0.25 + pulse * 0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFCD34D), Color(0xFFF59E0B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );
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
// DUST-PARTIKEL
// ════════════════════════════════════════════════════════════════════════

class _DustParticle extends PositionComponent {
  _DustParticle({
    required this.startX,
    required this.startY,
    required this.driftSide,
  }) : super(size: Vector2(28, 28));

  final double startX;
  final double startY;
  final double driftSide;
  double life = 0;
  static const double maxLife = 0.45;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position.x = startX - size.x / 2;
    position.y = startY - size.y / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    life += dt;
    if (life >= maxLife) {
      removeFromParent();
      return;
    }
    position.x += driftSide * 40 * dt;
    position.y += 20 * dt;
  }

  @override
  void render(Canvas canvas) {
    final t = (life / maxLife).clamp(0.0, 1.0);
    final radius = 6 + 10 * t;
    final alpha = (1 - t) * 0.45;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius,
      Paint()..color = const Color(0xFFD6CFA3).withOpacity(alpha),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// FINISH-LINIE
// ════════════════════════════════════════════════════════════════════════

class _FinishLineComponent extends Component
    with HasGameReference<LumoKartGame> {
  _FinishLineComponent({required this.game});
  @override
  final LumoKartGame game;

  @override
  void render(Canvas canvas) {
    final worldY = KartTuning.finishDistance;
    final screenY = game.worldToScreenY(worldY);
    // Wenn Ziel ausserhalb des Bildschirms ist, nichts zeichnen
    if (screenY < -120 || screenY > game.size.y + 120) return;

    final centerX = game.size.x / 2 + game.trackSwayAt(worldY) + game.shakeX;
    final halfW = KartTuning.trackWidth / 2 + 24;
    final stripeHeight = 24.0;

    // Schachbrett-Muster
    const cells = 10;
    final cellW = halfW * 2 / cells;
    for (int i = 0; i < cells; i++) {
      final color =
          i % 2 == 0 ? const Color(0xFF1F2937) : const Color(0xFFFAFAFA);
      canvas.drawRect(
        Rect.fromLTWH(
          centerX - halfW + i * cellW,
          screenY - stripeHeight / 2,
          cellW,
          stripeHeight,
        ),
        Paint()..color = color,
      );
    }

    // Banner ueber der Linie
    final bannerY = screenY - 60;
    final bannerRect = Rect.fromCenter(
      center: Offset(centerX, bannerY),
      width: 220,
      height: 36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bannerRect, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFDC2626)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bannerRect),
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'ZIEL',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.white,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(centerX - tp.width / 2, bannerY - tp.height / 2));
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
      padding: const EdgeInsets.fromLTRB(60, 12, 60, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _HudPill(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFCD34D),
                valueBuilder: () => '${game.stars}',
              ),
              const SizedBox(width: 8),
              _HudPill(
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFFEF4444),
                valueBuilder: () => '${(game.kart.speed * 0.3).toInt()} km/h',
              ),
              const Spacer(),
              _HudPill(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFF38BDF8),
                valueBuilder: () {
                  final pct = (game.kart.traveled / KartTuning.finishDistance)
                      .clamp(0.0, 1.0);
                  return '${(pct * 100).toInt()}%';
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(game: game),
          const SizedBox(height: 6),
          _CountdownOverlay(game: game),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.game});
  final LumoKartGame game;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  late final async.Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = async.Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    final pct =
        (widget.game.kart.traveled / KartTuning.finishDistance).clamp(0.0, 1.0);
    final boosting = widget.game.kart.boostTimer > 0;
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(boosting ? 0.7 : 0.3),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Stack(children: [
        FractionallySizedBox(
          widthFactor: pct,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pct < 0.5
                    ? const [Color(0xFF34D399), Color(0xFFFBBF24)]
                    : const [Color(0xFFFBBF24), Color(0xFFEF4444)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: boosting
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.6),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ]),
    );
  }
}

class _CountdownOverlay extends StatefulWidget {
  const _CountdownOverlay({required this.game});
  final LumoKartGame game;

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay> {
  late final async.Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = async.Timer.periodic(const Duration(milliseconds: 80), (_) {
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
    final t = widget.game.countdownTimer;
    if (t <= 0) return const SizedBox.shrink();
    final label = t > 2
        ? '3'
        : t > 1
            ? '2'
            : t > 0
                ? '1'
                : 'LOS!';
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            label,
            key: ValueKey(label),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
          ),
        ),
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
  late final async.Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = async.Timer.periodic(const Duration(milliseconds: 200), (_) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            widget.valueBuilder(),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 15,
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
    canvas.drawCircle(center, 60,
        Paint()..color = Colors.white.withOpacity(0.18));
    canvas.drawCircle(
      center,
      60,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final kc = center + knob;
    canvas.drawCircle(kc, 30,
        Paint()..color = Colors.black.withOpacity(0.3));
    canvas.drawCircle(
      kc,
      28,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFE5E7EB)],
        ).createShader(Rect.fromCircle(center: kc, radius: 28)),
    );
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
          width: 92,
          height: 92,
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
              color: Colors.white, size: 46),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// FRAGE-DIALOG
// ════════════════════════════════════════════════════════════════════════

class _MiniQuestionDialog extends StatefulWidget {
  const _MiniQuestionDialog({required this.question});
  final KartMiniQuestion question;

  @override
  State<_MiniQuestionDialog> createState() => _MiniQuestionDialogState();
}

class _MiniQuestionDialogState extends State<_MiniQuestionDialog> {
  int? _picked;
  bool _resolved = false;

  void _pick(int i) async {
    if (_resolved) return;
    setState(() {
      _picked = i;
      _resolved = true;
    });
    final correct = i == widget.question.correctIndex;
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    Navigator.of(context).pop(correct);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Dialog(
      backgroundColor: const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Lernfrage',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              q.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: List<Widget>.generate(q.options.length, (i) {
                final isPicked = _picked == i;
                final isCorrect = i == q.correctIndex;
                Color bg = Colors.white;
                Color border = const Color(0xFFE5E7EB);
                if (_resolved) {
                  if (isCorrect) {
                    bg = const Color(0xFFD1FAE5);
                    border = const Color(0xFF10B981);
                  } else if (isPicked) {
                    bg = const Color(0xFFFEE2E2);
                    border = const Color(0xFFF87171);
                  }
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resolved ? null : () => _pick(i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bg,
                        disabledBackgroundColor: bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: border, width: 1.6),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        q.options[i],
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_resolved) ...[
              const SizedBox(height: 10),
              Text(
                _picked == q.correctIndex
                    ? 'Super! +2 Sterne und Boost!'
                    : (q.hint ?? 'Beim naechsten Mal wieder probieren.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _picked == q.correctIndex
                      ? const Color(0xFF065F46)
                      : const Color(0xFF7C2D12),
                ),
              ),
            ],
          ],
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
    required this.onRetry,
    required this.onClose,
  });
  final int stars;
  final double timeUsed;
  final VoidCallback onRetry;
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
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFCD34D), size: 64),
            const SizedBox(height: 6),
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
              '+${stars * 8} XP   ${timeUsed.toStringAsFixed(1)} s',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFF97316), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Nochmal',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Zurueck',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 2.5D-BACKDROP (Wiesen-Theme)
// ════════════════════════════════════════════════════════════════════════

class _KartTrackBackdrop extends Component
    with HasGameReference<LumoKartGame> {
  _KartTrackBackdrop({required this.game});
  @override
  final LumoKartGame game;

  static const double _horizonFrac = 0.38;

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final horizonY = h * _horizonFrac;
    final cameraY = game.kart.traveled;

    // 1. Himmel
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizonY),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7FB9E0), Color(0xFFB9DCEF), Color(0xFFFEF3C7)],
          stops: [0.0, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, horizonY)),
    );

    // 2. Sonne
    final sunX = w * 0.82;
    final sunY = horizonY * 0.38;
    final sunR = math.min(w, h) * 0.058;
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR * 2.2,
      Paint()
        ..color = const Color(0xFFFEF08A).withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR * 1.4,
      Paint()
        ..color = const Color(0xFFFCD34D).withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(Offset(sunX, sunY), sunR,
        Paint()..color = const Color(0xFFFEF3C7));

    // 3. Wolken
    final cloudShift = (cameraY * 0.05) % (w * 1.4);
    _drawCloud(canvas, w * 0.15 - cloudShift, horizonY * 0.32, w * 0.10);
    _drawCloud(canvas, w * 0.55 - cloudShift, horizonY * 0.20, w * 0.13);
    _drawCloud(canvas, w * 0.95 - cloudShift, horizonY * 0.42, w * 0.08);
    _drawCloud(
        canvas, w * 0.30 - cloudShift + w * 1.4, horizonY * 0.28, w * 0.11);

    // 4. Ferne Huegel
    final farHillShift = (cameraY * 0.1) % (w * 0.4);
    final farHillPath = Path()..moveTo(-farHillShift, horizonY);
    final farPeaks = (w / (w * 0.4)).ceil() + 2;
    for (int i = 0; i < farPeaks; i++) {
      final px = i * (w * 0.4) - farHillShift;
      farHillPath
        ..lineTo(px + w * 0.10, horizonY - h * 0.040)
        ..lineTo(px + w * 0.20, horizonY - h * 0.015)
        ..lineTo(px + w * 0.30, horizonY - h * 0.055)
        ..lineTo(px + w * 0.40, horizonY);
    }
    farHillPath.close();
    canvas.drawPath(
        farHillPath, Paint()..color = const Color(0xFF93C5FD));

    // 5. Nahe Huegel
    final nearHillShift = (cameraY * 0.18) % (w * 0.5);
    final nearHillPath = Path()..moveTo(-nearHillShift, horizonY);
    final nearPeaks = (w / (w * 0.5)).ceil() + 2;
    for (int i = 0; i < nearPeaks; i++) {
      final px = i * (w * 0.5) - nearHillShift;
      nearHillPath
        ..quadraticBezierTo(
          px + w * 0.12, horizonY - h * 0.055,
          px + w * 0.25, horizonY - h * 0.020,
        )
        ..quadraticBezierTo(
          px + w * 0.37, horizonY - h * 0.075,
          px + w * 0.50, horizonY,
        );
    }
    nearHillPath.close();
    canvas.drawPath(
        nearHillPath, Paint()..color = const Color(0xFF65A30D));

    // 6. Boden (Trapez)
    final groundTopY = horizonY;
    final groundBottomY = h;
    final groundTopHalfW = w * 0.40;
    final groundBottomHalfW = w * 1.05;
    final groundPath = Path()
      ..moveTo(w / 2 - groundTopHalfW, groundTopY)
      ..lineTo(w / 2 + groundTopHalfW, groundTopY)
      ..lineTo(w / 2 + groundBottomHalfW, groundBottomY)
      ..lineTo(w / 2 - groundBottomHalfW, groundBottomY)
      ..close();
    canvas.drawPath(
      groundPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF86EFAC), Color(0xFF65A30D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
            Rect.fromLTWH(0, groundTopY, w, groundBottomY - groundTopY)),
    );

    // 7. Streifen
    const stripeSpacing = 60.0;
    final scroll = cameraY % stripeSpacing;
    for (int i = 0; i < 12; i++) {
      final worldDist = i * stripeSpacing - scroll;
      if (worldDist < 0) continue;
      final t = (worldDist / 700).clamp(0.0, 1.0);
      final perspectiveT = 1.0 - math.pow(1.0 - t, 1.6) as double;
      final stripeY =
          groundBottomY - perspectiveT * (groundBottomY - groundTopY);
      final stripeH = math.max(2.0, 14.0 * (1.0 - perspectiveT) + 1.5);
      final halfW = groundBottomHalfW +
          (groundTopHalfW - groundBottomHalfW) * perspectiveT;
      final isDark = (i + (cameraY ~/ stripeSpacing)) % 2 == 0;
      final color =
          isDark ? const Color(0xFF59A20E) : const Color(0xFF7CBE38);
      canvas.drawRect(
        Rect.fromLTWH(w / 2 - halfW, stripeY, halfW * 2, stripeH),
        Paint()..color = color,
      );
    }

    // 8. Banden
    _drawSideBarrier(
        canvas, w, h, horizonY, groundTopHalfW, groundBottomHalfW, true);
    _drawSideBarrier(
        canvas, w, h, horizonY, groundTopHalfW, groundBottomHalfW, false);
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double r) {
    final p = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.92);
    canvas.drawCircle(Offset(cx, cy), r * 0.7, p);
    canvas.drawCircle(Offset(cx + r * 0.6, cy + r * 0.1), r * 0.85, p);
    canvas.drawCircle(Offset(cx + r * 1.3, cy + r * 0.05), r * 0.75, p);
    canvas.drawCircle(Offset(cx + r * 1.85, cy + r * 0.15), r * 0.55, p);
  }

  void _drawSideBarrier(
    Canvas canvas,
    double w,
    double h,
    double horizonY,
    double topHalfW,
    double bottomHalfW,
    bool leftSide,
  ) {
    final cameraY = game.kart.traveled;
    final sign = leftSide ? -1.0 : 1.0;
    final topInner = w / 2 + sign * topHalfW;
    final topOuter = topInner + sign * w * 0.030;
    final bottomInner = w / 2 + sign * bottomHalfW;
    final bottomOuter = bottomInner + sign * w * 0.060;
    final barrierPath = Path()
      ..moveTo(topInner, horizonY)
      ..lineTo(topOuter, horizonY)
      ..lineTo(bottomOuter, h)
      ..lineTo(bottomInner, h)
      ..close();
    canvas.drawPath(
        barrierPath, Paint()..color = const Color(0xFFFFFFFF));
    canvas.save();
    canvas.clipPath(barrierPath);
    const stripeSpacing = 50.0;
    final scroll = cameraY % stripeSpacing;
    for (int i = 0; i < 14; i++) {
      final worldDist = i * stripeSpacing - scroll;
      if (worldDist < 0) continue;
      final t = (worldDist / 700).clamp(0.0, 1.0);
      final perspectiveT = 1.0 - math.pow(1.0 - t, 1.6) as double;
      final stripeY = h - perspectiveT * (h - horizonY);
      final stripeH = math.max(3.0, 18.0 * (1.0 - perspectiveT) + 2.0);
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, stripeY, w, stripeH),
          Paint()..color = const Color(0xFFDC2626),
        );
      }
    }
    canvas.restore();
    canvas.drawPath(
      barrierPath,
      Paint()
        ..color = const Color(0xFF1F2937)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }
}
