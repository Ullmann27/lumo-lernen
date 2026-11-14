import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../../../domain/games/memory_board.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';
import 'lumo_memory_stage.dart';
import 'lumo_memory_garden.dart';
import '../shared/lumo_game_pause_scope.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../lumo3d/lumo3d_launcher.dart';
import '../../lumo3d/native_table_transport.dart';
import '../../lumo3d/native_method_table_transport.dart';
import 'memory_flutter_adapter.dart';
import 'memory_round.dart';
import 'memory_table_session.dart';
import 'memory_turn_scheduler.dart';

class LumoMemoryScreen extends StatefulWidget {
  const LumoMemoryScreen({
    super.key,
    required this.appState,
    this.seed,
    this.difficulty,
    this.pack,
    this.nativeTransport = const NativeMethodTableTransport(),
    this.turnMilliseconds,
  });
  final int? seed;
  final LumoAppState appState;
  final MemoryDifficulty? difficulty;
  final MemoryThemePack? pack;
  final NativeTableTransport nativeTransport;
  final int Function()? turnMilliseconds;

  @override
  State<LumoMemoryScreen> createState() => _LumoMemoryScreenState();
}

enum _Player { kind, lumo }

class _LumoMemoryScreenState extends State<LumoMemoryScreen>
    with WidgetsBindingObserver {
  static const _flip = Duration(milliseconds: 460);
  late final LumoAppState _statsApp;
  late final int _profileGeneration;
  LearningProfileLease? _statsOwner;
  MemoryRoundController? _controller;
  MemoryTableSession? _session;
  final _clock = LumoGameTurnClock();
  late final MemoryTurnScheduler _turnScheduler;
  final _lumo = LumoCharacterController();
  Future<void> _actions = Future<void>.value();
  int _pendingActions = 0;
  int _queuedFlips = 0;
  int _generation = 0;
  bool _profileChanged = false;
  bool _loading = true;
  bool _nativePreparing = false;
  bool _nativeLaunching = false;
  int _nativeAttempt = 0;
  bool _syncingPause = false;
  String? _error;
  String? _shownResult;
  String? _lastRound;
  Map<String, int> _bestAtRoundStart = {};
  DialogRoute<void>? _resultRoute;

  bool get _currentProfile => mounted && !_profileChanged &&
      identical(widget.appState, _statsApp) &&
      _statsApp.profileGeneration == _profileGeneration;
  bool get _leaseCurrent {
    final owner = _statsOwner;
    return _currentProfile && owner != null &&
        _statsApp.canUseLearningLease(owner) &&
        _statsApp.school.cachedActiveStudentId ==
            (owner.logStudentId == 'self' ? null : owner.studentId);
  }
  bool get _canPlay => _leaseCurrent && !_loading && !_nativeLaunching && _controller != null;
  MemoryRoundController get _game => _controller!;
  MemoryDifficulty get _difficulty => MemoryDifficulty.values.byName(_game.state.difficulty);
  MemoryThemePack get _pack => MemoryThemePack.values.byName(_game.state.pack);
  List<MemoryMotif> get _cards => _game.state.cards.map(MemoryMotif.values.byName).toList();
  List<bool> get _matched => _game.state.matched;
  List<bool> get _faceUp => _game.state.faceUp;
  int get _kindPairs => _game.state.kindPairs;
  int get _lumoPairs => _game.state.lumoPairs;
  int get _kindMoves => _game.state.kindMoves;
  int get _kindStreak => _game.state.kindStreak;
  int get _total => _game.state.cards.length;
  _Player get _turn => _game.state.turn == 'kind' ? _Player.kind : _Player.lumo;
  bool get _busy => _pendingActions > 0 || _game.state.busy;
  Map<String, int> get _best => _game.best;
  String get _lumoLine => _error ?? _game.state.line;
  bool get _reduceMotion => widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _statsApp = widget.appState;
    _profileGeneration = _statsApp.profileGeneration;
    _statsApp.addListener(_checkProfile);
    _clock.addListener(_pauseChanged);
    _turnScheduler = MemoryTurnScheduler(
      milliseconds: widget.turnMilliseconds,
    );
    WidgetsBinding.instance.addObserver(this);
    // Capture the child before preferences, native opening or wallet awaits.
    final captured = _statsApp.captureLearningProfile();
    unawaited(_load(captured));
  }

  Future<void> _load(Future<LearningProfileLease> captured) async {
    try {
      final owner = await captured;
      if (!_currentProfile || !_statsApp.canUseLearningLease(owner)) return;
      _statsOwner = owner;
      final preferences = await SharedPreferences.getInstance();
      if (!_leaseCurrent) return;
      final key = sha256.convert(utf8.encode(owner.studentId)).toString();
      final controller = await MemoryRoundController.open(
        owner: key,
        catalog: const FlutterMemoryCatalog(),
        store: PreferencesMemoryStore(preferences, key),
        canUseProfile: () => _leaseCurrent,
        difficulty: widget.difficulty?.name,
        pack: widget.pack?.name,
        seed: widget.seed,
        configureUnplayed: widget.seed != null || widget.difficulty != null || widget.pack != null,
        award: (id, difficulty, kind, lumo) => _statsApp.recordMemoryResult(
          lease: owner, resultId: id, difficulty: difficulty,
          kindPairs: kind, lumoPairs: lumo,
        ),
      );
      if (!_leaseCurrent) { controller.dispose(); return; }
      _controller = controller;
      _bestAtRoundStart = controller.best;
      _loading = false;
      _sync();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_leaseCurrent) return;
        _speak(controller.restored
            ? 'Deine gespeicherte Runde wartet auf dich.'
            : controller.state.line);
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          await _openNative();
        }
      });
    } catch (_) {
      if (_currentProfile) {
        setState(() {
          _loading = false;
          _error = 'Dein Spielstand konnte noch nicht sicher geladen werden. Bitte öffne Memory erneut.';
        });
      }
    }
  }

  Future<void> _openNative() async {
    if (!_canPlay || _nativePreparing || _pendingActions != 0) return;
    final attempt = ++_nativeAttempt;
    _turnScheduler.cancelElapsed();
    setState(() => _nativePreparing = true);
    final session = MemoryTableSession(
      controller: _game, transport: widget.nativeTransport, reduceMotion: _reduceMotion,
    );
    _session = session;
    try {
      await session.open();
      if (!_leaseCurrent || !mounted || attempt != _nativeAttempt || _pendingActions != 0) return;
      setState(() => _nativeLaunching = true);
      await launchLumo3D(context, scene: 'memory', appState: _statsApp, tableToken: session.token);
    } catch (_) {
      // Missing native support keeps the same authoritative round available
      // in Flutter. No synthetic native success or new board is introduced.
    } finally {
      try {
        await session.close(persist: identical(_session, session) && _nativeLaunching);
      } catch (_) {}
      // A Flutter turn may already have detached this automatic opening.
      // Its late reply must not cancel or restart that turn's local timer.
      if (identical(_session, session)) {
        _session = null;
        if (_leaseCurrent) {
          setState(() { _nativePreparing = false; _nativeLaunching = false; });
          _sync();
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The Android table Activity has its own foreground/authority heartbeat.
    // Flutter backgrounding for that Activity must not pause its Dart owner.
    if (state != AppLifecycleState.resumed && !_nativeLaunching && _canPlay) _clock.pause();
  }

  @override
  void didUpdateWidget(covariant LumoMemoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.appState, _statsApp)) _checkProfile();
  }

  void _checkProfile() {
    if (!mounted || _profileChanged || _currentProfile) return;
    _turnScheduler.dispose();
    _controller?.dispose();
    final session = _session;
    _session = null;
    if (session != null) unawaited(session.close(persist: false));
    final result = _resultRoute;
    _resultRoute = null;
    if (result != null) result.navigator?.removeRoute(result);
    setState(() => _profileChanged = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statsApp.removeListener(_checkProfile);
    _clock.removeListener(_pauseChanged);
    _clock.dispose();
    _turnScheduler.dispose();
    _controller?.dispose();
    final session = _session;
    if (session != null) unawaited(session.close(persist: false));
    _lumo.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) {
    if (!_canPlay) return Future<void>.value();
    // A real Flutter choice while optional native availability is pending
    // wins over that automatic attempt. It must not be covered or discarded.
    if (_nativePreparing && !_nativeLaunching) {
      _nativeAttempt++;
      final opening = _session;
      _session = null;
      _nativePreparing = false;
      // close invalidates the opening generation synchronously. The UI never
      // waits for its platform reply before resolving the child's real turn.
      if (opening != null) unawaited(opening.close(persist: false));
    }
    _pendingActions++;
    setState(() {});
    final operation = _actions.then((_) async {
      if (!_canPlay) return;
      await action();
      if (_leaseCurrent) _error = null;
    });
    final handled = operation.catchError((Object _, StackTrace __) {
      if (_leaseCurrent) {
        _error = 'Speichern noch nicht bestätigt. Bitte erneut versuchen.';
        _syncingPause = true;
        _clock.pause();
        _syncingPause = false;
      }
    }).whenComplete(() {
      _pendingActions--;
      if (_leaseCurrent) _sync();
    });
    _actions = handled;
    return handled;
  }

  void _sync() {
    if (!_leaseCurrent || _controller == null) return;
    final id = _game.round.id;
    if (_lastRound != id) {
      _lastRound = id;
      _generation++;
      _shownResult = null;
    }
    _syncingPause = true;
    if (_game.round.paused || _error != null) {
      _clock.pause();
    } else {
      _clock.resume();
    }
    _syncingPause = false;
    setState(() {});
    _turnScheduler.cancelElapsed();
    if (!_nativePreparing && _session == null && !_clock.value &&
        _pendingActions == 0 && _game.state.remainingMs > 0) {
      final round = _game.round.id;
      final revision = _game.round.revision;
      _turnScheduler.schedule(_game.state.remainingMs, (elapsed) {
        if (!_canPlay || _clock.value || _game.round.id != round ||
            _game.round.revision != revision) return;
        unawaited(_run(() async { await _game.advance(elapsed); }));
      });
    }
    if (!_nativePreparing && !_clock.value && _pendingActions == 0 &&
        _game.state.complete && _game.round.rewarded && _shownResult != id) {
      _shownResult = id;
      // The durable turn has already completed outside build. Queue the
      // route before the next frame rather than inserting it after that frame.
      scheduleMicrotask(() {
        if (_canPlay && !_clock.value && _game.round.id == id) {
          _showGameOver();
        } else if (_shownResult == id) {
          _shownResult = null;
        }
      });
    }
  }

  void _pauseChanged() {
    if (_syncingPause || !_canPlay) return;
    final pause = _clock.value;
    final elapsed = _turnScheduler.cancelElapsed();
    unawaited(_run(() => _game.setPaused(pause, elapsedMs: pause ? elapsed : 0)));
  }

  void _tapCard(int index) {
    if (!_canPlay || _clock.value || !_game.state.canFlip || _queuedFlips >= 2) return;
    final round = _game.round.id;
    _queuedFlips++;
    unawaited(_run(() async {
      // Keep at most the two real card choices. The authority validates them
      // in order after each durable save; stale round/pause input is refused.
      if (_clock.value || _game.round.id != round) return;
      if (await _game.flip(index)) {
        // Optional platform feedback cannot hold the durable turn/pause queue.
        unawaited(HapticFeedback.lightImpact().catchError((Object _, StackTrace __) {}));
      }
    }).whenComplete(() => _queuedFlips--));
  }

  void _restart({MemoryDifficulty? difficulty, MemoryThemePack? pack}) {
    if (!_canPlay) return;
    _turnScheduler.cancelElapsed();
    unawaited(_run(() async {
      _bestAtRoundStart = _game.best;
      await _game.restart(difficulty: difficulty?.name, pack: pack?.name);
      _speak('Neue Runde! Du fängst an.');
    }));
  }

  Future<void> _leave() async {
    if (!_canPlay) return;
    final elapsed = _turnScheduler.cancelElapsed();
    var saved = false;
    await _run(() async {
      await _game.setPaused(true, elapsedMs: elapsed);
      await _game.flush();
      saved = true;
    });
    if (saved && _leaseCurrent && mounted) Navigator.of(context).pop();
  }

  void _speak(String text) {
    try { LumoVoice.instance.speak(text); } catch (_) {}
  }

  void _showGameOver() {
    if (!_canPlay || !_game.round.rewarded || !_game.state.complete) return;
    HapticFeedback.heavyImpact();
    final kindWon = _kindPairs > _lumoPairs;
    final draw = _kindPairs == _lumoPairs;
    final stars = _game.state.stars;
    final old = _bestAtRoundStart[_difficulty.name];
    final record = kindWon && old != null && _kindMoves < old;
    if (kindWon) _lumo.cheer();
    if (!kindWon && !draw) _lumo.comfort();
    _speak(_game.state.line);
    final title = kindWon ? 'Du hast gewonnen!' : draw ? 'Unentschieden' : 'Lumo gewinnt';
    final result = DialogRoute<void>(
      context: context, barrierDismissible: false,
      builder: (dialogContext) => LumoGameResultBack(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: _ResultCard(
            title: title,
            pairsLine: 'Du: $_kindPairs Paare    Lumo: $_lumoPairs Paare',
            stars: stars, maxStars: 5, record: record,
            moves: kindWon ? _kindMoves : null, won: kindWon,
            reduceMotion: _reduceMotion,
            onAgain: () { Navigator.of(dialogContext).pop(); _restart(); },
            onBack: () { Navigator.of(dialogContext).pop(); unawaited(_leave()); },
          ),
        ),
      ),
    );
    _resultRoute = result;
    Navigator.of(context).push(result).whenComplete(() {
      if (identical(_resultRoute, result)) _resultRoute = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_currentProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lumo Memory')),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Das Kinderprofil hat gewechselt. Öffne Memory erneut für dieses Kind.',
              textAlign: TextAlign.center),
        )),
      );
    }
    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lumo Memory')),
        body: Center(child: _loading
            ? const CircularProgressIndicator(semanticsLabel: 'Memory wird vorbereitet')
            : Padding(padding: const EdgeInsets.all(24),
                child: Text(_error ?? 'Memory ist noch nicht bereit.', textAlign: TextAlign.center))),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _clock.pause(); },
      child: Stack(fit: StackFit.expand, children: [
        TickerMode(
          enabled: !_clock.value,
          child: Scaffold(
            backgroundColor: const Color(0xFF3E6A3A),
            body: Stack(fit: StackFit.expand, children: [
              const LumoMemoryGarden(),
              const LumoMemoryGardenFrame(),
              SafeArea(child: LayoutBuilder(builder: (context, c) {
                final landscape = c.maxWidth >= c.maxHeight * 1.12;
                return landscape
                    ? _buildLandscape(c.maxWidth, c.maxHeight)
                    : _buildPortrait(c.maxWidth, c.maxHeight);
              })),
            ]),
          ),
        ),
        if (_nativeLaunching)
          const ColoredBox(
            key: ValueKey('memory-native-opening'),
            color: Color(0xF011253A),
            child: Center(child: CircularProgressIndicator(semanticsLabel: 'Memory-Tisch wird geöffnet')),
          )
        else if (_clock.value)
          LumoPausePanel(
            onResume: () => _clock.resume(),
            onRestart: () => _restart(),
            onLeave: () => unawaited(_leave()),
          ),
      ]),
    );
  }

  Widget _topBar({required double logoHeight}) {
    return SizedBox(
      height: math.max(56.0, logoHeight + 4),
      child: Row(children: [
        _RoundIconButton(
          key: const ValueKey('memory-close'),
          icon: Icons.close_rounded,
          tooltip: 'Pausieren / Zurück',
          onTap: _clock.pause,
        ),
        Expanded(
          child: Center(
            child: Semantics(
              header: true,
              label: 'Memory mit Lumo',
              excludeSemantics: true,
              child: Image.asset(
                'assets/lumo_design/memory/logo_memory.png',
                height: logoHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
        _RoundIconButton(
          key: const ValueKey('memory-restart'),
          icon: Icons.refresh_rounded,
          tooltip: 'Neu starten',
          onTap: _clock.pause,
        ),
      ]),
    );
  }

  Widget _lumoFigure(double size) => LumoCharacter(
        key: const ValueKey('memory-lumo'),
        pose: LumoDesignFoxPose.cheer,
        celebratePose: LumoDesignFoxPose.spielweltJump,
        size: size,
        shadow: false,
        reduceMotion: _reduceMotion,
        controller: _lumo,
        onTap: _lumo.wiggle,
      );

  Widget _scores() => Row(children: [
        Expanded(
          child: _ScorePill(
            label: 'Du',
            score: _kindPairs,
            color: LumoVisualTokens.gold,
            active: _turn == _Player.kind,
            total: _total ~/ 2,
            reduceMotion: _reduceMotion,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScorePill(
            label: 'Lumo',
            score: _lumoPairs,
            color: LumoVisualTokens.cyanBright,
            active: _turn == _Player.lumo,
            total: _total ~/ 2,
            reduceMotion: _reduceMotion,
          ),
        ),
      ]);

  String get _turnText => _turn == _Player.kind
      ? (_busy ? 'Lass die Karten kurz...' : 'Du bist dran! Tipp 2 Karten.')
      : (_busy ? 'Lumo denkt nach...' : 'Lumo ist dran!');

  Widget _comboBanner() => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: DecoratedBox(
          key: const ValueKey('memory-combo-banner'),
          decoration: BoxDecoration(
            color: const Color(0xE8FFF3C4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8C45A), width: 1.6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Combo x$_kindStreak!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7A4A10)),
            ),
          ),
        ),
      );

  Widget _chips() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemePackChips(
            selected: _pack,
            onSelect: (pack) {
              if (pack != _pack) _restart(pack: pack);
            },
          ),
          const SizedBox(height: 6),
          _DifficultyChips(
            selected: _difficulty,
            best: _best,
            onSelect: (d) {
              if (d != _difficulty) _restart(difficulty: d);
            },
          ),
        ],
      );

  Widget _buildPortrait(double w, double h) {
    final roomy = h >= 760;
    // Lumo lehnt sich wie im Zielbild hinter dem Brett hervor: Ein Teil der
    // Figur verschwindet hinter der Steinplatte, die Pfoten liegen am Rand.
    final lumoSize = roomy
        ? math.min(w * .5, 210.0)
        : (h >= 620 ? math.min(w * .34, 128.0) : 0.0);
    final hidden = lumoSize * .26;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(children: [
        _topBar(logoHeight: roomy ? math.min(96, h * .11) : 46),
        _scores(),
        if (_kindStreak >= 2) _comboBanner(),
        const SizedBox(height: 4),
        if (lumoSize > 0)
          SizedBox(
            height: lumoSize - hidden,
            child: LayoutBuilder(builder: (context, c) {
              final width = c.maxWidth;
              // Lumo steht links der Mitte, die Sprechblase rechts daneben –
              // nichts davon verdeckt sein Gesicht.
              final lumoLeft =
                  roomy ? width * .30 - lumoSize / 2 + lumoSize * .18 : 0.0;
              final bubbleLeft = lumoLeft + lumoSize * .78;
              return Stack(clipBehavior: Clip.none, children: [
                if (roomy)
                  Positioned(
                    left: 0,
                    top: 6,
                    width: lumoSize * .40,
                    child: _FloatingCard(
                        motif: MemoryMotif.panda,
                        angle: -.16,
                        phase: 0,
                        reduceMotion: _reduceMotion),
                  ),
                Positioned(
                  left: lumoLeft,
                  top: 0,
                  width: lumoSize,
                  height: lumoSize,
                  child: _lumoFigure(lumoSize),
                ),
                Positioned(
                  left: bubbleLeft,
                  right: 0,
                  top: roomy ? lumoSize * .12 : 4,
                  child: _SpeechBubble(text: _lumoLine),
                ),
              ]);
            }),
          ),
        Expanded(child: _board()),
        const SizedBox(height: 6),
        _TurnText(text: _turnText),
        const SizedBox(height: 4),
        _chips(),
      ]),
    );
  }

  Widget _buildLandscape(double w, double h) {
    final panelW = math.min(w * .36, 360.0);
    final lumoSize = math.min(h * .52, panelW * .8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(children: [
        SizedBox(
          width: panelW,
          child: Column(children: [
            _topBar(logoHeight: math.min(84, h * .18)),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      height: lumoSize,
                      width: panelW,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned(
                          left: 0,
                          top: lumoSize * .08,
                          width: panelW * .28,
                          child: _FloatingCard(
                              motif: MemoryMotif.giraffe,
                              angle: -.18,
                              phase: .2,
                              reduceMotion: _reduceMotion),
                        ),
                        Positioned(
                          right: 0,
                          top: lumoSize * .02,
                          width: panelW * .28,
                          child: _FloatingCard(
                              motif: MemoryMotif.pinguin,
                              angle: .16,
                              phase: .7,
                              reduceMotion: _reduceMotion),
                        ),
                        Center(child: _lumoFigure(lumoSize)),
                      ]),
                    ),
                    _SpeechBubble(text: _lumoLine),
                  ]),
                ),
              ),
            ),
            _scores(),
            const SizedBox(height: 6),
            _TurnText(text: _turnText),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: [
            Expanded(child: _board()),
            const SizedBox(height: 8),
            _chips(),
          ]),
        ),
      ]),
    );
  }

  Widget _board() {
    final reduce = _reduceMotion;
    // Runder Sandsteintisch wie auf der Referenz (p4-16): die Karten liegen
    // auf der gemalten Platte; Gesten bleiben beim Raster.
    return LumoMemoryStage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: LayoutBuilder(builder: (context, c) {
          const gap = 8.0;
          const aspect = .74;
          final grid =
              MemoryBoard.bestGrid(_total, c.maxWidth, c.maxHeight, gap: gap);
          final cardW = math.min(
            (c.maxWidth - gap * (grid.cols - 1)) / grid.cols,
            ((c.maxHeight - gap * (grid.rows - 1)) / grid.rows) * aspect,
          );
          final cardH = cardW / aspect;
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var r = 0; r < grid.rows; r++) ...[
                if (r > 0) const SizedBox(height: gap),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var col = 0; col < grid.cols; col++) ...[
                    if (col > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: cardW,
                      height: cardH,
                      child: _card(r * grid.cols + col, reduce),
                    ),
                  ],
                ]),
              ],
            ]),
          );
        }),
      ),
    );
  }

  Widget _card(int idx, bool reduce) {
    final showFront = _faceUp[idx] || _matched[idx];
    final motif = _cards[idx];
    return Semantics(
      label: 'Memory Karte ${idx + 1}'
          '${showFront ? ', ${motif.label}' : ', verdeckt'}'
          '${_matched[idx] ? ', Paar gefunden' : ''}',
      button: !_matched[idx],
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('memory-card-$idx'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapCard(idx),
        child: _MemoryCard(
          key: ValueKey('memory-card-$_generation-$idx'),
          index: idx,
          motif: motif,
          faceUp: showFront,
          matched: _matched[idx],
          reduceMotion: reduce,
          duration: _flip,
        ),
      ),
    );
  }
}

