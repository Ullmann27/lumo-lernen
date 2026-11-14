import 'dart:convert';

import 'package:flutter/services.dart';

import 'native_table_transport.dart';

/// Android's private, process-bound mailbox for the Memory and Quiz renderers.
class NativeMethodTableTransport implements NativeTableTransport {
  const NativeMethodTableTransport();

  static const _channel = MethodChannel('lumo_lernen/table_games');

  Future<void> _write(
    String method,
    String token,
    Map<String, Object?> state,
  ) async {
    final acknowledged = await _channel.invokeMethod<bool>(
      method,
      <String, Object?>{'token': token, 'state': jsonEncode(state)},
    );
    if (acknowledged != true) {
      throw StateError('Die Spielverbindung konnte nicht bestätigt werden.');
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
    if (raw == null || raw.length > 65536) {
      throw StateError('Die Spielverbindung ist nicht verfügbar.');
    }
    final parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Spielnachricht');
    }
    return parsed;
  }

  @override
  Future<void> close(String token) async {
    final acknowledged = await _channel.invokeMethod<bool>('close', {
      'token': token,
    });
    if (acknowledged != true) {
      throw StateError('Die Spielverbindung ist noch geöffnet.');
    }
  }
}
