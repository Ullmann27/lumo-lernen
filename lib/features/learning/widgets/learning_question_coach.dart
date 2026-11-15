import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../app/lumo_companion_host.dart';
import '../../../core/lumo_learning_session_contract.dart';
import '../../../core/lumo_voice.dart';
import '../../../domain/tutoring/native_learning_activity.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';
import '../../lumo3d/lumo3d_launcher.dart';
import '../nextgen/learning_coach_binding.dart';

/// Presents the existing question through the canonical companion. The owner
/// alone evaluates confirmed answers, limits help and persists rewards.
class LearningQuestionCoach extends StatefulWidget {
  const LearningQuestionCoach({
    super.key,
    required this.appState,
    required this.taskId,
    required this.subject,
    required this.unit,
    required this.prompt,
    required this.choices,
    required this.child,
    this.ownerSection = 'games',
    this.activity = 'game-learning-question',
    this.answering = true,
    this.active = true,
    this.isExam = false,
    this.helpUsed = false,
    this.helpText,
    this.lastAnswer,
    this.lastCorrect,
    this.onHint,
    this.onConfirmedChoice,
    this.onConfirmedAnswer,
    this.beforeInteraction,
    this.onStop,
    this.objectIds = const ['question-prompt'],
    this.focusObjectId = 'question-prompt',
    this.visibleExplanation,
    this.stepId,
    this.onFocus,
    this.voice,
  }) : assert(onConfirmedChoice == null || onConfirmedAnswer == null);

  final LumoAppState appState;
  final String taskId, subject, unit, prompt, ownerSection, activity;
  final Map<int, String> choices;
  final Widget child;
  final bool answering, helpUsed, active, isExam;
  final String? helpText, lastAnswer;
  final bool? lastCorrect;
  final VoidCallback? onHint, beforeInteraction, onStop;
  final ValueChanged<int>? onConfirmedChoice;
  final ValueChanged<String>? onConfirmedAnswer;
  final List<String> objectIds;
  final String focusObjectId;
  final String? visibleExplanation, stepId;
  final ValueChanged<String>? onFocus;

  /// Transport injection exercises cancellation without claiming device audio.
  final LumoVoice? voice;

  @override
  State<LearningQuestionCoach> createState() => _LearningQuestionCoachState();
}

