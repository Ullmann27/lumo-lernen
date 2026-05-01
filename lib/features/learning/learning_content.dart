import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/lumo_voice.dart';
import '../../domain/learning/adaptive_learning_engine.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/learning/lumo_learning_feedback_engine.dart';
import '../../domain/learning/reward_engine.dart';
import 'adapters/legacy_lumo_task_adapter.dart';
import 'renderers/adaptive_task_renderer.dart';
import 'renderers/writing_task_renderer.dart';

class LearningContent extends StatefulWidget {
  const LearningContent({super.key, required this.appState});
  final LumoAppState appState;

  @override
  State<LearningContent> createState() => _LearningContentState();
}

class _LearningContentState extends State<LearningContent> {
  final _factory = ExerciseFactory();
  final _adapter = const LegacyLumoTaskAdapter();
  final _resultHandler = const SkillStateUpdater();
  final _rewardEngine = const RewardEngine();
  final _feedbackEngine = LumoLearningFeedbackEngine();
  final Map<String, SkillState> _skillStates = <String, SkillState>{};
  final List<String> _recentTaskKeys = <String>[];
  final List<String> _recentUnits = <String>[];
  final Set<String> _sessionTaskKeys = <String>{};
  String? _lastTaskKey;

  static const int _recentTaskMemory = 80;
  static const int _recentUnitMemory = 10;

  late LumoTask _task;
  late TaskInstance _taskInstance;
  DateTime _taskStartedAt = DateTime.now();
  bool _answered = false;
  bool? _lastCorrect;
  RewardDelta? _lastRewardDelta;
  SkillState? _lastSkillState;
  LumoFeedbackTurn? _lastFeedback;
  int _questionNum = 1;

  int get _totalQuestions {
    switch (widget.appState.state.sessionKind) {
      case LumoSessionKind.quickPractice: return 10;
      case LumoSessionKind.exerciseSet:   return 20;
      case LumoSessionKind.test:          return 10;
      case LumoSessionKind.schoolwork:    return 30;
      case LumoSessionKind.tutoring:      return 8;
    }
  }

  bool get _allowHelp =>
      widget.appState.state.sessionKind != LumoSessionKind.schoolwork;

