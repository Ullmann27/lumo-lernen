import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'connect_four_engine.dart';
import 'connect_four_round.dart';

abstract interface class ConnectFourTransport {
  Future<void> open(String token, Map<String, Object?> state);
  Future<Map<String, dynamic>> poll(String token);
  Future<void> publish(String token, Map<String, Object?> state);
  Future<void> close(String token);
}

class NativeConnectFourTransport implements ConnectFourTransport {
  static const _channel = MethodChannel('lumo_lernen/connect_four');
  Future<void> _write(
      String method, String token, Map<String, Object?> state) async {
    if (await _channel.invokeMethod<bool>(
            method, {'token': token, 'state': jsonEncode(state)}) !=
        true) {
      throw StateError('Die Vier-Gewinnt-Verbindung ist nicht verfügbar');
    }
  }

  @override
  Future<void> open(String token, Map<String, Object?> state) =>
      _write('open', token, state);
  @override
  Future<void> publish(String token, Map<String, Object?> state) =>
      _write('publish', token, state);
  @override
  Future<Map<String, dynamic>> poll(String token) async {
    final raw = await _channel.invokeMethod<String>('poll', {'token': token});
    final parsed = jsonDecode(raw ?? '{}');
    if (parsed is! Map<String, dynamic>)
      throw StateError('Ungültige Spielverbindung');
    return parsed;
  }

  @override
  Future<void> close(String token) async {
    await _channel.invokeMethod<bool>('close', {'token': token});
  }
}

/// No renderer rule evaluation. It receives the existing Dart engine's board
/// and sends only bounded intent with exact session/round/revision/sequence.
class ConnectFourTableSession {
  ConnectFourTableSession(
      {required this.controller,
      ConnectFourTransport? transport,
      this.reduceMotion = false,
      String? token,
      DateTime Function()? now})
      : transport = transport ?? NativeConnectFourTransport(),
        token = token ?? ConnectFourRound.newId(),
        _now = now ?? DateTime.now;
  final ConnectFourRoundController controller;
  final ConnectFourTransport transport;
  final String token;
  final bool reduceMotion;
  final DateTime Function() _now;
  Timer? _timer;
  bool _open = false,
      _busy = false,
      _active = false,
      _paused = false,
      _exit = false;
  int _revision = 1, _ack = 0, _rejected = 0, _pauseEpoch = 0;
  int _remaining = 0, _lastTick = 0;
  String? _error;
  bool get isOpen => _open;
  bool get paused => !_active || _paused;
  bool get canDrop =>
      _open &&
      !paused &&
      !_exit &&
      _remaining == 0 &&
      controller.engine.phase == ConnectPhase.playing &&
      (controller.round.twoPlayers ||
          controller.engine.turn == ConnectPiece.child);

  Map<String, Object?> get view {
    final game = controller.engine;
    return {
      'schema': 1,
      'game': 'connect_four',
      'token': token,
      'roundId': controller.round.id,
      'owner': controller.round.owner,
      'revision': _revision,
      'ack': _ack,
      'rejected': _rejected,
      'recordRevision': controller.round.revision,
      'paused': paused,
      'exit': _exit,
      'canDrop': canDrop,
      'reduceMotion': reduceMotion,
      'twoPlayers': controller.round.twoPlayers,
      'level': controller.round.level.name,
      'phase': game.phase.name,
      'turn': game.turn.index,
      'columns': controller.round.columns,
      'validColumns': game.validColumns,
      'board': [
        for (var r = 0; r < 6; r++)
          for (var c = 0; c < 7; c++) game.at(r, c).index
      ],
      'winningLine': [
        for (final p in game.winningLine) [p.row, p.column]
      ],
      'rewarded': controller.round.rewarded,
      'error': _error,
    };
  }

  Future<void> open({bool automaticPolling = true}) async {
    if (_open || !controller.canUseProfile())
      throw StateError('Spiel nicht verfügbar');
    await controller.settleReward();
    if (!controller.canUseProfile())
      throw StateError('Kinderprofil hat gewechselt');
    _open = true;
    _remaining = controller.engine.turn == ConnectPiece.lumo &&
            !controller.round.twoPlayers
        ? 540
        : 0;
    _lastTick = _now().millisecondsSinceEpoch;
    try {
      await transport.open(token, view);
    } catch (_) {
      _open = false;
      rethrow;
    }
    if (!controller.canUseProfile()) {
      await close();
      throw StateError('Kinderprofil hat gewechselt');
    }
    if (automaticPolling)
      _timer = Timer.periodic(
          const Duration(milliseconds: 100), (_) => unawaited(pump()));
  }

