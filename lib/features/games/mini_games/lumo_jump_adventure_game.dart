import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  // ── Nintendo-Polish: visuelle Effekte ────────────────────────
  /// Stern-Burst-Partikel bei Aufnahme. Werden im Painter gezeichnet
  /// und im Tick reduziert (alive bis ttl <= 0).
  final List<_FxBurst> _starBursts = <_FxBurst>[];

  /// Holz-Splitter bei zerstoerter Kiste.
  final List<_FxSplinter> _splinters = <_FxSplinter>[];

  /// Screen-Shake bei Crate-Break / Boss-Treffer.
  double _shakeTimer = 0;
  double _shakeIntensity = 0;

  /// Anim-Zeit fuer Wolken-Drift + Lumo-Wedeln.
  double _animTime = 0;

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
    _animTime += dt;
    _updatePlayerState(dt);
    _updateFx(dt);

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
        _spawnSplinters(obstacle.rect.center);
        _triggerShake(intensity: 8, duration: 0.22);
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
        _spawnStarBurst(star.position);
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

  // ── Nintendo-Polish: FX-Methoden ──────────────────────────────
  void _updateFx(double dt) {
    // Stern-Bursts ausbleichen lassen + bewegen
    for (final b in _starBursts) {
      b.ttl -= dt;
      b.pos += b.vel * dt;
      b.vel = Offset(b.vel.dx * 0.95, b.vel.dy + 320 * dt);
    }
    _starBursts.removeWhere((b) => b.ttl <= 0);

    // Holz-Splitter mit Schwerkraft + Rotation
    for (final s in _splinters) {
      s.ttl -= dt;
      s.pos += s.vel * dt;
      s.vel = Offset(s.vel.dx * 0.96, s.vel.dy + 520 * dt);
      s.angle += s.spin * dt;
    }
    _splinters.removeWhere((s) => s.ttl <= 0);

    // Screen-Shake abklingen lassen
    if (_shakeTimer > 0) {
      _shakeTimer = math.max(0, _shakeTimer - dt);
      if (_shakeTimer == 0) _shakeIntensity = 0;
    }
  }

  void _spawnStarBurst(Offset center) {
    final r = math.Random();
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + r.nextDouble() * 0.4;
      final speed = 100 + r.nextDouble() * 90;
      _starBursts.add(_FxBurst(
        pos: center,
        vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed - 80),
        ttl: 0.55,
        color: const Color(0xFFFACC15),
        size: 4 + r.nextDouble() * 2,
      ));
    }
  }

  void _spawnSplinters(Offset center) {
    final r = math.Random();
    for (var i = 0; i < 7; i++) {
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi;
      final speed = 180 + r.nextDouble() * 140;
      _splinters.add(_FxSplinter(
        pos: center,
        vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed - 120),
        angle: r.nextDouble() * math.pi,
        spin: (r.nextDouble() - 0.5) * 12,
        ttl: 0.85,
        size: 6 + r.nextDouble() * 6,
      ));
    }
  }

  void _triggerShake({required double intensity, required double duration}) {
    _shakeIntensity = math.max(_shakeIntensity, intensity);
    _shakeTimer = math.max(_shakeTimer, duration);
  }

  /// Theme passend zum aktuellen Level-Block (1-5). Nintendo-Welt-Variation.
  _LumoTheme get _theme => _LumoTheme.forLevel(widget.level.id);

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
      // Lücke immer auf sicheres Maximum begrenzen – auch in Release-Builds.
      final safeGap = isJumpLogicallyPossible(verifiedGap)
          ? verifiedGap
          : _maxSafeGap;
      x += width + safeGap;
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
                            playerFacingRight: _vx >= 0,
                            platforms: _platforms,
                            stars: _stars,
                            obstacles: _obstacles,
                            questionBlocks: _questionBlocks,
                            chest: _chest,
                            confettiTrigger: _confettiTrigger,
                            theme: _theme,
                            animTime: _animTime,
                            starBursts: _starBursts,
                            splinters: _splinters,
                            shakeOffset: _shakeIntensity > 0
                                ? Offset(
                                    (math.Random(_shakeTimer.hashCode).nextDouble() - 0.5) * _shakeIntensity * 2,
                                    (math.Random((_shakeTimer * 7).hashCode).nextDouble() - 0.5) * _shakeIntensity * 2,
                                  )
                                : Offset.zero,
                            // Vorberechnete Counts für shouldRepaint
                            activeObstacleCount:
                                _obstacles.where((o) => o.active).length,
                            clearedBlockCount:
                                _questionBlocks.where((b) => b.cleared).length,
                            collectedStarCount:
                                _stars.where((s) => s.collected).length,
                            burstCount: _starBursts.length,
                            splinterCount: _splinters.length,
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
                  fontWeight: FontWeight.w800, color: LumoColors.ink700)),
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
    required this.playerFacingRight,
    required this.platforms,
    required this.stars,
    required this.obstacles,
    required this.questionBlocks,
    required this.chest,
    required this.confettiTrigger,
    required this.theme,
    required this.animTime,
    required this.starBursts,
    required this.splinters,
    required this.shakeOffset,
    required this.activeObstacleCount,
    required this.clearedBlockCount,
    required this.collectedStarCount,
    required this.burstCount,
    required this.splinterCount,
  });

  final double cameraX;
  final Rect playerRect;
  final _PlayerState playerState;
  final bool playerFacingRight;
  final List<_Platform> platforms;
  final List<_StarPickup> stars;
  final List<_Obstacle> obstacles;
  final List<_QuestionBlock> questionBlocks;
  final _Chest chest;
  final int confettiTrigger;
  final _LumoTheme theme;
  final double animTime;
  final List<_FxBurst> starBursts;
  final List<_FxSplinter> splinters;
  final Offset shakeOffset;
  // Vorberechnete Counts für effizientes shouldRepaint
  final int activeObstacleCount;
  final int clearedBlockCount;
  final int collectedStarCount;
  final int burstCount;
  final int splinterCount;

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Himmel-Gradient (Theme-spezifisch) ──────────────────
    final skyPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[theme.skyTop, theme.skyMid, theme.skyBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // ── 2. Parallax-Schicht: Sonne/Mond ────────────────────────
    final sunPaint = Paint()..color = theme.sunColor.withOpacity(0.85);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.18), 36, sunPaint);
    canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.18),
        50,
        Paint()..color = theme.sunColor.withOpacity(0.18));

    // Shake-Offset wird auf alle bewegten Schichten angewendet
    canvas.save();
    canvas.translate(shakeOffset.dx, shakeOffset.dy);

    // ── 3. Wolken / Theme-Partikel (langsam driftend) ─────────
    _paintBackgroundParticles(canvas, size);

    // ── 4. Parallax-Berge (ferne Schicht, cameraX * 0.15) ─────
    _paintMountainLayer(canvas, size, parallax: 0.15, color: theme.mountainBack, height: 110);
    // Parallax-Huegel (naehere Schicht, cameraX * 0.35)
    _paintMountainLayer(canvas, size, parallax: 0.35, color: theme.mountainFront, height: 78);

    // ── 5. Vordergrund mit voller Kamera-Translation ──────────
    canvas.save();
    canvas.translate(-cameraX, 0);

    _paintPlatforms(canvas);
    _paintObstacles(canvas);
    _paintQuestionBlocks(canvas);
    _paintStars(canvas);
    _paintChest(canvas);
    _paintFox(canvas);
    _paintStarBursts(canvas);
    _paintSplinters(canvas);
    _paintConfetti(canvas);

    canvas.restore();
    canvas.restore();
  }

  // ── Wolken/Partikel-Schicht ──────────────────────────────────
  void _paintBackgroundParticles(Canvas canvas, Size size) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.7);
    // 5 langsam driftende Wolken, verteilt
    for (var i = 0; i < 5; i++) {
      final baseX = (i * 280) - (cameraX * 0.1) - (animTime * 8 % 200);
      final wrapped = baseX % (size.width + 200);
      final x = wrapped < -100 ? wrapped + size.width + 200 : wrapped;
      final y = 40 + (i.isEven ? 0 : 30) + math.sin(animTime + i) * 4;
      _paintCloud(canvas, Offset(x, y), 1.0 + (i % 2) * 0.3, cloudPaint);
    }

    // Theme-spezifische Partikel (Schnee/Blaetter/Funken)
    if (theme.particleEmoji != null) {
      final t = animTime;
      for (var i = 0; i < 12; i++) {
        final baseX = (i * 67.3 + t * 18) % (size.width + 40);
        final y = ((i * 53.7 + t * 30) % size.height);
        final tp = TextPainter(
          text: TextSpan(
              text: theme.particleEmoji,
              style: TextStyle(fontSize: 12 + (i % 3) * 4, color: Colors.white.withOpacity(0.6))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(baseX, y));
      }
    }
  }

  void _paintCloud(Canvas canvas, Offset c, double scale, Paint p) {
    canvas.drawCircle(c, 18 * scale, p);
    canvas.drawCircle(c.translate(20 * scale, -6 * scale), 22 * scale, p);
    canvas.drawCircle(c.translate(40 * scale, 0), 18 * scale, p);
    canvas.drawCircle(c.translate(22 * scale, 8 * scale), 16 * scale, p);
  }

  void _paintMountainLayer(Canvas canvas, Size size,
      {required double parallax, required Color color, required double height}) {
    final offset = cameraX * parallax;
    final baseY = size.height * 0.62;
    final p = Paint()..color = color;
    final path = Path()..moveTo(0, baseY);
    const peakSpacing = 180.0;
    final peakCount = (size.width / peakSpacing).ceil() + 2;
    for (var i = 0; i < peakCount; i++) {
      final x = i * peakSpacing - (offset % peakSpacing);
      final isAlt = i.isEven;
      path.lineTo(x + peakSpacing / 2, baseY - height * (isAlt ? 1.0 : 0.72));
      path.lineTo(x + peakSpacing, baseY);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, p);
  }

  // ── Plattformen mit Premium-Stil ─────────────────────────────
  void _paintPlatforms(Canvas canvas) {
    for (final platform in platforms) {
      final r = platform.rect;
      final platTop = Rect.fromLTWH(r.left, r.top, r.width, 14);
      final platBody = Rect.fromLTWH(r.left, r.top + 14, r.width, r.height - 14);
      // Top-Schicht (Gras/Eis/Sand)
      canvas.drawRRect(
          RRect.fromRectAndCorners(platTop,
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12)),
          Paint()..color = theme.platformTop);
      // Body (Erde/Stein)
      canvas.drawRRect(
          RRect.fromRectAndCorners(platBody,
              bottomLeft: const Radius.circular(8),
              bottomRight: const Radius.circular(8)),
          Paint()..color = theme.platformBody);
      // Akzent-Linie an der Oberkante
      canvas.drawLine(
          Offset(r.left + 6, r.top + 14),
          Offset(r.right - 6, r.top + 14),
          Paint()
            ..color = theme.platformAccent
            ..strokeWidth = 2);
    }
  }

  void _paintObstacles(Canvas canvas) {
    for (final obstacle in obstacles) {
      if (!obstacle.active) continue;
      if (obstacle.type == _GameObjectType.breakableCrate) {
        // Hoelzerne Kiste mit Holzmaserung
        final r = obstacle.rect;
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(6)),
            Paint()..color = const Color(0xFF92400E));
        // Holzplanken-Linien
        final linePaint = Paint()
          ..color = const Color(0xFF7C2D12)
          ..strokeWidth = 2;
        canvas.drawLine(Offset(r.left, r.top + r.height / 3),
            Offset(r.right, r.top + r.height / 3), linePaint);
        canvas.drawLine(Offset(r.left, r.top + 2 * r.height / 3),
            Offset(r.right, r.top + 2 * r.height / 3), linePaint);
        // Eisen-Beschlag-Punkte
        final boltPaint = Paint()..color = const Color(0xFF422006);
        canvas.drawCircle(Offset(r.left + 5, r.top + 5), 2.5, boltPaint);
        canvas.drawCircle(Offset(r.right - 5, r.top + 5), 2.5, boltPaint);
        canvas.drawCircle(Offset(r.left + 5, r.bottom - 5), 2.5, boltPaint);
        canvas.drawCircle(Offset(r.right - 5, r.bottom - 5), 2.5, boltPaint);
      } else {
        final color = obstacle.requiresDuck
            ? const Color(0xFF7C3AED) // Lila: ducken
            : const Color(0xFF0EA5E9); // Blau: normal
        canvas.drawRRect(
            RRect.fromRectAndRadius(obstacle.rect, const Radius.circular(8)),
            Paint()..color = color);
        // Glanz oben
        canvas.drawRRect(
            RRect.fromLTRBR(obstacle.rect.left + 4, obstacle.rect.top + 3,
                obstacle.rect.right - 4, obstacle.rect.top + 8,
                const Radius.circular(4)),
            Paint()..color = Colors.white.withOpacity(0.3));
      }
    }
  }

  void _paintQuestionBlocks(Canvas canvas) {
    for (final block in questionBlocks) {
      if (block.cleared) continue;
      final r = block.rect;
      // Pulsierende Glow-Aura
      final pulse = 0.5 + math.sin(animTime * 3) * 0.5;
      canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(12)),
          Paint()..color = const Color(0xFFFCD34D).withOpacity(0.25 + pulse * 0.2));
      // Block-Body
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = const Color(0xFFF59E0B));
      // Inner-Highlight (3D-Effekt)
      canvas.drawRRect(
          RRect.fromLTRBR(r.left + 3, r.top + 3, r.right - 3, r.top + 12, const Radius.circular(4)),
          Paint()..color = Colors.white.withOpacity(0.45));
      // ? Symbol
      final tp = TextPainter(
        text: const TextSpan(
            text: '?',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
    }
  }

  void _paintStars(Canvas canvas) {
    final starPaint = Paint()..color = const Color(0xFFFACC15);
    final glowPaint = Paint()..color = const Color(0xFFFEF3C7).withOpacity(0.45);
    for (final star in stars) {
      if (star.collected) continue;
      final s = 10 * star.scalePulse;
      final cx = star.position.dx;
      final cy = star.position.dy + math.sin(animTime * 2 + star.position.dx) * 2;
      // Glow
      canvas.drawCircle(Offset(cx, cy), s * 1.7, glowPaint);
      // Stern-Form
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
      // Highlight im Stern
      canvas.drawCircle(Offset(cx - s * 0.25, cy - s * 0.25), 2, Paint()..color = Colors.white);
    }
  }

  void _paintChest(Canvas canvas) {
    final r = chest.rect;
    if (chest.opened) {
      // Geoeffnete Truhe mit Glanz
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = const Color(0xFF10B981));
      // Trophy-Stern
      final tp = TextPainter(
        text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 36)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
    } else {
      // Geschlossene Truhe mit Schloss
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = const Color(0xFF92400E));
      // Goldener Deckel
      canvas.drawRRect(
          RRect.fromLTRBR(r.left, r.top, r.right, r.top + 14, const Radius.circular(6)),
          Paint()..color = const Color(0xFFD97706));
      // Schloss
      canvas.drawRect(
          Rect.fromCenter(center: Offset(r.center.dx, r.top + 18), width: 14, height: 18),
          Paint()..color = const Color(0xFFFCD34D));
      canvas.drawCircle(Offset(r.center.dx, r.top + 18), 3, Paint()..color = const Color(0xFF422006));
    }
  }

  // ── Lumo (richtiger Fuchs - kein Box mehr!) ─────────────────
  void _paintFox(Canvas canvas) {
    final r = playerRect;
    final dir = playerFacingRight ? 1.0 : -1.0;
    final cx = r.center.dx;
    final cy = r.center.dy;
    final w = r.width;
    final h = r.height;

    final bodyColor = playerState == _PlayerState.rolling
        ? const Color(0xFF7C3AED) // Lila beim Rollen
        : const Color(0xFFF97316); // Orange normal
    final bellyColor = const Color(0xFFFEDBA4);
    final accentColor = playerState == _PlayerState.rolling
        ? const Color(0xFF5B21B6)
        : const Color(0xFFC2410C);

    // Roll = zur Kugel werden
    if (playerState == _PlayerState.rolling) {
      final rollSize = math.min(w, h) * 0.95;
      final center = Offset(cx, cy);
      canvas.drawCircle(center, rollSize / 2, Paint()..color = bodyColor);
      // Speed-Streifen rotierend
      final t = animTime * 14;
      for (var i = 0; i < 3; i++) {
        final a = t + i * (math.pi * 2 / 3);
        canvas.drawCircle(
            center + Offset(math.cos(a) * rollSize * 0.28, math.sin(a) * rollSize * 0.28),
            3, Paint()..color = const Color(0xFFFCD34D));
      }
      // Anti-Aliasing-Glow
      canvas.drawCircle(center, rollSize / 2 + 2,
          Paint()..color = bodyColor.withOpacity(0.3));
      return;
    }

    // Schwanz (hinter dem Körper)
    final tailWag = math.sin(animTime * 8) * 0.15 * dir;
    canvas.save();
    canvas.translate(cx - 14 * dir, cy + h * 0.05);
    canvas.rotate(tailWag);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-12 * dir, -8, -22 * dir, -4)
      ..quadraticBezierTo(-28 * dir, 8, -18 * dir, 14)
      ..quadraticBezierTo(-8 * dir, 8, 0, 4)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = bodyColor);
    // Weisse Schwanzspitze
    canvas.drawCircle(Offset(-22 * dir, 4), 6, Paint()..color = Colors.white);
    canvas.restore();

    // Hauptkoerper - eiförmig
    final bodyRect = Rect.fromCenter(center: Offset(cx, cy + 2), width: w * 0.78, height: h * 0.78);
    canvas.drawOval(bodyRect, Paint()..color = bodyColor);

    // Bauchpartie (heller, vorne)
    final bellyRect = Rect.fromCenter(
        center: Offset(cx + 6 * dir, cy + h * 0.18),
        width: w * 0.5,
        height: h * 0.42);
    canvas.drawOval(bellyRect, Paint()..color = bellyColor);

    // Kopf (kreisförmig, oben vorne)
    final headCx = cx + 8 * dir;
    final headCy = cy - h * 0.18;
    canvas.drawCircle(Offset(headCx, headCy), w * 0.32, Paint()..color = bodyColor);
    // Gesichts-Maske (heller Bereich um Schnauze)
    canvas.drawCircle(Offset(headCx + 4 * dir, headCy + 4), w * 0.22, Paint()..color = bellyColor);

    // Ohren - dreieckig
    final earColor = bodyColor;
    final earInner = accentColor;
    final earL = Path()
      ..moveTo(headCx - 14 * dir, headCy - w * 0.22)
      ..lineTo(headCx - 4 * dir, headCy - w * 0.42)
      ..lineTo(headCx + 4 * dir, headCy - w * 0.18)
      ..close();
    canvas.drawPath(earL, Paint()..color = earColor);
    // Innen-Ohr
    final earLInner = Path()
      ..moveTo(headCx - 10 * dir, headCy - w * 0.22)
      ..lineTo(headCx - 5 * dir, headCy - w * 0.34)
      ..lineTo(headCx + 0 * dir, headCy - w * 0.20)
      ..close();
    canvas.drawPath(earLInner, Paint()..color = earInner);
    // Zweites Ohr (hinten, etwas kleiner)
    final earR = Path()
      ..moveTo(headCx + 8 * dir, headCy - w * 0.20)
      ..lineTo(headCx + 18 * dir, headCy - w * 0.36)
      ..lineTo(headCx + 22 * dir, headCy - w * 0.10)
      ..close();
    canvas.drawPath(earR, Paint()..color = earColor);

    // Augen (gross, kindlich - Pixar-Style)
    final eyeY = headCy + 2;
    final eyeLx = headCx - 6 * dir;
    final eyeRx = headCx + 6 * dir;
    // Augen-Weiss
    canvas.drawCircle(Offset(eyeLx, eyeY), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(eyeRx, eyeY), 5, Paint()..color = Colors.white);
    // Pupillen (Blickrichtung folgt Lauf-Richtung)
    canvas.drawCircle(Offset(eyeLx + 1.5 * dir, eyeY), 2.8,
        Paint()..color = const Color(0xFF1F2937));
    canvas.drawCircle(Offset(eyeRx + 1.5 * dir, eyeY), 2.8,
        Paint()..color = const Color(0xFF1F2937));
    // Glanz-Punkte
    canvas.drawCircle(Offset(eyeLx + 2 * dir, eyeY - 1.5), 0.9,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(eyeRx + 2 * dir, eyeY - 1.5), 0.9,
        Paint()..color = Colors.white);

    // Schnauze - kleine Nase + Mund
    final noseX = headCx + 12 * dir;
    final noseY = headCy + 10;
    canvas.drawCircle(Offset(noseX, noseY), 2.5, Paint()..color = const Color(0xFF1F2937));
    // Mund - kleine Kurve
    final mouthPath = Path()
      ..moveTo(noseX - 3, noseY + 2)
      ..quadraticBezierTo(noseX, noseY + 5, noseX + 3, noseY + 2);
    canvas.drawPath(
        mouthPath,
        Paint()
          ..color = const Color(0xFF1F2937)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // Pfoten / Beine
    final legColor = accentColor;
    final legY = r.bottom - 6;
    final legRunFrame = math.sin(animTime * 14) * 4;
    final isRunning = playerState == _PlayerState.running;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx - 8, legY + (isRunning ? legRunFrame : 0)),
                width: 10, height: 12),
            const Radius.circular(4)),
        Paint()..color = legColor);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + 8, legY - (isRunning ? legRunFrame : 0)),
                width: 10, height: 12),
            const Radius.circular(4)),
        Paint()..color = legColor);

    // Ducken: Lumo bleibt klein gezeichnet (durch _playerHeight schon)
    // Springen: Beine ziehen sich an
  }

  // ── FX: Stern-Burst-Partikel ─────────────────────────────────
  void _paintStarBursts(Canvas canvas) {
    for (final b in starBursts) {
      final alpha = (b.ttl / 0.55).clamp(0.0, 1.0);
      final p = Paint()..color = b.color.withOpacity(alpha);
      canvas.drawCircle(b.pos, b.size, p);
      // Heller Kern
      canvas.drawCircle(b.pos, b.size * 0.45, Paint()..color = Colors.white.withOpacity(alpha * 0.8));
    }
  }

  // ── FX: Holz-Splitter ────────────────────────────────────────
  void _paintSplinters(Canvas canvas) {
    for (final s in splinters) {
      final alpha = (s.ttl / 0.85).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(s.pos.dx, s.pos.dy);
      canvas.rotate(s.angle);
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s.size, height: s.size * 0.4),
          Paint()..color = const Color(0xFF92400E).withOpacity(alpha));
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s.size, height: s.size * 0.4),
          Paint()
            ..color = const Color(0xFF7C2D12).withOpacity(alpha * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      canvas.restore();
    }
  }

  void _paintConfetti(Canvas canvas) {
    if (confettiTrigger <= 0) return;
    final colors = <Color>[
      const Color(0xFFFACC15),
      const Color(0xFFFB923C),
      const Color(0xFF34D399),
      const Color(0xFF60A5FA),
      const Color(0xFFF472B6),
    ];
    for (var i = 0; i < 18; i++) {
      final dx = playerRect.center.dx + math.sin(i.toDouble() + animTime * 4) * 38;
      final dy = playerRect.top - 12 - (i % 5) * 6 - math.cos(i.toDouble()) * 4;
      canvas.drawCircle(Offset(dx, dy), 2.6, Paint()..color = colors[i % colors.length]);
    }
  }

  @override
  bool shouldRepaint(covariant _LumoJumpPainter oldDelegate) {
    // Exakte O(1)-Prüfung relevanter Spielzustands-Felder.
    return cameraX != oldDelegate.cameraX ||
        playerRect != oldDelegate.playerRect ||
        playerState != oldDelegate.playerState ||
        playerFacingRight != oldDelegate.playerFacingRight ||
        confettiTrigger != oldDelegate.confettiTrigger ||
        clearedBlockCount != oldDelegate.clearedBlockCount ||
        collectedStarCount != oldDelegate.collectedStarCount ||
        activeObstacleCount != oldDelegate.activeObstacleCount ||
        burstCount != oldDelegate.burstCount ||
        splinterCount != oldDelegate.splinterCount ||
        shakeOffset != oldDelegate.shakeOffset ||
        animTime != oldDelegate.animTime ||
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

// ── Nintendo-Polish: FX-Partikel + Theme-System ─────────────────────

/// Generischer Stern-Burst-Partikel (gelb, fadiert aus).
class _FxBurst {
  _FxBurst({
    required this.pos,
    required this.vel,
    required this.ttl,
    required this.color,
    required this.size,
  });
  Offset pos;
  Offset vel;
  double ttl;
  final Color color;
  final double size;
}

/// Holz-Splitter bei zerstoerter Kiste.
class _FxSplinter {
  _FxSplinter({
    required this.pos,
    required this.vel,
    required this.angle,
    required this.spin,
    required this.ttl,
    required this.size,
  });
  Offset pos;
  Offset vel;
  double angle;
  final double spin;
  double ttl;
  final double size;
}

/// Theme-Farben + Effekte pro Welt (Wiese / Eis / Wald / Wueste / Lava).
/// Wird durch den Level-Block 1-5 bestimmt.
class _LumoTheme {
  const _LumoTheme({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.sunColor,
    required this.mountainBack,
    required this.mountainFront,
    required this.platformTop,
    required this.platformBody,
    required this.platformAccent,
    this.particleEmoji,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color sunColor;
  final Color mountainBack;
  final Color mountainFront;
  final Color platformTop;
  final Color platformBody;
  final Color platformAccent;

  /// Optionales Welt-spezifisches Partikel (Schneeflocke/Blatt/Funke).
  final String? particleEmoji;

  /// Liefert das Theme passend zum Level (1-50) -> Block 1-5.
  factory _LumoTheme.forLevel(int levelId) {
    final block = levelId <= 10
        ? 1
        : levelId <= 20
            ? 2
            : levelId <= 30
                ? 3
                : levelId <= 40
                    ? 4
                    : 5;
    switch (block) {
      case 1: // Wiese - warmer Tag, gruene Huegel
        return const _LumoTheme(
          skyTop: Color(0xFFBAE6FD),
          skyMid: Color(0xFFE0F2FE),
          skyBottom: Color(0xFFFEF3C7),
          sunColor: Color(0xFFFCD34D),
          mountainBack: Color(0xFF86EFAC),
          mountainFront: Color(0xFF22C55E),
          platformTop: Color(0xFF4ADE80),
          platformBody: Color(0xFF92400E),
          platformAccent: Color(0xFF15803D),
        );
      case 2: // Eis - kalt, blau, Schneeflocken
        return const _LumoTheme(
          skyTop: Color(0xFFE0F2FE),
          skyMid: Color(0xFFBAE6FD),
          skyBottom: Color(0xFFE5E7EB),
          sunColor: Color(0xFFF1F5F9),
          mountainBack: Color(0xFFCBD5E1),
          mountainFront: Color(0xFF94A3B8),
          platformTop: Color(0xFFDDF7FF),
          platformBody: Color(0xFF60A5FA),
          platformAccent: Color(0xFF1E40AF),
          particleEmoji: '❄',
        );
      case 3: // Wald - dunkles Gruen, Blaetter
        return const _LumoTheme(
          skyTop: Color(0xFFD9F99D),
          skyMid: Color(0xFFBBF7D0),
          skyBottom: Color(0xFFFEF3C7),
          sunColor: Color(0xFFFDE68A),
          mountainBack: Color(0xFF166534),
          mountainFront: Color(0xFF15803D),
          platformTop: Color(0xFF65A30D),
          platformBody: Color(0xFF422006),
          platformAccent: Color(0xFF14532D),
          particleEmoji: '🍃',
        );
      case 4: // Wueste - Sand, Kakteen-Farben
        return const _LumoTheme(
          skyTop: Color(0xFFFCD34D),
          skyMid: Color(0xFFFEF3C7),
          skyBottom: Color(0xFFFBA74A),
          sunColor: Color(0xFFFED7AA),
          mountainBack: Color(0xFFD97706),
          mountainFront: Color(0xFFB45309),
          platformTop: Color(0xFFFCD34D),
          platformBody: Color(0xFF92400E),
          platformAccent: Color(0xFF78350F),
        );
      case 5: // Lava - heiss, schwarz mit Glut
        return const _LumoTheme(
          skyTop: Color(0xFF7F1D1D),
          skyMid: Color(0xFFB91C1C),
          skyBottom: Color(0xFFF59E0B),
          sunColor: Color(0xFFEF4444),
          mountainBack: Color(0xFF1F2937),
          mountainFront: Color(0xFF111827),
          platformTop: Color(0xFFFB923C),
          platformBody: Color(0xFF1F2937),
          platformAccent: Color(0xFFEF4444),
          particleEmoji: '🔥',
        );
      default:
        return const _LumoTheme(
          skyTop: Color(0xFFBAE6FD),
          skyMid: Color(0xFFE0F2FE),
          skyBottom: Color(0xFFFEF3C7),
          sunColor: Color(0xFFFCD34D),
          mountainBack: Color(0xFF86EFAC),
          mountainFront: Color(0xFF22C55E),
          platformTop: Color(0xFF4ADE80),
          platformBody: Color(0xFF92400E),
          platformAccent: Color(0xFF15803D),
        );
    }
  }
}
