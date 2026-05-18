// lib/features/games/flame/lumo_jump_game.dart
//
// Lumo Jump Adventure – Flame 1.18 Edition
//
// Architektur:
//  • LumoFlameJumpGame extends FlameGame
//  • FoxPlayerComponent extends SpriteAnimationGroupComponent<FoxAnimationState>
//  • StarCoinComponent extends SpriteAnimationComponent
//  • ReactiveCrateComponent  – idle / wobble / broken
//  • BossChestComponent      – closed / opening / openGlow
//  • JumpPadComponent        – idle / compress / release
//  • LumoParallaxBackground  – 3 prozedural gezeichnete Ebenen
//  • PlatformTileComponent, QuestionBlockComponent, NormalObstacleComponent
//  • LumoJumpFlameScreen     – Flutter-Wrapper mit HUD + Steuerbuttons

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../core/german_task_templates.dart';
import '../../../core/math_task_templates.dart';
import '../../../domain/games/game_level_model.dart';
import '../mini_games/fox_sprite.dart';

// ── Enums ─────────────────────────────────────────────────────────────

enum CrateState { idle, wobble, broken }

enum ChestState { closed, opening, openGlow }

enum JumpPadState { idle, compress }

// ── Physik-Konstanten (abgestimmt auf das bestehende Spiel) ───────────

// ── Physik-Konstanten (Lumo-Bewegungsgefuehl) ───────────────────────
// Tuning fuer fluessigeres Mario-Style-Plattformer-Gefuehl:
// - Etwas schneller, hoehere Spruenge, groessere Coyote-Time
const double _gravity       = 1700;
const double _jumpPower     = 830;
const double _baseSpeed     = 270;
const double _duckSpeed     = 190;
const double _rollSpeedMult = 1.9;
const double _rollDuration  = 0.65;
/// Coyote-Time: wie lange Lumo nach Verlassen einer Plattform noch springen darf.
/// Groesser = flexibler/forgiving.
const double _coyoteWindow  = 0.28;
/// Jump-Buffer: wie lange ein zu frueh gedrueckter Sprung-Knopf erinnert wird.
const double _jumpBufferWin = 0.24;
const double _fallThreshold = 80;
const double _jumpPadBoost  = 1.55;
const double _baseGroundY   = 330.0;
const double _fallResetY    = 700.0;
const double _starRadius    = 22.0;
const double _maxSafeGap    = _baseSpeed * (_jumpPower / _gravity) * 2 * 0.82;

// ── Transparenz-Sprite-Hilfe ──────────────────────────────────────────
// Erstellt eine 1-Frame transparente SpriteAnimation als Platzhalter für
// SpriteAnimationGroupComponent und SpriteAnimationComponent-Subklassen,
// die render() komplett selbst überschreiben.
Future<SpriteAnimation> _createPlaceholderAnim() async {
  final rec = ui.PictureRecorder();
  Canvas(rec, const Rect.fromLTWH(0, 0, 2, 2))
      .drawRect(const Rect.fromLTWH(0, 0, 2, 2),
          Paint()..color = const Color(0x00000000));
  final img = await rec.endRecording().toImage(2, 2);
  return SpriteAnimation.spriteList([Sprite(img)], stepTime: 1.0);
}

// ════════════════════════════════════════════════════════════════════════
// HAUPTSPIEL – FlameGame
// ════════════════════════════════════════════════════════════════════════

class LumoFlameJumpGame extends FlameGame {
  LumoFlameJumpGame({
    required this.appState,
    required this.level,
    required this.onQuestionNeeded,
    required this.onChestChallenge,
    required this.onLevelComplete,
  });

  final LumoAppState appState;
  final GameLevel level;

  // Callbacks zu Flutter
  final Future<bool> Function(String title, LumoLearningTask task)
      onQuestionNeeded;
  final Future<bool> Function() onChestChallenge;
  final void Function(int totalStars, int levelStars) onLevelComplete;

  // Spielwelt-Objekte
  late FoxPlayerComponent fox;
  late BossChestComponent chest;
  final List<PlatformTileComponent>   platforms      = [];
  final List<StarCoinComponent>       stars          = [];
  final List<ReactiveCrateComponent>  crates         = [];
  final List<JumpPadComponent>        jumpPads       = [];
  final List<QuestionBlockComponent>  questionBlocks = [];
  final List<NormalObstacleComponent> obstacles      = [];

  // Session-Zustand
  int    sessionStars     = 0;
  int    totalEarnedStars = 0;
  double totalTime        = 0;
  double cameraX          = 0;
  double worldWidth       = 6400;
  bool   interactionLock  = false;
  bool   walletTransferred= false;
  String statusHint       = '';
  double statusHintTimer  = 0;

  // Reaktive Notifier für Flutter-HUD
  final ValueNotifier<int>    starsN  = ValueNotifier(0);
  final ValueNotifier<String> hintN   = ValueNotifier('');
  final ValueNotifier<int>    solvedN = ValueNotifier(0);
  final ValueNotifier<int>    totalQN = ValueNotifier(0);

  int get _solvedCount   => questionBlocks.where((b) => b.cleared).length;
  int get _requiredCount => questionBlocks.length;

  int get _levelSeed {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day)
                .millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay +
        level.id * 97;
  }

  @override
  Color backgroundColor() => const Color(0xFFBAE6FD);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // 3-Ebenen-Parallax-Hintergrund (tiefste Priorität)
    world.add(LumoParallaxBackground(game: this)..priority = -200);

    // Level aufbauen
    _buildLevel();

    // Fuchs
    fox = FoxPlayerComponent(game: this);
    fox.position = Vector2(70, _baseGroundY - 76);
    world.add(fox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    totalTime += dt;
    _updateCamera();
    _updateHint(dt);
    starsN.value  = sessionStars;
    solvedN.value = _solvedCount;
    totalQN.value = _requiredCount;
  }

  // ── Kamera ───────────────────────────────────────────────────────────

  void _updateCamera() {
    if (!fox.isMounted) return;
    final vw    = size.x;
    final target = fox.position.x - vw * 0.35;
    cameraX = target.clamp(0.0, math.max(0.0, worldWidth - vw));
    camera.viewfinder.position = Vector2(cameraX, 0);
  }

  // ── Status-Hinweis ────────────────────────────────────────────────────

  void showHint(String msg, {double sec = 2.5}) {
    statusHint      = msg;
    statusHintTimer = sec;
    hintN.value     = msg;
  }

  void _updateHint(double dt) {
    if (statusHintTimer > 0) {
      statusHintTimer -= dt;
      if (statusHintTimer <= 0) {
        statusHint  = '';
        hintN.value = '';
      }
    }
  }

  // ── Stern einsammeln ──────────────────────────────────────────────────

  void collectStar(StarCoinComponent star) {
    if (star.collected) return;
    star.collected = true;
    sessionStars++;
    totalEarnedStars++;
    showHint('+1 ⭐', sec: 1.0);
    HapticFeedback.lightImpact();
  }

  // ── Frageblock ────────────────────────────────────────────────────────

  Future<void> triggerQuestion(QuestionBlockComponent block) async {
    if (interactionLock || block.cleared) return;
    interactionLock = true;
    pauseEngine();
    final seed  = DateTime.now().millisecondsSinceEpoch + _solvedCount * 11;
    final task  = block.isGerman ? createGermanTask(seed) : createMathTask(seed);
    final title = block.isGerman ? 'Deutsch-Frageblock 🦊' : 'Mathe-Frageblock 🔢';
    final ok    = await onQuestionNeeded(title, task);
    if (ok) {
      block.cleared = true;
      sessionStars      += 5;
      totalEarnedStars  += 5;
      showHint('Super! +5 ⭐');
    }
    resumeEngine();
    interactionLock = false;
  }

  // ── Boss-Truhe ────────────────────────────────────────────────────────

  Future<void> triggerChest() async {
    if (interactionLock || chest.chestState != ChestState.closed) return;
    if (_solvedCount < _requiredCount) {
      showHint('Löse erst alle Frageblöcke ($_solvedCount/$_requiredCount)!');
      return;
    }
    interactionLock = true;
    pauseEngine();
    final opened = await onChestChallenge();
    if (opened) {
      chest.open();
      sessionStars      += 50;
      totalEarnedStars  += 50;
      showHint('Boss-Truhe geöffnet! +50 ⭐');
      resumeEngine();
      _finishLevel();
      return;
    }
    resumeEngine();
    interactionLock = false;
  }

  // ── Level abschließen ─────────────────────────────────────────────────

  void _finishLevel() {
    final lStars = chest.chestState != ChestState.closed &&
            _solvedCount == _requiredCount
        ? 3
        : _solvedCount >= (_requiredCount / 2).ceil()
            ? 2
            : _solvedCount > 0
                ? 1
                : 0;

    if (!walletTransferred) {
      walletTransferred = true;
      final st = appState.state;
      appState.update(st.copyWith(
        stars:       st.stars + totalEarnedStars,
        xp:          st.xp + totalEarnedStars * 2,
        mood:        LumoMood.celebrate,
        lumoMessage: 'Lumo Jump geschafft!\n+$totalEarnedStars Sterne',
      ));
    }

    GameProgressRepository().recordResult( // fire-and-forget
      childId:     _childId,
      levelId:     level.id,
      starsEarned: lStars,
    );

    onLevelComplete(totalEarnedStars, lStars);
  }

  String get _childId {
    final st   = appState.state;
    final name = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${name}_${st.grade}';
  }

  // ── Lernaufgaben ──────────────────────────────────────────────────────

  LumoLearningTask createMathTask(int seed) {
    final grade = math.max(level.gradeFloor, appState.state.grade);
    const units = ['Plus bis 10', 'Minus bis 10', 'Mengenvergleich', 'Zahlenstrahl'];
    final unit  = units[seed.abs() % units.length];
    final t     = MathTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return LumoLearningTask(prompt: t.prompt, choices: t.choices, answer: t.answer);
  }

  LumoLearningTask createGermanTask(int seed) {
    final grade = math.max(level.gradeFloor, appState.state.grade);
    const units = ['Anfangslaute', 'Endlaute', 'Silben', 'Wort-Bild-Zuordnung'];
    final unit  = units[seed.abs() % units.length];
    final t     = GermanTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return LumoLearningTask(prompt: t.prompt, choices: t.choices, answer: t.answer);
  }

  // ── Level-Generator ───────────────────────────────────────────────────

  void _buildLevel() {
    final config = _LevelConfig.forLevel(level.id);
    final rng   = math.Random(_levelSeed);
    double x    = 0;
    double lastY = _baseGroundY;

    // Startplattform (immer breit + flach fuer einen sicheren Start)
    _addPlatform(x, lastY, 420, 120);
    x = 380;

    var chunk = 0;
    while (x < config.worldLength) {
      // ── Plattform-Breite + Hoehen-Variation skalieren je nach Level ──
      final w  = (config.platformMinW +
              rng.nextInt(config.platformMaxW - config.platformMinW))
          .toDouble();
      final dy = (rng.nextInt(3) - 1) * config.yVariation;
      final y  = (lastY + dy).clamp(config.minY, config.maxY);
      _addPlatform(x, y, w, 90);

      // ── Sterne ──
      final sc = config.starsPerChunk + rng.nextInt(2);
      for (var i = 0; i < sc; i++) {
        final sx = x + 48 + i * ((w - 96) / math.max(1, sc - 1));
        final sy = y - 54 - (i.isEven ? 10.0 : 0.0);
        _addStar(sx, sy);
      }

      // ── Frageblock (haeufiger bei hoeheren Levels) ──
      if (chunk % config.questionBlockEveryN == 1) {
        _addQuestionBlock(x + w * 0.55, y - 70,
            isGerman: chunk % (config.questionBlockEveryN * 2) == 1);
      }

      // ── Hindernis oder Kiste ──
      if (chunk % config.obstacleEveryN == 0 && chunk > 0) {
        final ox = x + w * 0.35;
        if (rng.nextBool()) {
          _addCrate(ox, y - 52);
        } else {
          final isDuck = rng.nextBool();
          _addObstacle(ox, y - (isDuck ? 36 : 52), 54,
              isDuck ? 36 : 52, isDuck);
        }
        // Doppel-Hindernis bei hohen Leveln (taktisch fordernder)
        if (config.doubleObstacles && rng.nextDouble() < 0.4) {
          _addCrate(ox + 70, y - 52);
        }
      }

      // ── Jump-Pad ──
      if (chunk % config.jumpPadEveryN == 2 && chunk > 0) {
        _addJumpPad(x + w * 0.5 - 20, y - 22);
      }

      // ── PODEST-SEKTION (mehrstoeckige Plattformen, taktischer Aufstieg) ──
      // Ab Level 4 alle paar Chunks ein 3-Stock-Podest neben der Hauptebene
      if (config.includePodests && chunk % 6 == 4) {
        final podestX = x + w + 40;
        final tower1Y = y - 90;
        final tower2Y = y - 170;
        final tower3Y = y - 250;
        _addPlatform(podestX, tower1Y, 90, 24);
        _addStar(podestX + 45, tower1Y - 24);
        if (config.podestStories >= 2) {
          _addPlatform(podestX + 60, tower2Y, 80, 24);
          _addStar(podestX + 100, tower2Y - 24);
        }
        if (config.podestStories >= 3) {
          _addPlatform(podestX + 130, tower3Y, 70, 24);
          // Bonus-Stern oben
          _addStar(podestX + 165, tower3Y - 30);
          _addStar(podestX + 165, tower3Y - 50);
        }
      }

      // ── TIEFE TAL-SEKTION (Lumo muss runter + wieder rauf) ──
      // Ab Level 6: alle paar Chunks eine Tal-Sektion mit niedrigeren Plattformen
      if (config.includeValleys && chunk % 8 == 6) {
        final valleyX = x + w + 30;
        final valleyY = y + 50;
        _addPlatform(valleyX, valleyY.clamp(config.minY, config.maxY + 60),
            220, 90);
        _addStar(valleyX + 60, valleyY - 24);
        _addStar(valleyX + 110, valleyY - 30);
        _addStar(valleyX + 160, valleyY - 24);
      }

      lastY = y;
      final gap = (config.gapMin +
              rng.nextInt(config.gapMax - config.gapMin))
          .toDouble()
          .clamp(50.0, _maxSafeGap);
      x    += w + gap;
      chunk++;
    }

    // Boss-Truhe (immer am Ende)
    chest          = BossChestComponent(game: this);
    chest.position = Vector2(x + 120, lastY - 60);
    chest.size     = Vector2(74, 60);
    world.add(chest);

    _addPlatform(x, lastY, 320, 90);
    worldWidth = x + 700;
  }

  void _addPlatform(double x, double y, double w, double h) {
    final c = PlatformTileComponent()
      ..position = Vector2(x, y)
      ..size     = Vector2(w, h);
    platforms.add(c);
    world.add(c);
  }

  void _addStar(double x, double y) {
    final c = StarCoinComponent(game: this)
      ..position = Vector2(x - 14, y - 14)
      ..size     = Vector2(28, 28);
    stars.add(c);
    world.add(c);
  }

  void _addQuestionBlock(double x, double y, {required bool isGerman}) {
    final c = QuestionBlockComponent(game: this, isGerman: isGerman)
      ..position = Vector2(x, y)
      ..size     = Vector2(62, 62);
    questionBlocks.add(c);
    world.add(c);
  }

  void _addCrate(double x, double y) {
    final c = ReactiveCrateComponent(game: this)
      ..position = Vector2(x, y)
      ..size     = Vector2(54, 52);
    crates.add(c);
    world.add(c);
  }

  void _addObstacle(double x, double y, double w, double h, bool isDuck) {
    final c = NormalObstacleComponent(requiresDuck: isDuck)
      ..position = Vector2(x, y)
      ..size     = Vector2(w, h);
    obstacles.add(c);
    world.add(c);
  }

  void _addJumpPad(double x, double y) {
    final c = JumpPadComponent(game: this)
      ..position = Vector2(x, y)
      ..size     = Vector2(40, 22);
    jumpPads.add(c);
    world.add(c);
  }
}

