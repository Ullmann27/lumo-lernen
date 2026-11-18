import 'dart:convert';

import '../domain/learning/practice_session_plan.dart';
import 'legacy_learning_data.dart';

/// Where a child stopped inside a long session, at a round boundary.
class SessionRoundPosition {
  const SessionRoundPosition({
    required this.completedTasks,
    required this.totalTasks,
    this.correct = 0,
  });

  final int completedTasks;
  final int totalTasks;

  /// Tasks answered correctly so far, for the summary at the very end.
  final int correct;

  int get nextRound => completedTasks ~/ SessionRounds.size + 1;
}

/// Remembers the round a child stopped at, per child and per session.
///
/// A new, versioned key in the existing per-child preferences namespace.
/// Only round boundaries are stored: no answers, no task texts. Unreadable
/// content means "start at round 1" and is never treated as an error.
class SessionRoundResumeStore {
  SessionRoundResumeStore({String? studentId})
      : _namespace = LearningDataNamespace(studentId: studentId);

  static const storageKey = 'lumo_session_round_resume_v1';
  static const emptyValue = '{"version":1,"positions":{}}';
  static const _maxPositions = 40;
  static const _maxAge = Duration(days: 14);

  final LearningDataNamespace _namespace;

  Future<Map<String, Map<String, Object?>>> _read() async {
    final raw = await _namespace.read(storageKey);
    if (raw == null || raw.length > 65536) return {};
    try {
      final data = jsonDecode(raw);
      if (data is! Map || data['version'] != 1 || data['positions'] is! Map) {
        return {};
      }
      final out = <String, Map<String, Object?>>{};
      for (final entry in (data['positions'] as Map).entries) {
        final value = entry.value;
        if (entry.key is String && value is Map) {
          out[entry.key as String] = Map<String, Object?>.from(value);
        }
      }
      return out;
    } on FormatException {
      return {};
    }
  }

  Future<void> _write(Map<String, Map<String, Object?>> positions) =>
      _namespace.write(
          storageKey, jsonEncode({'version': 1, 'positions': positions}));

  /// The saved round boundary for [scope], if it still fits a session of
  /// [totalTasks] tasks and is not older than two weeks.
  Future<SessionRoundPosition?> load(String scope,
      {required int totalTasks, DateTime? now}) async {
    final entry = (await _read())[scope];
    if (entry == null) return null;
    final done = entry['done'];
    final total = entry['total'];
    final correct = entry['correct'];
    final at = DateTime.tryParse('${entry['at']}');
    if (done is! int ||
        total is! int ||
        total != totalTasks ||
        at == null ||
        !SessionRounds.isResumable(done, totalTasks) ||
        (now ?? DateTime.now()).difference(at) > _maxAge) {
      return null;
    }
    return SessionRoundPosition(
      completedTasks: done,
      totalTasks: total,
      correct: correct is int ? correct.clamp(0, done) : 0,
    );
  }

  Future<void> save(String scope, SessionRoundPosition position,
      {DateTime? now}) async {
    if (!SessionRounds.isResumable(
        position.completedTasks, position.totalTasks)) {
      return clear(scope);
    }
    final positions = await _read();
    positions.remove(scope);
    positions[scope] = {
      'done': position.completedTasks,
      'total': position.totalTasks,
      'correct': position.correct.clamp(0, position.completedTasks),
      'at': (now ?? DateTime.now()).toIso8601String(),
    };
    while (positions.length > _maxPositions) {
      positions.remove(positions.keys.first);
    }
    await _write(positions);
  }

  Future<void> clear(String scope) async {
    final positions = await _read();
    if (positions.remove(scope) == null) return;
    await _write(positions);
  }
}
