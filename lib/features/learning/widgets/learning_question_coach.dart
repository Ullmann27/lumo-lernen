import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_learning_narration.dart';
import '../../../core/lumo_learning_session_contract.dart';
import '../../../core/lumo_voice.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';

/// Adds the canonical companion to an existing game question. The game keeps
/// answer evaluation, joker limits, turn rules, persistence and rewards.
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
    this.answering = true,
    this.active = true,
    this.helpUsed = false,
    this.helpText,
    this.lastAnswer,
    this.lastCorrect,
    this.onHint,
    this.onConfirmedChoice,
    this.objectIds = const ['question-prompt'],
    this.focusObjectId = 'question-prompt',
    this.visibleExplanation,
    this.stepId,
    this.onFocus,
  });

  final LumoAppState appState;
  final String taskId, subject, unit, prompt;
  final Map<int, String> choices;
  final Widget child;
  final bool answering, helpUsed, active;
  final String? helpText, lastAnswer;
  final bool? lastCorrect;
  final VoidCallback? onHint;
  final ValueChanged<int>? onConfirmedChoice;
  final List<String> objectIds;
  final String focusObjectId;
  final String? visibleExplanation, stepId;
  final ValueChanged<String>? onFocus;

  @override
  State<LearningQuestionCoach> createState() => _LearningQuestionCoachState();
}

