// ════════════════════════════════════════════════════════════════════════
// LUMO VIER GEWINNT — klassisches Brettspiel, Lumo als KI-Gegner
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: kindbekannte Brettspiele mit Lumo als aktivem Gegner.
//
// Spielregeln:
//   - 7 Spalten x 6 Reihen
//   - Kind und Lumo wechseln sich ab, jeder wirft eine Spielsteine in
//     eine Spalte
//   - Stein fallt nach unten, bis er auf einen anderen Stein oder den
//     Boden trifft
//   - Wer zuerst 4 Steine in Reihe hat (waagrecht, senkrecht, diagonal)
//     gewinnt
//   - Volles Brett ohne Sieger -> Unentschieden
//
// Lumo-KI:
//   - Schwierigkeit "leicht" (Klasse-1-freundlich): 70% sieht Lumo nur
//     einen Zug voraus, 30% spielt zufaellig
//   - Score-Funktion zaehlt 2er und 3er Reihen + blockiert offensichtliche
//     Bedrohungen
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../core/lumo_voice.dart';

enum _Cell { empty, kind, lumo }

const int _cols = 7;
const int _rows = 6;
const int _winLength = 4;

class LumoConnectFourScreen extends StatefulWidget {
  const LumoConnectFourScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LumoConnectFourScreen> createState() => _LumoConnectFourScreenState();
}

