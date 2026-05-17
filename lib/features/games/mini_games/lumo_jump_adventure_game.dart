import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../core/math_task_templates.dart';
import '../../../domain/games/game_level_model.dart';

class LumoJumpPhysicsConfig {
  const LumoJumpPhysicsConfig._();

  static const double grid = 64;
  static const double playerWidth = 64;
  static const double playerHeight = 64;
  static const double crouchHeight = 40;
  static const double rollHeight = 36;
  static const double runSpeed = 228;
  static const double jumpVelocity = -505;
  static const double gravity = 1280;
  static const double coyoteTimeSeconds = 0.18;
  static const double jumpBufferSeconds = 0.20;
  static const double maxSafeJumpDistance = grid * 2.5;
  static const double minimumDuckClearance = 44;
  static const double groundTop = 380;
  static const double worldHeight = 540;
}

enum LumoJumpObstacleType {
  puddle,
  lowBranch,
  rollingLog,
}

class LumoJumpChunk {
  const LumoJumpChunk({
    required this.index,
    required this.startX,
    required this.endX,
    required this.requiredJumpDistance,
    required this.requiredDuckClearance,
    required this.hasQuestionBlock,
  });

  final int index;
  final double startX;
  final double endX;
  final double requiredJumpDistance;
  final double requiredDuckClearance;
  final bool hasQuestionBlock;

  bool get isSolvable =>
      requiredJumpDistance <= LumoJumpPhysicsConfig.maxSafeJumpDistance &&
      requiredDuckClearance >= LumoJumpPhysicsConfig.minimumDuckClearance;
}

class LumoJumpPlatformData {
  const LumoJumpPlatformData({required this.rect});

  final Rect rect;
}

class LumoJumpObstacleData {
  const LumoJumpObstacleData({
    required this.rect,
    required this.type,
  });

  final Rect rect;
  final LumoJumpObstacleType type;
}

class LumoJumpStarData {
  const LumoJumpStarData({required this.rect});

  final Rect rect;
}

class LumoJumpQuestionBlockData {
  const LumoJumpQuestionBlockData({
    required this.rect,
    required this.seed,
  });

  final Rect rect;
  final int seed;
}

class LumoJumpLevelData {
  const LumoJumpLevelData({
    required this.seed,
    required this.length,
    required this.platforms,
    required this.obstacles,
    required this.stars,
    required this.questionBlocks,
    required this.chestRect,
    required this.chunks,
  });

  final int seed;
  final double length;
  final List<LumoJumpPlatformData> platforms;
  final List<LumoJumpObstacleData> obstacles;
  final List<LumoJumpStarData> stars;
  final List<LumoJumpQuestionBlockData> questionBlocks;
  final Rect chestRect;
  final List<LumoJumpChunk> chunks;
}

int lumoJumpDailySeed([DateTime? now]) {
  final current = (now ?? DateTime.now()).toUtc();
  final startOfYear = DateTime.utc(current.year, 1, 1);
  final dayOfYear = current.difference(startOfYear).inDays + 1;
  return current.year * 1000 + dayOfYear;
}

