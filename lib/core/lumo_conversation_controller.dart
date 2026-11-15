import 'dart:async';

import 'package:flutter/foundation.dart';
import '../widgets/fox/lumo_companion_requests.dart';

import 'lumo_ai_proxy_client.dart';
import 'lumo_companion_engine.dart';
import 'lumo_context_engine.dart';
import 'lumo_learning_dialogue_intent.dart';
import 'lumo_learning_session_contract.dart';
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

/// One bounded conversation over the existing task bus. Only the task owner
/// handles permitted requests; this controller cannot score or grant rewards.
class LumoConversationController extends ChangeNotifier {
  LumoConversationController(
    this.context, {
    LumoAiProxyClient proxy = const LumoAiProxyClient(),
    this.onInterrupt,
  }) : _proxy = proxy {
    _conversationScope = context.conversationScope;
    context.addListener(_contextChanged);
    context.requests.learningCancellation.addListener(_busCancelled);
    LumoVoice.instance.status.addListener(_voiceChanged);
    LumoVoice.instance.clipMouth.addListener(_publishAudio);
    LumoVoice.instance.mediaAudibility.addListener(_publishAudio);
  }

  final LumoContextEngine context;
  final LumoAiProxyClient _proxy;
  final VoidCallback? onInterrupt;
  final List<LumoAiChatTurn> _history = [];
  List<LumoAiChatTurn> get history => List.unmodifiable(_history);
  LumoConversationPhase phase = LumoConversationPhase.idle;
  LumoSpeechCancellation? _request;
  String _conversationScope = '';
  int _generation = 0;
  int _turnSequence = 0;
  int _utteranceSequence = 0;
  int _responseGeneration = -1;
  int _responseRevision = -1;
  int _responseTurn = 0;
  double _responseSpeed = 1;
  bool _responseMaySpeak = false;
  LumoLearningIdentity? _responseIdentity;
  LumoLearningIdentity? _audioIdentity;
  LumoLearningPresentation? _audioPresentation;
  int? _audioUtterance;
  String _subtitle = '';
  int _audioCompletionBefore = 0;
  bool _disposed = false;
  bool _paused = false;
  bool _dispatchingAction = false;
  String? _actionScope;
  bool _emittingCancellation = false;

  bool get responseMaySpeak => _responseMaySpeak;
  int get turnId => _responseTurn;
  LumoLearningIdentity? get responseIdentity => _responseIdentity;
  bool get handlingCurrentLessonAction => _ownCompatibleAction;

  static const cancelled =
      LumoAiProxyResponse(reply: '', blocked: false, source: 'cancelled');

