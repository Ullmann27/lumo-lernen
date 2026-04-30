import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/lumo_voice.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import 'adapters/legacy_lumo_task_adapter.dart';
import 'renderers/adaptive_task_renderer.dart';

class LearningContent extends StatefulWidget {
  const LearningContent({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LearningContent> createState() => _LearningContentState();
}

class _LearningContentState extends State<LearningContent> {
  final _factory = ExerciseFactory();
  final _adapter = const LegacyLumoTaskAdapter();

  late LumoTask _task;
  late TaskInstance _taskInstance;
  bool _answered = false;
  bool? _lastCorrect;
  int _questionNum = 1;
  final int _totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    _loadNextTask(resetCounter: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LumoVoice.instance.speak('Arbeite wie im Heft. Ruhig lesen, dann erst antworten.');
    });
  }

  void _loadNextTask({bool resetCounter = false}) {
    _task = _nextTask();
    _taskInstance = _adapter.toTaskInstance(
      task: _task,
      childId: _childId,
      difficulty: widget.appState.state.grade,
    );
    _answered = false;
    _lastCorrect = null;
    if (resetCounter) _questionNum = 1;
  }

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty ? 'kind' : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  LumoTask _nextTask() {
    final st = widget.appState.state;
    return _factory.next(
      grade: st.grade,
      subject: st.subject,
      unit: st.unit == 'Alle' ? 'Alle' : st.unit,
      weakSkills: st.weakSkills,
      avoidUnits: {},
    );
  }

  void _answerAdaptive(AdaptiveTaskAnswer answer) {
    if (_answered) return;
    _completeAnswer(correct: answer.correct, hintUsed: false);
  }

  void _answerWriting(WritingTaskResult result) {
    if (_answered) return;
    final correctEnough = result.evaluation.overallScore >= .55;
    _completeAnswer(correct: correctEnough, hintUsed: result.evaluation.overallScore < .75);
  }

  void _completeAnswer({required bool correct, required bool hintUsed}) {
    setState(() {
      _answered = true;
      _lastCorrect = correct;
    });

    if (correct) {
      widget.appState.correctAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: true, hintUsed: hintUsed);
      LumoVoice.instance.speak('Super! Das war richtig!');
      Timer(const Duration(milliseconds: 1100), _nextQuestion);
    } else {
      widget.appState.wrongAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: false, hintUsed: hintUsed);
      LumoVoice.instance.speak('Fast. Wir schauen nochmal hin.');
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() {
      _questionNum = (_questionNum < _totalQuestions) ? _questionNum + 1 : 1;
      _loadNextTask(resetCounter: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.appState.state;
    final title = st.subject == 'Alle' ? 'Gemischte Übung' : st.subject;
    final chip = st.subject == 'Alle'
        ? 'Klasse ${st.grade} • adaptiv'
        : '${st.subject} • ${st.unit == 'Alle' ? 'alle Themen' : st.unit}';

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      return SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 14 : 26),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      title,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 34, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.05),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Arbeite wie im Heft. Ruhig lesen, dann erst antworten.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: LumoColors.ink500, height: 1.35),
                    ),
                  ]),
                ),
                Container(
                  decoration: BoxDecoration(color: LumoColors.orangeSurface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: LumoColors.orange.withOpacity(.20), blurRadius: 14, offset: const Offset(0, 6))]),
                  child: IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: LumoColors.orange, size: 26),
                    onPressed: () => LumoVoice.instance.speak('Aufgabe ${_task.prompt}'),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              _ProgressHeader(current: _questionNum, total: _totalQuestions, subject: chip),
              const SizedBox(height: 22),
              AdaptiveTaskRenderer(
                key: ValueKey(_taskInstance.taskInstanceId),
                task: _taskInstance,
                onAnswered: _answerAdaptive,
                onWritingSubmitted: _answerWriting,
              ),
              if (_answered && _lastCorrect != null) ...[
                const SizedBox(height: 22),
                _ExplanationCard(
                  correct: _lastCorrect!,
                  explanation: _task.explanation,
                  correctAnswer: '${_taskInstance.correctAnswer}',
                  onNext: _nextQuestion,
                ),
              ],
            ]),
          ),
        ),
      );
    });
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.current, required this.total, required this.subject});
  final int current;
  final int total;
  final String subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              'Aufgabe $current von $total',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 19, fontWeight: FontWeight.w900, color: LumoColors.ink900),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: LumoColors.orangeSurface, borderRadius: BorderRadius.circular(LumoRadius.pill), border: Border.all(color: LumoColors.orange.withOpacity(.2))),
              child: Text(
                subject,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.orange),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          child: LinearProgressIndicator(value: current / total, minHeight: 8, color: LumoColors.orange, backgroundColor: LumoColors.orange.withOpacity(.14)),
        ),
      ]),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.correct, required this.explanation, required this.correctAnswer, required this.onNext});
  final bool correct;
  final String explanation;
  final String correctAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(
        gradient: LinearGradient(
          colors: correct
              ? [const Color(0xFFDCFCE7), const Color(0xFFF0FFF4)]
              : [const Color(0xFFFFE4E6), const Color(0xFFFFF1F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(correct ? Icons.celebration_rounded : Icons.lightbulb_rounded, color: correct ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              correct ? 'Super gemacht!' : 'Nicht aufgeben!',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: correct ? const Color(0xFF14532D) : const Color(0xFF78350F)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(explanation, style: LumoTextStyles.body.copyWith(color: correct ? const Color(0xFF166534) : const Color(0xFF92400E))),
        if (!correct) ...[
          const SizedBox(height: 6),
          Text('Richtige Antwort: $correctAnswer', style: LumoTextStyles.body.copyWith(color: const Color(0xFF92400E), fontWeight: FontWeight.w900)),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]), borderRadius: BorderRadius.circular(LumoRadius.pill), boxShadow: LumoShadow.pill),
              child: const Text('Weiter →', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}
