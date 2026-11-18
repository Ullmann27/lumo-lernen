import '../../../widgets/design/lumo_answer_crystal.dart';
// ════════════════════════════════════════════════════════════════════════
// EINMALEINS — Klasse 2/3 Mathematik (interaktiv)
// ════════════════════════════════════════════════════════════════════════
// Klasse 2: 2er, 5er, 10er-Reihe
// Klasse 3: alle Reihen 1x1 bis 10x10
// 12 Aufgaben pro Session, Multiple-Choice, progressive Schwierigkeit.
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
import '../../learning/widgets/lumo_mistake_help_card.dart';
import '../lumo_phrases.dart';
import '../learning_module_progress.dart';

class EinmaleinsScreen extends StatefulWidget {
  const EinmaleinsScreen({
    super.key,
    required this.appState,
    this.fullRange = false, // false = nur 2/5/10er (Klasse 2)
  });
  final LumoAppState appState;
  final bool fullRange;

  @override
  State<EinmaleinsScreen> createState() => _EinmaleinsScreenState();
}

class _EinmaleinsScreenState extends State<EinmaleinsScreen>
    with TickerProviderStateMixin {
  static const int _totalTasks = 12;
  static const List<Color> _gradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];

  late final AnimationController _bounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _entryCtrl;
  final _taskScopeKey = GlobalKey();
  late final LearningModuleProgress _progress;
  final _rng = math.Random();

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
  Set<int> _countedGroups = {};

  late int _a;
  late int _b;
  late List<int> _answers;

  int get _correct => _a * _b;

  // Reihen die genutzt werden duerfen
  List<int> get _availableRows =>
      widget.fullRange ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] : [2, 5, 10];

  @override
  void initState() {
    super.initState();
    _progress = LearningModuleProgress(
      appState: widget.appState,
      subject: 'Mathematik',
      unit: widget.fullRange ? 'Großes 1×1' : 'Kleines 1×1',
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
    _a = _availableRows[_rng.nextInt(_availableRows.length)];
    _b = 2 + _rng.nextInt(9); // 2..10
    final correct = _correct;
    final wrongOptions = <int>{};
    // FIX: Safety-Limit. Bei correct=2 (z.B. _a=1, _b=2) koennen
    // negative Shifts nie greifen - vorher theoretisch Endlos-Loop.
    var safety = 0;
    while (wrongOptions.length < 3 && safety < 60) {
      safety++;
      final shifts = [_a, -_a, _b, -_b, _a * 2, -_a];
      final shift = shifts[_rng.nextInt(shifts.length)];
      final cand = correct + shift;
      if (cand > 0 && cand <= 100 && cand != correct) {
        wrongOptions.add(cand);
      }
    }
    // Auffuellen falls weniger als 3 zusammengekommen sind.
    var fillCounter = 1;
    while (wrongOptions.length < 3 && fillCounter < 200) {
      final cand = correct + fillCounter;
      if (cand > 0 && cand <= 100 && cand != correct) {
        wrongOptions.add(cand);
      }
      fillCounter++;
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
    _countedGroups = {};
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('$_a mal $_b. Wie viel ist das?');
    } catch (_) {}
  }

  void _speak(String text) {
    try {
      LumoVoice.instance.speak(text);
    } catch (_) {}
  }

  /// What a wrong product tells: one group too many or too few is the
  /// typical slip in a times table. Anything else gets a neutral sentence.
  ({String text, bool recognised}) _mistakeMessageFor(int answer) {
    final diff = (answer - _correct).abs();
    if (diff == _b) {
      return (
        text: answer > _correct
            ? 'Das ist eine $_b-er-Gruppe zu viel. Zähl die Gruppen noch '
                'einmal: Es sind $_a.'
            : 'Da fehlt noch eine $_b-er-Gruppe. Zähl die Gruppen noch '
                'einmal: Es sind $_a.',
        recognised: true,
      );
    }
    if (answer == _a + _b) {
      return (
        text: 'Du hast plus gerechnet. Mal heißt: $_a Gruppen mit je $_b.',
        recognised: true,
      );
    }
    return (
      text: 'Das passt noch nicht. Schau noch einmal: $_a Gruppen mit je $_b.',
      recognised: false,
    );
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
    // as it was; the difference shows in the evidence and in the
    // "allein gelöst" count.
    final alone = isCorrect && _wrongAttempts == 0 && !_hintShown;
    final saved = await _progress.saveAnswer(
      correct: isCorrect,
      hintUsed: _wrongAttempts > 0 || _hintShown,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 6 : 0,
      prompt: '$_a × $_b = ?',
      given: '$answer',
      expected: '$_correct',
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
      final message = _mistakeMessageFor(answer);
      final worked = _wrongAttempts + 1 >= 2;
      _speak(worked
          ? 'Wir lösen es gemeinsam, Schritt für Schritt.'
          : message.text);
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
          _mistakeMessage = message.text;
          _mistakeRecognised = message.recognised;
        }
      });
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
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: 'Mathe-Abenteuer',
        moduleTitle: widget.fullRange ? 'Großes 1×1' : 'Einmaleins 2/5/10',
        icon: Icons.grid_view_rounded,
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        correctAnswers: _correctCount,
        progressLabel: 'Aufgabe',
        hasMistake: _answered && _selectedAnswer != _correct,
        canLeave: () => !_progress.hasPending,
        companionUnit: _progress.unit,
        child: ModuleTaskScope(
          key: _taskScopeKey,
          appState: widget.appState,
          progress: _progress,
          moduleId: widget.fullRange ? 'm3_einmaleins_voll' : 'm2_einmaleins',
          taskKey: _taskIdx,
          prompt: '$_a × $_b = ?',
          objective:
              'Gleich große Gruppen zusammenzählen und als Malaufgabe verstehen.',
          answerChoices: _answers.map((answer) => '$answer').toList(),
          onConfirmChoice: (index) => _onAnswer(_answers[index]),
          helpSteps: [
            'Du siehst $_a Gruppen. Jede Gruppe enthält genau $_b Steine.',
            'Markiere eine Gruppe nach der anderen. '
                'Mit jeder weiteren Gruppe kommen $_b Steine dazu.',
            'Zähle in $_b-er-Schritten. Beginne mit der ersten Gruppe '
                'und addiere für jede weitere Gruppe $_b.',
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
            child: Column(children: [
              _buildTaskHeader(),
              const SizedBox(height: 12),
              _buildVisualization(),
              const SizedBox(height: 16),
              if (_guided) ...[
                LumoWorkedSolutionCard(
                  steps: [
                    '$_a × $_b heißt: $_a Gruppen mit je $_b.',
                    'Zähle in $_b-er-Schritten, $_a-mal: '
                        '${List.generate(_a, (i) => (i + 1) * _b).join(', ')}.',
                    'Die letzte Zahl ist die Lösung: $_a × $_b = $_correct.',
                  ],
                  callToAction: 'Tippe jetzt die $_correct an.',
                  nudge: _guidedNudge,
                ),
                const SizedBox(height: 14),
              ] else if (_mistakeMessage != null) ...[
                LumoMistakeFeedbackCard(
                  message: _mistakeMessage!,
                  recognised: _mistakeRecognised,
                  hint: 'Tippe die Gruppen oben der Reihe nach an. Mit jeder '
                      'Gruppe kommen $_b dazu.',
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
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
        child: Text('$_a × $_b = ?',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white)),
      ),
    );
  }

  Widget _buildVisualization() => LumoEqualGroupsWorkbench(
        groups: _a,
        perGroup: _b,
        counted: _countedGroups,
        enabled: !_answered && !_progress.hasPending,
        onChanged: (groups) => setState(() => _countedGroups = groups),
      );

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
        // The right answer is never shown while the child still has a try.
        state: _answered && isCorrect && isSelected
            ? LumoCrystalState.correct
            : (_answered && isSelected) || _wrongAnswers.contains(value)
                ? LumoCrystalState.retry
                : LumoCrystalState.neutral,
      ),
    );
  }
}