// ════════════════════════════════════════════════════════════════════════
// PARALLAX-HINTERGRUND – 3 Ebenen (Himmel / Berge / Hügel)
// ════════════════════════════════════════════════════════════════════════

/// Implementiert Parallax mit drei prozedural gezeichneten Ebenen:
///   Ebene 1 – Himmel-Gradient + Sonne + Wolken (fest)
///   Ebene 2 – Berge (15 % Kamera-Parallax)
///   Ebene 3 – Hügel (35 % Kamera-Parallax)
class LumoParallaxBackground extends PositionComponent {
  LumoParallaxBackground({required this.game});

  final LumoFlameJumpGame game;

  @override
  void update(double dt) {
    // Immer am linken Rand des Viewports bleiben
    position = Vector2(game.cameraX, 0);
    size     = game.size;
  }

  @override
  void render(Canvas canvas) {
    final s  = size;
    final cx = game.cameraX;

    _paintSky(canvas, s);
    // ── Schicht 1: ferne Berge (langsamster Parallax) ──────
    _paintMountainLayer(canvas, s,
        offset: cx * 0.10,
        color:  const Color(0xFFBBDEFB),
        hFrac:  0.34,
        peakW:  220);
    // ── Schicht 2: mittlere Berge mit Nebel ────────────────
    _paintMountainLayer(canvas, s,
        offset: cx * 0.20,
        color:  const Color(0xFF86EFAC),
        hFrac:  0.28,
        peakW:  180);
    // ── Schicht 3: Wasserfall im Hintergrund ───────────────
    _paintWaterfall(canvas, s, cx);
    // ── Schicht 4: vordere Huegel (kraeftiges Gruen) ───────
    _paintMountainLayer(canvas, s,
        offset: cx * 0.38,
        color:  const Color(0xFF22C55E),
        hFrac:  0.19,
        peakW:  160);
    // ── Schicht 5: Baum-Silhouetten + Voegel + Schmetterlinge ──
    _paintTreeline(canvas, s, cx);
    _paintBirds(canvas, s);
    _paintButterflies(canvas, s, cx);
  }