LumoJumpLevelData generateLumoJumpAdventureLevel({
  required int seed,
  int chunkCount = 14,
}) {
  final random = math.Random(seed);
  final grid = LumoJumpPhysicsConfig.grid;
  final chunkWidth = grid * 4;
  final groundTop = LumoJumpPhysicsConfig.groundTop;

  final platforms = _PlatformPool(chunkCount * 4 + 8)..reset();
  final obstacles = _ObstaclePool(chunkCount * 2 + 6)..reset();
  final stars = _StarPool(chunkCount * 4 + 24)..reset();
  final questionBlocks = _QuestionBlockPool(4)..reset();
  final chunks = <LumoJumpChunk>[];

  double addArc(double startX, double baseY, int count) {
    for (var i = 0; i < count; i++) {
      final wave = math.sin((i / math.max(1, count - 1)) * math.pi);
      final x = startX + i * (grid * 0.7);
      final y = baseY - 24 - (wave * 42);
      stars.add(Rect.fromLTWH(x, y, grid * 0.5, grid * 0.5));
    }
    return startX + count * (grid * 0.7);
  }

  platforms.add(Rect.fromLTWH(0, groundTop, grid * 3, grid * 2.2));
  var cursor = grid * 3;
  final questionChunkIndices = <int>{2, 6, 10};

  for (var index = 0; index < chunkCount; index++) {
    final chunkStart = cursor;
    final chunkEnd = chunkStart + chunkWidth;
    platforms.add(Rect.fromLTWH(chunkStart, groundTop, chunkWidth, grid * 2.2));

    final variant = random.nextInt(3);
    var jumpDistance = 0.0;
    var duckClearance = grid;
    final hasQuestionBlock = questionChunkIndices.contains(index);

    if (variant == 0) {
      final puddleX = chunkStart + grid * 1.8;
      final puddleWidth = grid;
      obstacles.add(
        Rect.fromLTWH(
          puddleX,
          groundTop + grid * 0.88,
          puddleWidth,
          grid * 0.32,
        ),
        LumoJumpObstacleType.puddle,
      );
      addArc(puddleX - grid * 0.2, groundTop - grid * 0.9, 3);
      jumpDistance = puddleWidth;
    } else if (variant == 1) {
      final branchX = chunkStart + grid * 1.6;
      obstacles.add(
        Rect.fromLTWH(
          branchX,
          groundTop - grid * 0.92,
          grid * 1.3,
          grid * 0.42,
        ),
        LumoJumpObstacleType.lowBranch,
      );
      addArc(branchX + grid * 0.1, groundTop - grid * 0.55, 2);
      duckClearance = grid * 0.7;
    } else {
      final logX = chunkStart + grid * 1.9;
      obstacles.add(
        Rect.fromLTWH(
          logX,
          groundTop + grid * 0.55,
          grid * 1.15,
          grid * 0.5,
        ),
        LumoJumpObstacleType.rollingLog,
      );
      addArc(logX - grid * 0.1, groundTop - grid * 0.7, 3);
      jumpDistance = grid * 1.15;
    }

    if (hasQuestionBlock) {
      final platformX = chunkStart + grid * 1.55;
      final platformY = groundTop - grid * 1.55;
      platforms.add(Rect.fromLTWH(platformX, platformY, grid * 2, grid * 0.38));
      questionBlocks.add(
        Rect.fromLTWH(platformX + grid * 0.6, platformY - grid * 0.85, grid * 0.8, grid * 0.8),
        seed + index * 137,
      );
      addArc(chunkStart + grid * 0.9, platformY - grid * 0.35, 4);
      jumpDistance = math.max(jumpDistance, grid * 1.25);
    }

    chunks.add(LumoJumpChunk(
      index: index,
      startX: chunkStart,
      endX: chunkEnd,
      requiredJumpDistance: jumpDistance,
      requiredDuckClearance: duckClearance,
      hasQuestionBlock: hasQuestionBlock,
    ));

    cursor = chunkEnd;
  }

  final finishStart = cursor;
  platforms.add(Rect.fromLTWH(finishStart, groundTop, grid * 5, grid * 2.2));
  addArc(finishStart + grid * 0.8, groundTop - grid * 0.9, 5);
  final chestRect = Rect.fromLTWH(
    finishStart + grid * 2.8,
    groundTop - grid * 0.95,
    grid,
    grid * 0.95,
  );

  return LumoJumpLevelData(
    seed: seed,
    length: finishStart + grid * 5,
    platforms: platforms.snapshot(),
    obstacles: obstacles.snapshot(),
    stars: stars.snapshot(),
    questionBlocks: questionBlocks.snapshot(),
    chestRect: chestRect,
    chunks: List<LumoJumpChunk>.unmodifiable(chunks),
  );
}

class LumoJumpAdventureGame extends StatefulWidget {
  const LumoJumpAdventureGame({
    super.key,
    required this.appState,
    required this.level,
  });

  final LumoAppState appState;
  final GameLevel level;

  @override
  State<LumoJumpAdventureGame> createState() => _LumoJumpAdventureGameState();
}

