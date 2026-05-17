import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../core/german_task_templates.dart';
import '../../../core/math_task_templates.dart';
import '../../../domain/games/game_level_model.dart';

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

class _LumoJumpAdventureGameState extends State<LumoJumpAdventureGame> {
  static const _repo = GameProgressRepository();

  static const double gravity = 1800;
  static const double jumpPower = 780;
  static const double moveSpeed = 230;
  static const double duckMoveSpeed = 170;
  static const double coyoteTimeWindow = 0.22;
  static const double jumpBufferWindow = 0.20;
  static const double coyoteExtensionFactor = 0.18;
  static const double starCollectionDistance = 26;

  static const double _worldHeight = 420;
  static const double _fallResetY = _worldHeight + 220;

  Timer? _loop;
  DateTime _lastTick = DateTime.now();

  final List<_Platform> _platforms = <_Platform>[];
  final List<_QuestionBlock> _questionBlocks = <_QuestionBlock>[];
  final List<_Obstacle> _obstacles = <_Obstacle>[];
  final List<_StarPickup> _stars = <_StarPickup>[];

  late _Chest _chest;
  late double _worldWidth;

  double _playerX = 70;
  double _playerY = 210;
  double _vx = 0;
  double _vy = 0;

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _duckPressed = false;
  bool _onGround = false;

  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;

  bool _paused = false;
  bool _interactionLock = false;
  bool _walletTransferred = false;

  int _sessionStars = 0;
  int _totalEarnedStars = 0;
  int _confettiTrigger = 0;
  String? _statusHint;

  double _checkpointX = 70;

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  int get _requiredBlockCount => _questionBlocks.length;
  int get _solvedBlockCount => _questionBlocks.where((b) => b.cleared).length;

  double get _playerWidth => _duckPressed ? 64 : 54;
  double get _playerHeight => _duckPressed ? 52 : 76;

  Rect get _playerRect => Rect.fromLTWH(_playerX, _playerY, _playerWidth, _playerHeight);

  double get _cameraX {
    final viewWidth = MediaQuery.sizeOf(context).width;
    final target = _playerX - viewWidth * 0.35;
    return target.clamp(0, math.max(0, _worldWidth - viewWidth));
  }

  @override
  void initState() {
    super.initState();
    _buildDailySeedLevel();
    _snapPlayerToStart();
    _startLoop();
  }

  void _buildDailySeedLevel() {
    final now = DateTime.now().toUtc();
    final daySeed = DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final generated = _generateLongLevel(daySeed + widget.level.id * 97);
    _platforms
      ..clear()
      ..addAll(generated.platforms);
    _questionBlocks
      ..clear()
      ..addAll(generated.questionBlocks);
    _obstacles
      ..clear()
      ..addAll(generated.obstacles);
    _stars
      ..clear()
      ..addAll(generated.stars);
    _worldWidth = generated.worldWidth;
    _chest = generated.chest;
  }

  _GeneratedLevel _generateLongLevel(int seed) {
    final random = math.Random(seed);
    final platforms = <_Platform>[];
    final stars = <_StarPickup>[];
    final obstacles = <_Obstacle>[];
    final questionBlocks = <_QuestionBlock>[];

    const baseGroundY = 330.0;
    double x = 0;
    double lastY = baseGroundY;

    platforms.add(_Platform(Rect.fromLTWH(0, baseGroundY, 420, 120)));
    x = 380;

    var chunk = 0;
    while (x < 5200) {
      final chunkWidth = 280 + random.nextInt(170);
      final heightDelta = (random.nextInt(3) - 1) * 28;
      final y = (lastY + heightDelta).clamp(220, 338).toDouble();
      final width = chunkWidth.toDouble();
      final rect = Rect.fromLTWH(x, y, width, 90);
      platforms.add(_Platform(rect));

      final starCount = 2 + random.nextInt(3);
      for (var i = 0; i < starCount; i++) {
        final sx = x + 48 + i * ((width - 96) / math.max(1, starCount - 1));
        final sy = y - 54 - (i.isEven ? 10 : 0);
        stars.add(_StarPickup(Offset(sx, sy)));
      }

      if (chunk % 2 == 1) {
        final blockX = x + width * 0.55;
        questionBlocks.add(_QuestionBlock(Rect.fromLTWH(blockX, y - 70, 62, 62), askGerman: chunk % 4 == 1));
      }

      if (chunk % 3 == 0) {
        final obsX = x + width * 0.35;
        final duckObstacle = random.nextBool();
        obstacles.add(
          _Obstacle(
            Rect.fromLTWH(obsX, y - (duckObstacle ? 36 : 52), 54, duckObstacle ? 36 : 52),
            requiresDuck: duckObstacle,
          ),
        );
      }

      lastY = y;
      x += width + 110;
      chunk++;
    }

    final chest = _Chest(Rect.fromLTWH(x + 120, lastY - 60, 74, 60));
    platforms.add(_Platform(Rect.fromLTWH(x, lastY, 320, 90)));
    return _GeneratedLevel(
      worldWidth: x + 700,
      platforms: platforms,
      stars: stars,
      obstacles: obstacles,
      questionBlocks: questionBlocks,
      chest: chest,
    );
  }

