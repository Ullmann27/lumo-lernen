import '../../../widgets/design/lumo_answer_crystal.dart';
// ════════════════════════════════════════════════════════════════════════
// MINUS BIS 10 — Klasse 1 Mathematik (interaktiv, kein Chat)
// ════════════════════════════════════════════════════════════════════════
// Visualisierung: Bonbons werden weggenommen. Kind tippt richtige Anzahl.
// 4 Multiple-Choice Antworten pro Aufgabe, 30 Aufgaben pro Session.
// Bei richtig: Lumo lobt + Sterne. Nach dem ersten Fehler: Rückmeldung, die
// zum Fehler passt, und ein zweiter Versuch. Nach dem zweiten Fehler: der
// Lösungsweg in Schritten; das Kind tippt die erklärte Antwort selbst an.
// Keine Aufgabe wird übersprungen.
// ════════════════════════════════════════════════════════════════════════

import '../../../widgets/design/lumo_learning_module_frame.dart';
import '../../learning/widgets/lumo_quantity_workbenches.dart';
import '../../learning/nextgen/module_task_scope.dart';
import '../../../theme/lumo_visual_tokens.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_voice.dart';
import '../../../domain/learning/error_detective.dart';
import '../../learning/widgets/lumo_mistake_help_card.dart';
import '../lumo_phrases.dart';
import '../learning_module_progress.dart';
import '../learning_module_rounds.dart';

class MinusBis10Screen extends StatefulWidget {
  const MinusBis10Screen({
    super.key,
    required this.appState,
    this.taskRandom,
  });
  final LumoAppState appState;
  // A reproducible test input; the normal route retains Random() unchanged.
  final math.Random? taskRandom;

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
  final _taskScopeKey = GlobalKey();
  late final LearningModuleProgress _progress;
  late final LearningModuleRounds _rounds =
      LearningModuleRounds(progress: _progress, totalTasks: _totalTasks);
  late final _rng = widget.taskRandom ?? math.Random();
  late final List<(int, int)> _round;

  int _taskIdx = 0;
  int _correctCount = 0;
  int _wrongAttempts = 0;
  // Help in two steps: feedback after the first mistake, the worked
  // solution after the second. The task is never skipped.
  final Set<int> _wrongAnswers = <int>{};
  String? _mistakeMessage;
  bool _mistakeRecognised = false;
  bool _hintShown = false;
  bool _guided = false;
  bool _guidedNudge = false;
  bool _answered = false;
  int? _selectedAnswer;
  Set<int> _removedBonbons = {};

  late int _a;
  late int _b;
  late List<int> _answers;

  int get _correct => _a - _b;

