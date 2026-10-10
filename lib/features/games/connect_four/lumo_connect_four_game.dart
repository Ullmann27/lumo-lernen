import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../../../widgets/design/lumo_motion.dart';
import '../shared/lumo_game_pause_scope.dart';
import 'connect_four_engine.dart';

const _cyan = Color(0xFF53DDFD);
const _gold = Color(0xFFFFD166);
const _ink = Color(0xFF071A3D);
const _panel = Color(0xEB0C2C58);

class LumoConnectFourScreen extends StatefulWidget {
  const LumoConnectFourScreen({super.key, required this.appState, this.seed});

  final LumoAppState appState;
  final int? seed;

  @override
  State<LumoConnectFourScreen> createState() => _LumoConnectFourScreenState();
}

class _LumoConnectFourScreenState extends State<LumoConnectFourScreen>
    with SingleTickerProviderStateMixin {
  ConnectFourEngine _game = ConnectFourEngine();
  final _clock = LumoGameTurnClock();
  late final math.Random _random;
  late final AnimationController _fall;
  ConnectPosition? _fallPosition;
  ConnectPiece _fallPiece = ConnectPiece.empty;
  bool _busy = false;
  bool _rewarded = false;
  bool _twoPlayers = false;
  int _round = 0;
  String _message = 'Vier in einer Reihe. Du fängst an!';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(LumoVoice.instance.speak(
          'Vier gewinnt! Du spielst mit Cyan, Lumo mit Gold. Du fängst an!',
          style: VoiceStyle.greeting,
        ));
      }
    });
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
    _clock.removeListener(_pauseChanged);
    _clock.dispose();
    _fall.dispose();
    unawaited(LumoVoice.instance.stop());
    super.dispose();
  }

  void _restart() {
    _round++;
    _clock.cancel();
    _fall.stop();
    _fall.reset();
    unawaited(LumoVoice.instance.stop());
    setState(() {
      _game = ConnectFourEngine();
      _fallPosition = null;
      _fallPiece = ConnectPiece.empty;
      _busy = false;
      _rewarded = false;
      _message = 'Neues Spiel. Du fängst an!';
    });
  }

  void _setMode(bool twoPlayers) {
    if (_twoPlayers == twoPlayers) return;
    _twoPlayers = twoPlayers;
    _restart();
  }

  void _tapColumn(int column) {
    if (_clock.value || _busy || _game.phase != ConnectPhase.playing) return;
    if (!_twoPlayers && _game.turn == ConnectPiece.lumo) return;
    _place(column);
  }

  void _place(int column) {
    final piece = _game.turn;
    final position = _game.drop(column);
    if (position == null) return;
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
    _clock.schedule(duration, () {
      if (!mounted || round != _round) return;
      _fall.value = 1;
      setState(() => _fallPosition = null);
      if (_game.phase != ConnectPhase.playing) {
        _finish();
      } else if (!_twoPlayers && _game.turn == ConnectPiece.lumo) {
        setState(() => _message = 'Lumo denkt nach …');
        _clock.schedule(const Duration(milliseconds: 540), () {
          if (!mounted || round != _round) return;
          final next = _game.chooseLumoColumn(_random);
          if (next != null) _place(next);
        });
      } else {
        setState(() {
          _busy = false;
          _message = _game.turn == ConnectPiece.child
              ? 'Du bist dran!'
              : 'Gold ist dran!';
        });
        if (_game.turn == ConnectPiece.child) {
          unawaited(LumoVoice.instance.speak('Du bist dran!'));
        }
      }
    });
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
    widget.appState.addStars(stars);
    widget.appState.addXp(drawn ? 20 : stars * 8);
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
  Widget build(BuildContext context) => LumoGamePauseScope(
        clock: _clock,
        onRestart: _restart,
        child: Scaffold(
          backgroundColor: _ink,
          body: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/lumo_design/bg/bg_glass_islands.png',
                fit: BoxFit.cover),
            const ColoredBox(color: Color(0x6603193F)),
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > constraints.maxHeight;
                return Column(children: [
                  _header(),
                  if (!wide) _modes(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: wide ? 20 : 12, vertical: 8),
                      child: wide
                          ? Row(children: [
                              Expanded(flex: 3, child: _board()),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: _companion(wide: true)),
                            ])
                          : Column(children: [
                              _turnLabel(),
                              const SizedBox(height: 12),
                              Expanded(child: _board()),
                              const SizedBox(height: 8),
                              _companion(wide: false),
                            ]),
                    ),
                  ),
                  _columnControls(),
                  const SizedBox(height: 8),
                ]);
              }),
            ),
          ]),
        ),
      );

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
            child: Text('LUMO 4 GEWINNT',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFF0C6))),
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
          for (final mode in [(false, 'Mit Lumo'), (true, 'Zu zweit')])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LumoPressable(
                glowColor: _twoPlayers == mode.$1 ? _gold : _cyan,
                child: FilledButton(
                  key: ValueKey('connect-mode-${mode.$1}'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(compact ? 104 : 116, 44),
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

  Widget _companion({required bool wide}) {
    Widget fox(double height) => RepaintBoundary(
          child: Image.asset('assets/lumo_design/fox/fox_thumb_wink.png',
              key: const ValueKey('connect-companion-fox'),
              height: height,
              fit: BoxFit.contain),
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
            const SizedBox(height: 4),
            const Text('Waagrecht, senkrecht oder diagonal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        );
      });
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      fox(80),
      const SizedBox(width: 12),
      const Flexible(
        child: Text(
            'Vier Steine. Eine Reihe.\nJeder Zug ist ein neuer Versuch!',
            style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
    ]);
  }

  Widget _columnControls() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              for (var c = 0; c < ConnectFourEngine.columns; c++)
                Expanded(
                  child: LumoPressable(
                    enabled: !_busy && !_clock.value,
                    radius: 12,
                    child: IconButton(
                      key: ValueKey('connect-column-$c'),
                      tooltip: 'Stein in Spalte ${c + 1}',
                      style: IconButton.styleFrom(
                        backgroundColor: _panel,
                        minimumSize: const Size(44, 48),
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
          ),
        ),
      );

  Widget _board() => Center(
        child: AspectRatio(
          aspectRatio: 7 / 6,
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xEF153E78),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cyan, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x7053DDFD), blurRadius: 24),
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
                return Stack(clipBehavior: Clip.none, children: [
                  for (var r = 0; r < 6; r++)
                    for (var c = 0; c < 7; c++)
                      Positioned(
                        left: c * w + (w - diameter) / 2,
                        top: r * h + (h - diameter) / 2,
                        width: diameter,
                        height: diameter,
                        child: Semantics(
                          label: 'Reihe ${r + 1}, Spalte ${c + 1}: '
                              '${_game.at(r, c).name}',
                          child: _disc(
                            _fallPosition == (row: r, column: c)
                                ? ConnectPiece.empty
                                : _game.at(r, c),
                            winner:
                                _game.winningLine.contains((row: r, column: c)),
                          ),
                        ),
                      ),
                  if (_fallPosition case final position?)
                    AnimatedBuilder(
                      animation: _fall,
                      builder: (context, _) {
                        final progress =
                            Curves.bounceOut.transform(_fall.value.clamp(0, 1));
                        final top = -diameter +
                            (position.row * h + (h - diameter) / 2 + diameter) *
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
                ]);
              }),
            ),
          ),
        ),
      );

  Widget _disc(ConnectPiece piece, {bool winner = false}) {
    final empty = piece == ConnectPiece.empty;
    final color = piece == ConnectPiece.child ? _cyan : _gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: empty ? const Color(0xFF081F4A) : null,
        gradient: empty
            ? null
            : RadialGradient(center: const Alignment(-.4, -.5), colors: [
                Color.lerp(color, Colors.white, .7)!,
                color,
                Color.lerp(color, _ink, .35)!,
              ], stops: const [
                0,
                .45,
                1
              ]),
        border: Border.all(
            color: winner
                ? Colors.white
                : empty
                    ? const Color(0xFF5387BA)
                    : color,
            width: winner ? 3 : 1.5),
        boxShadow: [
          if (!empty)
            BoxShadow(
                color: color.withValues(alpha: winner ? .8 : .35),
                blurRadius: winner ? 16 : 5),
        ],
      ),
      child: empty
          ? null
          : Center(
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
    );
  }
}