  Future<LumoAiProxyResponse> ask(String question) async {
    final input = question.trim();
    if (_disposed || input.isEmpty) return cancelled;
    final intent = LumoLearningDialogueIntent.parse(input, context.task);
    if (intent?.action == LumoLearningAction.stop) {
      interrupt();
      return const LumoAiProxyResponse(
          reply: 'Ich habe aufgehört. Du kannst in Ruhe weitermachen.',
          blocked: false,
          source: 'local_stopped');
    }
    if (_paused) return cancelled;
    if (input.length > 1200) {
      return const LumoAiProxyResponse(
          reply: 'Stell mir bitte eine kürzere Frage. '
              'Wir gehen sie dann gemeinsam durch.',
          blocked: false,
          source: 'local_input_too_long');
    }

    // A child may replace a pending question. Stop old work before capturing
    // the new lease, so the replacement's gesture is never cancelled by it.
    interrupt(reason: 'new_turn');
    final generation = _generation;
    final turn = ++_turnSequence;
    final scope = context.conversationScope;
    await LumoVoice.instance.stop();
    if (!_current(generation) || scope != context.conversationScope) {
      return cancelled;
    }
    _setPhase(LumoConversationPhase.thinking);
    final safeInput = LumoChildSafetyFilter.inspect(input).allowed;
    if (safeInput && !context.isAssessment) {
      context.requests.recordLearningEvent(
          LumoLearningEventKind.childAskedQuestion,
          context: context.task);
    }

    if (safeInput && intent != null) {
      final command = _handleCommand(input, intent, turn, scope);
      if (!_current(generation) || scope != context.conversationScope) {
        return cancelled;
      }
      _completeResponse(input, command, generation, turn,
          speed: intent.action == LumoLearningAction.slower ? .75 : 1);
      return command;
    }

    if (context.isAssessment) {
      final response = LumoAiProxyResponse(
          reply:
              'Im Test löst du die Aufgabe selbst. Danach üben wir gemeinsam.',
          blocked: !safeInput,
          source: 'local_assessment_no_help');
      _completeResponse(input, response, generation, turn);
      return response;
    }
    final visibleTask = context.task;
    if (safeInput &&
        visibleTask != null &&
        !visibleTask.allowedActions.contains(LumoLearningAction.explain) &&
        !visibleTask.allowedActions.contains(LumoLearningAction.hint)) {
      // Unclassified wording cannot bypass the task owner's help permissions
      // through either the local fallback engine or the online provider.
      _completeResponse(input, _unavailable, generation, turn);
      return _unavailable;
    }

    final revision = context.revision;
    final identity = context.learningIdentity;
    final request = LumoSpeechCancellation();
    _request = request;
    final state = context.appState.state;
    final local = const LumoCompanionEngine()
        .answer(input: input, state: state, task: context.task);
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
            message: input,
            history: history,
            context: context.aiContext,
            extras: context.remoteContext,
            cancellation: request);
        if (online.isCloudAnswer || online.blocked) response = online;
      } catch (_) {
        // The verified local help remains available without provider errors.
      }
    }
    if (!_current(generation) ||
        revision != context.revision ||
        request.cancelled ||
        (identity != null &&
            !context.requests.isCurrentLearningIdentity(identity))) {
      return cancelled;
    }
    _request = null;
    _completeResponse(input, response, generation, turn);
    return response;
  }

  LumoAiProxyResponse _handleCommand(
      String input, LumoLearningDialogueIntent intent, int turn, String scope) {
    final requests = context.requests;
    final identity = context.learningIdentity;
    if (context.isAssessment) {
      final task = context.task;
      final instructionOnly = task != null &&
          task.hasExplicitAllowedActions &&
          (intent.action == LumoLearningAction.repeat ||
              intent.action == LumoLearningAction.slower) &&
          task.allowedActions.contains(intent.action);
      if (!instructionOnly) {
        return const LumoAiProxyResponse(
            reply:
                'Im Test löst du die Aufgabe selbst. Danach üben wir gemeinsam.',
            blocked: false,
            source: 'local_assessment_no_help');
      }
    }
    var accepted = false;
    if (identity != null) {
      _dispatchingAction = true;
      _actionScope = scope;
      try {
        accepted = requests.requestLearningAction(intent.action,
            identity: identity, candidate: intent.candidate, turnId: turn);
      } finally {
        _dispatchingAction = false;
        _actionScope = null;
      }
    }
    if (scope != context.conversationScope) return cancelled;
    if (intent.action == LumoLearningAction.proposeAnswer) {
      return LumoAiProxyResponse(
          reply: accepted
              ? '${intent.isCorrection ? 'Ich ändere deinen Vorschlag auf' : 'Dein Vorschlag ist'} '
                  '„${intent.candidate}“. Schau ihn dir bei der Aufgabe an. '
                  'Erst wenn du ihn bestätigst, wird die Antwort geprüft.'
              : 'Du kannst deine Antwort direkt bei der Aufgabe eingeben '
                  'und dort selbst bestätigen.',
          blocked: false,
          source:
              accepted ? 'local_answer_proposal' : 'local_action_unavailable');
    }
    if (!accepted) {
      // The task owner determines the next permitted help. A rejected bus
      // request must not fall through to a generated/local explanation or a
      // figure gesture, even when an older snapshot still contains help text.
      return _unavailable;
    }
    final task = context.task;
    if (context.isAssessment) {
      // Reading the visible instruction is a distinct permission. Never
      // inspect stored hints, worked examples or the local/provider engine.
      if (task == null || task.prompt.trim().isEmpty) return _unavailable;
      return LumoAiProxyResponse(
          reply: task.prompt,
          blocked: false,
          source: 'local_assessment_instruction');
    }
    final explanation = const LumoCompanionEngine()
        .answer(
            input: 'Erklär mir: $input',
            state: context.appState.state,
            task: task)
        .text;
    final current = context.learningIdentity;
    if (current != null && task != null) {
      final target = task.objectIds.contains('bridge_two') &&
              RegExp(r'\b(warum|wieso|weshalb)\b', caseSensitive: false)
                  .hasMatch(input)
          ? 'bridge_two'
          : task.objectIds.contains('pattern_group')
              ? 'pattern_group'
              : task.objectIds.contains('syllable_0')
                  ? 'syllable_0'
                  : task.objectIds.isEmpty
                      ? null
                      : task.objectIds.first;
      requests.publishLearningPresentation(LumoLearningPresentation(
        identity: current,
        turnId: turn,
        gazeObjectId: task.allowedActions.contains(LumoLearningAction.look)
            ? target
            : null,
        pointObjectId: task.allowedActions.contains(LumoLearningAction.point)
            ? target
            : null,
        expression: task.lastCorrect == false ? 'comfort' : 'attentive',
        animationState: 'explaining',
      ));
    }
    return LumoAiProxyResponse(
        reply: explanation,
        blocked: false,
        source: 'local_lesson_${intent.action.name}');
  }

  static const _unavailable = LumoAiProxyResponse(
      reply: 'Diese Hilfe ist bei der aktuellen Aufgabe nicht freigegeben. '
          'Du kannst dort in Ruhe selbst weiterarbeiten.',
      blocked: false,
      source: 'local_action_unavailable');

  void _completeResponse(
      String input, LumoAiProxyResponse response, int generation, int turn,
      {double speed = 1}) {
    if (response.source == 'cancelled') return;
    if (!response.blocked) {
      _history.addAll([
        LumoAiChatTurn(role: 'user', content: input),
        LumoAiChatTurn(role: 'assistant', content: response.reply),
      ]);
      while (_history.length > 8) {
        _history.removeAt(0);
      }
    }
    _responseGeneration = generation;
    _responseRevision = context.revision;
    _responseIdentity = context.learningIdentity;
    _responseTurn = turn;
    _responseSpeed = speed;
    _responseMaySpeak = true;
    _setPhase(LumoConversationPhase.idle);
  }

  bool _current(int generation) =>
      !_disposed && !_paused && generation == _generation;

  Future<void> speak(String text,
      {VoiceStyle style = VoiceStyle.explain}) async {
    if (!_current(_responseGeneration) ||
        !_responseMaySpeak ||
        _responseRevision != context.revision ||
        !context.appState.state.settings.voiceEnabled ||
        (_responseIdentity != null &&
            !context.requests.isCurrentLearningIdentity(_responseIdentity!))) {
      return;
    }
    final generation = _generation;
    final utterance = ++_utteranceSequence;
    _audioUtterance = utterance;
    _audioIdentity = _responseIdentity;
    _audioPresentation = context.requests.learningPresentation.value;
    _audioCompletionBefore = LumoVoice.instance.completedPlaybackCount;
    _subtitle = text;
    await LumoVoice.instance
        .speakAndWait(text, style: style, speedFactor: _responseSpeed);
    if (_current(generation) && _audioUtterance == utterance) {
      _publishAudio();
      _audioUtterance = null;
      _audioIdentity = null;
      _audioPresentation = null;
    }
  }

  void listening(bool value) {
    if (!_disposed && !_paused && _request == null) {
      _setPhase(
          value ? LumoConversationPhase.listening : LumoConversationPhase.idle);
    }
  }

  void pause() {
    _paused = true;
    interrupt(reason: 'app_interrupted');
  }

  void resume() {
    _paused = false;
    _setPhase(LumoConversationPhase.idle);
  }

  void interrupt({String reason = 'stop'}) {
    if (_disposed) return;
    _invalidateWork();
    _emittingCancellation = true;
    try {
      context.requests.cancelLearningInteraction(reason: reason);
    } finally {
      _emittingCancellation = false;
    }
  }

  void _invalidateWork() {
    _generation++;
    _request?.cancel();
    _request = null;
    _responseMaySpeak = false;
    _audioUtterance = null;
    _audioIdentity = null;
    _audioPresentation = null;
    onInterrupt?.call();
    unawaited(LumoVoice.instance.stop());
    _setPhase(
        _paused ? LumoConversationPhase.paused : LumoConversationPhase.idle);
  }

  bool get _ownCompatibleAction =>
      _dispatchingAction && context.conversationScope == _actionScope;

  void _busCancelled() {
    if (_disposed || _emittingCancellation) return;
    if (_ownCompatibleAction &&
        context.requests.learningCancellation.value?.reason ==
            'context_changed') {
      return;
    }
    _invalidateWork();
  }

  void _contextChanged() {
    final scope = context.conversationScope;
    if (scope != _conversationScope) {
      _history.clear();
      _conversationScope = scope;
    } else if (_ownCompatibleAction) {
      return;
    }
    interrupt(reason: 'context_changed');
  }

  void _voiceChanged() {
    _publishAudio();
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
      VoiceStatus.idle => LumoConversationPhase.idle,
    });
  }

  void _publishAudio() {
    final identity = _audioIdentity;
    final utterance = _audioUtterance;
    if (_disposed ||
        identity == null ||
        utterance == null ||
        !context.requests.isCurrentLearningIdentity(identity)) {
      return;
    }
    final voice = LumoVoice.instance;
    final status = voice.status.value;
    final playing = status == VoiceStatus.speaking;
    final audioState = switch (status) {
      VoiceStatus.preparing => 'preparing',
      VoiceStatus.speaking => 'playing',
      VoiceStatus.paused => 'paused',
      VoiceStatus.error => 'unavailable',
      VoiceStatus.idle => voice.completedPlaybackCount > _audioCompletionBefore
          ? 'completed'
          : 'idle',
    };
    context.requests.publishLearningAudio(LumoLearningAudioFrame(
      identity: identity,
      turnId: _responseTurn,
      utteranceId: utterance,
      state: audioState,
      subtitle: _subtitle,
      positionMs: voice.mediaPosition.inMilliseconds,
      durationMs: voice.mediaDuration.inMilliseconds,
      audible: playing && voice.mediaAudible,
      envelopeAvailable: playing && voice.mouthEnvelopeAvailable,
      envelope:
          playing && voice.mediaAudible ? (voice.clipMouth.value ?? 0) : 0,
    ));
    final presentation = _audioPresentation;
    if (presentation != null && presentation.identity.matches(identity)) {
      context.requests.publishLearningPresentation(LumoLearningPresentation(
        identity: identity,
        turnId: _responseTurn,
        utteranceId: utterance,
        gazeObjectId: presentation.gazeObjectId,
        pointObjectId: playing ? presentation.pointObjectId : null,
        expression: presentation.expression,
        animationState: playing && voice.mediaAudible ? 'speaking' : 'idle',
      ));
    }
  }

  void _setPhase(LumoConversationPhase value) {
    if (_disposed || value == phase) return;
    phase = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    interrupt(reason: 'page_exit');
    _disposed = true;
    context.removeListener(_contextChanged);
    context.requests.learningCancellation.removeListener(_busCancelled);
    LumoVoice.instance.status.removeListener(_voiceChanged);
    LumoVoice.instance.clipMouth.removeListener(_publishAudio);
    LumoVoice.instance.mediaAudibility.removeListener(_publishAudio);
    _request?.cancel();
    _history.clear();
    super.dispose();
  }
}
