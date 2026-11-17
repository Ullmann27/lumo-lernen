import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_state.dart';
import '../../core/school_exercise_generator.dart';
import '../../core/lumo_learning_session_contract.dart';
import '../../core/task_hint_service.dart';
import '../../core/writing_target_parser.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import '../../domain/tutoring/native_learning_activity.dart';
import '../lumo3d/lumo3d_launcher.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import 'adapters/legacy_lumo_task_adapter.dart';
import 'renderers/shape_trace_task_renderer.dart';
import 'renderers/writing_task_renderer.dart';
import 'widgets/interactive_task_workspace.dart';
import 'widgets/cross_grade_visual_scene.dart';
import '../../widgets/design/lumo_answer_crystal.dart';

/// Direct, offline, interactive lessons in a voluntarily selected school grade.
///
/// The optional app state supplies settings and the existing companion only.
/// Choosing a grade never changes enrolment or grants school-grade rewards.
/// Answers are stored in a separate, namespaced practice counter.
class CrossGradePracticeScreen extends StatefulWidget {
  const CrossGradePracticeScreen({
    super.key,
    required this.profileName,
    required this.enrolledGrade,
    required this.lessonGrade,
    required this.subject,
    required this.unit,
    this.appState,
  });

  final String profileName;
  final int enrolledGrade;
  final int lessonGrade;
  final String subject;
  final String unit;
  final LumoAppState? appState;

  @override
  State<CrossGradePracticeScreen> createState() =>
      _CrossGradePracticeScreenState();
}

