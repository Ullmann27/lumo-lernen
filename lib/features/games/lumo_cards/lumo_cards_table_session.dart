import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'lumo_cards_game_controller.dart';
import 'lumo_cards_bot_policy.dart';
import 'lumo_cards_models.dart';
import 'lumo_cards_rules.dart';

/// The renderer receives only the viewer's hand and public information.
/// No deck order, opponent hand or learning answer crosses the native bridge.
Map<String, Object?> cardsTableView(
  LumoCardsGameController controller, {
  required String token,
  required int revision,
  required int ack,
  String? error,
  bool reduceMotion = false,
}) {
  final state = controller.state;
  final viewer = controller.vsBot ? 0 : state.currentPlayerIndex;
  final hidden = !controller.vsBot && state.phase == GamePhase.passDevice;
  Map<String, Object?> card(LumoCard value) => {
        'id': value.id,
        'color': value.color.name,
        'type': value.type.name,
        'number': value.number,
      };
  final mayPlay = !controller.turnClock.value &&
      state.currentPlayerIndex == viewer &&
      state.phase == GamePhase.playing;
  return {
    'protocol': 1,
    'token': token,
    'revision': revision,
    'ack': ack,
    'roundId': controller.roundId,
    'phase': state.phase.name,
    'paused': controller.turnClock.value,
    'reduceMotion': reduceMotion,
    'viewer': viewer,
    'current': state.currentPlayerIndex,
    'players': [
      for (final player in state.players)
        {
          'name': player.name,
          'count': player.hand.length,
          'stars': player.stars,
        }
    ],
    'hand': hidden
        ? <Object?>[]
        : [
            for (final value in state.players[viewer].hand)
              {
                ...card(value),
                'playable': mayPlay &&
                    state.topCard != null &&
                    LumoCardsRules.isPlayable(
                        card: value,
                        topCard: state.topCard!,
                        selectedColor: state.selectedColor),
              }
          ],
    'top': state.topCard == null ? null : card(state.topCard!),
    'selectedColor': state.selectedColor.name,
    'drawCount': state.drawPile.length,
    'canDraw': mayPlay,
    'message': error ?? state.lastActionMessage ?? 'Dein Zug wartet auf dich.',
    'error': error != null,
    'winner': state.winnerIndex,
    if (state.phase == GamePhase.learningQuestion &&
        state.currentPlayerIndex == viewer &&
        state.pendingLearningQuestion != null)
      'question': {
        'prompt': state.pendingLearningQuestion!.prompt,
        'options': state.pendingLearningQuestion!.options,
      },
  };
}

abstract interface class CardsTableTransport {
  Future<void> open(String token, Map<String, Object?> state);
  Future<Map<String, dynamic>> poll(String token);
  Future<void> publish(String token, Map<String, Object?> state);
  Future<void> close(String token);
}

class NativeCardsTableTransport implements CardsTableTransport {
  static const _channel = MethodChannel('lumo_lernen/cards_table');
  @override
  Future<void> open(String token, Map<String, Object?> state) async {
    if (await _channel.invokeMethod<bool>(
            'open', {'token': token, 'state': jsonEncode(state)}) !=
        true) {
      throw StateError('Cards table did not open');
    }
  }

  @override
  Future<Map<String, dynamic>> poll(String token) async {
    final value = await _channel.invokeMethod<String>('poll', {'token': token});
    final decoded = jsonDecode(value ?? '{}');
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid Cards mailbox');
    }
    return decoded;
  }

  @override
  Future<void> publish(String token, Map<String, Object?> state) async {
    if (await _channel.invokeMethod<bool>(
            'publish', {'token': token, 'state': jsonEncode(state)}) !=
        true) {
      throw StateError('Cards table update failed');
    }
  }

  @override
  Future<void> close(String token) async {
    await _channel.invokeMethod<bool>('close', {'token': token});
  }
}

/// One temporary native surface of the existing, persisted Dart Cards round.
/// Actions carry the exact published revision and an increasing sequence.
/// Acknowledgement follows storage, so a retry cannot play the same card twice.
class LumoCardsTableSession {
  LumoCardsTableSession({
    required this.controller,
    required this.persist,
    required this.canUseProfile,
    CardsTableTransport? transport,
    this.reduceMotion = false,
    this.round = 1,
    this.totalRounds = 1,
    this.canCallLumo,
    this.onCallLumo,
    String? token,
    DateTime Function()? now,
  })  : transport = transport ?? NativeCardsTableTransport(),
        token = token ?? _newToken(),
        _now = now ?? DateTime.now;

  final LumoCardsGameController controller;
  final Future<void> Function() persist;
  final bool Function() canUseProfile;
  final CardsTableTransport transport;
  final bool reduceMotion;
  final int round;
  final int totalRounds;
  final bool Function()? canCallLumo;
  final void Function()? onCallLumo;
  final String token;
  final DateTime Function() _now;
  Timer? _timer;
  bool _open = false;
  bool _busy = false;
  bool _dirty = true;
  bool _userPaused = false;
  bool _nativeActive = false;
  int _pauseEpoch = 0;
  int _revision = 1;
  int _processed = 0;
  int _ack = 0;
  String? _error;
  LumoCardsGameState? _publishedState;
  bool _storagePaused = false;

