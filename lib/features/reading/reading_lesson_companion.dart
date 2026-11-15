import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/lumo_companion_host.dart';
import '../../core/lumo_learning_session_contract.dart';
import '../../core/lumo_voice.dart';
import '../../domain/tutoring/native_learning_activity.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../learning/nextgen/learning_coach_binding.dart';
import '../lumo3d/lumo3d_launcher.dart';

/// Reading presentation over the shared task/action protocol. The owning
/// reading screen alone accepts answers and persists learning evidence.
class ReadingLessonCompanion extends StatefulWidget {
  const ReadingLessonCompanion({
    super.key,
    required this.appState,
    required this.taskId,
    required this.unit,
    required this.prompt,
    required this.helpSteps,
    required this.beforeInteraction,
    required this.child,
    this.choices = const [],
    this.answering = true,
    this.attempts = 0,
    this.lastAnswer,
    this.lastCorrect,
    this.onHelpUsed,
    this.onAnswerConfirmed,
  }) : assert(helpSteps.length > 0 && helpSteps.length <= 5);

  final LumoAppState appState;
  final String taskId, unit, prompt;
  final List<String> helpSteps, choices;
  final Future<void> Function() beforeInteraction;
  final Widget child;
  final bool answering;
  final int attempts;
  final String? lastAnswer;
  final bool? lastCorrect;
  final VoidCallback? onHelpUsed;
  final ValueChanged<String>? onAnswerConfirmed;

  @override
  State<ReadingLessonCompanion> createState() => _ReadingLessonCompanionState();
}

