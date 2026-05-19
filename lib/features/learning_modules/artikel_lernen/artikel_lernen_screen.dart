// ════════════════════════════════════════════════════════════════════════
// DER / DIE / DAS — Klasse 2 Deutsch (interaktiv)
// ════════════════════════════════════════════════════════════════════════
// Wort wird gezeigt - Kind tippt richtigen Artikel (der/die/das).
// 12 Aufgaben pro Session aus einem festen Wortschatz.
// Mit Emoji-Visualisierung fuer jedes Nomen.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class ArtikelLernenScreen extends StatefulWidget {
  const ArtikelLernenScreen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ArtikelLernenScreen> createState() => _ArtikelLernenScreenState();
}

class _ArtikelLernenScreenState extends State<ArtikelLernenScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 12;
  static const List<Color> _gradient = [
    Color(0xFFA855F7),
    Color(0xFF7C3AED),
  ];

  // Wortschatz: (Artikel, Wort, Emoji)
  static const List<List<String>> _vocabulary = [
    // DER (maskulin)
    ['der', 'Hund', '🐕'], ['der', 'Apfel', '🍎'], ['der', 'Ball', '⚽'],
    ['der', 'Baum', '🌳'], ['der', 'Tisch', '🪑'], ['der', 'Vogel', '🐦'],
    ['der', 'Schuh', '👟'], ['der', 'Bus', '🚌'], ['der', 'Mond', '🌙'],
    // DIE (feminin)
    ['die', 'Katze', '🐈'], ['die', 'Blume', '🌸'], ['die', 'Sonne', '☀️'],
    ['die', 'Banane', '🍌'], ['die', 'Maus', '🐁'], ['die', 'Tasche', '👜'],
    ['die', 'Uhr', '🕐'], ['die', 'Lampe', '💡'], ['die', 'Tür', '🚪'],
    // DAS (neutral)
    ['das', 'Auto', '🚗'], ['das', 'Haus', '🏠'], ['das', 'Kind', '🧒'],
    ['das', 'Buch', '📖'], ['das', 'Brot', '🍞'], ['das', 'Pferd', '🐴'],
    ['das', 'Wasser', '💧'], ['das', 'Bett', '🛏️'], ['das', 'Fahrrad', '🚲'],
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  String? _selectedAnswer;

  late List<String> _current; // [artikel, wort, emoji]
  late List<List<String>> _shuffledVocab;

  String get _correctArticle => _current[0];
  String get _word => _current[1];
  String get _emoji => _current[2];

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _shuffledVocab = List.of(_vocabulary)..shuffle(_rng);
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTask());
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    _current = _shuffledVocab[_taskIdx % _shuffledVocab.length];
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('Welcher Artikel passt zu $_word?');
    } catch (_) {}
  }

  void _onAnswer(String answer) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final isCorrect = answer == _correctArticle;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(6);
      try {
        LumoVoice.instance
            .speak('${LumoPhrases.correct()} $_correctArticle $_word.');
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      _nextTask();
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance
            .speak('Schau: $_correctArticle $_word.');
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 2400));
      if (!mounted) return;
      _nextTask();
    }
  }

  void _nextTask() {
    if (_taskIdx + 1 >= _totalTasks) {
      _showFinish();
      return;
    }
    setState(() {
      _taskIdx++;
      _generateTask();
    });
    _entryCtrl.forward(from: 0);
    _speakTask();
  }

  void _showFinish() {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    widget.appState.addStars(stars);
    widget.appState.addXp(_correctCount * 8);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Geschafft!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Artikel richtig!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
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
          const SizedBox(height: 12),
          Text(LumoPhrases.celebrate(),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Fertig',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    color: _gradient[0])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, child) {
                  return Opacity(opacity: _entryCtrl.value, child: child);
                },
                child: Column(children: [
                  _buildWordCard(),
                  const SizedBox(height: 28),
                  const Text('Welcher Artikel?',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C3AED))),
                  const SizedBox(height: 16),
                  _buildAnswerColumn(),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: _gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(
            children: [
              Text('Wort ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Der / Die / Das',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFFCD34D), size: 18),
            const SizedBox(width: 4),
            Text('$_correctCount',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _buildWordCard() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 6) * 5;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: _gradient[0].withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(children: [
          Text(_emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          Text(_word,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _gradient[1])),
        ]),
      ),
    );
  }

  Widget _buildAnswerColumn() {
    return Column(children: [
      for (final article in ['der', 'die', 'das']) ...[
        _buildAnswerButton(article),
        const SizedBox(height: 10),
      ],
    ]);
  }

  Widget _buildAnswerButton(String article) {
    final isSelected = _selectedAnswer == article;
    final isCorrect = article == _correctArticle;
    Color bgColor = Colors.white;
    Color textColor = _gradient[1];
    Color borderColor = _gradient[0].withOpacity(0.3);
    if (_answered) {
      if (isSelected && isCorrect) {
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981);
      } else if (isSelected && !isCorrect) {
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        borderColor = const Color(0xFFEF4444);
      } else if (!isSelected && isCorrect) {
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFCD34D);
      }
    }
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final s = isSelected && isCorrect
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.08
            : 1.0;
        return Transform.scale(scale: s, child: child);
      },
      child: GestureDetector(
        onTap: _answered ? null : () => _onAnswer(article),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(
                  color: borderColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Center(
            child: Text(article,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}