  void _snapPlayerToStart() {
    final first = _platforms.first.rect;
    _playerX = first.left + 44;
    _playerY = first.top - _playerHeight;
    _checkpointX = _playerX;
  }

  void _startLoop() {
    _lastTick = DateTime.now();
    _loop = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _paused) return;

    final now = DateTime.now();
    var dt = now.difference(_lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = now;
    dt = dt.clamp(0.0, 0.05);

    final direction = (_rightPressed ? 1 : 0) - (_leftPressed ? 1 : 0);
    final speed = _duckPressed ? duckMoveSpeed : moveSpeed;
    _vx = direction * speed;

    _jumpBufferTimer = math.max(0, _jumpBufferTimer - dt);
    _coyoteTimer = _onGround ? coyoteTimeWindow : math.max(0, _coyoteTimer - dt);

    _tryConsumeJump();

    final previousRect = _playerRect;

    _moveHorizontally(dt);

    _vy += gravity * dt;
    _vy = _vy.clamp(-1500, 1500);
    _playerY += _vy * dt;

    _resolveVertical(previousRect);
    _collectStars();
    _checkQuestionBlocks();
    _checkChest();

    if (_playerY > _fallResetY) {
      _resetAfterFall();
    }

    _checkpointX = math.max(_checkpointX, _playerX);

    setState(() {});
  }

  void _tryConsumeJump() {
    if (_jumpBufferTimer <= 0) return;
    if (!(_onGround || _coyoteTimer > 0)) return;

    final airTime = (_LumoJumpAdventureGameState.jumpPower.abs() / _LumoJumpAdventureGameState.gravity) * 2;

    _vy = -jumpPower;
    _onGround = false;
    _coyoteTimer = 0;
    _jumpBufferTimer = 0;
    _statusHint = null;
    _coyoteTimer = math.min(coyoteTimeWindow, airTime * coyoteExtensionFactor);
    HapticFeedback.mediumImpact();
  }

  void _moveHorizontally(double dt) {
    if (_vx == 0) return;
    _playerX += _vx * dt;

    final rect = _playerRect;
    for (final obstacle in _obstacles) {
      if (_duckPressed && obstacle.requiresDuck) {
        continue;
      }
      if (rect.overlaps(obstacle.rect)) {
        if (_vx > 0) {
          _playerX = obstacle.rect.left - _playerWidth - 0.5;
        } else {
          _playerX = obstacle.rect.right + 0.5;
        }
        _vx = 0;
      }
    }

    _playerX = _playerX.clamp(0, _worldWidth - _playerWidth);
  }

  void _resolveVertical(Rect previousRect) {
    var landed = false;
    final rect = _playerRect;

    for (final platform in _platforms) {
      final p = platform.rect;
      final horizontalOverlap = rect.right > p.left + 6 && rect.left < p.right - 6;
      if (!horizontalOverlap) continue;

      final wasAbove = previousRect.bottom <= p.top + 4;
      final nowPastTop = rect.bottom >= p.top;
      if (_vy >= 0 && wasAbove && nowPastTop) {
        _playerY = p.top - _playerHeight;
        _vy = 0;
        landed = true;
      }
    }

    _onGround = landed;
  }

