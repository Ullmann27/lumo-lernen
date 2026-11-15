import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../app/lumo_companion_host.dart';
import '../../../core/learning_attempt_id.dart';
import '../../../core/learning_journey.dart';
import '../../../core/lumo_learning_narration.dart';
import '../../../core/lumo_learning_session_contract.dart';
import '../../../core/lumo_voice.dart';
import '../../../core/progress_repository.dart';
import '../../../domain/tutoring/native_learning_activity.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';
import '../../learning_modules/learning_module_progress.dart';
import '../../lumo3d/lumo3d_launcher.dart';
import '../nextgen/learning_lab_resume.dart';
import '../nextgen/learning_coach_binding.dart';
import 'learning_lab_catalog.dart';
import 'learning_manipulatives.dart';

enum _Phase { example, build, recall, transfer, reflection }

/// A checked, local lesson. Model actions remain observations; only explicit
/// answer confirmation reaches the existing profile-bound progress writer.
class LearningLabScreen extends StatefulWidget {
  const LearningLabScreen({
    super.key,
    required this.appState,
    required this.topic,
    this.seed = 0,
  });

  final LumoAppState appState;
  final LabTopic topic;
  final int seed;

  @override
  State<LearningLabScreen> createState() => _LearningLabScreenState();
}

class _LearningLabScreenState extends State<LearningLabScreen>
    with WidgetsBindingObserver {
  late final LearningModuleProgress _progress = LearningModuleProgress(
    appState: widget.appState,
    subject: widget.topic.subject,
    unit: widget.topic.unit,
  );
  final _narration = LumoLearningNarration();
  final _fox = LumoCharacterController();
  final _answer = TextEditingController();
  late final LearningCoachBinding _coach;
  LearningProfileLease? _lease;
  LearningLabResumeRepository? _resume;
  LumoCompanionTaskContext? _published;
  _Phase _phase = _Phase.example;
  bool _loading = true;
  bool _invalid = false;
  bool _busy = false;
  bool _done = false;
  bool _wrongBefore = false;
  bool _foreground = true;
  bool _selfTry = false;
  bool _interruptedSave = false;
  bool _resumeUnavailable = false;
  bool _slow = false;
  bool _speechCandidate = false;
  bool _nativeLearningOpen = false;
  bool _nativeReturnPending = false;
  String? _nativeStepId;
  int _hint = 0;
  int _support = 0;
  int _moved = 0;
  int _attempt = 0;
  int _revision = 0;
  int _voiceSerial = 0;
  int? _patternChoice;
  int? _pendingSyllable;
  int? _activeSyllable;
  Set<int> _pieces = <int>{};
  List<int> _tokens = <int>[];
  List<String>? _lastSegments;
  String _feedback = '';
  String? _focusObjectId;
  String? _lastText;
  String? _pendingAttemptId;
  String? _lastSavedAttemptId;
  String? _resumeNotice;
  String? _resumeError;
  String _sessionId = 'lab-${newLearningAttemptId()}';

  bool get _reduced =>
      widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode ||
      MediaQuery.disableAnimationsOf(context);
  bool get _safe =>
      mounted &&
      !_invalid &&
      _lease != null &&
      widget.appState.isCurrentLearningLease(_lease!) &&
      widget.appState.state.grade >= widget.topic.minimumGrade;
  bool get _canAnswer =>
      _safe && !_busy && !_done && !_progress.hasPending && !_interruptedSave;
  bool get _editable => _canAnswer && _foreground && !_nativeLearningOpen;
  bool get _active =>
      _safe &&
      !_loading &&
      (_foreground || _nativeLearningOpen) &&
      _routeVisible;
  bool get _routeVisible =>
      mounted && ModalRoute.of(context)?.isCurrent != false;
  bool get _modelPhase => _phase == _Phase.example || _phase == _Phase.build;
  int get _effectiveSupport => _modelPhase ? math.max(3, _support) : _support;
  LabProblem _problem(int index) => widget
      .topic.problems[(widget.seed + index) % widget.topic.problems.length];
  // The demonstrated task stays the same when the child takes over its model.
  // Only recall and transfer use different checked problems.
  LabProblem get _current => _problem(switch (_phase) {
        _Phase.example || _Phase.build => 0,
        _Phase.recall => 2,
        _Phase.transfer || _Phase.reflection => 3,
      });
  List<String> get _syllables => [
        for (final index in _current.tokenOrder) _current.tokens[index],
      ];

  static const _body = TextStyle(
    color: LumoVisualTokens.white,
    fontFamily: 'Nunito',
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );

  @override
  void initState() {
    super.initState();
    _coach = LearningCoachBinding(
      isActive: () => _active,
      onHint: _help,
      onExplain: () => _help(differently: true),
      onRepeat: _repeat,
      onSlower: _slower,
      onStop: _stop,
      onCancel: _stopSpeech,
      onTryMyself: _tryMyself,
      onProposeAnswer: _proposeAnswer,
      onFocus: (id, action) {
        _focusObjectId = id;
        _coach.present(
            objectId: id,
            point: action == LumoLearningAction.point,
            state: 'focused_input');
      },
    );
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.appState.addListener(_checkProfile);
    _progress.addListener(_repaint);
    _narration.addListener(_repaint);
    LumoVoice.instance.status.addListener(_voiceChanged);
    LumoCompanionRequests.instance.helpRequested.addListener(_requestHelp);
    _answer.addListener(_answerChanged);
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route visibility and viewport changes must keep the same model while
    // withdrawing the command binding when another route covers this lesson.
    ModalRoute.isCurrentOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  Future<void> _load() async {
    try {
      final lease = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(lease);
      await lease.profile.loadJourney();
      if (!mounted || !widget.appState.isCurrentLearningLease(lease)) return;
      _lease = lease;
      _resume = LearningLabResumeRepository(
        studentId: lease.studentId,
        mayWrite: () => widget.appState.canUseLearningLease(lease),
      );
      try {
        final saved = await _resume!.load(widget.topic, widget.seed);
        if (!mounted || !widget.appState.isCurrentLearningLease(lease)) return;
        if (saved != null && saved.phase != 'reflection') _restore(saved);
      } on FormatException {
        // Preserve unknown/damaged bytes. Regular assessed answers still use
        // the existing writer; this view does not overwrite its old checkpoint.
        _resumeUnavailable = true;
        _resumeNotice =
            'Die vorige Ansicht konnte nicht sicher geöffnet werden. '
            'Deine gespeicherten Antworten bleiben erhalten.';
      }
      if (!mounted) return;
      setState(() => _loading = false);
      _publish();
    } catch (_) {
      if (mounted) {
        setState(() {
          _invalid = true;
          _loading = false;
        });
      }
    }
  }

  void _restore(LearningLabCheckpoint saved) {
    _sessionId = saved.sessionId;
    _phase = _Phase.values.byName(saved.phase);
    _moved = saved.moved;
    _pieces = saved.pieces.toSet();
    _tokens = List<int>.of(saved.tokens);
    _patternChoice = saved.patternChoice;
    _hint = saved.hint;
    _support = saved.support;
    _wrongBefore = saved.wrongBefore;
    _attempt = saved.attempt;
    _answer.text = saved.answer;
    _lastSavedAttemptId = saved.lastSavedAttemptId;
    _pendingAttemptId = saved.pendingAttemptId;
    final record = _lease!.profile.journey
        .records[SkillRecord.makeId(widget.topic.subject, widget.topic.unit)];
    final accepted = record?.recentTaskIds ?? const <String>[];
    _done = saved.done && accepted.contains(saved.lastSavedAttemptId);
    if (saved.pendingAttemptId != null) {
      if (accepted.contains(saved.pendingAttemptId)) {
        _done = _phase == _Phase.build
            ? _modelValid()
            : _current.accepts(saved.answer);
        _wrongBefore = !_done;
        _lastSavedAttemptId = saved.pendingAttemptId;
        _pendingAttemptId = null;
      } else {
        // The existing writer is not a cross-process transaction. Do not
        // automatically resubmit a possibly saved school answer after a crash.
        _interruptedSave = true;
      }
    }
    _resumeNotice = _interruptedSave
        ? 'Die letzte Speicherung wurde unterbrochen. Diese Antwort wird '
            'nicht nochmals gewertet. Du kannst mit dem nächsten Schritt '
            'weiterarbeiten; bestätigte Lernstände bleiben erhalten.'
        : 'Hier machen wir weiter. Deine gelegten Teile und Hilfen sind erhalten.';
    if (_done) {
      _feedback = 'Dieser Lernschritt ist bereits gespeichert.';
    } else if (_hint > 0) {
      _feedback = _current.hints[_hint - 1];
    }
  }

  LearningLabCheckpoint _checkpointValue() => LearningLabCheckpoint(
        topicId: widget.topic.id,
        seed: widget.seed,
        sessionId: _sessionId,
        phase: _phase.name,
        problemId: _current.id,
        moved: _moved,
        pieces: _pieces.toList()..sort(),
        tokens: List<int>.of(_tokens),
        patternChoice: _patternChoice,
        hint: _hint,
        support: math.max(_support, _hint),
        wrongBefore: _wrongBefore,
        attempt: _attempt,
        answer: _answer.text,
        done: _done,
        pendingAttemptId: _pendingAttemptId,
        lastSavedAttemptId: _lastSavedAttemptId,
      );

  Future<bool> _checkpoint() async {
    final resume = _resume;
    if (resume == null || _resumeUnavailable || !_safe) return true;
    final value = _checkpointValue();
    try {
      final saved = await resume.save(value, widget.topic);
      if (mounted && _safe && saved && _resumeError != null) {
        setState(() => _resumeError = null);
      }
      return saved;
    } catch (_) {
      if (mounted && _safe) {
        setState(() => _resumeError =
            'Die aktuelle Ansicht wartet noch aufs Speichern. Bitte wiederholen.');
      }
      return false;
    }
  }

  void _answerChanged() {
    if (_safe && !_loading && !_busy && !_done && !_interruptedSave) {
      unawaited(_checkpoint());
    }
  }

  void _checkProfile() {
    if (!mounted || _lease == null || _invalid) return;
    if (!widget.appState.isCurrentLearningLease(_lease!) ||
        widget.appState.state.grade < widget.topic.minimumGrade) {
      setState(() => _invalid = true);
      _coach.interrupt('profile_changed');
      unawaited(_stopSpeech());
      LumoCompanionRequests.instance.clearTask(_published);
    } else {
      if (!widget.appState.state.settings.voiceEnabled) {
        unawaited(_stopSpeech());
      }
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      unawaited(_checkpoint());
      unawaited(_stopSpeech());
      if (!_nativeLearningOpen) {
        _coach.interrupt('background');
        setState(_discardSpeechCandidate);
        _focusObjectId = null;
      }
    } else if (_nativeReturnPending) {
      setState(_finishNativeReturn);
    }
    _publish();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  String get _visibleExplanation {
    final p = _current;
    if (p.mode == LabMode.bridge && (_modelPhase || _hint >= 3)) {
      final occupied = p.start + _moved;
      final free = 10 - occupied;
      final remaining = p.addend - _moved;
      if (free > 0) {
        return 'Im Zehnerfeld liegen $occupied Plättchen. '
            'Es ${free == 1 ? "ist noch ein Platz frei" : "sind noch $free Plätze frei"}. '
            '${_moved == 0 ? "Darum brauchen wir zuerst ${p.modelTarget} aus dem Vorrat." : "Lege nur die fehlenden Plättchen dazu."} '
            'Jetzt bist du dran.';
      }
      return 'Du hast ${p.modelTarget} Plättchen hinübergelegt. '
          'Im Feld sind genau 10. Daneben bleiben $remaining. '
          '10 + $remaining = ${p.start + p.addend}.';
    }
    if (_feedback.isNotEmpty && !_selfTry) return _feedback;
    if (_modelPhase) return p.guidedPrompt;
    return p.hints[_hint.clamp(0, p.hints.length - 1)];
  }

  String get _currentStep => switch (_current.mode) {
        LabMode.bridge => _moved == _current.modelTarget
            ? (_current.start == 8 && _current.addend == 5
                ? 'remainder_three'
                : 'remainder_${_current.addend - _moved}')
            : (_current.start == 8 && _current.addend == 5
                ? 'bridge_two'
                : 'bridge_${_current.modelTarget - _moved}'),
        LabMode.word => 'syllables_${_tokens.length}',
        LabMode.pattern =>
          _patternChoice == null ? 'pattern_group' : 'pattern_next',
        LabMode.fraction => 'fraction_${_pieces.length}',
        _ => 'tokens_${_tokens.length}',
      };

  List<String> get _objectIds {
    final p = _current;
    final visible =
        _modelPhase || (p.mode == LabMode.pattern) || (_hint >= 3 && !_selfTry);
    return [
      'task_prompt',
      if (_nativeLearningOpen) ...[
        'task_model',
        if (p.mode == LabMode.pattern)
          for (var i = 0; i < p.tokens.length; i++) 'answer_$i',
      ],
      if (!_modelPhase && p.mode != LabMode.pattern) 'answer_field',
      if (visible)
        ...switch (p.mode) {
          LabMode.bridge => <String>[
              'ten_frame',
              'addend',
              for (var i = 0; i < 10; i++) 'ten-slot-$i',
              for (var i = _moved; i < p.addend; i++) 'quantity-bank-$i',
              for (var i = 0; i < _moved; i++) 'quantity-placed-$i',
            ],
          LabMode.word => <String>[
              'syllable-word',
              for (var i = 0; i < _syllables.length; i++) 'syllable_$i',
            ],
          LabMode.pattern => <String>[
              'pattern_group',
              'pattern_next',
              for (var i = 0; i < p.pattern.length; i++) 'pattern-item-$i',
              for (var i = 0; i < p.tokens.length; i++) 'pattern-option-$i',
            ],
          LabMode.fraction => <String>[
              'fraction-disc',
              for (var i = 0; i < p.denominator; i++) 'fraction-piece-$i',
            ],
          _ => <String>[
              for (var i = 0; i < p.tokens.length; i++)
                'token-${_tokens.contains(i) ? "work" : "bank"}-$i',
            ],
        },
    ];
  }

  void _proposeAnswer(String candidate) {
    if (!_active || !_canAnswer || _modelPhase || candidate.length > 80) return;
    setState(() {
      _speechCandidate = true;
      _answer.text = candidate;
      if (_current.mode == LabMode.pattern && !_nativeLearningOpen) {
        final index = _current.tokens.indexWhere(
            (value) => value.toLowerCase() == candidate.trim().toLowerCase());
        _patternChoice = index < 0 ? null : index;
      }
      _feedback = 'Ich habe „$candidate“ verstanden. Prüfe den Vorschlag. '
          'Erst mit „Antwort prüfen“ wird deine Antwort gewertet.';
    });
    _publish();
    unawaited(_checkpoint());
  }

  void _publish() {
    if (!mounted) return;
    if (!_active) {
      if (_speechCandidate) setState(_discardSpeechCandidate);
      LumoCompanionRequests.instance.clearTask(_published);
      return;
    }
    final revision = ++_revision;
    final p = _current;
    final task = LumoCompanionTaskContext(
      taskId: p.id,
      subject: widget.topic.subject,
      unit: widget.topic.unit,
      prompt: _phase == _Phase.build ? p.guidedPrompt : p.prompt,
      answering: !_done && _phase != _Phase.reflection && !_interruptedSave,
      attempts: _attempt,
      helpLevel: _effectiveSupport,
      lastAnswer: _speechCandidate
          ? null
          : _answer.text.isEmpty
              ? null
              : _answer.text,
      lastCorrect: _done
          ? true
          : _wrongBefore
              ? false
              : null,
      previousHelp: _hint == 0 ? null : p.hints[_hint - 1],
      localHelp: _visibleExplanation,
      activity: 'guided_lesson',
      ownerSection: 'learn',
      profileGeneration: _lease!.generation,
      // The separate native Activity owns this exact step until its return.
      // Hidden model callbacks or a proposed pattern choice cannot retarget it.
      stepId: _nativeStepId ?? '${_phase.name}:$_currentStep',
      objectIds: _objectIds,
      explanation: _visibleExplanation,
      answerChoices: p.mode == LabMode.pattern ? p.tokens : const [],
      isExplanation: _modelPhase,
      allowedActions: {
        LumoLearningAction.stop,
        LumoLearningAction.repeat,
        if (!_done && !_interruptedSave) ...{
          LumoLearningAction.hint,
          LumoLearningAction.explain,
          LumoLearningAction.slower,
          LumoLearningAction.look,
          LumoLearningAction.point,
          LumoLearningAction.highlight,
          if (!_modelPhase) LumoLearningAction.proposeAnswer,
        },
      },
    );
    _published = task;
    final requests = LumoCompanionRequests.instance;
    requests.tutor.enterTask(task.tutorScope);
    if (_safe && revision == _revision && identical(_published, task)) {
      _coach.publish(task);
      if (_focusObjectId != null && _objectIds.contains(_focusObjectId)) {
        _coach.present(objectId: _focusObjectId, point: true, state: 'explain');
      }
    }
  }

  void _event(LumoLearningEventKind kind) => LumoCompanionRequests.instance
      .recordLearningEvent(kind, context: _published);

  bool _modelValid() => switch (_current.mode) {
        LabMode.bridge => _moved == _current.modelTarget,
        LabMode.fraction => _pieces.length == _current.modelTarget,
        LabMode.pattern =>
          _patternChoice != null && _current.modelAccepts([_patternChoice!]),
        LabMode.word ||
        LabMode.english ||
        LabMode.nature =>
          _current.modelAccepts(_tokens),
      };

  void _modelChanged(VoidCallback change, String focus) {
    if (!_editable) return;
    unawaited(_stopSpeech());
    setState(() {
      if (_speechCandidate && _current.mode == LabMode.pattern) {
        _discardSpeechCandidate();
      }
      change();
      _focusObjectId = focus;
      _selfTry = false;
      _feedback = _current.mode == LabMode.bridge ? _visibleExplanation : '';
    });
    _publish();
    unawaited(_checkpoint());
  }

  String get _modelFeedback => switch (_current.mode) {
        LabMode.bridge =>
          'Im Zehnerfeld fehlen noch ${10 - _current.start - _moved} Plättchen. '
              'Fülle nur diese freien Plätze.',
        LabMode.fraction =>
          'Du hast ${_pieces.length} Teile markiert. Vergleiche die Anzahl '
              'mit dem Auftrag; alle Teile bleiben gleich groß.',
        LabMode.pattern => _patternChoice == null
            ? 'Wähle zuerst eine Form für den freien Platz.'
            : 'Prüfe die wiederkehrende Gruppe. Passt deine Form an die nächste Stelle?',
        _ => 'Prüfe die Reihenfolge. Du kannst jeden gelegten Baustein '
            'antippen und zurücklegen.',
      };

  Future<void> _checkModel() async {
    if (!_editable || _phase != _Phase.build) return;
    if (!_modelValid()) {
      setState(() => _feedback = _modelFeedback);
      _fox.think();
      _publish();
      return;
    }
    final p = _current;
    setState(() {
      _busy = true;
      _attempt++;
      _pendingAttemptId = '$_sessionId-$_attempt';
    });
    if (!await _checkpoint()) {
      if (mounted) {
        setState(() {
          _busy = false;
          _pendingAttemptId = null;
        });
      }
      return;
    }
    final evidence = LearningEvidence(
      taskId: _pendingAttemptId!,
      problemId: p.id,
      correct: true,
      helpLevel: 3,
    );
    final saved = await _progress.saveObservation(evidence);
    if (!_safe) return;
    setState(() {
      _busy = false;
      _done = saved;
      if (saved) {
        _lastSavedAttemptId = evidence.taskId;
        _pendingAttemptId = null;
      }
      _feedback = saved
          ? '${p.mode == LabMode.bridge ? _visibleExplanation : p.workedExample} '
              'Gut gebaut! Danach probierst du eine andere Aufgabe selbst.'
          : 'Dein Lernschritt wurde nicht gespeichert.';
    });
    _publish();
    if (saved) {
      await _checkpoint();
      _fox.cheer();
      unawaited(_read(_feedback, automatic: true));
    }
  }

  Future<void> _checkAnswer() async {
    if (!_editable || _modelPhase || _phase == _Phase.reflection) return;
    final p = _current;
    final text = p.mode == LabMode.pattern && _patternChoice != null
        ? p.tokens[_patternChoice!]
        : _answer.text.trim();
    if (text.isEmpty) {
      setState(() => _feedback = p.mode == LabMode.pattern
          ? 'Wähle zuerst eine Form.'
          : 'Trage zuerst deine Antwort ein.');
      return;
    }
    final correct = p.accepts(text);
    final support = math.max(_support, _wrongBefore ? 1 : 0);
    setState(() {
      _busy = true;
      _speechCandidate = false;
      _attempt++;
      _answer.text = text;
      _pendingAttemptId = '$_sessionId-$_attempt';
    });
    if (!await _checkpoint()) {
      if (mounted) {
        setState(() {
          _busy = false;
          _pendingAttemptId = null;
        });
      }
      return;
    }
    final evidence = LearningEvidence(
      taskId: _pendingAttemptId!,
      problemId: p.id,
      correct: correct,
      helpLevel: support,
      transferCheck: _phase == _Phase.transfer,
      errorTag: correct ? null : p.errorTag(text),
    );
    _publish();
    _event(LumoLearningEventKind.answerSubmitted);
    final saved = await _progress.saveAnswer(
      correct: correct,
      hintUsed: support > 0,
      prompt: p.prompt,
      given: text,
      expected: p.expected,
      learningEvidence: evidence,
    );
    if (!_safe) return;
    setState(() {
      _busy = false;
      _done = saved && correct;
      if (saved) {
        _lastSavedAttemptId = evidence.taskId;
        _pendingAttemptId = null;
        _wrongBefore = _wrongBefore || !correct;
        _feedback = correct
            ? support == 0
                ? 'Richtig! Ganz selbstständig geschafft.'
                : 'Richtig! Diese Antwort war mit Hilfe.'
            : p.feedback(text);
      } else {
        _invalid = true;
      }
    });
    _publish();
    if (saved) {
      _event(correct
          ? LumoLearningEventKind.answerCorrect
          : LumoLearningEventKind.answerIncorrect);
      await _checkpoint();
      correct ? _fox.cheer() : _fox.think();
      unawaited(_read(_feedback, automatic: true));
    }
  }

  Future<void> _next({bool skipInterrupted = false}) async {
    if (!_safe ||
        !_foreground ||
        !_routeVisible ||
        _nativeLearningOpen ||
        _busy ||
        _progress.hasPending ||
        (_phase != _Phase.example && !_done && !skipInterrupted) ||
        _phase == _Phase.reflection) {
      return;
    }
    _coach.interrupt('step_changed');
    await _stopSpeech();
    if (!_safe || !_foreground || !_routeVisible || _nativeLearningOpen) return;
    final keepExampleModel = _phase == _Phase.example;
    setState(() {
      _phase = _Phase.values[_phase.index + 1];
      if (!keepExampleModel) {
        _moved = 0;
        _pieces = <int>{};
        _tokens = <int>[];
        _patternChoice = null;
        _hint = 0;
        _support = 0;
      }
      _wrongBefore = false;
      _done = false;
      _interruptedSave = false;
      _pendingAttemptId = null;
      _lastSavedAttemptId = null;
      _feedback = '';
      _focusObjectId = null;
      _lastText = null;
      _lastSegments = null;
      _selfTry = false;
      _speechCandidate = false;
      _resumeNotice = null;
      _answer.clear();
    });
    _publish();
    if (_phase == _Phase.reflection) {
      _event(LumoLearningEventKind.lessonCompleted);
    }
    await _checkpoint();
  }

  void _requestHelp() {
    if (_routeVisible &&
        identical(
            LumoCompanionRequests.instance.taskContext.value, _published)) {
      _help();
    }
  }

  void _help({bool differently = false}) {
    if (!_active || !_canAnswer || _phase == _Phase.reflection) return;
    setState(() {
      _hint = differently && _hint < 3 ? 3 : (_hint + 1).clamp(1, 5);
      _support = math.max(_support, _hint);
      _selfTry = false;
      _feedback = _current.hints[_hint - 1];
      _focusObjectId = switch (_current.mode) {
        LabMode.bridge => 'ten_frame',
        LabMode.word => 'syllable_0',
        LabMode.pattern => 'pattern_group',
        LabMode.fraction => 'fraction-disc',
        _ => 'task_prompt',
      };
    });
    _fox.think();
    _publish();
    _event(LumoLearningEventKind.hintRequested);
    _event(LumoLearningEventKind.hintAccepted);
    unawaited(_checkpoint());
    unawaited(_read(_feedback));
  }

  Future<void> _repeat() async {
    if (!_safe || _busy) return;
    _event(LumoLearningEventKind.taskRepeated);
    if (_lastSegments != null) {
      await _readSyllables(slow: _slow);
    } else {
      await _read(_lastText ?? _visibleExplanation);
    }
  }

  Future<void> _slower() async {
    if (!_safe || _busy) return;
    _slow = true;
    if (_current.mode == LabMode.word && (_modelPhase || _hint >= 3)) {
      await _readSyllables(slow: true);
    } else {
      await _read(_lastText ?? _visibleExplanation, slow: true);
    }
  }

  void _tryMyself() {
    if (!_safe || _busy || _done) return;
    _coach.interrupt('child_requested_independence');
    unawaited(_stopSpeech());
    setState(() {
      _selfTry = true;
      _focusObjectId = null;
      _feedback = 'Du bist dran. Ich warte, bis du wieder Hilfe möchtest.';
    });
    // Earlier assistance is deliberately retained in _support and the checkpoint.
    _publish();
    _event(LumoLearningEventKind.hintDeclined);
    unawaited(_checkpoint());
  }

  void _stop() {
    if (!_safe) return;
    unawaited(_stopSpeech());
    setState(() {
      _discardSpeechCandidate();
      _focusObjectId = null;
      _feedback = 'Die Erklärung ist angehalten. Deine Aufgabe bleibt liegen.';
    });
    _publish();
  }

  void _discardSpeechCandidate() {
    if (!_speechCandidate) return;
    _speechCandidate = false;
    if (_current.mode == LabMode.pattern) _patternChoice = null;
    _answer.clear();
  }

  void _finishNativeReturn() {
    _nativeLearningOpen = false;
    _nativeReturnPending = false;
    _nativeStepId = null;
    if (_speechCandidate && _current.mode == LabMode.pattern) {
      final index = _current.tokens.indexWhere(
          (value) => value.toLowerCase() == _answer.text.trim().toLowerCase());
      _patternChoice = index < 0 ? null : index;
    }
  }

  Future<void> _openNativeLearning() async {
    if (!_editable ||
        !_routeVisible ||
        !_coach.ownsCurrentTask ||
        _phase == _Phase.reflection) {
      return;
    }
    final problemId = _current.id;
    final phase = _phase;
    _discardSpeechCandidate();
    unawaited(_stopSpeech());
    // Assistance is marked synchronously, before checkpoint/platform I/O.
    // The existing answer writer remains the only assessment authority.
    _support = math.max(_support, 1);
    setState(() {
      _nativeLearningOpen = true;
      _nativeReturnPending = false;
      _nativeStepId = '${_phase.name}:$_currentStep';
      _hint = math.max(_hint, 1);
      _selfTry = false;
      _feedback = _current.hints[_hint - 1];
    });
    _publish();
    _event(LumoLearningEventKind.hintRequested);
    _event(LumoLearningEventKind.hintAccepted);
    final task = _published;
    final activity =
        task == null ? null : NativeLearningActivity.fromCompanionContext(task);
    try {
      if (activity == null || !await _checkpoint()) return;
      if (!mounted ||
          !_active ||
          !_foreground ||
          _current.id != problemId ||
          _phase != phase ||
          !_coach.ownsCurrentTask) {
        return;
      }
      // All six Lab modes retain their exact current prompt/choices in the
      // bounded task_card. No second evaluator or guessed subject model.
      await launchLumo3D(context,
          scene: 'learning',
          appState: widget.appState,
          subject: widget.topic.subject,
          learning: activity);
    } catch (_) {
      if (_safe && _current.id == problemId && _phase == phase) {
        setState(() => _feedback = 'Die 3D-Ansicht ist gerade nicht verfügbar. '
            'Du kannst mit dieser Aufgabe weiterarbeiten.');
      }
    } finally {
      if (mounted && _current.id == problemId && _phase == phase) {
        setState(() {
          if (_foreground) {
            _finishNativeReturn();
          } else {
            // Android can complete the method call before Flutter resumes.
            // Keep the binding and the ungraded candidate through that gap.
            _nativeReturnPending = true;
          }
        });
        _publish();
        unawaited(_checkpoint());
      }
    }
  }

  bool _maySpeak(int serial) =>
      _safe &&
      _foreground &&
      !_nativeLearningOpen &&
      _routeVisible &&
      widget.appState.state.settings.voiceEnabled &&
      serial == _voiceSerial;

  Future<void> _read(String text, {bool automatic = false, bool? slow}) async {
    if (!_safe || !_foreground || !_routeVisible || _nativeLearningOpen) return;
    final settings = widget.appState.state.settings;
    if (!settings.voiceEnabled ||
        (automatic && (!settings.autoReadEnabled || settings.calmMode))) {
      return;
    }
    final serial = ++_voiceSerial;
    _pendingSyllable = null;
    _activeSyllable = null;
    _lastSegments = null;
    _lastText = text;
    if (slow != null) _slow = slow;
    try {
      await _narration.stop();
      if (!_maySpeak(serial)) return;
      await LumoVoice.instance.configure(
          rate: _slow ? settings.voiceRate * .7 : settings.voiceRate);
      if (!_maySpeak(serial)) return;
      if (automatic) {
        await _narration.feedback(text);
      } else {
        await _narration.read(text);
      }
    } catch (_) {
      // The current text remains visible if device audio is unavailable.
    } finally {
      if (serial == _voiceSerial) {
        await LumoVoice.instance
            .configure(rate: widget.appState.state.settings.voiceRate);
      }
    }
  }

  Future<void> _readSyllables({bool slow = false, int? only}) async {
    if (!_safe ||
        !_routeVisible ||
        !_foreground ||
        _nativeLearningOpen ||
        _current.mode != LabMode.word) {
      return;
    }
    final settings = widget.appState.state.settings;
    if (!settings.voiceEnabled) return;
    final parts = _syllables;
    if (only != null && (only < 0 || only >= parts.length)) return;
    if (!_modelPhase) {
      _support = math.max(_support, 3);
      _publish();
      unawaited(_checkpoint());
    }
    final serial = ++_voiceSerial;
    _lastSegments = List<String>.of(parts);
    _lastText = _current.expected;
    _slow = slow;
    try {
      await _narration.stop();
      if (!_maySpeak(serial)) return;
      await LumoVoice.instance
          .configure(rate: slow ? settings.voiceRate * .7 : settings.voiceRate);
      for (final index in only == null
          ? List<int>.generate(parts.length, (i) => i)
          : <int>[only]) {
        if (!_maySpeak(serial)) return;
        _pendingSyllable = index;
        _focusObjectId = 'syllable_$index';
        final completedBefore = LumoVoice.instance.completedPlaybackCount;
        await _narration.read(parts[index]);
        if (!_maySpeak(serial) ||
            LumoVoice.instance.completedPlaybackCount <= completedBefore) {
          // Do not sweep the next syllables when synthesis, playback or a real
          // completion event is unavailable. This is not a reading timer.
          break;
        }
      }
    } catch (_) {
      // All checked syllables and controls remain readable and tappable.
    } finally {
      if (serial == _voiceSerial) {
        _pendingSyllable = null;
        _activeSyllable = null;
        if (mounted) setState(() {});
        await LumoVoice.instance
            .configure(rate: widget.appState.state.settings.voiceRate);
      }
    }
  }

  void _voiceChanged() {
    if (!_safe) return;
    final speaking = _foreground &&
        _routeVisible &&
        _narration.isActive &&
        LumoVoice.instance.status.value == VoiceStatus.speaking;
    final active = speaking ? _pendingSyllable : null;
    if (_activeSyllable != active) setState(() => _activeSyllable = active);
    if (speaking) {
      _fox.talk();
    } else if (_narration.isActive &&
        LumoVoice.instance.status.value == VoiceStatus.preparing) {
      _fox.think();
    }
  }

  Future<void> _stopSpeech() async {
    ++_voiceSerial;
    _pendingSyllable = null;
    _activeSyllable = null;
    await _narration.stop();
    await LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate);
  }

  Widget _model(LabProblem p, bool enabled) {
    final captured = _coach.identity;
    void change(VoidCallback update, String focus) {
      if (captured != null && _coach.matches(captured)) {
        _modelChanged(update, focus);
      }
    }

    return switch (p.mode) {
      LabMode.bridge => QuantityBridgeBoard(
          start: p.start,
          addend: p.addend,
          moved: _moved,
          maxMoved: p.modelTarget,
          onChanged: (n) => change(
              () => _moved = n, n == p.modelTarget ? 'addend' : 'ten_frame'),
          enabled: enabled,
          reduceMotion: _reduced,
          reveal: !_selfTry && (_hint >= 3 || _moved == p.modelTarget),
        ),
      LabMode.fraction => FractionBuildBoard(
          denominator: p.denominator,
          selected: _pieces,
          onChanged: (n) => change(() => _pieces = n, 'fraction-disc'),
          enabled: enabled,
          reduceMotion: _reduced,
        ),
      LabMode.pattern => PatternBuildBoard(
          sequence: p.pattern,
          options: p.tokens,
          groupLength: p.repeatLength,
          selected: _patternChoice,
          onChanged: (n) => change(() => _patternChoice = n, 'pattern_next'),
          enabled: enabled,
          revealGroup: !_selfTry && _hint > 0,
          reduceMotion: _reduced,
        ),
      LabMode.word => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SyllableLearningBoard(
              word: p.expected,
              wordPlaybackLabel: 'Silben vorsprechen',
              syllables: _syllables,
              activeIndex: _activeSyllable,
              onReadSegment: widget.appState.state.settings.voiceEnabled
                  ? (i) {
                      if (captured != null && _coach.matches(captured)) {
                        unawaited(_readSyllables(slow: _slow, only: i));
                      }
                    }
                  : null,
              onReadWord: widget.appState.state.settings.voiceEnabled
                  ? _bound(() => unawaited(_readSyllables(slow: _slow)))
                  : null,
              enabled: enabled,
              reduceMotion: _reduced,
            ),
            const SizedBox(height: 14),
            LearningTokenWorkbench(
              tokens: p.tokens,
              selected: _tokens,
              onChanged: (n) =>
                  change(() => _tokens = n, 'syllable_${n.length.clamp(0, 2)}'),
              enabled: enabled,
              reduceMotion: _reduced,
            ),
          ],
        ),
      LabMode.english || LabMode.nature => LearningTokenWorkbench(
          tokens: p.tokens,
          selected: _tokens,
          onChanged: (n) => change(() => _tokens = n,
              n.isEmpty ? 'task_prompt' : 'token-work-${n.last}'),
          enabled: enabled,
          reduceMotion: _reduced,
        ),
    };
  }

  VoidCallback? _bound(VoidCallback? action) {
    final captured = _coach.identity;
    if (action == null ||
        captured == null ||
        !_foreground ||
        _nativeLearningOpen) {
      return null;
    }
    return () {
      if (_foreground && !_nativeLearningOpen && _coach.matches(captured)) {
        action();
      }
    };
  }

  Widget _button(String key, String caption, VoidCallback? onTap) =>
      FilledButton(
        key: ValueKey(key),
        onPressed: _bound(onTap),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: LumoVisualTokens.cyan,
          foregroundColor: const Color(0xFF071F36),
        ),
        child: Text(caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w900)),
      );

  Widget _command(
          String key, IconData icon, String label, VoidCallback? action) =>
      OutlinedButton.icon(
        key: ValueKey(key),
        onPressed: _bound(action),
        icon: Icon(icon, size: 21),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: LumoVisualTokens.cyanBright,
          textStyle: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 15),
        ),
      );

  Widget _commands() {
    final voice = widget.appState.state.settings.voiceEnabled;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      _command('lab-open-3d', Icons.view_in_ar_rounded, 'Mit Lumo in 3D',
          _editable ? () => unawaited(_openNativeLearning()) : null),
      _command('lab-help', Icons.lightbulb_outline, 'Hilf mir',
          _editable ? () => _coach.request(LumoLearningAction.hint) : null),
      _command(
          voice && _lastText != null ? 'lab-voice-repeat' : 'lab-repeat',
          Icons.replay_rounded,
          'Noch einmal',
          _safe && !_busy
              ? () => _coach.request(LumoLearningAction.repeat)
              : null),
      _command(
          'lab-slower',
          Icons.slow_motion_video_rounded,
          'Langsamer',
          voice && _safe && !_busy
              ? () => _coach.request(LumoLearningAction.slower)
              : null),
      _command(
          'lab-explain-differently',
          Icons.swap_horiz_rounded,
          'Anders erklären',
          _editable ? () => _coach.request(LumoLearningAction.explain) : null),
      _command('lab-stop', Icons.stop_circle_outlined, 'Stopp',
          _safe ? () => _coach.request(LumoLearningAction.stop) : null),
      _command(
          'lab-try-myself',
          Icons.touch_app_outlined,
          'Selbst versuchen',
          _editable
              ? () {
                  final current = _coach.identity;
                  if (current != null) _coach.tryMyself(current);
                }
              : null),
      _command(
          'lab-ask-lumo',
          Icons.forum_outlined,
          'Frage an Lumo',
          _safe && !_busy
              ? () => unawaited(showLumoConversation(context,
                  appState: widget.appState,
                  onSection: widget.appState.setSection))
              : null),
    ]);
  }

  Widget _content() {
    final p = _current;
    if (_phase == _Phase.reflection) {
      final record = _lease!.profile.journey
          .records[SkillRecord.makeId(widget.topic.subject, widget.topic.unit)];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Dein Verstehensmoment', style: _body.copyWith(fontSize: 25)),
        const SizedBox(height: 14),
        Text(p.reflection, style: _body),
        const SizedBox(height: 14),
        Text(record?.explanation ?? 'Wir lernen Schritt für Schritt.',
            style: _body.copyWith(color: LumoVisualTokens.muted, fontSize: 16)),
        const SizedBox(height: 16),
        _button('lab-finish', 'Zurück zu den Lernwelten',
            () => Navigator.of(context).maybePop()),
      ]);
    }
    if (_modelPhase) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_phase == _Phase.example ? p.prompt : p.guidedPrompt,
            style: _body.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (_phase == _Phase.example)
          Text(
              p.mode == LabMode.bridge
                  ? 'Im Feld liegen ${p.start}, daneben ${p.addend}. '
                      'Bewege ein Plättchen und beobachte, was sich ändert.'
                  : p.guidedPrompt,
              style:
                  _body.copyWith(fontSize: 16, color: LumoVisualTokens.muted)),
        const SizedBox(height: 14),
        KeyedSubtree(
            key: const ValueKey('lab-model'), child: _model(p, _editable)),
        const SizedBox(height: 14),
        if (_phase == _Phase.example) ...[
          _button(
              'lab-speak',
              p.mode == LabMode.word
                  ? 'Silben anhören'
                  : 'Sichtbaren Schritt anhören',
              () => unawaited(p.mode == LabMode.word
                  ? _readSyllables(slow: _slow)
                  : _read(_visibleExplanation))),
          const SizedBox(height: 10),
          _button(
              'lab-next', 'Jetzt gemeinsam bauen', () => unawaited(_next())),
        ] else ...[
          _button('lab-check-model', 'Mein Modell prüfen',
              _editable ? () => unawaited(_checkModel()) : null),
          if (_done) ...[
            const SizedBox(height: 12),
            _button('lab-next', 'Jetzt selbstständig antworten',
                () => unawaited(_next())),
          ],
        ],
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(p.prompt,
          style: _body.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (p.mode == LabMode.pattern || (_hint >= 3 && !_selfTry)) ...[
        KeyedSubtree(
            key: const ValueKey('lab-model'), child: _model(p, _editable)),
        const SizedBox(height: 12),
      ],
      if (p.mode != LabMode.pattern)
        TextField(
          key: const ValueKey('lab-answer'),
          controller: _answer,
          enabled: _editable,
          maxLength: 80,
          autocorrect: false,
          keyboardType: p.mode == LabMode.bridge || p.mode == LabMode.fraction
              ? TextInputType.number
              : TextInputType.text,
          style: _body.copyWith(fontSize: 22),
          decoration: InputDecoration(
            labelText: _speechCandidate
                ? 'Sprachvorschlag – bitte prüfen'
                : 'Deine Antwort',
            hintText: 'Hier schreiben',
            border: const OutlineInputBorder(),
            filled: true,
          ),
        ),
      const SizedBox(height: 12),
      _button('lab-check-answer', 'Antwort prüfen',
          _editable ? () => unawaited(_checkAnswer()) : null),
      if (_done) ...[
        const SizedBox(height: 12),
        _button(
            'lab-next',
            _phase == _Phase.recall ? 'Neue Aufgabe' : 'Mein Rückblick',
            () => unawaited(_next())),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    const captions = [
      'Beispiel',
      'Gemeinsam bauen',
      'Freier Abruf',
      'Neue Aufgabe',
      'Rückblick'
    ];
    return PopScope(
      canPop: !_progress.hasPending && !_busy,
      child: Scaffold(
        backgroundColor: LumoVisualTokens.night,
        appBar: AppBar(
            title: Text(widget.topic.title),
            backgroundColor: LumoVisualTokens.night,
            foregroundColor: LumoVisualTokens.white),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !_safe
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(22),
                          child: Text(
                              'Kinderprofil wurde gewechselt oder die Lernwelt ist für eine spätere Klasse vorgesehen. Bitte kehre zurück.',
                              textAlign: TextAlign.center,
                              style: _body)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
                      children: [
                        Center(
                            child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LinearProgressIndicator(
                                    value: (_phase.index + 1) / 5,
                                    minHeight: 7,
                                    color: LumoVisualTokens.cyan),
                                const SizedBox(height: 12),
                                Text(captions[_phase.index],
                                    style: _body.copyWith(
                                        color: LumoVisualTokens.cyanBright,
                                        fontSize: 17)),
                                Row(children: [
                                  LumoCharacter(
                                      pose: LumoDesignFoxPose.bookWelcome,
                                      size: 78,
                                      controller: _fox,
                                      reduceMotion: _reduced),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(widget.topic.goal,
                                          style: _body.copyWith(fontSize: 16))),
                                ]),
                                if (_resumeNotice != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(_resumeNotice!,
                                          key: const ValueKey(
                                              'lab-resume-notice'),
                                          style: _body.copyWith(fontSize: 15))),
                                const SizedBox(height: 12),
                                DecoratedBox(
                                  key: ValueKey('lab-phase-${_phase.name}'),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF153D64),
                                      Color(0xFF0B2341)
                                    ]),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: const Color(0xFF5D91AE)),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x55020D23),
                                          blurRadius: 24,
                                          offset: Offset(0, 8))
                                    ],
                                  ),
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: _content()),
                                ),
                                if (_interruptedSave)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _button(
                                          'lab-skip-interrupted',
                                          'Mit nächstem Schritt weiter',
                                          () => unawaited(
                                              _next(skipInterrupted: true)))),
                                if (_feedback.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Semantics(
                                          liveRegion: true,
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                    _done
                                                        ? Icons
                                                            .check_circle_outline
                                                        : Icons
                                                            .chat_bubble_outline,
                                                    color: LumoVisualTokens
                                                        .cyanBright,
                                                    size: 22),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: Text(_feedback,
                                                        key: const ValueKey(
                                                            'lab-feedback'),
                                                        style: _body.copyWith(
                                                            fontSize: 17))),
                                              ]))),
                                if (_phase != _Phase.reflection) ...[
                                  const SizedBox(height: 16),
                                  Text('Mit Lumo weiterdenken',
                                      style: _body.copyWith(fontSize: 18)),
                                  const SizedBox(height: 8),
                                  _commands(),
                                  if (!widget
                                      .appState.state.settings.voiceEnabled)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                            'Die Stimme ist ausgeschaltet. Alle Schritte bleiben lesbar und bedienbar.',
                                            style: _body.copyWith(
                                                fontSize: 14,
                                                color:
                                                    LumoVisualTokens.muted))),
                                ],
                                if (_resumeError != null) ...[
                                  const SizedBox(height: 10),
                                  Text(_resumeError!,
                                      style: _body.copyWith(fontSize: 15)),
                                  _button(
                                      'lab-retry-checkpoint',
                                      'Ansicht speichern wiederholen',
                                      () => unawaited(_checkpoint())),
                                ],
                                if (_progress.error != null) ...[
                                  const SizedBox(height: 10),
                                  Text(_progress.error!,
                                      style: _body.copyWith(fontSize: 15)),
                                  _button(
                                      'lab-retry-save',
                                      'Speichern wiederholen',
                                      _progress.saving
                                          ? null
                                          : _progress.retry),
                                ],
                                if (_progress.saving || _busy)
                                  const LinearProgressIndicator(),
                              ]),
                        ))
                      ],
                    ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _coach.dispose();
    if (identical(
        LumoCompanionRequests.instance.taskContext.value, _published)) {
      LumoCompanionRequests.instance
          .cancelLearningInteraction(reason: 'page_exit');
    }
    ++_voiceSerial;
    // Preserve the current draft without recording a learning answer.
    if (_safe) unawaited(_checkpoint());
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_checkProfile);
    LumoCompanionRequests.instance.helpRequested.removeListener(_requestHelp);
    LumoVoice.instance.status.removeListener(_voiceChanged);
    _progress.removeListener(_repaint);
    _narration.removeListener(_repaint);
    _answer.removeListener(_answerChanged);
    final task = _published;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => LumoCompanionRequests.instance.clearTask(task));
    _progress.dispose();
    _narration.dispose();
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
    _fox.dispose();
    _answer.dispose();
    super.dispose();
  }
}