  void _paintSky(Canvas canvas, Vector2 s) {
    final rect = Rect.fromLTWH(0, 0, s.x, s.y);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE), Color(0xFFFEF3C7)],
            stops:  [0.0, 0.55, 1.0],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ).createShader(rect));

    // Sonne mit Strahlen + Glow (mehr Praesenz)
    final sunC = Offset(s.x * 0.85, s.y * 0.14);
    // Glow-Schichten
    canvas.drawCircle(sunC, 60, Paint()..color = const Color(0xFFFCD34D).withOpacity(0.18));
    canvas.drawCircle(sunC, 42, Paint()..color = const Color(0xFFFCD34D).withOpacity(0.35));
    // Strahlen (rotierend)
    final rayPaint = Paint()
      ..color = const Color(0xFFFCD34D).withOpacity(0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2 + game.totalTime * 0.15;
      final r1 = 32.0 + math.sin(game.totalTime + i) * 2;
      final r2 = 50.0 + math.sin(game.totalTime * 1.4 + i) * 4;
      canvas.drawLine(
          sunC + Offset(math.cos(a) * r1, math.sin(a) * r1),
          sunC + Offset(math.cos(a) * r2, math.sin(a) * r2),
          rayPaint);
    }
    // Sonnenkoerper
    canvas.drawCircle(sunC, 28,
        Paint()..color = const Color(0xFFFCD34D));
    canvas.drawCircle(sunC.translate(-7, -7), 9,
        Paint()..color = Colors.white.withOpacity(0.8));

    // Driftende Wolken (mehrere Schichten)
    _paintCloud(canvas,
        s.x * 0.18 + math.sin(game.totalTime * 0.04) * 10, s.y * 0.12, 65, 24);
    _paintCloud(canvas,
        s.x * 0.42 + math.sin(game.totalTime * 0.03 + 1) * 8, s.y * 0.18, 80, 30);
    _paintCloud(canvas,
        s.x * 0.65 + math.cos(game.totalTime * 0.05) * 6, s.y * 0.10, 55, 22);
    _paintCloud(canvas,
        s.x * 0.28 + math.cos(game.totalTime * 0.025 + 2) * 9, s.y * 0.22, 48, 18);
  }

  void _paintCloud(Canvas canvas, double cx, double cy, double w, double h) {
    // Sanfter Schatten unten
    final shadow = Paint()..color = const Color(0xFF94A3B8).withOpacity(0.18);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 4), width: w * 1.1, height: h * 0.5),
        shadow);
    // Wolken-Kreise (organisch)
    final p = Paint()..color = Colors.white.withOpacity(0.92);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h), p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - w * 0.28, cy + 2),
            width:  w * 0.65,
            height: h * 0.78),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + w * 0.28, cy + 2),
            width:  w * 0.65,
            height: h * 0.78),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + w * 0.15, cy - h * 0.3),
            width:  w * 0.5,
            height: h * 0.7),
        p);
    // Highlight oben
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - w * 0.1, cy - h * 0.25),
            width:  w * 0.35,
            height: h * 0.3),
        Paint()..color = Colors.white);
  }

  /// Zeichnet eine Schicht sich wiederholender Berggipfel.
  void _paintMountainLayer(Canvas canvas, Vector2 s,
      {required double offset,
       required Color color,
       required double hFrac,
       double peakW = 180}) {
    final h   = s.y * hFrac;
    final cnt = (s.x / peakW).ceil() + 2;
    final mod = offset % peakW;
    final paint = Paint()..color = color;
    final darker = Paint()..color = color.withOpacity(0.7);
    for (var i = -1; i < cnt; i++) {
      final px = i * peakW - mod + peakW * 0.5;
      // Berg-Hauptkoerper
      canvas.drawPath(
          Path()
            ..moveTo(px - peakW * 0.5, s.y)
            ..lineTo(px,                s.y - h)
            ..lineTo(px + peakW * 0.5, s.y)
            ..close(),
          paint);
      // Schatten-Seite (rechts dunkler fuer 3D)
      canvas.drawPath(
          Path()
            ..moveTo(px, s.y - h)
            ..lineTo(px + peakW * 0.5, s.y)
            ..lineTo(px + peakW * 0.05, s.y)
            ..close(),
          darker);
      // Schnee-Spitze
      if (h > s.y * 0.2) {
        canvas.drawPath(
            Path()
              ..moveTo(px - peakW * 0.12, s.y - h + 12)
              ..lineTo(px, s.y - h)
              ..lineTo(px + peakW * 0.12, s.y - h + 12)
              ..lineTo(px + peakW * 0.06, s.y - h + 16)
              ..lineTo(px - peakW * 0.06, s.y - h + 16)
              ..close(),
            Paint()..color = Colors.white.withOpacity(0.85));
      }
    }
  }

  /// Wasserfall-Effekt im Hintergrund (mittlere Ebene, stilisiert).
  void _paintWaterfall(Canvas canvas, Vector2 s, double cx) {
    final wfX = s.x * 0.75 - (cx * 0.15 % s.x);
    if (wfX < -100 || wfX > s.x + 100) return;
    final topY = s.y * 0.30;
    final bottomY = s.y * 0.66;
    // Wasserfall-Streifen
    final rect = Rect.fromLTWH(wfX, topY, 36, bottomY - topY);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.6),
              const Color(0xFF7DD3FC).withOpacity(0.75),
              const Color(0xFF38BDF8).withOpacity(0.65),
            ],
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
          ).createShader(rect));
    // Animierte vertikale Linien (Wasser-Fluss)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 5; i++) {
      final lx = wfX + 4 + i * 7;
      final offset = (game.totalTime * 120 + i * 13) % 30;
      for (var j = 0; j < 6; j++) {
        final ly = topY + j * 30 + offset;
        if (ly > bottomY) continue;
        canvas.drawLine(
            Offset(lx, ly),
            Offset(lx, ly + 14),
            linePaint);
      }
    }
    // Spray unten
    final sprayY = bottomY;
    final sprayPaint = Paint()..color = Colors.white.withOpacity(0.6);
    for (var i = 0; i < 8; i++) {
      final sx = wfX + 18 + (i - 4) * 8 + math.sin(game.totalTime * 4 + i) * 2;
      final sr = 4.0 + math.cos(game.totalTime * 3 + i) * 1.5;
      canvas.drawCircle(Offset(sx, sprayY - sr / 2), sr, sprayPaint);
    }
  }

  /// Dunkle Baum-Silhouetten am unteren Horizont (Tiefe).
  void _paintTreeline(Canvas canvas, Vector2 s, double cx) {
    final offset = cx * 0.55;
    const treeW = 60.0;
    final baseY = s.y * 0.85;
    final cnt = (s.x / treeW).ceil() + 2;
    final mod = offset % treeW;
    final paint = Paint()..color = const Color(0xFF166534).withOpacity(0.85);
    for (var i = -1; i < cnt; i++) {
      final tx = i * treeW - mod;
      final h = 50.0 + ((i * 17) % 24);
      // Tannen-Form (3 Dreiecke uebereinander)
      for (var j = 0; j < 3; j++) {
        final tw = treeW * (0.5 - j * 0.08);
        final ty = baseY - h + j * (h * 0.28);
        canvas.drawPath(
            Path()
              ..moveTo(tx + treeW * 0.5 - tw * 0.5, ty + 12)
              ..lineTo(tx + treeW * 0.5, ty - 8)
              ..lineTo(tx + treeW * 0.5 + tw * 0.5, ty + 12)
              ..close(),
            paint);
      }
      // Stamm
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(tx + treeW * 0.5, baseY - 4),
              width: 4, height: 8),
          Paint()..color = const Color(0xFF422006));
    }
  }

  /// Voegel die sanft durch den Himmel ziehen (3 Voegel).
  void _paintBirds(Canvas canvas, Vector2 s) {
    final t = game.totalTime;
    for (var i = 0; i < 3; i++) {
      final baseX = (s.x * 1.2 + i * 280 - (t * 30 + i * 100)) % (s.x * 1.5) - s.x * 0.25;
      final baseY = s.y * (0.08 + i * 0.04) + math.sin(t * 1.5 + i) * 4;
      _paintBird(canvas, Offset(baseX, baseY), t * 8 + i * 2);
    }
  }

  void _paintBird(Canvas canvas, Offset c, double wingPhase) {
    final p = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // Voegel als geschwungenes M
    final flap = math.sin(wingPhase) * 5;
    final path = Path()
      ..moveTo(c.dx - 9, c.dy + 1)
      ..quadraticBezierTo(c.dx - 4, c.dy - 4 + flap, c.dx, c.dy + 1)
      ..quadraticBezierTo(c.dx + 4, c.dy - 4 + flap, c.dx + 9, c.dy + 1);
    canvas.drawPath(path, p);
  }

  /// Bunt flatternde Schmetterlinge im mittleren Bereich.
  void _paintButterflies(Canvas canvas, Vector2 s, double cx) {
    final t = game.totalTime;
    final colors = <Color>[
      const Color(0xFFFB7185),
      const Color(0xFFA78BFA),
      const Color(0xFFFCD34D),
    ];
    for (var i = 0; i < 3; i++) {
      final x = (s.x * (0.15 + i * 0.32) + math.sin(t * 0.4 + i * 2) * 30 -
              (cx * 0.4) % s.x) %
          s.x;
      final y = s.y * (0.45 + i * 0.08) + math.sin(t * 1.2 + i) * 12;
      _paintButterfly(canvas, Offset(x, y), t * 14 + i, colors[i]);
    }
  }

  void _paintButterfly(Canvas canvas, Offset c, double wingPhase, Color color) {
    final wingW = 5 + math.sin(wingPhase) * 2;
    final p = Paint()..color = color.withOpacity(0.85);
    // 4 Fluegel als Ovale
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(-wingW, -2), width: 6, height: 8), p);
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(wingW, -2), width: 6, height: 8), p);
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(-wingW * 0.8, 3), width: 5, height: 6), p);
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(wingW * 0.8, 3), width: 5, height: 6), p);
    // Koerper
    canvas.drawCircle(c, 1.5, Paint()..color = const Color(0xFF1F2937));
  }
}

// ════════════════════════════════════════════════════════════════════════
// PLATTFORM
// ════════════════════════════════════════════════════════════════════════

class PlatformTileComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Schatten UNTER der Plattform fuer Tiefe
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(2, h - 2, w - 4, 8),
            const Radius.circular(4)),
        Paint()..color = Colors.black.withOpacity(0.18));

    // Erdkoerper mit Gradient (oben heller, unten dunkler)
    final earthRect = Rect.fromLTWH(0, 4, w, h - 4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(earthRect, const Radius.circular(8)),
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFA16207),
              Color(0xFF92400E),
              Color(0xFF78350F),
            ],
            stops: [0.0, 0.4, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(earthRect));

    // Stein-Textur (sichtbare Kiesel im Erdkoerper)
    final rng = math.Random((position.x * 7 + position.y * 3).round());
    final pebbleCount = (w / 35).floor();
    for (var i = 0; i < pebbleCount; i++) {
      final px = 12 + i * 32 + rng.nextInt(20).toDouble();
      final py = 22 + rng.nextInt((h - 30).round()).toDouble();
      final ps = 3.0 + rng.nextInt(4);
      // Kiesel-Body
      canvas.drawOval(
          Rect.fromCenter(center: Offset(px, py), width: ps * 2, height: ps * 1.4),
          Paint()..color = const Color(0xFF57534E).withOpacity(0.6));
      // Highlight
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(px - ps * 0.3, py - ps * 0.3),
              width: ps * 0.8,
              height: ps * 0.4),
          Paint()..color = Colors.white.withOpacity(0.35));
    }

    // Wurzel-Linien (organischer)
    final rootPaint = Paint()
      ..color = const Color(0xFF422006).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < (w / 80).floor(); i++) {
      final rx = 30 + i * 70 + rng.nextInt(20);
      canvas.drawPath(
          Path()
            ..moveTo(rx.toDouble(), 18)
            ..quadraticBezierTo(
                rx + 4.0, 30, rx + (rng.nextInt(8) - 4).toDouble(), h - 8),
          rootPaint);
    }

    // Grasoberflaeche mit Hauptgradient
    final grassRect = Rect.fromLTWH(0, 0, w, 18);
    canvas.drawRRect(
        RRect.fromLTRBR(0, 0, w, 18, const Radius.circular(8)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF86EFAC), Color(0xFF4ADE80), Color(0xFF16A34A)],
            stops: [0.0, 0.5, 1.0],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ).createShader(grassRect));

    // Gras-Halme (kleine Spitzen am oberen Rand)
    final grassPaint = Paint()..color = const Color(0xFF15803D);
    for (var i = 0; i < (w / 12).floor(); i++) {
      final gx = 6 + i * 12 + rng.nextInt(6) - 3;
      final gh = 3.0 + rng.nextInt(3);
      canvas.drawPath(
          Path()
            ..moveTo(gx.toDouble() - 1.5, 0)
            ..lineTo(gx.toDouble(), -gh)
            ..lineTo(gx.toDouble() + 1.5, 0)
            ..close(),
          grassPaint);
    }

    // Blumen-Akzente (kleine bunte Punkte)
    for (var i = 0; i < (w / 100).floor(); i++) {
      final fx = 30 + i * 90 + rng.nextInt(40);
      final fy = -1.0;
      final colors = <Color>[
        const Color(0xFFFB7185),
        const Color(0xFFA78BFA),
        const Color(0xFFFCD34D),
        Colors.white,
      ];
      final flowerColor = colors[rng.nextInt(colors.length)];
      // 5 Blutenblaetter
      for (var j = 0; j < 5; j++) {
        final a = (j / 5) * math.pi * 2;
        canvas.drawCircle(
            Offset(fx + math.cos(a) * 2.2, fy + math.sin(a) * 2.2),
            1.6,
            Paint()..color = flowerColor);
      }
      // Mittelpunkt
      canvas.drawCircle(
          Offset(fx.toDouble(), fy),
          1.2,
          Paint()..color = const Color(0xFFFCD34D));
    }

    // Glanzlicht auf der oberen Kante (3D-Effekt)
    canvas.drawRRect(
        RRect.fromLTRBR(2, 2, w - 2, 5, const Radius.circular(3)),
        Paint()..color = Colors.white.withOpacity(0.25));
  }
}

