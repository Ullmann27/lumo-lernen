import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sammelt die letzten N Crash-Stacktraces der App, damit Heinz im
/// Eltern-Bereich nachlesen kann, wo es zuletzt geknallt hat.
///
/// Wichtig: nur Diagnose, keine Privatdaten. Speichert nur Exception-Typ,
/// Fehlertext, Datum und Stack-Trace (Code-Adressen).
class LumoErrorLog {
  LumoErrorLog._();
  static final LumoErrorLog instance = LumoErrorLog._();

  static const String _prefsKey = 'lumo_error_log_v1';
  static const int _maxEntries = 20;

  final List<LumoErrorEntry> _memory = <LumoErrorEntry>[];
  bool _hydrated = false;

  Future<void> hydrate() async {
    if (_hydrated) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _memory
          ..clear()
          ..addAll(list
              .whereType<Map<String, dynamic>>()
              .map(LumoErrorEntry.fromJson));
      }
    } catch (_) {
      // Fehler beim Laden des Fehler-Logs darf den App-Start nicht blockieren.
    } finally {
      _hydrated = true;
    }
  }

  Future<void> record(FlutterErrorDetails details) async {
    final entry = LumoErrorEntry(
      timestamp: DateTime.now(),
      exception: details.exceptionAsString(),
      library: details.library ?? 'unknown',
      context: details.context?.toString() ?? '',
      stack: details.stack?.toString() ?? '',
    );
    _memory.insert(0, entry);
    while (_memory.length > _maxEntries) {
      _memory.removeLast();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_memory.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {
      // Persistierung des Fehlers darf NIE einen weiteren Fehler werfen.
    }
  }

  List<LumoErrorEntry> get entries => List<LumoErrorEntry>.unmodifiable(_memory);

  Future<void> clear() async {
    _memory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}

class LumoErrorEntry {
  const LumoErrorEntry({
    required this.timestamp,
    required this.exception,
    required this.library,
    required this.context,
    required this.stack,
  });

  final DateTime timestamp;
  final String exception;
  final String library;
  final String context;
  final String stack;

  Map<String, dynamic> toJson() => <String, dynamic>{
        't': timestamp.toIso8601String(),
        'e': exception,
        'l': library,
        'c': context,
        's': _truncate(stack, 4000),
      };

  static LumoErrorEntry fromJson(Map<String, dynamic> json) {
    return LumoErrorEntry(
      timestamp: DateTime.tryParse(json['t']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      exception: json['e']?.toString() ?? '',
      library: json['l']?.toString() ?? '',
      context: json['c']?.toString() ?? '',
      stack: json['s']?.toString() ?? '',
    );
  }

  static String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}\n... (gekuerzt)';
  }
}
