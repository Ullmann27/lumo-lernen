import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/game_progress_repository.dart';
import '../../../core/german_task_templates.dart';
import '../../../core/math_task_templates.dart';
import '../../../domain/games/game_level_model.dart';

/// Spieler-Zustand für Animations- und Mechanik-Logik.
enum _PlayerState { idle, running, jumping, ducking, rolling }

/// Hindernistypen – normales Hindernis oder zerstörbare Kiste.
enum _GameObjectType { obstacle, breakableCrate }

/// Lumo Jump Adventure – Side-Scroller mit 60-FPS-Ticker-Engine,
/// echtem Delta-Time, Roll-/Dash-Mechanik und mathematisch
/// garantierten Sprüngen (Spelunky-Algorithmus).
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

  // ── Physik-Konstanten ──────────────────────────────────────────
  static const double gravity = 1800;
  static const double jumpPower = 780;
  static const double _baseSpeed = 230;
  static const double duckMoveSpeed = 170;
  static const double coyoteTimeWindow = 0.22;
  static const double jumpBufferWindow = 0.20;
  static const double coyoteExtensionFactor = 0.18;
  static const double starCollectionDistance = 26;

  // ── Roll/Dash-Konstanten ──────────────────────────────────────
  static const double _rollDuration = 0.6;
  static const double _rollSpeedMultiplier = 1.8;

  // ── Welt-Konstanten ───────────────────────────────────────────
  static const double _worldHeight = 420;
  static const double _fallResetY = _worldHeight + 220;

  /// Maximale sichere Lücke in Pixeln basierend auf Spieler-Physik.
  /// airTime = 2 * (jumpPower / gravity); maxDist = _baseSpeed * airTime.
  static const double _maxSafeGap =
      _baseSpeed * (jumpPower / gravity) * 2 * 0.85;

  // ── 60-FPS Ticker-Engine ──────────────────────────────────────
  late final Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // ── Spielwelt-Objekte ─────────────────────────────────────────
  final List<_Platform> _platforms = <_Platform>[];
  final List<_QuestionBlock> _questionBlocks = <_QuestionBlock>[];
  final List<_Obstacle> _obstacles = <_Obstacle>[];
  final List<_StarPickup> _stars = <_StarPickup>[];
  late _Chest _chest;
  late double _worldWidth;

  // ── Spieler-Zustand ───────────────────────────────────────────
  double _playerX = 70;
  double _playerY = 210;
  double _vx = 0;
  double _vy = 0;

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _duckPressed = false;
  bool _onGround = false;

  _PlayerState _playerState = _PlayerState.idle;
  double _rollTimer = 0;

  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;

  // ── Session-Zustand ───────────────────────────────────────────
  bool _paused = false;
  bool _interactionLock = false;
  bool _walletTransferred = false;

  int _sessionStars = 0;
  int _totalEarnedStars = 0;
  int _confettiTrigger = 0;
  String? _statusHint;

  double _checkpointX = 70;

  // ── Hilfsfunktionen ───────────────────────────────────────────
  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty
        ? 'kind'
        : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  int get _requiredBlockCount => _questionBlocks.length;
  int get _solvedBlockCount => _questionBlocks.where((b) => b.cleared).length;

  double get _playerWidth =>
      (_duckPressed || _playerState == _PlayerState.rolling) ? 64 : 54;
  double get _playerHeight =>
      (_duckPressed || _playerState == _PlayerState.rolling) ? 52 : 76;

  Rect get _playerRect =>
      Rect.fromLTWH(_playerX, _playerY, _playerWidth, _playerHeight);

  double get _cameraX {
    final viewWidth = MediaQuery.sizeOf(context).width;
    final target = _playerX - viewWidth * 0.35;
    return target.clamp(0, math.max(0, _worldWidth - viewWidth));
  }

  /// Spelunky-Garantie: Prüft, ob Lumo eine Lücke mit einem vollen
  /// Sprung überwinden kann. Gibt `false` zurück, wenn die Lücke zu
  /// groß ist – der Level-Generator nutzt dies zur Validierung.
  static bool isJumpLogicallyPossible(double gapWidth) {
    const double airTime = (jumpPower / gravity) * 2;
    const double maxDistance = _baseSpeed * airTime;
    return gapWidth <= maxDistance * 0.85; // 15 % Sicherheitsreserve
  }

  // ── Initialisierung ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _buildDailySeedLevel();
    _snapPlayerToStart();
    _ticker = createTicker(_onTick)..start();
  }

  // ── 60-FPS Game-Loop mit echter Delta-Time ────────────────────
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    // Ersten Frame überspringen (kein Delta berechenbar)
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    if (_paused) {
      _lastTime = elapsed;
      return;
    }
    // Echte Delta-Time in Sekunden – gleicht Framerate-Schwankungen aus
    final double dt =
        ((elapsed - _lastTime).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastTime = elapsed;
    _update(dt);
  }

  void _update(double dt) {
    _updatePlayerState(dt);

    // Geschwindigkeit abhängig vom Spielerzustand
    final double speed;
    switch (_playerState) {
      case _PlayerState.rolling:
        speed = _baseSpeed * _rollSpeedMultiplier;
      case _PlayerState.ducking:
        speed = duckMoveSpeed;
      default:
        speed = _baseSpeed;
    }

    final direction = (_rightPressed ? 1 : 0) - (_leftPressed ? 1 : 0);
    _vx = direction * speed;

    _jumpBufferTimer = math.max(0, _jumpBufferTimer - dt);
    _coyoteTimer =
        _onGround ? coyoteTimeWindow : math.max(0, _coyoteTimer - dt);

    _tryConsumeJump();

    final previousRect = _playerRect;

    _moveHorizontally(dt);

    // Gravitation mit Delta-Time multipliziert
    _vy += gravity * dt;
    _vy = _vy.clamp(-1500.0, 1500.0);
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

  void _updatePlayerState(double dt) {
    // Roll läuft: Timer herunterzählen
    if (_playerState == _PlayerState.rolling) {
      _rollTimer -= dt;
      if (_rollTimer <= 0) {
        _playerState = _PlayerState.idle;
        _rollTimer = 0;
      }
      return;
    }

    // Normale Zustandsübergänge
    if (_duckPressed) {
      _playerState = _PlayerState.ducking;
    } else if (!_onGround) {
      _playerState = _PlayerState.jumping;
    } else if (_vx.abs() > 0) {
      _playerState = _PlayerState.running;
    } else {
      _playerState = _PlayerState.idle;
    }
  }

  /// Aktiviert den Roll/Dash für 0,6 Sekunden.
  void _activateRoll() {
    if (_playerState == _PlayerState.rolling) return; // bereits aktiv
    if (!_onGround) return; // nur am Boden rollen
    _playerState = _PlayerState.rolling;
    _rollTimer = _rollDuration;
    HapticFeedback.lightImpact();
  }

  void _tryConsumeJump() {
    if (_jumpBufferTimer <= 0) return;
    if (!(_onGround || _coyoteTimer > 0)) return;

    _vy = -jumpPower;
    _onGround = false;
    _jumpBufferTimer = 0;
    _statusHint = null;
    _coyoteTimer = math.min(
        coyoteTimeWindow, (jumpPower / gravity) * 2 * coyoteExtensionFactor);
    HapticFeedback.mediumImpact();
  }

  void _moveHorizontally(double dt) {
    if (_vx == 0) return;
    _playerX += _vx * dt;

    final rect = _playerRect;
    for (final obstacle in _obstacles) {
      if (!obstacle.active) continue;

      // Ducken ermöglicht Durchrutschen unter niedrigen Hindernissen
      if (_duckPressed && obstacle.requiresDuck) continue;

      if (!rect.overlaps(obstacle.rect)) continue;

      // ── Zerstörungs-Logik: Rolling + BreakableCrate ──────────
      if (_playerState == _PlayerState.rolling &&
          obstacle.type == _GameObjectType.breakableCrate) {
        obstacle.active = false; // Kiste zerstört
        _sessionStars += 3;
        _totalEarnedStars += 3;
        _confettiTrigger++;
        _statusHint = 'Kiste zerstört! +3 ⭐';
        continue; // Kein Abbremsen
      }

      // Normale Kollision: Spieler wird blockiert
      if (_vx > 0) {
        _playerX = obstacle.rect.left - _playerWidth - 0.5;
      } else {
        _playerX = obstacle.rect.right + 0.5;
      }
      _vx = 0;
    }

    _playerX = _playerX.clamp(0, _worldWidth - _playerWidth);
  }

  void _resolveVertical(Rect previousRect) {
    var landed = false;
    final rect = _playerRect;

    for (final platform in _platforms) {
      final p = platform.rect;
      final horizontalOverlap =
          rect.right > p.left + 6 && rect.left < p.right - 6;
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
      makeTask: (seed) =>
          block.askGerman ? _createGermanTask(seed) : _createMathTask(seed),
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
        _statusHint =
            'Löse erst alle Frageblöcke ($_solvedBlockCount/$_requiredBlockCount).';
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
                localSetState(() => feedback =
                    'Stark! Noch $remaining ${remaining == 1 ? 'richtige Aufgabe' : 'richtige Aufgaben'}.');
              } else {
                streak = 0;
                seed += 41;
                task = _createMathTask(seed);
                selected = null;
                localSetState(
                    () => feedback = 'Fast! Wir starten die 3er-Serie neu.');
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFFFF7E6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Boss-Truhe'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Serie: $streak / 3',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(task.prompt,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    ...List<Widget>.generate(task.choices.length, (i) {
                      final isSelected = selected == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => localSetState(() => selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? LumoColors.orange : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD97706)
                                      : LumoColors.ink100,
                                  width: 2),
                            ),
                            child: Text(
                              task.choices[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : LumoColors.ink900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(feedback,
                        style: const TextStyle(
                            color: LumoColors.ink600,
                            fontWeight: FontWeight.w700)),
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
    final seed =
        DateTime.now().millisecondsSinceEpoch + _solvedBlockCount * 11;
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
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 8))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(task.prompt,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 22)),
                    const SizedBox(height: 12),
                    ...List<Widget>.generate(task.choices.length, (i) {
                      final selectedNow = selected == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => localSetState(() => selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: selectedNow
                                  ? LumoColors.orange
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: selectedNow
                                      ? const Color(0xFFD97706)
                                      : LumoColors.ink100,
                                  width: 2),
                            ),
                            child: Text(
                              task.choices[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selectedNow
                                    ? Colors.white
                                    : LumoColors.ink900,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(feedback,
                        style: const TextStyle(
                            color: LumoColors.ink600,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submit,
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
          },
        );
      },
    );

    return solved;
  }

  _LearningTask _createMathTask(int seed) {
    final grade =
        math.max(widget.level.gradeFloor, widget.appState.state.grade);
    final units = <String>[
      'Plus bis 10',
      'Minus bis 10',
      'Mengenvergleich',
      'Zahlenstrahl'
    ];
    final unit = units[seed.abs() % units.length];
    final task = MathTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return _LearningTask(
        prompt: task.prompt, choices: task.choices, answer: task.answer);
  }

  _LearningTask _createGermanTask(int seed) {
    final grade =
        math.max(widget.level.gradeFloor, widget.appState.state.grade);
    final units = <String>[
      'Anfangslaute',
      'Endlaute',
      'Silben',
      'Wort-Bild-Zuordnung'
    ];
    final unit = units[seed.abs() % units.length];
    final task =
        GermanTaskTemplates.generate(grade: grade, unit: unit, seed: seed);
    return _LearningTask(
        prompt: task.prompt, choices: task.choices, answer: task.answer);
  }

  int _resultStars() {
    if (_chest.opened && _solvedBlockCount == _requiredBlockCount) return 3;
    if (_solvedBlockCount >= (_requiredBlockCount / 2).ceil()) return 2;
    if (_solvedBlockCount > 0) return 1;
    return 0;
  }

  Future<void> _finishLevel() async {
    _ticker.stop(); // Ticker anhalten, während Dialog gezeigt wird
    final levelStars = _resultStars();

    await _repo.recordResult(
      childId: _childId,
      levelId: widget.level.id,
      starsEarned: levelStars,
    );

    // Wallet einmalig an globalen AppState übergeben
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
      builder: (_) => _LevelCompleteDialog(
        totalStars: _totalEarnedStars,
        levelStars: levelStars,
        onContinue: () => Navigator.of(context).pop(), // schließt nur Dialog
      ),
    );

    if (!mounted) return;
    // Spiel-Screen mit gesammelten Sternen beenden – Aufrufer fängt den Wert auf
    Navigator.of(context).pop(_totalEarnedStars);
  }

  /// Abbruch-Bestätigung: Spieler kann zwischenspeichern oder fortsetzen.
  Future<void> _confirmAbort() async {
    _ticker.stop();
    _paused = true;
    final quit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF7E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Spiel verlassen?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          _totalEarnedStars > 0
              ? 'Du hast bisher $_totalEarnedStars Sterne gesammelt.\nDiese werden trotzdem gespeichert!'
              : 'Dein Fortschritt wird nicht gespeichert.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Weiterspielen'),
          ),
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
      // Bereits verdiente Sterne ans Wallet übergeben, auch beim Abbruch
      if (_totalEarnedStars > 0 && !_walletTransferred) {
        _walletTransferred = true;
        final st = widget.appState.state;
        widget.appState.update(st.copyWith(
          stars: st.stars + _totalEarnedStars,
          xp: st.xp + (_totalEarnedStars * 2),
        ));
      }
      Navigator.of(context).pop(_totalEarnedStars);
    } else {
      _paused = false;
      _ticker.start();
    }
  }

  void _resetAfterFall() {
    final nearest = _platforms
            .where((p) => p.rect.left <= _checkpointX + 50)
            .fold<_Platform?>(
              null,
              (best, next) =>
                  best == null || next.rect.left > best.rect.left ? next : best,
            ) ??
        _platforms.first;

    _playerX = nearest.rect.left + 20;
    _playerY = nearest.rect.top - _playerHeight;
    _vx = 0;
    _vy = 0;
    _onGround = true;
    _statusHint = 'Alles gut! Lumo startet wieder sicher.';
  }

  // ── Level-Generator ───────────────────────────────────────────
  void _buildDailySeedLevel() {
    final now = DateTime.now().toUtc();
    final daySeed = DateTime.utc(now.year, now.month, now.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
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
        final sx =
            x + 48 + i * ((width - 96) / math.max(1, starCount - 1));
        final sy = y - 54 - (i.isEven ? 10 : 0);
        stars.add(_StarPickup(Offset(sx, sy)));
      }

      if (chunk % 2 == 1) {
        final blockX = x + width * 0.55;
        questionBlocks.add(_QuestionBlock(
            Rect.fromLTWH(blockX, y - 70, 62, 62),
            askGerman: chunk % 4 == 1));
      }

      if (chunk % 3 == 0) {
        final obsX = x + width * 0.35;
        final isCrate = random.nextBool();
        if (isCrate) {
          // Zerstörbare Kiste – lässt sich mit Roll-Dash zerstören
          obstacles.add(_Obstacle(
            Rect.fromLTWH(obsX, y - 52, 54, 52),
            requiresDuck: false,
            type: _GameObjectType.breakableCrate,
          ));
        } else {
          final duckObstacle = random.nextBool();
          obstacles.add(_Obstacle(
            Rect.fromLTWH(
                obsX, y - (duckObstacle ? 36 : 52), 54, duckObstacle ? 36 : 52),
            requiresDuck: duckObstacle,
          ));
        }
      }

      lastY = y;

      // ── Spelunky-Garantie: Lücke mathematisch begrenzen ──────
      final rawGap = 60 + random.nextInt(80); // 60–140 px Basis
      final verifiedGap = rawGap.toDouble().clamp(50.0, _maxSafeGap);
      assert(isJumpLogicallyPossible(verifiedGap),
          'Gap $verifiedGap überschreitet max. Sprungweite!');
      x += width + verifiedGap;
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

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lumo Jump Adventure',
          style:
              TextStyle(fontWeight: FontWeight.w900, color: LumoColors.ink900),
        ),
        leading: IconButton(
          onPressed: _confirmAbort,
          icon: const Icon(Icons.arrow_back_rounded, color: LumoColors.ink700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── HUD – strikt getrennt vom Game-Canvas ──────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _HudChip(
                      label: 'Sterne: $_sessionStars',
                      icon: Icons.star_rounded),
                  const SizedBox(width: 8),
                  _HudChip(
                      label:
                          'Frageblöcke: $_solvedBlockCount/$_requiredBlockCount',
                      icon: Icons.quiz_rounded),
                  const SizedBox(width: 8),
                  _HudChip(
                      label: _chest.opened ? 'Truhe offen' : 'Boss-Truhe',
                      icon: Icons.inventory_2_rounded),
                ],
              ),
            ),
            // ── Game-Canvas – RepaintBoundary isoliert Redraws ─
            Expanded(
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LumoJumpPainter(
                            cameraX: _cameraX,
                            playerRect: _playerRect,
                            playerState: _playerState,
                            platforms: _platforms,
                            stars: _stars,
                            obstacles: _obstacles,
                            questionBlocks: _questionBlocks,
                            chest: _chest,
                            confettiTrigger: _confettiTrigger,
                            // Vorberechnete Counts für shouldRepaint
                            activeObstacleCount:
                                _obstacles.where((o) => o.active).length,
                            clearedBlockCount:
                                _questionBlocks.where((b) => b.cleared).length,
                            collectedStarCount:
                                _stars.where((s) => s.collected).length,
                          ),
                        ),
                      ),
                      if (_statusHint != null)
                        Positioned(
                          left: 10,
                          right: 10,
                          top: 8,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusHint!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: LumoColors.ink700),
                              ),
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
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Steuerung ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  _holdButton(
                    icon: Icons.arrow_left_rounded,
                    onDown: () => setState(() => _leftPressed = true),
                    onUp: () => setState(() => _leftPressed = false),
                  ),
                  const SizedBox(width: 8),
                  _holdButton(
                    icon: Icons.arrow_right_rounded,
                    onDown: () => setState(() => _rightPressed = true),
                    onUp: () => setState(() => _rightPressed = false),
                  ),
                  const SizedBox(width: 8),
                  _holdButton(
                    icon: Icons.keyboard_double_arrow_down_rounded,
                    onDown: () => setState(() => _duckPressed = true),
                    onUp: () => setState(() => _duckPressed = false),
                    label: 'Ducken',
                  ),
                  const SizedBox(width: 8),
                  // Roll/Dash-Button
                  _holdButton(
                    icon: Icons.rotate_right_rounded,
                    onDown: _activateRoll,
                    onUp: () {},
                    label: 'Rollen',
                    color: const Color(0xFF7C3AED),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Level abschließen',
                        style: TextStyle(fontWeight: FontWeight.w900)),
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
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: label == null
            ? Icon(icon, color: Colors.white, size: 34)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }
}