// ════════════════════════════════════════════════════════════════════════
// NORMALES HINDERNIS
// ════════════════════════════════════════════════════════════════════════

class NormalObstacleComponent extends PositionComponent {
  NormalObstacleComponent({required this.requiresDuck});

  final bool requiresDuck;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final color =
        requiresDuck ? const Color(0xFF7C3AED) : const Color(0xFF0EA5E9);
    final colorDark = requiresDuck
        ? const Color(0xFF5B21B6)
        : const Color(0xFF0369A1);

    // Schatten unter dem Hindernis
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, h + 2),
            width: w * 0.95,
            height: 6),
        Paint()..color = Colors.black.withOpacity(0.25));

    // Hauptkoerper mit Vertikal-Gradient
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            const Radius.circular(10)),
        Paint()
          ..shader = LinearGradient(
            colors: [color, colorDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Highlight oben (Glanz)
    canvas.drawRRect(
        RRect.fromLTRBR(4, 3, w - 4, h * 0.35, const Radius.circular(8)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(4, 3, w - 8, h * 0.32)));

    // Augen-Setup (zentral, freundlicher Charakter)
    final eyeY = h * 0.42;
    final eyeR = math.min(w, h) * 0.11;

    // Augen-Weiss (gross, rund - freundlich nicht boese)
    canvas.drawCircle(Offset(w * 0.32, eyeY), eyeR * 1.15,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.68, eyeY), eyeR * 1.15,
        Paint()..color = Colors.white);
    // Pupillen mittig, gross, schauen nach vorne
    canvas.drawCircle(Offset(w * 0.32, eyeY), eyeR * 0.65,
        Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(w * 0.68, eyeY), eyeR * 0.65,
        Paint()..color = const Color(0xFF1F2937));
    // Pupillen-Glanzpunkte (lebendig)
    canvas.drawCircle(Offset(w * 0.32 - eyeR * 0.2, eyeY - eyeR * 0.2),
        eyeR * 0.22, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.68 - eyeR * 0.2, eyeY - eyeR * 0.2),
        eyeR * 0.22, Paint()..color = Colors.white);

    // Niedliche rote Wangen (Charakter, freundlich)
    final cheek = Paint()..color = const Color(0xFFFB7185).withOpacity(0.55);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.20, eyeY + eyeR * 1.6),
            width: w * 0.15,
            height: h * 0.10),
        cheek);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.80, eyeY + eyeR * 1.6),
            width: w * 0.15,
            height: h * 0.10),
        cheek);

    // Bei requiresDuck: kleine Stachel oben (Spielfigur "stachelig")
    if (requiresDuck) {
      final spikePaint = Paint()..color = colorDark;
      for (var i = 0; i < 3; i++) {
        final sx = w * (0.25 + i * 0.25);
        canvas.drawPath(
            Path()
              ..moveTo(sx - 4, 0)
              ..lineTo(sx, -6)
              ..lineTo(sx + 4, 0)
              ..close(),
            spikePaint);
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// STERN-MÜNZE – SpriteAnimationComponent mit prozedurallem Rendering
// ════════════════════════════════════════════════════════════════════════

class StarCoinComponent extends SpriteAnimationComponent {
  StarCoinComponent({required this.game});

  final LumoFlameJumpGame game;
  bool   collected = false;
  double _baseY    = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await _createPlaceholderAnim();
    anchor    = Anchor.topLeft;
  }

  @override
  void onMount() {
    super.onMount();
    _baseY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!collected) {
      position.y =
          _baseY + math.sin(game.totalTime * 2.2 + position.x * 0.01) * 3.5;
    }
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s  = size.x * 0.5;
    final t  = game.totalTime;

    // Pulsierende Glow-Halo (mehrschichtig)
    final pulse = 0.85 + math.sin(t * 3.0 + position.x * 0.01) * 0.15;
    canvas.drawCircle(Offset(cx, cy), s * 1.6 * pulse,
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.12));
    canvas.drawCircle(Offset(cx, cy), s * 1.3 * pulse,
        Paint()..color = const Color(0xFFFBBF24).withOpacity(0.22));
    canvas.drawCircle(Offset(cx, cy), s * 1.05 * pulse,
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.42));

    // Kreis-Body mit Radial-Gradient
    canvas.drawCircle(
        Offset(cx, cy),
        s * 0.88,
        Paint()
          ..shader = RadialGradient(
            colors: const [
              Color(0xFFFEF3C7),
              Color(0xFFFCD34D),
              Color(0xFFF59E0B),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: s)));

    // Inner Stern (rotiert)
    final rot  = t * 0.9 + position.x * 0.01;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a  = -math.pi / 2 + (i / 10) * math.pi * 2 + rot;
      final r  = i.isEven ? s * 0.52 : s * 0.26;
      final px = cx + math.cos(a) * r;
      final py = cy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFEF3C7));

    // Glanzpunkt
    canvas.drawCircle(
        Offset(cx - s * 0.25, cy - s * 0.25),
        s * 0.18,
        Paint()..color = Colors.white.withOpacity(0.85));

    // Funkel-Partikel um den Stern (4 Sterne die rotieren)
    for (var i = 0; i < 4; i++) {
      final a = (i / 4) * math.pi * 2 + t * 1.5;
      final r = s * (1.4 + math.sin(t * 2 + i) * 0.15);
      final sx = cx + math.cos(a) * r;
      final sy = cy + math.sin(a) * r;
      final sparkleSize = 2.2 + math.sin(t * 4 + i) * 1.0;
      _drawSparkle(canvas, Offset(sx, sy), sparkleSize,
          Colors.white.withOpacity(0.75));
    }
  }

  /// Zeichnet ein kleines 4-strahliges Funkel-Symbol.
  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.3, c.dy - r * 0.3)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.3, c.dy + r * 0.3)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.3, c.dy + r * 0.3)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.3, c.dy - r * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }
}

// ════════════════════════════════════════════════════════════════════════
// FRAGEBLOCK
// ════════════════════════════════════════════════════════════════════════

class QuestionBlockComponent extends PositionComponent {
  QuestionBlockComponent({required this.game, required this.isGerman});

  final LumoFlameJumpGame game;
  final bool isGerman;
  bool cleared = false;

  @override
  void render(Canvas canvas) {
    if (cleared) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8)),
          Paint()..color = const Color(0xFFD1D5DB).withOpacity(0.6));
      // X-Marke fuer geklaerten Block
      final clearedPaint = Paint()
        ..color = const Color(0xFF6B7280)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(size.x * 0.3, size.y * 0.3),
          Offset(size.x * 0.7, size.y * 0.7),
          clearedPaint);
      canvas.drawLine(
          Offset(size.x * 0.7, size.y * 0.3),
          Offset(size.x * 0.3, size.y * 0.7),
          clearedPaint);
      return;
    }

    final t     = game.totalTime;
    final r     = Rect.fromLTWH(0, 0, size.x, size.y);
    final pulse = 0.5 + math.sin(t * 3) * 0.5;

    // Schatten unter dem Block (3D)
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            r.translate(0, 4), const Radius.circular(10)),
        Paint()..color = Colors.black.withOpacity(0.25));

    // Pulsierender Glow-Halo (mehrschichtig)
    canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(12), const Radius.circular(16)),
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.15 + pulse * 0.10));
    canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(12)),
        Paint()
          ..color = const Color(0xFFFCD34D).withOpacity(0.30 + pulse * 0.20));

    // Block-Body mit Gradient
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFFEF3C7),
              Color(0xFFFCD34D),
              Color(0xFFF59E0B),
            ],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(r));

    // Rote Edelstein-Knoepfe an den 4 Ecken (Charakter)
    final gemSize = math.min(size.x, size.y) * 0.10;
    final gemPositions = [
      Offset(6 + gemSize, 6 + gemSize),
      Offset(size.x - 6 - gemSize, 6 + gemSize),
      Offset(6 + gemSize, size.y - 6 - gemSize),
      Offset(size.x - 6 - gemSize, size.y - 6 - gemSize),
    ];
    for (final c in gemPositions) {
      canvas.drawCircle(c, gemSize,
          Paint()..color = const Color(0xFF92400E));
      canvas.drawCircle(c, gemSize * 0.7,
          Paint()..color = const Color(0xFFFBBF24));
    }

    // Highlight-Glanz oben
    canvas.drawRRect(
        RRect.fromLTRBR(4, 4, size.x - 4, size.y * 0.4, const Radius.circular(7)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.55),
              Colors.white.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(4, 4, size.x - 8, size.y * 0.35)));

    // Symbol mit Outline
    final symText = isGerman ? 'A' : '?';
    // Outline
    final outline = TextPainter(
      text: TextSpan(
          text: symText,
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = const Color(0xFF92400E))),
      textDirection: TextDirection.ltr,
    )..layout();
    outline.paint(canvas,
        Offset(size.x / 2 - outline.width / 2, size.y / 2 - outline.height / 2));
    // Fuellung
    final tp = TextPainter(
      text: TextSpan(
          text:  symText,
          style: const TextStyle(
              fontSize:   32,
              fontWeight: FontWeight.w900,
              color:      Color(0xFFFEF3C7))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2));
  }
}

// ════════════════════════════════════════════════════════════════════════
// REAGIERENDE KISTE – idle / wobble / broken
// ════════════════════════════════════════════════════════════════════════

class ReactiveCrateComponent extends PositionComponent {
  ReactiveCrateComponent({required this.game});

  final LumoFlameJumpGame game;
  CrateState crateState = CrateState.idle;
  double     wiggleTimer = 0;
  bool       active      = true;

  void startWobble() {
    if (crateState == CrateState.idle) {
      crateState  = CrateState.wobble;
      wiggleTimer = 0;
    }
  }

  void stopWobble() {
    if (crateState == CrateState.wobble) crateState = CrateState.idle;
    wiggleTimer = 0;
  }

  void breakCrate() {
    crateState = CrateState.broken;
    active     = false;
  }

