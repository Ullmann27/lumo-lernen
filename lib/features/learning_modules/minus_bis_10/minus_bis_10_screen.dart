// ════════════════════════════════════════════════════════════════════════
// MINUS BIS 10 — Klasse 1 Mathematik (interaktiv, kein Chat)
// ════════════════════════════════════════════════════════════════════════
// Visualisierung: Bonbons werden weggenommen. Kind tippt richtige Anzahl.
// 4 Multiple-Choice Antworten pro Aufgabe, 10 Aufgaben pro Session.
// Bei richtig: Lumo lobt + Sterne. Bei falsch: sanft + Hilfe-Bild.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

class MinusBis10Screen extends StatefulWidget {
  const MinusBis10Screen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<MinusBis10Screen> createState() => _MinusBis10ScreenState();
}

class _MinusBis10ScreenState extends State<MinusBis10Screen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 30;
  static const List<Color> _gradient = [
    Color(0xFFEC4899),
    Color(0xFFBE185D),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  int _wrongAttempts = 0;
  bool _showHint = false;
  bool _answered = false;
  int? _selectedAnswer;

  late int _a;
  late int _b;
  late List<int> _answers;

  int get _correct => _a - _b;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _generateTask();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakTask();
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    // _a in 3..10, _b in 1.._a-1 -> Ergebnis 1..9 (nie 0 oder negativ)
    _a = 3 + _rng.nextInt(8);
    _b = 1 + _rng.nextInt(_a - 1);
    final correct = _correct;
    final wrongOptions = <int>{};
    while (wrongOptions.length < 3) {
      final delta = _rng.nextInt(5) - 2; // -2..+2
      final cand = correct + delta;
      if (cand >= 0 && cand <= 10 && cand != correct) {
        wrongOptions.add(cand);
      }
    }
    _answers = [correct, ...wrongOptions]..shuffle(_rng);
    _answered = false;
    _selectedAnswer = null;
    _showHint = false;
    _wrongAttempts = 0;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('$_a minus $_b. Wie viele bleiben?');
    } catch (_) {}
  }

  void _onAnswer(int answer) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final isCorrect = answer == _correct;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(5);
      final phrase = LumoPhrases.correct();
      try {
        LumoVoice.instance.speak(phrase);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      _nextTask();
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      _wrongAttempts++;
      final phrase = LumoPhrases.wrongGentle();
      try {
        LumoVoice.instance.speak(phrase);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      if (_wrongAttempts >= 2) {
        setState(() => _showHint = true);
        await Future.delayed(const Duration(milliseconds: 2400));
        if (!mounted) return;
        _nextTask();
      } else {
        setState(() {
          _answered = false;
          _selectedAnswer = null;
        });
      }
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
    widget.appState.addXp(_correctCount * 10);
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
          Text('$_correctCount / $_totalTasks richtig!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
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
                  _buildTaskHeader(),
                  const SizedBox(height: 24),
                  _buildBonbonsVisualization(),
                  const SizedBox(height: 32),
                  _buildAnswerGrid(),
                  if (_showHint) ...[
                    const SizedBox(height: 20),
                    _buildHintCard(),
                  ],
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
              Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const Text('Minus bis 10',
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

  Widget _buildTaskHeader() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: _gradient[0].withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Text('$_a − $_b = ?',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: _gradient[1])),
      ),
    );
  }

  // Visualisierung: a Bonbons, davon b durchgestrichen
  Widget _buildBonbonsVisualization() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(_a, (i) {
        final isRemoved = i < _b;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + i * 40),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isRemoved
                ? Colors.grey.shade300
                : const Color(0xFFFCE7F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isRemoved
                    ? Colors.grey.shade400
                    : _gradient[0].withOpacity(0.5),
                width: 2),
          ),
          child: Center(
            child: isRemoved
                ? const Icon(Icons.close_rounded,
                    color: Colors.red, size: 24)
                : const Text('🍬', style: TextStyle(fontSize: 22)),
          ),
        );
      }),
    );
  }

  Widget _buildAnswerGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: _answers.map((a) => _buildAnswerButton(a)).toList(),
    );
  }

  Widget _buildAnswerButton(int value) {
    final isSelected = _selectedAnswer == value;
    final isCorrect = value == _correct;
    Color bgColor = Colors.white;
    Color textColor = _gradient[1];
    Color borderColor = _gradient[0].withOpacity(0.3);
    if (_answered && isSelected) {
      if (isCorrect) {
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981);
      } else {
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        borderColor = const Color(0xFFEF4444);
      }
    } else if (_answered && isCorrect && _wrongAttempts >= 1) {
      bgColor = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFFCD34D);
    }
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final bounceScale = isSelected && isCorrect
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.1
            : 1.0;
        return Transform.scale(scale: bounceScale, child: child);
      },
      child: GestureDetector(
        onTap: _answered ? null : () => _onAnswer(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
            child: Text('$value',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 2),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 8),
          Text('Schau hin:',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD97706))),
        ]),
        const SizedBox(height: 8),
        Text('Du hattest $_a Bonbons. Du isst $_b davon. '
            'Dann sind ${_correct} übrig.',
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E))),
      ]),
    );
  }
}