  void _collectStars() {
    final rect = _playerRect.inflate(6);
    for (final star in _stars) {
      if (star.collected) continue;
      if ((rect.center - star.position).distance <= starCollectionDistance) {
        star.collected = true;
        star.scalePulse = 1.35;
        _sessionStars += 1;
        _totalEarnedStars += 1;
        _confettiTrigger++;
      } else if (star.scalePulse > 1.0) {
        star.scalePulse = math.max(1.0, star.scalePulse - 0.04);
      }
    }
  }

  void _checkQuestionBlocks() {
    if (_interactionLock || _paused) return;
    final rect = _playerRect;
    for (final block in _questionBlocks) {
      if (block.cleared) continue;
      if (rect.overlaps(block.rect.inflate(8))) {
        _interactionLock = true;
        _openQuestionBlockTask(block);
        return;
      }
    }
  }

  Future<void> _openQuestionBlockTask(_QuestionBlock block) async {
    _paused = true;
    final solved = await _showLearningTaskBottomSheet(
      title: block.askGerman ? 'Deutsch-Frageblock' : 'Mathe-Frageblock',
      makeTask: (seed) => block.askGerman ? _createGermanTask(seed) : _createMathTask(seed),
    );
    if (!mounted) return;

    if (solved) {
      setState(() {
        block.cleared = true;
        _sessionStars += 5;
        _totalEarnedStars += 5;
        _confettiTrigger++;
        _statusHint = 'Super! Frageblock geschafft (+5 ⭐)';
      });
    }

    _paused = false;
    _interactionLock = false;
  }

  void _checkChest() {
    if (_paused || _interactionLock || _chest.opened) return;
    if (_playerRect.overlaps(_chest.rect.inflate(8))) {
      _interactionLock = true;
      _openChestChallenge();
    }
  }

