import '../../../widgets/design/lumo_answer_crystal.dart';
// ════════════════════════════════════════════════════════════════════════
// ZAHLEN BIS 10 — Klasse 1 Mathematik (visuelles Zaehlen)
// ════════════════════════════════════════════════════════════════════════
// Aufgabentypen (gemischt):
//   - 'Wie viele Punkte siehst du?' (Zaehlen 1-10)
//   - 'Welche Zahl kommt nach X?'
//   - 'Welche Zahl ist groesser: X oder Y?'
// 12 Aufgaben pro Session, Multiple-Choice.
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/design/lumo_learning_module_frame.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../lumo_phrases.dart';
import '../learning_module_progress.dart';
import '../../learning/nextgen/module_task_scope.dart';

enum _ZahlAufgabenTyp { zaehlen, nachfolger, groesser }

class ZahlenBis10Screen extends StatefulWidget {
  const ZahlenBis10Screen({
    super.key,
    required this.appState,
    this.taskRandom,
  });
  final LumoAppState appState;
  // Optional reproducible samples; the normal route retains Random().
  final math.Random? taskRandom;

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
  final _taskScopeKey = GlobalKey();
  late final LearningModuleProgress _progress;
  late final _rng = widget.taskRandom ?? math.Random();

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
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Mathematik',
      unit: 'Zahlen 1-10',
    );
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
    _progress.dispose();
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
        _zahl1 = _rng.nextInt(10); // 0..9, damit auch 9 → 10 geübt wird.
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
    // "Welche Zahl ist groesser?": nur die beiden gezeigten Zahlen zur Wahl.
    // Vorher kamen zufaellige Zahlen dazu, die kleinere fehlte oft, und eine
    // noch groessere Zahl wurde als falsch gewertet.
    _answers = _typ == _ZahlAufgabenTyp.groesser
        ? ([_zahl1, _zahl2]..shuffle(_rng))
        : ([_correctAnswer, ...wrong]..shuffle(_rng));
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
        text = 'Welche Zahl ist größer: $_zahl1 oder $_zahl2?';
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
      problemKey:
          '${_typ.name}:$_zahl1:${_typ == _ZahlAufgabenTyp.groesser ? _zahl2 : 0}',
      correct: isCorrect,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 5 : 0,
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      setState(() => _correctCount++);
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
    if (!await _progress.feedbackDelay(const Duration(milliseconds: 1100)) ||
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
        await _progress.saveBonus(stars: stars, xp: _correctCount * 8);
    if (!saved || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Geschafft!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
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

  Widget _withTaskContext(Widget child) => ModuleTaskScope(
        key: _taskScopeKey,
        appState: widget.appState,
        progress: _progress,
        moduleId: 'm1_zahlen10',
        taskKey: _taskIdx,
        prompt: switch (_typ) {
          _ZahlAufgabenTyp.zaehlen => 'Wie viele Punkte siehst du?',
          _ZahlAufgabenTyp.nachfolger => 'Welche Zahl kommt nach $_zahl1?',
          _ZahlAufgabenTyp.groesser =>
            'Welche Zahl ist größer: $_zahl1 oder $_zahl2?',
        },
        objective: switch (_typ) {
          _ZahlAufgabenTyp.zaehlen => 'Du zählst jeden Punkt genau einmal.',
          _ZahlAufgabenTyp.nachfolger =>
            'Du findest den nächsten Schritt in der Zahlenreihe.',
          _ZahlAufgabenTyp.groesser => 'Du vergleichst zwei Zahlen bis zehn.',
        },
        answerChoices: _answers.map((number) => '$number').toList(),
        onConfirmChoice: (index) => _onAnswer(_answers[index]),
        helpSteps: switch (_typ) {
          _ZahlAufgabenTyp.zaehlen => [
              'Beginne bei einem Punkt. Berühre beim Zählen jeden Punkt genau einmal.',
              'Gehe in einer festen Reihenfolge, zum Beispiel von links nach rechts. So vergisst du keinen Punkt.',
              'Die zuletzt gesprochene Zahl sagt, wie viele Punkte es insgesamt sind. Suche diese Zahl bei den Antworten.',
            ],
          _ZahlAufgabenTyp.nachfolger => [
              'Starte bei $_zahl1 und zähle genau einen Schritt weiter.',
              'Der Nachfolger ist eins mehr. Stell dir vor, zu $_zahl1 kommt noch ein Gegenstand dazu.',
              'Prüfe die Antwort, indem du von ihr einen Schritt zurückzählst. Dann musst du wieder bei $_zahl1 sein.',
            ],
          _ZahlAufgabenTyp.groesser => [
              'Vergleiche nur die beiden gezeigten Zahlen $_zahl1 und $_zahl2.',
              'Sprich die Zahlenreihe. Welche der beiden Zahlen kommt später?',
              'Stell dir zu jeder Zahl eine Reihe gleich großer Punkte vor. Die längere Reihe gehört zur größeren Zahl.',
            ],
        },
        answering: !_answered,
        lastAnswer: _selectedAnswer?.toString(),
        lastCorrect: _answered ? _selectedAnswer == _correctAnswer : null,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: 'Mathe-Abenteuer',
        moduleTitle: 'Zahlen bis 10',
        guidance: switch (_typ) {
          _ZahlAufgabenTyp.zaehlen => 'Zähle jeden Punkt einmal.',
          _ZahlAufgabenTyp.nachfolger => 'Zähle einen Schritt weiter.',
          _ZahlAufgabenTyp.groesser => 'Vergleiche die beiden Zahlen.',
        },
        mistakeGuidance: 'Wir lernen Schritt für Schritt.',
        icon: Icons.pin_rounded,
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        correctAnswers: _correctCount,
        progressLabel: 'Aufgabe',
        hasMistake: _answered && _selectedAnswer != _correctAnswer,
        canLeave: () => !_progress.hasPending,
        companionUnit: _progress.unit,
        child: _withTaskContext(AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, child) {
            return Opacity(
                opacity: LumoLessonStyle.reducedMotion(context, widget.appState)
                    ? 1
                    : _entryCtrl.value,
                child: child);
          },
          child: LumoLessonTaskLayout(
            task: Column(children: [
              _buildTaskHeader(),
              const SizedBox(height: 12),
              _buildVisualization(),
            ]),
            answers: _buildAnswerGrid(),
          ),
        )),
      ),
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
        final shake = LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 0.0
            : math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 2),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }

  Widget _buildVisualization() {
    switch (_typ) {
      case _ZahlAufgabenTyp.zaehlen:
        return _buildDots(_zahl1);
      case _ZahlAufgabenTyp.nachfolger:
        return LumoLessonNumberFlow(before: '$_zahl1', after: '?');
      case _ZahlAufgabenTyp.groesser:
        // Schmal oder mit großer Schrift wird die Zeile verkleinert statt
        // über den Rand zu laufen.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBigNumber(_zahl1),
              const SizedBox(width: 16),
              const Text('oder',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: LumoVisualTokens.muted)),
              const SizedBox(width: 16),
              _buildBigNumber(_zahl2),
            ],
          ),
        );
    }
  }

  Widget _buildBigNumber(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 2),
      ),
      child: Text('$n',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white)),
    );
  }

  Widget _buildDots(int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .55)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          count,
          (i) => Container(
            key: ValueKey('zahlen-dot-$i'),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _gradient[0],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: LumoVisualTokens.cyan.withValues(alpha: .55),
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
    return LumoLessonAnswerGrid(
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
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) => Transform.scale(
        scale: isSelected &&
                isCorrect &&
                !LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * .1
            : 1,
        child: child,
      ),
      child: LumoAnswerCrystal(
        label: '$value',
        onPressed: _answered ? null : () => _onAnswer(value),
        state: _answered && isCorrect && (isSelected || false)
            ? LumoCrystalState.correct
            : _answered && isSelected
                ? LumoCrystalState.retry
                : LumoCrystalState.neutral,
      ),
    );
  }
}