  @override
  void update(double dt) {
    if (crateState == CrateState.wobble) wiggleTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;

    final angle = crateState == CrateState.wobble
        ? math.sin(wiggleTimer * 14) * 0.055
        : 0.0;

    if (angle != 0) {
      canvas
        ..save()
        ..translate(size.x / 2, size.y / 2)
        ..rotate(angle)
        ..translate(-size.x / 2, -size.y / 2);
    }

    _paintCrate(canvas);

    if (angle != 0) canvas.restore();
  }

  void _paintCrate(Canvas canvas) {
    final r = Rect.fromLTWH(0, 0, size.x, size.y);

    // Schatten
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            r.shift(const Offset(2, 3)), const Radius.circular(6)),
        Paint()..color = Colors.black.withOpacity(0.22));

    // Holzkorpus
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)),
        Paint()
          ..shader = LinearGradient(
            colors: const [Color(0xFFA16207), Color(0xFF78350F)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ).createShader(r));

    // Holzmaserung
    final grain = Paint()
      ..color      = const Color(0xFF422006).withOpacity(0.22)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final gx = r.left + r.width * i / 4;
      canvas.drawLine(
          Offset(gx, r.top + 4), Offset(gx, r.bottom - 4), grain);
    }

    // Kreuz-Rahmen
    final fr = Paint()
      ..color      = const Color(0xFFEAB308)
      ..strokeWidth = 3
      ..strokeCap  = StrokeCap.round;
    canvas
      ..drawLine(
          Offset(r.left + 4, r.top + 4), Offset(r.right - 4, r.bottom - 4), fr)
      ..drawLine(
          Offset(r.right - 4, r.top + 4), Offset(r.left + 4, r.bottom - 4), fr)
      ..drawRRect(
          RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(4)),
          Paint()
            ..color      = const Color(0xFFEAB308)
            ..style      = PaintingStyle.stroke
            ..strokeWidth = 3);

    // Ecknägel
    for (final pos in [
      Offset(r.left + 6,  r.top + 6),
      Offset(r.right - 6, r.top + 6),
      Offset(r.left + 6,  r.bottom - 6),
      Offset(r.right - 6, r.bottom - 6),
    ]) {
      canvas
        ..drawCircle(pos, 2.8, Paint()..color = const Color(0xFF422006))
        ..drawCircle(
            pos.translate(-0.8, -0.8), 1.0,
            Paint()..color = const Color(0xFFFCD34D));
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// JUMP-PAD – idle / compress / release
// ════════════════════════════════════════════════════════════════════════

class JumpPadComponent extends PositionComponent {
  JumpPadComponent({required this.game});

  final LumoFlameJumpGame game;
  JumpPadState padState  = JumpPadState.idle;
  double       _spring   = 0;
  static const _maxSpring = 0.30;

  void activate() {
    padState = JumpPadState.compress;
    _spring  = _maxSpring;
    HapticFeedback.mediumImpact();
  }

  @override
  void update(double dt) {
    if (padState == JumpPadState.compress) {
      _spring = math.max(0, _spring - dt * 2.5);
      if (_spring == 0) padState = JumpPadState.idle;
    }
  }

  @override
  void render(Canvas canvas) {
    final r    = Rect.fromLTWH(0, 0, size.x, size.y);
    final comp = padState == JumpPadState.compress
        ? math.sin(math.pi * (1 - _spring / _maxSpring)) * 0.55
        : 0.0;

    final compH = r.height * (1.0 - comp * 0.55);
    final topY  = r.bottom - compH;
    final pad   = Rect.fromLTRB(r.left, topY, r.right, r.bottom);

    // Sockel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left - 5, r.bottom - 9, r.width + 10, 9),
            const Radius.circular(5)),
        Paint()..color = const Color(0xFF78716C));

    // Feder-Spiralen
    final coilH = compH * 0.58;
    final coil  = Paint()
      ..color      = const Color(0xFFD97706)
      ..strokeWidth = 3
      ..strokeCap  = StrokeCap.round
      ..style      = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final yBase = r.bottom - 9 - (i / 4) * coilH;
      final yTop  = r.bottom - 9 - ((i + 1) / 4) * coilH;
      if (i.isEven) {
        canvas.drawLine(Offset(r.left + 4,     yBase),
                        Offset(r.center.dx,  yTop), coil);
      } else {
        canvas.drawLine(Offset(r.center.dx,  yBase),
                        Offset(r.right - 4,  yTop), coil);
      }
    }

    // Ober-Pad
    canvas.drawRRect(
        RRect.fromRectAndRadius(pad, const Radius.circular(7)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFB923C), Color(0xFFF97316)],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ).createShader(pad));
    canvas.drawRRect(
        RRect.fromLTRBR(
            pad.left + 4, pad.top + 2, pad.right - 4, pad.top + 5,
            const Radius.circular(3)),
        Paint()..color = Colors.white.withOpacity(0.38));

    // Pfeil nach oben
    final mx = pad.center.dx;
    final my = pad.center.dy;
    final ap = Paint()
      ..color      = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..strokeCap  = StrokeCap.round;
    canvas
      ..drawLine(Offset(mx,     my + 4), Offset(mx,     my - 4), ap)
      ..drawLine(Offset(mx - 4, my),     Offset(mx,     my - 4), ap)
      ..drawLine(Offset(mx + 4, my),     Offset(mx,     my - 4), ap);

    // Glow bei Aktivierung
    if (padState == JumpPadState.compress) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(pad.inflate(6), const Radius.circular(12)),
          Paint()
            ..color = const Color(0xFFFCD34D)
                .withOpacity(_spring / _maxSpring * 0.5));
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// BOSS-TRUHE – closed / opening / openGlow
// ════════════════════════════════════════════════════════════════════════

class BossChestComponent extends PositionComponent {
  BossChestComponent({required this.game});

  final LumoFlameJumpGame game;
  ChestState chestState = ChestState.closed;
  double     lidAngle   = 0;
  double     _openTime  = 0;

  void open() {
    if (chestState == ChestState.closed) chestState = ChestState.opening;
  }

  @override
  void update(double dt) {
    if (chestState == ChestState.opening) {
      _openTime += dt;
      lidAngle   = math.min(_openTime * 5.0, math.pi * 0.75);
      if (lidAngle >= math.pi * 0.75) chestState = ChestState.openGlow;
    }
  }

  @override
  void render(Canvas canvas) {
    final r = Rect.fromLTWH(0, 0, size.x, size.y);
    if (chestState == ChestState.closed) {
      _paintClosed(canvas, r);
    } else {
      _paintOpen(canvas, r);
    }
  }

