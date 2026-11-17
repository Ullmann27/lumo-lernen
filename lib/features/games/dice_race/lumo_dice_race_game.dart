// ════════════════════════════════════════════════════════════════════════
// LUMO WÜRFEL-WETTLAUF — vereinfachtes Mensch-aergere-dich-nicht
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: kleine Kinderspiele mit Lumo als Gegner. Mensch-aergere-
// dich-nicht in voller Form mit 4 Figuren ist fuer ein Tablet-Game zu
// fummelig - hier eine 1-Figur-Variante mit den wichtigen Elementen:
//
//   - 30 Felder lineare Bahn
//   - Beide Spieler starten auf Feld 0
//   - Wuerfel 1-6 (zufaellig pro Klick)
//   - Wuerfel-Zahl = Schritte
//   - Wer auf das Feld des Gegners zieht, schickt den Gegner zurueck zum
//     Start (klassische "Aergern"-Regel)
//   - Wer zuerst Feld 30 erreicht, gewinnt
//   - Ueber-Wuerfeln ist erlaubt: man bleibt vor Feld 30 stehen
//
// Lumo-KI:
//   - Wuerfelt zufaellig (keine Kontrolle, ist Wuerfelspiel)
//   - Eine kleine Animation-Pause, damit es sich wie ein echter Zug
//     anfuehlt
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../shared/lumo_game_pause_scope.dart';
import '../shared/lumo_board_game_stage.dart';

class LumoDiceRaceScreen extends StatefulWidget {
  const LumoDiceRaceScreen({super.key, required this.appState, this.seed});
  final int? seed;
  final LumoAppState appState;

  @override
  State<LumoDiceRaceScreen> createState() => _LumoDiceRaceScreenState();
}

enum _Player { kind, lumo }

