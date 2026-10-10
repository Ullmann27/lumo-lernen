import 'dart:async';

import 'package:flutter/foundation.dart';

import 'lumo_ai_proxy_client.dart';
import 'lumo_companion_engine.dart';
import 'lumo_context_engine.dart';
import 'lumo_sulafat_client.dart';
import 'lumo_voice.dart';

enum LumoConversationPhase {
  idle,
  listening,
  thinking,
  speaking,
  paused,
  error
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
    await LumoVoice.instance.stop();
    if (_disposed || _paused || generation != _generation) return cancelled;
    final request = LumoSpeechCancellation();
    _request = request;
    _setPhase(LumoConversationPhase.thinking);
    final app = context.appState;
    final state = app.state;
    final local = const LumoCompanionEngine()
        .answer(input: question, state: state, task: context.task);
    final safeInput = LumoChildSafetyFilter.inspect(question).allowed;
    var response = LumoAiProxyResponse(
        reply: context.isAssessment
            ? 'Im Test löst du die Aufgabe selbst. Danach üben wir gemeinsam.'
            : local.text,
        blocked: !safeInput,
        source: 'local_companion');
    if (!context.isAssessment &&
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
    if (!response.blocked) {
      _history.addAll([
        LumoAiChatTurn(role: 'user', content: question),
        LumoAiChatTurn(role: 'assistant', content: response.reply),
      ]);
    }
    while (_history.length > 8) {
      _history.removeAt(0);
    }
    _setPhase(LumoConversationPhase.idle);
    return response;
  }

  Future<void> speak(String text,
      {VoiceStyle style = VoiceStyle.explain}) async {
    if (_disposed || _paused || !context.appState.state.settings.voiceEnabled) {
      return;
    }
    await LumoVoice.instance.speakAndWait(text, style: style);
  }

  void listening(bool value) {
    if (!_disposed && !_paused && _request == null) {
      _setPhase(
          value ? LumoConversationPhase.listening : LumoConversationPhase.idle);
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
    _request?.cancel();
    _request = null;
    unawaited(LumoVoice.instance.stop());
    _setPhase(
        _paused ? LumoConversationPhase.paused : LumoConversationPhase.idle);
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
      VoiceStatus.preparing => LumoConversationPhase.thinking,
      VoiceStatus.error => LumoConversationPhase.error,
      VoiceStatus.idle => LumoConversationPhase.idle,
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
    unawaited(LumoVoice.instance.stop());
    super.dispose();
  }
}
