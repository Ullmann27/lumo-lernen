// ════════════════════════════════════════════════════════════════════════
// ZAHLEN BIS 10 — Klasse 1 Mathematik (visuelles Zaehlen)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen (gemischt):
//   - 'Wie viele Punkte siehst du?' (Zaehlen 1-10)
//   - 'Welche Zahl kommt nach X?'
//   - 'Welche Zahl ist groesser: X oder Y?'
// 12 Aufgaben pro Session, Multiple-Choice.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _ZahlAufgabenTyp { zaehlen, nachfolger, groesser }

class ZahlenBis10Screen extends StatefulWidget {
  const ZahlenBis10Screen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ZahlenBis10Screen> createState() => _ZahlenBis10ScreenState();
}

class _ZahlenBis10ScreenState extends State<ZahlenBis10Screen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 12;
  static const List<Color> _gradient = [
    Color(0xFF06B6D4),
    Color(0xFF0891B2),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedAnswer;

  late _ZahlAufgabenTyp _typ;
  late int _zahl1;
  late int _zahl2;
  late int _correctAnswer;
  late List<int> _answers;

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
    final r = _rng.nextInt(3);
    _typ = _ZahlAufgabenTyp.values[r];
    switch (_typ) {
      case _ZahlAufgabenTyp.zaehlen:
        _zahl1 = 1 + _rng.nextInt(10);
        _correctAnswer = _zahl1;
        break;
      case _ZahlAufgabenTyp.nachfolger:
        _zahl1 = _rng.nextInt(9); // 0..8
        _correctAnswer = _zahl1 + 1;
        break;
      case _ZahlAufgabenTyp.groesser:
        _zahl1 = 1 + _rng.nextInt(10);
        _zahl2 = 1 + _rng.nextInt(10);
        while (_zahl2 == _zahl1) {
          _zahl2 = 1 + _rng.nextInt(10);
        }
        _correctAnswer = math.max(_zahl1, _zahl2);
        break;
    }
    final wrong = <int>{};
    while (wrong.length < 3) {
      final cand = 1 + _rng.nextInt(10);
      if (cand != _correctAnswer) wrong.add(cand);
    }
    _answers = [_correctAnswer, ...wrong]..shuffle(_rng);
    _answered = false;
    _selectedAnswer = null;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    String text;
    switch (_typ) {
      case _ZahlAufgabenTyp.zaehlen:
        text = 'Wie viele Punkte siehst du?';
        break;
      case _ZahlAufgabenTyp.nachfolger:
        text = 'Welche Zahl kommt nach $_zahl1?';
        break;
      case _ZahlAufgabenTyp.groesser:
        text = 'Welche Zahl ist groesser: $_zahl1 oder $_zahl2?';
        break;
    }
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onAnswer(int answer) async {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final isCorrect = answer == _correctAnswer;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      _correctCount++;
      widget.appState.addStars(1);
      widget.appState.addXp(5);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _nextTask();
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
          Text('$_correctCount / $_totalTasks Aufgaben richtig!',
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
                  _buildTaskHeader(),
                  const SizedBox(height: 24),
                  _buildVisualization(),
                  const SizedBox(height: 32),
                  _buildAnswerGrid(),
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
              const Text('Zahlen bis 10',
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
    String text;
    switch (_typ) {
      case _ZahlAufgabenTyp.zaehlen:
        text = 'Wie viele Punkte siehst du?';
        break;
      case _ZahlAufgabenTyp.nachfolger:
        text = 'Welche Zahl kommt nach $_zahl1?';
        break;
      case _ZahlAufgabenTyp.groesser:
        text = 'Welche Zahl ist größer?';
        break;
    }
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(
            offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _gradient[1])),
      ),
    );
  }

  Widget _buildVisualization() {
    switch (_typ) {
      case _ZahlAufgabenTyp.zaehlen:
        return _buildDots(_zahl1);
      case _ZahlAufgabenTyp.nachfolger:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _gradient[0].withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('$_zahl1   →   ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: _gradient[1])),
        );
      case _ZahlAufgabenTyp.groesser:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBigNumber(_zahl1),
            const Text('oder',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280))),
            _buildBigNumber(_zahl2),
          ],
        );
    }
  }

  Widget _buildBigNumber(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
      ),
      child: Text('$n',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: _gradient[1])),
    );
  }

  Widget _buildDots(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gradient[0].withOpacity(0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          count,
          (i) => Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _gradient[0],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _gradient[0].withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
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
    final isCorrect = value == _correctAnswer;
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
    }
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final s = isSelected && isCorrect
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * 0.1
            : 1.0;
        return Transform.scale(scale: s, child: child);
      },
      child: GestureDetector(
        onTap: _answered ? null : () => _onAnswer(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 3),
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
}