// ── HUD-Chip ─────────────────────────────────────────────────────

// ── Level-Abschluss-Dialog ────────────────────────────────────────
// Polierter Exit im Lumo-Design: zeigt Sterne-Animation, Ergebnis
// und leitet sanft zur Level-Map zurück.

class _LevelCompleteDialog extends StatelessWidget {
  const _LevelCompleteDialog({
    required this.totalStars,
    required this.levelStars,
    required this.onContinue,
  });

  final int totalStars;
  final int levelStars;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final headline = levelStars == 3
        ? '⭐⭐⭐ Perfekt!'
        : levelStars == 2
            ? '⭐⭐ Super!'
            : levelStars == 1
                ? '⭐ Geschafft!'
                : 'Level beendet';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fuchs-Emoji als Stellvertreter-Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                shape: BoxShape.circle,
                border: Border.all(
                    color: LumoColors.orange.withOpacity(0.4), width: 3),
              ),
              alignment: Alignment.center,
              child: const Text('🦊',
                  style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: LumoColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            // Sterne-Anzeige
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (i) {
                final earned = i < levelStars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    earned ? '⭐' : '☆',
                    style: TextStyle(
                        fontSize: 36,
                        color: earned ? null : LumoColors.ink300),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: LumoColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '+$totalStars ${totalStars == 1 ? 'Stern' : 'Sterne'} ins Wallet',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: LumoColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LumoRadius.pill)),
                  elevation: 0,
                ),
                onPressed: onContinue,
                child: const Text(
                  'Zurück zur Karte',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
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
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: LumoColors.ink800)),
        ],
      ),
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────
// Optimierung: shouldRepaint prüft exakt die relevanten Felder,
// damit kein unnötiger Frame gezeichnet wird. Das HUD bleibt im
// Widget-Tree (außerhalb des Painters) und löst keine Painter-
// Rebuilds aus.