class _LumoConnectFourScreenState extends State<LumoConnectFourScreen> {
  late List<List<_Cell>> _board;
  _Cell _turn = _Cell.kind;
  bool _busy = false;
  List<List<int>>? _winLine; // Liste von [row, col] der Gewinnsteine
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _resetBoard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say('Vier gewinnt! Du bist Gelb, ich bin Rot. Du faengst an.');
    });
  }

  void _say(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _resetBoard() {
    _board = List.generate(
      _rows,
      (_) => List<_Cell>.filled(_cols, _Cell.empty),
    );
    _turn = _Cell.kind;
    _busy = false;
    _winLine = null;
  }

  void _tapColumn(int col) {
    if (_busy || _turn != _Cell.kind || _winLine != null) return;
    if (!_dropPiece(col, _Cell.kind)) return;
    HapticFeedback.lightImpact();
    setState(() {});
    final won = _checkWinner(_Cell.kind);
    if (won != null) {
      _onWin(_Cell.kind, won);
      return;
    }
    if (_isBoardFull()) {
      _onDraw();
      return;
    }
    _turn = _Cell.lumo;
    _busy = true;
    setState(() {});
    Timer(const Duration(milliseconds: 900), _lumoMove);
  }

  /// Wirft einen Stein in die Spalte. Gibt false zurueck, wenn die
  /// Spalte voll ist.
  bool _dropPiece(int col, _Cell who) {
    for (var row = _rows - 1; row >= 0; row--) {
      if (_board[row][col] == _Cell.empty) {
        _board[row][col] = who;
        return true;
      }
    }
    return false;
  }

  /// Macht den Zug rueckgaengig (fuer KI-Suche).
  void _undoTopOf(int col) {
    for (var row = 0; row < _rows; row++) {
      if (_board[row][col] != _Cell.empty) {
        _board[row][col] = _Cell.empty;
        return;
      }
    }
  }

  bool _isBoardFull() {
    for (var c = 0; c < _cols; c++) {
      if (_board[0][c] == _Cell.empty) return false;
    }
    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // LUMO-KI
  // ──────────────────────────────────────────────────────────────────

  void _lumoMove() {
    if (!mounted) return;
    final col = _pickBestColumnForLumo();
    if (col == null) {
      _onDraw();
      return;
    }
    _dropPiece(col, _Cell.lumo);
    HapticFeedback.lightImpact();
    setState(() {});
    final won = _checkWinner(_Cell.lumo);
    if (won != null) {
      _onWin(_Cell.lumo, won);
      return;
    }
    if (_isBoardFull()) {
      _onDraw();
      return;
    }
    _turn = _Cell.kind;
    _busy = false;
    setState(() {});
    _say('Du bist dran!');
  }

  /// Klasse-1-freundliche KI: 70% strategisch (blocken / gewinnen),
  /// 30% zufaellig. So gewinnt das Kind oft genug, hat aber Lerneffekt.
  int? _pickBestColumnForLumo() {
    final validCols = <int>[
      for (var c = 0; c < _cols; c++)
        if (_board[0][c] == _Cell.empty) c
    ];
    if (validCols.isEmpty) return null;

    // 1. Kann Lumo SOFORT gewinnen?
    for (final c in validCols) {
      if (_dropPiece(c, _Cell.lumo)) {
        final win = _checkWinner(_Cell.lumo);
        _undoTopOf(c);
        if (win != null) return c;
      }
    }
    // 2. Muss Lumo das Kind BLOCKEN, sonst gewinnt es?
    for (final c in validCols) {
      if (_dropPiece(c, _Cell.kind)) {
        final win = _checkWinner(_Cell.kind);
        _undoTopOf(c);
        if (win != null) return c;
      }
    }
    // 3. 30% zufaellig (Klasse-1-Fairness)
    if (_rng.nextDouble() < 0.30) {
      return validCols[_rng.nextInt(validCols.length)];
    }
    // 4. Score-basierte Wahl (Mitte ist besser als Rand)
    final scores = <int, int>{};
    for (final c in validCols) {
      // Bonus fuer Mitte (Spalte 3 ist optimal in 7-col Brett)
      final centerBonus = -((c - 3).abs() * 2);
      // Pluspunkte fuer "macht 3er Reihe"
      if (_dropPiece(c, _Cell.lumo)) {
        var ownPotential = _countPotentialLines(_Cell.lumo);
        _undoTopOf(c);
        scores[c] = centerBonus + ownPotential;
      } else {
        scores[c] = centerBonus;
      }
    }
    final sortedCols = validCols.toList()
      ..sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
    return sortedCols.first;
  }

  /// Zaehlt unbesetzte 4er-Linien fuer die Farbe (Heuristik).
  int _countPotentialLines(_Cell who) {
    final other = who == _Cell.lumo ? _Cell.kind : _Cell.lumo;
    var count = 0;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        for (final dir in const [
          [0, 1],
          [1, 0],
          [1, 1],
          [1, -1]
        ]) {
          final dr = dir[0];
          final dc = dir[1];
          final endR = r + dr * (_winLength - 1);
          final endC = c + dc * (_winLength - 1);
          if (endR < 0 || endR >= _rows || endC < 0 || endC >= _cols) continue;
          var mine = 0;
          var opp = 0;
          for (var k = 0; k < _winLength; k++) {
            final cell = _board[r + dr * k][c + dc * k];
            if (cell == who) mine++;
            if (cell == other) opp++;
          }
          if (opp == 0) count += mine * mine; // 3er > 2er
        }
      }
    }
    return count;
  }

  // ──────────────────────────────────────────────────────────────────
  // GEWINN-PRUEFUNG
  // ──────────────────────────────────────────────────────────────────

  /// Gibt die Linie zurueck wenn `who` gewonnen hat, sonst null.
  List<List<int>>? _checkWinner(_Cell who) {
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        for (final dir in const [
          [0, 1],
          [1, 0],
          [1, 1],
          [1, -1]
        ]) {
          final dr = dir[0];
          final dc = dir[1];
          final endR = r + dr * (_winLength - 1);
          final endC = c + dc * (_winLength - 1);
          if (endR < 0 || endR >= _rows || endC < 0 || endC >= _cols) continue;
          var ok = true;
          for (var k = 0; k < _winLength; k++) {
            if (_board[r + dr * k][c + dc * k] != who) {
              ok = false;
              break;
            }
          }
          if (ok) {
            return [
              for (var k = 0; k < _winLength; k++)
                [r + dr * k, c + dc * k]
            ];
          }
        }
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────
  // SPIEL-ENDE
  // ──────────────────────────────────────────────────────────────────

  void _onWin(_Cell who, List<List<int>> line) {
    setState(() {
      _winLine = line;
      _busy = true;
    });
    HapticFeedback.heavyImpact();
    final kindWon = who == _Cell.kind;
    final stars = kindWon ? 5 : 2;
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 8);
    _say(kindWon
        ? 'Du hast vier in Reihe! $stars Sterne fuer dich!'
        : 'Ich habe vier in Reihe! Nochmal probieren?');
    _showFinishDialog(
        kindWon: kindWon, drawn: false, stars: stars, lumoWon: !kindWon);
  }

  void _onDraw() {
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    widget.appState.addStars(3);
    widget.appState.addXp(20);
    _say('Unentschieden! Beide waren gleich gut. 3 Sterne!');
    _showFinishDialog(
        kindWon: false, drawn: true, stars: 3, lumoWon: false);
  }

  void _showFinishDialog({
    required bool kindWon,
    required bool drawn,
    required int stars,
    required bool lumoWon,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          kindWon
              ? '🎉 Du gewinnst!'
              : drawn
                  ? '🤝 Unentschieden'
                  : '🦊 Lumo gewinnt',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 22),
        ),
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
              setState(_resetBoard);
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
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTurnIndicator(),
            Expanded(child: Center(child: _buildBoard())),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Center(
            child: Text('Vier gewinnt mit Lumo 🦊',
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
          onPressed: () => setState(_resetBoard),
        ),
      ]),
    );
  }

  Widget _buildTurnIndicator() {
    final isKind = _turn == _Cell.kind;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isKind ? const Color(0xFFFCD34D) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFFEAB308), width: 2.4),
              ),
              child: const Center(
                child: Text('Du 🟡',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: !isKind ? const Color(0xFFF87171) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: const Color(0xFFEF4444), width: 2.4),
              ),
              child: Center(
                child: Text(_busy && !isKind ? 'Lumo denkt... 🦊' : 'Lumo 🔴',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: !isKind ? Colors.white : const Color(0xFF7F1D1D))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: _cols / (_rows + 0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: LayoutBuilder(builder: (_, constraints) {
          final cellSize = constraints.maxWidth / _cols;
          return Column(
            children: [
              // Spalten-Tap-Buttons
              Row(
                children: List.generate(_cols, (c) {
                  final disabled = _busy ||
                      _turn != _Cell.kind ||
                      _winLine != null ||
                      _board[0][c] != _Cell.empty;
                  return SizedBox(
                    width: cellSize,
                    height: cellSize * 0.55,
                    child: IconButton(
                      onPressed: disabled ? null : () => _tapColumn(c),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: disabled
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFFFCD34D),
                        size: cellSize * 0.7,
                      ),
                    ),
                  );
                }),
              ),
              // Brett
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: List.generate(_rows, (r) {
                      return Expanded(
                        child: Row(
                          children: List.generate(_cols, (c) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: _buildCell(r, c),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final cell = _board[r][c];
    final isWin = _winLine != null &&
        _winLine!.any((p) => p[0] == r && p[1] == c);
    final Color color;
    switch (cell) {
      case _Cell.empty:
        color = const Color(0xFF1E40AF);
        break;
      case _Cell.kind:
        color = const Color(0xFFFCD34D);
        break;
      case _Cell.lumo:
        color = const Color(0xFFF87171);
        break;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isWin
            ? Border.all(color: const Color(0xFF22C55E), width: 3)
            : null,
        boxShadow: cell != _Cell.empty
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
    );
  }
}