class _CrossGradePracticeScreenState extends State<CrossGradePracticeScreen>
    with WidgetsBindingObserver {
  static const _adapter = LegacyLumoTaskAdapter();
  static const _hints = TaskHintService();
  late final ExerciseFactory _factory;
  late LumoTask _task;
  late TaskInstance _taskInstance;
  String? _taskError;
  String? _selected;
  String? _firstWrongChoice;
  bool? _lastCorrect;
  bool _practiceComplete = false;
  bool _quiet = false;
  bool _profileChanged = false;
  int? _profileGeneration;
  int _helpLevel = 0;
  int _loadSerial = 0;
  int _workspaceRevision = 0;
  bool _showSupport = false;
  String? _workspaceMessage;
  List<String> _workspaceObjectIds = const [];
  int _workspaceStep = 0;
  int _handledRequest = -1;
  bool _slow = false;
  bool _supportStopped = false;
  String? _activeObjectId;
  String? _speechSubtitle;
  final _proposalController = TextEditingController();
  bool _hasProposal = false;
  LumoLearningIdentity? _proposalIdentity;
  int _proposalToken = 0;
  bool _foreground = true, _nativeOpen = false, _nativeReturnPending = false;
  LumoCompanionTaskContext? _publishedContext;
  int _answered = 0;
  int _correct = 0;
  bool _progressLoaded = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  bool get _reduced =>
      _quiet ||
      widget.appState?.state.settings.reduceAnimations == true ||
      widget.appState?.state.settings.calmMode == true;

  bool get _canWork =>
      (_foreground || _nativeOpen) &&
      _progressLoaded &&
      !_profileChanged &&
      _loadError == null &&
      _taskError == null &&
      !_saving &&
      _selected == null &&
      !_practiceComplete;

  bool get _completed => _selected != null || _practiceComplete;

  String get _scope {
    // This lightweight local scope never changes the official profile grade.
    final safeName = widget.profileName.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9äöüß]+'),
          '_',
        );
    return 'cross_grade_practice_v1:${safeName.isEmpty ? 'kind' : safeName}:'
        '${widget.lessonGrade}:${widget.subject}:${widget.unit}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _factory = ExerciseFactory();
    _profileGeneration = widget.appState?.profileGeneration;
    widget.appState?.addListener(_checkProfile);
    LumoCompanionRequests.instance.helpRequested.addListener(_companionHelp);
    LumoCompanionRequests.instance.learningAction.addListener(_learningAction);
    LumoCompanionRequests.instance.learningPresentation
        .addListener(_learningPresentation);
    LumoCompanionRequests.instance.learningAudio.addListener(_learningAudio);
    _createTask();
    unawaited(_loadProgress());
  }

  @override
  void didUpdateWidget(covariant CrossGradePracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState?.removeListener(_checkProfile);
      widget.appState?.addListener(_checkProfile);
    }
    if (oldWidget.profileName != widget.profileName ||
        oldWidget.enrolledGrade != widget.enrolledGrade ||
        oldWidget.lessonGrade != widget.lessonGrade ||
        oldWidget.subject != widget.subject ||
        oldWidget.unit != widget.unit ||
        oldWidget.appState != widget.appState) {
      _loadSerial++;
      _profileGeneration = widget.appState?.profileGeneration;
      _profileChanged = false;
      _progressLoaded = false;
      _saving = false;
      _loadError = null;
      _saveError = null;
      _answered = 0;
      _correct = 0;
      _createTask();
      unawaited(_loadProgress());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadSerial++;
    widget.appState?.removeListener(_checkProfile);
    final requests = LumoCompanionRequests.instance;
    requests.helpRequested.removeListener(_companionHelp);
    requests.learningAction.removeListener(_learningAction);
    requests.learningPresentation.removeListener(_learningPresentation);
    requests.learningAudio.removeListener(_learningAudio);
    _proposalController.dispose();
    final published = _publishedContext;
    if (published != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (identical(requests.taskContext.value, published)) {
          requests.clearTask(published);
        }
      });
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (!_nativeOpen) {
        _stopSupport();
        LumoCompanionRequests.instance.clearTask(_publishedContext);
      }
      _foreground = false;
    } else {
      setState(() {
        _foreground = true;
        if (_nativeReturnPending) {
          _nativeOpen = false;
          _nativeReturnPending = false;
        }
      });
      _publishTask();
    }
  }

  void _checkProfile() {
    if (!mounted) return;
    final app = widget.appState;
    if (app != null &&
        (app.resetting || app.profileGeneration != _profileGeneration)) {
      setState(() => _profileChanged = true);
      return;
    }
    setState(() {});
  }

  void _createTask() {
    _selected = null;
    _lastCorrect = null;
    _practiceComplete = false;
    _firstWrongChoice = null;
    _helpLevel = 0;
    _showSupport = false;
    _workspaceRevision++;
    _workspaceMessage = null;
    _workspaceObjectIds = const [];
    _workspaceStep = 0;
    _activeObjectId = null;
    _speechSubtitle = null;
    _hasProposal = false;
    _proposalController.clear();
    _supportStopped = false;
    try {
      // The exact checked object owns the visible problem AND its answer.
      // Unknown topics never quietly turn into unrelated material.
      final next = _adapter.qualityCheckedTask(_factory.nextExact(
        grade: widget.lessonGrade,
        subject: widget.subject,
        unit: widget.unit,
      ));
      if (next.grade != widget.lessonGrade ||
          next.subject != widget.subject ||
          next.unit != widget.unit) {
        throw StateError('The task changed the requested learning scope');
      }
      _task = next;
      _taskInstance = _adapter.toTaskInstance(
        task: next,
        childId: _scope,
        difficulty: next.difficulty,
      );
      _taskError = null;
      _publishTask();
    } catch (_) {
      _taskError = 'Diese Aufgabe konnte nicht sicher vorbereitet werden. '
          'Bitte versuche es erneut oder wähle ein anderes Thema.';
    }
  }

  void _publishTask() {
    if (!_foreground && !_nativeOpen) return;
    if (widget.appState == null || _taskError != null || _profileChanged) {
      return;
    }
    final taskId = _taskInstance.taskInstanceId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _taskError != null ||
          (!_foreground && !_nativeOpen) ||
          _profileChanged ||
          _taskInstance.taskInstanceId != taskId ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      final value = LumoCompanionTaskContext(
        subject: _task.subject,
        unit: _task.unit,
        prompt: _task.prompt,
        taskId: taskId,
        attempts:
            (_firstWrongChoice == null ? 0 : 1) + (_selected == null ? 0 : 1),
        helpLevel: _helpLevel,
        answering: _canWork,
        lastAnswer: _selected ?? _firstWrongChoice,
        lastCorrect: _lastCorrect,
        localHelp:
            _hints.explain(_task, level: _helpLevel < 1 ? 1 : _helpLevel),
        activity: 'cross_grade_practice',
        ownerSection: 'learn',
        profileGeneration: _profileGeneration,
        stepId: '${_completed ? 'review' : 'work'}:$_workspaceStep',
        objectIds: [
          'cross-grade-question',
          for (var i = 0; i < _task.choices.length; i++)
            'cross-grade-choice-$i',
          ..._workspaceObjectIds,
        ],
        explanation: _workspaceMessage,
        errorType:
            _firstWrongChoice == null ? null : 'confirmed_answer_mismatch',
        answerChoices: _task.choices,
        allowedActions: {
          ...lumoDefaultLearningActions,
          if (_workspaceObjectIds.isNotEmpty) ...{
            LumoLearningAction.look,
            LumoLearningAction.point,
            LumoLearningAction.highlight,
          },
          if (_canWork && _task.choices.isNotEmpty)
            LumoLearningAction.proposeAnswer,
        },
        isExplanation: _showSupport && !_supportStopped,
      );
      _publishedContext = value;
      final requests = LumoCompanionRequests.instance;
      requests.publishTask(value);
      final identity = requests.learningIdentity.value;
      if (identity != null &&
          !_supportStopped &&
          _activeObjectId != null &&
          value.objectIds.contains(_activeObjectId)) {
        requests.publishLearningPresentation(LumoLearningPresentation(
          identity: identity,
          gazeObjectId: _activeObjectId,
          pointObjectId: _activeObjectId,
          expression: _lastCorrect == true ? 'pleased' : 'attentive',
          animationState: _showSupport ? 'explaining' : 'observing',
        ));
      }
    });
  }

  void _companionHelp() {
    if (!mounted ||
        !_canWork ||
        !identical(LumoCompanionRequests.instance.taskContext.value,
            _publishedContext) ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _requestHelp();
  }

  void _requestHelp() {
    if (!_canWork) return;
    setState(() {
      _helpLevel = (_helpLevel + 1).clamp(1, 3);
      _supportStopped = false;
      _showSupport = true;
      _workspaceMessage = _hints.explain(_task, level: _helpLevel);
    });
    _publishTask();
  }

  bool get _ownsCompanion =>
      mounted &&
      (_foreground || _nativeOpen) &&
      !_profileChanged &&
      _taskError == null &&
      identical(LumoCompanionRequests.instance.taskContext.value,
          _publishedContext) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _learningAction() {
    final requests = LumoCompanionRequests.instance;
    final action = requests.learningAction.value;
    if (!_ownsCompanion ||
        action == null ||
        !requests.isCurrentLearningIdentity(action.identity) ||
        action.requestId == _handledRequest) {
      return;
    }
    _handledRequest = action.requestId;
    if (action.action == LumoLearningAction.stop) {
      setState(() {
        _hasProposal = false;
        _proposalIdentity = null;
        _proposalController.clear();
        _supportStopped = true;
        _showSupport = false;
        _workspaceMessage = null;
        _activeObjectId = null;
        _speechSubtitle = null;
      });
      _publishTask();
      return;
    }
    if (!_canWork) return;
    switch (action.action) {
      case LumoLearningAction.hint:
      case LumoLearningAction.explain:
        _requestHelp();
      case LumoLearningAction.repeat:
        _repeatModel();
      case LumoLearningAction.slower:
        setState(() {
          _slow = true;
          _supportStopped = false;
          _workspaceMessage = 'Wir gehen langsam, Schritt für Schritt. '
              'Du bestimmst, wann du weiterarbeitest.';
        });
        _publishTask();
      case LumoLearningAction.proposeAnswer:
        // Recognition remains a visible, editable proposal. Only the child's
        // confirmation calls the existing, checked answer pathway.
        setState(() {
          _proposalToken++;
          _proposalIdentity = action.identity;
          _proposalController.text = action.candidate ?? '';
          _hasProposal = true;
        });
      case LumoLearningAction.look:
      case LumoLearningAction.point:
      case LumoLearningAction.highlight:
        setState(() {
          _activeObjectId = action.objectId;
          _supportStopped = false;
          if (action.action != LumoLearningAction.look) {
            _helpLevel = _helpLevel < 1 ? 1 : _helpLevel;
          }
        });
        _publishTask();
      case LumoLearningAction.stop:
        break;
    }
  }

  void _learningPresentation() {
    final requests = LumoCompanionRequests.instance;
    final presentation = requests.learningPresentation.value;
    if (!_ownsCompanion ||
        _supportStopped ||
        presentation == null ||
        !requests.isCurrentLearningIdentity(presentation.identity)) {
      return;
    }
    final id = presentation.pointObjectId ?? presentation.gazeObjectId;
    if (_activeObjectId != id) setState(() => _activeObjectId = id);
  }

  void _learningAudio() {
    final requests = LumoCompanionRequests.instance;
    final frame = requests.learningAudio.value;
    if (!_ownsCompanion ||
        _supportStopped ||
        frame == null ||
        !requests.isCurrentLearningIdentity(frame.identity)) {
      return;
    }
    // Actual player subtitles only; no invented word or syllable timings.
    if (_speechSubtitle != frame.subtitle) {
      setState(() => _speechSubtitle = frame.subtitle);
    }
  }

  void _stopSupport() {
    _hasProposal = false;
    _proposalIdentity = null;
    _proposalController.clear();
    if (_ownsCompanion) {
      LumoCompanionRequests.instance.cancelLearningInteraction();
    } else {
      setState(() {
        _supportStopped = true;
        _showSupport = false;
        _workspaceMessage = null;
        _activeObjectId = null;
        _speechSubtitle = null;
      });
    }
  }

  void _repeatModel() {
    if (!_canWork) return;
    setState(() {
      _workspaceRevision++;
      _supportStopped = false;
      _workspaceMessage = 'Beginne am Lernobjekt noch einmal. '
          'Deine Aufgabe bleibt dieselbe.';
    });
    _publishTask();
  }

  void _sendAction(LumoLearningAction action) {
    final requests = LumoCompanionRequests.instance;
    final identity = requests.learningIdentity.value;
    if (_ownsCompanion &&
        identity != null &&
        requests.requestLearningAction(action, identity: identity)) {
      return;
    }
    switch (action) {
      case LumoLearningAction.hint:
      case LumoLearningAction.explain:
        _requestHelp();
      case LumoLearningAction.repeat:
        _repeatModel();
      case LumoLearningAction.slower:
        setState(() => _slow = true);
      case LumoLearningAction.stop:
        _stopSupport();
      default:
        break;
    }
  }

  VoidCallback? _proposalConfirmation() {
    final identity = _proposalIdentity;
    final token = _proposalToken;
    if (!_hasProposal ||
        !_canWork ||
        identity == null ||
        _proposedChoice == null) return null;
    return () {
      if (!_hasProposal ||
          token != _proposalToken ||
          _proposalIdentity?.matches(identity) != true) return;
      final choice = _proposedChoice;
      if (choice == null) return;
      setState(() => _hasProposal = false);
      unawaited(_answer(choice));
    };
  }

  String? get _proposedChoice {
    final identity = _proposalIdentity;
    if (!_foreground ||
        _nativeOpen ||
        identity == null ||
        !LumoCompanionRequests.instance.isCurrentLearningIdentity(identity))
      return null;
    final proposed = _proposalController.text.trim().toLowerCase();
    final matches = _task.choices
        .where((choice) => choice.trim().toLowerCase() == proposed)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  Future<void> _loadProgress() async {
    final scope = _scope;
    final serial = ++_loadSerial;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Do not treat malformed history as a fresh profile. Keep both keys
      // untouched so the family can recover the existing local data.
      var answered = prefs.getInt('$scope:answered') ?? 0;
      var correct = prefs.getInt('$scope:correct') ?? 0;
      if (answered < 0 || correct < 0 || correct > answered) {
        throw const FormatException('Invalid existing practice counters');
      }
      // Existing counters retain their format. A separate write-ahead record
      // finishes only an already accepted answer after interruption.
      final pending = prefs.getString('$scope:pending_answer');
      if (pending != null) {
        final decoded = jsonDecode(pending);
        if (decoded is! Map<String, dynamic> ||
            decoded['answered'] is! int ||
            decoded['correct'] is! int) {
          throw const FormatException('Invalid pending practice answer');
        }
        final pendingAnswered = decoded['answered'] as int;
        final pendingCorrect = decoded['correct'] as int;
        if (pendingAnswered < 1 ||
            pendingCorrect < 0 ||
            pendingCorrect > pendingAnswered ||
            answered > pendingAnswered ||
            correct > pendingCorrect ||
            pendingAnswered - answered > 1 ||
            pendingCorrect - correct > 1) {
          throw const FormatException('Conflicting pending practice answer');
        }
        if (!await prefs.setInt('$scope:answered', pendingAnswered) ||
            !await prefs.setInt('$scope:correct', pendingCorrect) ||
            !await prefs.remove('$scope:pending_answer')) {
          throw StateError('The pending practice answer could not be saved');
        }
        answered = pendingAnswered;
        correct = pendingCorrect;
      }
      if (answered < 0 || correct < 0 || correct > answered) {
        throw const FormatException('Invalid existing practice counters');
      }
      if (!mounted || serial != _loadSerial || scope != _scope) return;
      setState(() {
        _answered = answered;
        _correct = correct;
        _progressLoaded = true;
        _loadError = null;
      });
      _publishTask();
    } catch (_) {
      if (!mounted || serial != _loadSerial || scope != _scope) return;
      setState(() {
        _progressLoaded = false;
        _loadError =
            'Der gespeicherte Lernstand konnte nicht sicher geladen werden. '
            'Deine bisherigen Daten bleiben unverändert.';
      });
    }
  }

  Future<void> _answer(String choice) async {
    if (!_foreground || _nativeOpen) return;
    if (!_canWork || !_task.choices.contains(choice)) return;
    if (choice == _firstWrongChoice) return;
    final correct = choice == _task.answer;
    // The first wrong attempt is unfinished: offer a hint, without writing
    // counters or disclosing the solution until the child tries again.
    if (!correct && _firstWrongChoice == null) {
      setState(() {
        _firstWrongChoice = choice;
        _helpLevel = _helpLevel < 1 ? 1 : _helpLevel;
        _showSupport = true;
        _workspaceMessage = _hints.explain(_task, level: _helpLevel);
      });
      _publishTask();
      return;
    }
    await _acceptAnswer(choice, correct);
  }

  Future<void> _acceptAnswer(String choice, bool correct) async {
    if (!_canWork) return;
    setState(() {
      _selected = choice;
      _lastCorrect = correct;
      _answered++;
      if (correct) _correct++;
      _saveError = null;
      _saving = true;
    });
    _publishTask();
    await _persistAcceptedAnswer();
  }

  void _writingAnswer(WritingTaskResult result) {
    if (!_canWork ||
        result.task.taskInstanceId != _taskInstance.taskInstanceId) {
      return;
    }
    if (result.skipped) {
      setState(_createTask);
      return;
    }
    final typed = result.typedAnswer;
    if (typed != null) {
      String clean(String value) =>
          value.trim().replaceAll(RegExp(r'\s+'), ' ');
      final target = WritingTargetParser.parse(_task.prompt);
      unawaited(_acceptAnswer(typed, clean(typed) == clean(target)));
    } else {
      // A real trainer attempt is practice. It has no fabricated ink grade.
      setState(() => _practiceComplete = true);
      _publishTask();
    }
  }

  void _shapeAnswer(ShapeTraceTaskResult result) {
    if (!_canWork ||
        result.task.taskInstanceId != _taskInstance.taskInstanceId) {
      return;
    }
    if (result.correct) {
      unawaited(_acceptAnswer(result.shape, true));
    } else {
      setState(() {
        _helpLevel = _helpLevel < 1 ? 1 : _helpLevel;
        _showSupport = true;
        _workspaceMessage = result.feedback;
      });
      _publishTask();
    }
  }

  /// Persist the already accepted answer. Retry calls this exact method
  /// without changing the counters, so an interrupted partial write cannot
  /// award a second attempt or alter the registered school profile.
  Future<void> _persistAcceptedAnswer() async {
    if (!mounted || !_progressLoaded || _selected == null) return;
    final answered = _answered;
    final correct = _correct;
    final scope = _scope;
    final serial = _loadSerial;
    bool saved = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Short-circuit on a rejected write rather than silently declaring
      // success; retry overwrites only the same target values.
      final staged = await prefs.setString(
          '$scope:pending_answer',
          jsonEncode({
            'answered': answered,
            'correct': correct,
          }));
      if (staged &&
          await prefs.setInt('$scope:answered', answered) &&
          await prefs.setInt('$scope:correct', correct)) {
        saved = await prefs.remove('$scope:pending_answer');
      }
    } catch (_) {
      saved = false;
    }
    if (!mounted || serial != _loadSerial || scope != _scope) return;
    setState(() {
      _saving = false;
      _saveError = saved
          ? null
          : 'Speichern nicht möglich. Bitte erneut versuchen. '
              'Die Antwort bleibt erhalten.';
    });
  }

  Future<void> _retrySave() async {
    if (_saving ||
        _saveError == null ||
        _selected == null ||
        !_progressLoaded) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    await _persistAcceptedAnswer();
  }

  void _next() {
    if (!_progressLoaded ||
        _saving ||
        _saveError != null ||
        !_completed ||
        _profileChanged) {
      return;
    }
    setState(_createTask);
  }

  String get _secondChanceHint {
    return _workspaceMessage ?? _hints.explain(_task, level: _helpLevel);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF62E5F4);
    if (_taskError != null) {
      return CrossGradeVisualScene(
        title: '${widget.lessonGrade}. Klasse · ${widget.subject}',
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.help_outline_rounded,
                color: Colors.white, size: 44),
            const SizedBox(height: 16),
            Text(_taskError!,
                key: const ValueKey('cross-grade-task-error'),
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('cross-grade-task-retry'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => setState(_createTask),
              icon: const Icon(Icons.refresh),
              label: const Text('Aufgabe erneut vorbereiten'),
            ),
          ]),
        )),
      );
    }
    final choices = _task.choices;
    final selected = _selected;
    return PopScope(
        canPop: !_saving,
        child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations:
                    _reduced || MediaQuery.of(context).disableAnimations),
            child: CrossGradeVisualScene(
              title: '${widget.lessonGrade}. Klasse · ${widget.subject}',
              body: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CrossGradeLumoHeader(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.lessonGrade}. Klasse · ${widget.unit}',
                              key: const ValueKey('cross-grade-unit'),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_learningGoal,
                                key:
                                    const ValueKey('cross-grade-learning-goal'),
                                style: const TextStyle(
                                    color: Color(0xFFB7F1FF),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(
                              'Frei üben · Dein Lernprofil bleibt in der '
                              '${widget.enrolledGrade}. Klasse.',
                              key: const ValueKey('cross-grade-profile-info'),
                              style: const TextStyle(color: Color(0xFFE2F1F8)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Extra-Übungen: $_answered · richtig: $_correct',
                              key: const ValueKey('cross-grade-counter'),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_progressLoaded) ...[
                              const SizedBox(height: 10),
                              CrossGradeProgressRibbon(
                                  answered: _answered, correct: _correct),
                            ],
                          ],
                        ),
                      ),
                      if (_profileChanged) ...[
                        const SizedBox(height: 12),
                        const Text(
                            'Das Lernprofil wurde gewechselt. Öffne die Übung '
                            'für das neue Profil erneut.',
                            key: ValueKey('cross-grade-profile-changed'),
                            style: TextStyle(
                                color: Color(0xFFFFD58D), fontSize: 16)),
                      ],
                      if (_loadError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          key: const ValueKey('cross-grade-load-error'),
                          style: const TextStyle(
                              color: Color(0xFFFFD58D),
                              fontWeight: FontWeight.w800),
                        ),
                        TextButton.icon(
                          key: const ValueKey('cross-grade-load-retry'),
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48)),
                          onPressed: () => unawaited(_loadProgress()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Lernstand erneut laden'),
                        ),
                      ] else if (!_progressLoaded) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text('Lernfortschritt wird geladen …',
                              key: ValueKey('cross-grade-loading'),
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                      const SizedBox(height: 22),
                      CrossGradeGlassPanel(
                          child: Text(
                        _task.prompt,
                        key: const ValueKey('cross-grade-question'),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                      const SizedBox(height: 16),
                      if (_taskInstance.taskType == TaskType.writingCanvas)
                        AbsorbPointer(
                          absorbing: !_canWork,
                          child: WritingTaskRenderer(
                              key: ValueKey(_taskInstance.taskInstanceId),
                              task: _taskInstance,
                              onSubmitted: _writingAnswer),
                        )
                      else if (_taskInstance.taskType == TaskType.shapeTrace)
                        AbsorbPointer(
                          absorbing: !_canWork,
                          child: ShapeTraceTaskRenderer(
                              key: ValueKey(_taskInstance.taskInstanceId),
                              task: _taskInstance,
                              onSubmitted: _shapeAnswer),
                        )
                      else ...[
                        InteractiveTaskWorkspace(
                          key: ValueKey(_taskInstance.taskInstanceId),
                          task: _taskInstance,
                          enabled: _canWork,
                          reduceMotion: _reduced || _supportStopped,
                          slow: _slow,
                          replaySerial: _workspaceRevision,
                          activeObjectId:
                              _supportStopped ? null : _activeObjectId,
                          showSolution: _completed,
                          helpLevel: _showSupport ? _helpLevel : 0,
                          onInteraction: (event) {
                            if (_nativeOpen || !_foreground) return;
                            if (_profileChanged ||
                                _taskError != null ||
                                event.taskId != _taskInstance.taskInstanceId) {
                              return;
                            }
                            setState(() {
                              if (event.isHelp) {
                                _helpLevel = _helpLevel < 1 ? 1 : _helpLevel;
                              }
                              if (!_supportStopped &&
                                  event.explanation.isNotEmpty) {
                                _workspaceMessage = event.explanation;
                              }
                              final ids = event.visibleState['objectIds'];
                              _workspaceObjectIds = ids is List
                                  ? ids.whereType<String>().toSet().toList()
                                  : const ['task-workspace'];
                              _activeObjectId =
                                  _workspaceObjectIds.contains(event.objectId)
                                      ? event.objectId
                                      : 'task-workspace';
                              _workspaceStep++;
                            });
                            _publishTask();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _learningControls(),
                      const SizedBox(height: 16),
                      if (_speechSubtitle?.isNotEmpty ?? false) ...[
                        Semantics(
                            liveRegion: true,
                            child: Text(_speechSubtitle!,
                                key: const ValueKey(
                                    'cross-grade-spoken-subtitle'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 17))),
                        const SizedBox(height: 12),
                      ],
                      if (_hasProposal && !_completed) ...[
                        _answerProposal(),
                        const SizedBox(height: 16),
                      ],
                      for (var i = 0; i < choices.length; i++) ...[
                        if (widget.subject == 'Mathematik' &&
                            choices[i].length <= 14)
                          SizedBox(
                            height: 110,
                            child: LumoAnswerCrystal(
                              buttonKey: ValueKey('cross-grade-choice-$i'),
                              label: choices[i],
                              fontSize: choices[i].length <= 5 ? 29 : 19,
                              state:
                                  selected != null && choices[i] == _task.answer
                                      ? LumoCrystalState.correct
                                      : choices[i] == _firstWrongChoice
                                          ? LumoCrystalState.retry
                                          : LumoCrystalState.neutral,
                              onPressed:
                                  _canWork && choices[i] != _firstWrongChoice
                                      ? () => _answer(choices[i])
                                      : null,
                            ),
                          )
                        else
                          OutlinedButton(
                            key: ValueKey('cross-grade-choice-$i'),
                            onPressed:
                                _canWork && choices[i] != _firstWrongChoice
                                    ? () => _answer(choices[i])
                                    : null,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              alignment: Alignment.centerLeft,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              backgroundColor:
                                  selected != null && choices[i] == _task.answer
                                      ? const Color(0xFF185848)
                                      : selected == choices[i] ||
                                              choices[i] == _firstWrongChoice
                                          ? const Color(0xFF593643)
                                          : const Color(0xFF123B65),
                              side: BorderSide(
                                color: selected != null &&
                                        choices[i] == _task.answer
                                    ? const Color(0xFF72F0B0)
                                    : accent.withOpacity(.75),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(choices[i],
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(height: 9),
                      ],
                      if (_completed ||
                          _firstWrongChoice != null ||
                          _workspaceMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _practiceComplete
                              ? 'Schreibübung abgeschlossen. Gut geübt!'
                              : selected == null
                                  ? _secondChanceHint
                                  : _lastCorrect == true
                                      ? _helpLevel > 0
                                          ? 'Richtig! Mit Hilfe geschafft.'
                                          : 'Richtig! Gut gemacht!'
                                      : 'Die richtige Antwort ist: ${_task.answer}',
                          key: const ValueKey('cross-grade-feedback'),
                          style: TextStyle(
                            color: _lastCorrect == true || _practiceComplete
                                ? const Color(0xFF77F0B8)
                                : const Color(0xFFFFD58D),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_completed)
                          CrossGradeGlassPanel(
                              child: Text(
                            _task.explanation,
                            key: const ValueKey('cross-grade-explanation'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, height: 1.4),
                          )),
                        if (_saveError != null) ...[
                          const SizedBox(height: 12),
                          Text(_saveError!,
                              key: const ValueKey('cross-grade-save-error'),
                              style: const TextStyle(
                                  color: Color(0xFFFFD58D),
                                  fontWeight: FontWeight.w800)),
                          TextButton.icon(
                              key: const ValueKey('cross-grade-save-retry'),
                              style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48)),
                              onPressed: _saving ? null : _retrySave,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Erneut speichern')),
                        ],
                        if (_saving)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text('Antwort wird gespeichert …',
                                key: ValueKey('cross-grade-saving'),
                                style: TextStyle(color: Colors.white70)),
                          ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const ValueKey('cross-grade-next'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16B9D7),
                            foregroundColor: const Color(0xFF07223C),
                            minimumSize: const Size.fromHeight(54),
                          ),
                          onPressed: !_completed
                              ? null
                              : (!_saving &&
                                      _saveError == null &&
                                      _progressLoaded &&
                                      !_profileChanged
                                  ? _next
                                  : null),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Nächste Aufgabe',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )));
  }

  String get _learningGoal {
    final subject = widget.subject;
    if (subject == 'Mathematik') {
      return 'Lernziel: ${Curriculum.prettifyUnit(widget.unit)} verstehen und selbst lösen.';
    }
    if (subject == 'Logik') {
      return 'Lernziel: Regeln erkennen und deine Auswahl prüfen.';
    }
    if (subject == 'Lesen') {
      return 'Lernziel: genau lesen und die Antwort im Text finden.';
    }
    if (subject == 'Schreiben') {
      return 'Lernziel: deine Vorlage aufmerksam schreiben.';
    }
    if (subject == 'Sachunterricht') {
      return 'Lernziel: Zusammenhänge beobachten und erklären.';
    }
    return 'Lernziel: ${Curriculum.prettifyUnit(widget.unit)} erkennen und anwenden.';
  }

  Future<void> _openNativeLearning() async {
    final app = widget.appState;
    final bus = LumoCompanionRequests.instance;
    final before = bus.learningIdentity.value;
    if (app == null ||
        !_canWork ||
        !_ownsCompanion ||
        _nativeOpen ||
        before == null) return;
    final taskId = _taskInstance.taskInstanceId;
    _hasProposal = false;
    _proposalIdentity = null;
    _requestHelp();
    // The workspace announces its changed explanation after rendering. Its
    // owner publishes that semantic step on the following frame; capture the
    // launch only after both have reached the shared contract.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final current = bus.learningIdentity.value;
    if (!mounted ||
        !_foreground ||
        !_canWork ||
        !_ownsCompanion ||
        taskId != _taskInstance.taskInstanceId ||
        current == null ||
        before.sessionId != current.sessionId ||
        before.taskId != current.taskId ||
        current.cancelEpoch - before.cancelEpoch !=
            current.revision - before.revision) return;
    setState(() => _nativeOpen = true);
    try {
      await launchLumo3D(context,
          scene: 'learning',
          appState: app,
          subject: widget.subject,
          learning: NativeLearningActivity.forTask(_taskInstance));
    } finally {
      if (mounted && taskId == _taskInstance.taskInstanceId) {
        setState(() {
          _nativeReturnPending = !_foreground;
          _nativeOpen = !_foreground;
        });
        _publishTask();
      }
    }
  }

  Widget _learningControls() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (widget.appState != null)
            OutlinedButton.icon(
              key: const ValueKey('cross-grade-native-learning'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white),
              onPressed: _canWork && !_nativeOpen
                  ? () => unawaited(_openNativeLearning())
                  : null,
              icon: const Icon(Icons.view_in_ar_rounded),
              label: const Text('Mit Lumo in 3D'),
            ),
          OutlinedButton.icon(
            key: const ValueKey('cross-grade-help'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: const Color(0xFFFFD58D)),
            onPressed: _canWork
                ? () => _sendAction(_helpLevel == 0
                    ? LumoLearningAction.hint
                    : LumoLearningAction.explain)
                : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(_helpLevel == 0 ? 'Hilf mir' : 'Anders erklären'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('cross-grade-repeat-model'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: Colors.white),
            onPressed:
                _canWork ? () => _sendAction(LumoLearningAction.repeat) : null,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Noch einmal'),
          ),
          if (_showSupport)
            OutlinedButton.icon(
              key: const ValueKey('cross-grade-self-try'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white),
              onPressed: _canWork ? _stopSupport : null,
              icon: const Icon(Icons.touch_app_rounded),
              label: const Text('Selbst versuchen'),
            ),
          OutlinedButton.icon(
            key: const ValueKey('cross-grade-slower'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: Colors.white),
            onPressed:
                _canWork ? () => _sendAction(LumoLearningAction.slower) : null,
            icon: const Icon(Icons.slow_motion_video_rounded),
            label: Text(_slow ? 'Langsam aktiv' : 'Langsamer'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('cross-grade-stop'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: Colors.white),
            onPressed: _stopSupport,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Stopp'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('cross-grade-quiet'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: Colors.white),
            onPressed: () => setState(() => _quiet = !_quiet),
            icon: Icon(_reduced
                ? Icons.pause_circle_outline
                : Icons.motion_photos_off_outlined),
            label: Text(_reduced ? 'Ruhiger Modus aktiv' : 'Ruhiger Modus'),
          ),
        ],
      );

  Widget _answerProposal() => CrossGradeGlassPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Habe ich dich richtig verstanden?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
              key: const ValueKey('cross-grade-answer-proposal'),
              controller: _proposalController,
              enabled: _canWork,
              maxLength: 160,
              style: const TextStyle(color: Colors.white, fontSize: 19),
              decoration: const InputDecoration(
                  labelText: 'Erkannte Antwort – du kannst sie ändern',
                  labelStyle: TextStyle(color: Color(0xFFB7F1FF))),
              onChanged: (_) => setState(() {})),
          const Text(
              'Erst deine Bestätigung zählt. Du kannst auch eine '
              'Antwort darunter antippen.',
              style: TextStyle(color: Color(0xFFB7F1FF), height: 1.4)),
          const SizedBox(height: 8),
          FilledButton.icon(
              key: const ValueKey('cross-grade-proposal-confirm'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _proposalConfirmation(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Diese Antwort bestätigen')),
          TextButton(
              key: const ValueKey('cross-grade-proposal-dismiss'),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Colors.white),
              onPressed: () => setState(() => _hasProposal = false),
              child: const Text('Ich wähle selbst')),
        ]),
      );
}
