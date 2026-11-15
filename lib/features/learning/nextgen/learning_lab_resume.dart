import 'dart:async';
import 'dart:convert';

import '../../../core/legacy_learning_data.dart';
import '../lab/learning_lab_catalog.dart';

/// A local view checkpoint, not another learning record. Only the existing
/// LearningModuleProgress writer can accept answers or award progress.
class LearningLabCheckpoint {
  LearningLabCheckpoint({
    required this.topicId,
    required this.seed,
    required this.sessionId,
    required this.phase,
    required this.problemId,
    this.moved = 0,
    this.pieces = const [],
    this.tokens = const [],
    this.patternChoice,
    this.hint = 0,
    this.support = 0,
    this.wrongBefore = false,
    this.attempt = 0,
    this.answer = '',
    this.done = false,
    this.pendingAttemptId,
    this.lastSavedAttemptId,
  });

  static const phases = [
    'example',
    'build',
    'recall',
    'transfer',
    'reflection'
  ];
  final String topicId, sessionId, phase, problemId, answer;
  final int seed, moved, hint, support, attempt;
  final List<int> pieces, tokens;
  final int? patternChoice;
  final bool wrongBefore, done;
  final String? pendingAttemptId, lastSavedAttemptId;

  String get key => '$topicId:$seed';

  Map<String, Object?> toJson() => {
        'topicId': topicId,
        'seed': seed,
        'sessionId': sessionId,
        'phase': phase,
        'problemId': problemId,
        'moved': moved,
        'pieces': pieces,
        'tokens': tokens,
        'patternChoice': patternChoice,
        'hint': hint,
        'support': support,
        'wrongBefore': wrongBefore,
        'attempt': attempt,
        'answer': answer,
        'done': done,
        'pendingAttemptId': pendingAttemptId,
        'lastSavedAttemptId': lastSavedAttemptId,
      };

  factory LearningLabCheckpoint.fromJson(Object? raw, LabTopic topic) {
    if (raw is! Map<String, dynamic> ||
        raw.length != 17 ||
        raw['topicId'] != topic.id ||
        !phases.contains(raw['phase']) ||
        raw['seed'] is! int ||
        (raw['seed'] as int).abs() > 1000000 ||
        !_identity(raw['sessionId']) ||
        !_identity(raw['problemId']) ||
        !_count(raw['moved'], 20) ||
        !_count(raw['hint'], 5) ||
        !_count(raw['support'], 5) ||
        !_count(raw['attempt'], 10000) ||
        raw['wrongBefore'] is! bool ||
        raw['done'] is! bool ||
        raw['answer'] is! String ||
        (raw['answer'] as String).length > 80 ||
        (raw['pendingAttemptId'] != null &&
            !_identity(raw['pendingAttemptId'])) ||
        (raw['lastSavedAttemptId'] != null &&
            !_identity(raw['lastSavedAttemptId']))) {
      throw const FormatException('Unsupported learning session checkpoint');
    }
    final seed = raw['seed'] as int;
    final phase = raw['phase'] as String;
    final index = switch (phase) {
      'example' || 'build' => 0,
      'recall' => 2,
      _ => 3,
    };
    final problem = topic.problems[(seed + index) % topic.problems.length];
    final pieces = _indices(raw['pieces'], problem.denominator);
    final tokens = _indices(raw['tokens'], problem.tokens.length);
    final choice = raw['patternChoice'];
    if (problem.id != raw['problemId'] ||
        (problem.mode == LabMode.bridge &&
            (raw['moved'] as int) > problem.modelTarget) ||
        (choice != null &&
            (choice is! int ||
                choice < 0 ||
                choice >= problem.tokens.length)) ||
        (raw['hint'] as int) > (raw['support'] as int) ||
        (raw['done'] == true && raw['lastSavedAttemptId'] == null) ||
        (raw['done'] == true && raw['pendingAttemptId'] != null)) {
      throw const FormatException('Inconsistent learning session checkpoint');
    }
    return LearningLabCheckpoint(
      topicId: topic.id,
      seed: seed,
      sessionId: raw['sessionId'] as String,
      phase: phase,
      problemId: problem.id,
      moved: raw['moved'] as int,
      pieces: pieces,
      tokens: tokens,
      patternChoice: choice as int?,
      hint: raw['hint'] as int,
      support: raw['support'] as int,
      wrongBefore: raw['wrongBefore'] as bool,
      attempt: raw['attempt'] as int,
      answer: raw['answer'] as String,
      done: raw['done'] as bool,
      pendingAttemptId: raw['pendingAttemptId'] as String?,
      lastSavedAttemptId: raw['lastSavedAttemptId'] as String?,
    );
  }

