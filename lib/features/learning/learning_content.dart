import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../app/app_design.dart';
import '../../core/ai_task_cache.dart';
import '../../core/ai_tutor_service.dart';
import '../../core/error_breakdown_repository.dart';
import '../../core/lumo_ai_proxy_client.dart';
import '../../core/lumo_tutor_contracts.dart';
import '../../core/lumo_tutor_engine.dart';
import '../../core/lumo_visual_aid_service.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/task_quality_guard.dart';
import '../../core/recent_task_repository.dart';
import '../../core/session_variety_guard.dart';
import '../../core/lumo_voice.dart';
import '../../domain/learning/adaptive_learning_engine.dart';
import '../../domain/learning/error_detective.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/learning/lumo_learning_feedback_engine.dart';
import '../../domain/learning/reward_engine.dart';
import '../shared/widgets/lumo_premium_effects.dart';
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
  Set<String> _lastTaskMarkers = <String>{};

  // Nachhilfelehrer: KI-generierte Aufgaben aus Cache, basierend auf Schwaechen
  static const AiTutorService _tutor = AiTutorService();
  static const AiTaskCache _aiCache = AiTaskCache();
  static const TaskQualityGuard _taskQualityGuard = TaskQualityGuard();
  static const RecentTaskRepository _recentRepo = RecentTaskRepository();
  static const LumoTutorEngine _localTutorEngine = LumoTutorEngine();
  // Visuelle Hilfe als 4. Eskalations-Stufe (nach 5+ Fehlversuchen).
  // Nutzt nur den lokalen Pfad (kein Cloud-Aufruf, keine Credit-Kosten),
  // weil das fuer Heinz' Toechter im taeglichen Lernen ausreicht.
  static const LumoVisualAidService _visualAidService = LumoVisualAidService();
  // Vermeidet sichtbare Wiederholungen ueber den exakten Aufgaben-Key
  // hinaus: gleiche Antwort, gleiches Prompt-Muster, gleiche Schluesselwoerter.
  // So sehen Heinz' Toechter nicht 5x in Folge "1+2", "2+1", "1+3" usw.
  final SessionVarietyGuard _varietyGuard = SessionVarietyGuard();
  final List<LumoAiTaskDraft> _aiDraftQueue = <LumoAiTaskDraft>[];

  static const int _recentTaskMemory = RecentTaskRepository.maxTaskKeys;
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
  // Bildhilfe-Karte als 4. Hilfsstufe nach 5+ Fehlversuchen.
  // Nur lokal generiert, kein Cloud-Aufruf.
  LumoVisualAid? _visualAid;

  // Konfetti-Trigger: jedes Hochzaehlen loest einen neuen Burst aus.
  // Wird bei richtigen Antworten erhoeht.
  int _confettiTrigger = 0;

  // Phase 2 - Lumo Fehlerdetektiv: zaehlt Fehlerarten in dieser Session.
  // Wird in den ErrorBreakdownRepository persistiert und vom DNA-Engine
  // in Phase 1 gelesen.
  final Map<String, int> _errorBreakdown = <String, int>{};
  final ErrorBreakdownRepository _errorRepo = const ErrorBreakdownRepository();

  // KI-Hilfe vom Cloud-Tutor (optional, nur wenn aiProxyEnabled).
  // Heinz' Wunsch: pro Bereich zugeschnittener KI-Helfer mit echtem Kontext.
  final LumoAiProxyClient _aiProxy = const LumoAiProxyClient();
  String? _aiHelpReply;
  bool _aiHelpLoading = false;

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
    _visualAid = null;
    _aiHelpReply = null;
    _aiHelpLoading = false;
    if (resetCounter) {
      _questionNum = 1;
      _attemptCount = 0;
    }
  }

  /// Holt KI-Hilfe vom Cloud-Tutor fuer die aktuelle Aufgabe.
  /// Heinz' Wunsch: pro Bereich zugeschnittener Helfer.
  /// Wenn aiProxyEnabled = false: lokaler Hinweis wird gezeigt.
  Future<void> _askAiTutor() async {
    if (_aiHelpLoading) return;
    if (!mounted) return;
    setState(() => _aiHelpLoading = true);
    try {
      // Bereich basierend auf Subject und Unit waehlen.
      final subject = _task.subject;
      final context = _aiContextForSubject(subject);
      // Konkrete Frage an Lumo: "Hilf mir bei dieser Aufgabe".
      final question = 'Aufgabe: "${_task.prompt}" '
          'Mein bisheriger Versuch: ${_attemptCount > 0 ? 'noch nicht richtig' : 'noch keiner'}. '
          'Bitte gib mir EINEN kleinen Tipp, ohne die Loesung zu verraten.';
      final response = await _aiProxy.ask(
        settings: widget.appState.state.settings,
        state: widget.appState.state,
        message: question,
        context: context,
        extras: <String, Object?>{
          'unit': _task.unit,
          'attempt': _attemptCount,
          'visual': _task.visual,
        },
      );
      if (!mounted) return;
      setState(() {
        _aiHelpReply = response.reply;
        _aiHelpLoading = false;
      });
      // Antwort gleich vorlesen, damit auch nicht-lesende Kinder es hoeren.
      if (widget.appState.state.settings.voiceEnabled) {
        unawaited(LumoVoice.instance.speak(response.reply, style: VoiceStyle.explain));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiHelpReply = 'Lumo konnte gerade keine Hilfe geben. Versuche es nochmal.';
        _aiHelpLoading = false;
      });
    }
  }

  LumoAiContext _aiContextForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematik':
      case 'mathe':
        return LumoAiContext.mathCoach;
      case 'deutsch':
      case 'rechtschreibung':
        return LumoAiContext.writingHelper;
      case 'lesen':
        return LumoAiContext.readingBuddy;
      case 'sachunterricht':
      case 'natur':
        return LumoAiContext.scienceExplorer;
      default:
        return LumoAiContext.learningTutor;
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
    LumoTask? relaxedFallback;
    if (aiSubject != null && _aiDraftQueue.isNotEmpty) {
      while (_aiDraftQueue.isNotEmpty) {
        final draft = _aiDraftQueue.removeAt(0);
        // Cache-Markierung im Hintergrund
        _aiCache.markConsumed(childId: _childId, subject: aiSubject, prompt: draft.prompt);
        final aiTask = _draftToLumoTask(draft, st.grade, factorySubject, factoryUnit);
        if (aiTask == null) continue;
        if (_canUseTask(aiTask, relaxed: false)) return aiTask;
        relaxedFallback ??= _canUseTask(aiTask, relaxed: true) ? aiTask : null;
      }
      // Wenn der KI-Vorrat nur Wiederholungen enthaelt, ziehen wir lieber
      // lokal weiter, statt dem Kind direkt wieder dieselbe Aufgabe zu zeigen.
    }

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

      if (!_wasRecentlySeen(task)) fallback ??= task;

      // Direkte und persistierte Wiederholungen verhindern: gleicher Task
      // oder gleiche Aufgaben-Familie -> weiter ziehen.
      if (_wasRecentlySeen(task)) continue;

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
    final markers = _taskMemoryKeys(task);
    _lastTaskMarkers = markers.toSet();
    _sessionTaskKeys.addAll(markers);
    for (final marker in markers) {
      _recentTaskKeys.remove(marker);
      _recentTaskKeys.add(marker);
    }
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

  bool _canUseTask(LumoTask task, {required bool relaxed}) {
    if (_wasRecentlySeen(task)) return false;
    return _varietyGuard.allows(task, relaxed: relaxed);
  }

  bool _wasRecentlySeen(LumoTask task) {
    final markers = _taskMemoryKeys(task);
    return markers.any((marker) =>
        _lastTaskMarkers.contains(marker) ||
        _sessionTaskKeys.contains(marker) ||
        _recentTaskKeys.contains(marker));
  }

  List<String> _taskMemoryKeys(LumoTask task) => _varietyGuard.taskMemoryKeys(task);

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
    // Heinz' Wunsch: Schreib-Pruefung war zu ungenau (>= 0.55 reichte).
    // Jetzt strenger:
    //  - overallScore muss >= 0.70 sein (vorher 0.55)
    //  - UND nicht incomplete (Coverage zu niedrig)
    //  - UND nicht spiegelverkehrt
    // So bekommen schlampige Striche nicht mehr "richtig" geantwortet.
    final ev = result.evaluation;
    final correctEnough = ev.overallScore >= 0.70 && !ev.incomplete && !ev.mirrored;
    _completeAnswer(
      correct: correctEnough,
      hintUsed: _allowHelp && ev.overallScore < .80,
      answerGiven: 'writing:${ev.overallScore.toStringAsFixed(2)}',
      handwritingScore: ev.overallScore,
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

  /// Laedt die lokale Bildhilfe asynchron und setzt sie via setState.
  /// Wird ausgeloest wenn das Kind nach 5+ Versuchen immer noch falsch
  /// liegt - dann zeigt Lumo eine bildliche Erklaerung mit Schritten.
  /// Kein Cloud-Aufruf, keine Credit-Kosten.
  Future<void> _loadVisualAid() async {
    try {
      final aid = await _visualAidService.buildAid(
        task: _task,
        grade: widget.appState.state.grade,
        attemptCount: _attemptCount,
        // settings sind nur fuer den Cloud-Pfad relevant. Wir uebergeben
        // bewusst die aktuellen Settings - shouldUsePaidImage prueft
        // intern ob der Cloud-Pfad freigegeben ist. Default: nein.
        settings: widget.appState.state.settings,
        childId: _childId,
        childName: _childFirstName,
        childRequestedImage: false,
      );
      if (!mounted) return;
      setState(() => _visualAid = aid);
    } catch (_) {
      // Bildhilfe ist optional. Wenn sie nicht laedt, gehts ohne weiter.
    }
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
      // Heinz' Wunsch: Konfetti bei Erfolgen. Wird ueber Trigger-Int
      // ausgeloest, damit der CustomPainter neu animiert.
      _confettiTrigger++;
      HapticFeedback.mediumImpact();
    } else if (_allowHelp) {
      _attemptCount++;
    }

    // Phase 2 - Lumo Fehlerdetektiv. Erkennt sofort beim 1. Fehler
    // die wahrscheinlichste Fehlerart und gibt kindgerechtes Feedback.
    // Faellt zurueck auf den bestehenden Tutor-Engine wenn Vertrauen niedrig.
    String? nextTutorHint;
    if (!correct) {
      final detection = const ErrorDetective().analyze(
        subject: _task.subject,
        prompt: _task.prompt,
        correctAnswer: '${_taskInstance.correctAnswer}',
        givenAnswer: '$answerGiven',
      );
      if (detection.confidence >= 0.65) {
        nextTutorHint = detection.childFriendlyMessage;
        // Fehlerart zaehlen + persistieren fuer die DNA-Anzeige in Phase 1.
        final key = detection.pattern.germanShortLabel;
        _errorBreakdown[key] = (_errorBreakdown[key] ?? 0) + 1;
        unawaited(_errorRepo.increment(_childId, key));
      } else {
        // Niedrige Konfidenz - generischer Tutor-Hint (nur ab 3 Versuchen).
        nextTutorHint = _buildTutorHint(answerGiven, errorTypes);
      }
    }
    // 4. Eskalations-Stufe: nach 5+ Fehlversuchen lokale Bildhilfe nachladen.
    // Asynchron, damit die UI sofort reagiert. Setzt _visualAid via setState
    // sobald fertig. Cloud-Aufruf ist explizit ausgeschlossen.
    if (!correct && _allowHelp && _attemptCount >= 5 && _visualAid == null) {
      unawaited(_loadVisualAid());
    }
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
      // Stack mit Confetti-Overlay: bei richtigen Antworten regnet es
      // physikalisch korrektes Konfetti (Newton-Schwerkraft + Luftwiderstand)
      // ueber den gesamten Inhalt.
      return Stack(
        children: [
          SingleChildScrollView(
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
              _LumoJourneyMap(
                currentStep: _questionNum,
                totalSteps: _totalQuestions,
                subject: chip,
                lastWasCorrect: _answered ? _lastCorrect : null,
              ),
              if (_tutorHint != null) ...[
                const SizedBox(height: 14),
                _TutorHintBanner(text: _tutorHint!),
              ],
              if (_visualAid != null) ...[
                const SizedBox(height: 14),
                _VisualAidCard(aid: _visualAid!),
              ],
              // KI-Hilfe-Button: nur sichtbar wenn aiProxyEnabled.
              // Heinz wollte KI in alle Bereiche integrieren - wenn aktiviert.
              if (widget.appState.state.settings.aiProxyEnabled && !_answered) ...[
                const SizedBox(height: 12),
                _AiHelpButton(
                  loading: _aiHelpLoading,
                  onTap: _askAiTutor,
                  subject: _task.subject,
                ),
              ],
              if (_aiHelpReply != null) ...[
                const SizedBox(height: 12),
                _AiHelpBubble(
                  text: _aiHelpReply!,
                  onSpeak: () => LumoVoice.instance.speak(_aiHelpReply!, style: VoiceStyle.explain),
                ),
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
      ),
          // Konfetti-Layer: feuert bei jeder richtigen Antwort.
          Positioned.fill(
            child: LumoConfettiBurst(trigger: _confettiTrigger),
          ),
        ],
      );
    });
  }
}