class _LumoJumpAdventureGameState extends State<LumoJumpAdventureGame>
    with SingleTickerProviderStateMixin {
  static const _repo = GameProgressRepository();

  final ValueNotifier<int> _frameTick = ValueNotifier<int>(0);
  late final Ticker _ticker;
  late final LumoJumpLevelData _levelData;
  late final _JumpWorld _world;
  late final List<MathConcreteTask> _bossTasks;

  Duration? _lastTick;
  bool _jumpQueued = false;
  bool _duckHeld = false;
  _QuestionOverlayState? _questionOverlay;
  _BossOverlayState? _bossOverlay;
  bool _completed = false;
  int _pathStarsCollected = 0;
  int _walletStarsEarned = 0;

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  bool get _paused => _questionOverlay != null || _bossOverlay != null || _completed;

  @override
  void initState() {
    super.initState();
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    _levelData = generateLumoJumpAdventureLevel(seed: lumoJumpDailySeed());
    _world = _JumpWorld(level: _levelData);
    _bossTasks = List<MathConcreteTask>.generate(3, (index) {
      return MathTaskTemplates.generate(
        grade: grade,
        unit: _unitForLevel(widget.level),
        seed: _levelData.seed + 500 + index * 29,
      );
    });
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameTick.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null) return;
    final dt = ((elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond)
        .clamp(0.0, 1 / 30)
        .toDouble();
    _world.update(
      dt: dt,
      jumpQueued: _jumpQueued,
      duckHeld: _duckHeld,
      paused: _paused,
    );
    _jumpQueued = false;
    _processWorldEvents();
    _frameTick.value++;
  }

  void _processWorldEvents() {
    if (_questionOverlay != null || _bossOverlay != null || _completed) return;
    for (final star in _world.stars.where((star) => star.active && !star.collected)) {
      if (_world.playerRect.overlaps(star.rect)) {
        star.collected = true;
        star.sparkTimer = 0.35;
        _pathStarsCollected++;
        HapticFeedback.selectionClick();
      }
    }

    for (final block in _world.questionBlocks.where((block) => block.active && !block.solved)) {
      if (_world.playerRect.center.dx >= block.rect.center.dx - 6) {
        _world.pauseMomentum();
        setState(() {
          _questionOverlay = _QuestionOverlayState(
            block: block,
            task: _buildQuestionTask(block.seed),
          );
        });
        return;
      }
    }

    if (!_completed && _bossOverlay == null && !_world.chestOpened) {
      final triggerRect = _levelData.chestRect.inflate(12);
      if (_world.playerRect.overlaps(triggerRect)) {
        _world.pauseMomentum();
        setState(() {
          _bossOverlay = _BossOverlayState(tasks: _bossTasks);
        });
      }
    }
  }

  MathConcreteTask _buildQuestionTask(int seed) {
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    return MathTaskTemplates.generate(
      grade: grade,
      unit: _unitForLevel(widget.level),
      seed: seed,
    );
  }

  String _unitForLevel(GameLevel level) {
    final title = level.title.toLowerCase();
    if (title.contains('minus')) return 'Minus bis 10';
    if (title.contains('20')) return 'Plus bis 20';
    return 'Plus bis 10';
  }

  void _queueJump() {
    HapticFeedback.lightImpact();
    _jumpQueued = true;
  }

  void _startDuckHold() {
    HapticFeedback.selectionClick();
    _duckHeld = true;
    _world.requestRoll();
  }

  void _endDuckHold() {
    _duckHeld = false;
  }

  Future<void> _applyWalletReward(int stars, String source) async {
    if (stars <= 0) return;
    _walletStarsEarned += stars;
    widget.appState.awardEarnedStars(
      stars,
      message: 'Lumo hat $stars Sterne aus $source gesammelt! ⭐',
    );
  }

  Future<void> _completeAdventure() async {
    if (_completed) return;
    final solvedBlocks = _world.questionBlocks.where((block) => block.solved).length;
    final catalogStars = solvedBlocks >= _world.questionBlocks.length
        ? 3
        : solvedBlocks >= 2
            ? 2
            : 1;
    await _repo.recordResult(
      childId: _childId,
      levelId: widget.level.id,
      starsEarned: catalogStars,
    );
    if (!mounted) return;
    setState(() {
      _completed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: LumoColors.ink700),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Lumo Jump Adventure',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: LumoColors.ink900,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
          child: Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _frameTick,
                builder: (_, __, ___) => _AdventureHeader(
                  pathStarsCollected: _pathStarsCollected,
                  walletStarsEarned: _walletStarsEarned,
                  questionBlocksSolved:
                      _world.questionBlocks.where((block) => block.solved).length,
                  totalQuestionBlocks: _world.questionBlocks.length,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LumoRadius.xl),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFFBAF0FF),
                        Color(0xFFE9FFF4),
                        Color(0xFFFFF9D7),
                      ],
                    ),
                    boxShadow: LumoShadow.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(LumoRadius.xl),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ValueListenableBuilder<int>(
                            valueListenable: _frameTick,
                            builder: (_, __, ___) {
                              return CustomPaint(
                                painter: _LumoJumpPainter(world: _world),
                              );
                            },
                          ),
                        ),
                        if (_questionOverlay != null)
                          Positioned.fill(
                            child: _TaskOverlayCard(
                              key: ValueKey<String>('question_${_questionOverlay!.block.seed}'),
                              title: 'Frageblock',
                              subtitle: '5 Sterne für Lumos Wallet',
                              task: _questionOverlay!.task,
                              progressLabel: 'Block geschafft? Dann geht es weiter!',
                              onSolved: () async {
                                final block = _questionOverlay!.block;
                                block.solved = true;
                                block.active = false;
                                await _applyWalletReward(5, 'dem Frageblock');
                                if (!mounted) return;
                                setState(() {
                                  _questionOverlay = null;
                                });
                              },
                              onClose: () {
                                setState(() {
                                  _questionOverlay = null;
                                });
                              },
                            ),
                          ),
                        if (_bossOverlay != null)
                          Positioned.fill(
                            child: _TaskOverlayCard(
                              key: ValueKey<String>('boss_${_bossOverlay!.currentIndex}'),
                              title: 'Boss-Truhe',
                              subtitle: '3 richtige Aufgaben in Folge für 50 Sterne',
                              task: _bossOverlay!.tasks[_bossOverlay!.currentIndex],
                              progressLabel:
                                  'Serie: ${_bossOverlay!.currentIndex}/3 richtig in Folge',
                              resetOnWrong: true,
                              onSolved: () async {
                                final next = _bossOverlay!.currentIndex + 1;
                                if (next < _bossOverlay!.tasks.length) {
                                  setState(() {
                                    _bossOverlay = _bossOverlay!.copyWith(currentIndex: next);
                                  });
                                  return;
                                }
                                _world.chestOpened = true;
                                await _applyWalletReward(50, 'der Boss-Truhe');
                                if (!mounted) return;
                                setState(() {
                                  _bossOverlay = null;
                                });
                                await _completeAdventure();
                              },
                              onWrong: () {
                                setState(() {
                                  _bossOverlay = _bossOverlay!.copyWith(currentIndex: 0);
                                });
                              },
                              onClose: () {},
                              dismissible: false,
                            ),
                          ),
                        if (_completed)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.26),
                              alignment: Alignment.center,
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(LumoRadius.xl),
                                  boxShadow: LumoShadow.success,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Die Truhe ist offen! 🎉',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 28,
                                        color: LumoColors.ink900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Lumo hat $_walletStarsEarned Wallet-Sterne und $_pathStarsCollected Wegsterne gesammelt.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: LumoColors.ink600,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Zur Spielewelt'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00A6A6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _queueJump,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      label: const Text('Springen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) => _startDuckHold(),
                      onTapUp: (_) => _endDuckHold(),
                      onTapCancel: _endDuckHold,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(LumoRadius.pill),
                          boxShadow: LumoShadow.pill,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard_double_arrow_down_rounded,
                                color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Ducken / Rollen',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdventureHeader extends StatelessWidget {
  const _AdventureHeader({
    required this.pathStarsCollected,
    required this.walletStarsEarned,
    required this.questionBlocksSolved,
    required this.totalQuestionBlocks,
  });

  final int pathStarsCollected;
  final int walletStarsEarned;
  final int questionBlocksSolved;
  final int totalQuestionBlocks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeaderPill(
            color: const Color(0xFFFFB800),
            label: 'Wegsterne',
            value: '$pathStarsCollected',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeaderPill(
            color: const Color(0xFFFF7A2F),
            label: 'Wallet',
            value: '$walletStarsEarned',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeaderPill(
            color: const Color(0xFF8B5CF6),
            label: 'Blöcke',
            value: '$questionBlocksSolved/$totalQuestionBlocks',
          ),
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: Colors.white.withOpacity(0.88)),
        boxShadow: LumoShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: LumoColors.ink500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskOverlayCard extends StatefulWidget {
  const _TaskOverlayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.task,
    required this.progressLabel,
    required this.onSolved,
    required this.onClose,
    this.onWrong,
    this.resetOnWrong = false,
    this.dismissible = true,
  });

  final String title;
  final String subtitle;
  final MathConcreteTask task;
  final String progressLabel;
  final Future<void> Function() onSolved;
  final VoidCallback onClose;
  final VoidCallback? onWrong;
  final bool resetOnWrong;
  final bool dismissible;

  @override
  State<_TaskOverlayCard> createState() => _TaskOverlayCardState();
}

