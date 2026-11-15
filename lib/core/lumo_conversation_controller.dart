import 'dart:async';

import 'package:flutter/foundation.dart';
import '../widgets/fox/lumo_companion_requests.dart';

import 'lumo_ai_proxy_client.dart';
import 'lumo_companion_engine.dart';
import 'lumo_context_engine.dart';
import 'lumo_sulafat_client.dart';
import 'lumo_task_dialogue.dart';
import 'lumo_voice.dart';

enum LumoConversationPhase {
  idle,
  listening,
  thinking,
  speaking,
  waiting,
  interrupted,
  paused,
  error
}

/// One identity for subtitle, audio, object focus and an amplitude-based mouth.
/// Position is the media player's position, never a guessed word duration.
class LumoConversationUtterance {
  const LumoConversationUtterance({
    required this.id,
    required this.sessionId,
    required this.taskId,
    required this.turnId,
    required this.contextRevision,
    required this.subtitle,
    this.objectIds = const [],
    this.gesture = LumoTaskDialogueGesture.lookAtChild,
  });
  final String id, sessionId, taskId, turnId, subtitle;
  final int contextRevision;
  final List<String> objectIds;
  final LumoTaskDialogueGesture gesture;
  bool get phonemeTimingAvailable => false;
}

/// A bounded RAM-only conversation over the real lesson. The controller has no
/// grading, reward, navigation or persistence capability. Lesson answers remain
/// drafts until the task owner confirms and validates them.
class LumoConversationController extends ChangeNotifier {
  LumoConversationController(
    this.context, {
    LumoAiProxyClient proxy = const LumoAiProxyClient(),
  }) : _proxy = proxy {
    _scope = context.conversationScope;
    context.addListener(_contextChanged);
    LumoVoice.instance.status.addListener(_voiceChanged);
    LumoVoice.instance.clipMouth.addListener(_playbackChanged);
  }

  static int _nextSession = 0;
  final String sessionId = 'conversation-${++_nextSession}';
  final LumoContextEngine context;
  final LumoAiProxyClient _proxy;
  final List<LumoAiChatTurn> _history = [];
  List<LumoAiChatTurn> get history => List.unmodifiable(_history);
  LumoConversationPhase phase = LumoConversationPhase.idle;
  LumoSpeechCancellation? _request;
  LumoTaskDialogueReply? lastDialogue;
  LumoConversationUtterance? utterance;
  LumoAiProxyResponse? _lastResponse;
  String _scope = '';
  int _generation = 0;
  int _turn = 0;
  bool _disposed = false;
  bool _paused = false;
  bool _speakingOwned = false;
  LumoTaskDialogueReply? _focusedReply;

  static const cancelled =
      LumoAiProxyResponse(reply: '', blocked: false, source: 'cancelled');

  Duration get playbackPosition =>
      _ownsPlayback ? LumoVoice.instance.playbackPosition : Duration.zero;
  double get mouthOpening =>
      _ownsPlayback ? LumoVoice.instance.clipMouth.value ?? 0 : 0;
  bool get _ownsPlayback =>
      _speakingOwned &&
      utterance != null &&
      LumoVoice.instance.activeUtteranceId == utterance!.id;

