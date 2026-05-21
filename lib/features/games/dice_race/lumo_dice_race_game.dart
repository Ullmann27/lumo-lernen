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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/lumo_voice.dart';

class LumoDiceRaceScreen extends StatefulWidget {
  const LumoDiceRaceScreen({super.key, required this.appState});
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
  final math.Random _rng = math.Random();
  late AnimationController _diceCtrl;

  @override
  void initState() {
    super.initState();
    _diceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say('Wuerfel-Wettlauf! Wer zuerst beim Stern ist, gewinnt. Du faengst an!');
    });
  }

  @override
  void dispose() {
    _diceCtrl.dispose();
    super.dispose();
  }

  void _say(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _resetGame() {
    setState(() {
      _kindPos = 0;
      _lumoPos = 0;
      _lastRoll = null;
      _turn = _Player.kind;
      _busy = false;
      _hint = null;
    });
  }

  Future<void> _rollDice() async {
    if (_busy) return;
    if (_kindPos >= _goal || _lumoPos >= _goal) return;
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _hint = null;
    });
    // Wuerfel-Animation: rasende Zufallszahlen
    await _diceCtrl.forward(from: 0);
    final roll = 1 + _rng.nextInt(6);
    setState(() => _lastRoll = roll);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _applyRoll(roll);
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
        extra = 'Du hast Lumo geschickt zurueck zum Start! 🦊';
      }
      _hint = extra ?? 'Du wuerfelst $roll und gehst $roll Felder vor.';
      setState(() {});
      if (_kindPos >= _goal) {
        _onWin(_Player.kind);
        return;
      }
      // Lumo dran
      _turn = _Player.lumo;
      Timer(const Duration(milliseconds: 700), _lumoRoll);
    } else {
      var next = _lumoPos + roll;
      if (next > _goal) next = _goal;
      _lumoPos = next;
      String? extra;
      if (_lumoPos == _kindPos && _lumoPos != _goal && _kindPos != 0) {
        _kindPos = 0;
        extra = 'Oh nein - Lumo schlaegt dich zurueck zum Start!';
      }
      _hint = extra ?? 'Lumo wuerfelt $roll.';
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

  Future<void> _lumoRoll() async {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _hint = 'Lumo wuerfelt 🦊...');
    await _diceCtrl.forward(from: 0);
    final roll = 1 + _rng.nextInt(6);
    setState(() => _lastRoll = roll);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _applyRoll(roll);
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
      builder: (_) => AlertDialog(
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatusBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildTrack()),
            _buildDicePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Center(
            child: Text('Wuerfel-Wettlauf 🎲',
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
          onPressed: _resetGame,
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
              _statusPill('Du', _kindPos, const Color(0xFFFB923C),
                  isActive: _turn == _Player.kind),
              const SizedBox(width: 12),
              _statusPill('Lumo 🦊', _lumoPos, const Color(0xFF8B5CF6),
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
                    color: LumoColors.ink700)),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String label, int pos, Color color,
      {required bool isActive}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2.4),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : color)),
          const Spacer(),
          Text('$pos / $_goal',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : color)),
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
      final cellSize = math.min(wBased, hBased).clamp(36.0, 96.0);
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
              padding: EdgeInsets.only(
                  bottom: r == rowsTotal - 1 ? 0 : rowSpacing),
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
    // Bonus-Felder alle 5 Schritte: machen das Brett bunt und feiern
    // kleine Fortschritte.
    final isBonus = !isGoal && !isStart && pos % 5 == 0;
    // Sanfte Pastell-Toene fuer normale Felder im Wechsel.
    final stripeA = pos.isEven;
    final List<Color> baseColors = isGoal
        ? const [Color(0xFFFCD34D), Color(0xFFEAB308)]
        : isStart
            ? const [Color(0xFFA7F3D0), Color(0xFF34D399)]
            : isBonus
                ? const [Color(0xFFFCE7F3), Color(0xFFFBCFE8)]
                : stripeA
                    ? const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)]
                    : const [Color(0xFFF9FAFB), Color(0xFFE5E7EB)];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: baseColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGoal
                ? const Color(0xFFB45309)
                : isBonus
                    ? const Color(0xFFEC4899)
                    : const Color(0xFFD1D5DB),
            width: isGoal ? 2.4 : 1.4),
        boxShadow: isGoal || isBonus
            ? [
                BoxShadow(
                  color: (isGoal
                          ? const Color(0xFFEAB308)
                          : const Color(0xFFEC4899))
                      .withOpacity(.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Stack(alignment: Alignment.center, children: [
        // Position-Zahl klein oben links
        Positioned(
          top: 3,
          left: 5,
          child: Text('$pos',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isGoal
                      ? const Color(0xFFB45309)
                      : const Color(0xFF6B7280))),
        ),
        // Feld-Symbol (Stern / Bonus / Start)
        if (isGoal)
          const Text('🏆', style: TextStyle(fontSize: 22))
        else if (isBonus)
          const Text('⭐', style: TextStyle(fontSize: 16))
        else if (isStart)
          const Text('🚩', style: TextStyle(fontSize: 16)),
        // Spielfiguren ueberlagern alles
        if (isKindHere && isLumoHere)
          const Text('🦊🧒', style: TextStyle(fontSize: 16, height: 1.0))
        else if (isKindHere)
          const Text('🧒', style: TextStyle(fontSize: 22, height: 1.0))
        else if (isLumoHere)
          const Text('🦊', style: TextStyle(fontSize: 22, height: 1.0)),
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
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF1F2937), width: 2.4),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    _lastRoll == null
                        ? '?'
                        : ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'][_lastRoll! - 1],
                    style: const TextStyle(
                        fontSize: 42, color: Color(0xFF1F2937)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canRoll ? _rollDice : null,
              icon: const Icon(Icons.casino_rounded),
              label: Text(canRoll
                  ? 'Wuerfeln!'
                  : (_busy
                      ? (_turn == _Player.lumo ? 'Lumo... 🦊' : 'Moment...')
                      : 'Warten')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
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
