import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_learning_session_contract.dart';
import '../../../core/lumo_voice.dart';
import '../../../widgets/fox/lumo_companion_requests.dart';
import '../../../theme/lumo_visual_tokens.dart';

/// Exam-safe consumer of the canonical LUMO bus. It never receives a solution.
/// Repeating an instruction never replays or extends a memory stimulus.
class ExamCompanionScope extends StatefulWidget {
  const ExamCompanionScope(
      {super.key,
      required this.appState,
      required this.generation,
      required this.taskId,
      required this.subject,
      required this.unit,
      required this.prompt,
      required this.instruction,
      required this.child,
      this.exam = true});

  final LumoAppState appState;
  final int generation;
  final String taskId, subject, unit, prompt, instruction;
  final bool exam;
  final Widget child;

  @override
  State<ExamCompanionScope> createState() => _ExamCompanionScopeState();
}

class _ExamCompanionScopeState extends State<ExamCompanionScope> {
  final _requests = LumoCompanionRequests.instance;
  LumoCompanionTaskContext? _published;
  int _handled = -1, _revision = 0;
  bool _reading = false, _calm = false;
  String? _visibleInstruction;

  @override
  void initState() {
    super.initState();
    _requests.learningAction.addListener(_action);
    _requests.taskContext.addListener(_contextChanged);
    _publish();
  }

  @override
  void didUpdateWidget(covariant ExamCompanionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId ||
        oldWidget.prompt != widget.prompt) {
      _stop();
      _visibleInstruction = null;
    }
    _publish();
  }

  bool get _owns =>
      mounted &&
      widget.generation == widget.appState.profileGeneration &&
      identical(_requests.taskContext.value, _published) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  void _publish() {
    final id = widget.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          id != widget.taskId ||
          widget.generation != widget.appState.profileGeneration ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      final taskContext = LumoCompanionTaskContext(
        subject: widget.subject,
        unit: widget.unit,
        prompt: widget.prompt,
        taskId: id,
        isExam: widget.exam,
        answering: widget.exam,
        localHelp: widget.instruction,
        activity: 'thinking_test',
        ownerSection: 'tests',
        profileGeneration: widget.generation,
        stepId: widget.exam ? 'exam_instruction' : 'review',
        objectIds: const ['thinking-question'],
        allowedActions: const {
          LumoLearningAction.repeat,
          LumoLearningAction.slower,
          LumoLearningAction.stop
        },
      );
      _published = taskContext;
      _requests.publishTask(taskContext);
      final identity = _requests.learningIdentity.value;
      if (identity != null && _owns) {
        _requests.publishLearningPresentation(LumoLearningPresentation(
            identity: identity,
            gazeObjectId: 'thinking-question',
            expression: 'attentive',
            animationState: 'observing'));
      }
    });
  }

  void _contextChanged() {
    if (_reading && !identical(_requests.taskContext.value, _published)) {
      _stop();
    }
  }

  void _action() {
    final request = _requests.learningAction.value;
    if (!_owns ||
        request == null ||
        _handled == request.requestId ||
        !_requests.isCurrentLearningIdentity(request.identity)) {
      return;
    }
    _handled = request.requestId;
    _perform(request.action);
  }

  void _perform(LumoLearningAction action) {
    if (!_owns) return;
    if (action == LumoLearningAction.stop) {
      _stop();
      setState(() => _visibleInstruction = null);
      return;
    }
    if (action != LumoLearningAction.repeat &&
        action != LumoLearningAction.slower) {
      return;
    }
    final text = '${widget.prompt}\n${widget.instruction}';
    setState(() => _visibleInstruction = text);
    if (widget.appState.state.settings.voiceEnabled) {
      unawaited(_read(text, slower: action == LumoLearningAction.slower));
    }
  }

  Future<void> _read(String text, {required bool slower}) async {
    final token = ++_revision;
    _reading = true;
    final voice = LumoVoice.instance;
    try {
      await voice.stop();
      if (!_owns || token != _revision) return;
      final rate = widget.appState.state.settings.voiceRate;
      await voice.configure(rate: slower ? rate * .75 : rate);
      if (!_owns || token != _revision) return;
      await voice.speakAndWait(text, style: VoiceStyle.explain);
    } catch (_) {
      // The same instruction remains visible when audio is unavailable.
    } finally {
      if (token == _revision) {
        _reading = false;
        await voice.configure(rate: widget.appState.state.settings.voiceRate);
      }
    }
  }

  void _stop() {
    ++_revision;
    if (!_reading) return;
    _reading = false;
    unawaited(LumoVoice.instance.stop());
    unawaited(LumoVoice.instance
        .configure(rate: widget.appState.state.settings.voiceRate));
  }

  @override
  void dispose() {
    _stop();
    _requests.learningAction.removeListener(_action);
    _requests.taskContext.removeListener(_contextChanged);
    _requests.clearTask(_published);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm = _calm ||
        widget.appState.state.settings.calmMode ||
        widget.appState.state.settings.reduceAnimations;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
          disableAnimations: calm || MediaQuery.disableAnimationsOf(context)),
      child: Column(children: [
        Expanded(child: widget.child),
        if (_visibleInstruction != null)
          ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 112),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text(_visibleInstruction!,
                      key: const ValueKey('exam-instruction'),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15)))),
        Material(
            color: const Color(0xFF0B284B),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                _control('Auftrag', Icons.replay_rounded,
                    () => _perform(LumoLearningAction.repeat)),
                _control('Langsamer', Icons.slow_motion_video_rounded,
                    () => _perform(LumoLearningAction.slower)),
                _control('Stopp', Icons.stop_rounded,
                    () => _perform(LumoLearningAction.stop)),
                _control(_calm ? 'Ruhig ✓' : 'Ruhig', Icons.spa_outlined,
                    () => setState(() => _calm = !_calm)),
              ],
            )),
      ]),
    );
  }

  Widget _control(String label, IconData icon, VoidCallback action) =>
      TextButton.icon(
        style: TextButton.styleFrom(
            minimumSize: const Size(72, 48),
            foregroundColor: LumoVisualTokens.white,
            padding: const EdgeInsets.symmetric(horizontal: 10)),
        onPressed: action,
        icon: Icon(icon, size: 19),
        label: Text(label),
      );
}