// ═══════════════════════════ Karte mit 3D-Flip ═══════════════════════════

class _MemoryCard extends StatefulWidget {
  const _MemoryCard({
    super.key,
    required this.index,
    required this.motif,
    required this.faceUp,
    required this.matched,
    required this.reduceMotion,
    required this.duration,
  });

  final int index;
  final MemoryMotif motif;
  final bool faceUp;
  final bool matched;
  final bool reduceMotion;
  final Duration duration;

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: w.faceUp ? 1 : 0),
        duration: w.reduceMotion ? const Duration(milliseconds: 1) : w.duration,
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) {
          final front = t > .5;
          final double lift = 1.0 +
              (w.reduceMotion ? 0.0 : .04 * math.sin(t * math.pi)) +
              (_pressed && !w.faceUp && !w.reduceMotion ? .03 : 0.0);
          final face = front
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _CardFront(motif: w.motif, matched: w.matched),
                )
              : _CardBack(index: w.index);
          return Transform.scale(
            scale: lift,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0014)
                ..rotateY(t * math.pi),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  face,
                  if (w.matched && !w.reduceMotion)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: const _MatchSparkle(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('memory-back-$index'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3E8A4A),
            Color(0xFF2A6A38),
            Color(0xFF1A4A28),
            Color(0xFF2F7340),
          ],
          stops: [0, .28, .78, 1],
        ),
        border: Border.all(color: const Color(0xFFE8C45A), width: 2.7),
        boxShadow: const [
          BoxShadow(color: Color(0x99C9A227), blurRadius: 11),
          BoxShadow(
              color: Color(0x66020A24), blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xCCFFE7A0), width: 1.2),
            ),
          ),
        ),
        const Center(
          child: FractionallySizedBox(
            widthFactor: .62,
            heightFactor: .74,
            child: FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_rounded,
                      color: Color(0xFFD8F0A8),
                      size: 72,
                      shadows: [
                        Shadow(color: Color(0xAA8FE08A), blurRadius: 16)
                      ]),
                  SizedBox(height: 2),
                  Icon(Icons.pets_rounded,
                      color: Color(0xFFE8C45A),
                      size: 22,
                      shadows: [
                        Shadow(color: Color(0x66FFE08A), blurRadius: 8)
                      ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.motif, required this.matched});
  final MemoryMotif motif;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final glow = matched ? const Color(0xFFFFD86B) : const Color(0xFFE8C45A);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A2A58),
        border: Border.all(
            color: matched ? const Color(0xFFFFE9A6) : const Color(0xFFE4B84A),
            width: 2.8),
        boxShadow: [
          BoxShadow(
              color: glow.withOpacity(matched ? .85 : .42),
              blurRadius: matched ? 18 : 10,
              spreadRadius: matched ? 2 : 0),
        ],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: motif.sticker
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(
                              const Color(0xFFFFF6DC), motif.tintLight, .22)!,
                          Color.lerp(
                              const Color(0xFFE8C97A), motif.tintDark, .18)!,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(motif.path,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium),
                    ),
                  )
                : Image.asset(motif.path,
                    fit: BoxFit.cover, filterQuality: FilterQuality.medium),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x99FFF3C4), width: 1.1),
            ),
          ),
        ),
        if (matched)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              key: const ValueKey('memory-matched-mark'),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9A6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8A5A11)),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 16, color: Color(0xFF18334D)),
            ),
          ),
      ]),
    );
  }
}