class _LearningQuestionCoachState extends State<LearningQuestionCoach>
    with WidgetsBindingObserver {
  final _bus = LumoCompanionRequests.instance;
  final _candidate = TextEditingController();
  late final int _generation;
  late final LearningCoachBinding _binding;
  LumoCompanionTaskContext? _published;
  LumoLearningIdentity? _candidateIdentity;
  Object? _candidateToken;
  bool _proposalVisible = false,
      _slow = false,
      _quiet = false,
      _explain = false;
  bool _foreground = true, _routeCurrent = true, _talkOpen = false;
  bool _nativeOpen = false, _disposed = false;
  int _speech = 0, _requestedHints = 0, _publishEpoch = 0;
  int? _voiceRequest;
  String? _proposalNotice;

  LumoVoice get _voice => widget.voice ?? LumoVoice.instance;
  bool get _profileCurrent =>
      mounted &&
      !_disposed &&
      !widget.appState.resetting &&
      widget.appState.profileGeneration == _generation;
  bool get _scopeActive =>
      _profileCurrent &&
      widget.active &&
      (_foreground || _nativeOpen) &&
      (_routeCurrent || _talkOpen);
  bool get _current => _scopeActive && _foreground && !_nativeOpen;
  bool get _owns =>
      _binding.ownsCurrentTask &&
      _published?.semanticKey == _snapshot().semanticKey;
  bool get _canPropose =>
      widget.answering &&
      !widget.isExam &&
      (widget.onConfirmedChoice != null || widget.onConfirmedAnswer != null);
  String get _readText =>
      _explain && widget.helpText != null ? widget.helpText! : widget.prompt;

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _binding = LearningCoachBinding(
      isActive: () => _scopeActive,
      onHint: _hint,
      onExplain: _hint,
      onRepeat: () => _queueRead(_readText),
      onSlower: () {
        _slow = true;
        _queueRead(_readText);
      },
      onStop: _stop,
      onCancel: _cancel,
      onTryMyself: _stop,
      onProposeAnswer: _propose,
      onFocus: (target, action) {
        if (!_current || !_owns || !widget.objectIds.contains(target)) return;
        widget.onFocus?.call(target);
        _binding.present(
            objectId: target, point: action != LumoLearningAction.look);
      },
    );
    _bus.taskContext.addListener(_contextChanged);
    widget.appState.addListener(_profileChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!_scopeActive) _cancel();
    _schedulePublish();
  }

  @override
  void didUpdateWidget(covariant LearningQuestionCoach oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId ||
        oldWidget.ownerSection != widget.ownerSection ||
        oldWidget.subject != widget.subject ||
        oldWidget.unit != widget.unit) {
      _cancel();
      _requestedHints = 0;
      _explain = false;
      _slow = false;
    } else if (!widget.active ||
        _published?.semanticKey != _snapshot().semanticKey) {
      _cancel();
    }
    _schedulePublish(
        readAfterPublish:
            widget.helpText != oldWidget.helpText && _explain && !_nativeOpen
                ? widget.helpText
                : null);
  }

  LumoCompanionTaskContext _snapshot() {
    final help = _explain ? widget.helpText : null;
    return LumoCompanionTaskContext(
      taskId: widget.taskId,
      subject: widget.subject,
      unit: widget.unit,
      prompt: widget.prompt,
      answering: widget.answering,
      isExam: widget.isExam,
      profileGeneration: _generation,
      ownerSection: widget.ownerSection,
      activity: widget.activity,
      stepId: widget.stepId ?? (widget.answering ? 'answer' : 'feedback'),
      objectIds: widget.objectIds,
      answerChoices: widget.choices.values.toList(growable: false),
      helpLevel: widget.helpUsed || _requestedHints > 0 ? 1 : 0,
      localHelp: widget.isExam
          ? null
          : help ??
              widget.visibleExplanation ??
              (widget.choices.isEmpty
                  ? 'Lies den sichtbaren Auftrag noch einmal. Du kannst deine Antwort vor dem Bestätigen ändern.'
                  : 'Lies die Frage noch einmal. Vergleiche die angebotenen Antworten.'),
      explanation: widget.isExam ? null : help ?? widget.visibleExplanation,
      isExplanation: !widget.isExam && help != null,
      lastAnswer: widget.lastAnswer,
      lastCorrect: widget.lastCorrect,
      allowedActions: {
        LumoLearningAction.repeat,
        LumoLearningAction.slower,
        LumoLearningAction.stop,
        if (!widget.isExam) ...{
          LumoLearningAction.look,
          LumoLearningAction.point,
          LumoLearningAction.highlight,
          if (widget.onHint != null && widget.answering) ...{
            LumoLearningAction.hint,
            LumoLearningAction.explain,
          },
          if (_canPropose) LumoLearningAction.proposeAnswer,
        },
      },
    );
  }

  void _schedulePublish({String? readAfterPublish}) {
    final epoch = ++_publishEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted || epoch != _publishEpoch) return;
      _publish();
      if (readAfterPublish != null) _queueRead(readAfterPublish);
    });
  }

  void _publish() {
    if (!_scopeActive) {
      _cancel();
      _bus.clearTask(_published);
      return;
    }
    final task = _snapshot();
    if (_binding.ownsCurrentTask &&
        _published?.semanticKey == task.semanticKey) {
      return;
    }
    _discardCandidate();
    _published = task;
    _binding.publish(task);
    if (!widget.isExam) {
      _binding.present(
          objectId: widget.focusObjectId, point: task.isExplanation);
    }
  }

  void _profileChanged() {
    if (!_profileCurrent) {
      _cancel();
      _bus.clearTask(_published);
      if (mounted) setState(() {});
    }
  }

  void _contextChanged() {
    if (!identical(_bus.taskContext.value, _published)) _cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancel();
      // The existing Android launcher needs this exact owner throughout its
      // Activity. It is still the same task, not a new unanswered snapshot.
      if (!_nativeOpen) _bus.clearTask(_published);
    } else {
      _schedulePublish();
    }
    if (mounted) setState(() {});
  }

  void _hint({bool read = true}) {
    if (!_current ||
        !_owns ||
        widget.isExam ||
        !widget.answering ||
        widget.onHint == null) {
      return;
    }
    widget.beforeInteraction?.call();
    _cancelOwnedSpeech();
    setState(() {
      _explain = true;
      _requestedHints++;
    });
    widget.onHint!();
    _publish();
    _bus.recordLearningEvent(LumoLearningEventKind.hintRequested,
        context: _published);
    if (read && widget.helpText != null) _queueRead(widget.helpText!);
  }

  void _queueRead(String text) {
    if (!_current) return;
    final epoch = ++_speech;
    final taskId = widget.taskId;
    final identity = _binding.identity;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (!_current ||
            !_owns ||
            epoch != _speech ||
            taskId != widget.taskId) {
          return;
        }
        final expected = identity;
        if (expected != null && _binding.matches(expected)) {
          unawaited(_read(text, expected, epoch));
        }
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _read(
      String text, LumoLearningIdentity identity, int epoch) async {
    if (!_current ||
        !_owns ||
        epoch != _speech ||
        !_binding.matches(identity)) {
      return;
    }
    widget.beforeInteraction?.call();
    if (!_current ||
        !_binding.matches(identity) ||
        epoch != _speech ||
        !widget.appState.state.settings.voiceEnabled) {
      return;
    }
    final voice = _voice;
    final before = voice.requestRevision;
    final playing = voice.speakAndWait(text,
        style: VoiceStyle.explain, speedFactor: _slow ? .7 : 1);
    _voiceRequest =
        voice.requestRevision == before ? null : voice.requestRevision;
    try {
      await playing;
    } catch (_) {
      // The actual task and its visible help remain usable without audio.
    } finally {
      if (epoch == _speech) _voiceRequest = null;
    }
  }

  void _cancelOwnedSpeech() {
    ++_speech;
    final request = _voiceRequest;
    _voiceRequest = null;
    // No global tempo reset and no unowned stop on disposal or late completion.
    // A newer voice request belongs to its new page, even before native start.
    if (request != null && _voice.requestRevision == request) {
      unawaited(_voice.stop());
    }
  }

  void _discardCandidate() {
    _candidateIdentity = null;
    _candidateToken = null;
    _proposalVisible = false;
    _candidate.clear();
    _proposalNotice = null;
  }

  void _cancel() {
    _cancelOwnedSpeech();
    final visible = _proposalVisible;
    _discardCandidate();
    if (visible && mounted && !_disposed) setState(() {});
  }

  void _stop() {
    _cancel();
    widget.onStop?.call();
    if (mounted && !_disposed) setState(() => _explain = false);
    _schedulePublish();
  }

  void _stopRequested() {
    if (_binding.ownsCurrentTask) {
      _binding.interrupt('question-child-stop');
    } else {
      _stop();
    }
  }

  void _propose(String text) {
    if (!_current || !_owns || !_canPropose) return;
    final identity = _binding.identity;
    if (identity == null) return;
    setState(() {
      _candidate.text = text;
      _candidateIdentity = identity;
      _candidateToken = Object();
      _proposalVisible = true;
      _proposalNotice = null;
    });
  }

  void _confirm(Object token) {
    final identity = _candidateIdentity;
    if (!_current ||
        !_owns ||
        !_canPropose ||
        !_proposalVisible ||
        !identical(token, _candidateToken) ||
        identity == null ||
        !_binding.matches(identity)) {
      return;
    }
    final text = _candidate.text.trim();
    if (text.isEmpty || text.length > 120) {
      setState(
          () => _proposalNotice = 'Trage zuerst deinen Antwortvorschlag ein.');
      return;
    }
    int? choice;
    if (widget.onConfirmedChoice != null) {
      final matches = widget.choices.entries.where(
          (entry) => entry.value.trim().toLowerCase() == text.toLowerCase());
      if (matches.length != 1) {
        setState(() => _proposalNotice =
            'Das passt noch nicht eindeutig zu einer Karte. Ändere den Text oder wähle selbst.');
        return;
      }
      choice = matches.single.key;
    }
    setState(_discardCandidate);
    if (choice != null) {
      widget.onConfirmedChoice!(choice);
    } else {
      widget.onConfirmedAnswer!(text);
    }
  }

  VoidCallback? _confirmationCallback() {
    final token = _candidateToken;
    if (!_current || token == null) return null;
    // A callback from an older frame must not confirm a replacement proposal,
    // even when both proposals happen to share the same task identity.
    return () => _confirm(token);
  }

  Future<void> _talk() async {
    if (!_current || !_owns || _talkOpen) return;
    widget.beforeInteraction?.call();
    _cancelOwnedSpeech();
    _talkOpen = true;
    try {
      await showLumoConversation(context,
          appState: widget.appState, onSection: widget.appState.setSection);
    } finally {
      _talkOpen = false;
      if (mounted) _schedulePublish();
    }
  }

  Future<void> _openNative() async {
    if (!_current || !_owns || widget.isExam || _nativeOpen) return;
    final identity = _binding.identity;
    if (identity == null) return;
    widget.beforeInteraction?.call();
    _cancel();
    if (widget.onHint != null && widget.answering) _hint(read: false);
    setState(() => _nativeOpen = true);
    try {
      // The owner may update its existing joker/help state synchronously. Use
      // that resulting snapshot, and reject Stop or a task/step switch meanwhile.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final current = _binding.identity;
      if (!mounted ||
          !_scopeActive ||
          !_owns ||
          current == null ||
          current.sessionId != identity.sessionId ||
          current.taskId != identity.taskId ||
          current.stepId != identity.stepId ||
          current.cancelEpoch - identity.cancelEpoch !=
              current.revision - identity.revision) {
        return;
      }
      final descriptor =
          NativeLearningActivity.fromCompanionContext(_published!);
      if (descriptor == null) return;
      await launchLumo3D(context,
          scene: 'learning',
          subject: widget.subject,
          appState: widget.appState,
          learning: descriptor);
    } finally {
      _nativeOpen = false;
      if (mounted) {
        setState(() {});
        _schedulePublish();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_publishEpoch;
    _cancelOwnedSpeech();
    _binding.dispose();
    _bus.taskContext.removeListener(_contextChanged);
    widget.appState.removeListener(_profileChanged);
    WidgetsBinding.instance.removeObserver(this);
    _bus.clearTask(_published);
    _candidate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: _quiet ||
                widget.appState.state.settings.calmMode ||
                widget.appState.state.settings.reduceAnimations ||
                MediaQuery.disableAnimationsOf(context)),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AbsorbPointer(
                  absorbing: !_current || _talkOpen, child: widget.child),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _button(
                    'Frag Lumo', Icons.forum_outlined, _current ? _talk : null,
                    id: 'question-lumo-talk'),
                if (!widget.isExam &&
                    widget.taskId.isNotEmpty &&
                    widget.prompt.trim().isNotEmpty)
                  _button('Mit Lumo in 3D', Icons.view_in_ar_outlined,
                      _current ? _openNative : null,
                      id: 'question-lumo-native'),
                _button('Noch einmal', Icons.volume_up_outlined,
                    _current ? () => _queueRead(_readText) : null),
                _button(
                    'Langsamer',
                    Icons.slow_motion_video,
                    _current
                        ? () {
                            _slow = true;
                            _queueRead(_readText);
                          }
                        : null),
                if (widget.onHint != null && !widget.isExam)
                  _button('Hilf mir', Icons.lightbulb_outline,
                      _current && widget.answering ? _hint : null),
                if (widget.onHint != null && _explain && !widget.isExam)
                  _button('Anders erklären', Icons.swap_horiz,
                      _current && widget.answering ? _hint : null),
                _button('Stopp', Icons.stop_circle_outlined, _stopRequested),
                _button('Selbst versuchen', Icons.touch_app_outlined,
                    _stopRequested),
                _button(_quiet ? 'Ruhig: an' : 'Ruhiger Modus',
                    Icons.spa_outlined, () => setState(() => _quiet = !_quiet)),
                if (widget.onConfirmedAnswer != null && _canPropose)
                  _button('Antwort tippen', Icons.edit_outlined,
                      _current ? () => _propose('') : null),
              ]),
              if (_proposalVisible) ...[
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF12385F),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                              'Habe ich dich richtig verstanden? Bestätige oder ändere den Vorschlag.',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          TextField(
                              key: const ValueKey('game-answer-proposal'),
                              controller: _candidate,
                              maxLength: 120,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  labelText: 'Dein Antwortvorschlag',
                                  labelStyle: TextStyle(color: Colors.white))),
                          if (_proposalNotice != null)
                            Text(_proposalNotice!,
                                style:
                                    const TextStyle(color: Color(0xFFFFDBA3))),
                          _button(
                              widget.onConfirmedAnswer != null
                                  ? 'Antwort bestätigen'
                                  : 'Diese Karte wählen',
                              Icons.check,
                              _confirmationCallback()),
                          _button('Vorschlag verwerfen', Icons.close,
                              () => setState(_discardCandidate)),
                        ])),
              ],
            ]),
      );

  Widget _button(String label, IconData icon, VoidCallback? onPressed,
          {String? id}) =>
      OutlinedButton.icon(
          key: id == null ? null : ValueKey(id),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF12385F),
              side: const BorderSide(color: Color(0xFF4D9DC5))));
}