class _LumoJumpPainter extends CustomPainter {
  const _LumoJumpPainter({
    required this.cameraX,
    required this.playerRect,
    required this.playerState,
    required this.platforms,
    required this.stars,
    required this.obstacles,
    required this.questionBlocks,
    required this.chest,
    required this.confettiTrigger,
    required this.activeObstacleCount,
    required this.clearedBlockCount,
    required this.collectedStarCount,
  });

  final double cameraX;
  final Rect playerRect;
  final _PlayerState playerState;
  final List<_Platform> platforms;
  final List<_StarPickup> stars;
  final List<_Obstacle> obstacles;
  final List<_QuestionBlock> questionBlocks;
  final _Chest chest;
  final int confettiTrigger;
  // Vorberechnete Counts für effizientes shouldRepaint
  final int activeObstacleCount;
  final int clearedBlockCount;
  final int collectedStarCount;

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund-Gradient (statisch – könnte in ImageShader gecacht werden)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFA7F3D0), Color(0xFFBFDBFE), Color(0xFFFDE68A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    canvas.save();
    canvas.translate(-cameraX, 0);

    // ── Plattformen ───────────────────────────────────────────
    final platformPaint = Paint()..color = const Color(0xFF22C55E);
    for (final platform in platforms) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(platform.rect, const Radius.circular(10)),
          platformPaint);
    }

    // ── Hindernisse ───────────────────────────────────────────
    for (final obstacle in obstacles) {
      if (!obstacle.active) continue;
      final Color color;
      if (obstacle.type == _GameObjectType.breakableCrate) {
        color = const Color(0xFF92400E); // Braune Kiste
      } else if (obstacle.requiresDuck) {
        color = const Color(0xFF7C3AED); // Lila: ducken
      } else {
        color = const Color(0xFF0EA5E9); // Blau: normal
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(obstacle.rect, const Radius.circular(8)),
          Paint()..color = color);

      // Kisten-Icon
      if (obstacle.type == _GameObjectType.breakableCrate) {
        final tp = TextPainter(
          text: const TextSpan(
              text: '📦',
              style: TextStyle(fontSize: 20)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            canvas,
            Offset(obstacle.rect.center.dx - tp.width / 2,
                obstacle.rect.center.dy - tp.height / 2));
      }
    }

    // ── Frageblöcke ───────────────────────────────────────────
    for (final block in questionBlocks) {
      if (block.cleared) continue;
      canvas.drawRRect(
          RRect.fromRectAndRadius(block.rect, const Radius.circular(8)),
          Paint()..color = const Color(0xFFF59E0B));
      final tp = TextPainter(
        text: const TextSpan(
            text: '?',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(block.rect.center.dx - tp.width / 2,
              block.rect.center.dy - tp.height / 2));
    }

    // ── Sterne ────────────────────────────────────────────────
    final starPaint = Paint()..color = const Color(0xFFFACC15);
    for (final star in stars) {
      if (star.collected) continue;
      final s = 10 * star.scalePulse;
      final cx = star.position.dx;
      final cy = star.position.dy;
      final path = Path()
        ..moveTo(cx, cy - s)
        ..lineTo(cx + s * 0.35, cy - s * 0.2)
        ..lineTo(cx + s, cy - s * 0.1)
        ..lineTo(cx + s * 0.5, cy + s * 0.25)
        ..lineTo(cx + s * 0.65, cy + s)
        ..lineTo(cx, cy + s * 0.55)
        ..lineTo(cx - s * 0.65, cy + s)
        ..lineTo(cx - s * 0.5, cy + s * 0.25)
        ..lineTo(cx - s, cy - s * 0.1)
        ..lineTo(cx - s * 0.35, cy - s * 0.2)
        ..close();
      canvas.drawPath(path, starPaint);
    }

    // ── Boss-Truhe ────────────────────────────────────────────
    canvas.drawRRect(
        RRect.fromRectAndRadius(chest.rect, const Radius.circular(8)),
        Paint()
          ..color =
              chest.opened ? const Color(0xFF10B981) : const Color(0xFF92400E));

    // ── Lumo (Fuchs) ──────────────────────────────────────────
    final foxColor = playerState == _PlayerState.rolling
        ? const Color(0xFF7C3AED) // Lila beim Rollen
        : const Color(0xFFF97316); // Orange normal
    canvas.drawRRect(
        RRect.fromRectAndRadius(playerRect, const Radius.circular(10)),
        Paint()..color = foxColor);

    // Augen
    canvas.drawCircle(
        Offset(playerRect.left + playerRect.width * 0.30, playerRect.top + 18),
        5,
        Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(playerRect.left + playerRect.width * 0.70, playerRect.top + 18),
        5,
        Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(playerRect.left + playerRect.width * 0.30, playerRect.top + 18),
        2,
        Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(playerRect.left + playerRect.width * 0.70, playerRect.top + 18),
        2,
        Paint()..color = Colors.black);

    // ── Konfetti bei Sammel-Events ────────────────────────────
    if (confettiTrigger > 0) {
      final confettiPaint = Paint()..color = const Color(0x99FFFFFF);
      for (var i = 0; i < 14; i++) {
        final dx = playerRect.center.dx + math.sin(i.toDouble()) * 36;
        final dy = playerRect.top - 12 - (i % 4) * 5;
        canvas.drawCircle(Offset(dx, dy), 2.4, confettiPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LumoJumpPainter oldDelegate) {
    // Exakte O(1)-Prüfung relevanter Spielzustands-Felder.
    // Counts werden vom State vorberechnet übergeben – keine Iteration hier.
    return cameraX != oldDelegate.cameraX ||
        playerRect != oldDelegate.playerRect ||
        playerState != oldDelegate.playerState ||
        confettiTrigger != oldDelegate.confettiTrigger ||
        clearedBlockCount != oldDelegate.clearedBlockCount ||
        collectedStarCount != oldDelegate.collectedStarCount ||
        activeObstacleCount != oldDelegate.activeObstacleCount ||
        chest.opened != oldDelegate.chest.opened;
  }
}

// ── Daten-Klassen ─────────────────────────────────────────────────

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
  _Obstacle(
    this.rect, {
    required this.requiresDuck,
    this.type = _GameObjectType.obstacle,
  });
  final Rect rect;
  final bool requiresDuck;
  final _GameObjectType type;
  bool active = true; // false = zerstörte Kiste
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
  const _LearningTask(
      {required this.prompt, required this.choices, required this.answer});
  final String prompt;
  final List<String> choices;
  final String answer;
}