/// Goldene Funken, die einmal aus einem gefundenen Paar herausfliegen.
class _MatchSparkle extends StatelessWidget {
  const _MatchSparkle();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(painter: _SparklePainter(t)),
      );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (.55 + .5 * t);
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * math.pi + .3;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      final fade = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = const Color(0xFFFFE08A).withOpacity(fade);
      canvas.drawCircle(p, 2.4 + 2 * fade, paint);
      canvas.drawRect(
          Rect.fromCenter(center: p, width: 9 * fade + 2, height: 1.4), paint);
      canvas.drawRect(
          Rect.fromCenter(center: p, width: 1.4, height: 9 * fade + 2), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

// ═══════════════════════════ Kleine Bausteine ═══════════════════════════

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xCC0B2A5C),
          side: const BorderSide(color: Color(0xAAE8C45A)),
        ),
      );
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    required this.color,
    required this.active,
    required this.total,
    required this.reduceMotion,
  });
  final int total;
  final bool reduceMotion;
  final String label;
  final int score;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: reduceMotion || MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xF20E3A7A) : const Color(0xB30B2A5C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : const Color(0x99E8C45A),
              width: active ? 2.4 : 1.2),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(.55), blurRadius: 14)]
              : null,
        ),
        child: Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.copy_all_rounded, color: color, size: 18),
                const SizedBox(width: 6),
                Text('$score',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text(' / $total',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFCCE0F5))),
              ]),
            ),
          ),
        ]),
      );
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xD90B2A5C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xCCE8C45A)),
        ),
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textScaler:
              MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.25),
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
      );
}