  Future<LumoAiProxyResponse> ask(
    String question, {
    double? recognitionConfidence,
    bool isFinal = true,
  }) async {
    if (_disposed || _paused || question.trim().isEmpty) return cancelled;
    if (question.length > 1200) {
      return const LumoAiProxyResponse(
          reply: 'Stell mir bitte eine kürzere Frage. '
              'Wir gehen sie dann gemeinsam durch.',
          blocked: false,
          source: 'local_input_too_long');
    }
    final generation = ++_generation;
    final revision = context.revision;
    final previous = lastDialogue;
    _clearFocus();
    _request?.cancel();
    _request = null;
    _speakingOwned = false;
    utterance = null;
    await LumoVoice.instance.stop();
    if (!_current(generation, revision)) return cancelled;
    final request = LumoSpeechCancellation();
    _request = request;
    _setPhase(LumoConversationPhase.thinking);
    final state = context.appState.state;
    final task = context.task;
    final safeInput = LumoChildSafetyFilter.inspect(question).allowed;
    final local = const LumoCompanionEngine()
        .answer(input: question, state: state, task: task);
    final snapshot = task?.dialogue;
    final dialogue = snapshot == null
        ? null
        : const LumoTaskDialogueEngine().respond(
            input: question,
            snapshot: snapshot,
            previousReply: previous,
            recognitionConfidence: recognitionConfidence,
            isFinal: isFinal);
    var response = LumoAiProxyResponse(
        reply: context.isAssessment
            ? 'Im Test löst du die Aufgabe selbst. Danach üben wir gemeinsam.'
            : local.text,
        blocked: !safeInput,
        source: 'local_companion');
    lastDialogue = null;

    // Serious concerns are handled locally before any provider or logging.
    if (dialogue?.intent == LumoTaskDialogueIntent.concern) {
      lastDialogue = dialogue;
      response = LumoAiProxyResponse(
          reply: dialogue!.text, blocked: true, source: 'local_support');
    } else if (dialogue?.shouldStopSpeech == true) {
      lastDialogue = dialogue;
      response = LumoAiProxyResponse(
          reply: dialogue!.text, blocked: false, source: dialogue.source);
    } else if (!isFinal ||
        (recognitionConfidence != null &&
            (!recognitionConfidence.isFinite || recognitionConfidence < .65))) {
      response = const LumoAiProxyResponse(
          reply: 'Ich habe dich noch nicht sicher verstanden. '
              'Sag es bitte noch einmal oder tippe deine Frage.',
          blocked: false,
          source: 'local_clarification');
    } else if (safeInput &&
        !context.isAssessment &&
        dialogue?.handled == true) {
      lastDialogue = dialogue;
      response = LumoAiProxyResponse(
          reply: dialogue!.text, blocked: false, source: dialogue.source);
    } else if (safeInput && !context.isAssessment) {
      final q = question.trim().toLowerCase().replaceAll(RegExp(r'[.!?]'), '');
      if (RegExp(r'^(stopp?|halt)( bitte)?$').hasMatch(q)) {
        response = const LumoAiProxyResponse(
            reply: 'Gestoppt. Ich höre zu.',
            blocked: false,
            source: 'local_stop');
      } else if (q.contains('allein versuchen') ||
          q.contains('selbst versuchen') ||
          q.contains('ohne hilfe')) {
        response = const LumoAiProxyResponse(
            reply: 'Du kannst es in Ruhe allein versuchen. '
                'Wenn du Hilfe möchtest, bin ich hier.',
            blocked: false,
            source: 'local_alone');
      } else if ((q.contains('noch einmal') ||
              q.contains('nochmal') ||
              q.contains('langsamer')) &&
          _lastResponse != null) {
        response = LumoAiProxyResponse(
            reply: _lastResponse!.reply,
            blocked: _lastResponse!.blocked,
            source: q.contains('langsamer') ? 'local_slower' : 'local_repeat');
      } else if (task == null &&
          isFinal &&
          (recognitionConfidence == null || recognitionConfidence >= .65) &&
          _proxy.isConfigured(state.settings)) {
        // Free provider text is confined to general chat. A model cannot
        // replace the task owner's reviewed explanations, answers or marks.
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
          // Existing local knowledge remains available without network.
        }
      }
    }
    if (!_current(generation, revision) || request.cancelled) return cancelled;
    _request = null;
    if (!response.blocked && isFinal) {
      if (!context.isAssessment) {
        context.requests.recordLearningEvent(
            LumoLearningEventKind.childAskedQuestion,
            context: task);
      }
      _history.addAll([
        LumoAiChatTurn(role: 'user', content: question),
        LumoAiChatTurn(role: 'assistant', content: response.reply),
      ]);
      while (_history.length > 8) {
        _history.removeAt(0);
      }
    }
    final turn = '${++_turn}';
    utterance = LumoConversationUtterance(
      id: '$sessionId-$turn',
      sessionId: snapshot?.sessionId ?? sessionId,
      taskId: task?.taskId ?? '',
      turnId: turn,
      contextRevision: revision,
      subtitle: response.reply,
      objectIds: lastDialogue?.targetObjectIds ?? const [],
      gesture: lastDialogue?.gesture ?? LumoTaskDialogueGesture.lookAtChild,
    );
    if (lastDialogue != null && lastDialogue!.targetObjectIds.isNotEmpty) {
      _focusedReply = lastDialogue;
      context.requests.dialogueFocus.value = _focusedReply;
    }
    if (response.source != 'local_stop' &&
        response.source != 'local_alone' &&
        lastDialogue?.shouldStopSpeech != true) _lastResponse = response;
    _setPhase(lastDialogue?.shouldStopSpeech == true ||
            response.source == 'local_stop' ||
            response.source == 'local_alone'
        ? LumoConversationPhase.interrupted
        : LumoConversationPhase.waiting);
    return response;
  }

  Future<void> speak(String text,
      {VoiceStyle style = VoiceStyle.explain,
      String? expectedUtteranceId}) async {
    if (_disposed ||
        _paused ||
        _speakingOwned ||
        phase == LumoConversationPhase.interrupted ||
        !context.appState.state.settings.voiceEnabled ||
        lastDialogue?.shouldStopSpeech == true) return;
    final current = utterance;
    if (current == null ||
        current.subtitle != text ||
        (expectedUtteranceId != null && current.id != expectedUtteranceId) ||
        current.contextRevision != context.revision) return;
    final generation = _generation;
    final revision = context.revision;
    // speechParts identify visible syllables, not a replacement for the spoken
    // explanation. Always speak the entire subtitle, including a "why" reply.
    final fragments = [text];
    _speakingOwned = true;
    final tempo = lastDialogue?.speechRateMultiplier ??
        (_lastResponse?.source == 'local_slower' ? .75 : 1.0);
    for (final fragment in fragments) {
      if (!_current(generation, revision) || !_speakingOwned) return;
      await LumoVoice.instance.speakAndWait(fragment,
          style: style, utteranceId: current.id, tempo: tempo);
      if (!_current(generation, revision) || !_speakingOwned) return;
      if (LumoVoice.instance.lastError.value != null) break;
    }
    _speakingOwned = false;
    _setPhase(LumoVoice.instance.lastError.value == null
        ? LumoConversationPhase.waiting
        : LumoConversationPhase.error);
  }

  void listening(bool value) {
    if (!_disposed && !_paused && _request == null && !_speakingOwned) {
      _setPhase(value
          ? LumoConversationPhase.listening
          : LumoConversationPhase.waiting);
    }
  }

  void waitForChild() {
    if (!_disposed && !_paused && _request == null && !_speakingOwned) {
      _setPhase(LumoConversationPhase.waiting);
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
    _clearFocus();
    _generation++;
    _request?.cancel();
    _request = null;
    _speakingOwned = false;
    utterance = null;
    unawaited(LumoVoice.instance.stop());
    _setPhase(_paused
        ? LumoConversationPhase.paused
        : LumoConversationPhase.interrupted);
  }

  void _clearFocus() {
    if (_focusedReply != null &&
        identical(context.requests.dialogueFocus.value, _focusedReply)) {
      context.requests.dialogueFocus.value = null;
    }
    _focusedReply = null;
  }

  void clearMemory() {
    interrupt();
    _history.clear();
    _lastResponse = null;
    lastDialogue = null;
    notifyListeners();
  }

  bool _current(int generation, int revision) =>
      !_disposed &&
      !_paused &&
      generation == _generation &&
      revision == context.revision;

  void _contextChanged() {
    final next = context.conversationScope;
    if (next != _scope) {
      _scope = next;
      _history.clear();
      _lastResponse = null;
      lastDialogue = null;
    }
    interrupt();
  }

  void _voiceChanged() {
    if (_disposed || _paused || _request != null || !_speakingOwned) return;
    final status = LumoVoice.instance.status.value;
    if (status == VoiceStatus.speaking && !_ownsPlayback) {
      _speakingOwned = false;
      _setPhase(LumoConversationPhase.interrupted);
      return;
    }
    _setPhase(switch (status) {
      VoiceStatus.speaking => LumoConversationPhase.speaking,
      VoiceStatus.paused => LumoConversationPhase.paused,
      VoiceStatus.preparing => LumoConversationPhase.thinking,
      VoiceStatus.error => LumoConversationPhase.error,
      VoiceStatus.idle => LumoConversationPhase.waiting,
    });
  }

  void _playbackChanged() {
    if (!_disposed && _ownsPlayback) notifyListeners();
  }

  void _setPhase(LumoConversationPhase value) {
    if (_disposed || value == phase) return;
    phase = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearFocus();
    _disposed = true;
    context.removeListener(_contextChanged);
    LumoVoice.instance.status.removeListener(_voiceChanged);
    LumoVoice.instance.clipMouth.removeListener(_playbackChanged);
    _request?.cancel();
    _history.clear();
    unawaited(LumoVoice.instance.stop());
    super.dispose();
  }
}