  static String _newToken() {
    final rng = Random.secure();
    return List.generate(
        16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Map<String, Object?> get view => {
        ...cardsTableView(controller,
            token: token,
            revision: _revision,
            ack: _ack,
            error: _error,
            reduceMotion: reduceMotion),
        'canCall': canCallLumo?.call() ?? false,
        'round': round,
        'totalRounds': totalRounds,
        'difficulty': controller.difficulty.label,
      };

  Future<void> open({bool automaticPolling = true}) async {
    if (_open || !canUseProfile()) {
      throw StateError('Cards session unavailable');
    }
    _userPaused = controller.turnClock.value;
    controller.turnClock.pause();
    await persist();
    if (!canUseProfile()) throw StateError('Cards profile changed');
    await transport.open(token, view);
    _publishedState = controller.state;
    _open = true;
    controller.addListener(_changed);
    controller.turnClock.addListener(_changed);
    if (automaticPolling) {
      _timer = Timer.periodic(
          const Duration(milliseconds: 100), (_) => unawaited(pump()));
    }
  }

  void _changed() {
    _dirty = true;
  }

  Future<void> pump() async {
    if (!_open || _busy) return;
    _busy = true;
    try {
      if (!canUseProfile()) {
        controller.turnClock.pause();
        _error =
            'Deine Spiel-Freigabe hat sich geändert. Bitte zur Lern-App zurückkehren.';
        _revision++;
        await transport.publish(token, view);
        await close();
        return;
      }
      final mailbox = await transport.poll(token);
      if (!_open || !canUseProfile()) return;
      final life = mailbox['lifecycle'];
      final stamp = life is Map ? life['stamp'] : null;
      final age = stamp is int ? _now().millisecondsSinceEpoch - stamp : 100000;
      final active =
          life is Map && life['active'] == true && age >= 0 && age < 2500;
      final pauseEpoch = life is Map ? life['pauseEpoch'] : null;
      // Preserve a background pause even if Android suspended Dart between
      // the native onPause and onResume heartbeats.
      if ((pauseEpoch is int && pauseEpoch > _pauseEpoch) ||
          (!active && _nativeActive)) {
        if (pauseEpoch is int) _pauseEpoch = pauseEpoch;
        _userPaused = true;
        controller.turnClock.pause();
      }
      if (active != _nativeActive) {
        _nativeActive = active;
        if (active && !_userPaused) {
          controller.turnClock.resume();
        } else {
          controller.turnClock.pause();
        }
      }
      final request = mailbox['request'];
      if (request is Map<String, dynamic>) _consume(request);
      if (!_dirty) return;
      final savingState = controller.state;
      await persist();
      if (!_open || !canUseProfile()) return;
      if (!identical(savingState, controller.state)) return;
      _ack = _processed;
      _error = null;
      _revision++;
      await transport.publish(token, view);
      _publishedState = controller.state;
      _dirty = false;
      if (_storagePaused && _nativeActive && !_userPaused) {
        _storagePaused = false;
        controller.turnClock.resume();
      }
    } catch (_) {
      // Keep the current action in memory and retry persistence before ack.
      // Existing session and idempotent reward repositories remain authoritative.
      controller.turnClock.pause();
      _storagePaused = true;
      _dirty = true;
      _error = 'Die Runde wartet aufs Speichern. Bitte kurz warten.';
    } finally {
      _busy = false;
    }
  }

  void _consume(Map<String, dynamic> request) {
    final sequence = request['sequence'];
    if (request['token'] != token ||
        sequence is! int ||
        sequence <= _processed ||
        sequence > 1000000000) {
      return;
    }
    _processed = sequence;
    _dirty = true;
    if (request['revision'] != _revision ||
        !_nativeActive ||
        !canUseProfile() ||
        !identical(_publishedState, controller.state)) {
      return;
    }
    final action = request['action'];
    if (action == 'pause') {
      _userPaused = true;
      controller.turnClock.pause();
      return;
    }
    if (action == 'resume') {
      _userPaused = false;
      controller.turnClock.resume();
      return;
    }
    if (controller.turnClock.value) return;
    final state = controller.state;
    final viewer = controller.vsBot ? 0 : state.currentPlayerIndex;
    if (state.currentPlayerIndex != viewer) return;
    switch (action) {
      case 'call':
        if (canCallLumo?.call() == true) onCallLumo?.call();
      case 'play':
        final id = request['cardId'];
        final matching =
            state.currentPlayer.hand.where((card) => card.id == id);
        if (matching.isNotEmpty) controller.playCard(matching.first);
      case 'draw':
        controller.drawCard();
      case 'color':
        final matching = LumoCardColor.values
            .where((color) => color.name == request['color']);
        if (matching.isNotEmpty) controller.selectColor(matching.first);
      case 'answer':
        final answer = request['index'];
        final question = state.pendingLearningQuestion;
        if (answer is int &&
            question != null &&
            answer >= 0 &&
            answer < question.options.length) {
          controller.answerLearningQuestion(answer);
        }
      case 'handover':
        controller.confirmHandover();
    }
  }

  Future<void> close() async {
    if (!_open) return;
    _open = false;
    _timer?.cancel();
    _timer = null;
    controller.removeListener(_changed);
    controller.turnClock.removeListener(_changed);
    controller.turnClock.pause();
    await transport.close(token);
  }
}
