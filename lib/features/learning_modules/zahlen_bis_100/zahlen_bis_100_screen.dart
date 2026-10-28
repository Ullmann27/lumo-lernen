// ════════════════════════════════════════════════════════════════════════
// ZAHLEN BIS 100 — Klasse 2 Mathematik
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen:
//   - 'Welche Zahl kommt nach X?' (Nachfolger 0..99)
//   - 'Welche Zahl ist groesser: X oder Y?' (Vergleich)
//   - 'Wie viele Zehner und Einer hat X?' (Stellenwert)
// 12 Aufgaben pro Session.
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/design/lumo_learning_module_frame.dart';
import '../../../widgets/design/lumo_answer_crystal.dart';
import '../../../widgets/design/lumo_math_stage.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';
import '../learning_module_progress.dart';

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

  final _lumo = LumoCharacterController();
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  late final LearningModuleProgress _progress;
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
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Mathematik',
      unit: 'Zahlen bis 100',
    );
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
    _progress.dispose();
    _lumo.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _generateTask() {
    _typ =
        _Zahl100FrageTyp.values[_rng.nextInt(_Zahl100FrageTyp.values.length)];
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
    // FIX: Safety-Limit gegen theoretischen Endlos-Loop, falls correctAnswer
    // an einer Bereichsgrenze sitzt (0 oder 100) und die Random-Deltas
    // ungluecklich fallen. Nach 60 Versuchen Auffuellen mit beliebigen
    // anderen Zahlen, damit immer 3 unique wrong answers da sind.
    var safety = 0;
    while (wrong.length < 3 && safety < 60) {
      safety++;
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
    var fillCounter = 1;
    while (wrong.length < 3 && fillCounter < 200) {
      final cand = (_correctAnswer + fillCounter) % 100 + 1;
      if (cand != _correctAnswer) wrong.add(cand);
      fillCounter++;
    }
    // "Welche Zahl ist groesser?": nur die beiden gezeigten Zahlen zur Wahl.
    // Vorher kamen zufaellige Zahlen dazu, die kleinere fehlte oft, und eine
    // noch groessere Zahl wurde als falsch gewertet.
    _answers = _typ == _Zahl100FrageTyp.vergleich
        ? ([_zahl1, _zahl2]..shuffle(_rng))
        : ([_correctAnswer, ...wrong]..shuffle(_rng));
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
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final isCorrect = answer == _correctAnswer;
    final saved = await _progress.saveAnswer(
      problemKey: '${_typ.name}:$_zahl1:${_typ == _Zahl100FrageTyp.vergleich ? _zahl2 : 0}',
      correct: isCorrect,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 6 : 0,
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _lumo.cheer();
      setState(() => _correctCount++);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      _lumo.comfort();
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
    }
    if (!await _progress.feedbackDelay(const Duration(milliseconds: 1300)) ||
        !mounted) {
      return;
    }
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

  Future<void> _showFinish() async {
    final stars = ((_correctCount / _totalTasks) * 5).round().clamp(1, 5);
    final saved =
        await _progress.saveBonus(stars: stars, xp: _correctCount * 10);
    if (!saved || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: LumoVisualTokens.navigation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Geschafft!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount / $_totalTasks Aufgaben richtig!',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: LumoVisualTokens.white,
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
                  color: LumoVisualTokens.white,
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
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        immersive: true,
        characterController: _lumo,
        scrollResetKey: _taskIdx,
        title: 'Mathe-Abenteuer',
        moduleTitle: 'Zahlen bis 100',
        icon: Icons.pin_rounded,
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        correctAnswers: _correctCount,
        progressLabel: 'Aufgabe',
        canLeave: () => !_progress.hasPending,
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, child) {
            return Opacity(
                opacity: LumoLessonStyle.reducedMotion(context, widget.appState)
                    ? 1
                    : _entryCtrl.value,
                child: child);
          },
          child: Column(children: [
            _buildTaskHeader(),
            const SizedBox(height: 12),
            LumoMathStage(
              visualization: _buildVisualization(),
              controller: _lumo,
              reduceMotion:
                  LumoLessonStyle.reducedMotion(context, widget.appState),
            ),
            const SizedBox(height: 16),
            _buildAnswerGrid(),
          ]),
        ),
      ),
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
        final shake = LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 0.0
            : math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: LumoCrystalPanel(
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }

  Widget _buildVisualization() {
    switch (_typ) {
      case _Zahl100FrageTyp.nachfolger:
      case _Zahl100FrageTyp.vorgaenger:
        return LumoCrystalPanel(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_typ == _Zahl100FrageTyp.nachfolger ? '$_zahl1' : '?',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.white)),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 30, color: LumoVisualTokens.cyanBright)),
                  Text(_typ == _Zahl100FrageTyp.nachfolger ? '?' : '$_zahl1',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.white)),
                ])));
      case _Zahl100FrageTyp.vergleich:
        // Schmal oder mit großer Schrift verkleinern statt überlaufen.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bigNumberBox(_zahl1),
              const SizedBox(width: 16),
              const Text('oder',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: LumoVisualTokens.muted)),
              const SizedBox(width: 16),
              _bigNumberBox(_zahl2),
            ],
          ),
        );
      case _Zahl100FrageTyp.zehnerEiner:
        final zehner = _zahl1 ~/ 10;
        final einer = _zahl1 % 10;
        return Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: LumoVisualTokens.cyan.withValues(alpha: .55),
                  width: 2),
            ),
            child: Text('$_zahl1',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white)),
          ),
          const SizedBox(height: 12),
          Text('Das sind ? Zehner und $einer Einer',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LumoVisualTokens.white.withOpacity(0.7))),
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
                    color: LumoVisualTokens.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ]);
    }
  }

  Widget _bigNumberBox(int n) {
    return LumoCrystalPanel(
      child: Text('$n',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white)),
    );
  }

  Widget _buildAnswerGrid() => LumoCrystalAnswerGrid(
        children: _answers.map(_buildAnswerButton).toList(),
      );

  Widget _buildAnswerButton(int value) => LumoAnswerCrystal(
        label: '$value',
        onPressed: _answered ? null : () => _onAnswer(value),
        state: !_answered
            ? LumoCrystalState.neutral
            : value == _correctAnswer
                ? LumoCrystalState.correct
                : _selectedAnswer == value
                    ? LumoCrystalState.retry
                    : LumoCrystalState.neutral,
      );
}
