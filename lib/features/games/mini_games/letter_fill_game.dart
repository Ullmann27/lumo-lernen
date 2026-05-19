// ════════════════════════════════════════════════════════════════════════
// LETTER FILL GAME — Buchstaben-Luecken-Raetsel (Volksschule Klasse 1-2)
// ════════════════════════════════════════════════════════════════════════
// Heinz: 'Visuelle Deutsch-Aufgaben wie Buchstaben eintragen, Silben,
// oder Wörter vollenden.'
//
// Lehrplan-Bezug:
//   Klasse 1: Anlaut, einfache Woerter (M_US -> MAUS)
//   Klasse 2: Mehrere Luecken, schwierigere Woerter
//
// Spielablauf:
//   1. Wort mit einer Luecke wird gezeigt: "M_US" + Bild-Hinweis
//   2. 4 Buchstaben-Choices unten
//   3. Kind tippt den richtigen Buchstaben
//   4. Visuelles Feedback + naechste Aufgabe
//   5. 6 Woerter pro Runde
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../app/app_theme.dart';
import '../../../domain/games/game_level_model.dart';

class LetterFillGame extends StatefulWidget {
  const LetterFillGame({
    super.key,
    required this.appState,
    required this.level,
  });

  final LumoAppState appState;
  final GameLevel level;

  @override
  State<LetterFillGame> createState() => _LetterFillGameState();
}

class _LetterFillGameState extends State<LetterFillGame> {
  // ── Wortliste mit Luecke + Hinweis-Emoji ──
  // Format: (Wort, Index der Luecke, Hinweis-Emoji)
  // Sortiert nach Schwierigkeit: einfach (3-4 Buchstaben) zu komplexer.
  static const List<_FillTask> _bank = [
    // Klasse 1 - 3-4 Buchstaben, Anlaut
    _FillTask('MAUS', 0, '🐭'),
    _FillTask('HUND', 0, '🐕'),
    _FillTask('FISCH', 0, '🐟'),
    _FillTask('SONNE', 0, '☀️'),
    _FillTask('AUTO', 0, '🚗'),
    _FillTask('BAUM', 0, '🌳'),
    _FillTask('APFEL', 0, '🍎'),
    _FillTask('BUCH', 0, '📖'),
    // Mitte des Wortes
    _FillTask('HAUS', 1, '🏠'),
    _FillTask('KATZE', 2, '🐱'),
    _FillTask('BLUME', 2, '🌸'),
    _FillTask('VOGEL', 1, '🐦'),
    _FillTask('TISCH', 2, '🪑'),
    // Klasse 2 - komplexer
    _FillTask('SCHULE', 3, '🏫'),
    _FillTask('FREUND', 2, '🧒'),
    _FillTask('SPIELE', 4, '🎮'),
    _FillTask('REGEN', 1, '🌧️'),
    _FillTask('STERN', 2, '⭐'),
    _FillTask('MILCH', 2, '🥛'),
    _FillTask('PFERD', 2, '🐎'),
  ];

  static const int _tasksPerRound = 6;

  final math.Random _rng = math.Random();
  late List<_FillTask> _roundTasks;
  int _taskIndex = 0;
  int _correct = 0;
  String? _selectedLetter;
  bool _showFeedback = false;
  bool _wasCorrect = false;

  @override
  void initState() {
    super.initState();
    _roundTasks = List<_FillTask>.from(_bank)..shuffle(_rng);
    _roundTasks = _roundTasks.take(_tasksPerRound).toList();
  }

  _FillTask get _current => _roundTasks[_taskIndex];

  /// Generiert 4 Buchstaben-Choices: 1x richtig + 3x falsch.
  List<String> _choices() {
    final correct = _current.word[_current.gapIndex];
    const all = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final wrong = <String>{};
    while (wrong.length < 3) {
      final c = all[_rng.nextInt(all.length)];
      if (c != correct) wrong.add(c);
    }
    final list = [correct, ...wrong]..shuffle(_rng);
    return list;
  }

  late List<String> _currentChoices = _choices();

  void _pickLetter(String letter) {
    if (_showFeedback) return;
    HapticFeedback.lightImpact();
    final correct = _current.word[_current.gapIndex];
    setState(() {
      _selectedLetter = letter;
      _showFeedback = true;
      _wasCorrect = letter == correct;
      if (_wasCorrect) _correct++;
    });
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 1400), _nextTask);
  }

  void _nextTask() {
    if (!mounted) return;
    if (_taskIndex + 1 >= _roundTasks.length) {
      _finishRound();
      return;
    }
    setState(() {
      _taskIndex++;
      _selectedLetter = null;
      _showFeedback = false;
      _currentChoices = _choices();
    });
  }

  void _finishRound() {
    final stars = (_correct * 5 / _tasksPerRound).round().clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correct * 8);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFEF3C7),
        title: const Text('Geschafft! 🦊',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Du hast $_correct von ${_roundTasks.length} richtig.',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15)),
          const SizedBox(height: 12),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      color: i < stars
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFD1D5DB),
                      size: 36))),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Zurueck',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE),
      appBar: AppBar(
        backgroundColor: LumoColors.purple,
        foregroundColor: Colors.white,
        title: Text(widget.level.title,
            style:
                const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Fortschritt
            Row(children: [
              Text('Wort ${_taskIndex + 1} / ${_roundTasks.length}',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4C1D95))),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Color(0xFFFCD34D), size: 24),
              Text(' $_correct',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4C1D95))),
            ]),
            const SizedBox(height: 28),
            // Hinweis-Emoji
            Text(_current.hint,
                style: const TextStyle(fontSize: 100, height: 1)),
            const SizedBox(height: 20),
            // Wort mit Luecke
            _buildWord(),
            const Spacer(),
            // 4 Buchstaben-Choices
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, i) {
                final letter = _currentChoices[i];
                final correct = _current.word[_current.gapIndex];
                final isSelected = _selectedLetter == letter;
                Color bg = Colors.white;
                Color border = const Color(0xFF6D28D9);
                if (_showFeedback && isSelected) {
                  bg = _wasCorrect
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2);
                  border = _wasCorrect
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626);
                }
                if (_showFeedback && letter == correct && !isSelected) {
                  bg = const Color(0xFFD1FAE5);
                  border = const Color(0xFF059669);
                }
                return GestureDetector(
                  onTap: () => _pickLetter(letter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 2.6),
                      boxShadow: [
                        BoxShadow(
                            color: border.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Center(
                      child: Text(letter,
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: border)),
                    ),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildWord() {
    final word = _current.word;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(word.length, (i) {
        final isGap = i == _current.gapIndex;
        final displayChar = isGap
            ? (_showFeedback ? word[i] : '_')
            : word[i];
        Color color = const Color(0xFF4C1D95);
        if (isGap && _showFeedback) {
          color = _wasCorrect
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626);
        } else if (isGap) {
          color = LumoColors.purple;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 48,
          height: 64,
          decoration: BoxDecoration(
            color: isGap
                ? const Color(0xFFFFFFFF).withOpacity(0.8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isGap
                ? Border.all(color: LumoColors.purple, width: 2.4)
                : null,
          ),
          child: Center(
            child: Text(displayChar,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ),
        );
      }),
    );
  }
}

class _FillTask {
  const _FillTask(this.word, this.gapIndex, this.hint);
  final String word;
  final int gapIndex;
  final String hint;
}
