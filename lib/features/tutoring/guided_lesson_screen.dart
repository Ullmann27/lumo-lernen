import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/lumo_voice.dart';
import '../../core/lumo_learning_session_contract.dart';
import '../../core/learning_attempt_id.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../domain/tutoring/guided_lesson_evidence.dart';
import '../../domain/tutoring/native_learning_activity.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';
import '../../widgets/fox/lumo_character.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../learning/lab/learning_manipulatives.dart';
import '../learning/nextgen/learning_coach_binding.dart';
import '../learning_modules/learning_module_progress.dart';
import '../lumo3d/lumo3d_launcher.dart';
import 'guided_math_illustration.dart';

/// Real five-part instruction using existing tutoring types, central voice,
/// companion bus and the captured-owner learning writer.
class GuidedLessonScreen extends StatefulWidget {
  const GuidedLessonScreen({
    super.key,
    required this.appState,
    required this.lesson,
    required this.discovery,
    this.voice,
  });

  final LumoAppState appState;
  final GuidedLesson lesson;
  final bool discovery;
  final LumoVoice? voice;

  @override
  State<GuidedLessonScreen> createState() => _GuidedLessonScreenState();
}

class _GuidedLessonScreenState extends State<GuidedLessonScreen>
    with WidgetsBindingObserver {
  static int _nextSession = 0;
  final _session = ++_nextSession;
  final _lumo = LumoCharacterController();
  final _stopSignal = ValueNotifier<int>(0);
  final _candidateController = TextEditingController();
  late final LearningCoachBinding _coach;
  String? _candidate;
  LumoLearningIdentity? _candidateIdentity;
  String? _focusObjectId;
  late final int _generation;
  late final _progress = LearningModuleProgress(
    appState: widget.appState,
    subject: widget.lesson.subject,
    unit: widget.lesson.schoolUnit,
    discoveryTarget: widget.discovery ? widget.lesson.discoveryTarget : null,
  );
  int _index = 0;
  int _serial = 0;
  int _attempts = 0;
  int _helpLevel = 0;
  int _solved = 0;
  int _independentSolved = 0;
  final Set<int> _accompaniedSteps = {};
  int _replay = 0;
  bool _ready = false;
  bool _busy = false;
  bool _passed = false;
  bool _stale = false;
  late final LumoVoice _voice = widget.voice ?? LumoVoice.instance;
  int? _voiceRequest;
  bool get _ownsVoice =>
      _voiceRequest != null && _voice.requestRevision == _voiceRequest;
  bool _completed = false;
  bool _showExplanation = false;
  bool _hideHelp = false;
  bool _foreground = true;
  bool _routeVisible = true;
  bool _nativeLearningOpen = false;
  bool _nativeReturnPending = false;
  bool _slowNarration = false;
  bool _presentationStopped = false;
  int? _pendingSyllable;
  int? _activeSyllable;
  String? _lastNarration;
  int _voiceSequence = 0;
  String? _blocked;
  String? _lastAnswer;
  bool? _lastCorrect;
  String? _feedback;
  String? _previousHelp;
  GuidedLessonStep? _easier;
  List<String> _choices = [];
  LumoCompanionTaskContext? _published;

  GuidedLessonStep get _step => _easier ?? widget.lesson.steps[_index];
  // Remediation is real support, but it is not a tip already shown on return.
  // Keep the visible hint ladder separate from the evidence of accompaniment.
  int get _evidenceHelpLevel =>
      _easier == null && _accompaniedSteps.contains(_index)
          ? math.max(1, _helpLevel)
          : _helpLevel;
  bool get _current =>
      mounted &&
      !_stale &&
      !widget.appState.resetting &&
      widget.appState.profileGeneration == _generation &&
      (widget.discovery || widget.lesson.grade <= widget.appState.state.grade);
  bool get _quiet =>
      widget.appState.state.settings.reduceAnimations ||
      widget.appState.state.settings.calmMode ||
      MediaQuery.disableAnimationsOf(context);

  static const _body = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 18,
      height: 1.4,
      fontWeight: FontWeight.w700);

  @override
  void initState() {
    super.initState();
    _coach = LearningCoachBinding(
      isActive: () =>
          _current &&
          _ready &&
          _blocked == null &&
          _routeVisible &&
          (_foreground || _nativeLearningOpen),
      onHint: _requestHelp,
      onExplain: () => _requestHelp(differently: true),
      onRepeat: _repeatExplanation,
      onSlower: _slowerExplanation,
      onStop: _stopExplanation,
      onCancel: _cancelPresentation,
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
    _generation = widget.appState.profileGeneration;
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _progress.addListener(_saveChanged);
    widget.appState.addListener(_profileChanged);
    LumoCompanionRequests.instance.helpRequested.addListener(_legacyHelp);
    _voice.status.addListener(_voiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = ModalRoute.isCurrentOf(context) ?? true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_routeVisible) {
        _publish();
      } else {
        _cancelPresentation();
        _coach.clear();
      }
    });
  }

  Future<void> _load() async {
    if (!mounted || _stale) return;
    // Explain a forbidden school route before touching a lease: _current
    // intentionally rejects it, and otherwise left the gate stuck on Loading.
    if (!widget.discovery &&
        widget.lesson.grade > widget.appState.state.grade) {
      setState(() {
        _ready = true;
        _blocked = 'Ein Thema aus einer höheren Schulstufe gehört zu '
            '„Mit Lumo Neues entdecken“. Deine Schulklasse bleibt gleich.';
      });
      return;
    }
    try {
      final owner = await widget.appState.captureLearningProfile();
      await widget.appState.prepareLearningLease(owner);
      if (!_current || !widget.appState.isCurrentLearningLease(owner)) return;
      if (widget.discovery) {
        await owner.profile.loadDiscovery();
        if (!_current) return;
        if (!owner.profile.canDiscover(widget.lesson.grade)) {
          setState(() {
            _ready = true;
            _blocked = 'Bitte gib das Gerät einer erwachsenen Person. '
                'Dieses Thema braucht eine eigene Entdeckungsfreigabe.';
          });
          return;
        }
      }
      setState(() => _ready = true);
      _startStep();
      if (widget.discovery) {
        LumoCompanionRequests.instance
            .recordLearningEvent(LumoLearningEventKind.exploreTopicRequested);
      }
      _lumo.hello();
    } catch (_) {
      if (!_current) return;
      setState(() {
        _ready = true;
        _blocked = 'Deine gespeicherten Lerndaten konnten nicht sicher '
            'geladen werden. Sie bleiben unverändert.';
      });
    }
  }

  void _saveChanged() {
    if (mounted) setState(() {});
  }

  void _profileChanged() {
    if (_stale ||
        (widget.appState.profileGeneration == _generation &&
            (widget.discovery ||
                widget.lesson.grade <= widget.appState.state.grade))) {
      return;
    }
    _stale = true;
    _cancelPresentation();
    final task = _published;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LumoCompanionRequests.instance.clearTask(task);
      if (mounted) setState(() {});
    });
  }

  void _startStep() {
    if (!_current) return;
    _stopOwnedVoice();
    setState(() {
      _serial++;
      _choices = _step.isQuestion
          ? (_step.choices..shuffle(math.Random(_session * 31 + _serial)))
          : [];
      _attempts = 0;
      _helpLevel = 0;
      _passed = !_step.isQuestion;
      _lastAnswer = null;
      _candidate = null;
      _candidateIdentity = null;
      _candidateController.clear();
      _focusObjectId = null;
      _lastCorrect = null;
      _feedback = null;
      _previousHelp = null;
      _showExplanation = false;
      _hideHelp = false;
      _lastNarration = null;
      _activeSyllable = null;
      _pendingSyllable = null;
      _replay++;
    });
    _publish();
    // Publishing a new step cancels its predecessor synchronously. Only the
    // fresh illustration may now start its own explicitly scoped playback.
    _presentationStopped = false;
    if (_step.type == TutoringStepType.recap && !_completed) {
      _completed = true;
      LumoCompanionRequests.instance
          .recordLearningEvent(LumoLearningEventKind.lessonCompleted);
      _lumo.cheer();
    }
    final settings = widget.appState.state.settings;
    if (settings.voiceEnabled &&
        settings.autoReadEnabled &&
        !settings.calmMode &&
        !_tenFrameExample) {
      unawaited(_read(_step.instruction));
    }
  }

  bool get _tenFrameExample =>
      widget.lesson.concept == GuidedLessonConcept.bridgeTen &&
      _step.type == TutoringStepType.showExample;

  bool get _segmentedWord =>
      widget.lesson.concept == GuidedLessonConcept.syllables &&
      _step.word.isNotEmpty &&
      (!_step.isQuestion || (_helpLevel >= 3 && !_hideHelp));

  List<String> get _objectIds => [
        'guided-step-title',
        'guided-instruction',
        'guided-illustration',
        if (_segmentedWord) ...[
          'syllable-word-picture',
          'syllable-word',
          for (var i = 0; i < _step.syllables.length; i++)
            'guided-spoken-syllable-$i',
        ] else if (widget.lesson.concept == GuidedLessonConcept.syllables &&
            _step.word.isNotEmpty)
          'guided-unsegmented-word',
        if (widget.lesson.concept == GuidedLessonConcept.plantParts)
          'guided-flowering-plant',
        if (_step.isQuestion)
          for (final choice in _choices) 'guided-answer-$choice',
        if (_previousHelp != null && !_hideHelp) 'guided-actual-hint',
      ];

  VoidCallback? _bound(VoidCallback? callback) {
    if (callback == null) return null;
    final captured = _coach.identity;
    return captured == null
        ? null
        : () {
            if (_coach.matches(captured)) callback();
          };
  }

  void _legacyHelp() {
    if (_coach.ownsCurrentTask) _coach.request(LumoLearningAction.hint);
  }

  void _requestHelp({bool differently = false}) {
    if (_step.isQuestion) {
      _help(differently: differently);
      return;
    }
    if (!_current ||
        !_ready ||
        (_busy && !_nativeLearningOpen) ||
        _blocked != null) {
      return;
    }
    setState(() {
      _showExplanation = true;
      _hideHelp = false;
      _focusObjectId = _segmentedWord ? 'syllable-word' : 'guided-illustration';
    });
    _publish();
    if (_segmentedWord) {
      unawaited(_readSyllables());
    } else {
      unawaited(_read(_step.instruction));
    }
  }

  void _cancelPresentation({bool discardCandidate = true}) {
    _stopOwnedVoice();
    _stopSignal.value++;
    if (mounted) {
      setState(() {
        _presentationStopped = true;
        if (discardCandidate) {
          _candidate = null;
          _candidateIdentity = null;
          _candidateController.clear();
        }
        _focusObjectId = null;
      });
    }
  }

  void _proposeAnswer(String value) {
    if (!_coach.ownsCurrentTask ||
        !_current ||
        !_ready ||
        (_busy && !_nativeLearningOpen) ||
        _passed ||
        !_step.isQuestion ||
        _progress.hasPending) {
      return;
    }
    final candidate = value.trim();
    if (candidate.isEmpty || candidate.length > 160) return;
    _candidateController.text = candidate;
    setState(() {
      _candidate = candidate;
      _candidateIdentity = _coach.identity;
    });
    // A transcript remains an editable proposal. Only the explicit confirmation
    // below reaches the existing deterministic answer evaluator and writer.
  }

  void _confirmCandidate() {
    final identity = _candidateIdentity;
    if (identity == null || !_coach.matches(identity)) return;
    final answer = _candidateController.text.trim();
    if (answer.isNotEmpty) unawaited(_answer(answer));
  }

  void _publish() {
    if (!_current ||
        !_ready ||
        _blocked != null ||
        !_routeVisible ||
        (!_foreground && !_nativeLearningOpen)) {
      _coach.clear();
      return;
    }
    _published = LumoCompanionTaskContext(
      taskId: 'guided-$_session-$_serial',
      subject: widget.lesson.subject,
      unit: widget.lesson.schoolUnit,
      prompt: _step.instruction,
      answering: _step.isQuestion &&
          !_passed &&
          (!_busy || _nativeLearningOpen) &&
          !_progress.hasPending,
      attempts: _attempts,
      helpLevel: _lastCorrect == true ? _evidenceHelpLevel : _helpLevel,
      lastAnswer: _lastAnswer,
      lastCorrect: _lastCorrect,
      localHelp: _step.isQuestion ? _step.help(level: _helpLevel + 1) : null,
      previousHelp: _previousHelp,
      activity: widget.discovery ? 'discovery' : 'guided_lesson',
      ownerSection: 'learn',
      profileGeneration: _generation,
      stepId:
          '${widget.lesson.id}:$_index:${_step.type.name}:${_easier == null ? "task" : "prerequisite"}',
      objectIds: _objectIds,
      explanation: _previousHelp ??
          (_step.isQuestion
              ? _step.help(level: _helpLevel + 1)
              : _step.instruction),
      answerChoices: _choices,
      isExplanation: !_step.isQuestion,
      allowedActions: {
        LumoLearningAction.stop,
        LumoLearningAction.repeat,
        LumoLearningAction.slower,
        LumoLearningAction.look,
        LumoLearningAction.point,
        LumoLearningAction.highlight,
        if ((!_busy || _nativeLearningOpen) &&
            !_progress.hasPending &&
            (!_step.isQuestion || !_passed)) ...{
          LumoLearningAction.explain,
          LumoLearningAction.hint,
          if (_step.isQuestion) LumoLearningAction.proposeAnswer,
        },
      },
    );
    _coach.publish(_published!);
    if (_focusObjectId != null && _objectIds.contains(_focusObjectId)) {
      _coach.present(objectId: _focusObjectId, point: true, state: 'explain');
    }
  }

  Future<void> _answer(String answer) async {
    if (!_current ||
        !_foreground ||
        !_routeVisible ||
        _busy ||
        _passed ||
        !_step.isQuestion ||
        _progress.hasPending) {
      return;
    }
    final step = _step;
    final serial = _serial;
    final correct = step.accepts(answer);
    setState(() {
      _busy = true;
      _attempts++;
      _lastAnswer = answer;
      _candidate = null;
      _candidateIdentity = null;
      _candidateController.clear();
    });
    _publish();
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.answerSubmitted);
    final evidenceHelpLevel = _evidenceHelpLevel;
    final independent = GuidedLessonEvidence.isIndependent(
        attempts: _attempts, helpLevel: evidenceHelpLevel);
    if (!correct) _accompaniedSteps.add(_index);
    // Only independent school answers count as school skills/Daily.
    // Prerequisite and accompanied examples are not fabricated mastery.
    final saved = widget.discovery || step.isIndependent
        ? await _progress.saveAnswer(
            correct: correct,
            hintUsed: !independent,
            prompt: step.instruction,
            given: answer,
            expected: step.expected,
            discoveryStep: step.observation!,
            learningEvidence: widget.discovery
                ? null
                : GuidedLessonEvidence.observation(
                    lesson: widget.lesson,
                    step: step,
                    attemptId: newLearningAttemptId(),
                    answer: answer,
                    attempts: _attempts,
                    helpLevel: evidenceHelpLevel),
          )
        : true;
    if (!_current || serial != _serial) return;
    setState(() {
      _busy = false;
      if (!saved) {
        _blocked = 'Die Freigabe oder das Kinderprofil wurde geändert. '
            'Bitte gehe zur Lernübersicht zurück.';
        return;
      }
      _lastCorrect = correct;
      _passed = correct;
      if (correct) {
        _solved++;
        if (step.isIndependent && independent) _independentSolved++;
        _feedback = step.isIndependent && independent
            ? widget.lesson.subject == 'Mathematik'
                ? 'Du hast selbst gerechnet. Gut gemacht!'
                : 'Das hast du selbst herausgefunden. Gut gemacht!'
            : !independent
                ? 'Das passt! Mit den gemeinsamen Schritten hast du es geschafft.'
                : 'Das passt! Weiter geht es in deinem Tempo.';
      } else {
        _feedback = _attempts == 1
            ? 'Fast! Probiere es noch einmal. Wenn du magst, hilft dir ein Tipp.'
            : 'Wir können es mit kleineren Schritten probieren. '
                'Du entscheidest, ob du Hilfe möchtest.';
      }
    });
    if (!saved) return;
    _publish();
    final requests = LumoCompanionRequests.instance;
    requests.recordInteraction(LumoInteractionKind.answerChecked);
    requests.recordLearningEvent(correct
        ? LumoLearningEventKind.answerCorrect
        : LumoLearningEventKind.answerIncorrect);
    if (correct) {
      _lumo.cheer();
    } else {
      _lumo.comfort();
    }
    if (widget.appState.state.settings.autoReadEnabled &&
        widget.appState.state.settings.voiceEnabled &&
        !widget.appState.state.settings.calmMode) {
      unawaited(_read(_feedback!,
          style: correct ? VoiceStyle.celebrate : VoiceStyle.comfort));
    }
  }

  void _help({bool differently = false}) {
    if (!_current ||
        !_ready ||
        _blocked != null ||
        (_busy && !_nativeLearningOpen) ||
        _passed ||
        !_step.isQuestion) {
      return;
    }
    final requests = LumoCompanionRequests.instance;
    requests.recordLearningEvent(LumoLearningEventKind.hintRequested);
    setState(() {
      _accompaniedSteps.add(_index);
      _helpLevel = differently
          ? math.max(2, _helpLevel + 1).clamp(1, 3)
          : (_helpLevel + 1).clamp(1, 3);
      _hideHelp = false;
      _previousHelp = (_helpLevel == 1
              ? GuidedLessonEvidence.hintForAnswer(
                  lesson: widget.lesson, step: _step, answer: _lastAnswer)
              : null) ??
          _step.help(level: _helpLevel);
    });
    _publish();
    requests.recordLearningEvent(LumoLearningEventKind.hintAccepted);
    _lumo.think();
    if (widget.appState.state.settings.autoReadEnabled &&
        widget.appState.state.settings.voiceEnabled &&
        !widget.appState.state.settings.calmMode) {
      unawaited(_read(_previousHelp!));
    }
  }

  void _easierPractice() {
    if (!_current || _busy || _progress.hasPending || _easier != null) return;
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.taskRepeated);
    setState(() {
      _accompaniedSteps.add(_index);
      _easier = widget.lesson.easierPractice;
    });
    _startStep();
  }

  void _replayExample() {
    if (!_current || _busy || _progress.hasPending) return;
    _coach.interrupt('replay');
    setState(() {
      _presentationStopped = false;
      _replay++;
    });
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.taskRepeated);
  }

  Future<void> _openLearningWorld() async {
    if (!_current || _busy || _progress.hasPending) return;
    final activity = NativeLearningActivity.fromLesson(widget.lesson, _step) ??
        (_published == null
            ? null
            : NativeLearningActivity.fromCompanionContext(_published!));
    if (activity == null) return;
    final serial = _serial;
    _cancelPresentation();
    setState(() {
      _busy = true;
      _nativeLearningOpen = true;
      // Requested solution support remains assistance even when Android's
      // return acknowledgement is interrupted after the child saw the model.
      _accompaniedSteps.add(_index);
      _helpLevel = math.max(1, _helpLevel);
    });
    _publish();
    try {
      await launchLumo3D(context,
          scene: 'learning',
          grade: widget.lesson.grade,
          subject: widget.lesson.subject,
          appState: widget.appState,
          learning: activity);
    } catch (_) {
      if (_current && _serial == serial) {
        setState(() => _feedback = 'Die 3D-Ansicht ist gerade nicht verfügbar. '
            'Du kannst mit den Lernobjekten hier weiterarbeiten.');
      }
    } finally {
      if (_current && _serial == serial) {
        setState(() {
          _busy = false;
          _nativeReturnPending = !_foreground;
          _nativeLearningOpen = !_foreground;
        });
        _publish();
      }
    }
  }

  Future<void> _next() async {
    if (!_current || _busy || !_passed || _progress.hasPending) return;
    if (_step.type == TutoringStepType.recap) {
      await Navigator.of(context).maybePop();
      return;
    }
    if (_easier != null) {
      setState(() => _easier = null);
      _startStep();
      return;
    }
    if (widget.discovery && _step.type == TutoringStepType.showExample) {
      setState(() => _busy = true);
      final saved = await _progress.saveDiscoveryIntroduction();
      if (!_current) return;
      setState(() => _busy = false);
      if (!saved) {
        setState(() => _blocked = 'Die Entdeckungsfreigabe wurde geändert. '
            'Deine bisherigen Daten bleiben erhalten.');
        return;
      }
    }
    setState(() => _index++);
    _startStep();
  }

  Future<void> _read(String text,
      {VoiceStyle style = VoiceStyle.explain}) async {
    if (!_current ||
        !_foreground ||
        _nativeLearningOpen ||
        !widget.appState.state.settings.voiceEnabled ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final sequence = ++_voiceSequence;
    _lastNarration = text;
    _pendingSyllable = null;
    _activeSyllable = null;
    try {
      final stopping = _voice.stop();
      final stopRequest = _voice.requestRevision;
      _voiceRequest = stopRequest;
      await stopping;
      if (!_current ||
          sequence != _voiceSequence ||
          _voice.requestRevision != stopRequest) {
        return;
      }
      await _playOwnedVoice(text, style: style);
    } catch (_) {
      // Voice owns its error status. The instruction remains readable and no
      // failed playback becomes a learning answer.
    } finally {
      if (sequence == _voiceSequence) {
        _voiceRequest = null;
      }
    }
  }

  void _stopOwnedVoice() {
    _voiceSequence++;
    _pendingSyllable = null;
    _activeSyllable = null;
    final request = _voiceRequest;
    _voiceRequest = null;
    if (request != null && _voice.requestRevision == request) {
      unawaited(_voice.stop());
    }
  }

  Future<void> _playOwnedVoice(String text,
      {VoiceStyle style = VoiceStyle.explain}) {
    final before = _voice.requestRevision;
    final playing = _voice.speakAndWait(text,
        style: style, speedFactor: _slowNarration ? .7 : 1);
    _voiceRequest =
        _voice.requestRevision == before ? null : _voice.requestRevision;
    _voiceChanged();
    return playing;
  }

  void _voiceChanged() {
    if (!_current) return;
    if (!_ownsVoice) {
      if (_activeSyllable != null) setState(() => _activeSyllable = null);
      return;
    }
    if (_voice.status.value == VoiceStatus.speaking) {
      _lumo.talk();
      if (_activeSyllable != _pendingSyllable) {
        setState(() => _activeSyllable = _pendingSyllable);
        if (_activeSyllable != null) {
          _coach.present(
              objectId: 'guided-spoken-syllable-$_activeSyllable',
              point: true,
              state: 'speaking');
        }
      }
    } else if (_voice.status.value == VoiceStatus.preparing) {
      _lumo.think();
      if (_activeSyllable != null) setState(() => _activeSyllable = null);
    } else if (_activeSyllable != null) {
      setState(() => _activeSyllable = null);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancelPresentation(discardCandidate: !_nativeLearningOpen);
      if (!_nativeLearningOpen) _coach.clear();
    } else {
      if (_nativeReturnPending) {
        _nativeReturnPending = false;
        _nativeLearningOpen = false;
      }
      _publish();
    }
  }

  Future<void> _readSyllables({int? only}) async {
    if (!_current ||
        !_foreground ||
        _nativeLearningOpen ||
        !_ready ||
        _busy ||
        !widget.appState.state.settings.voiceEnabled ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final parts = _step.syllables;
    if (parts.isEmpty || (only != null && (only < 0 || only >= parts.length))) {
      return;
    }
    if (_step.isQuestion) {
      _accompaniedSteps.add(_index);
      _helpLevel = math.max(1, _helpLevel);
      _publish();
    }
    final sequence = ++_voiceSequence;
    final serial = _serial;
    bool current() =>
        _current &&
        _foreground &&
        !_nativeLearningOpen &&
        _ownsVoice &&
        sequence == _voiceSequence &&
        serial == _serial &&
        widget.appState.state.settings.voiceEnabled &&
        ModalRoute.of(context)?.isCurrent != false;
    try {
      final stopping = _voice.stop();
      _voiceRequest = _voice.requestRevision;
      await stopping;
      if (!current()) return;
      for (final index in only == null
          ? List<int>.generate(parts.length, (i) => i)
          : <int>[only]) {
        if (!current()) return;
        _pendingSyllable = index;
        final completedBefore = _voice.completedPlaybackCount;
        await _playOwnedVoice(parts[index]);
        if (!current() ||
            _voice.completedPlaybackCount <= completedBefore) {
          break;
        }
      }
    } catch (_) {
      // Keep the word and all segments available when speech cannot play.
    } finally {
      if (sequence == _voiceSequence) {
        _voiceRequest = null;
        _pendingSyllable = null;
        _activeSyllable = null;
        if (mounted) setState(() {});
      }
    }
  }

  void _repeatExplanation() {
    if (!_current || (_busy && !_nativeLearningOpen) || _progress.hasPending) {
      return;
    }
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.taskRepeated);
    if (widget.lesson.concept == GuidedLessonConcept.syllables &&
        (!_step.isQuestion || _helpLevel >= 3)) {
      unawaited(_readSyllables());
    } else if (_tenFrameExample) {
      _replayExample();
    } else {
      unawaited(_read(_lastNarration ?? _previousHelp ?? _step.instruction));
    }
  }

  void _slowerExplanation() {
    if (!_current || (_busy && !_nativeLearningOpen)) return;
    _slowNarration = true;
    _repeatExplanation();
  }

  void _tryMyself() {
    if (!_current || _busy) return;
    _coach.interrupt('child_requested_independence');
    _cancelPresentation();
    setState(() {
      _hideHelp = true;
      _feedback = 'Du bist dran. Ich warte, bis du wieder Hilfe möchtest.';
    });
    // Never erase help already used for the later independent/assisted check.
    _publish();
    LumoCompanionRequests.instance
        .recordLearningEvent(LumoLearningEventKind.hintDeclined);
  }

  void _stopExplanation() {
    if (!_current) return;
    _cancelPresentation();
    setState(() => _feedback =
        'Die Erklärung ist angehalten. Deine Aufgabe bleibt erhalten.');
    _publish();
  }

  Widget _coachControls() {
    Widget control(
            String key, IconData icon, String label, VoidCallback? onPressed) =>
        OutlinedButton.icon(
          key: ValueKey(key),
          onPressed: _bound(onPressed),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
          icon: Icon(icon, size: 21),
          label: Text(label),
        );
    return Wrap(spacing: 8, runSpacing: 8, children: [
      if (!_step.isQuestion)
        control('guided-coach-help', Icons.lightbulb_outline, 'Hilf mir',
            _busy ? null : () => _coach.request(LumoLearningAction.hint)),
      control('guided-coach-repeat', Icons.replay_rounded, 'Noch einmal',
          _busy ? null : () => _coach.request(LumoLearningAction.repeat)),
      control(
          'guided-coach-slower',
          Icons.slow_motion_video_rounded,
          'Langsamer',
          _busy || !widget.appState.state.settings.voiceEnabled
              ? null
              : () => _coach.request(LumoLearningAction.slower)),
      control(
          'guided-coach-alternative',
          Icons.swap_horiz_rounded,
          'Anders erklären',
          _busy || (_passed && _step.isQuestion)
              ? null
              : () => _coach.request(LumoLearningAction.explain)),
      control('guided-coach-stop', Icons.stop_circle_outlined, 'Stopp',
          () => _coach.request(LumoLearningAction.stop)),
      control(
          'guided-coach-myself',
          Icons.touch_app_outlined,
          'Selbst versuchen',
          _busy
              ? null
              : () {
                  final captured = _coach.identity;
                  if (captured != null) _coach.tryMyself(captured);
                }),
      if (widget.appState.state.settings.voiceEnabled && !_tenFrameExample)
        control(
            'guided-coach-read',
            Icons.volume_up_rounded,
            'Vorlesen',
            _busy
                ? null
                : () => unawaited(
                    _read(_previousHelp ?? _feedback ?? _step.instruction))),
    ]);
  }

  bool _canLeave() {
    if (!_progress.hasPending) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wir speichern noch. '
            'Bitte versuche das Speichern bei Bedarf erneut.')));
    return false;
  }

  Future<void> _navigate(LumoSection section) async {
    final navigator = Navigator.of(context);
    if (section == LumoSection.learn) {
      await navigator.maybePop();
      return;
    }
    // Akademie -> hub -> lesson is a real nested route stack. Popping only the
    // lesson left the hub covering Games/Profile even after the section changed.
    final app = widget.appState;
    navigator.popUntil((route) => route.isFirst);
    app.setSection(section);
  }

  Widget _answerChoice(String answer) {
    final selected = _lastAnswer == answer && _lastCorrect != null;
    final correct = selected && _lastCorrect == true;
    final color = selected
        ? correct
            ? const Color(0xFF155A47)
            : const Color(0xFF693C69)
        : const Color(0xFF124A88);
    return Semantics(
      button: true,
      enabled: !_busy && !_passed,
      onTap: _bound(_busy || _passed ? null : () => unawaited(_answer(answer))),
      selected: selected,
      label: selected
          ? '$answer, ${correct ? "richtig" : "noch einmal versuchen"}'
          : answer,
      excludeSemantics: true,
      child: FilledButton(
        key: ValueKey('guided-answer-$answer'),
        onPressed:
            _bound(_busy || _passed ? null : () => unawaited(_answer(answer))),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color,
          disabledForegroundColor: Colors.white,
          textStyle: _body.copyWith(fontSize: 22),
          side: selected
              ? BorderSide(
                  color: correct
                      ? const Color(0xFF83EACD)
                      : const Color(0xFFEFC2E7),
                  width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(answer, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() => FilledButton.icon(
        key: const ValueKey('guided-continue'),
        onPressed: _bound(_busy ? null : () => unawaited(_next())),
        style: FilledButton.styleFrom(
            minimumSize: const Size(64, 56),
            backgroundColor: LumoVisualTokens.gold,
            foregroundColor: const Color(0xFF172844)),
        icon: Icon(_step.type == TutoringStepType.recap
            ? Icons.home_rounded
            : Icons.arrow_forward_rounded),
        label: Text(
            _step.type == TutoringStepType.recap
                ? 'Zur Lernübersicht'
                : _easier != null
                    ? 'Zurück zu meiner Aufgabe'
                    : 'Weiter',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );

  @override
  void dispose() {
    _coach.dispose();
    if (identical(
        LumoCompanionRequests.instance.taskContext.value, _published)) {
      LumoCompanionRequests.instance
          .cancelLearningInteraction(reason: 'page_exit');
    }
    WidgetsBinding.instance.removeObserver(this);
    widget.appState.removeListener(_profileChanged);
    LumoCompanionRequests.instance.helpRequested.removeListener(_legacyHelp);
    _voice.status.removeListener(_voiceChanged);
    _stopOwnedVoice();
    final task = _published;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => LumoCompanionRequests.instance.clearTask(task));
    _progress.removeListener(_saveChanged);
    _progress.dispose();
    _lumo.dispose();
    _stopSignal.dispose();
    _candidateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _stale || _blocked != null) {
      return Scaffold(
        backgroundColor: LumoVisualTokens.night,
        appBar: AppBar(
          backgroundColor: LumoVisualTokens.night,
          foregroundColor: LumoVisualTokens.white,
          title: Text(widget.lesson.title),
        ),
        body: LumoSceneBackground(
          scene: LumoScene.learning,
          showPlaceholderLabel: false,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LumoGlassCard(
                child: Column(children: [
                  Text(
                      _stale
                          ? 'Das Kinderprofil wurde gewechselt.'
                          : _blocked ?? 'Wir laden deinen Lernweg…',
                      style: _body),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Zur Lernübersicht'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    }
    final step = _step;
    final size = MediaQuery.sizeOf(context);
    final illustrationSerial = _serial;
    final settings = widget.appState.state.settings;
    final fixedContinue = size.width < 600 && size.height >= 480;
    return PopScope(
      canPop: !_progress.hasPending,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: widget.discovery ? 'Neues entdecken' : 'Lumo erklärt es mir',
        moduleTitle: widget.lesson.title,
        companionUnit: widget.lesson.schoolUnit,
        icon: widget.discovery ? Icons.explore_rounded : Icons.school_rounded,
        taskIndex: _index,
        totalTasks: widget.lesson.steps.length,
        progressLabel: 'Schritt',
        correctAnswers: _solved,
        correctCaption: 'gelöst',
        progressComplete: _completed,
        hasMistake: _lastCorrect == false,
        characterController: _lumo,
        guidance: 'Du gibst das Tempo vor.',
        mistakeGuidance: 'Wir probieren es gemeinsam.',
        canLeave: _canLeave,
        onNavigate: _navigate,
        scrollResetKey: _serial,
        footer: fixedContinue && _passed
            ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child:
                    SizedBox(width: double.infinity, child: _continueButton()))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(step.title,
                key: const ValueKey('guided-step-title'),
                style:
                    _body.copyWith(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
                step.type == TutoringStepType.showExample
                    ? switch (widget.lesson.concept) {
                        GuidedLessonConcept.bridgeTen =>
                          'Fülle zuerst den Zehner. Dann zähle die übrigen '
                              'Äpfel dazu.',
                        GuidedLessonConcept.equalGroups =>
                          'Gleiche Gruppen lassen sich als Plusrechnung '
                              'und als Malrechnung beschreiben.',
                        GuidedLessonConcept.subtractTen =>
                          'Nimm zuerst bis zehn weg. Nimm dann den Rest weg. '
                              'Zusammen sind es genau ${step.b} Äpfel.',
                        GuidedLessonConcept.syllables ||
                        GuidedLessonConcept.plantParts =>
                          step.instruction,
                        GuidedLessonConcept.bridgeHundred =>
                          'Ergänze zuerst zum nächsten Hunderter. Bündle zehn Zehner und gib den Rest dazu.',
                        GuidedLessonConcept.fractionParts =>
                          'Zähle gleich große Teile zusammen. Die Teilgröße und die untere Zahl bleiben gleich.',
                      }
                    : step.instruction,
                key: const ValueKey('guided-instruction'),
                style: _body),
            const SizedBox(height: 16),
            TickerMode(
              key: const ValueKey('guided-illustration'),
              enabled: !_presentationStopped && _foreground,
              child: _segmentedWord
                  ? SyllableLearningBoard(
                      word: step.word,
                      syllables: step.syllables,
                      segmentKeyPrefix: 'guided-spoken-syllable-',
                      wordPlaybackLabel: 'Silben vorsprechen',
                      activeIndex: _activeSyllable,
                      onReadSegment: settings.voiceEnabled
                          ? (index) => _bound(
                                  () => unawaited(_readSyllables(only: index)))
                              ?.call()
                          : null,
                      onReadWord: settings.voiceEnabled
                          ? _bound(() => unawaited(_readSyllables()))
                          : null,
                      reduceMotion: _quiet,
                    )
                  : GuidedMathIllustration(
                      key: ValueKey('guided-illustration-$_serial-$_replay'),
                      lesson: widget.lesson,
                      step: step,
                      stopSignal: _stopSignal,
                      autoNarrate: settings.voiceEnabled &&
                          settings.autoReadEnabled &&
                          !settings.calmMode,
                      onNarratePhase: settings.voiceEnabled
                          ? (text) async {
                              if (_serial == illustrationSerial &&
                                  _tenFrameExample) {
                                await _read(text);
                              }
                            }
                          : null,
                      onStopNarration: () {
                        // Disposing the old example must not stop the next task.
                        if (_serial == illustrationSerial) _stopOwnedVoice();
                      },
                      reduceMotion: _quiet),
            ),
            if (_published != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  key: const ValueKey('guided-open-3d'),
                  onPressed: _bound(_busy || _progress.hasPending
                      ? null
                      : () => unawaited(_openLearningWorld())),
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(48, 56)),
                  icon: const Icon(Icons.view_in_ar_rounded),
                  label: const Text('Mit Lumo in 3D ausprobieren'),
                ),
              ),
            if (step.type == TutoringStepType.showExample) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 8, children: [
                if (widget.lesson.concept != GuidedLessonConcept.bridgeTen)
                  OutlinedButton.icon(
                    onPressed: _bound(_replayExample),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Beispiel noch einmal'),
                  ),
                TextButton.icon(
                    onPressed: _bound(() =>
                        setState(() => _showExplanation = !_showExplanation)),
                    icon: Icon(_showExplanation
                        ? Icons.expand_less_rounded
                        : Icons.menu_book_rounded),
                    label: Text(_showExplanation
                        ? 'Erklärung einklappen'
                        : 'Erklärung lesen')),
              ]),
              if (_showExplanation)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(step.instruction, style: _body)),
            ],
            if (step.isQuestion) ...[
              const SizedBox(height: 16),
              LumoLessonAnswerGrid(
                crossAxisCount:
                    step.answerKind == GuidedAnswerKind.repeatedAddition ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.35
                        ? 1
                        : 2,
                children: [
                  for (final answer in _choices) _answerChoice(answer),
                ],
              ),
            ],
            if (_candidate != null) ...[
              const SizedBox(height: 12),
              LumoLessonSurface(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      'Ich habe „$_candidate“ verstanden. Prüfe den Vorschlag. '
                      'Du kannst auch eine Antwort oben antippen.',
                      key: const ValueKey('guided-candidate'),
                      style: _body),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('guided-candidate-edit'),
                    controller: _candidateController,
                    enabled: !_busy && !_passed,
                    maxLength: 160,
                    decoration: const InputDecoration(
                        labelText: 'Antwortvorschlag bearbeiten'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    key: const ValueKey('guided-confirm-candidate'),
                    onPressed:
                        _busy || _passed ? null : _bound(_confirmCandidate),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(48, 52)),
                    child: const Text('Diese Antwort bestätigen'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('guided-cancel-candidate'),
                    onPressed: _bound(() => setState(() {
                          _candidate = null;
                          _candidateIdentity = null;
                          _candidateController.clear();
                        })),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 52)),
                    child: const Text('Vorschlag verwerfen'),
                  ),
                ],
              )),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 12),
              Text(_feedback!,
                  key: const ValueKey('guided-feedback'), style: _body),
            ],
            if (_previousHelp != null && !_hideHelp) ...[
              const SizedBox(height: 12),
              LumoLessonSurface(
                child: Text(_previousHelp!,
                    key: const ValueKey('guided-actual-hint'), style: _body),
              ),
            ],
            if (_progress.hasPending) ...[
              const SizedBox(height: 12),
              Text(_progress.error ?? _progress.savingText, style: _body),
              if (_progress.error != null)
                FilledButton(
                    onPressed: _progress.saving ? null : _progress.retry,
                    child: const Text('Erneut speichern')),
            ],
            if (step.type == TutoringStepType.recap) ...[
              const SizedBox(height: 12),
              Text(
                  '$_independentSolved ${_independentSolved == 1 ? "neue Aufgabe" : "neue Aufgaben"} selbst gelöst. '
                  '${widget.discovery ? "Der Schulfortschritt bleibt getrennt." : "Hilfen und selbstständige Antworten werden getrennt erfasst."}',
                  style: _body),
            ],
            const SizedBox(height: 16),
            if (step.isQuestion && !_passed)
              Wrap(spacing: 10, runSpacing: 10, children: [
                OutlinedButton.icon(
                    onPressed: _bound(_busy
                        ? null
                        : () => _coach.request(LumoLearningAction.hint)),
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: Text(_helpLevel == 0 ? 'Tipp' : 'Anderer Tipp')),
                if (_easier == null)
                  OutlinedButton(
                      onPressed: _bound(_busy ? null : _easierPractice),
                      child: const Text('Leichter üben')),
              ]),
            if (_passed && !fixedContinue) _continueButton(),
            const SizedBox(height: 16),
            _coachControls(),
            if (!settings.voiceEnabled)
              const Text(
                  'Die Stimme ist ausgeschaltet. '
                  'Du kannst die Erklärung hier lesen.',
                  style: _body),
            ValueListenableBuilder<String?>(
              valueListenable: _voice.lastError,
              builder: (_, error, __) => error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error, style: _body)),
            ),
          ],
        ),
      ),
    );
  }
}
