import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/ai_task_cache.dart';
import '../../core/ai_tutor_service.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_tutor_contracts.dart';
import '../../core/lumo_tutor_engine.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/task_quality_guard.dart';
import '../../core/recent_task_repository.dart';
import '../../core/session_variety_guard.dart';
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

  // Nachhilfelehrer: KI-generierte Aufgaben aus Cache, basierend auf Schwaechen
  static const AiTutorService _tutor = AiTutorService();
  static const AiTaskCache _aiCache = AiTaskCache();
  static const TaskQualityGuard _taskQualityGuard = TaskQualityGuard();
  static const RecentTaskRepository _recentRepo = RecentTaskRepository();
  static const LumoTutorEngine _localTutorEngine = LumoTutorEngine();
  // Vermeidet sichtbare Wiederholungen ueber den exakten Aufgaben-Key
  // hinaus: gleiche Antwort, gleiches Prompt-Muster, gleiche Schluesselwoerter.
  // So sehen Heinz' Toechter nicht 5x in Folge "1+2", "2+1", "1+3" usw.
  final SessionVarietyGuard _varietyGuard = SessionVarietyGuard();
  final List<LumoAiTaskDraft> _aiDraftQueue = <LumoAiTaskDraft>[];

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
  int _attemptCount = 0;
  String? _tutorHint;

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
    // Persistente Wiederholungsvermeidung nachladen, ohne den ersten Frame zu blockieren.
    _hydrateRecent();
    // Nachhilfelehrer-Hook (fire and forget):
    //   1. KI-Aufgaben aus Cache laden (kostenlos, lokal)
    //   2. Wenn Cache niedrig und KI freigegeben: vom Server nachfuellen
    _hydrateAiQueueAndMaybeRefill();
  }

  Future<void> _hydrateRecent() async {
    final st = widget.appState.state;
    final childId = _childId;
    final subject = st.subject;
    final keys = await _recentRepo.loadTaskKeys(childId: childId, subject: subject);
    final units = await _recentRepo.loadUnits(childId: childId, subject: subject);
    if (!mounted) return;
    setState(() {
      final currentKeys = List<String>.from(_recentTaskKeys);
      final currentUnits = List<String>.from(_recentUnits);

      _recentTaskKeys
        ..clear()
        ..addAll(keys);
      for (final key in currentKeys) {
        _recentTaskKeys.remove(key);
        _recentTaskKeys.add(key);
      }
      while (_recentTaskKeys.length > _recentTaskMemory) {
        _recentTaskKeys.removeAt(0);
      }

      _recentUnits
        ..clear()
        ..addAll(units);
      for (final unit in currentUnits) {
        _recentUnits.remove(unit);
        _recentUnits.add(unit);
      }
      while (_recentUnits.length > _recentUnitMemory) {
        _recentUnits.removeAt(0);
      }
    });
  }

  Future<void> _hydrateAiQueueAndMaybeRefill() async {
    final st = widget.appState.state;
    final subject = _aiSubjectName(st.subject);
    if (subject == null) return;
    final fresh = await _aiCache.loadFresh(childId: _childId, subject: subject);
    if (mounted) {
      setState(() {
        _aiDraftQueue
          ..clear()
          ..addAll(fresh);
      });
    }
    // Refill bei Bedarf - laeuft asynchron, kein Block
    final result = await _tutor.refillIfNeeded(
      settings: st.settings,
      profile: widget.appState.learningProfile,
      childId: _childId,
      childName: st.childName,
      grade: st.grade,
      subject: subject,
    );
    if (!mounted) return;
    if (!result.skipped && result.generated > 0) {
      // Neue Drafts in die Queue uebernehmen
      final updated = await _aiCache.loadFresh(childId: _childId, subject: subject);
      if (!mounted) return;
      setState(() {
        _aiDraftQueue
          ..clear()
          ..addAll(updated);
      });
    }
  }

  /// Mappt App-Subject-Bezeichnungen auf Cache/Server-Schluessel.
  /// Null bedeutet: kein KI-Vorrat fuer dieses Subject.
  String? _aiSubjectName(String stateSubject) {
    final s = stateSubject.trim();
    if (s == 'Mathematik' || s == 'Mathe') return 'Mathematik';
    if (s == 'Deutsch') return 'Deutsch';
    return null; // Lesen/Schreiben/Mixed -> Standard-Generator
  }

  LumoTutorSubject _tutorSubjectFor(String subject) {
    final normalized = subject.trim().toLowerCase();
    if (normalized.contains('mathe')) return LumoTutorSubject.mathematik;
    if (normalized.contains('deutsch') || normalized.contains('rechtschreibung') || normalized.contains('schreiben')) {
      return LumoTutorSubject.deutsch;
    }
    if (normalized.contains('lesen')) return LumoTutorSubject.lesen;
    if (normalized.contains('englisch')) return LumoTutorSubject.englisch;
    return LumoTutorSubject.sachunterricht;
  }

  String get _childFirstName {
    final name = widget.appState.state.childName.trim();
    if (name.isEmpty) return 'Kind';
    return name.split(RegExp(r'\s+')).first;
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
    _tutorHint = null;
    if (resetCounter) {
      _questionNum = 1;
      _attemptCount = 0;
    }
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

    // Nachhilfelehrer-Bypass: wenn KI-Vorrat vorhanden ist und das
    // Subject Mathe oder Deutsch ist, bevorzuge eine KI-Aufgabe.
    // Kein Crash bei Validierungs-Problemen - dann faellt es einfach
    // auf den Standard-Generator zurueck.
    final aiSubject = _aiSubjectName(st.subject);
    if (aiSubject != null && _aiDraftQueue.isNotEmpty) {
      final draft = _aiDraftQueue.removeAt(0);
      // Cache-Markierung im Hintergrund
      _aiCache.markConsumed(childId: _childId, subject: aiSubject, prompt: draft.prompt);
      final aiTask = _draftToLumoTask(draft, st.grade, factorySubject, factoryUnit);
      if (aiTask != null) {
        return aiTask;
      }
      // sonst weiter mit Standard-Generator
    }

    final avoidUnits = factoryUnit == 'Alle' ? _recentUnits.toSet() : <String>{};
    LumoTask? fallback;
    LumoTask? relaxedFallback;

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
      if (_recentTaskKeys.contains(key) || _sessionTaskKeys.contains(key)) continue;

      // SessionVarietyGuard: prueft auch Antwort-/Muster-/Wort-Wiederholung,
      // nicht nur den exakten Aufgaben-Key. Bei strikter Pruefung erst.
      if (_varietyGuard.allows(task, relaxed: false)) {
        return task;
      }
      // Falls strikt nicht passt, merken wir uns den ersten Treffer der
      // wenigstens beim relaxed-Check durchkommt.
      relaxedFallback ??= _varietyGuard.allows(task, relaxed: true) ? task : null;
    }

    // Fallback-Reihenfolge:
    //   1. relaxed-Variante (anderes Muster, evtl. gleiches Wort)
    //   2. allgemeiner Fallback aus dem ersten Versuch
    //   3. komplett neuer Generator-Aufruf ohne Vermeidungs-Set
    return relaxedFallback ?? fallback ?? _factory.next(
      grade: st.grade,
      subject: factorySubject == 'Lesen' ? 'Deutsch' : factorySubject,
      unit: factoryUnit == 'Aktives Lesen' ? 'Satz verstehen' : factoryUnit,
      weakSkills: st.weakSkills,
      avoidUnits: const <String>{},
    );
  }

  /// Wandelt einen vom Server gelieferten Draft in einen LumoTask um.
  /// Liefert null wenn die Pflichtfelder nicht passen oder der TaskQualityGuard
  /// die Aufgabe als fachlich/strukturell unsicher bewertet.
  LumoTask? _draftToLumoTask(LumoAiTaskDraft draft, int grade, String subject, String unit) {
    if (draft.prompt.trim().isEmpty || draft.answer.trim().isEmpty) return null;
    if (draft.choices.length < 2) return null;
    if (!draft.choices.any((c) => c.trim().toLowerCase() == draft.answer.trim().toLowerCase())) {
      return null;
    }
    final probe = LumoTask(
      id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
      grade: grade,
      subject: subject == 'Alle' ? 'Mathematik' : subject,
      unit: unit == 'Alle' ? 'KI Nachhilfe' : unit,
      prompt: draft.prompt,
      answer: draft.answer,
      choices: draft.choices,
      explanation: draft.explanation.isEmpty ? 'Lumo erklärt dir das gleich Schritt für Schritt.' : draft.explanation,
      visual: draft.visual,
      difficulty: grade,
      missionTag: 'ai_cache',
    );
    if (!_taskQualityGuard.validate(probe)) return null;
    return probe;
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

    // Variety-Guard merkt sich die Aufgabe ueber den exakten Key hinaus
    // (Antwort, Prompt-Muster, Schluesselwoerter).
    _varietyGuard.remember(task);

    _recentUnits.remove(task.unit);
    _recentUnits.add(task.unit);
    while (_recentUnits.length > _recentUnitMemory) {
      _recentUnits.removeAt(0);
    }

    _recentRepo.saveTaskKeys(
      childId: _childId,
      subject: widget.appState.state.subject,
      keys: List<String>.from(_recentTaskKeys),
    ).ignore();
    _recentRepo.saveUnits(
      childId: _childId,
      subject: widget.appState.state.subject,
      units: List<String>.from(_recentUnits),
    ).ignore();
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

  String? _buildTutorHint(Object answerGiven, List<ErrorType> errorTypes) {
    if (!_allowHelp || _attemptCount < 3) return null;
    final helpLevel = _localTutorEngine.decideHelpLevel(
      attemptCount: _attemptCount,
      hasRepeatedWeakness: false,
      premiumEnabled: true,
    );
    final mode = _localTutorEngine.decideMode(
      attemptCount: _attemptCount,
      hasRepeatedWeakness: false,
      isTestReview: widget.appState.state.sessionKind == LumoSessionKind.test,
    );
    final request = LumoTutorRequest(
      mode: mode,
      subject: _tutorSubjectFor(_task.subject),
      grade: widget.appState.state.grade,
      unit: _task.unit,
      helpLevel: helpLevel,
      childFirstName: _childFirstName,
      currentPrompt: _task.prompt,
      childAnswer: '$answerGiven',
      correctAnswer: '${_taskInstance.correctAnswer}',
      attemptCount: _attemptCount,
      weaknessTags: errorTypes.map((type) => type.name).toList(growable: false),
    );
    final response = _localTutorEngine.buildLocalFallback(request);
    return response.shortHint ?? response.explanation ?? response.speech;
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
    if (correct) {
      _attemptCount = 0;
    } else if (_allowHelp) {
      _attemptCount++;
    }
    final nextTutorHint = correct ? null : _buildTutorHint(answerGiven, errorTypes);
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
      _tutorHint = nextTutorHint;
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
      if (nextQuestion == 1) {
        _sessionTaskKeys.clear();
        _attemptCount = 0;
      }
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
              if (_tutorHint != null) ...[
                const SizedBox(height: 14),
                _TutorHintBanner(text: _tutorHint!),
              ],
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.05, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: AdaptiveTaskRenderer(
                  key: ValueKey(_taskInstance.taskInstanceId),
                  task: _taskInstance,
                  onAnswered: _answerAdaptive,
                  onWritingSubmitted: _answerWriting,
                ),
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

class _TutorHintBanner extends StatelessWidget {
  const _TutorHintBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.30)),
        boxShadow: LumoShadow.card,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.22)),
          ),
          child: const Text('🦊', style: TextStyle(fontSize: 19)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Lumo erklärt',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: LumoColors.ink700, height: 1.28),
            ),
          ]),
        ),
      ]),
    );
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