class _ReadingLessonCompanionState extends State<ReadingLessonCompanion>
    with WidgetsBindingObserver {
  static const _objectId = 'reading-task';
  final _bus = LumoCompanionRequests.instance;
  final _candidate = TextEditingController();
  late final int _generation = widget.appState.profileGeneration;
  late final LearningCoachBinding _binding;
  LumoCompanionTaskContext? _published;
  LumoLearningIdentity? _candidateIdentity;
  int _helpLevel = 0, _speechEpoch = 0, _publishEpoch = 0;
  bool _foreground = true, _routeCurrent = true, _invalid = false;
  bool _talkOpen = false, _nativeOpen = false, _speaking = false;
  bool _showHelp = false, _focused = false;
  String? _candidateNotice;

  bool get _active =>
      mounted &&
      !_invalid &&
      !widget.appState.resetting &&
      widget.appState.profileGeneration == _generation &&
      (_foreground || _nativeOpen) &&
      (_routeCurrent || _talkOpen);
  String? get _help => _showHelp && _helpLevel > 0
      ? widget.helpSteps[(_helpLevel - 1).clamp(0, widget.helpSteps.length - 1)]
      : null;

  @override
  void initState() {
    super.initState();
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _binding = LearningCoachBinding(
      isActive: () => _active,
      onHint: _nextHelp,
      onExplain: _nextHelp,
      onRepeat: () => _read(_help ?? widget.prompt),
      onSlower: () => _read(_help ?? widget.prompt, slower: true),
      onStop: _stop,
      onCancel: _cancelOwnedSpeech,
      onTryMyself: _stop,
      onProposeAnswer: _propose,
      onFocus: (id, action) {
        if (id != _objectId) return;
        setState(() => _focused = true);
        _binding.present(
            objectId: id,
            point: action != LumoLearningAction.look,
            state: 'explaining');
      },
    );
    widget.appState.addListener(_profileChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _schedulePublish();
  }

  @override
  void didUpdateWidget(covariant ReadingLessonCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _cancelOwnedSpeech();
      _helpLevel = 0;
      _showHelp = _focused = false;
      _discardCandidate();
    } else if (oldWidget.answering && !widget.answering) {
      _discardCandidate();
    }
    _schedulePublish();
  }

  void _profileChanged() {
    if (widget.appState.resetting ||
        widget.appState.profileGeneration != _generation) {
      _invalid = true;
      _cancelOwnedSpeech();
      _bus.clearTask(_published);
      if (mounted) setState(_discardCandidate);
    }
  }

  void _schedulePublish() {
    final epoch = ++_publishEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _publishEpoch) return;
      _publish();
    });
  }

  void _publish() {
    if (!_active) {
      _cancelOwnedSpeech();
      _bus.clearTask(_published);
      return;
    }
    final task = LumoCompanionTaskContext(
      subject: 'Lesen',
      unit: widget.unit,
      prompt: widget.prompt,
      taskId: widget.taskId,
      ownerSection: 'reading',
      profileGeneration: _generation,
      activity: 'reading',
      stepId: widget.answering ? 'reading-answer' : 'reading-feedback',
      answering: widget.answering,
      attempts: widget.attempts,
      helpLevel: _helpLevel,
      lastAnswer: widget.lastAnswer,
      lastCorrect: widget.lastCorrect,
      localHelp: _help ?? widget.helpSteps.first,
      explanation: _help,
      isExplanation: _help != null,
      answerChoices: widget.choices,
      objectIds: const [_objectId],
      allowedActions: {
        LumoLearningAction.repeat,
        LumoLearningAction.slower,
        LumoLearningAction.stop,
        LumoLearningAction.look,
        LumoLearningAction.point,
        LumoLearningAction.highlight,
        if (widget.answering) ...{
          LumoLearningAction.hint,
          LumoLearningAction.explain,
          if (widget.onAnswerConfirmed != null)
            LumoLearningAction.proposeAnswer,
        },
      },
    );
    if (_binding.ownsCurrentTask && _published?.semanticKey == task.semanticKey)
      return;
    _discardCandidate();
    _published = task;
    _binding.publish(task);
  }

  void _nextHelp() {
    if (!_active || !widget.answering) return;
    widget.onHelpUsed?.call();
    setState(() {
      _helpLevel = (_helpLevel + 1).clamp(1, widget.helpSteps.length);
      _showHelp = _focused = true;
    });
    _publish();
    _binding.present(objectId: _objectId, point: true, state: 'explaining');
    unawaited(_read(_help!));
  }

  Future<void> _read(String text, {bool slower = false}) async {
    final identity = _binding.identity;
    if (!_active || identity == null) return;
    final epoch = ++_speechEpoch;
    await widget.beforeInteraction();
    if (!_active || epoch != _speechEpoch || !_binding.matches(identity))
      return;
    if (!widget.appState.state.settings.voiceEnabled) return;
    _speaking = true;
    try {
      await LumoVoice.instance.speakAndWait(text,
          style: VoiceStyle.explain, speedFactor: slower ? .7 : 1);
    } finally {
      if (epoch == _speechEpoch) _speaking = false;
    }
  }

  void _cancelOwnedSpeech() {
    ++_speechEpoch;
    if (_speaking) {
      _speaking = false;
      unawaited(LumoVoice.instance.stop());
    }
    // Even a request not heard yet must lose its confirmation lease.
    _candidateIdentity = null;
  }

  Future<void> _stop() async {
    _cancelOwnedSpeech();
    if (mounted)
      setState(() {
        _discardCandidate();
        _focused = false;
      });
    await widget.beforeInteraction();
  }

  void _discardCandidate() {
    _candidateIdentity = null;
    _candidate.clear();
    _candidateNotice = null;
  }

  void _propose(String value) {
    if (!_active || !widget.answering || widget.onAnswerConfirmed == null)
      return;
    setState(() {
      _candidate.text = value;
      _candidateIdentity = _binding.identity;
      _candidateNotice = null;
    });
  }

  void _confirm() {
    final identity = _candidateIdentity;
    if (!_active ||
        identity == null ||
        !_binding.matches(identity) ||
        !widget.answering ||
        widget.onAnswerConfirmed == null) return;
    final text = _candidate.text.trim();
    final matches = widget.choices
        .where((choice) => choice.trim().toLowerCase() == text.toLowerCase())
        .toList();
    if (matches.length != 1) {
      setState(() => _candidateNotice =
          'Das ist noch keine eindeutige Antwort. Ändere den Vorschlag oder wähle selbst.');
      return;
    }
    setState(_discardCandidate);
    widget.onAnswerConfirmed!(matches.single);
  }

  Future<void> _talk() async {
    final identity = _binding.identity;
    if (!_active || identity == null) return;
    await widget.beforeInteraction();
    if (!mounted || !_active || !_binding.matches(identity)) return;
    _talkOpen = true;
    try {
      await showLumoConversation(context,
          appState: widget.appState, onSection: widget.appState.setSection);
    } finally {
      _talkOpen = false;
      if (mounted) _schedulePublish();
    }
  }

  Future<void> _world() async {
    final identity = _binding.identity;
    if (!_active || _nativeOpen || _published == null || identity == null)
      return;
    await widget.beforeInteraction();
    if (!mounted || !_active || !_binding.matches(identity)) return;
    widget.onHelpUsed?.call();
    _helpLevel = _helpLevel.clamp(1, widget.helpSteps.length);
    _publish();
    final descriptor = NativeLearningActivity.fromCompanionContext(_published!);
    if (descriptor == null) return;
    _nativeOpen = true;
    try {
      await launchLumo3D(context,
          scene: 'learning',
          subject: 'Lesen',
          appState: widget.appState,
          learning: descriptor);
    } finally {
      _nativeOpen = false;
      if (mounted) _schedulePublish();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancelOwnedSpeech();
      if (mounted) setState(_discardCandidate);
      unawaited(widget.beforeInteraction());
      if (!_nativeOpen) _bus.clearTask(_published);
    } else {
      _schedulePublish();
    }
  }

  @override
  void dispose() {
    ++_publishEpoch;
    _cancelOwnedSpeech();
    _binding.dispose();
    _bus.clearTask(_published);
    widget.appState.removeListener(_profileChanged);
    WidgetsBinding.instance.removeObserver(this);
    _candidate.dispose();
    super.dispose();
  }

  Widget _button(String id, String label, IconData icon, VoidCallback action) =>
      OutlinedButton.icon(
          key: ValueKey(id),
          onPressed: _active ? action : null,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: const Color(0xFF23473F),
              backgroundColor: const Color(0xFFFFF8E9)));

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              key: const ValueKey(_objectId),
              identifier: _objectId,
              label: 'Aktueller Leseschritt',
              container: true,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          width: 2,
                          color: _focused
                              ? const Color(0xFFCF9638)
                              : Colors.transparent)),
                  child: widget.child)),
          const SizedBox(height: 12),
          if (_help != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                    liveRegion: true,
                    child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFEABD),
                            borderRadius: BorderRadius.circular(16)),
                        child: Text(_help!,
                            key: const ValueKey('reading-lumo-help-text'),
                            style: const TextStyle(
                                color: Color(0xFF23473F),
                                fontSize: 17,
                                height: 1.5))))),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _button(
                'reading-lumo-talk', 'Frag Lumo', Icons.forum_outlined, _talk),
            _button(
                'reading-lumo-repeat',
                'Noch einmal',
                Icons.volume_up_outlined,
                () => _binding.request(LumoLearningAction.repeat)),
            _button('reading-lumo-slower', 'Langsamer', Icons.slow_motion_video,
                () => _binding.request(LumoLearningAction.slower)),
            if (widget.answering)
              _button(
                  'reading-lumo-hint',
                  _helpLevel == 0 ? 'Ein Hinweis' : 'Anders erklären',
                  Icons.lightbulb_outline,
                  () => _binding.request(LumoLearningAction.hint)),
            _button('reading-lumo-stop', 'Stopp', Icons.stop_circle_outlined,
                () => _binding.request(LumoLearningAction.stop)),
            _button('reading-lumo-world', 'Mit Lumo in 3D', Icons.view_in_ar,
                _world),
          ]),
          if (_candidateIdentity != null) ...[
            const SizedBox(height: 12),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E9),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Habe ich dich richtig verstanden?',
                          style: TextStyle(
                              color: Color(0xFF23473F),
                              fontWeight: FontWeight.w800)),
                      TextField(
                          key: const ValueKey('reading-lumo-candidate'),
                          controller: _candidate,
                          maxLength: 120,
                          style: const TextStyle(color: Color(0xFF23473F)),
                          decoration: const InputDecoration(
                              labelText: 'Dein Antwortvorschlag')),
                      if (_candidateNotice != null)
                        Text(_candidateNotice!,
                            style: const TextStyle(color: Color(0xFF794019))),
                      _button('reading-lumo-confirm', 'Diese Antwort prüfen',
                          Icons.check, _confirm),
                    ])),
          ],
        ],
      );
}