class _LumoDiceRaceScreenState extends State<LumoDiceRaceScreen>
    with TickerProviderStateMixin {
  static const int _goal = 30;

  int _kindPos = 0;
  int _lumoPos = 0;
  int? _lastRoll;
  _Player _turn = _Player.kind;
  bool _busy = false;
  String? _hint;
  late final math.Random _rng;
  late AnimationController _diceCtrl;
  final _clock = LumoGameTurnClock();

  @override
  void initState() {
    super.initState();
    _rng = widget.seed == null ? math.Random() : math.Random(widget.seed);
    _diceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say(
          'Würfel-Wettlauf! Wer zuerst beim Stern ist, gewinnt. Du fängst an!');
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    _diceCtrl.dispose();
    super.dispose();
  }

  void _say(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _resetGame() {
    _clock.cancel();
    _diceCtrl.reset();
    setState(() {
      _kindPos = 0;
      _lumoPos = 0;
      _lastRoll = null;
      _turn = _Player.kind;
      _busy = false;
      _hint = null;
    });
  }

  void _rollDice() {
    if (_clock.value || _busy || _turn != _Player.kind) return;
    if (_kindPos >= _goal || _lumoPos >= _goal) return;
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _hint = null;
    });
    // Wuerfel-Animation: rasende Zufallszahlen
    _animateRoll();
  }

  void _applyRoll(int roll) {
    if (_turn == _Player.kind) {
      var next = _kindPos + roll;
      if (next > _goal) next = _goal; // Stehen bleiben vor Ziel
      _kindPos = next;
      // Lumo schlagen?
      String? extra;
      if (_kindPos == _lumoPos && _kindPos != _goal && _lumoPos != 0) {
        _lumoPos = 0;
        extra = 'Du hast Lumo zurück zum Start geschickt! 🦊';
      }
      _hint = extra ?? 'Du würfelst $roll und gehst $roll Felder vor.';
      setState(() {});
      if (_kindPos >= _goal) {
        _onWin(_Player.kind);
        return;
      }
      // Lumo dran
      _turn = _Player.lumo;
      _clock.schedule(const Duration(milliseconds: 700), _lumoRoll);
    } else {
      var next = _lumoPos + roll;
      if (next > _goal) next = _goal;
      _lumoPos = next;
      String? extra;
      if (_lumoPos == _kindPos && _lumoPos != _goal && _kindPos != 0) {
        _kindPos = 0;
        extra = 'Oh nein - Lumo schlaegt dich zurueck zum Start!';
      }
      _hint = extra ?? 'Lumo würfelt $roll.';
      setState(() {});
      if (_lumoPos >= _goal) {
        _onWin(_Player.lumo);
        return;
      }
      _turn = _Player.kind;
      _busy = false;
      setState(() {});
      _say('Du bist dran!');
    }
  }

  void _lumoRoll() {
    if (!mounted || _turn != _Player.lumo) return;
    HapticFeedback.lightImpact();
    setState(() => _hint = 'Lumo würfelt…');
    _animateRoll();
  }

  void _animateRoll() {
    final settings = widget.appState.state.settings;
    if (!settings.reduceAnimations &&
        !settings.calmMode &&
        !MediaQuery.disableAnimationsOf(context)) {
      _diceCtrl.forward(from: 0);
    }
    _clock.schedule(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final roll = 1 + _rng.nextInt(6);
      setState(() => _lastRoll = roll);
      _clock.schedule(const Duration(milliseconds: 350), () {
        if (mounted) _applyRoll(roll);
      });
    });
  }

  void _onWin(_Player who) {
    HapticFeedback.heavyImpact();
    final kindWon = who == _Player.kind;
    final stars = kindWon ? 5 : 2;
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 8);
    _say(kindWon
        ? 'Du bist beim Stern! Du hast gewonnen! $stars Sterne!'
        : 'Lumo ist zuerst beim Stern. Nochmal probieren?');
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LumoGameResultBack(
          child: AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(kindWon ? '🎉 Du gewinnst!' : '🦊 Lumo gewinnt',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 22)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.star_rounded,
                  size: 38,
                  color: i < stars
                      ? const Color(0xFFFCD34D)
                      : const Color(0xFFD1D5DB)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Nochmal!',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Zur Spielewelt',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ),
        ],
      )),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LumoGamePauseScope(
        clock: _clock,
        onRestart: _resetGame,
        child: Scaffold(
          body: LumoBoardGameStage(
              child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: LayoutBuilder(builder: (context, bounds) {
                  if (bounds.maxWidth > bounds.maxHeight &&
                      (bounds.maxWidth >= 700 || bounds.maxHeight < 480)) {
                    return Row(children: [
                      Expanded(flex: 3, child: _buildTrack()),
                      SizedBox(
                          width: (bounds.maxWidth * .35).clamp(260.0, 360.0),
                          child: SingleChildScrollView(
                              child: Column(children: [
                            _buildDicePanel(),
                            _buildStatusBar(),
                          ]))),
                    ]);
                  }
                  return Column(children: [
                    _buildStatusBar(),
                    Expanded(child: _buildTrack()),
                    _buildDicePanel(),
                  ]);
                })),
              ],
            ),
          )),
        ));
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF235D78), Color(0xFF132744)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          tooltip: 'Pausieren / Zurück',
          onPressed: _clock.pause,
        ),
        const Expanded(
          child: Center(
            child: Text('Würfel-Wettlauf',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Neu starten',
          onPressed: _clock.pause,
        ),
      ]),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              _statusPill('Du', _kindPos, LumoBoardColors.gold,
                  isActive: _turn == _Player.kind),
              const SizedBox(width: 12),
              _statusPill('Lumo', _lumoPos, LumoBoardColors.cyan,
                  isActive: _turn == _Player.lumo),
            ],
          ),
          if (_hint != null) ...[
            const SizedBox(height: 8),
            Text(_hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5F4FF))),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String label, int pos, Color color,
      {required bool isActive}) {
    return Expanded(
      child: AnimatedContainer(
        duration: lumoBoardMotionDuration(context,
            reduceMotion: widget.appState.state.settings.reduceAnimations ||
                widget.appState.state.settings.calmMode),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: isActive
                  ? const [Color(0xFF1B466D), Color(0xFF102A4C)]
                  : const [Color(0xFF122D4B), Color(0xFF0B203C)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2.4),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Image.asset(
                label == 'Lumo'
                    ? 'assets/lumo_design/ui/avatar_fox.webp'
                    : 'assets/lumo_design/board_games/pawn_child.png',
                width: 30,
                height: 30,
                excludeFromSemantics: true),
            const SizedBox(width: 6),
            Flexible(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFFBED2E8)))),
          ]),
          const SizedBox(height: 4),
          Text('$pos / $_goal',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : const Color(0xFFBED2E8))),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pos / _goal,
              minHeight: 4,
              color: color,
              backgroundColor: const Color(0xFF294665),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTrack() {
    // Spielfeld: 6 Reihen a 5 Felder, Schlangenfoermig.
    // FIX (Heinz Screenshot 2026-05-21): vorher 'BOTTOM OVERFLOWED BY
    // 426 PIXEL' weil cellSize nur aus maxWidth berechnet wurde. Jetzt
    // beide Constraints (width + height) ausreizen mit min().
    const cols = 5;
    const rowsTotal = 6;
    const colSpacing = 6.0;
    const rowSpacing = 6.0;
    return LayoutBuilder(builder: (_, c) {
      final availW = c.maxWidth - 28;
      final availH = c.maxHeight - 20;
      final wBased = (availW - (cols - 1) * colSpacing) / cols;
      final hBased = (availH - (rowsTotal - 1) * rowSpacing) / rowsTotal;
      final cellSize = math.min(wBased, hBased).clamp(12.0, 96.0);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rowsTotal, (r) {
            // Schlangenform: gerade Reihen links->rechts, ungerade rechts->links
            final cells = <Widget>[];
            for (var col = 0; col < cols; col++) {
              final actualCol = r % 2 == 0 ? col : (cols - 1 - col);
              final realPos = r * cols + actualCol + 1;
              cells.add(SizedBox(
                width: cellSize,
                height: cellSize,
                child: _buildTrackCell(realPos),
              ));
              if (col < cols - 1) {
                cells.add(const SizedBox(width: colSpacing));
              }
            }
            return Padding(
              padding:
                  EdgeInsets.only(bottom: r == rowsTotal - 1 ? 0 : rowSpacing),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: cells),
            );
          }),
        ),
      );
    });
  }

  Widget _buildTrackCell(int pos) {
    final isKindHere = _kindPos == pos;
    final isLumoHere = _lumoPos == pos;
    final isGoal = pos == _goal;
    final isStart = pos == 1;
    return Semantics(
      label:
          'Feld $pos${isKindHere ? ", deine Figur" : ""}${isLumoHere ? ", Lumo" : ""}',
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
            child: ExcludeSemantics(
                child: Image.asset('assets/lumo_design/board_games/tile.png',
                    fit: BoxFit.fill))),
        Positioned(
            top: 6,
            left: 8,
            child: Text('$pos',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF132F45)))),
        if (isGoal && !isKindHere && !isLumoHere)
          FractionallySizedBox(
              widthFactor: .6,
              heightFactor: .6,
              child: Image.asset('assets/lumo_design/ui/trophy.webp'))
        else if (isStart && !isKindHere && !isLumoHere)
          FractionallySizedBox(
              widthFactor: .5,
              heightFactor: .5,
              child:
                  Image.asset('assets/lumo_design/icons/flag_checkered.webp')),
        if (isKindHere || isLumoHere)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isKindHere)
              Flexible(
                  child: Image.asset(
                      'assets/lumo_design/board_games/pawn_child.png')),
            if (isLumoHere)
              Flexible(
                  child: Stack(alignment: Alignment.center, children: [
                Image.asset('assets/lumo_design/board_games/pawn_lumo.png'),
                FractionallySizedBox(
                    widthFactor: .43,
                    heightFactor: .43,
                    child:
                        Image.asset('assets/lumo_design/ui/avatar_fox.webp')),
              ])),
          ]),
      ]),
    );
  }

  Widget _buildDicePanel() {
    final canRoll = !_busy && _turn == _Player.kind && _kindPos < _goal;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Wuerfel-Anzeige
          AnimatedBuilder(
            animation: _diceCtrl,
            builder: (_, __) {
              final shake = math.sin(_diceCtrl.value * math.pi * 6) * 6;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: SizedBox(
                    width: 86,
                    height: 86,
                    child: _lastRoll == null
                        ? Image.asset(
                            'assets/lumo_design/board_games/die_1.png',
                            semanticLabel: 'Würfel bereit')
                        : Image.asset(
                            'assets/lumo_design/board_games/die_$_lastRoll.png',
                            semanticLabel: 'Gewürfelt: $_lastRoll')),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton.icon(
              key: const ValueKey('dice-roll'),
              onPressed: canRoll ? _rollDice : null,
              icon: const Icon(Icons.casino_rounded),
              label: Text(canRoll
                  ? 'Würfeln!'
                  : (_busy
                      ? (_turn == _Player.lumo ? 'Lumo würfelt…' : 'Moment...')
                      : 'Warten')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF235D78),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF173654),
                disabledForegroundColor: const Color(0xFFBED2E8),
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
