// ════════════════════════════════════════════════════════════════════════
// ZAHLEN BIS 100 — Klasse 2 Mathematik
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Zahl kommt nach X?' (Nachfolger 0..99)
//   - 'Welche Zahl ist groesser: X oder Y?' (Vergleich)
//   - 'Wie viele Zehner und Einer hat X?' (Stellenwert)
// 12 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';

enum _Zahl100FrageTyp { nachfolger, vorgaenger, vergleich, zehnerEiner }

class ZahlenBis100Screen extends StatefulWidget {
  const ZahlenBis100Screen({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<ZahlenBis100Screen> createState() => _ZahlenBis100ScreenState();
}

class _ZahlenBis100ScreenState extends State<ZahlenBis100Screen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 12;
  static const List<Color> _gradient = [
    Color(0xFF14B8A6),
    Color(0xFF0F766E),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _rng = math.Random();

  int _taskIdx = 0;
  int _correctCount = 0;
  bool _answered = false;
  int? _selectedAnswer;

  late _Zahl100FrageTyp _typ;
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
    _typ = _Zahl100FrageTyp.values[_rng.nextInt(_Zahl100FrageTyp.values.length)];
    switch (_typ) {
      case _Zahl100FrageTyp.nachfolger:
        _zahl1 = 10 + _rng.nextInt(89); // 10..98
        _correctAnswer = _zahl1 + 1;
        break;
      case _Zahl100FrageTyp.vorgaenger:
        _zahl1 = 11 + _rng.nextInt(89); // 11..99
        _correctAnswer = _zahl1 - 1;
        break;
      case _Zahl100FrageTyp.vergleich:
        _zahl1 = 10 + _rng.nextInt(89);
        _zahl2 = 10 + _rng.nextInt(89);
        while (_zahl2 == _zahl1) {
          _zahl2 = 10 + _rng.nextInt(89);
        }
        _correctAnswer = math.max(_zahl1, _zahl2);
        break;
      case _Zahl100FrageTyp.zehnerEiner:
        _zahl1 = 10 + _rng.nextInt(89); // 10..98
        // Antwort: Zehner-Stelle (z.B. 47 -> 4 Zehner)
        _correctAnswer = _zahl1 ~/ 10;
        break;
    }
    final wrong = <int>{};
    while (wrong.length < 3) {
      int cand;
      if (_typ == _Zahl100FrageTyp.zehnerEiner) {
        cand = 1 + _rng.nextInt(9);
      } else {
        final delta = (1 + _rng.nextInt(5)) * (_rng.nextBool() ? 1 : -1);
        cand = _correctAnswer + delta;
        if (cand < 0 || cand > 100) continue;
      }
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
      case _Zahl100FrageTyp.nachfolger:
        text = 'Welche Zahl kommt nach $_zahl1?';
        break;
      case _Zahl100FrageTyp.vorgaenger:
        text = 'Welche Zahl kommt vor $_zahl1?';
        break;
      case _Zahl100FrageTyp.vergleich:
        text = 'Welche Zahl ist größer: $_zahl1 oder $_zahl2?';
        break;
      case _Zahl100FrageTyp.zehnerEiner:
        text = 'Wie viele Zehner hat die Zahl $_zahl1?';
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
      widget.appState.addXp(6);
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
    await Future.delayed(const Duration(milliseconds: 1300));
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
          child: Column(children: [
            Text('Aufgabe ${_taskIdx + 1} / $_totalTasks',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const Text('Zahlen bis 100',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ]),
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
      case _Zahl100FrageTyp.nachfolger:
        text = 'Welche Zahl kommt nach $_zahl1?';
        break;
      case _Zahl100FrageTyp.vorgaenger:
        text = 'Welche Zahl kommt vor $_zahl1?';
        break;
      case _Zahl100FrageTyp.vergleich:
        text = 'Welche Zahl ist größer?';
        break;
      case _Zahl100FrageTyp.zehnerEiner:
        text = 'Wie viele Zehner hat $_zahl1?';
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      case _Zahl100FrageTyp.nachfolger:
      case _Zahl100FrageTyp.vorgaenger:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _gradient[0].withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
              _typ == _Zahl100FrageTyp.nachfolger
                  ? '$_zahl1   →   ?'
                  : '?   →   $_zahl1',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: _gradient[1])),
        );
      case _Zahl100FrageTyp.vergleich:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bigNumberBox(_zahl1),
            const Text('oder',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280))),
            _bigNumberBox(_zahl2),
          ],
        );
      case _Zahl100FrageTyp.zehnerEiner:
        final zehner = _zahl1 ~/ 10;
        final einer = _zahl1 % 10;
        return Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
            ),
            child: Text('$_zahl1',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: _gradient[1])),
          ),
          const SizedBox(height: 12),
          Text('Das sind ? Zehner und $einer Einer',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _gradient[1].withOpacity(0.7))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < zehner; i++)
                Container(
                  width: 24,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _gradient[0],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 10),
              for (int i = 0; i < einer; i++)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _gradient[1].withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ]);
    }
  }

  Widget _bigNumberBox(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gradient[0].withOpacity(0.3), width: 2),
      ),
      child: Text('$n',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: _gradient[1])),
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
    } else if (_answered && isCorrect) {
      bgColor = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFFCD34D);
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
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor)),
          ),
        ),
      ),
    );
  }
}