  static bool _count(Object? value, int max) =>
      value is int && value >= 0 && value <= max;

  static bool _identity(Object? value) =>
      value is String &&
      value.isNotEmpty &&
      value.length <= 180 &&
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

  static List<int> _indices(Object? raw, int length) {
    if (raw is! List ||
        raw.length > length ||
        raw.any((i) => i is! int || i < 0 || i >= length) ||
        raw.toSet().length != raw.length) {
      throw const FormatException('Unsupported learning model selection');
    }
    return List<int>.unmodifiable(raw.cast<int>());
  }
}

/// Uses the existing per-child namespace and durable-write checks. Sessions
/// from equal display names remain separated by their captured student IDs.
class LearningLabResumeRepository {
  LearningLabResumeRepository({
    required String studentId,
    required this.mayWrite,
  })  : _studentId = studentId,
        _namespace = LearningDataNamespace(studentId: studentId);

  static const storageKey = 'lumo_learning_lab_session_v1';
  static final Map<String, Future<void>> _tails = {};
  final String _studentId;
  final LearningDataNamespace _namespace;
  final bool Function() mayWrite;

  Future<T> _serialize<T>(Future<T> Function() action) {
    final previous = _tails[_studentId];
    final done = Completer<void>();
    _tails[_studentId] = done.future;
    Future<T> run() async {
      if (previous != null) await previous;
      return action();
    }

    final result = run();
    void finish() {
      if (identical(_tails[_studentId], done.future)) {
        _tails.remove(_studentId);
      }
      done.complete();
    }

    unawaited(result.then<void>((_) => finish(),
        onError: (Object _, StackTrace __) => finish()));
    return result;
  }

  Future<Map<String, Object?>> _read() async {
    final raw = await _namespace.read(storageKey);
    if (raw == null) return {};
    if (raw.length > 65536) {
      throw const FormatException('Unsupported learning session size');
    }
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data.length != 2 ||
        data['version'] != 1 ||
        data['sessions'] is! Map<String, dynamic> ||
        (data['sessions'] as Map).length > 24) {
      throw const FormatException('Unsupported learning session format');
    }
    return Map<String, Object?>.of(data['sessions'] as Map<String, dynamic>);
  }

  Future<LearningLabCheckpoint?> load(LabTopic topic, int seed) =>
      _serialize(() async {
        final sessions = await _read();
        final raw = sessions['${topic.id}:$seed'];
        return raw == null ? null : LearningLabCheckpoint.fromJson(raw, topic);
      });

  Future<bool> save(LearningLabCheckpoint value, LabTopic topic) =>
      _serialize(() async {
        if (!mayWrite()) return false;
        // Validate current catalog identity, model bounds and data before I/O.
        LearningLabCheckpoint.fromJson(value.toJson(), topic);
        final sessions = await _read();
        if (!mayWrite()) return false;
        sessions.remove(value.key);
        sessions[value.key] = value.toJson();
        // Retain the latest bounded views, not an unlimited history database.
        while (sessions.length > 24) {
          sessions.remove(sessions.keys.first);
        }
        await _namespace.write(
            storageKey, jsonEncode({'version': 1, 'sessions': sessions}));
        return true;
      });

  Future<bool> remove(LabTopic topic, int seed) => _serialize(() async {
        if (!mayWrite()) return false;
        final sessions = await _read();
        if (!mayWrite()) return false;
        sessions.remove('${topic.id}:$seed');
        await _namespace.write(
            storageKey, jsonEncode({'version': 1, 'sessions': sessions}));
        return true;
      });
}
