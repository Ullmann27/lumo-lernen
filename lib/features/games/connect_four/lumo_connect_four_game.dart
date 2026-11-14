import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../../../widgets/design/lumo_motion.dart';
import '../shared/lumo_game_pause_scope.dart';
import 'connect_four_engine.dart';
import 'connect_four_round.dart';
import 'connect_four_table_session.dart';
import '../../lumo3d/lumo3d_launcher.dart';
import 'lumo_connect_four_stage.dart';

const _cyan = Color(0xFF53DDFD);
const _gold = Color(0xFFFFD166);
const _ink = Color(0xFF071A3D);
const _panel = Color(0xEB0C2C58);
const _columnTouchSize = 48.0;
const _boardPadding = 10.0;
const _boardBorderWidth = 2.4;
const _boardContentInset = _boardPadding + _boardBorderWidth;
const _minimumBoardWidth =
    ConnectFourEngine.columns * _columnTouchSize + _boardContentInset * 2;

class LumoConnectFourScreen extends StatefulWidget {
  const LumoConnectFourScreen({super.key, required this.appState, this.seed});

  final LumoAppState appState;
  final int? seed;

  @override
  State<LumoConnectFourScreen> createState() => _LumoConnectFourScreenState();
}

class _LumoConnectFourScreenState extends State<LumoConnectFourScreen>
    with SingleTickerProviderStateMixin {
  final ConnectFourEngine _empty = ConnectFourEngine();
  ConnectFourRoundController? _controller;
  LearningProfileLease? _owner;
  ConnectFourEngine get _game => _controller?.engine ?? _empty;
  bool _loading = true;
  bool _nativeOpening = false;
  bool _nativeUnavailable = false;
  String? _loadError;
  ConnectFourTableSession? _nativeSession;

  bool _currentOwner() =>
      mounted &&
      _owner != null &&
      !widget.appState.resetting &&
      widget.appState.canUseLearningLease(_owner!) &&
      widget.appState.profileGeneration == _owner!.generation &&
      widget.appState.school.cachedActiveStudentId ==
          (_owner!.logStudentId == 'self' ? null : _owner!.studentId);

  Future<void> _initializeRound() async {
    try {
      final owner = await widget.appState.captureLearningProfile();
      if (!mounted) return;
      _owner = owner;
      if (!_currentOwner()) throw StateError('Kinderprofil hat gewechselt');
      final controller = await ConnectFourRoundController.open(
        studentId: owner.studentId,
        canUseProfile: _currentOwner,
        seed: widget.seed,
        award: (id, stars, xp) => widget.appState.recordConnectFourResult(
            lease: owner, resultId: id, stars: stars, xp: xp),
      );
      if (!_currentOwner()) {
        controller.dispose();
        return;
      }
      _controller = controller;
      setState(() {
        _loading = false;
        _loadError = null;
        _syncRound();
      });
      unawaited(LumoVoice.instance
          .speak(controller.announcement, style: VoiceStyle.greeting));
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _openNative();
      } else if (_game.phase == ConnectPhase.playing &&
          !_twoPlayers &&
          _game.turn == ConnectPiece.lumo) {
        _resumeBot();
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadError =
              'Deine gespeicherte Runde konnte nicht sicher geladen werden. '
              'Die vorhandenen Daten bleiben erhalten.';
        });
    }
  }

  void _syncRound() {
    final controller = _controller;
    if (controller == null) return;
    _twoPlayers = controller.round.twoPlayers;
    _lumoLevel = controller.round.level;
    _completedChildMoves = (_game.moves + 1) ~/ 2;
    _message = _game.phase == ConnectPhase.draw
        ? 'Unentschieden. Stark gespielt!'
        : _game.phase == ConnectPhase.won
            ? (_game.turn == ConnectPiece.child
                ? 'Du gewinnst!'
                : _twoPlayers
                    ? 'Gold gewinnt!'
                    : 'Lumo gewinnt!')
            : _game.turn == ConnectPiece.child
                ? 'Du bist dran!'
                : _twoPlayers
                    ? 'Gold ist dran!'
                    : 'Lumo denkt nach …';
  }

  void _resumeBot() {
    final generation = _round;
    _busy = true;
    _clock.schedule(const Duration(milliseconds: 540), () {
      if (!_currentOwner() || generation != _round || _nativeOpening) return;
      final column = _game.chooseLumoColumn(_random, level: _lumoLevel);
      if (column != null) _place(column);
    });
  }

  Future<void> _openNative() async {
    if (_controller == null || !_currentOwner() || _nativeOpening || _busy)
      return;
    _clock.pause();
    _clock.cancel();
    _round++;
    _fall.stop();
    setState(() => _nativeOpening = true);
    final session = ConnectFourTableSession(
        controller: _controller!, reduceMotion: _reduced);
    _nativeSession = session;
    var opened = false;
    try {
      await session.open();
      if (_currentOwner())
        opened = await launchLumo3D(context,
            scene: 'connect_four',
            appState: widget.appState,
            connectFourToken: session.token);
    } catch (_) {
      opened = false;
    } finally {
      await session.close();
      _nativeSession = null;
      if (mounted)
        setState(() {
          _nativeOpening = false;
          _fallPosition = null;
          _busy = false;
          _syncRound();
          if (!opened) _nativeUnavailable = true;
        });
    }
    if (!_currentOwner()) {
      if (mounted)
        setState(() => _loadError =
            'Das Kinderprofil hat gewechselt. Bitte zur Spielewelt zurückkehren.');
      return;
    }
    // Actual native return leaves the same Dart round explicitly paused.
    // Missing native integration falls back to the existing Flutter board.
    if (!opened) {
      _clock.resume();
      if (!_twoPlayers &&
          _game.turn == ConnectPiece.lumo &&
          _game.phase == ConnectPhase.playing) _resumeBot();
    } else if (!_twoPlayers &&
        _game.turn == ConnectPiece.lumo &&
        _game.phase == ConnectPhase.playing) {
      _resumeBot(); // scheduled but paused until the child chooses Fortsetzen
    }
  }

  final _clock = LumoGameTurnClock();
  late final math.Random _random;
  late final AnimationController _fall;
  ConnectPosition? _fallPosition;
  ConnectPiece _fallPiece = ConnectPiece.empty;
  bool _busy = false;
  bool _rewarded = false;
  bool _twoPlayers = false;
  ConnectLumoLevel _lumoLevel = ConnectLumoLevel.mittel;
  int? _winReplayIndex;
  int _round = 0;
  int _completedChildMoves = 0;
  String _message = 'Deine gespeicherte Runde wird geladen …';

  bool get _reduced =>
      widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode ||
      LumoMotion.reduced(context);

  @override
  void initState() {
    super.initState();
    _random = widget.seed == null ? math.Random() : math.Random(widget.seed);
    _fall = AnimationController(vsync: this);
    _clock.addListener(_pauseChanged);
    unawaited(_initializeRound());
  }

  void _pauseChanged() {
    if (_clock.value) {
      _fall.stop();
      unawaited(LumoVoice.instance.stop());
    } else if (_fallPosition != null && !_reduced) {
      _fall.forward();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _round++;
    unawaited(_nativeSession?.close());
    _controller?.dispose();
    _clock.removeListener(_pauseChanged);
    _clock.dispose();
    _fall.dispose();
    unawaited(LumoVoice.instance.stop());
    super.dispose();
  }

  void _restart() {
    unawaited(_restartRound());
  }

  Future<void> _restartRound({bool? twoPlayers}) async {
    if (_controller == null || !_currentOwner() || _nativeOpening) return;
    _round++;
    _clock.cancel();
    _fall.stop();
    setState(() => _busy = true);
    try {
      await _controller!.restart(twoPlayers: twoPlayers);
      if (!_currentOwner()) return;
      setState(() {
        _fall.reset();
        _fallPosition = null;
        _fallPiece = ConnectPiece.empty;
        _busy = false;
        _rewarded = false;
        _winReplayIndex = null;
        _syncRound();
      });
    } catch (_) {
      _saveError();
    }
  }

  void _saveError() {
    if (!mounted) return;
    _clock.pause();
    setState(() {
      _busy = false;
      _message = 'Speichern noch nicht bestätigt. Bitte erneut versuchen.';
    });
  }

  void _setMode(bool twoPlayers) {
    if (_twoPlayers != twoPlayers && !_busy)
      unawaited(_restartRound(twoPlayers: twoPlayers));
  }

  Future<void> _setLevel(ConnectLumoLevel level) async {
    if (_controller == null || !_currentOwner() || _busy) return;
    try {
      await _controller!.setLevel(level);
      if (_currentOwner()) setState(_syncRound);
    } catch (_) {
      _saveError();
    }
  }

  void _tapColumn(int column) {
    if (!_currentOwner() ||
        _nativeOpening ||
        _clock.value ||
        _busy ||
        _game.phase != ConnectPhase.playing) return;
    if (!_twoPlayers && _game.turn == ConnectPiece.lumo) return;
    _place(column);
  }

  Future<void> _place(int column) async {
    if (!_currentOwner() || _controller == null || _nativeOpening) return;
    final piece = _game.turn;
    final generation = _round;
    setState(() => _busy = true);
    ConnectPosition? position;
    try {
      position = await _controller!
          .play(column, bot: !_twoPlayers && piece == ConnectPiece.lumo);
    } catch (_) {
      _saveError();
      return;
    }
    if (!_currentOwner() || generation != _round) return;
    if (position == null) {
      setState(() => _busy = false);
      return;
    }
    if (piece == ConnectPiece.child) _completedChildMoves++;
    final round = _round;
    final duration = _reduced
        ? Duration.zero
        : Duration(milliseconds: 210 + position.row * 30);
    _fall.duration = duration;
    _fall.value = 0;
    setState(() {
      _busy = true;
      _fallPiece = piece;
      _fallPosition = position;
      _message = piece == ConnectPiece.child
          ? 'Dein Stein fällt!'
          : _twoPlayers
              ? 'Gold ist am Zug.'
              : 'Lumo setzt seinen Stein.';
    });
    if (!_reduced) _fall.forward();
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));
    // The same pausable clock controls landing and the bot. An animation
    // callback from an abandoned round can never advance a new game.
    void land() {
      if (!_currentOwner() || round != _round || _nativeOpening) return;
      _fall.value = 1;
      setState(() => _fallPosition = null);
      if (_game.phase != ConnectPhase.playing) {
        _finish();
      } else if (!_twoPlayers && _game.turn == ConnectPiece.lumo) {
        setState(() => _message = 'Lumo denkt nach …');
        _clock.schedule(const Duration(milliseconds: 540), () {
          if (!_currentOwner() || round != _round || _nativeOpening) return;
          final next = _game.chooseLumoColumn(_random, level: _lumoLevel);
          if (next != null) _place(next);
        });
      } else {
        setState(() {
          _busy = false;
          _message = _game.turn == ConnectPiece.child
              ? 'Du bist dran!'
              : 'Gold ist dran!';
        });
        // The visual turn label stays live on every move; narration is a
        // sparse reminder rather than an interruption after every move.
        if (_game.turn == ConnectPiece.child &&
            _completedChildMoves > 0 &&
            _completedChildMoves % 5 == 0) {
          unawaited(LumoVoice.instance.speak(
            (_completedChildMoves ~/ 5).isEven
                ? 'Überleg dir deinen nächsten Zug.'
                : 'Du bist wieder dran!',
          ));
        }
      }
    }

    if (duration == Duration.zero && !_clock.value) {
      land();
    } else {
      _clock.schedule(duration, land);
    }
  }

  void _finish() {
    if (_rewarded) return;
    _rewarded = true;
    final drawn = _game.phase == ConnectPhase.draw;
    final childWon = !drawn && _game.turn == ConnectPiece.child;
    final stars = drawn
        ? 3
        : childWon || _twoPlayers
            ? 5
            : 2;
    // The shared controller already persisted this result exactly once.
    setState(() {
      _busy = true;
      _message = drawn
          ? 'Unentschieden. Stark gespielt!'
          : childWon
              ? 'Vier in einer Reihe. Du gewinnst!'
              : _twoPlayers
                  ? 'Gold gewinnt!'
                  : 'Lumo gewinnt. Noch eine Runde?';
    });
    unawaited(LumoVoice.instance.speak(_message,
        style: childWon || drawn ? VoiceStyle.celebrate : VoiceStyle.comfort));
    final line = _game.winningLine;
    if (line.isEmpty) {
      _showResultDialog(stars);
      return;
    }
    _runWinReplay(line, stars, 0);
  }

  void _runWinReplay(List<ConnectPosition> line, int stars, int index) {
    if (!mounted) return;
    setState(() => _winReplayIndex = index);
    if (index + 1 < line.length) {
      _clock.schedule(const Duration(milliseconds: 220), () {
        _runWinReplay(line, stars, index + 1);
      });
      return;
    }
    _clock.schedule(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      setState(() => _winReplayIndex = null);
      _showResultDialog(stars);
    });
  }

  void _showResultDialog(int stars) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LumoGameResultBack(
        child: AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: _cyan),
          ),
          title: Text(_message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/lumo_design/fox/fox_cheer.png', height: 100),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 34, color: i < stars ? _gold : Colors.white24)),
            ),
            Text('+$stars Sterne',
                style: const TextStyle(color: _gold, fontSize: 18)),
          ]),
          actions: [
            LumoPressable(
              child: TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _restart();
                  },
                  child: const Text('Nochmal!')),
            ),
            LumoPressable(
              child: TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zur Spielewelt')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _loadError != null)
      return Scaffold(
        backgroundColor: _ink,
        appBar: AppBar(title: const Text('Vier gewinnt')),
        body: Center(
            child: _loading
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_loadError!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center))),
      );
    return LumoGamePauseScope(
      clock: _clock,
      onRestart: _restart,
      child: Scaffold(
        backgroundColor: _ink,
        body: Stack(fit: StackFit.expand, children: [
          const LumoConnectFourRoom(),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > constraints.maxHeight;
              // Use the edge space before making a phone board scroll.
              final horizontalPadding = wide
                  ? 20.0
                  : math.min(
                      12.0,
                      math.max(0.0,
                          (constraints.maxWidth - _minimumBoardWidth) / 2));
              return Column(children: [
                _header(),
                if (!wide) _modes(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 8),
                    child: wide
                        ? Row(children: [
                            Expanded(flex: 3, child: _playArea()),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _companion(wide: true)),
                          ])
                        : Builder(builder: (context) {
                            final companionH = math.min(222.0,
                                math.max(152.0, constraints.maxHeight * 0.24));
                            return Column(children: [
                              _turnLabel(),
                              const SizedBox(height: 8),
                              Expanded(child: _playArea()),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: companionH,
                                child:
                                    _companion(wide: false, height: companionH),
                              ),
                            ]);
                          }),
                  ),
                ),
                const SizedBox(height: 8),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _header() => Container(
        color: const Color(0xAA071A3D),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          LumoPressable(
            radius: 14,
            child: IconButton(
              tooltip: 'Pausieren / Zurück',
              onPressed: _clock.pause,
              icon: const Icon(Icons.arrow_back_rounded, color: _cyan),
            ),
          ),
          const Expanded(
            child: Text('LUMO • 4 GEWINNT',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFF0C6))),
          ),
          if (!kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android &&
              !_nativeUnavailable)
            IconButton(
              key: const ValueKey('connect-open-native'),
              tooltip: 'In 3D weiterspielen',
              onPressed: _busy || _nativeOpening
                  ? null
                  : () => unawaited(_openNative()),
              icon: const Icon(Icons.view_in_ar, color: _gold),
            ),
          LumoPressable(
            radius: 14,
            child: IconButton(
              tooltip: 'Neu starten',
              onPressed: _restart,
              icon: const Icon(Icons.refresh_rounded, color: _cyan),
            ),
          ),
        ]),
      );

  Widget _modes({bool compact = false}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(alignment: WrapAlignment.center, runSpacing: 8, children: [
          if (!_twoPlayers)
            for (final level in ConnectLumoLevel.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LumoPressable(
                  glowColor: _lumoLevel == level ? _gold : _cyan,
                  child: FilledButton(
                    key: ValueKey('connect-level-${level.name}'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(compact ? 88 : 100, 48),
                      textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w900),
                      padding:
                          EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
                      backgroundColor: _lumoLevel == level ? _gold : _panel,
                      foregroundColor:
                          _lumoLevel == level ? _ink : Colors.white,
                    ),
                    onPressed: () {
                      if (_lumoLevel == level) return;
                      unawaited(_setLevel(level));
                    },
                    child: Text(switch (level) {
                      ConnectLumoLevel.leicht => 'Leicht',
                      ConnectLumoLevel.mittel => 'Mittel',
                      ConnectLumoLevel.schlau => 'Schlau',
                    }),
                  ),
                ),
              ),
          for (final mode in [(false, 'Mit Lumo'), (true, 'Zu zweit')])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LumoPressable(
                glowColor: _twoPlayers == mode.$1 ? _gold : _cyan,
                child: FilledButton(
                  key: ValueKey('connect-mode-${mode.$1}'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(compact ? 104 : 116, 48),
                    textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                    padding:
                        EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
                    backgroundColor: _twoPlayers == mode.$1 ? _gold : _panel,
                    foregroundColor:
                        _twoPlayers == mode.$1 ? _ink : Colors.white,
                  ),
                  onPressed: () => _setMode(mode.$1),
                  child: Text(mode.$2),
                ),
              ),
            ),
        ]),
      );

  Widget _turnLabel() => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cyan.withValues(alpha: .55)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle,
                color: _game.turn == ConnectPiece.child ? _cyan : _gold,
                size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 16)),
            ),
          ]),
        ),
      );

  Widget _companion({required bool wide, double height = 160}) {
    Widget fox(double foxHeight) => RepaintBoundary(
          child: SizedBox(
            height: foxHeight,
            width: foxHeight * 1.12,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset('assets/lumo_design/fox/fox_thumb_wink.png',
                    key: const ValueKey('connect-companion-fox'),
                    height: foxHeight,
                    fit: BoxFit.contain),
                Positioned(
                  right: foxHeight * 0.02,
                  bottom: foxHeight * 0.16,
                  width: foxHeight * 0.30,
                  height: foxHeight * 0.30,
                  child: const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(-0.35, -0.42),
                          colors: [
                            Color(0xFFFFF6D0),
                            Color(0xFFFFD166),
                            Color(0xFFC48A20),
                          ],
                        ),
                        border: Border.fromBorderSide(
                          BorderSide(color: Color(0xFFFFF3C4), width: 1.5),
                        ),
                        boxShadow: [
                          BoxShadow(color: Color(0xAAFFD166), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    if (wide) {
      return LayoutBuilder(builder: (context, constraints) {
        // An embedded/foldable viewport may be smaller than MediaQuery.
        // Size the mascot from the space this panel actually receives.
        final compact = constraints.maxHeight < 360;
        return SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _modes(compact: compact),
            SizedBox(height: compact ? 4 : 12),
            _turnLabel(),
            const SizedBox(height: 8),
            fox(compact ? 64 : 210),
            if (!compact) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _discTray(piece: ConnectPiece.child, label: 'Du')),
                const SizedBox(width: 8),
                Expanded(
                    child: _discTray(piece: ConnectPiece.lumo, label: 'Lumo')),
              ]),
            ],
            const SizedBox(height: 4),
            const Text('Waagrecht, senkrecht oder diagonal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        );
      });
    }
    final foxH = math.min(height * 0.90, 188.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _discTray(piece: ConnectPiece.child, label: 'Du')),
        const SizedBox(width: 6),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 10,
              right: 10,
              bottom: 0,
              height: foxH * 0.26,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF8A6238), Color(0xFF4A3018)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: foxH * 0.08),
              child: fox(foxH),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Expanded(child: _discTray(piece: ConnectPiece.lumo, label: 'Lumo')),
      ],
    );
  }

  Widget _discTray({required ConnectPiece piece, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 13)),
        const SizedBox(height: 4),
        SizedBox(
          height: 74,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 2,
                right: 2,
                bottom: 0,
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF8A5A28), Color(0xFF3A220E)],
                    ),
                    border: Border.all(color: const Color(0xFFD4B07A)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < 4; i++)
                Positioned(
                  bottom: 12 + i * 8.0,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: _disc(piece),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _playArea() => LayoutBuilder(builder: (context, constraints) {
        const tableExtra = 28.0;
        const controlsGap = 8.0;
        final availableHeight = math.max(
            0.0,
            constraints.maxHeight -
                _columnTouchSize -
                controlsGap -
                tableExtra);
        final fittedWidth =
            math.min(constraints.maxWidth, availableHeight * 7 / 6);
        final width = math.max(fittedWidth, _minimumBoardWidth);
        final boardHeight = math.min(availableHeight, width * 6 / 7);
        // Board wells and their 48dp controls share one coordinate system.
        // On narrow/short displays they scroll together; only the well spacing
        // changes with the available height, never the column hit targets.
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(constraints.maxWidth, width),
            child: SingleChildScrollView(
              key: const ValueKey('connect-column-scroll'),
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    height: boardHeight + tableExtra,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -18,
                          right: -18,
                          bottom: 0,
                          height: boardHeight * 0.42 + tableExtra,
                          child: const IgnorePointer(
                            child: CustomPaint(
                              painter: LumoConnectFourTablePedestal(),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: boardHeight,
                          child: _board(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: controlsGap),
                  _columnControls(),
                ]),
              ),
            ),
          ),
        );
      });

  Widget _columnControls() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _boardContentInset),
        child: Row(children: [
          for (var c = 0; c < ConnectFourEngine.columns; c++)
            Expanded(
              child: LumoPressable(
                enabled: !_busy && !_clock.value,
                radius: 12,
                pressedScale: 1,
                child: IconButton(
                  key: ValueKey('connect-column-$c'),
                  tooltip: 'Stein in Spalte ${c + 1}',
                  style: IconButton.styleFrom(
                    backgroundColor: _panel,
                    minimumSize: const Size.square(_columnTouchSize),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _cyan.withValues(alpha: .5)),
                    ),
                  ),
                  onPressed: !_busy &&
                          !_clock.value &&
                          _game.phase == ConnectPhase.playing &&
                          _game.validColumns.contains(c)
                      ? () => _tapColumn(c)
                      : null,
                  icon: Icon(Icons.arrow_downward_rounded,
                      size: 24,
                      color: _busy
                          ? Colors.white24
                          : _game.turn == ConnectPiece.child
                              ? _cyan
                              : _gold),
                ),
              ),
            ),
        ]),
      );

  Widget _board() => Center(
        child: SizedBox.expand(
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 16,
                  right: -12,
                  bottom: -10,
                  width: 16,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10)),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0A4A86), Color(0xFF041226)],
                        ),
                        border: Border.all(color: const Color(0x6648D0F0)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: -8,
                  bottom: -14,
                  height: 16,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(12)),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0C3A6A), Color(0xFF030A18)],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(_boardPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xE0081636),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: const Color(0xFF8AF0FF),
                        width: _boardBorderWidth),
                    boxShadow: const [
                      BoxShadow(color: Color(0x8853DDFD), blurRadius: 28),
                      BoxShadow(color: Color(0x66FFD166), blurRadius: 18),
                      BoxShadow(
                          color: Color(0x90051633),
                          blurRadius: 14,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final w = constraints.maxWidth / 7;
                    final h = constraints.maxHeight / 6;
                    final diameter = math.min(w, h) * .80;
                    return GestureDetector(
                      key: const ValueKey('connect-board-tap-area'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          _tapColumn((details.localPosition.dx / w).floor()),
                      child: Stack(clipBehavior: Clip.none, children: [
                        for (var r = 0; r < 6; r++)
                          for (var c = 0; c < 7; c++)
                            Positioned(
                              left: c * w + (w - diameter) / 2,
                              top: r * h + (h - diameter) / 2,
                              width: diameter,
                              height: diameter,
                              child: Semantics(
                                key: ValueKey('connect-cell-$r-$c'),
                                label: 'Reihe ${r + 1}, Spalte ${c + 1}: '
                                    '${_game.at(r, c).name}',
                                child: _disc(
                                  _fallPosition == (row: r, column: c)
                                      ? ConnectPiece.empty
                                      : _game.at(r, c),
                                  winner: _game.winningLine
                                      .contains((row: r, column: c)),
                                  replayFocus: _winReplayIndex != null &&
                                      _winReplayIndex! <
                                          _game.winningLine.length &&
                                      _game.winningLine[_winReplayIndex!] ==
                                          (row: r, column: c),
                                ),
                              ),
                            ),
                        if (_fallPosition case final position?)
                          AnimatedBuilder(
                            animation: _fall,
                            builder: (context, _) {
                              final progress = Curves.bounceOut
                                  .transform(_fall.value.clamp(0, 1));
                              final top = -diameter +
                                  (position.row * h +
                                          (h - diameter) / 2 +
                                          diameter) *
                                      progress;
                              return Positioned(
                                left: position.column * w + (w - diameter) / 2,
                                top: top,
                                width: diameter,
                                height: diameter,
                                child: _disc(_fallPiece),
                              );
                            },
                          ),
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: LumoConnectFourGlassPlate(
                                columns: ConnectFourEngine.columns,
                                rows: ConnectFourEngine.rows,
                                diameterFactor: .80,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _disc(ConnectPiece piece,
      {bool winner = false, bool replayFocus = false}) {
    final empty = piece == ConnectPiece.empty;
    final color = piece == ConnectPiece.child ? _cyan : _gold;
    final disc = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: empty ? const Color(0xFF061028) : null,
        gradient: empty
            ? const RadialGradient(
                center: Alignment(0, 0.35),
                colors: [Color(0xFF030814), Color(0xFF102044)],
              )
            : RadialGradient(center: const Alignment(-.35, -.42), colors: [
                Color.lerp(color, Colors.white, .78)!,
                Color.lerp(color, Colors.white, .22)!,
                color,
                Color.lerp(color, _ink, .28)!,
              ], stops: const [
                0,
                .28,
                .68,
                1
              ]),
        border: Border.all(
            color: winner
                ? Colors.white
                : empty
                    ? const Color(0x665387BA)
                    : Color.lerp(color, Colors.white, .35)!,
            width: winner ? 3 : 1.8),
        boxShadow: [
          if (!empty)
            BoxShadow(
                color: color.withValues(alpha: winner ? .95 : .5),
                blurRadius: winner ? 24 : 9,
                spreadRadius: winner ? 3 : 0),
          if (winner)
            BoxShadow(
                color: Colors.white.withValues(alpha: .55), blurRadius: 10),
        ],
      ),
      child: empty
          ? null
          : Stack(fit: StackFit.expand, children: [
              Padding(
                padding: const EdgeInsets.all(3.2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.lerp(color, Colors.white, .55)!,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(-0.35, -0.42),
                child: FractionallySizedBox(
                  widthFactor: .34,
                  heightFactor: .22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .55),
                    ),
                  ),
                ),
              ),
              Center(
                child: FractionallySizedBox(
                  widthFactor: .42,
                  heightFactor: .42,
                  child: FittedBox(
                    child: Icon(
                      piece == ConnectPiece.child
                          ? Icons.auto_awesome_rounded
                          : Icons.circle_outlined,
                      color: _ink.withValues(alpha: .35),
                    ),
                  ),
                ),
              ),
            ]),
    );
    return AnimatedScale(
      scale: replayFocus ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: disc,
    );
  }
}
