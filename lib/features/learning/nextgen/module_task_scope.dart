import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/learning_attempt_id.dart';
import '../../../core/lumo_learning_session_contract.dart';
import '../../../core/lumo_voice.dart';
import '../../../domain/tutoring/native_learning_activity.dart';
import '../../lumo3d/lumo3d_launcher.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';
import '../../learning_modules/learning_module_progress.dart';

/// A presentation adapter for an existing, independently assessed module.
///
/// Place this inside the learning module frame's child. The frame owns
/// beginPresentedTask; this adapter never resets that assistance boundary.
/// Proposals are presentation-only until explicit confirmation forwards an
/// offered choice index to the module. Domain evaluation and saving stay there.
class ModuleTaskScope extends StatefulWidget {
  const ModuleTaskScope({
    super.key,
    required this.appState,
    required this.progress,
    required this.moduleId,
    required this.taskKey,
    required this.prompt,
    required this.objective,
    required this.answerChoices,
    required this.helpSteps,
    required this.child,
    this.answering = true,
    this.lastAnswer,
    this.lastCorrect,
    this.onConfirmChoice,
  }) : assert(helpSteps.length > 0 && helpSteps.length <= 5);

  final LumoAppState appState;
  final LearningModuleProgress progress;
  final String moduleId;
  final Object taskKey;
  final String prompt;
  final String objective;
  final List<String> answerChoices;
  final List<String> helpSteps;
  final bool answering;
  final String? lastAnswer;
  final bool? lastCorrect;

  /// Invoked only after the child confirms one uniquely matched visible choice.
  /// The module still owns correctness, progress and the durable save.
  final ValueChanged<int>? onConfirmChoice;
  final Widget child;

  /// This ID is backed by the actual visible exercise container below.
  static const taskObjectId = 'module_task';

  @override
  State<ModuleTaskScope> createState() => _ModuleTaskScopeState();
}

