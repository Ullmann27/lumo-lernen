import 'dart:async';

import 'package:flutter/foundation.dart';
import '../widgets/fox/lumo_companion_requests.dart';

import 'lumo_ai_proxy_client.dart';
import 'lumo_companion_engine.dart';
import 'lumo_context_engine.dart';
import 'lumo_sulafat_client.dart';
import 'lumo_task_dialogue_engine.dart';
import 'lumo_voice.dart';

enum LumoConversationPhase {
  idle,
  listening,
  thinking,
  speaking,
  paused,
  error,
  waiting,
  interrupted,
}

/// Spoken subtitle and semantic gaze target, bound to one task revision.
/// Chat 3 can observe this together with LumoVoice.clipMouth. The envelope
/// follows actual audio playback, it is not phoneme-level lip sync.
class LumoConversationCue {
  const LumoConversationCue({
    required this.utteranceId,
    required this.taskId,
    required this.contextRevision,
    required this.subtitle,
    this.focus,
  });

  final String utteranceId;
  final String taskId;
  final int contextRevision;
  final String subtitle;
  final String? focus;
}

/// One short-lived conversation over actual context. History is RAM-only,
/// limited to four exchanges and discarded on task/profile/screen changes.
/// This controller has no reward or navigation capabilities.
class LumoConversationController extends ChangeNotifier {
  LumoConversationController(
    this.context, {
    LumoAiProxyClient proxy = const LumoAiProxyClient(),
  }) : _proxy = proxy {
    context.addListener(_contextChanged);
    LumoVoice.instance.status.addListener(_voiceChanged);
  }

  final LumoContextEngine context;
  final LumoAiProxyClient _proxy;
  final List<LumoAiChatTurn> _history = [];
  final String _sessionId = DateTime.now().microsecondsSinceEpoch.toString();
  final ValueNotifier<LumoConversationCue?> activeCue =
      ValueNotifier<LumoConversationCue?>(null);
  LumoConversationCue? _preparedCue;
  LumoTaskDialogueAction? lastTaskAction;
  int _round = 0;
  List<LumoAiChatTurn> get history => List.unmodifiable(_history);
  LumoConversationPhase phase = LumoConversationPhase.idle;
  LumoSpeechCancellation? _request;
  int _generation = 0;
  bool _disposed = false;
  bool _paused = false;

  static const cancelled =
      LumoAiProxyResponse(reply: '', blocked: false, source: 'cancelled');