class _TutorHintBanner extends StatefulWidget {
  const _TutorHintBanner({required this.text});

  final String text;

  @override
  State<_TutorHintBanner> createState() => _TutorHintBannerState();
}

class _TutorHintBannerState extends State<_TutorHintBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutQuart,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, .12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LumoGradients.peachComfort,
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.32), width: 1.4),
            boxShadow: LumoShadow.help(const Color(0xFFFFB96B)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Akzent-Linie links als visueller Anker
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Lumo-Avatar mit doppeltem Glow
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFFFF7E6)],
                          radius: .9,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.30), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFB800).withOpacity(.30), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Text('🦊', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text(
                            'Lumo erklärt',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F), letterSpacing: .2),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(.18),
                              borderRadius: BorderRadius.circular(LumoRadius.pill),
                            ),
                            child: const Text(
                              'Tipp',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF92400E), letterSpacing: .6),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        Text(
                          widget.text,
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: LumoColors.ink700, height: 1.32),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Bildhilfe-Karte als 4. Hilfsstufe nach 5+ Fehlversuchen.
/// Zeigt Lumo's Erklaerung mit visuellen Schritten (Emoji-basiert),
/// damit Heinz' Toechter die Aufgabe wirklich verstehen koennen.
/// Kein Cloud-Image, alles lokal generiert.
class _VisualAidCard extends StatefulWidget {
  const _VisualAidCard({required this.aid});