  void _paintClosed(Canvas canvas, Rect r) {
    canvas
      ..drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = const Color(0xFF92400E))
      ..drawRRect(
          RRect.fromLTRBR(r.left, r.top, r.right, r.top + 14,
              const Radius.circular(6)),
          Paint()..color = const Color(0xFFD97706))
      ..drawRect(
          Rect.fromCenter(
              center: Offset(r.center.dx, r.top + 18),
              width: 14,
              height: 18),
          Paint()..color = const Color(0xFFFCD34D))
      ..drawCircle(Offset(r.center.dx, r.top + 18), 3,
          Paint()..color = const Color(0xFF422006));
  }

  void _paintOpen(Canvas canvas, Rect r) {
    final frac = (lidAngle / (math.pi * 0.75)).clamp(0.0, 1.0);

    // Glühender Innenraum
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFCD34D).withOpacity(frac),
              const Color(0xFF92400E)
            ],
            stops: const [0.45, 1.0],
          ).createShader(r));

    // Truhen-Boden
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left, r.top + 14, r.width, r.height - 14),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFF78350F));

    // Deckel dreht sich auf
    canvas
      ..save()
      ..translate(r.left, r.top)
      ..rotate(-lidAngle)
      ..drawRRect(
          RRect.fromLTRBR(0, 0, r.width, 16, const Radius.circular(6)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFF92400E)],
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(0, 0, r.width, 16)))
      ..restore();

    // Funken
    if (frac > 0.1 && frac < 0.98) _paintSparkles(canvas, r, frac);

    // Trophy ab 70 % sichtbar
    if (frac > 0.7) {
      final alpha = ((frac - 0.7) / 0.3).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
            text:  '🏆',
            style: TextStyle(
                fontSize: 34, color: Colors.white.withOpacity(alpha))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2 + 4));
    }
  }

  void _paintSparkles(Canvas canvas, Rect r, double progress) {
    final t    = game.totalTime;
    final gold = Paint()..color = const Color(0xFFFCD34D).withOpacity(0.85);
    for (var i = 0; i < 8; i++) {
      final a  = (i / 8) * math.pi * 2 + t * 3.5;
      final d  = 18 + progress * 38;
      final cx = r.center.dx + math.cos(a) * d;
      final cy = r.top - 6 + math.sin(a) * d * 0.45;
      canvas.drawCircle(Offset(cx, cy), 2.5 + (i % 3), gold);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// FUCHS-SPIELER
// SpriteAnimationGroupComponent<FoxAnimationState> mit prozedurallem Render
// ════════════════════════════════════════════════════════════════════════

class FoxPlayerComponent
    extends SpriteAnimationGroupComponent<FoxAnimationState> {
  FoxPlayerComponent({required this.game})
      : super(size: Vector2(54, 76), anchor: Anchor.topLeft);

  final LumoFlameJumpGame game;

  // Physik
  double vx           = 0;
  double vy           = 0;
  bool   onGround     = false;
  bool   leftPressed  = false;
  bool   rightPressed = false;
  bool   duckPressed  = false;
  /// Joystick-Velocity-Input: -1.0 (voll links) bis 1.0 (voll rechts).
  /// Wird kontinuierlich vom Joystick-Widget gesetzt, bricht NICHT ab.
  double stickX       = 0;
  double rollTimer    = 0;
  double coyoteTimer  = 0;
  double jumpBufTimer = 0;
  double checkpointX  = 70;
  bool   facingRight  = true;

  /// Wird auf true gesetzt sobald die echten Sprite-Animationen geladen sind.
  /// Solange false bleibt der prozedurale Fallback aktiv.
  bool _spritesLoaded = false;

  double get _pW => (duckPressed || current == FoxAnimationState.roll) ? 64 : 54;
  double get _pH => (duckPressed || current == FoxAnimationState.roll) ? 52 : 76;

  Rect get worldRect =>
      Rect.fromLTWH(position.x, position.y, _pW, _pH);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Erst Placeholder setzen damit das Spiel sofort startet
    final placeholder = await _createPlaceholderAnim();
    animations  = {for (final s in FoxAnimationState.values) s: placeholder};
    current     = FoxAnimationState.idle;
    // Dann die echten Sprites asynchron laden
    _loadRealSprites();
  }

  /// Laedt die 39 echten Fox-Frames aus assets/lumo_jump/fox/ als
  /// SpriteAnimationen. Asynchron - Game startet ohne Wartezeit.
  Future<void> _loadRealSprites() async {
    try {
      // Flame's images.prefix ist 'assets/images/' - wir setzen es auf
      // leer damit beliebige Pfade unter assets/ funktionieren.
      game.images.prefix = '';

      Future<SpriteAnimation> _loadAnim(
          String dir, int count, double fps) async {
        final sprites = <Sprite>[];
        for (var i = 1; i <= count; i++) {
          final id = i.toString().padLeft(2, '0');
          final img = await game.images
              .load('assets/lumo_jump/fox/$dir/fox_${dir}_$id.png');
          sprites.add(Sprite(img));
        }
        return SpriteAnimation.spriteList(sprites, stepTime: 1.0 / fps);
      }

      final idle = await _loadAnim('idle', 8, 8);
      final run  = await _loadAnim('run', 12, 16);
      final jump = await _loadAnim('jump', 4, 10);
      final fall = await _loadAnim('fall', 4, 10);
      final duck = await _loadAnim('duck', 3, 6);
      final roll = await _loadAnim('roll', 8, 16);

      // Setze die echten Animationen
      animations = {
        FoxAnimationState.idle: idle,
        FoxAnimationState.run:  run,
        FoxAnimationState.jump: jump,
        FoxAnimationState.fall: fall,
        FoxAnimationState.duck: duck,
        FoxAnimationState.roll: roll,
      };
      _spritesLoaded = true;
      // Hitbox vergroessern - die echten Sprites sind 96x96 sichtbar
      size = Vector2(96, 96);
    } catch (e) {
      // Bei Ladefehler bleibt prozeduraler Fallback aktiv
      _spritesLoaded = false;
    }
  }

  /// Render: echte Sprites wenn geladen, sonst prozeduraler Fallback.
  @override
  void render(Canvas canvas) {
    if (_spritesLoaded) {
      // Flip horizontal wenn nach links schauend
      if (!facingRight) {
        canvas.save();
        canvas.translate(size.x, 0);
        canvas.scale(-1, 1);
        super.render(canvas);
        canvas.restore();
      } else {
        super.render(canvas);
      }
    } else {
      // Prozeduraler Fallback bis Sprites geladen sind
      FoxSprite.paint(
        canvas,
        rect:        Rect.fromLTWH(0, 0, _pW, _pH),
        state:       current ?? FoxAnimationState.idle,
        facingRight: facingRight,
        animTime:    game.totalTime,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updatePhysics(dt);
    _updateAnimState();
  }

  // ── Sprung-Tastendruck ────────────────────────────────────────────────

  void jump() => jumpBufTimer = _jumpBufferWin;

  void activateRoll() {
    if (current == FoxAnimationState.roll || !onGround) return;
    rollTimer = _rollDuration;
    HapticFeedback.lightImpact();
  }

  // ── Animations-Zustand ────────────────────────────────────────────────

  void _updateAnimState() {
    if (rollTimer > 0) {
      current = FoxAnimationState.roll;
    } else if (duckPressed) {
      current = FoxAnimationState.duck;
    } else if (!onGround) {
      current = vy > _fallThreshold
          ? FoxAnimationState.fall
          : FoxAnimationState.jump;
    } else if (vx.abs() > 0) {
      current = FoxAnimationState.run;
    } else {
      current = FoxAnimationState.idle;
    }
    size = Vector2(_pW, _pH);
  }

  // ── Physik-Update ─────────────────────────────────────────────────────

  void _updatePhysics(double dt) {
    if (rollTimer > 0) {
      rollTimer -= dt;
      if (rollTimer < 0) rollTimer = 0;
    }

    final spd = current == FoxAnimationState.roll
        ? _baseSpeed * _rollSpeedMult
        : duckPressed
            ? _duckSpeed
            : _baseSpeed;

    // Stick-Input (kontinuierlich, -1..1) hat Vorrang vor Button-Input.
    // Wenn beide null sind: vx = 0 (stehen bleiben).
    final double inputX;
    if (stickX.abs() > 0.05) {
      inputX = stickX.clamp(-1.0, 1.0);
    } else {
      inputX = ((rightPressed ? 1 : 0) - (leftPressed ? 1 : 0)).toDouble();
    }
    vx = inputX * spd;
    if (inputX > 0.05) facingRight = true;
    if (inputX < -0.05) facingRight = false;

    // Coyote + Jump-Buffer
    jumpBufTimer = math.max(0, jumpBufTimer - dt);
    coyoteTimer  =
        onGround ? _coyoteWindow : math.max(0, coyoteTimer - dt);

    // Sprung auslösen
    if (jumpBufTimer > 0 && (onGround || coyoteTimer > 0)) {
      vy           = -_jumpPower;
      onGround     = false;
      jumpBufTimer = 0;
      HapticFeedback.mediumImpact();
    }

    _moveX(dt);

    vy += _gravity * dt;
    vy  = vy.clamp(-1500.0, 1500.0);
    position.y += vy * dt;

    _checkJumpPads();
    _resolveVertical();
    _collectStars();
    _checkQuestionBlocks();
    _checkChest();
    _updateCrateWiggle();

    if (position.y > _fallResetY) _resetAfterFall();
    checkpointX = math.max(checkpointX, position.x);
  }

  void _moveX(double dt) {
    if (vx == 0) return;
    position.x += vx * dt;

    for (final obs in game.obstacles) {
      final or_ = Rect.fromLTWH(
          obs.position.x, obs.position.y, obs.size.x, obs.size.y);
      if (!worldRect.overlaps(or_)) continue;
      if (duckPressed && obs.requiresDuck) continue;
      if (vx > 0) {
        position.x = or_.left - _pW - 0.5;
      } else {
        position.x = or_.right + 0.5;
      }
      vx = 0;
    }

    for (final crate in game.crates) {
      if (!crate.active) continue;
      final cr = Rect.fromLTWH(
          crate.position.x, crate.position.y, crate.size.x, crate.size.y);
      if (!worldRect.overlaps(cr)) continue;
      if (current == FoxAnimationState.roll) {
        crate.breakCrate();
        game.sessionStars      += 3;
        game.totalEarnedStars  += 3;
        game.showHint('Kiste zerstört! +3 ⭐');
        continue;
      }
      if (vx > 0) {
        position.x = cr.left - _pW - 0.5;
      } else {
        position.x = cr.right + 0.5;
      }
      vx = 0;
    }

    position.x =
        position.x.clamp(0, game.worldWidth - _pW);
  }

  void _resolveVertical() {
    final rect   = worldRect;
    var   landed = false;

    for (final platform in game.platforms) {
      final p = Rect.fromLTWH(
          platform.position.x, platform.position.y,
          platform.size.x, platform.size.y);

      final hOvlp = rect.right > p.left + 6 && rect.left < p.right - 6;
      if (!hOvlp) continue;

      // Annäherung von oben (vorherige Position war oberhalb)
      final prevBottom = position.y + _pH - vy * (1.0 / 60);
      final wasAbove   = prevBottom <= p.top + 4;
      final nowPast    = rect.bottom >= p.top;

      if (vy >= 0 && wasAbove && nowPast) {
        position.y = p.top - _pH;
        vy         = 0;
        landed     = true;
      }
    }
    onGround = landed;
  }

  void _checkJumpPads() {
    if (vy < 0) return;
    final rect = worldRect;
    for (final pad in game.jumpPads) {
      final p = Rect.fromLTWH(
          pad.position.x, pad.position.y, pad.size.x, pad.size.y);
      final hOvlp = rect.right > p.left + 4 && rect.left < p.right - 4;
      if (!hOvlp) continue;
      if (rect.bottom >= p.top && vy >= 0) {
        position.y = p.top - _pH;
        vy         = -_jumpPower * _jumpPadBoost;
        onGround   = false;
        pad.activate();
        game.showHint('Sprungfeder! 🌀', sec: 1.2);
      }
    }
  }

  void _collectStars() {
    final center = Offset(worldRect.center.dx, worldRect.center.dy);
    for (final star in game.stars) {
      if (star.collected) continue;
      final sc = Offset(
          star.position.x + star.size.x / 2,
          star.position.y + star.size.y / 2);
      if ((center - sc).distance < _starRadius) game.collectStar(star);
    }
  }

  void _checkQuestionBlocks() {
    if (game.interactionLock) return;
    for (final block in game.questionBlocks) {
      if (block.cleared) continue;
      final br = Rect.fromLTWH(
          block.position.x, block.position.y,
          block.size.x, block.size.y);
      if (worldRect.overlaps(br.inflate(8))) {
        game.triggerQuestion(block);
        return;
      }
    }
  }

  void _checkChest() {
    if (game.interactionLock) return;
    if (game.chest.chestState != ChestState.closed) return;
    final cr = Rect.fromLTWH(
        game.chest.position.x, game.chest.position.y,
        game.chest.size.x, game.chest.size.y);
    if (worldRect.overlaps(cr.inflate(8))) game.triggerChest();
  }

  void _updateCrateWiggle() {
    final center = worldRect.center;
    for (final crate in game.crates) {
      if (!crate.active) continue;
      final cc = Offset(
          crate.position.x + crate.size.x / 2,
          crate.position.y + crate.size.y / 2);
      if ((center - cc).distance < 110) {
        crate.startWobble();
      } else {
        crate.stopWobble();
      }
    }
  }

  void _resetAfterFall() {
    final nearest = game.platforms
        .where((p) => p.position.x <= checkpointX + 50)
        .fold<PlatformTileComponent?>(null, (best, p) {
      if (best == null) return p;
      return (p.position.x - checkpointX).abs() <
              (best.position.x - checkpointX).abs()
          ? p
          : best;
    });

    if (nearest != null) {
      position = Vector2(
          nearest.position.x + 30, nearest.position.y - _pH);
    } else {
      position = Vector2(70, _baseGroundY - _pH);
    }
    vy = 0;
    vx = 0;
    game.showHint('Lumo versucht es nochmal! 🦊');
    HapticFeedback.heavyImpact();
  }
}

// ════════════════════════════════════════════════════════════════════════
// LERNAUFGABE – Datenklasse
// ════════════════════════════════════════════════════════════════════════

class LumoLearningTask {
  const LumoLearningTask({
    required this.prompt,
    required this.choices,
    required this.answer,
  });

  final String       prompt;
  final List<String> choices;
  final String       answer;
}

// ════════════════════════════════════════════════════════════════════════
// FLUTTER-SCREEN – Wrapper mit Flame-GameWidget, HUD und Steuerbuttons
// ════════════════════════════════════════════════════════════════════════

class LumoJumpFlameScreen extends StatefulWidget {
  const LumoJumpFlameScreen({
    super.key,
    required this.appState,
    required this.level,
  });

  final LumoAppState appState;
  final GameLevel    level;

  @override
  State<LumoJumpFlameScreen> createState() => _LumoJumpFlameScreenState();
}

class _LumoJumpFlameScreenState extends State<LumoJumpFlameScreen> {
  late LumoFlameJumpGame _game;
  bool _walletTransferred = false;

  @override
  void initState() {
    super.initState();
    _game = LumoFlameJumpGame(
      appState:        widget.appState,
      level:           widget.level,
      onQuestionNeeded: _showQuestion,
      onChestChallenge: _showChestChallenge,
      onLevelComplete:  _handleLevelComplete,
    );
  }

  @override
  void dispose() {
    _game.starsN.dispose();
    _game.hintN.dispose();
    _game.solvedN.dispose();
    _game.totalQN.dispose();
    super.dispose();
  }

  // ── Frageblock-Dialog ─────────────────────────────────────────────────

  Future<bool> _showQuestion(String title, LumoLearningTask task) async {
    var solved = false;
    await showModalBottomSheet<void>(
      context:         context,
      backgroundColor: Colors.transparent,
      isDismissible:   false,
      enableDrag:      false,
      builder: (ctx) => _QuestionSheet(
        title: title,
        task:  task,
        onSolved: (ok) {
          solved = ok;
          Navigator.of(ctx).pop();
        },
      ),
    );
    return solved;
  }

  // ── Boss-Truhen-Challenge ──────────────────────────────────────────────

  Future<bool> _showChestChallenge() async {
    var    opened   = false;
    var    streak   = 0;
    var    seed     = DateTime.now().millisecondsSinceEpoch;
    String feedback = 'Beantworte 3 Aufgaben hintereinander richtig.';
    LumoLearningTask task = _game.createMathTask(seed);

    await showDialog<void>(
      context:           context,
      barrierDismissible: false,
      builder: (ctx) {
        int? selected;
        return StatefulBuilder(
          builder: (ctx2, localSet) {
            Future<void> submit() async {
              if (selected == null) return;
              if (task.choices[selected!] == task.answer) {
                streak++;
                HapticFeedback.mediumImpact();
                if (streak >= 3) {
                  opened = true;
                  Navigator.of(ctx2).pop();
                  return;
                }
                final rem = 3 - streak;
                seed += 29;
                task = _game.createMathTask(seed);
                selected = null;
                localSet(() => feedback =
                    'Stark! Noch $rem ${rem == 1 ? "richtige Aufgabe" : "richtige Aufgaben"}.');
              } else {
                streak = 0;
                seed += 41;
                task = _game.createMathTask(seed);
                selected = null;
                localSet(
                    () => feedback = 'Fast! Wir starten die 3er-Serie neu.');
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFFFF7E6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('🔒 Boss-Truhe',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize:      MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Serie: $streak / 3',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(task.prompt,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    ...List.generate(task.choices.length, (i) {
                      final sel = selected == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => localSet(() => selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: sel ? LumoColors.orange : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: sel
                                      ? const Color(0xFFD97706)
                                      : LumoColors.ink100,
                                  width: 2),
                            ),
                            child: Text(task.choices[i],
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: sel
                                        ? Colors.white
                                        : LumoColors.ink900)),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(feedback,
                        style: const TextStyle(
                            color:      LumoColors.ink600,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: submit,
                    child: const Text('Antwort prüfen')),
              ],
            );
          },
        );
      },
    );
    return opened;
  }

  // ── Level-Abschluss ────────────────────────────────────────────────────

  void _handleLevelComplete(int totalStars, int levelStars) {
    _game.pauseEngine();
    showDialog<void>(
      context:           context,
      barrierDismissible: false,
      builder: (_) => _LevelCompleteDialog(
        totalStars: totalStars,
        levelStars: levelStars,
        onContinue: () {
          Navigator.of(context).pop();           // Dialog
          Navigator.of(context).pop(totalStars); // Game-Screen
        },
      ),
    );
  }

  // ── Abbruch-Bestätigung ────────────────────────────────────────────────

  Future<void> _confirmAbort() async {
    _game.pauseEngine();
    final quit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF7E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Spiel verlassen?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          _game.totalEarnedStars > 0
              ? 'Du hast bisher ${_game.totalEarnedStars} Sterne gesammelt.\nDiese werden gespeichert!'
              : 'Dein Fortschritt wird nicht gespeichert.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Weiterspielen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LumoColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verlassen',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (quit == true) {
      if (_game.totalEarnedStars > 0 && !_walletTransferred) {
        _walletTransferred = true;
        final st = widget.appState.state;
        widget.appState.update(st.copyWith(
          stars: st.stars + _game.totalEarnedStars,
          xp:    st.xp + _game.totalEarnedStars * 2,
        ));
      }
      if (mounted) Navigator.of(context).pop(_game.totalEarnedStars);
    } else {
      _game.resumeEngine();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHud(),
            Expanded(child: GameWidget(game: _game)),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────

  Widget _buildHud() {
    return Container(
      height:  52,
      color:   const Color(0xFFFFF7E6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon:        const Icon(Icons.close_rounded, size: 22),
            onPressed:   _confirmAbort,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
          // Sterne
          ValueListenableBuilder<int>(
            valueListenable: _game.starsN,
            builder: (_, v, __) => Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFCD34D), size: 20),
                const SizedBox(width: 4),
                Text('$v',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
          const Spacer(),
          // Frageblock-Fortschritt
          ValueListenableBuilder<int>(
            valueListenable: _game.solvedN,
            builder: (_, solved, __) =>
                ValueListenableBuilder<int>(
              valueListenable: _game.totalQN,
              builder: (_, total, __) => total > 0
                  ? Row(children: [
                      const Icon(Icons.help_outline_rounded,
                          color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 4),
                      Text('$solved/$total',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ])
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 8),
          // Status-Hinweis
          ValueListenableBuilder<String>(
            valueListenable: _game.hintN,
            builder: (_, hint, __) => hint.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        LumoColors.orange.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(hint,
                        style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w800,
                            color:      LumoColors.orange)),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Steuerbuttons - Joystick + Action-Buttons ─────────────────────────

  Widget _buildControls() {
    return Container(
      height: 180,
      color:  const Color(0xCC000000),
      child: Stack(
        children: [
          // Links: Virtual Joystick (kontinuierlich, bricht NICHT ab)
          Positioned(
            left:   24,
            bottom: 16,
            top:    16,
            child: _VirtualJoystick(
              onChanged: (vec) {
                _game.fox.stickX = vec.dx;
                _game.fox.duckPressed = vec.dy > 0.6;
              },
            ),
          ),
          // Rechts: Action-Buttons gestapelt (Jump oben, Roll unten)
          Positioned(
            right:  24,
            top:    16,
            bottom: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Jump - oben, gross, orange (wichtigste Action)
                _CircularActionButton(
                  size:    72,
                  color:   const Color(0xFFF97316),
                  label:   '▲',
                  onTap:   () => _game.fox.jump(),
                ),
                const SizedBox(height: 14),
                // Roll - unten, lila
                _CircularActionButton(
                  size:    60,
                  color:   const Color(0xFF7C3AED),
                  label:   '●',
                  onTap:   () => _game.fox.activateRoll(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Virtual Joystick - kontinuierliche Bewegung, bricht NICHT ab ────────

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({required this.onChanged});
  /// Liefert (dx, dy) im Bereich -1..1. (0,0) = Mittelstellung.
  final ValueChanged<Offset> onChanged;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  static const double _radius = 64;
  static const double _knobRadius = 30;
  /// Groessere unsichtbare HitArea damit der Finger nicht aus dem
  /// Joystick rutscht (200x200 statt 128x128).
  static const double _hitAreaSize = 200;
  /// Aktuelle Knob-Position relativ zum Mittelpunkt (-_radius..+_radius).
  Offset _knobOffset = Offset.zero;
  /// ID des aktiven Touch-Pointers. -1 = inaktiv. Verhindert Konflikt
  /// mit den Action-Buttons (Multi-Touch).
  int _activePointerId = -1;
  /// Mittelpunkt der HitArea (in lokalen Koordinaten).
  late Offset _center;

  void _updateFrom(Offset localPos) {
    var diff = localPos - _center;
    final dist = diff.distance;
    if (dist > _radius) {
      diff = diff * (_radius / dist);
    }
    setState(() => _knobOffset = diff);
    final norm = Offset(diff.dx / _radius, diff.dy / _radius);
    widget.onChanged(norm);
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
          // Nur erster Pointer zaehlt - weitere ignorieren
          if (_activePointerId != -1) return;
          _activePointerId = e.pointer;
          _updateFrom(e.localPosition);
        },
        onPointerMove: (e) {
          // Nur unser Pointer reagiert
          if (e.pointer != _activePointerId) return;
          _updateFrom(e.localPosition);
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
          painter: _JoystickPainter(
              knobOffset: _knobOffset,
              active: _activePointerId != -1,
              center: _center),
          size: const Size(_hitAreaSize, _hitAreaSize),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({
    required this.knobOffset,
    required this.active,
    required this.center,
  });
  final Offset knobOffset;
  final bool active;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    // Center kommt jetzt vom State - Listener-Bereich ist groesser
    // als die visuelle Basis. Visual = 128px Kreis um den center.
    // Aeusserer Ring (Basis)
    canvas.drawCircle(center, 64,
        Paint()..color = Colors.white.withOpacity(0.12));
    canvas.drawCircle(center, 64,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Richtungs-Hinweise (kleine Pfeile innen)
    final hintPaint = Paint()..color = Colors.white.withOpacity(0.35);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final c = center + Offset(math.cos(a) * 52, math.sin(a) * 52);
      canvas.drawCircle(c, 3, hintPaint);
    }
    // Knob (innerer Kreis)
    final knobCenter = center + knobOffset;
    canvas.drawCircle(knobCenter, 32,
        Paint()..color = Colors.black.withOpacity(0.3));
    canvas.drawCircle(knobCenter, 30,
        Paint()
          ..shader = RadialGradient(
            colors: active
                ? <Color>[
                    const Color(0xFFFCD34D),
                    const Color(0xFFF97316),
                  ]
                : <Color>[
                    Colors.white,
                    const Color(0xFFE5E7EB),
                  ],
          ).createShader(Rect.fromCircle(center: knobCenter, radius: 30)));
    canvas.drawCircle(knobCenter, 30,
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) =>
      old.knobOffset != knobOffset ||
      old.active != active ||
      old.center != center;
}

// ── Action-Button (rund, Premium-Stil wie auf Konsolen) ────────────────

class _CircularActionButton extends StatefulWidget {
  const _CircularActionButton({
    required this.size,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final double size;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  State<_CircularActionButton> createState() => _CircularActionButtonState();
}

class _CircularActionButtonState extends State<_CircularActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onPointerUp:     (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve:    Curves.easeOut,
        child: Container(
          width:  widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                Color.lerp(widget.color, Colors.white, 0.3)!,
                widget.color,
              ],
              stops: const <double>[0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color:     widget.color.withOpacity(0.5),
                blurRadius: 16,
                offset:    const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color:     Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset:    const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: widget.size * 0.45,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x60000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Spielknopf ────────────────────────────────────────────────────────

class _GameButton extends StatefulWidget {
  const _GameButton({
    this.icon,
    this.label,
    required this.onDown,
    required this.onUp,
    this.accent,
    this.large = false,
  });

  final IconData?    icon;
  final String?      label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final Color?       accent;
  final bool         large;

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? Colors.white;
    final sz    = widget.large ? 64.0 : 54.0;
    return GestureDetector(
      onTapDown:   (_) { setState(() => _pressed = true);  widget.onDown(); },
      onTapUp:     (_) { setState(() => _pressed = false); widget.onUp(); },
      onTapCancel: ()  { setState(() => _pressed = false); widget.onUp(); },
      child: Container(
        margin: const EdgeInsets.all(6),
        width: sz, height: sz,
        decoration: BoxDecoration(
          color:  _pressed
              ? color.withOpacity(0.88)
              : color.withOpacity(0.20),
          shape:  BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.55), width: 2),
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon, color: color, size: 22)
              : Text(widget.label ?? '',
                  style: TextStyle(
                      color:      color,
                      fontWeight: FontWeight.w900,
                      fontSize:   18)),
        ),
      ),
    );
  }
}

// ── Frage-Sheet ──────────────────────────────────────────────────────

class _QuestionSheet extends StatefulWidget {
  const _QuestionSheet({
    required this.title,
    required this.task,
    required this.onSolved,
  });

  final String           title;
  final LumoLearningTask task;
  final void Function(bool) onSolved;

  @override
  State<_QuestionSheet> createState() => _QuestionSheetState();
}

class _QuestionSheetState extends State<_QuestionSheet> {
  int?   _selected;
  String _feedback = 'Tippe auf die richtige Antwort.';

  void _submit() {
    if (_selected == null) return;
    if (widget.task.choices[_selected!] == widget.task.answer) {
      widget.onSolved(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _selected = null;
        _feedback = 'Noch nicht ganz – versuch es nochmal!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin:  const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color:        const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color:      Color(0x33000000),
                blurRadius: 18,
                offset:     Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Text(widget.task.prompt,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 12),
            ...List.generate(widget.task.choices.length, (i) {
              final sel = _selected == i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: sel ? LumoColors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFFD97706)
                              : LumoColors.ink100,
                          width: 2),
                    ),
                    child: Text(widget.task.choices[i],
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color:
                                sel ? Colors.white : LumoColors.ink900)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(_feedback,
                style: const TextStyle(
                    color:      LumoColors.ink600,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Antwort prüfen',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level-Abschluss-Dialog ────────────────────────────────────────────

class _LevelCompleteDialog extends StatelessWidget {
  const _LevelCompleteDialog({
    required this.totalStars,
    required this.levelStars,
    required this.onContinue,
  });

  final int          totalStars;
  final int          levelStars;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Level geschafft!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  3,
                  (i) => Icon(
                      i < levelStars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFCD34D),
                      size: 38)),
            ),
            const SizedBox(height: 8),
            Text('+$totalStars Sterne insgesamt',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Weiter',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level-Konfiguration (Schwierigkeitsgrad je nach level.id) ────────

/// Steuert wie das Spiel pro Level-ID erzeugt wird. Mit 10 Stufen.
/// - Hoehere Level: laenger, mehr Hindernisse, mehr Hoehenvariation,
///   Podeste (Sprung-Tuerme) und Tal-Sektionen.
class _LevelConfig {
  const _LevelConfig({
    required this.worldLength,
    required this.platformMinW,
    required this.platformMaxW,
    required this.yVariation,
    required this.minY,
    required this.maxY,
    required this.starsPerChunk,
    required this.questionBlockEveryN,
    required this.obstacleEveryN,
    required this.jumpPadEveryN,
    required this.gapMin,
    required this.gapMax,
    required this.includePodests,
    required this.podestStories,
    required this.includeValleys,
    required this.doubleObstacles,
  });

  final double worldLength;
  final int platformMinW;
  final int platformMaxW;
  final double yVariation;
  final double minY;
  final double maxY;
  final int starsPerChunk;
  final int questionBlockEveryN;
  final int obstacleEveryN;
  final int jumpPadEveryN;
  final int gapMin;
  final int gapMax;
  final bool includePodests;
  final int podestStories;
  final bool includeValleys;
  final bool doubleObstacles;

  /// Mappt eine beliebige Level-ID (1..50 aus dem Catalog) auf
  /// 10 Schwierigkeits-Stufen.
  factory _LevelConfig.forLevel(int levelId) {
    // Skaliere auf 1..10
    final stage = ((levelId - 1) % 10) + 1;
    return _stages[stage - 1];
  }

  static const List<_LevelConfig> _stages = <_LevelConfig>[
    // Level 1 - Tutorial: kurz, einfach, viel Platz
    _LevelConfig(
      worldLength: 4200,
      platformMinW: 320,
      platformMaxW: 440,
      yVariation: 18,
      minY: 240,
      maxY: 340,
      starsPerChunk: 2,
      questionBlockEveryN: 3,
      obstacleEveryN: 4,
      jumpPadEveryN: 7,
      gapMin: 60,
      gapMax: 110,
      includePodests: false,
      podestStories: 0,
      includeValleys: false,
      doubleObstacles: false,
    ),
    // Level 2 - Etwas mehr Hindernisse
    _LevelConfig(
      worldLength: 4800,
      platformMinW: 280,
      platformMaxW: 400,
      yVariation: 22,
      minY: 230,
      maxY: 340,
      starsPerChunk: 2,
      questionBlockEveryN: 3,
      obstacleEveryN: 3,
      jumpPadEveryN: 6,
      gapMin: 70,
      gapMax: 130,
      includePodests: false,
      podestStories: 0,
      includeValleys: false,
      doubleObstacles: false,
    ),
    // Level 3 - Mehr Hoehenvariation, erste Podeste
    _LevelConfig(
      worldLength: 5400,
      platformMinW: 260,
      platformMaxW: 380,
      yVariation: 26,
      minY: 220,
      maxY: 340,
      starsPerChunk: 2,
      questionBlockEveryN: 2,
      obstacleEveryN: 3,
      jumpPadEveryN: 5,
      gapMin: 80,
      gapMax: 140,
      includePodests: true,
      podestStories: 1,
      includeValleys: false,
      doubleObstacles: false,
    ),
    // Level 4 - 2-stoeckige Podeste
    _LevelConfig(
      worldLength: 6000,
      platformMinW: 240,
      platformMaxW: 360,
      yVariation: 28,
      minY: 210,
      maxY: 340,
      starsPerChunk: 3,
      questionBlockEveryN: 2,
      obstacleEveryN: 3,
      jumpPadEveryN: 5,
      gapMin: 80,
      gapMax: 150,
      includePodests: true,
      podestStories: 2,
      includeValleys: false,
      doubleObstacles: false,
    ),
    // Level 5 - Erste Tal-Sektionen, mehr Sterne
    _LevelConfig(
      worldLength: 6600,
      platformMinW: 240,
      platformMaxW: 340,
      yVariation: 32,
      minY: 200,
      maxY: 350,
      starsPerChunk: 3,
      questionBlockEveryN: 2,
      obstacleEveryN: 3,
      jumpPadEveryN: 4,
      gapMin: 90,
      gapMax: 160,
      includePodests: true,
      podestStories: 2,
      includeValleys: true,
      doubleObstacles: false,
    ),
    // Level 6 - Doppel-Hindernisse, taktischer
    _LevelConfig(
      worldLength: 7200,
      platformMinW: 220,
      platformMaxW: 320,
      yVariation: 34,
      minY: 200,
      maxY: 350,
      starsPerChunk: 3,
      questionBlockEveryN: 2,
      obstacleEveryN: 2,
      jumpPadEveryN: 4,
      gapMin: 100,
      gapMax: 170,
      includePodests: true,
      podestStories: 2,
      includeValleys: true,
      doubleObstacles: true,
    ),
    // Level 7 - 3-stoeckige Podeste, schmaler
    _LevelConfig(
      worldLength: 7800,
      platformMinW: 200,
      platformMaxW: 300,
      yVariation: 38,
      minY: 190,
      maxY: 360,
      starsPerChunk: 3,
      questionBlockEveryN: 2,
      obstacleEveryN: 2,
      jumpPadEveryN: 4,
      gapMin: 100,
      gapMax: 180,
      includePodests: true,
      podestStories: 3,
      includeValleys: true,
      doubleObstacles: true,
    ),
    // Level 8 - Lange Strecken, alles aktiv
    _LevelConfig(
      worldLength: 8400,
      platformMinW: 200,
      platformMaxW: 280,
      yVariation: 42,
      minY: 180,
      maxY: 360,
      starsPerChunk: 4,
      questionBlockEveryN: 2,
      obstacleEveryN: 2,
      jumpPadEveryN: 3,
      gapMin: 110,
      gapMax: 190,
      includePodests: true,
      podestStories: 3,
      includeValleys: true,
      doubleObstacles: true,
    ),
    // Level 9 - Pre-Boss
    _LevelConfig(
      worldLength: 9000,
      platformMinW: 190,
      platformMaxW: 260,
      yVariation: 44,
      minY: 170,
      maxY: 370,
      starsPerChunk: 4,
      questionBlockEveryN: 2,
      obstacleEveryN: 2,
      jumpPadEveryN: 3,
      gapMin: 120,
      gapMax: 200,
      includePodests: true,
      podestStories: 3,
      includeValleys: true,
      doubleObstacles: true,
    ),
    // Level 10 - BOSS-LEVEL: laengste Strecke, alles dabei
    _LevelConfig(
      worldLength: 10000,
      platformMinW: 180,
      platformMaxW: 250,
      yVariation: 48,
      minY: 160,
      maxY: 370,
      starsPerChunk: 5,
      questionBlockEveryN: 2,
      obstacleEveryN: 2,
      jumpPadEveryN: 3,
      gapMin: 120,
      gapMax: 200,
      includePodests: true,
      podestStories: 3,
      includeValleys: true,
      doubleObstacles: true,
    ),
  ];
}