class _TurnText extends StatelessWidget {
  const _TurnText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
        style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Color(0xCC03193F), blurRadius: 6)]),
      );
}

class _ThemePackChips extends StatelessWidget {
  const _ThemePackChips({required this.selected, required this.onSelect});
  final MemoryThemePack selected;
  final ValueChanged<MemoryThemePack> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (final pack in MemoryThemePack.values) ...[
        if (pack != MemoryThemePack.values.first) const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            button: true,
            selected: pack == selected,
            label: 'Kartenpack ${pack.label}',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('memory-pack-${pack.name}'),
              onTap: () => onSelect(pack),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: pack == selected
                      ? const Color(0xFF3E8A4A)
                      : const Color(0xB30B2A5C),
                  border: Border.all(
                      color: pack == selected
                          ? const Color(0xFFB8F0A8)
                          : const Color(0x99E8C45A),
                      width: 1.6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(pack.label,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _DifficultyChips extends StatelessWidget {
  const _DifficultyChips(
      {required this.selected, required this.best, required this.onSelect});
  final MemoryDifficulty selected;
  final Map<String, int> best;
  final ValueChanged<MemoryDifficulty> onSelect;

  @override
  Widget build(BuildContext context) {
    final record = best[selected.name];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        for (final d in MemoryDifficulty.values) ...[
          if (d != MemoryDifficulty.values.first) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: d == selected,
              label: 'Schwierigkeit ${d.label}, ${d.cards} Karten',
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('memory-diff-${d.name}'),
                onTap: () => onSelect(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: d == selected
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFE7A0), Color(0xFFD4A024)])
                        : null,
                    color: d == selected ? null : const Color(0xB30B2A5C),
                    border: Border.all(
                        color: d == selected
                            ? const Color(0xFFFFF3C4)
                            : const Color(0x99E8C45A),
                        width: 1.6),
                    boxShadow: d == selected
                        ? const [
                            BoxShadow(color: Color(0x8CE8C45A), blurRadius: 12)
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(d.label,
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: d == selected
                                  ? const Color(0xFF2A1A08)
                                  : Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
      if (record != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Dein Rekord: $record Züge',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFE08A))),
        ),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.pairsLine,
    required this.stars,
    required this.maxStars,
    required this.record,
    required this.moves,
    required this.won,
    required this.reduceMotion,
    required this.onAgain,
    required this.onBack,
  });

  final String title;
  final String pairsLine;
  final int stars;
  final int maxStars;
  final bool record;
  final int? moves;
  final bool won;
  final bool reduceMotion;
  final VoidCallback onAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF2123F86), Color(0xF2071A3E)],
          ),
          border: Border.all(color: const Color(0xCCE8C45A), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66E8C45A), blurRadius: 24),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            LumoCharacter(
              pose: won
                  ? LumoDesignFoxPose.spielweltJump
                  : LumoDesignFoxPose.cheer,
              size: 120,
              shadow: false,
              reduceMotion: reduceMotion,
              celebratePose: null,
            ),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(pairsLine,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F4FF))),
            if (moves != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    record
                        ? 'Neuer Rekord: $moves Züge!'
                        : 'Geschafft in $moves Zügen',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFE08A))),
              ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < maxStars; i++)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.star_rounded,
                      size: 38,
                      color: i < stars
                          ? LumoVisualTokens.gold
                          : const Color(0x55FFFFFF)),
                ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E9BE8),
                  shape: const StadiumBorder(
                      side: BorderSide(color: Color(0xFFE8C45A), width: 2)),
                ),
                child: const Text('Nochmal!',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: onBack,
                child: const Text('Zur Spielewelt',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Schwebende, leicht gedrehte Tierkarte als Deko neben Lumo (Zielbild 02).
class _FloatingCard extends StatefulWidget {
  const _FloatingCard({
    required this.motif,
    required this.angle,
    required this.phase,
    required this.reduceMotion,
  });
  final MemoryMotif motif;
  final double angle;
  final double phase;
  final bool reduceMotion;

  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: .74,
        child: _CardFront(motif: widget.motif, matched: false),
      ),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: card,
        builder: (context, child) {
          final t = math.sin((_c.value + widget.phase) * 2 * math.pi);
          return Transform.translate(
            offset: Offset(0, t * 4),
            child:
                Transform.rotate(angle: widget.angle + t * .03, child: child),
          );
        },
      ),
    );
  }
}
