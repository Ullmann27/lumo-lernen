import '../../../widgets/design/lumo_answer_crystal.dart';
// ════════════════════════════════════════════════════════════════════════
// EINMALEINS — Klasse 2/3 Mathematik (interaktiv)
// ════════════════════════════════════════════════════════════════════════
// Klasse 2: 2er, 5er, 10er-Reihe
// Klasse 3: alle Reihen 1x1 bis 10x10
// 12 Aufgaben pro Session, Multiple-Choice, progressive Schwierigkeit.
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
  late final LearningModuleProgress _progress;
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
    _showHint = false;
    _wrongAttempts = 0;
  }

  void _speakTask() {
    if (!widget.appState.state.settings.voiceEnabled) return;
    try {
      LumoVoice.instance.speak('$_a mal $_b. Wie viel ist das?');
    } catch (_) {}
  }

  void _onAnswer(int answer) async {
    if (_answered || _progress.hasPending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
    final isCorrect = answer == _correct;
    final saved = await _progress.saveAnswer(
      correct: isCorrect,
      hintUsed: _showHint,
      stars: isCorrect ? 1 : 0,
      xp: isCorrect ? 6 : 0,
      prompt: '$_a × $_b = ?',
      given: '$answer',
      expected: '$_correct',
    );
    if (!saved || !mounted) return;
    if (isCorrect) {
      _bounceCtrl.forward(from: 0);
      setState(() => _correctCount++);
      try {
        LumoVoice.instance.speak(LumoPhrases.correct());
      } catch (_) {}
      if (!await _progress.feedbackDelay(const Duration(milliseconds: 1100)) ||
          !mounted) {
        return;
      }
      _nextTask();
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      _wrongAttempts++;
      try {
        LumoVoice.instance.speak(LumoPhrases.wrongGentle());
      } catch (_) {}
      if (!await _progress.feedbackDelay(const Duration(milliseconds: 1400)) ||
          !mounted) {
        return;
      }
      if (_wrongAttempts >= 2) {
        setState(() => _showHint = true);
        if (!await _progress
                .feedbackDelay(const Duration(milliseconds: 2800)) ||
            !mounted) {
          return;
        }
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
            _buildVisualization(),
            const SizedBox(height: 16),
            _buildAnswerGrid(),
            if (_showHint) ...[
              const SizedBox(height: 20),
              _buildHintCard(),
            ],
          ]),
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

  // Visualisierung: a Reihen mit je b Punkten = Multiplikations-Gitter
  Widget _buildVisualization() {
    if (_a > 5 || _b > 5) {
      // Bei groesseren Zahlen: Hinweis statt visualisieren (sonst Overflow)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LumoVisualTokens.cyan.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
            '$_a-mal die $_b zusammenzählen:\n'
            '${List.filled(_a, _b).join(' + ')} = ?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LumoVisualTokens.white)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LumoVisualTokens.lessonPanel.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .55)),
      ),
      child: Column(
        children: List.generate(_a, (row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_b, (col) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _gradient[0],
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          );
        }),
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
    final isCorrect = value == _correct;
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) => Transform.scale(
        scale: isSelected && isCorrect &&
                !LumoLessonStyle.reducedMotion(context, widget.appState)
            ? 1 + math.sin(_bounceCtrl.value * math.pi) * .1 : 1,
        child: child,
      ),
      child: LumoAnswerCrystal(
        label: '$value',
        onPressed: _answered ? null : () => _onAnswer(value),
        state: _answered && isCorrect && (isSelected || _wrongAttempts >= 1)
            ? LumoCrystalState.correct
            : _answered && isSelected ? LumoCrystalState.retry
            : LumoCrystalState.neutral,
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
          const Text('Trick:',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD97706))),
        ]),
        const SizedBox(height: 8),
        Text(
            '$_a × $_b heißt: $_a-mal die $_b nehmen. '
            '${List.filled(_a, _b).join(' + ')} = $_correct',
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E))),
      ]),
    );
  }
}