  Future<void> pump() async {
    if (!_open || _busy) return;
    _busy = true;
    try {
      if (!controller.canUseProfile()) {
        await close();
        return;
      }
      final before = jsonEncode(view);
      final box = await transport.poll(token);
      if (!_open || !controller.canUseProfile()) {
        await close();
        return;
      }
      final tick = _now().millisecondsSinceEpoch;
      final elapsed = (tick - _lastTick).clamp(0, 500);
      _lastTick = tick;
      if (!paused) _remaining = (_remaining - elapsed).clamp(0, 2000);
      final life = box['lifecycle'];
      final stamp = life is Map ? life['stamp'] : null;
      final age = stamp is int ? tick - stamp : 100000;
      final epoch = life is Map ? life['pauseEpoch'] : null;
      final active =
          life is Map && life['active'] == true && age >= 0 && age < 2500;
      if ((epoch is int && epoch > _pauseEpoch) || (!active && _active))
        _paused = true;
      if (epoch is int && epoch > _pauseEpoch) _pauseEpoch = epoch;
      _active = active;
      final request = box['request'];
      if (request is Map<String, dynamic>) await _consume(request);
      if (!_open || !controller.canUseProfile()) {
        await close();
        return;
      }
      if (!paused &&
          !_exit &&
          _remaining == 0 &&
          controller.engine.phase == ConnectPhase.playing &&
          !controller.round.twoPlayers &&
          controller.engine.turn == ConnectPiece.lumo) {
        final drop = await controller.playBot();
        if (drop != null) _remaining = reduceMotion ? 0 : 210 + drop.row * 30;
      }
      if (!_open || !controller.canUseProfile()) {
        await close();
        return;
      }
      if (jsonEncode(view) != before) {
        _revision++;
        await transport.publish(token, view);
      }
    } catch (_) {
      _paused = true;
      _error = 'Speichern noch nicht bestätigt. Bitte erneut versuchen.';
      if (_open && controller.canUseProfile()) {
        try {
          _revision++;
          await transport.publish(token, view);
        } catch (_) {
          await close();
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _consume(Map<String, dynamic> request) async {
    final seq = request['sequence'];
    if (request['token'] != token ||
        seq is! int ||
        seq <= _ack ||
        seq <= _rejected ||
        seq > 1000000000) return;
    // A slot accepted before an Activity pause/revision change must receive
    // a negative acknowledgement. Otherwise it would block a later Resume.
    if (request['roundId'] != controller.round.id ||
        request['revision'] is! int ||
        request['revision'] != _revision ||
        !_active ||
        _exit) {
      _rejected = seq;
      return;
    }
    try {
      switch (request['action']) {
        case 'drop':
          final c = request['column'];
          if (!canDrop || c is! int || c < 0 || c > 6) return;
          final position = await controller.play(c);
          if (position == null) return;
          _remaining = (reduceMotion ? 0 : 210 + position.row * 30) +
              (!controller.round.twoPlayers &&
                      controller.engine.phase == ConnectPhase.playing
                  ? 540
                  : 0);
        case 'pause':
          _paused = true;
        case 'resume':
          await controller.settleReward();
          _paused = false;
        case 'exit':
          await controller.settleReward();
          _paused = true;
          _exit = true;
        case 'restart':
          if (!paused && controller.engine.phase == ConnectPhase.playing)
            return;
          await controller.restart();
          _remaining = 0;
          _paused = false;
        case 'level':
          if (!ConnectLumoLevel.values.any((l) => l.name == request['level']))
            return;
          await controller.setLevel(ConnectLumoLevel.values
              .firstWhere((l) => l.name == request['level']));
        case 'mode':
          if (request['twoPlayers'] is! bool ||
              (!paused && controller.engine.moves > 0)) return;
          await controller.restart(twoPlayers: request['twoPlayers'] as bool);
          _remaining = 0;
          _paused = false;
        default:
          return;
      }
      if (!_open || !controller.canUseProfile()) return;
      _error = null;
      _ack = seq;
    } catch (_) {
      // Reject is distinct from durable ACK. The transport permits a new
      // explicit retry after this negative result, never a repeated drop.
      _rejected = seq;
      rethrow;
    } finally {
      // Invalid/full-column or paused intents are consumed negatively; only
      // a committed move or accepted control can carry the positive ACK.
      if (_ack != seq && _rejected < seq) _rejected = seq;
    }
  }

  Future<void> close() async {
    if (!_open) return;
    _open = false;
    _active = false;
    _paused = true;
    _timer?.cancel();
    _timer = null;
    try {
      await transport.close(token);
    } catch (_) {}
  }
}