class _ModuleTaskScopeState extends State<ModuleTaskScope>
    with WidgetsBindingObserver {
  final _requests = LumoCompanionRequests.instance;
  late final int _profileGeneration = widget.appState.profileGeneration;
  late final String _session = newLearningAttemptId();
  LumoCompanionTaskContext? _published;
  int _taskRevision = 0;
  int _publishRevision = 0;
  int _speechEpoch = 0;
  int _handledAction = -1;
  int _helpIndex = -1;
  int _helpLevel = 0;
  bool _showHelp = false;
  bool _focused = false;
  bool _speaking = false;
  bool _foreground = true;
  bool _routeCurrent = true;
  bool _invalid = false;
  bool _nativeLearningOpen = false;
  bool _nativeReturnPending = false;
  final _candidateController = TextEditingController();
  final _candidateAnchor = GlobalKey();
  LumoLearningIdentity? _candidateIdentity;
  String? _candidateNotice;
  String? _nativeNotice;

  bool get _safe =>
      mounted &&
      !_invalid &&
      (_foreground || _nativeLearningOpen) &&
      _routeCurrent &&
      !widget.appState.resetting &&
      widget.appState.profileGeneration == _profileGeneration;

  bool get _canHelp => _safe && widget.answering && !widget.progress.hasPending;
  bool get _canPropose =>
      _canHelp &&
      widget.onConfirmChoice != null &&
      widget.answerChoices.isNotEmpty;
  bool get _ownsTask =>
      _published != null && identical(_requests.taskContext.value, _published);
  String? get _explanation =>
      _showHelp && _helpIndex >= 0 ? widget.helpSteps[_helpIndex] : null;

  @override
  void initState() {
    super.initState();
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    widget.appState.addListener(_checkProfile);
    _requests.helpRequested.addListener(_requestedHelp);
    _requests.learningAction.addListener(_requestedAction);
    _requests.learningCancellation.addListener(_cancelled);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _schedulePublish();
  }

  @override
  void didUpdateWidget(covariant ModuleTaskScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskKey != widget.taskKey ||
        oldWidget.moduleId != widget.moduleId) {
      _taskRevision++;
      _discardCandidate(rebuild: false);
      _nativeNotice = null;
      _helpIndex = -1;
      _helpLevel = 0;
      _showHelp = false;
      _focused = false;
      // The module may already have started the new task's own voice line.
      // Invalidate our pending work without stopping that newer narration.
      _cancelNarration(stopPlayer: false);
    } else if (oldWidget.answering && !widget.answering) {
      _discardCandidate(rebuild: false);
      _focused = false;
      _cancelNarration(stopPlayer: false);
    }
    _schedulePublish();
  }

  void _checkProfile() {
    if (widget.appState.resetting ||
        widget.appState.profileGeneration != _profileGeneration) {
      _invalid = true;
      _cancelNarration();
      _requests.clearTask(_published);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancelNarration();
      if (!_nativeLearningOpen) {
        _discardCandidate();
        _requests.clearTask(_published);
      }
    } else {
      if (_nativeReturnPending) {
        _nativeReturnPending = false;
        _nativeLearningOpen = false;
      }
      _schedulePublish();
    }
  }

  void _schedulePublish() {
    final revision = ++_publishRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _publishRevision) return;
      _publish();
    });
  }

  void _publish() {
    if (!_safe) {
      _cancelNarration();
      _discardCandidate();
      _requests.clearTask(_published);
      return;
    }
    final task = LumoCompanionTaskContext(
      taskId: '${widget.moduleId}:$_session:$_taskRevision',
      subject: widget.progress.subject,
      unit: widget.progress.unit,
      prompt: widget.prompt,
      answering: widget.answering && !widget.progress.hasPending,
      attempts: widget.lastCorrect == null ? 0 : 1,
      helpLevel: _helpLevel,
      lastAnswer: widget.lastAnswer,
      lastCorrect: widget.lastCorrect,
      previousHelp: _helpIndex > 0 ? widget.helpSteps[_helpIndex - 1] : null,
      localHelp: _explanation,
      activity: 'learning_module',
      ownerSection: 'learn',
      profileGeneration: _profileGeneration,
      stepId: _showHelp ? 'help_${_helpIndex + 1}' : 'answer',
      objectIds: const [ModuleTaskScope.taskObjectId],
      explanation: _explanation,
      answerChoices: List.unmodifiable(widget.answerChoices),
      allowedActions: {
        ...lumoDefaultLearningActions,
        if (_canPropose) LumoLearningAction.proposeAnswer,
        LumoLearningAction.look,
        LumoLearningAction.point,
        LumoLearningAction.highlight,
      },
      isExplanation: _showHelp,
    );
    if (_ownsTask && _published?.semanticKey == task.semanticKey) return;
    _published = task;
    _requests.publishTask(task);
  }

  void _requestedHelp() {
    if (_ownsTask) _nextHelp();
  }

  void _requestedAction() {
    final request = _requests.learningAction.value;
    if (request == null ||
        request.requestId == _handledAction ||
        !_safe ||
        !_ownsTask ||
        !_requests.isCurrentLearningIdentity(request.identity)) {
      return;
    }
    _handledAction = request.requestId;
    switch (request.action) {
      case LumoLearningAction.explain:
      case LumoLearningAction.hint:
        _nextHelp();
      case LumoLearningAction.repeat:
        _repeat();
      case LumoLearningAction.slower:
        _repeat(slower: true);
      case LumoLearningAction.stop:
        _cancelNarration();
        // The explicit task-owned stop also stops the module's own prompt.
        unawaited(LumoVoice.instance.stop());
        _discardCandidate();
        setState(() => _focused = false);
      case LumoLearningAction.look:
      case LumoLearningAction.point:
      case LumoLearningAction.highlight:
        if (request.objectId == ModuleTaskScope.taskObjectId) {
          setState(() => _focused = true);
          _pointAtTask();
        }
      case LumoLearningAction.proposeAnswer:
        final candidate = request.candidate;
        if (candidate != null) _proposeAnswer(candidate, request.identity);
    }
  }

  void _discardCandidate({bool rebuild = true}) {
    if (_candidateIdentity == null &&
        _candidateController.text.isEmpty &&
        _candidateNotice == null) {
      return;
    }
    void clear() {
      _candidateIdentity = null;
      _candidateController.clear();
      _candidateNotice = null;
    }

    if (rebuild && mounted) {
      setState(clear);
    } else {
      clear();
    }
  }

  void _cancelled() {
    if (_candidateIdentity != null &&
        !_requests.isCurrentLearningIdentity(_candidateIdentity!)) {
      _discardCandidate();
    }
    _cancelNarration();
  }

  void _proposeAnswer(String candidate, LumoLearningIdentity identity) {
    if (!_canPropose ||
        !_ownsTask ||
        candidate.trim().isEmpty ||
        candidate.length > 160) {
      return;
    }
    setState(() {
      _candidateIdentity = identity;
      _candidateController.text = candidate.trim();
      _candidateNotice = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = _candidateAnchor.currentContext;
      if (mounted &&
          _foreground &&
          !_nativeLearningOpen &&
          _candidateIdentity != null &&
          anchor != null) {
        unawaited(Scrollable.ensureVisible(anchor, duration: Duration.zero));
      }
    });
  }

  VoidCallback? _boundCandidateConfirmation() {
    final captured = _candidateIdentity;
    if (captured == null) return null;
    return () {
      if (_candidateIdentity?.matches(captured) != true) return;
      _confirmCandidate();
    };
  }

  void _confirmCandidate() {
    final identity = _candidateIdentity;
    if (!_canPropose ||
        !_foreground ||
        _nativeLearningOpen ||
        !_ownsTask ||
        identity == null ||
        !_requests.isCurrentLearningIdentity(identity)) {
      return;
    }
    final candidate = _candidateController.text.trim().toLowerCase();
    final indices = [
      for (var i = 0; i < widget.answerChoices.length; i++)
        if (widget.answerChoices[i].trim().toLowerCase() == candidate) i,
    ];
    if (indices.length != 1) {
      setState(() =>
          _candidateNotice = 'Das passt noch nicht eindeutig zu einer Antwort. '
              'Ändere den Vorschlag oder tippe auf eine Antwortkarte.');
      return;
    }
    final confirm = widget.onConfirmChoice!;
    _discardCandidate();
    _cancelNarration();
    confirm(indices.single);
  }

  Future<void> _openNativeLearning() async {
    if (!_canHelp || !_ownsTask || _nativeLearningOpen) return;
    final revision = _taskRevision;
    _discardCandidate();
    _cancelNarration();
    // The local hint is visible before I/O; the same attempt is already marked
    // assisted if the Android explanation is closed or interrupted later.
    final level = _helpLevel < 1 ? 1 : _helpLevel;
    widget.progress.notePresentationHelp(level: level);
    setState(() {
      _nativeLearningOpen = true;
      _nativeReturnPending = false;
      _nativeNotice = null;
      _helpIndex = _helpIndex < 0 ? 0 : _helpIndex;
      _helpLevel = level;
      _showHelp = true;
    });
    _publish();
    final task = _published;
    final activity =
        task == null ? null : NativeLearningActivity.fromCompanionContext(task);
    try {
      if (activity == null) return;
      await launchLumo3D(context,
          scene: 'learning',
          appState: widget.appState,
          subject: widget.progress.subject,
          learning: activity);
    } catch (_) {
      if (mounted && revision == _taskRevision) {
        setState(
            () => _nativeNotice = 'Die 3D-Ansicht ist gerade nicht verfügbar. '
                'Du kannst mit dieser Aufgabe weiterarbeiten.');
      }
    } finally {
      if (mounted && revision == _taskRevision) {
        setState(() {
          _nativeReturnPending = !_foreground;
          _nativeLearningOpen = !_foreground;
        });
        _publish();
      }
    }
  }

  void _nextHelp() {
    if (!_canHelp) return;
    final index = (_helpIndex + 1).clamp(0, widget.helpSteps.length - 1);
    // This happens synchronously before the text or voice can reveal a hint.
    widget.progress.notePresentationHelp(level: index + 1);
    setState(() {
      _helpIndex = index;
      _helpLevel = index + 1;
      _showHelp = true;
      _focused = true;
    });
    _publish();
    _requests.recordLearningEvent(LumoLearningEventKind.hintRequested,
        context: _published);
    _pointAtTask();
    unawaited(_narrate(widget.helpSteps[index]));
  }

  void _pointAtTask() {
    final identity = _requests.learningIdentity.value;
    if (identity == null || !_ownsTask) return;
    _requests.publishLearningPresentation(LumoLearningPresentation(
      identity: identity,
      gazeObjectId: ModuleTaskScope.taskObjectId,
      pointObjectId: ModuleTaskScope.taskObjectId,
      expression: 'attentive',
      animationState: 'explaining',
    ));
  }

  void _repeat({bool slower = false}) {
    if (!_safe || !widget.answering) return;
    // Repeating or slowing the same explanation never advances the hint.
    _requests.recordLearningEvent(LumoLearningEventKind.taskRepeated,
        context: _published);
    unawaited(_narrate(_explanation ?? widget.prompt, slower: slower));
  }

  Future<void> _narrate(String text, {bool slower = false}) async {
    if (!_safe || !widget.appState.state.settings.voiceEnabled) return;
    final epoch = ++_speechEpoch;
    final voice = LumoVoice.instance;
    _speaking = true;
    try {
      final rate = widget.appState.state.settings.voiceRate;
      await voice.configure(rate: slower ? rate * .7 : rate);
      if (!_safe || epoch != _speechEpoch) return;
      await voice.speakAndWait(text, style: VoiceStyle.explain);
    } finally {
      if (epoch == _speechEpoch) {
        _speaking = false;
        await voice.configure(rate: widget.appState.state.settings.voiceRate);
      }
    }
  }

  void _cancelNarration({bool stopPlayer = true}) {
    ++_speechEpoch;
    if (!_speaking) return;
    _speaking = false;
    if (stopPlayer) unawaited(LumoVoice.instance.stop());
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
  }

  void _selfTry() {
    if (!_safe) return;
    _requests.recordLearningEvent(LumoLearningEventKind.hintDeclined,
        context: _published);
    _requests.cancelLearningInteraction(reason: 'self_try');
    _cancelNarration();
    setState(() {
      _showHelp = false;
      _focused = false;
    });
    // The help level remains part of this attempt after hiding the panel.
    _publish();
  }

  @override
  void dispose() {
    ++_publishRevision;
    _cancelNarration();
    widget.appState.removeListener(_checkProfile);
    _requests.helpRequested.removeListener(_requestedHelp);
    _requests.learningAction.removeListener(_requestedAction);
    _requests.learningCancellation.removeListener(_cancelled);
    _candidateController.dispose();
    final owned = _published;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _requests.clearTask(owned));
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _action(String label, IconData icon, VoidCallback? onPressed,
      {String? id}) {
    return TextButton.icon(
      key: id == null ? null : ValueKey(id),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: LumoVisualTokens.white,
        disabledForegroundColor: LumoVisualTokens.white.withValues(alpha: .45),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: const ValueKey(ModuleTaskScope.taskObjectId),
          identifier: ModuleTaskScope.taskObjectId,
          container: true,
          label: 'Aktuelle Lernaufgabe',
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: _focused ? LumoVisualTokens.cyan : Colors.transparent,
                  width: 2),
            ),
            child: widget.child,
          ),
        ),
        if (_candidateIdentity != null) ...[
          const SizedBox(height: 12),
          LearningAnswerCandidateCard(
            key: _candidateAnchor,
            keyPrefix: 'module',
            controller: _candidateController,
            notice: _candidateNotice,
            onConfirm: _canPropose ? _boundCandidateConfirmation() : null,
            onDiscard: _discardCandidate,
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('module-open-3d'),
          onPressed: _canHelp && !_nativeLearningOpen
              ? () => unawaited(_openNativeLearning())
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
          icon: const Icon(Icons.view_in_ar_rounded),
          label: const Text('Mit Lumo in 3D ausprobieren'),
        ),
        if (_nativeNotice != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_nativeNotice!,
                  style: const TextStyle(color: LumoVisualTokens.white))),
        const SizedBox(height: 12),
        Text(widget.objective,
            key: const ValueKey('module-learning-objective'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: LumoVisualTokens.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_showHelp) ...[
          Container(
            key: const ValueKey('module-help-panel'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: LumoVisualTokens.lessonPanel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LumoVisualTokens.cyan)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lumos Hinweis ${_helpIndex + 1}',
                    style: const TextStyle(
                        color: LumoVisualTokens.cyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(_explanation!,
                      key: const ValueKey('module-help-text'),
                      style: const TextStyle(
                          color: LumoVisualTokens.white,
                          height: 1.5,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                const Text('Jetzt kannst du selbst weiterarbeiten.',
                    style: TextStyle(
                        color: LumoVisualTokens.white,
                        height: 1.4,
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            _action(_showHelp ? 'Anders erklären' : 'Hilf mir',
                Icons.lightbulb_outline_rounded, _canHelp ? _nextHelp : null,
                id: 'module-task-help'),
            _action('Noch einmal', Icons.replay_rounded,
                _safe && widget.answering ? _repeat : null,
                id: 'module-task-repeat'),
            _action('Langsamer', Icons.slow_motion_video_rounded,
                _safe && widget.answering ? () => _repeat(slower: true) : null,
                id: 'module-task-slower'),
            if (_showHelp)
              _action('Selbst versuchen', Icons.touch_app_rounded, _selfTry,
                  id: 'module-task-self-try'),
            _action('Stopp', Icons.stop_circle_outlined, () {
              _requests.cancelLearningInteraction();
              _cancelNarration();
            }, id: 'module-task-stop'),
          ],
        ),
      ],
    );
  }
}

/// Shared visible confirmation surface; this widget never evaluates an answer.
class LearningAnswerCandidateCard extends StatelessWidget {
  const LearningAnswerCandidateCard(
      {super.key,
      required this.keyPrefix,
      required this.controller,
      required this.onConfirm,
      required this.onDiscard,
      this.notice});

  final String keyPrefix;
  final TextEditingController controller;
  final VoidCallback? onConfirm;
  final VoidCallback onDiscard;
  final String? notice;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: LumoVisualTokens.lessonPanel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LumoVisualTokens.cyan, width: 2)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Habe ich dich richtig verstanden?',
              style: TextStyle(
                  color: LumoVisualTokens.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'Du kannst den Vorschlag ändern. Erst dein Bestätigen zählt.',
              style: TextStyle(color: LumoVisualTokens.white, height: 1.4)),
          const SizedBox(height: 12),
          TextField(
              key: ValueKey('$keyPrefix-answer-candidate'),
              controller: controller,
              maxLength: 160,
              style: const TextStyle(color: Color(0xFF12366A), fontSize: 20),
              decoration: const InputDecoration(
                  labelText: 'Deine Antwort',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder())),
          if (notice != null)
            Text(notice!,
                style: const TextStyle(color: LumoVisualTokens.white)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
                key: ValueKey('$keyPrefix-confirm-candidate'),
                onPressed: onConfirm,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Diese Antwort bestätigen')),
            OutlinedButton(
                key: ValueKey('$keyPrefix-discard-candidate'),
                onPressed: onDiscard,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    foregroundColor: LumoVisualTokens.white),
                child: const Text('Verwerfen')),
          ]),
        ]),
      );
}