  final LumoVisualAid aid;

  @override
  State<_VisualAidCard> createState() => _VisualAidCardState();
}

class _VisualAidCardState extends State<_VisualAidCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..forward();

  late final Animation<double> _headerFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, .4, curve: Curves.easeOutQuart),
  );

  late final Animation<double> _bodyFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.2, .7, curve: Curves.easeOutQuart),
  );

  Animation<double> _stepFade(int index) {
    final start = (.35 + index * .12).clamp(0.0, .92);
    final end = (start + .25).clamp(start + .05, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.aid.steps;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LumoGradients.visualCool,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(.32), width: 1.4),
        boxShadow: LumoShadow.help(const Color(0xFF6366F1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        child: Stack(children: [
          // Dekorativer Hintergrund-Glow oben rechts
          Positioned(
            top: -40,
            right: -40,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFA5B4FC).withOpacity(.45),
                      const Color(0xFFA5B4FC).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Akzent-Linie links
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // HEADER mit großem Avatar
              FadeTransition(
                opacity: _headerFade,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFEEF2FF)],
                        radius: .9,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(.40), width: 1.6),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withOpacity(.32), blurRadius: 14, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: const Text('🎨', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text(
                          'Lumo zeigt es dir',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4338CA), letterSpacing: .8),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(.20),
                            borderRadius: BorderRadius.circular(LumoRadius.pill),
                          ),
                          child: const Text(
                            'BILD-HILFE',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF312E81), letterSpacing: .8),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        widget.aid.title,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B), height: 1.15),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              // ERKLAERUNG
              FadeTransition(
                opacity: _bodyFade,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.62),
                    borderRadius: BorderRadius.circular(LumoRadius.md),
                    border: Border.all(color: Colors.white.withOpacity(.85), width: 1.0),
                  ),
                  child: Text(
                    widget.aid.explanation,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B), height: 1.4),
                  ),
                ),
              ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isLast = index == steps.length - 1;
                  return ScaleTransition(
                    scale: _stepFade(index),
                    alignment: Alignment.centerLeft,
                    child: FadeTransition(
                      opacity: _stepFade(index),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                        child: IntrinsicHeight(
                          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            // Step-Nummer + Verbindungslinie
                            Column(children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(.36), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    color: const Color(0xFF6366F1).withOpacity(.30),
                                  ),
                                ),
                            ]),
                            const SizedBox(width: 12),
                            // Step-Inhalt als kleine Karte
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.85),
                                  borderRadius: BorderRadius.circular(LumoRadius.md),
                                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(.18), width: 1.0),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(.08), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  // Visual gross und mittig, das ist der Kernpunkt
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        step.visual,
                                        style: const TextStyle(fontSize: 28, height: 1.2, letterSpacing: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step.caption,
                                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B), height: 1.3),
                                  ),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// 3D-Lernkarte mit Lumo-Fuchs der von Station zu Station huepft.