  @override
  void initState() {
    super.initState();
    _round = [
      for (var a = 3; a <= 10; a++)
        for (var b = 1; b < a; b++) (a, b),
    ]..shuffle(math.Random());
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Mathematik',
      unit: 'Minus bis 10',
    );
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _generateTask();
    _restoreRound();
    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakTask();
    });
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
    // _a in 3..10, _b in 1.._a-1 -> Ergebnis 1..9 (nie 0 oder negativ)
    // Tests may inject a seeded RNG to exercise each visible quantity.
    // Keep that deterministic accessibility probe unchanged. Real child
    // sessions (no injected RNG) use the unique shuffled problem deck.
    if (widget.taskRandom != null) {
      _a = 3 + _rng.nextInt(8);
      _b = 1 + _rng.nextInt(_a - 1);
    } else {
      final problem = _round[_taskIdx];
      _a = problem.$1;
      _b = problem.$2;
    }
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
    _wrongAttempts = 0;
    _wrongAnswers.clear();
    _mistakeMessage = null;
    _mistakeRecognised = false;
    _hintShown = false;
    _guided = false;
    _guidedNudge = false;
    _removedBonbons = {};
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('$_a minus $_b. Wie viele bleiben?');
    } catch (_) {}
  }

  void _speak(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  void _onAnswer(int answer) async {
    if (_answered || _progress.hasPending) return;
    final isCorrect = answer == _correct;
    // The solution has been worked through together. A wrong tap is not
    // recorded again; it only points back to the explained answer.
    if (_guided && !isCorrect) {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      setState(() => _guidedNudge = true);
      return;
    }
    if (_wrongAnswers.contains(answer)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    // Solved alone: first try and no tip. Everything else is recorded as
    // solved together. The module's small reward for a finished task stays
    // as it was (the Android flow checks it); the difference shows in the
    // evidence and in the "allein gelöst" count.
    final alone = isCorrect && _wrongAttempts == 0 && !_hintShown;
    final saved = await _progress.saveAnswer(
      problemKey: '$_a - $_b',
      cosmosSubjectId: 'm1_minus10',
      cosmosIsMath: true,
      correct: isCorrect,
      hintUsed: _wrongAttempts > 0 || _hintShown,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 5 : 0,
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      if (alone) setState(() => _correctCount++);
      _speak(alone ? LumoPhrases.correct() : 'Gemeinsam gelöst!');
      if (!await _progress.feedbackDelay(const Duration(milliseconds: 1100)) ||
          !mounted) {
        return;
      }
      _nextTask();
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      final detection = const ErrorDetective().analyze(
        subject: 'Mathematik',
        prompt: '$_a − $_b = ?',
        correctAnswer: '$_correct',
        givenAnswer: '$answer',
      );
      final message = detection.isRecognised
          ? detection.childFriendlyMessage
          : 'Das passt noch nicht. Schau noch einmal auf die Bonbons.';
      final worked = _wrongAttempts + 1 >= 2;
      _speak(worked ? 'Wir lösen es gemeinsam, Schritt für Schritt.' : message);
      if (!await _progress.feedbackDelay(const Duration(milliseconds: 1400)) ||
          !mounted) {
        return;
      }
      setState(() {
        _wrongAttempts++;
        _answered = false;
        _selectedAnswer = null;
        if (worked) {
          // All answers are available again: the child taps the explained
          // answer instead of the last one left.
          _guided = true;
          _wrongAnswers.clear();
          _mistakeMessage = null;
        } else {
          _wrongAnswers.add(answer);
          _mistakeMessage = message;
          _mistakeRecognised = detection.isRecognised;
        }
      });
    }
  }

  /// Continues at the round where the child stopped last time.
  Future<void> _restoreRound() async {
    final position = await _rounds.restore();
    if (position == null || !mounted || _taskIdx != 0 || _answered) return;
    setState(() {
      _taskIdx = position.completedTasks;
      _correctCount = position.correct;
      _generateTask();
    });
    _speakTask();
  }

  Future<void> _nextTask() async {
    if (_taskIdx + 1 >= _totalTasks) {
      _rounds.finished();
      _showFinish();
      return;
    }
    // After every tenth task: a real place to stop, with the place saved.
    if (!await _rounds.continueAfter(context,
        completedTasks: _taskIdx + 1, correct: _correctCount)) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;
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
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Geschafft!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_correctCount von $_totalTasks allein gelöst!',
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
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: 'Mathe-Abenteuer',
        moduleTitle: 'Minus bis 10',
        guidance: 'Zähle, was übrig bleibt.',
        mistakeGuidance: 'Die übrigen Bonbons zählen.',
        icon: Icons.calculate_rounded,
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        inRounds: true,
        correctAnswers: _correctCount,
        progressLabel: 'Aufgabe',
        hasMistake: _answered && _selectedAnswer != _correct,
        canLeave: () => !_progress.hasPending,
        companionUnit: _progress.unit,
        child: ModuleTaskScope(
          key: _taskScopeKey,
          appState: widget.appState,
          progress: _progress,
          moduleId: 'm1_minus10',
          taskKey: _taskIdx,
          prompt: '$_a − $_b = ?',
          objective: 'Eine Menge verkleinern und den Rest bestimmen.',
          answerChoices: _answers.map((answer) => '$answer').toList(),
          onConfirmChoice: (index) => _onAnswer(_answers[index]),
          helpSteps: [
            'Bei Minus nimmst du etwas von der Startmenge weg.',
            'Tippe $_b Bonbons an. Sie werden durchgestrichen. '
                'Ein zweites Antippen legt einen Bonbon zurück.',
            'Prüfe zuerst: Hast du genau $_b weggenommen? '
                'Zähle dann nur die Bonbons ohne Kreuz.',
          ],
          answering: !_answered && !_progress.hasPending,
          lastAnswer: _selectedAnswer?.toString(),
          lastCorrect: _answered ? _selectedAnswer == _correct : null,
          child: AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, child) {
              return Opacity(
                  opacity:
                      LumoLessonStyle.reducedMotion(context, widget.appState)
                          ? 1
                          : _entryCtrl.value,
                  child: child);
            },
            child: LumoLessonTaskLayout(
              landscapeAlignment: CrossAxisAlignment.start,
              task: Column(children: [
                _buildTaskHeader(),
                const SizedBox(height: 12),
                _buildBonbonsVisualization(),
              ]),
              answers: Column(children: [
                if (_guided) ...[
                  LumoWorkedSolutionCard(
                    steps: [
                      'Du hast $_a Bonbons.',
                      'Nimm $_b davon weg. Zähle, wie viele ohne Kreuz '
                          'bleiben.',
                      'Es bleiben $_correct. Also: $_a − $_b = $_correct.',
                    ],
                    callToAction: 'Tippe jetzt die $_correct an.',
                    nudge: _guidedNudge,
                  ),
                  const SizedBox(height: 14),
                ] else if (_mistakeMessage != null) ...[
                  LumoMistakeFeedbackCard(
                    message: _mistakeMessage!,
                    recognised: _mistakeRecognised,
                    hint: 'Tippe $_b Bonbons an: Sie werden durchgestrichen. '
                        'Zähle dann nur die Bonbons ohne Kreuz.',
                    hintVisible: _hintShown,
                    onShowHint: () {
                      _progress.notePresentationHelp();
                      setState(() => _hintShown = true);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                _buildAnswerGrid(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) {
        final shake = LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 0.0
            : math.sin(_shakeCtrl.value * math.pi * 8) * 6;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 2),
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
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }

  Widget _buildBonbonsVisualization() => LumoSubtractionWorkbench(
        start: _a,
        takeAway: _b,
        removed: _removedBonbons,
        enabled: !_answered && !_progress.hasPending,
        onChanged: (removed) => setState(() => _removedBonbons = removed),
      );

  Widget _buildAnswerGrid() {
    // The compact lesson grid caps cells at 68–84 dp and flattens the body
    // and pedestal. Reserve the existing crystal grid's full material height.
    return LumoCrystalAnswerGrid(
      children: _answers.map((a) => _buildAnswerButton(a)).toList(),
    );
  }

  Widget _buildAnswerButton(int value) {
    final isSelected = _selectedAnswer == value;
    final isCorrect = value == _correct;
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
        onPressed: _answered || _wrongAnswers.contains(value)
            ? null
            : () => _onAnswer(value),
        state: _answered && isCorrect && isSelected
            ? LumoCrystalState.correct
            : (_answered && isSelected) || _wrongAnswers.contains(value)
                ? LumoCrystalState.retry
                : LumoCrystalState.neutral,
      ),
    );
  }
}