class _TaskOverlayCardState extends State<_TaskOverlayCard> {
  int? _selectedIndex;
  bool _revealed = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withOpacity(0.22),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LumoRadius.xl),
            boxShadow: LumoShadow.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: LumoColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: LumoColors.ink600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.progressLabel,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: LumoColors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.task.prompt,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: LumoColors.ink900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              ...List<Widget>.generate(widget.task.choices.length, (index) {
                final choice = widget.task.choices[index];
                final selected = _selectedIndex == index;
                final isCorrect = choice == widget.task.answer;
                var background = Colors.white;
                var border = LumoColors.ink100;
                var foreground = LumoColors.ink900;
                if (_revealed) {
                  if (isCorrect) {
                    background = const Color(0xFF10B981);
                    border = const Color(0xFF059669);
                    foreground = Colors.white;
                  } else if (selected) {
                    background = const Color(0xFFFED7AA);
                    border = const Color(0xFFEA580C);
                    foreground = const Color(0xFF7C2D12);
                  }
                } else if (selected) {
                  background = const Color(0xFFFFE0CC);
                  border = LumoColors.orange;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(LumoRadius.lg),
                    onTap: _revealed ? null : () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(LumoRadius.lg),
                        border: Border.all(color: border, width: 2),
                      ),
                      child: Text(
                        choice,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_revealed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    widget.task.explanation,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: LumoColors.ink600,
                      height: 1.35,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.dismissible)
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text('Weiterlaufen'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_revealed ? 'Weiter' : 'Pruefen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedIndex == null || _submitting) return;
    final selected = widget.task.choices[_selectedIndex!];
    final isCorrect = selected == widget.task.answer;
    if (!_revealed) {
      setState(() {
        _revealed = true;
      });
      if (!isCorrect && widget.resetOnWrong) {
        widget.onWrong?.call();
      }
      return;
    }
    if (!isCorrect) {
      setState(() {
        _revealed = false;
        _selectedIndex = null;
      });
      return;
    }
    setState(() {
      _submitting = true;
    });
    await widget.onSolved();
  }
}

class _QuestionOverlayState {
  const _QuestionOverlayState({
    required this.block,
    required this.task,
  });

  final _QuestionBlockState block;
  final MathConcreteTask task;
}

class _BossOverlayState {
  const _BossOverlayState({
    required this.tasks,
    this.currentIndex = 0,
  });

  final List<MathConcreteTask> tasks;
  final int currentIndex;

  _BossOverlayState copyWith({int? currentIndex}) {
    return _BossOverlayState(
      tasks: tasks,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class _JumpWorld {
  _JumpWorld({required LumoJumpLevelData level})
      : level = level,
        platforms = level.platforms
            .map((entry) => _PlatformState(rect: entry.rect))
            .toList(growable: false),
        obstacles = level.obstacles
            .map((entry) => _ObstacleState(rect: entry.rect, type: entry.type))
            .toList(growable: false),
        stars = level.stars
            .map((entry) => _StarState(rect: entry.rect))
            .toList(growable: false),
        questionBlocks = level.questionBlocks
            .map((entry) => _QuestionBlockState(rect: entry.rect, seed: entry.seed))
            .toList(growable: false),
        playerX = LumoJumpPhysicsConfig.grid,
        playerY = LumoJumpPhysicsConfig.groundTop - LumoJumpPhysicsConfig.playerHeight;

  final LumoJumpLevelData level;
  final List<_PlatformState> platforms;
  final List<_ObstacleState> obstacles;
  final List<_StarState> stars;
  final List<_QuestionBlockState> questionBlocks;

  double playerX;
  double playerY;
  double velocityY = 0;
  double coyoteTimer = 0;
  double jumpBuffer = 0;
  double rollTimer = 0;
  double animationTime = 0;
  double cameraX = 0;
  bool grounded = true;
  bool chestOpened = false;

  Rect get playerRect {
    final height = rollTimer > 0
        ? LumoJumpPhysicsConfig.rollHeight
        : _ducking
            ? LumoJumpPhysicsConfig.crouchHeight
            : LumoJumpPhysicsConfig.playerHeight;
    return Rect.fromLTWH(
      playerX,
      playerY + (LumoJumpPhysicsConfig.playerHeight - height),
      LumoJumpPhysicsConfig.playerWidth,
      height,
    );
  }

  bool get _ducking => rollTimer <= 0 && _duckHeldInternal;
  bool _duckHeldInternal = false;

  void pauseMomentum() {
    jumpBuffer = 0;
  }

  void requestRoll() {
    if (grounded) {
      rollTimer = math.max(rollTimer, 0.34);
    }
  }

  void update({
    required double dt,
    required bool jumpQueued,
    required bool duckHeld,
    required bool paused,
  }) {
    animationTime += dt;
    _duckHeldInternal = duckHeld;
    for (final star in stars.where((star) => star.sparkTimer > 0)) {
      star.sparkTimer = math.max(0, star.sparkTimer - dt);
    }
    if (paused) return;

    if (jumpQueued) {
      jumpBuffer = LumoJumpPhysicsConfig.jumpBufferSeconds;
    } else {
      jumpBuffer = math.max(0, jumpBuffer - dt);
    }

    if (grounded) {
      coyoteTimer = LumoJumpPhysicsConfig.coyoteTimeSeconds;
    } else {
      coyoteTimer = math.max(0, coyoteTimer - dt);
    }

    if (rollTimer > 0) {
      rollTimer = math.max(0, rollTimer - dt);
    }

    if (jumpBuffer > 0 && (grounded || coyoteTimer > 0)) {
      velocityY = LumoJumpPhysicsConfig.jumpVelocity;
      grounded = false;
      jumpBuffer = 0;
      coyoteTimer = 0;
    }

    final previousRect = playerRect;
    playerX += LumoJumpPhysicsConfig.runSpeed * dt;
    velocityY += LumoJumpPhysicsConfig.gravity * dt;
    playerY += velocityY * dt;

    final landing = _findLandingPlatform(previousRect);
    if (landing != null) {
      playerY = landing.rect.top - LumoJumpPhysicsConfig.playerHeight;
      velocityY = 0;
      grounded = true;
    } else {
      grounded = false;
    }

    final currentRect = playerRect;
    for (final obstacle in obstacles.where((entry) => entry.active)) {
      if (!currentRect.overlaps(obstacle.rect)) continue;
      final allowsPass = switch (obstacle.type) {
        LumoJumpObstacleType.puddle => currentRect.bottom <= obstacle.rect.top + 10,
        LumoJumpObstacleType.lowBranch => currentRect.height <= LumoJumpPhysicsConfig.crouchHeight,
        LumoJumpObstacleType.rollingLog => currentRect.bottom <= obstacle.rect.top + 8,
      };
      if (!allowsPass) {
        playerX = obstacle.rect.left - LumoJumpPhysicsConfig.playerWidth - 6;
        break;
      }
    }

    cameraX = (playerX - 180)
        .clamp(0.0, math.max(0.0, level.length - 640))
        .toDouble();
  }

  _PlatformState? _findLandingPlatform(Rect previousRect) {
    final currentRect = playerRect;
    _PlatformState? best;
    for (final platform in platforms) {
      final horizontallyOverlapping =
          currentRect.right > platform.rect.left + 8 &&
              currentRect.left < platform.rect.right - 8;
      final crossedTop =
          previousRect.bottom <= platform.rect.top + 6 && currentRect.bottom >= platform.rect.top;
      if (horizontallyOverlapping && crossedTop) {
        best = platform;
      }
    }
    if (best != null) return best;
    if (playerY >= LumoJumpPhysicsConfig.groundTop - LumoJumpPhysicsConfig.playerHeight) {
      return _PlatformState(
        rect: Rect.fromLTWH(
          0,
          LumoJumpPhysicsConfig.groundTop,
          level.length,
          LumoJumpPhysicsConfig.grid * 2.2,
        ),
      );
    }
    return null;
  }
}

class _PlatformState {
  const _PlatformState({required this.rect});

  final Rect rect;
}

class _ObstacleState {
  const _ObstacleState({required this.rect, required this.type}) : active = true;

  final Rect rect;
  final LumoJumpObstacleType type;
  final bool active;
}

class _StarState {
  _StarState({required this.rect});

  final Rect rect;
  bool active = true;
  bool collected = false;
  double sparkTimer = 0;
}

class _QuestionBlockState {
  _QuestionBlockState({required this.rect, required this.seed});

  final Rect rect;
  final int seed;
  bool active = true;
  bool solved = false;
}

class _LumoJumpPainter extends CustomPainter {
  const _LumoJumpPainter({required this.world});

  final _JumpWorld world;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 640;
    final scaleY = size.height / LumoJumpPhysicsConfig.worldHeight;
    final scale = math.min(scaleX, scaleY);
    final paintSize = Size(640 * scale, LumoJumpPhysicsConfig.worldHeight * scale);
    final offset = Offset((size.width - paintSize.width) / 2, (size.height - paintSize.height) / 2);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale, scale);
    _paintScene(canvas, const Size(640, LumoJumpPhysicsConfig.worldHeight));
    canvas.restore();
  }

  void _paintScene(Canvas canvas, Size size) {
    final skyPaint = Paint()..color = const Color(0xFFBAF0FF);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final sunPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawCircle(const Offset(92, 92), 34, sunPaint);

    final hillPaint = Paint()..color = const Color(0xFFA7F3D0);
    canvas.drawOval(const Rect.fromLTWH(-80 - world.cameraX * 0.2, 278, 320, 180), hillPaint);
    canvas.drawOval(const Rect.fromLTWH(180 - world.cameraX * 0.22, 290, 360, 160), hillPaint);
    canvas.drawOval(const Rect.fromLTWH(430 - world.cameraX * 0.25, 286, 300, 172), hillPaint);

    canvas.save();
    canvas.translate(-world.cameraX, 0);

    for (final platform in world.platforms) {
      final rect = platform.rect;
      final fill = Paint()..color = const Color(0xFF6CC070);
      final top = Paint()..color = const Color(0xFF9BE27A);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top, rect.width, math.min(rect.height, 18).toDouble()),
          const Radius.circular(18),
        ),
        top,
      );
    }

    for (final obstacle in world.obstacles) {
      final rect = obstacle.rect;
      switch (obstacle.type) {
        case LumoJumpObstacleType.puddle:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(18)),
            Paint()..color = const Color(0xFF5DB7FF),
          );
          canvas.drawOval(
            Rect.fromLTWH(rect.left + 10, rect.top + 4, rect.width - 20, rect.height - 8),
            Paint()..color = const Color(0xFFADE8FF),
          );
        case LumoJumpObstacleType.lowBranch:
          final branch = Paint()..color = const Color(0xFF8B5A2B);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(14)),
            branch,
          );
          canvas.drawCircle(
            Offset(rect.left + 18, rect.top + rect.height / 2),
            12,
            Paint()..color = const Color(0xFF34D399),
          );
          canvas.drawCircle(
            Offset(rect.right - 18, rect.top + rect.height / 2 - 6),
            14,
            Paint()..color = const Color(0xFF22C55E),
          );
        case LumoJumpObstacleType.rollingLog:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(20)),
            Paint()..color = const Color(0xFF9A6B3A),
          );
          canvas.drawCircle(
            Offset(rect.left + 10, rect.center.dy),
            8,
            Paint()..color = const Color(0xFFD9A66A),
          );
          canvas.drawCircle(
            Offset(rect.right - 10, rect.center.dy),
            8,
            Paint()..color = const Color(0xFFD9A66A),
          );
      }
    }

    for (final block in world.questionBlocks.where((entry) => entry.active)) {
      final rect = block.rect;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()..color = block.solved ? const Color(0xFF10B981) : const Color(0xFFFFB800),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: block.solved ? Colors.white : const Color(0xFF7C2D12),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2),
      );
    }

    for (final star in world.stars.where((entry) => entry.active && !entry.collected)) {
      _drawStar(canvas, star.rect.center, 16 + math.sin(world.animationTime * 8) * 2, const Color(0xFFFFD166));
    }
    for (final star in world.stars.where((entry) => entry.sparkTimer > 0)) {
      final t = star.sparkTimer / 0.35;
      final sparkPaint = Paint()..color = const Color(0xFFFFF3B0).withOpacity(t.clamp(0.0, 1.0).toDouble());
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        canvas.drawCircle(
          star.rect.center + Offset(math.cos(angle), math.sin(angle)) * (22 * (1 - t)),
          4 * t,
          sparkPaint,
        );
      }
    }

    _drawChest(canvas, world.level.chestRect, world.chestOpened);
    _drawLumo(canvas, world.playerRect, world);
    canvas.restore();
  }

  void _drawChest(Canvas canvas, Rect rect, bool opened) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = opened ? const Color(0xFF22C55E) : const Color(0xFFB45309),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.36),
        const Radius.circular(16),
      ),
      Paint()..color = opened ? const Color(0xFF86EFAC) : const Color(0xFFF59E0B),
    );
    canvas.drawCircle(rect.center, 8, Paint()..color = Colors.white);
  }

  void _drawLumo(Canvas canvas, Rect rect, _JumpWorld world) {
    final body = Paint()..color = const Color(0xFFFF7A2F);
    final cream = Paint()..color = const Color(0xFFFFF7E8);
    final ear = Paint()..color = const Color(0xFF7C2D12);

    canvas.save();
    if (world.rollTimer > 0) {
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(world.animationTime * 10);
      canvas.translate(-rect.center.dx, -rect.center.dy);
    }

    canvas.drawOval(rect, body);
    canvas.drawOval(
      Rect.fromLTWH(rect.left + rect.width * 0.26, rect.top + rect.height * 0.22,
          rect.width * 0.5, rect.height * 0.5),
      cream,
    );

    final leftEar = Path()
      ..moveTo(rect.left + rect.width * 0.18, rect.top + rect.height * 0.2)
      ..lineTo(rect.left + rect.width * 0.30, rect.top - rect.height * 0.08)
      ..lineTo(rect.left + rect.width * 0.42, rect.top + rect.height * 0.22)
      ..close();
    final rightEar = Path()
      ..moveTo(rect.right - rect.width * 0.18, rect.top + rect.height * 0.2)
      ..lineTo(rect.right - rect.width * 0.30, rect.top - rect.height * 0.08)
      ..lineTo(rect.right - rect.width * 0.42, rect.top + rect.height * 0.22)
      ..close();
    canvas.drawPath(leftEar, body);
    canvas.drawPath(rightEar, body);
    canvas.drawPath(leftEar.shift(const Offset(0, 4)), ear);
    canvas.drawPath(rightEar.shift(const Offset(0, 4)), ear);

    final eyePaint = Paint()..color = const Color(0xFF1F1713);
    canvas.drawCircle(Offset(rect.left + rect.width * 0.36, rect.top + rect.height * 0.42), 3.4, eyePaint);
    canvas.drawCircle(Offset(rect.right - rect.width * 0.36, rect.top + rect.height * 0.42), 3.4, eyePaint);
    canvas.drawCircle(Offset(rect.center.dx, rect.top + rect.height * 0.55), 4.2, eyePaint);

    final tail = Path()
      ..moveTo(rect.right - 6, rect.top + rect.height * 0.65)
      ..quadraticBezierTo(rect.right + 22, rect.top + rect.height * 0.28,
          rect.right + 34, rect.top + rect.height * 0.62)
      ..quadraticBezierTo(rect.right + 18, rect.top + rect.height * 0.76,
          rect.right + 4, rect.top + rect.height * 0.72)
      ..close();
    canvas.drawPath(tail, body);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * 0.45;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LumoJumpPainter oldDelegate) => true;
}