  Future<void> _openChestChallenge() async {
    if (_solvedBlockCount < _requiredBlockCount) {
      setState(() {
        _statusHint = 'Löse erst alle Frageblöcke (${_solvedBlockCount}/$_requiredBlockCount).';
      });
      _interactionLock = false;
      return;
    }

    _paused = true;
    var streak = 0;
    var seed = DateTime.now().millisecondsSinceEpoch;

    final opened = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int? selected;
        String feedback = 'Beantworte 3 Aufgaben hintereinander richtig.';
        _LearningTask task = _createMathTask(seed);

        return StatefulBuilder(
          builder: (context, localSetState) {
            Future<void> submit() async {
              if (selected == null) return;
              final answer = task.choices[selected!];
              if (answer == task.answer) {
                streak++;
                HapticFeedback.mediumImpact();
                if (streak >= 3) {
                  Navigator.of(context).pop(true);
                  return;
                }
                final remaining = 3 - streak;
                seed += 29;
                task = _createMathTask(seed);
                selected = null;
                localSetState(() => feedback = 'Stark! Noch $remaining ${remaining == 1 ? 'richtige Aufgabe' : 'richtige Aufgaben'}.');
              } else {
                streak = 0;
                seed += 41;
                task = _createMathTask(seed);
                selected = null;
                localSetState(() => feedback = 'Fast! Wir starten die 3er-Serie neu.');
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFFFF7E6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Boss-Truhe'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Serie: $streak / 3', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(task.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    ...List<Widget>.generate(task.choices.length, (i) {
                      final isSelected = selected == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => localSetState(() => selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected ? LumoColors.orange : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isSelected ? const Color(0xFFD97706) : LumoColors.ink100, width: 2),
                            ),
                            child: Text(
                              task.choices[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : LumoColors.ink900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(feedback, style: const TextStyle(color: LumoColors.ink600, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submit,
                  child: const Text('Antwort prüfen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (opened == true) {
      setState(() {
        _chest.opened = true;
        _sessionStars += 50;
        _totalEarnedStars += 50;
        _statusHint = 'Boss-Truhe geöffnet! +50 ⭐';
        _confettiTrigger += 2;
      });
      await _finishLevel();
      return;
    }

    _paused = false;
    _interactionLock = false;
  }

  Future<bool> _showLearningTaskBottomSheet({
    required String title,
    required _LearningTask Function(int seed) makeTask,
  }) async {
    var solved = false;
    final seed = DateTime.now().millisecondsSinceEpoch + _solvedBlockCount * 11;
    final task = makeTask(seed);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        int? selected;
        String feedback = 'Tippe auf die richtige Antwort.';

        return StatefulBuilder(
          builder: (context, localSetState) {
            void submit() {
              if (selected == null) return;
              final answer = task.choices[selected!];
              if (answer == task.answer) {
                solved = true;
                Navigator.of(context).pop();
                return;
              }
              HapticFeedback.heavyImpact();
              localSetState(() {
                selected = null;
                feedback = 'Noch nicht ganz. Versuch es nochmal!';
              });
            }

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(task.prompt, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                    const SizedBox(height: 12),
                    ...List<Widget>.generate(task.choices.length, (i) {
                      final selectedNow = selected == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => localSetState(() => selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: selectedNow ? LumoColors.orange : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selectedNow ? const Color(0xFFD97706) : LumoColors.ink100, width: 2),
                            ),
                            child: Text(
                              task.choices[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selectedNow ? Colors.white : LumoColors.ink900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(feedback, style: const TextStyle(color: LumoColors.ink600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LumoColors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Antwort prüfen', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return solved;
  }

  _LearningTask _createMathTask(int seed) {
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    final units = <String>['Plus bis 10', 'Minus bis 10', 'Mengenvergleich', 'Zahlenstrahl'];
    final unit = units[seed.abs() % units.length];
    final task = MathTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return _LearningTask(prompt: task.prompt, choices: task.choices, answer: task.answer);
  }

  _LearningTask _createGermanTask(int seed) {
    final grade = math.max(widget.level.gradeFloor, widget.appState.state.grade);
    final units = <String>['Anfangslaute', 'Endlaute', 'Silben', 'Wort-Bild-Zuordnung'];
    final unit = units[seed.abs() % units.length];
    final task = GermanTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return _LearningTask(prompt: task.prompt, choices: task.choices, answer: task.answer);
  }

  int _resultStars() {
    if (_chest.opened && _solvedBlockCount == _requiredBlockCount) return 3;
    if (_solvedBlockCount >= (_requiredBlockCount / 2).ceil()) return 2;
    if (_solvedBlockCount > 0) return 1;
    return 0;
  }

  Future<void> _finishLevel() async {
    final stars = _resultStars();

    await _repo.recordResult(
      childId: _childId,
      levelId: widget.level.id,
      starsEarned: stars,
    );

    if (!_walletTransferred) {
      _walletTransferred = true;
      final st = widget.appState.state;
      widget.appState.update(st.copyWith(
        stars: st.stars + _totalEarnedStars,
        xp: st.xp + (_totalEarnedStars * 2),
        mood: LumoMood.celebrate,
        lumoMessage: 'Lumo Jump geschafft!\n+$_totalEarnedStars Sterne',
      ));
    }

    if (!mounted) return;

    _paused = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Level geschafft!'),
        content: Text('Du hast $_totalEarnedStars Sterne gesammelt und $stars Level-Sterne erhalten.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Zurück zur Karte'),
          ),
        ],
      ),
    );
  }

  void _resetAfterFall() {
    final nearest = _platforms.where((p) => p.rect.left <= _checkpointX + 50).fold<_Platform?>(
          null,
          (best, next) => best == null || next.rect.left > best.rect.left ? next : best,
        ) ??
        _platforms.first;

    _playerX = nearest.rect.left + 20;
    _playerY = nearest.rect.top - _playerHeight;
    _vx = 0;
    _vy = 0;
    _onGround = true;
    _statusHint = 'Alles gut! Lumo startet wieder sicher.';
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lumo Jump Adventure',
          style: TextStyle(fontWeight: FontWeight.w900, color: LumoColors.ink900),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: LumoColors.ink700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _HudChip(label: 'Sterne: $_sessionStars', icon: Icons.star_rounded),
                  const SizedBox(width: 8),
                  _HudChip(label: 'Frageblöcke: $_solvedBlockCount/$_requiredBlockCount', icon: Icons.quiz_rounded),
                  const SizedBox(width: 8),
                  _HudChip(label: _chest.opened ? 'Truhe offen' : 'Boss-Truhe', icon: Icons.inventory_2_rounded),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LumoJumpPainter(
                          cameraX: _cameraX,
                          playerRect: _playerRect,
                          platforms: _platforms,
                          stars: _stars,
                          obstacles: _obstacles,
                          questionBlocks: _questionBlocks,
                          chest: _chest,
                          confettiTrigger: _confettiTrigger,
                        ),
                      ),
                    ),
                    if (_statusHint != null)
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusHint!,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: LumoColors.ink700),
                          ),
                        ),
                      ),
                    if (_paused)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: const Color(0x66000000),
                            alignment: Alignment.center,
                            child: const Text(
                              'Aufgabe läuft…',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  _holdButton(
                    icon: Icons.arrow_left_rounded,
                    onDown: () => setState(() => _leftPressed = true),
                    onUp: () => setState(() => _leftPressed = false),
                  ),
                  const SizedBox(width: 10),
                  _holdButton(
                    icon: Icons.arrow_right_rounded,
                    onDown: () => setState(() => _rightPressed = true),
                    onUp: () => setState(() => _rightPressed = false),
                  ),
                  const SizedBox(width: 10),
                  _holdButton(
                    icon: Icons.keyboard_double_arrow_down_rounded,
                    onDown: () => setState(() => _duckPressed = true),
                    onUp: () => setState(() => _duckPressed = false),
                    label: 'Ducken',
                  ),
                  const Spacer(),
                  _holdButton(
                    icon: Icons.arrow_upward_rounded,
                    onDown: () {
                      _jumpBufferTimer = jumpBufferWindow;
                    },
                    onUp: () {},
                    label: 'Springen',
                    color: const Color(0xFFFB923C),
                  ),
                ],
              ),
            ),
            if (_chest.opened)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finishLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LumoColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Level abschließen', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _holdButton({
    required IconData icon,
    required VoidCallback onDown,
    required VoidCallback onUp,
    String? label,
    Color color = const Color(0xFF2563EB),
  }) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: label == null
            ? Icon(icon, color: Colors.white, size: 36)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 30),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: LumoColors.ink700),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: LumoColors.ink800)),
        ],
      ),
    );
  }
}