/// Inspiriert von Golf-Apps und Duolingo - Heinz' Toechter sehen
/// ihren Fortschritt visuell als Reise auf einem Pfad.
///
/// Pfad-Layout: 8-12 Stationen entlang einer geschwungenen Kurve mit
/// Perspektive (kleinere Stationen hinten, groesser vorne).
class _LumoJourneyMap extends StatefulWidget {
  const _LumoJourneyMap({
    required this.currentStep,
    required this.totalSteps,
    required this.subject,
    required this.lastWasCorrect,
  });

  final int currentStep;
  final int totalSteps;
  final String subject;
  /// null = noch nicht beantwortet
  /// true  = Lumo huepft mit Freude-Animation
  /// false = Lumo schwankt sanft (kein Drama)
  final bool? lastWasCorrect;

  @override
  State<_LumoJourneyMap> createState() => _LumoJourneyMapState();
}

class _LumoJourneyMapState extends State<_LumoJourneyMap> with TickerProviderStateMixin {
  late final AnimationController _hopController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _idleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant _LumoJourneyMap old) {
    super.didUpdateWidget(old);
    // Wenn Lumo zur naechsten Station kommt: Hop-Animation triggern
    if (old.currentStep != widget.currentStep) {
      _hopController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hopController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  /// Liefert die x/y-Koordinaten einer Station auf dem geschwungenen Pfad.
  /// 0..1 normalisiert. Geschwungene S-Kurve fuer Tiefe-Effekt.
  Offset _stationOffset(int step, int total, double width, double height) {
    final t = (step / (total - 1).clamp(1, double.infinity)).clamp(0.0, 1.0);
    // X laeuft von links unten nach rechts oben mit S-Schwung
    final x = 0.10 + 0.80 * t + 0.12 * (math.sin(t * math.pi * 2));
    // Y: oben (hinten) bei spaeten Stationen, unten (vorne) bei fruehen
    final y = 0.85 - 0.65 * t;
    return Offset(x * width, y * height);
  }

  /// Skalierung fuer 3D-Tiefe: vorne groesser, hinten kleiner.
  double _stationScale(int step, int total) {
    final t = (step / (total - 1).clamp(1, double.infinity)).clamp(0.0, 1.0);
    return 1.0 - 0.40 * t;
  }

  /// Symbol fuer eine Station - rotiert je nach Position fuer Abwechslung.
  String _stationEmoji(int step, int total) {
    if (step == total - 1) return '🏆'; // Ziel
    const symbols = ['🌟', '🎯', '🎨', '📚', '✏️', '🎵', '🌈', '🦋', '🍀', '⭐', '🎁'];
    return symbols[step % symbols.length];
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalSteps.clamp(2, 20);
    final progress = (widget.currentStep / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    return Container(
      width: double.infinity,
      decoration: lumoCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF0), Color(0xFFFFE5C7)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HEADER mit Fortschritt
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]),
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              boxShadow: [
                BoxShadow(color: LumoColors.orange.withOpacity(.32), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              'Station ${widget.currentStep}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: .3),
            ),
          ),
          const SizedBox(width: 8),
          Text('von $total', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: LumoColors.ink500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              border: Border.all(color: LumoColors.orange.withOpacity(.30), width: 1.2),
            ),
            child: Text(
              '$percent%',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: LumoColors.orange, letterSpacing: .2),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // SUBJECT-CHIP klein und subtil
        Text(
          widget.subject,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: LumoColors.ink500, letterSpacing: .3),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // 3D-PFAD mit Lumo
        AspectRatio(
          aspectRatio: 2.4,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return ClipRRect(
              borderRadius: BorderRadius.circular(LumoRadius.lg),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE0F2FE), // Himmel oben (hinten)
                      Color(0xFFFFF3E0), // Wiese unten (vorne)
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_hopController, _idleController]),
                  builder: (context, _) => CustomPaint(
                    painter: _JourneyPainter(
                      total: total,
                      currentStep: widget.currentStep,
                      hopProgress: _hopController.value,
                      idlePulse: _idleController.value,
                      stationOffset: _stationOffset,
                      stationScale: _stationScale,
                      stationEmoji: _stationEmoji,
                      lastWasCorrect: widget.lastWasCorrect,
                    ),
                    size: Size(w, h),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Progress-Balken als zusaetzliche Lese-Hilfe
        Stack(clipBehavior: Clip.none, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: progress),
              builder: (context, animatedProgress, _) => LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 6,
                color: LumoColors.orange,
                backgroundColor: LumoColors.orange.withOpacity(.14),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// CustomPainter fuer die 3D-Lernreise.
/// Zeichnet:
///   - Geschwungenen Pfad (gepunktet bis aktuelle Station, danach gestrichelt)
///   - Stationen als Kreise mit Schatten und Symbol
///   - Lumo-Fuchs an der aktuellen Position mit Hop-Bewegung
class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.total,
    required this.currentStep,
    required this.hopProgress,
    required this.idlePulse,
    required this.stationOffset,
    required this.stationScale,
    required this.stationEmoji,
    required this.lastWasCorrect,
  });

  final int total;
  final int currentStep;
  final double hopProgress;
  final double idlePulse;
  final Offset Function(int, int, double, double) stationOffset;
  final double Function(int, int) stationScale;
  final String Function(int, int) stationEmoji;
  final bool? lastWasCorrect;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // PFAD ZEICHNEN - geschwungene Linie zwischen allen Stationen
    final pathDone = Path();
    final pathTodo = Path();
    Offset? prev;
    for (var i = 0; i < total; i++) {
      final pos = stationOffset(i, total, w, h);
      if (i == 0) {
        pathDone.moveTo(pos.dx, pos.dy);
        pathTodo.moveTo(pos.dx, pos.dy);
      } else {
        // Bezier-Kurve fuer weichen Schwung
        final ctrl = Offset((prev!.dx + pos.dx) / 2, (prev.dy + pos.dy) / 2 + 8);
        if (i < currentStep) {
          pathDone.quadraticBezierTo(ctrl.dx, ctrl.dy, pos.dx, pos.dy);
        }
        if (i >= currentStep - 1) {
          pathTodo.quadraticBezierTo(ctrl.dx, ctrl.dy, pos.dx, pos.dy);
        }
      }
      prev = pos;
    }

    // Done-Pfad: dick und orange
    final donePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF7A2F), Color(0xFFFFB800)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(pathDone, donePaint);

    // Todo-Pfad: gestrichelt und blass
    final todoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF7A2F).withOpacity(.30);
    _drawDashedPath(canvas, pathTodo, todoPaint);

    // STATIONEN ZEICHNEN
    for (var i = 0; i < total; i++) {
      final pos = stationOffset(i, total, w, h);
      final scale = stationScale(i, total);
      final isPast = i < currentStep - 1;
      final isCurrent = i == currentStep - 1;
      final isFuture = i >= currentStep;
      final isFinal = i == total - 1;
      final r = (isFinal ? 22 : 16) * scale;

      // Schatten unter Station
      canvas.drawCircle(
        pos.translate(0, r * 0.8),
        r * 0.7,
        Paint()..color = Colors.black.withOpacity(.10),
      );

      // Station-Kreis
      Color fillColor;
      if (isPast) {
        fillColor = const Color(0xFF22C55E); // Mint - geschafft
      } else if (isCurrent) {
        fillColor = const Color(0xFFFF7A2F); // Orange - aktiv
      } else {
        fillColor = Colors.white;
      }
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = fillColor,
      );
      // Border
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = isPast
              ? const Color(0xFF15803D)
              : isCurrent
                  ? const Color(0xFFC2410C)
                  : const Color(0xFFFCD34D),
      );

      // Pulse fuer current
      if (isCurrent) {
        final pulse = 1.0 + idlePulse * 0.30;
        canvas.drawCircle(
          pos,
          r * pulse,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = const Color(0xFFFF7A2F).withOpacity(.40 * (1 - idlePulse)),
        );
      }

      // Symbol
      final symbol = isPast
          ? '✓'
          : isFinal && isFuture
              ? '🏆'
              : stationEmoji(i, total);
      final tp = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: r * 1.0,
            fontWeight: FontWeight.w900,
            color: isPast ? Colors.white : Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos.translate(-tp.width / 2, -tp.height / 2));
    }

    // LUMO-FUCHS an aktueller Position mit Hop-Animation
    final lumoStation = (currentStep - 1).clamp(0, total - 1);
    final lumoBase = stationOffset(lumoStation, total, w, h);
    // Hop: parabel-foermige Bewegung nach oben waehrend hopProgress 0 -> 1
    final hopHeight = lastWasCorrect == false
        ? 4.0 // bei falsch nur leichtes Schwanken
        : 18.0;
    final hopY = -4 * hopHeight * hopProgress * (1 - hopProgress);
    // Idle wackeln: leichte Bewegung wenn nicht gerade gehoppt wird
    final idleY = hopProgress > 0.95 || hopProgress < 0.05
        ? math.sin(idlePulse * math.pi * 2) * 1.5
        : 0.0;
    final lumoPos = lumoBase.translate(0, hopY + idleY - 22);
    // Lumo-Schatten
    canvas.drawCircle(
      lumoBase.translate(0, -2),
      11,
      Paint()..color = Colors.black.withOpacity(.18 - hopProgress * .12),
    );
    // Lumo selbst (Fuchs-Emoji)
    final lumoTp = TextPainter(
      text: const TextSpan(
        text: '🦊',
        style: TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lumoTp.paint(canvas, lumoPos.translate(-lumoTp.width / 2, -lumoTp.height / 2));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLen).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter old) =>
      old.currentStep != currentStep ||
      old.hopProgress != hopProgress ||
      old.idlePulse != idlePulse ||
      old.lastWasCorrect != lastWasCorrect;
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.current, required this.total, required this.subject});
  final int current;
  final int total;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final progress = (current / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Animierte Aufgaben-Nummer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]),
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              boxShadow: [
                BoxShadow(color: LumoColors.orange.withOpacity(.30), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              '$current',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'von $total',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: LumoColors.ink500),
          ),
          const Spacer(),
          // Subject-Chip mit dezentem Schatten
          Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: LumoColors.orangeSurface,
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              border: Border.all(color: LumoColors.orange.withOpacity(.24)),
              boxShadow: [
                BoxShadow(color: LumoColors.orange.withOpacity(.10), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              subject,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: LumoColors.orange, letterSpacing: .2),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Progress mit Prozent-Bubble der mitläuft
        Stack(clipBehavior: Clip.none, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: progress),
              builder: (context, animatedProgress, _) => LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 10,
                color: LumoColors.orange,
                backgroundColor: LumoColors.orange.withOpacity(.14),
              ),
            ),
          ),
          // Prozent-Bubble der über der Linie sitzt
          Positioned(
            top: -2,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                border: Border.all(color: LumoColors.orange.withOpacity(.32), width: 1.2),
                boxShadow: [
                  BoxShadow(color: LumoColors.orange.withOpacity(.18), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                '$percent%',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: LumoColors.orange, letterSpacing: .2),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ExplanationCard extends StatefulWidget {
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
  State<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<_ExplanationCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: .92, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutQuart,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.rewardDelta;
    final skill = widget.skillState;
    final fb = widget.feedback;
    final correct = widget.correct;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.topCenter,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LumoRadius.xl),
            gradient: correct ? LumoGradients.successFresh : LumoGradients.peachComfort,
            border: Border.all(
              color: (correct ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withOpacity(.32),
              width: 1.4,
            ),
            boxShadow: correct ? LumoShadow.success : LumoShadow.help(const Color(0xFFFB923C)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.xl),
            child: Stack(children: [
              // Dekorativer Glow oben rechts
              Positioned(
                top: -50,
                right: -40,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (correct ? const Color(0xFF34D399) : const Color(0xFFFB923C)).withOpacity(.32),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Konfetti-Sterne dezent bei Erfolg
              if (correct) ...const [
                Positioned(top: 14, right: 70, child: Text('✨', style: TextStyle(fontSize: 14))),
                Positioned(top: 38, right: 24, child: Text('⭐', style: TextStyle(fontSize: 16))),
                Positioned(top: 62, right: 56, child: Text('✨', style: TextStyle(fontSize: 12))),
              ],
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            (correct ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7)),
                          ],
                          radius: .9,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (correct ? const Color(0xFF34D399) : const Color(0xFFF59E0B)).withOpacity(.32),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        correct ? '🎉' : '💪',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fb?.title ?? (correct ? 'Super gemacht!' : 'Nicht aufgeben!'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: correct ? const Color(0xFF14532D) : const Color(0xFF78350F),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    fb?.cardMessage ?? widget.explanation,
                    style: LumoTextStyles.body.copyWith(
                      color: correct ? const Color(0xFF166534) : const Color(0xFF92400E),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LearningTipBox(text: fb?.learningTip ?? widget.explanation, correct: correct),
                  if (!correct) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.85),
                        borderRadius: BorderRadius.circular(LumoRadius.sm),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.30), width: 1.0),
                      ),
                      child: Row(children: [
                        const Text('✓', style: TextStyle(fontSize: 16, color: Color(0xFF15803D), fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Richtige Antwort: ${widget.correctAnswer}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  if (reward != null) ...[
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _InfoPill(text: '+${reward.stars} Sterne'),
                      _InfoPill(text: '+${reward.xp} XP'),
                      if (fb != null) _InfoPill(text: fb.rewardLabel),
                      if (fb?.badgeLabel != null) _InfoPill(text: fb!.badgeLabel!),
                      if (skill != null) _InfoPill(text: 'Können ${(skill.masteryScore * 100).round()}%'),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]),
                          borderRadius: BorderRadius.circular(LumoRadius.pill),
                          boxShadow: LumoShadow.pill,
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Weiter', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                          SizedBox(width: 6),
                          Text('→', style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
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

  /// Erkennt typische Reward-Texte und zeigt passendes Emoji vorne dran.
  /// Macht die kleinen Pillen sofort lesbar.
  String get _emoji {
    final lower = text.toLowerCase();
    if (lower.contains('stern')) return '⭐';
    if (lower.contains('xp')) return '⚡';
    if (lower.contains('können') || lower.contains('koennen')) return '📈';
    if (lower.contains('badge') || lower.contains('abzeichen')) return '🏅';
    if (lower.contains('streak')) return '🔥';
    if (lower.contains('level')) return '🎖️';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final em = _emoji;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(.95), Colors.white.withOpacity(.78)],
        ),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: LumoColors.orange.withOpacity(.22)),
        boxShadow: [
          BoxShadow(color: LumoColors.orange.withOpacity(.12), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (em.isNotEmpty) ...[
          Text(em, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: LumoColors.ink700,
            letterSpacing: .1,
          ),
        ),
      ]),
    );
  }
}

/// Premium KI-Hilfe-Button. Sichtbar nur wenn aiProxyEnabled.
/// Hat einen pulsierenden Glow + Sparkle-Icon.
class _AiHelpButton extends StatefulWidget {
  const _AiHelpButton({
    required this.loading,
    required this.onTap,
    required this.subject,
  });

  final bool loading;
  final VoidCallback onTap;
  final String subject;

  @override
  State<_AiHelpButton> createState() => _AiHelpButtonState();
}

class _AiHelpButtonState extends State<_AiHelpButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Pro Fach eigene Farbe.
    final color = switch (widget.subject.toLowerCase()) {
      'mathematik' || 'mathe' => const Color(0xFFFF7A2F),
      'deutsch' || 'rechtschreibung' => const Color(0xFF8B5CF6),
      'lesen' => const Color(0xFFF472B6),
      'sachunterricht' || 'natur' => const Color(0xFF10B981),
      _ => const Color(0xFF60A5FA),
    };
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.loading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.lg),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.42),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              else
                const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                widget.loading ? 'Lumo denkt nach…' : 'Lumo, hilf mir',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Antwort-Bubble fuer die KI-Hilfe.
/// Lila Gradient + Sparkles + Vorlese-Button.
class _AiHelpBubble extends StatelessWidget {
  const _AiHelpBubble({required this.text, required this.onSpeak});
  final String text;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5EFFF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text('🦊', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lumo sagt:',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6D28D9),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up_rounded, size: 22, color: Color(0xFF7C3AED)),
                tooltip: 'Lumo vorlesen lassen',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