class _PlatformPool {
  _PlatformPool(int size)
      : _entries = List<_PlatformMutable>.generate(size, (_) => _PlatformMutable());

  final List<_PlatformMutable> _entries;
  int _cursor = 0;

  void reset() {
    _cursor = 0;
    for (final entry in _entries) {
      entry.rect = Rect.zero;
      entry.active = false;
    }
  }

  void add(Rect rect) {
    final entry = _entries[_cursor++];
    entry.rect = rect;
    entry.active = true;
  }

  List<LumoJumpPlatformData> snapshot() => List<LumoJumpPlatformData>.unmodifiable(
        _entries
            .where((entry) => entry.active)
            .map((entry) => LumoJumpPlatformData(rect: entry.rect)),
      );
}

class _ObstaclePool {
  _ObstaclePool(int size)
      : _entries = List<_ObstacleMutable>.generate(size, (_) => _ObstacleMutable());

  final List<_ObstacleMutable> _entries;
  int _cursor = 0;

  void reset() {
    _cursor = 0;
    for (final entry in _entries) {
      entry.rect = Rect.zero;
      entry.active = false;
      entry.type = LumoJumpObstacleType.puddle;
    }
  }

  void add(Rect rect, LumoJumpObstacleType type) {
    final entry = _entries[_cursor++];
    entry.rect = rect;
    entry.type = type;
    entry.active = true;
  }