  @override
  void initState() {
    super.initState();
    _loadNextTask(resetCounter: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LumoVoice.instance.speak(_welcomeForKind);
    });
  }

  String get _welcomeForKind {
    switch (widget.appState.state.sessionKind) {
      case LumoSessionKind.quickPractice:
        return 'Arbeite wie im Heft. Ruhig lesen, dann erst antworten.';
      case LumoSessionKind.exerciseSet:
        return 'Wir machen heute zwanzig Aufgaben. Ich merke mir, was dir gut gelingt.';
      case LumoSessionKind.test:
        return 'Testmodus. Lies ruhig und antworte selbst.';
      case LumoSessionKind.schoolwork:
        return 'Wie eine echte Schularbeit. Ich gebe heute keine Hilfe.';
      case LumoSessionKind.tutoring:
        return 'Nachhilfe. Ich schaue genau, welcher Schritt dir hilft.';
    }
  }

  void _loadNextTask({bool resetCounter = false}) {
    _task = _nextTask();
    _rememberTask(_task);
    _taskInstance = _adapter.toTaskInstance(
      task: _task,
      childId: _childId,
      difficulty: widget.appState.state.grade,
    );
    _taskStartedAt = DateTime.now();
    _answered = false;
    _lastCorrect = null;
    _lastRewardDelta = null;
    _lastSkillState = null;
    _lastFeedback = null;
    if (resetCounter) _questionNum = 1;
  }

  String get _childId {
    final st = widget.appState.state;
    final safeName = st.childName.trim().isEmpty ? 'kind' : st.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${st.grade}';
  }

  LumoTask _nextTask() {
    final st = widget.appState.state;
    final factorySubject = _factorySubjectFor(st.subject, st.unit);
    final factoryUnit = _factoryUnitFor(st.subject, st.unit);
    final avoidUnits = factoryUnit == 'Alle' ? _recentUnits.toSet() : <String>{};
    LumoTask? fallback;

    for (var attempt = 0; attempt < 80; attempt++) {
      final task = _factory.next(
        grade: st.grade,
        subject: factorySubject,
        unit: factoryUnit,
        weakSkills: st.weakSkills,
        avoidUnits: attempt < 40 ? avoidUnits : const <String>{},
      );

      if (_isPassiveReadingQuiz(task)) continue;

      fallback ??= task;
      final key = _taskKey(task);
      // Direkte Wiederholung verhindern: gleicher key wie zuletzt -> weiter ziehen
      if (_lastTaskKey != null && _lastTaskKey == key) continue;
      if (!_recentTaskKeys.contains(key) && !_sessionTaskKeys.contains(key)) return task;
    }

    return fallback ?? _factory.next(
      grade: st.grade,
      subject: factorySubject == 'Lesen' ? 'Deutsch' : factorySubject,
      unit: factoryUnit == 'Aktives Lesen' ? 'Satz verstehen' : factoryUnit,
      weakSkills: st.weakSkills,
      avoidUnits: const <String>{},
    );
  }

  String _factorySubjectFor(String subject, String unit) {
    final normalizedUnit = unit.trim().toLowerCase();
    if (normalizedUnit == 'schreiben üben' || normalizedUnit == 'schreiben ueben') {
      return 'Schreiben';
    }
    if (normalizedUnit == 'aktives lesen' || normalizedUnit == 'vorlesen') {
      return 'Lesen';
    }
    return subject == 'Alle Themen' ? 'Alle' : subject;
  }

  String _factoryUnitFor(String subject, String unit) {
    final normalized = unit.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'alle themen') return 'Alle';

    const aliases = <String, String>{
      'wörter lesen': 'Satz verstehen',
      'woerter lesen': 'Satz verstehen',
      'buchstaben finden': 'Anfangslaute',
      'reime erkennen': 'Reime',
      'satz bilden': 'Satz bauen',
      'schreiben üben': 'Buchstaben nachspuren',
      'schreiben ueben': 'Buchstaben nachspuren',
      'silben klatschen': 'Silben',
      'mengen zählen': 'Plus bis 10',
      'mengen zaehlen': 'Plus bis 10',
      'rechenhaus': 'Rechenhaeuser',
      'zahlenstrahl': 'Zahlenreihe',
      'zwanzigerfeld': 'Zehner und Einer',
    };
    return aliases[normalized] ?? unit;
  }

  bool _isPassiveReadingQuiz(LumoTask task) {
    return task.subject.trim().toLowerCase() == 'lesen' && !task.handwriting;
  }

  void _rememberTask(LumoTask task) {
    final key = _taskKey(task);
    _lastTaskKey = key;
    _sessionTaskKeys.add(key);
    _recentTaskKeys.remove(key);
    _recentTaskKeys.add(key);
    while (_recentTaskKeys.length > _recentTaskMemory) {
      _recentTaskKeys.removeAt(0);
    }

    _recentUnits.remove(task.unit);
    _recentUnits.add(task.unit);
    while (_recentUnits.length > _recentUnitMemory) {
      _recentUnits.removeAt(0);
    }
  }

  String _taskKey(LumoTask task) {
    final normalizedChoices = task.choices
        .map((choice) => choice.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .toList(growable: false)
      ..sort();
    return <String>[
      task.subject.trim().toLowerCase(),
      task.unit.trim().toLowerCase(),
      task.prompt.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
      task.answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
      task.visual,
      task.handwriting ? 'handwriting' : 'choice',
      task.difficulty.toString(),
      normalizedChoices.join(','),
    ].join('|');
  }

  void _answerAdaptive(AdaptiveTaskAnswer answer) {
    if (_answered) return;
    _completeAnswer(
      correct: answer.correct,
      hintUsed: !_allowHelp ? false : false,
      answerGiven: answer.answer,
    );
  }

  void _answerWriting(WritingTaskResult result) {
    if (_answered) return;
    final correctEnough = result.evaluation.overallScore >= .55;
    _completeAnswer(
      correct: correctEnough,
      hintUsed: _allowHelp && result.evaluation.overallScore < .75,
      answerGiven: 'writing:${result.evaluation.overallScore.toStringAsFixed(2)}',
      handwritingScore: result.evaluation.overallScore,
    );
  }

  void _completeAnswer({
    required bool correct,
    required bool hintUsed,
    required Object answerGiven,
    double? handwritingScore,
  }) {
    final before = _skillStates[_taskInstance.skillId.value] ??
        SkillState(
          childId: _childId,
          skillId: _taskInstance.skillId,
          currentDifficulty: widget.appState.state.grade,
          masteryScore: .20,
          repetitionNeed: .50,
        );

    final responseTimeMs = DateTime.now().difference(_taskStartedAt).inMilliseconds;
    final errorTypes = correct ? const <ErrorType>[] : _legacyErrorTypes(answerGiven);
    final result = TaskResult(
      taskInstanceId: _taskInstance.taskInstanceId,
      childId: _childId,
      skillId: _taskInstance.skillId,
      correct: correct,
      responseTimeMs: responseTimeMs,
      helpUsed: hintUsed,
      detectedErrorTypes: errorTypes,
      handwritingScore: handwritingScore,
      frustrationSignal: !correct && responseTimeMs > 18000,
    );
    final after = _resultHandler.applyResult(before: before, result: result);
    final rewardDelta = _rewardEngine.calculateTaskReward(
      result: result,
      before: before,
      after: after,
      mode: _learningModeForSession,
      completedSession: _questionNum >= _totalQuestions,
    );

    final feedback = _feedbackEngine.record(
      LumoInteractionEvent(
        subject: _task.subject,
        unit: _task.unit,
        prompt: _task.prompt,
        correctAnswer: _taskInstance.correctAnswer,
        givenAnswer: answerGiven,
        correct: correct,
        helpUsed: hintUsed,
        responseTimeMs: responseTimeMs,
        errorTypes: errorTypes,
        masteryBefore: before.masteryScore,
        masteryAfter: after.masteryScore,
        taskIndex: _questionNum,
        totalTasks: _totalQuestions,
        sessionKind: widget.appState.state.sessionKind.name,
        handwritingScore: handwritingScore,
      ),
    );

    _skillStates[_taskInstance.skillId.value] = after;

    setState(() {
      _answered = true;
      _lastCorrect = correct;
      _lastRewardDelta = rewardDelta;
      _lastSkillState = after;
      _lastFeedback = feedback;
    });

    if (correct) {
      widget.appState.correctAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: true, hintUsed: hintUsed);
      LumoVoice.instance.speak(feedback.spokenText);
      Timer(Duration(milliseconds: feedback.autoAdvanceDelayMs), _nextQuestion);
    } else {
      widget.appState.wrongAnswer(_task.unit);
      widget.appState.recordLearningAnswer(subject: _task.subject, unit: _task.unit, correct: false, hintUsed: hintUsed);
      LumoVoice.instance.speak(feedback.spokenText);
    }
  }

  LearningMode get _learningModeForSession {
    switch (widget.appState.state.sessionKind) {
      case LumoSessionKind.quickPractice:
      case LumoSessionKind.exerciseSet:
        return LearningMode.practice;
      case LumoSessionKind.test:
        return LearningMode.subjectTest;
      case LumoSessionKind.schoolwork:
        return LearningMode.exam;
      case LumoSessionKind.tutoring:
        return LearningMode.tutoring;
    }
  }

  List<ErrorType> _legacyErrorTypes(Object answerGiven) {
    if (_task.subject == 'Mathematik') {
      final given = int.tryParse('$answerGiven'.replaceAll(RegExp(r'[^0-9-]'), ''));
      final expected = int.tryParse('${_taskInstance.correctAnswer}'.replaceAll(RegExp(r'[^0-9-]'), ''));
      if (given != null && expected != null && (given - expected).abs() == 1) {
        return const <ErrorType>[ErrorType.countingError];
      }
      if (_task.prompt.contains('+') || _task.prompt.contains('-')) {
        return const <ErrorType>[ErrorType.plusMinusConfusion];
      }
      return const <ErrorType>[ErrorType.quantityError];
    }
    if (_task.unit.toLowerCase().contains('silben')) return const <ErrorType>[ErrorType.syllableCountWrong];
    if (_task.unit.toLowerCase().contains('laut') || _task.unit.toLowerCase().contains('st oder sp')) return const <ErrorType>[ErrorType.soundMisread];
    if (_task.unit.toLowerCase().contains('schreiben') || _task.unit.toLowerCase().contains('mehrzahl')) return const <ErrorType>[ErrorType.wordImageMismatch];
    return const <ErrorType>[ErrorType.conceptConfusion];
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() {
      final nextQuestion = _questionNum < _totalQuestions ? _questionNum + 1 : 1;
      if (nextQuestion == 1) _sessionTaskKeys.clear();
      _questionNum = nextQuestion;
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
                    Text(
                      _welcomeForKind,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: LumoColors.ink500, height: 1.35),
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
                  rewardDelta: _lastRewardDelta,
                  skillState: _lastSkillState,
                  feedback: _lastFeedback,
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
  const _ExplanationCard({
    required this.correct,
    required this.explanation,
    required this.correctAnswer,
    required this.onNext,
    this.rewardDelta,
    this.skillState,
    this.feedback,
  });

  final bool correct;
  final String explanation;
  final String correctAnswer;
  final VoidCallback onNext;
  final RewardDelta? rewardDelta;
  final SkillState? skillState;
  final LumoFeedbackTurn? feedback;

  @override
  Widget build(BuildContext context) {
    final reward = rewardDelta;
    final skill = skillState;
    final fb = feedback;
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
              fb?.title ?? (correct ? 'Super gemacht!' : 'Nicht aufgeben!'),
              style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: correct ? const Color(0xFF14532D) : const Color(0xFF78350F)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          fb?.cardMessage ?? explanation,
          style: LumoTextStyles.body.copyWith(color: correct ? const Color(0xFF166534) : const Color(0xFF92400E)),
        ),
        const SizedBox(height: 8),
        _LearningTipBox(text: fb?.learningTip ?? explanation, correct: correct),
        if (!correct) ...[
          const SizedBox(height: 8),
          Text('Richtige Antwort: $correctAnswer', style: LumoTextStyles.body.copyWith(color: const Color(0xFF92400E), fontWeight: FontWeight.w900)),
        ],
        if (reward != null) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _InfoPill(text: '+${reward.stars} Sterne'),
            _InfoPill(text: '+${reward.xp} XP'),
            if (fb != null) _InfoPill(text: fb.rewardLabel),
            if (fb?.badgeLabel != null) _InfoPill(text: fb!.badgeLabel!),
            if (skill != null) _InfoPill(text: 'Können ${(skill.masteryScore * 100).round()}%'),
          ]),
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

class _LearningTipBox extends StatelessWidget {
  const _LearningTipBox({required this.text, required this.correct});

  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: (correct ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withOpacity(.22)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.psychology_rounded, color: correct ? const Color(0xFF22C55E) : const Color(0xFFF59E0B), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: LumoColors.ink700, height: 1.28),
          ),
        ),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: LumoColors.orange.withOpacity(.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.ink700),
      ),
    );
  }
}
