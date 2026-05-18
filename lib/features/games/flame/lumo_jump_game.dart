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

const double _gravity       = 1800;
const double _jumpPower     = 780;
const double _baseSpeed     = 230;
const double _duckSpeed     = 170;
const double _rollSpeedMult = 1.8;
const double _rollDuration  = 0.6;
const double _coyoteWindow  = 0.22;
const double _jumpBufferWin = 0.20;
const double _fallThreshold = 80;
const double _jumpPadBoost  = 1.55;
const double _baseGroundY   = 330.0;
const double _fallResetY    = 650.0;
const double _starRadius    = 22.0;
const double _maxSafeGap    = _baseSpeed * (_jumpPower / _gravity) * 2 * 0.85;

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
    final rng   = math.Random(_levelSeed);
    double x    = 0;
    double lastY = _baseGroundY;

    // Startplattform
    _addPlatform(x, lastY, 420, 120);
    x = 380;

    var chunk = 0;
    while (x < 5200) {
      final w  = (280 + rng.nextInt(170)).toDouble();
      final dy = (rng.nextInt(3) - 1) * 28.0;
      final y  = (lastY + dy).clamp(220.0, 338.0);

      _addPlatform(x, y, w, 90);

      // Sterne
      final sc = 2 + rng.nextInt(3);
      for (var i = 0; i < sc; i++) {
        final sx = x + 48 + i * ((w - 96) / math.max(1, sc - 1));
        final sy = y - 54 - (i.isEven ? 10.0 : 0.0);
        _addStar(sx, sy);
      }

      // Frageblock
      if (chunk % 2 == 1) {
        _addQuestionBlock(x + w * 0.55, y - 70, isGerman: chunk % 4 == 1);
      }

      // Hindernis oder Kiste
      if (chunk % 3 == 0) {
        final ox = x + w * 0.35;
        if (rng.nextBool()) {
          _addCrate(ox, y - 52);
        } else {
          final isDuck = rng.nextBool();
          _addObstacle(ox, y - (isDuck ? 36 : 52), 54,
              isDuck ? 36 : 52, isDuck);
        }
      }

      // Jump-Pad
      if (chunk % 5 == 2 && chunk > 0) {
        _addJumpPad(x + w * 0.5 - 20, y - 22);
      }

      lastY = y;
      final gap = (60 + rng.nextInt(80)).toDouble().clamp(50.0, _maxSafeGap);
      x    += w + gap;
      chunk++;
    }

    // Boss-Truhe
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
    _paintMountainLayer(canvas, s,
        offset: cx * 0.15,
        color:  const Color(0xFF86EFAC),
        hFrac:  0.28);
    _paintMountainLayer(canvas, s,
        offset: cx * 0.35,
        color:  const Color(0xFF22C55E),
        hFrac:  0.19);
  }

  void _paintSky(Canvas canvas, Vector2 s) {
    final rect = Rect.fromLTWH(0, 0, s.x, s.y);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE), Color(0xFFFEF3C7)],
            stops:  [0.0, 0.6, 1.0],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ).createShader(rect));

    // Sonne
    canvas.drawCircle(Offset(s.x * 0.88, s.y * 0.12), 28,
        Paint()..color = const Color(0xFFFCD34D));
    canvas.drawCircle(Offset(s.x * 0.88, s.y * 0.12), 20,
        Paint()..color = Colors.white.withOpacity(0.40));

    // animierte Wolken
    _paintCloud(canvas,
        s.x * 0.20 + math.sin(game.totalTime * 0.04) * 8, s.y * 0.14,
        55, 22);
    _paintCloud(canvas,
        s.x * 0.55 + math.sin(game.totalTime * 0.03 + 1) * 6, s.y * 0.10,
        70, 26);
    _paintCloud(canvas,
        s.x * 0.72 + math.cos(game.totalTime * 0.05) * 5, s.y * 0.18,
        48, 18);
  }

  void _paintCloud(Canvas canvas, double cx, double cy, double w, double h) {
    final p = Paint()..color = Colors.white.withOpacity(0.82);
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
  }

  /// Zeichnet eine Schicht sich wiederholender Berggipfel.
  void _paintMountainLayer(Canvas canvas, Vector2 s,
      {required double offset, required Color color, required double hFrac}) {
    const w   = 180.0;
    final h   = s.y * hFrac;
    final cnt = (s.x / w).ceil() + 2;
    final mod = offset % w;
    final paint = Paint()..color = color;
    for (var i = -1; i < cnt; i++) {
      final px = i * w - mod + w * 0.5;
      canvas.drawPath(
          Path()
            ..moveTo(px - w * 0.5, s.y)
            ..lineTo(px,           s.y - h)
            ..lineTo(px + w * 0.5, s.y)
            ..close(),
          paint);
    }
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

    // Erdkörper
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 4, w, h - 4), const Radius.circular(6)),
        Paint()..color = const Color(0xFF92400E));

    // Grasoberfläche
    canvas.drawRRect(
        RRect.fromLTRBR(0, 0, w, 16, const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, w, 16)));

    // dekorative Steine
    final rng = math.Random((position.x * 7 + position.y).round());
    for (var i = 0; i < (w / 60).floor(); i++) {
      final sx = 20 + i * 55 + rng.nextInt(25).toDouble();
      canvas.drawOval(
          Rect.fromCenter(center: Offset(sx, 8), width: 10, height: 5),
          Paint()..color = Colors.white.withOpacity(0.22));
    }
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
    final color =
        requiresDuck ? const Color(0xFF7C3AED) : const Color(0xFF0EA5E9);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8)),
        Paint()..color = color);
    canvas.drawRRect(
        RRect.fromLTRBR(4, 3, size.x - 4, 8, const Radius.circular(4)),
        Paint()..color = Colors.white.withOpacity(0.28));
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

    // Glow-Halo
    canvas.drawCircle(Offset(cx, cy), s * 1.15,
        Paint()..color = const Color(0xFFFCD34D).withOpacity(0.32));

    // Kreis-Body
    canvas.drawCircle(
        Offset(cx, cy),
        s * 0.88,
        Paint()
          ..shader = RadialGradient(
            colors: const [Color(0xFFFCD34D), Color(0xFFF59E0B)],
          ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: s)));

    // Innerer Stern (rotiert)
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
          Paint()..color = const Color(0xFFD1D5DB));
      return;
    }

    final t     = game.totalTime;
    final r     = Rect.fromLTWH(0, 0, size.x, size.y);
    final pulse = 0.5 + math.sin(t * 3) * 0.5;

    // Äußeres Glühen
    canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(12)),
        Paint()
          ..color = const Color(0xFFFCD34D).withOpacity(0.22 + pulse * 0.18));

    // Block
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()..color = const Color(0xFFF59E0B));
    canvas.drawRRect(
        RRect.fromLTRBR(3, 3, size.x - 3, 12, const Radius.circular(4)),
        Paint()..color = Colors.white.withOpacity(0.42));

    // Symbol
    final tp = TextPainter(
      text: TextSpan(
          text:  isGerman ? 'A' : '?',
          style: const TextStyle(
              fontSize:   28,
              fontWeight: FontWeight.w900,
              color:      Color(0xFF92400E))),
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
  double rollTimer    = 0;
  double coyoteTimer  = 0;
  double jumpBufTimer = 0;
  double checkpointX  = 70;
  bool   facingRight  = true;

  double get _pW => (duckPressed || current == FoxAnimationState.roll) ? 64 : 54;
  double get _pH => (duckPressed || current == FoxAnimationState.roll) ? 52 : 76;

  Rect get worldRect =>
      Rect.fromLTWH(position.x, position.y, _pW, _pH);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final anim = await _createPlaceholderAnim();
    animations  = {for (final s in FoxAnimationState.values) s: anim};
    current     = FoxAnimationState.idle;
  }

  /// Render überschreibt SpriteAnimationGroupComponent.render() vollständig
  /// und nutzt den prozeduralen FoxSprite-Painter.
  @override
  void render(Canvas canvas) {
    FoxSprite.paint(
      canvas,
      rect:        Rect.fromLTWH(0, 0, _pW, _pH),
      state:       current ?? FoxAnimationState.idle,
      facingRight: facingRight,
      animTime:    game.totalTime,
    );
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

    final dir = (rightPressed ? 1 : 0) - (leftPressed ? 1 : 0);
    vx = dir * spd;
    if (dir > 0) facingRight = true;
    if (dir < 0) facingRight = false;

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

  // ── Steuerbuttons ─────────────────────────────────────────────────────

  Widget _buildControls() {
    return Container(
      height: 100,
      color:  const Color(0xCC000000),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Links / Rechts
          Row(children: [
            _GameButton(
              icon:   Icons.arrow_back_ios_rounded,
              onDown: () => _game.fox.leftPressed  = true,
              onUp:   () => _game.fox.leftPressed  = false,
            ),
            _GameButton(
              icon:   Icons.arrow_forward_ios_rounded,
              onDown: () => _game.fox.rightPressed = true,
              onUp:   () => _game.fox.rightPressed = false,
            ),
          ]),
          // Ducken / Roll / Springen
          Row(children: [
            _GameButton(
              label:  'Duck',
              onDown: () => _game.fox.duckPressed = true,
              onUp:   () => _game.fox.duckPressed = false,
            ),
            const SizedBox(width: 8),
            _GameButton(
              label:  'Roll',
              onDown: () => _game.fox.activateRoll(),
              onUp:   () {},
              accent: LumoColors.purple,
            ),
            const SizedBox(width: 8),
            _GameButton(
              label:  '↑',
              onDown: () => _game.fox.jump(),
              onUp:   () {},
              accent: LumoColors.orange,
              large:  true,
            ),
          ]),
        ],
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