  Future<LumoAiProxyResponse> ask(String question) async {
    if (_disposed || _paused || question.trim().isEmpty || _request != null) {
      return cancelled;
    }
    if (question.length > 1200) {
      return const LumoAiProxyResponse(
          reply: 'Stell mir bitte eine kürzere Frage. '
              'Wir gehen sie dann gemeinsam durch.',
          blocked: false,
          source: 'local_input_too_long');
    }
    final generation = ++_generation;
    final revision = context.revision;
    _preparedCue = null;
    lastTaskAction = null;
    await LumoVoice.instance.stop();
    if (_disposed || _paused || generation != _generation) return cancelled;
    final request = LumoSpeechCancellation();
    _request = request;
    _setPhase(LumoConversationPhase.thinking);
    final app = context.appState;
    final state = app.state;
    final safeInput = LumoChildSafetyFilter.inspect(question).allowed;
    final task = context.task;
    final lastAnswer = _history.isNotEmpty &&
            _history.last.role == 'assistant'
        ? _history.last.content
        : null;
    final decision = safeInput
        ? const LumoTaskDialogueEngine().respond(
            input: question, task: task, previousReply: lastAnswer)
        : null;
    if (decision?.action == LumoTaskDialogueAction.stop) {
      interrupt();
      return cancelled;
    }
    final local = const LumoCompanionEngine()
        .answer(input: question, state: state, task: task);
    if (safeInput && !context.isAssessment) {
      context.requests.recordLearningEvent(
          LumoLearningEventKind.childAskedQuestion,
          context: context.task);
    }
    var response = LumoAiProxyResponse(
        reply: context.isAssessment
            ? 'Im Test löst du die Aufgabe selbst. Danach üben wir gemeinsam.'
            : decision?.text ?? local.text,
        blocked: !safeInput,
        source: decision == null ? 'local_companion' : 'local_task_dialogue');
    // A task-owner hint is authoritative; never let an open-model reply
    // override the approved help level or claim a learning result.
    if (decision == null && !context.isAssessment &&
        safeInput &&
        _proxy.isConfigured(state.settings)) {
      try {
        final online = await _proxy.ask(
            settings: state.settings,
            state: state,
            message: question,
            history: history,
            context: context.aiContext,
            extras: context.remoteContext,
            cancellation: request);
        if (online.isCloudAnswer || online.blocked) response = online;
      } catch (_) {
        // Keep the real local task help; never expose raw provider errors.
      }
    }
    if (_disposed ||
        _paused ||
        generation != _generation ||
        revision != context.revision ||
        request.cancelled) {
      return cancelled;
    }
    _request = null;
    lastTaskAction = decision?.action;
    final utterance = ++_round;
    _preparedCue = LumoConversationCue(
      utteranceId: _sessionId + ':' + revision.toString() + ':' +
          utterance.toString(),
      taskId: task?.taskId ?? '',
      contextRevision: revision,
      subtitle: decision?.subtitle ?? response.reply,
      focus: decision?.focus,
    );
    if (!response.blocked) {
      _history.addAll([
        LumoAiChatTurn(role: 'user', content: question),
        LumoAiChatTurn(role: 'assistant', content: response.reply),
      ]);
    }
    while (_history.length > 8) {
      _history.removeAt(0);
    }
    _setPhase(LumoConversationPhase.waiting);
    return response;
  }

  Future<void> speak(String text,
      {VoiceStyle style = VoiceStyle.explain}) async {
    if (_disposed || _paused || !context.appState.state.settings.voiceEnabled) {
      return;
    }
    final cue = _preparedCue;
    if (cue != null && cue.contextRevision == context.revision) {
      activeCue.value = cue;
    }
    try {
      await LumoVoice.instance.speakAndWait(text, style: style);
    } finally {
      if (identical(activeCue.value, cue)) activeCue.value = null;
    }
  }

  void listening(bool value) {
    if (!_disposed && !_paused && _request == null) {
      _setPhase(
          value ? LumoConversationPhase.listening : LumoConversationPhase.waiting);
    }
  }

  void pause() {
    _paused = true;
    interrupt();
  }

  void resume() {
    _paused = false;
    _setPhase(LumoConversationPhase.idle);
  }

  void interrupt() {
    _generation++;
    _preparedCue = null;
    lastTaskAction = null;
    activeCue.value = null;
    _request?.cancel();
    _request = null;
    unawaited(LumoVoice.instance.stop());
    _setPhase(
        _paused ? LumoConversationPhase.paused : LumoConversationPhase.interrupted);
  }

  void _contextChanged() {
    _history.clear();
    interrupt();
  }

  void _voiceChanged() {
    if (_disposed ||
        _paused ||
        _request != null ||
        phase == LumoConversationPhase.listening) {
      return;
    }
    _setPhase(switch (LumoVoice.instance.status.value) {
      VoiceStatus.speaking => LumoConversationPhase.speaking,
      VoiceStatus.paused => LumoConversationPhase.paused,
      VoiceStatus.preparing => LumoConversationPhase.thinking,
      VoiceStatus.error => LumoConversationPhase.error,
      VoiceStatus.idle => LumoConversationPhase.waiting,
    });
  }

  void _setPhase(LumoConversationPhase value) {
    if (_disposed || value == phase) return;
    phase = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    context.removeListener(_contextChanged);
    LumoVoice.instance.status.removeListener(_voiceChanged);
    _request?.cancel();
    _history.clear();
    activeCue.dispose();
    unawaited(LumoVoice.instance.stop());
    super.dispose();
  }
}