class _LumoJumpPainter extends CustomPainter {
  const _LumoJumpPainter({
    required this.cameraX,
    required this.playerRect,
    required this.platforms,
    required this.stars,
    required this.obstacles,
    required this.questionBlocks,
    required this.chest,
    required this.confettiTrigger,
  });

  final double cameraX;
  final Rect playerRect;
  final List<_Platform> platforms;
  final List<_StarPickup> stars;
  final List<_Obstacle> obstacles;
  final List<_QuestionBlock> questionBlocks;
  final _Chest chest;
  final int confettiTrigger;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFA7F3D0), Color(0xFFBFDBFE), Color(0xFFFDE68A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    canvas.save();
    canvas.translate(-cameraX, 0);

    final platformPaint = Paint()..color = const Color(0xFF22C55E);
    for (final platform in platforms) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(platform.rect, const Radius.circular(10)),
        platformPaint,
      );
    }

    for (final obstacle in obstacles) {
      final paint = Paint()..color = obstacle.requiresDuck ? const Color(0xFF7C3AED) : const Color(0xFF0EA5E9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(obstacle.rect, const Radius.circular(8)),
        paint,
      );
    }

    for (final block in questionBlocks) {
      if (block.cleared) continue;
      final paint = Paint()..color = const Color(0xFFF59E0B);
      canvas.drawRRect(RRect.fromRectAndRadius(block.rect, const Radius.circular(8)), paint);
      final tp = TextPainter(
        text: const TextSpan(text: '?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(block.rect.center.dx - tp.width / 2, block.rect.center.dy - tp.height / 2));
    }

    for (final star in stars) {
      if (star.collected) continue;
      final s = 10 * star.scalePulse;
      final path = Path()
        ..moveTo(star.position.dx, star.position.dy - s)
        ..lineTo(star.position.dx + s * 0.35, star.position.dy - s * 0.2)
        ..lineTo(star.position.dx + s, star.position.dy - s * 0.1)
        ..lineTo(star.position.dx + s * 0.5, star.position.dy + s * 0.25)
        ..lineTo(star.position.dx + s * 0.65, star.position.dy + s)
        ..lineTo(star.position.dx, star.position.dy + s * 0.55)
        ..lineTo(star.position.dx - s * 0.65, star.position.dy + s)
        ..lineTo(star.position.dx - s * 0.5, star.position.dy + s * 0.25)
        ..lineTo(star.position.dx - s, star.position.dy - s * 0.1)
        ..lineTo(star.position.dx - s * 0.35, star.position.dy - s * 0.2)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFACC15));
    }

    final chestPaint = Paint()..color = chest.opened ? const Color(0xFF10B981) : const Color(0xFF92400E);
    canvas.drawRRect(RRect.fromRectAndRadius(chest.rect, const Radius.circular(8)), chestPaint);

    final foxBody = Paint()..color = const Color(0xFFF97316);
    canvas.drawRRect(RRect.fromRectAndRadius(playerRect, const Radius.circular(10)), foxBody);
    canvas.drawCircle(Offset(playerRect.left + playerRect.width * 0.30, playerRect.top + 18), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(playerRect.left + playerRect.width * 0.70, playerRect.top + 18), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(playerRect.left + playerRect.width * 0.30, playerRect.top + 18), 2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(playerRect.left + playerRect.width * 0.70, playerRect.top + 18), 2, Paint()..color = Colors.black);

    if (confettiTrigger > 0) {
      final confetti = Paint()..color = const Color(0x99FFFFFF);
      for (var i = 0; i < 14; i++) {
        final dx = playerRect.center.dx + math.sin(i.toDouble()) * 36;
        final dy = playerRect.top - 12 - (i % 4) * 5;
        canvas.drawCircle(Offset(dx, dy), 2.4, confetti);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LumoJumpPainter oldDelegate) {
    final oldClearedBlocks = oldDelegate.questionBlocks.where((b) => b.cleared).length;
    final newClearedBlocks = questionBlocks.where((b) => b.cleared).length;
    final oldCollectedStars = oldDelegate.stars.where((s) => s.collected).length;
    final newCollectedStars = stars.where((s) => s.collected).length;

    return oldDelegate.cameraX != cameraX ||
        oldDelegate.playerRect != playerRect ||
        oldDelegate.confettiTrigger != confettiTrigger ||
        oldClearedBlocks != newClearedBlocks ||
        oldCollectedStars != newCollectedStars ||
        oldDelegate.chest.opened != chest.opened;
  }
}

class _GeneratedLevel {
  const _GeneratedLevel({
    required this.worldWidth,
    required this.platforms,
    required this.stars,
    required this.obstacles,
    required this.questionBlocks,
    required this.chest,
  });

  final double worldWidth;
  final List<_Platform> platforms;
  final List<_StarPickup> stars;
  final List<_Obstacle> obstacles;
  final List<_QuestionBlock> questionBlocks;
  final _Chest chest;
}

class _Platform {
  const _Platform(this.rect);
  final Rect rect;
}

class _Obstacle {
  const _Obstacle(this.rect, {required this.requiresDuck});
  final Rect rect;
  final bool requiresDuck;
}

class _QuestionBlock {
  _QuestionBlock(this.rect, {required this.askGerman});
  final Rect rect;
  final bool askGerman;
  bool cleared = false;
}

class _StarPickup {
  _StarPickup(this.position);
  final Offset position;
  bool collected = false;
  double scalePulse = 1.0;
}

class _Chest {
  _Chest(this.rect);
  final Rect rect;
  bool opened = false;
}

class _LearningTask {
  const _LearningTask({required this.prompt, required this.choices, required this.answer});
  final String prompt;
  final List<String> choices;
  final String answer;
}
