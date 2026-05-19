// ════════════════════════════════════════════════════════════════════════
// COLOR BOXES GAME — Mengen-Anmalen (Volksschule Klasse 1-2)
// ════════════════════════════════════════════════════════════════════════
// Heinz: 'Die Kästchen anmalen-Aufgabe. 10 Kästchen, 8 vorgegeben, Kind
// muss 2 noch anmalen, oder selbstständig die Kästchen vervollständigen.'
//
// Lehrplan-Bezug:
//   Klasse 1: Mengenerfassung 1-10, Kardinalzahl-Bedeutung
//   Klasse 2: Mengen bis 20, Zerlegung, Erganzung
//
// Spielablauf:
//   1. Aufgabe: "Male 7 Kaestchen an" (oder "Wie viele fehlen zu 10?")
//   2. 10 Kaestchen in einem Raster, X bereits angemalt
//   3. Kind tippt leere Kaestchen um sie anzumalen
//   4. Bei richtiger Anzahl: korrekt + Sterne
//   5. 5 Aufgaben pro Runde, danach Result-Dialog
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../domain/games/game_level_model.dart';

class ColorBoxesGame extends StatefulWidget {
  const ColorBoxesGame({
    super.key,
    required this.appState,
    required this.level,
  });

  final LumoAppState appState;
  final GameLevel level;

  @override
  State<ColorBoxesGame> createState() => _ColorBoxesGameState();
}

class _ColorBoxesGameState extends State<ColorBoxesGame> {
  static const int _tasksPerRound = 5;
  static const int _totalBoxes = 10;

  final math.Random _rng = math.Random();
  int _taskIndex = 0;
  int _correct = 0;
  late int _targetCount;
  late int _preFilledCount;
  late List<bool> _boxes;

  @override
  void initState() {
    super.initState();
    _newTask();
  }

  void _newTask() {
    // Aufgabe: zwischen 4 und 9 als Target. PreFilled: 1-3 weniger.
    _targetCount = 4 + _rng.nextInt(6); // 4..9
    _preFilledCount = math.max(0, _targetCount - (1 + _rng.nextInt(3)));
    _boxes = List<bool>.filled(_totalBoxes, false);
    // Pre-Fill an zufaelligen Positionen
    final positions = List<int>.generate(_totalBoxes, (i) => i)..shuffle(_rng);
    for (int i = 0; i < _preFilledCount; i++) {
      _boxes[positions[i]] = true;
    }
  }

  int get _filledCount => _boxes.where((b) => b).length;

  void _toggleBox(int idx) {
    HapticFeedback.lightImpact();
    setState(() {
      _boxes[idx] = !_boxes[idx];
    });
  }

  void _checkAnswer() {
    HapticFeedback.mediumImpact();
    if (_filledCount == _targetCount) {
      _correct++;
      _showFeedback(true);
    } else {
      _showFeedback(false);
    }
  }

  void _showFeedback(bool correct) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: correct ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
        title: Text(
          correct ? '🎉 Richtig!' : '🤔 Nicht ganz...',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900),
        ),
        content: Text(
          correct
              ? 'Du hast genau $_targetCount Kaestchen angemalt. Super!'
              : 'Du hast $_filledCount angemalt. Wir brauchen $_targetCount. Versuche es nochmal!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (correct) {
                _nextTask();
              }
            },
            child: Text(correct ? 'Weiter' : 'OK',
                style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _nextTask() {
    if (_taskIndex + 1 >= _tasksPerRound) {
      _finishRound();
      return;
    }
    setState(() {
      _taskIndex++;
      _newTask();
    });
  }

  void _finishRound() {
    // Belohnung: 1 Stern pro richtige Aufgabe (max 5)
    final stars = _correct;
    widget.appState.addStars(stars);
    widget.appState.addXp(stars * 5);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEF3C7),
        title: const Text('Runde fertig! 🦊',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Du hast $_correct von $_tasksPerRound Aufgaben richtig.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                _tasksPerRound,
                (i) => Icon(Icons.star_rounded,
                    color: i < _correct
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFD1D5DB),
                    size: 36)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Zurueck',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      appBar: AppBar(
        backgroundColor: LumoColors.orange,
        foregroundColor: Colors.white,
        title: Text(widget.level.title,
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Fortschritt
            Row(children: [
              Text('Aufgabe ${_taskIndex + 1} / $_tasksPerRound',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C2D12))),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Color(0xFFFCD34D), size: 24),
              Text(' $_correct',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7C2D12))),
            ]),
            const SizedBox(height: 24),
            // Aufgabe
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LumoColors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: LumoColors.orange.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                const Text('Male so viele Kaestchen an:',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C2D12))),
                const SizedBox(height: 8),
                Text('$_targetCount',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.orange)),
                const SizedBox(height: 4),
                Text('Du hast $_filledCount angemalt',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _filledCount == _targetCount
                            ? const Color(0xFF059669)
                            : const Color(0xFF92400E))),
              ]),
            ),
            const SizedBox(height: 28),
            // 10 Kaestchen in 2x5 Raster
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 360,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _totalBoxes,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, i) => _BoxTile(
                      filled: _boxes[i],
                      onTap: () => _toggleBox(i),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Check-Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumoColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Pruefen',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BoxTile extends StatelessWidget {
  const _BoxTile({required this.filled, required this.onTap});
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: filled ? const Color(0xFFEA580C) : const Color(0xFF92400E),
              width: 2.4),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: filled
            ? const Center(
                child: Icon(Icons.star_rounded, color: Colors.white, size: 32))
            : null,
      ),
    );
  }
}