class _LearningQuestionCoachState extends State<LearningQuestionCoach>
    with WidgetsBindingObserver {
  final _bus = LumoCompanionRequests.instance;
  final _narration = LumoLearningNarration();
  final _candidate = TextEditingController();
  late int _generation;
  LumoCompanionTaskContext? _published;
  bool _proposalVisible = false,
      _slow = false,
      _quiet = false,
      _explain = false;
  int _handled = -1, _speech = 0, _requestedHints = 0;
  String? _proposalNotice;

  bool get _profileCurrent =>
      mounted &&
      !widget.appState.resetting &&
      widget.appState.profileGeneration == _generation &&
      (ModalRoute.of(context)?.isCurrent ?? true);
  bool get _current => widget.active && _profileCurrent;
  bool get _owns => _current && identical(_bus.taskContext.value, _published);

  @override
  void initState() {
    super.initState();
    _generation = widget.appState.profileGeneration;
    _bus.learningAction.addListener(_request);
    _bus.taskContext.addListener(_contextChanged);
    widget.appState.addListener(_profileChanged);
    WidgetsBinding.instance.addObserver(this);
    _publish();
  }

  @override
  void didUpdateWidget(covariant LearningQuestionCoach oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) {
      _stop();
      _bus.clearTask(_published);
    }
    if (oldWidget.taskId != widget.taskId) {
      _stop();
      _proposalVisible = false;
      _candidate.clear();
      _requestedHints = 0;
      _proposalNotice = null;
      _explain = false;
    }
    if (widget.helpText != oldWidget.helpText &&
        _explain &&
        widget.helpText != null) {
      _queueRead(widget.helpText!);
    }
    _publish();
  }

  void _publish() {
    final taskId = widget.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_current || taskId != widget.taskId) return;
      final help = _explain ? widget.helpText : null;
      final context = LumoCompanionTaskContext(
        taskId: taskId,
        subject: widget.subject,
        unit: widget.unit,
        prompt: widget.prompt,
        answering: widget.answering,
        profileGeneration: _generation,
        ownerSection: 'games',
        activity: 'game-learning-question',
        stepId: widget.stepId ?? (widget.answering ? 'answer' : 'feedback'),
        objectIds: widget.objectIds,
        answerChoices: widget.choices.values.toList(growable: false),
        helpLevel: widget.helpUsed || _requestedHints > 0 ? 1 : 0,
        localHelp: help ??
            widget.visibleExplanation ??
            'Lies die Frage noch einmal. Vergleiche die angebotenen Antworten.',
        explanation: help ?? widget.visibleExplanation,
        isExplanation: help != null,
        lastAnswer: widget.lastAnswer,
        lastCorrect: widget.lastCorrect,
        allowedActions: {
          LumoLearningAction.repeat,
          LumoLearningAction.slower,
          LumoLearningAction.stop,
          LumoLearningAction.look,
          LumoLearningAction.point,
          LumoLearningAction.highlight,
          if (widget.onHint != null && widget.answering) ...{
            LumoLearningAction.hint,
            LumoLearningAction.explain,
          },
          if (widget.onConfirmedChoice != null && widget.answering)
            LumoLearningAction.proposeAnswer,
        },
      );
      _published = context;
      _bus.publishTask(context);
      _present(widget.focusObjectId, point: help != null);
    });
  }

  void _profileChanged() {
    if (mounted &&
        (widget.appState.profileGeneration != _generation ||
            widget.appState.resetting)) {
      _stop();
      _bus.clearTask(_published);
      setState(() {});
    }
  }

  void _contextChanged() {
    if (_narration.isActive && !identical(_bus.taskContext.value, _published)) {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  void _request() {
    final request = _bus.learningAction.value;
    if (!_owns ||
        request == null ||
        request.requestId == _handled ||
        !_bus.isCurrentLearningIdentity(request.identity)) {
      return;
    }
    _handled = request.requestId;
    switch (request.action) {
      case LumoLearningAction.hint:
      case LumoLearningAction.explain:
        _hint();
      case LumoLearningAction.repeat:
        _queueRead(_explain && widget.helpText != null
            ? widget.helpText!
            : widget.prompt);
      case LumoLearningAction.slower:
        _slow = true;
        _queueRead(_explain && widget.helpText != null
            ? widget.helpText!
            : widget.prompt);
      case LumoLearningAction.stop:
        _stop();
        setState(() => _explain = false);
        _publish();
      case LumoLearningAction.proposeAnswer:
        if (widget.answering &&
            widget.onConfirmedChoice != null &&
            request.candidate != null) {
          setState(() {
            _candidate.text = request.candidate!;
            _proposalVisible = true;
            _proposalNotice = null;
          });
        }
      case LumoLearningAction.highlight:
      case LumoLearningAction.point:
      case LumoLearningAction.look:
        final target = request.objectId;
        if (target != null && widget.objectIds.contains(target)) {
          widget.onFocus?.call(target);
          _present(target, point: request.action != LumoLearningAction.look);
        }
        break;
    }
  }

  void _present(String objectId, {required bool point}) {
    final identity = _bus.learningIdentity.value;
    if (!_owns || identity == null || !widget.objectIds.contains(objectId)) {
      return;
    }
    _bus.publishLearningPresentation(LumoLearningPresentation(
      identity: identity,
      gazeObjectId: objectId,
      pointObjectId: point ? objectId : null,
      expression: point ? 'explaining' : 'attentive',
      animationState: point ? 'point' : 'idle',
    ));
  }

  void _hint() {
    if (!_current || !widget.answering || widget.onHint == null) return;
    setState(() {
      _explain = true;
      _requestedHints++;
    });
    // The parent executes the actual limited joker or staged method hint.
    widget.onHint!();
    _publish();
    if (widget.helpText != null) _queueRead(widget.helpText!);
  }

  void _queueRead(String text) {
    final taskId = widget.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (_owns && taskId == widget.taskId) unawaited(_read(text));
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _read(String text) async {
    if (!_owns || !widget.appState.state.settings.voiceEnabled) return;
    final serial = ++_speech;
    final identity = _bus.learningIdentity.value;
    if (identity == null) return;
    final rate = widget.appState.state.settings.voiceRate;
    try {
      await _narration.stop();
      if (!_owns ||
          serial != _speech ||
          !_bus.isCurrentLearningIdentity(identity)) {
        return;
      }
      await LumoVoice.instance.configure(rate: _slow ? rate * .7 : rate);
      if (!_owns ||
          serial != _speech ||
          !_bus.isCurrentLearningIdentity(identity)) {
        return;
      }
      await _narration.read(text);
    } catch (_) {
      // The visible question and help remain usable without device audio.
    } finally {
      if (serial == _speech) await LumoVoice.instance.configure(rate: rate);
    }
  }

  void _stop() {
    ++_speech;
    if (_narration.isActive) unawaited(_narration.stop());
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
  }

  void _stopRequested() {
    if (_owns) _bus.cancelLearningInteraction(reason: 'game-child-stop');
    _stop();
    if (mounted) setState(() => _explain = false);
    _publish();
  }

  void _confirm() {
    if (!_current || !widget.answering || widget.onConfirmedChoice == null) {
      return;
    }
    final text = _candidate.text.trim();
    final matches = widget.choices.entries
        .where((e) => e.value.toLowerCase() == text.toLowerCase());
    if (matches.length != 1) {
      setState(() => _proposalNotice =
          'Das passt noch nicht eindeutig zu einer Karte. Ändere den Text oder wähle selbst.');
      return;
    }
    final choice = matches.single.key;
    setState(() {
      _proposalVisible = false;
      _candidate.clear();
    });
    widget.onConfirmedChoice!(choice);
  }

  @override
  void dispose() {
    _stop();
    _narration.dispose();
    _candidate.dispose();
    _bus.learningAction.removeListener(_request);
    _bus.taskContext.removeListener(_contextChanged);
    widget.appState.removeListener(_profileChanged);
    WidgetsBinding.instance.removeObserver(this);
    _bus.clearTask(_published);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: _quiet ||
                widget.appState.state.settings.calmMode ||
                widget.appState.state.settings.reduceAnimations ||
                MediaQuery.disableAnimationsOf(context)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AbsorbPointer(absorbing: !_profileCurrent, child: widget.child),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _button(
                'Noch einmal',
                Icons.volume_up_outlined,
                _current
                    ? () => _queueRead(_explain && widget.helpText != null
                        ? widget.helpText!
                        : widget.prompt)
                    : null),
            _button(
                'Langsamer',
                Icons.slow_motion_video,
                _current
                    ? () {
                        _slow = true;
                        _queueRead(_explain && widget.helpText != null
                            ? widget.helpText!
                            : widget.prompt);
                      }
                    : null),
            if (widget.onHint != null)
              _button('Hilf mir', Icons.lightbulb_outline,
                  _current && widget.answering ? _hint : null),
            if (widget.onHint != null && _explain)
              _button('Anders erklären', Icons.swap_horiz,
                  _current && widget.answering ? _hint : null),
            _button('Stopp', Icons.stop_circle_outlined, _stopRequested),
            _button(
                'Selbst versuchen', Icons.touch_app_outlined, _stopRequested),
            _button(_quiet ? 'Ruhig: an' : 'Ruhiger Modus', Icons.spa_outlined,
                () => setState(() => _quiet = !_quiet)),
          ]),
          if (_proposalVisible) ...[
            const SizedBox(height: 12),
            const Text(
                'Habe ich dich richtig verstanden? Bestätige oder ändere den Vorschlag.',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            TextField(
                key: const ValueKey('game-answer-proposal'),
                controller: _candidate,
                maxLength: 120,
                decoration:
                    const InputDecoration(labelText: 'Dein Antwortvorschlag')),
            if (_proposalNotice != null)
              Text(_proposalNotice!,
                  style: const TextStyle(color: Color(0xFFFFDBA3))),
            _button(
                'Diese Karte wählen', Icons.check, _current ? _confirm : null),
            _button('Vorschlag verwerfen', Icons.close,
                () => setState(() => _proposalVisible = false)),
          ],
        ]),
      );

  Widget _button(String label, IconData icon, VoidCallback? onPressed) =>
      OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF12385F),
              side: const BorderSide(color: Color(0xFF4D9DC5))));
}