  List<LumoJumpObstacleData> snapshot() => List<LumoJumpObstacleData>.unmodifiable(
        _entries.where((entry) => entry.active).map(
              (entry) => LumoJumpObstacleData(rect: entry.rect, type: entry.type),
            ),
      );
}

class _StarPool {
  _StarPool(int size) : _entries = List<_StarMutable>.generate(size, (_) => _StarMutable());

  final List<_StarMutable> _entries;
  int _cursor = 0;

  void reset() {
    _cursor = 0;
    for (final entry in _entries) {
      entry.rect = Rect.zero;
      entry.active = false;
    }
  }

  void add(Rect rect) {
    final entry = _entries[_cursor++];
    entry.rect = rect;
    entry.active = true;
  }

  List<LumoJumpStarData> snapshot() => List<LumoJumpStarData>.unmodifiable(
        _entries.where((entry) => entry.active).map((entry) => LumoJumpStarData(rect: entry.rect)),
      );
}

class _QuestionBlockPool {
  _QuestionBlockPool(int size)
      : _entries = List<_QuestionBlockMutable>.generate(size, (_) => _QuestionBlockMutable());

  final List<_QuestionBlockMutable> _entries;
  int _cursor = 0;

  void reset() {
    _cursor = 0;
    for (final entry in _entries) {
      entry.rect = Rect.zero;
      entry.active = false;
      entry.seed = 0;
    }
  }

  void add(Rect rect, int seed) {
    final entry = _entries[_cursor++];
    entry.rect = rect;
    entry.seed = seed;
    entry.active = true;
  }

  List<LumoJumpQuestionBlockData> snapshot() =>
      List<LumoJumpQuestionBlockData>.unmodifiable(
        _entries.where((entry) => entry.active).map(
              (entry) => LumoJumpQuestionBlockData(rect: entry.rect, seed: entry.seed),
            ),
      );
}

class _PlatformMutable {
  Rect rect = Rect.zero;
  bool active = false;
}

class _ObstacleMutable {
  Rect rect = Rect.zero;
  LumoJumpObstacleType type = LumoJumpObstacleType.puddle;
  bool active = false;
}

class _StarMutable {
  Rect rect = Rect.zero;
  bool active = false;
}

class _QuestionBlockMutable {
  Rect rect = Rect.zero;
  int seed = 0;
  bool active = false;
}
