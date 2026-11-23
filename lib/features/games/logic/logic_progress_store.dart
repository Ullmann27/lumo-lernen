import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/iq/test_history_queue.dart';
import '../../../core/legacy_learning_data.dart';
import '../../../domain/logic/logic_games.dart';
import '../../../domain/logic/logic_learning_profile.dart';

/// Profile-scoped local storage. All operations share the existing keyed queue,
/// so a rapid answer/hint/completion sequence cannot overwrite another write.
class LogicProgressStore {
  const LogicProgressStore({this.preferences = SharedPreferences.getInstance});

  final Future<SharedPreferences> Function() preferences;
  static const _prefix = LogicProgress.preferencePrefix;
  static int _nextAttempt = 0;
  static final Set<Future<Object?>> _pending = {};

  Future<T> _run<T>(String profileId, Future<T> Function() action) {
    final work = TestHistoryQueue.run(
      _key(profileId),
      () => LearningStorage.run((_) => action()),
    );
    _pending.add(work);
    unawaited(work.then<void>(
      (_) { _pending.remove(work); },
      onError: (Object _, StackTrace __) { _pending.remove(work); },
    ));
    return work;
  }

  /// The app blocks new actions before waiting here during backup/reset.
  static Future<void> flushPendingWrites() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }

  String _key(String profileId) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(profileId, 'profileId', 'A child is required');
    }
    return _prefix + Uri.encodeComponent(profileId);
  }

  Future<LogicProgress> load(String profileId) =>
      _run(profileId, () => _read(profileId));

  Future<LogicProgress> _read(String profileId) async {
    final prefs = await preferences();
    final raw = prefs.getString(_key(profileId));
    if (raw == null) return LogicProgress(profileId: profileId);
    final result = LogicProgress.fromJson(jsonDecode(raw));
    if (result.profileId != profileId) {
      throw const FormatException('Logic progress belongs to another child');
    }
    return result;
  }

  Future<LogicProgress> _write(LogicProgress progress) async {
    final prefs = await preferences();
    await LearningStorage.write(
      prefs,
      _key(progress.profileId),
      jsonEncode(progress.toJson()),
    );
    return progress;
  }

  Future<LogicProgress> setGrade(String profileId, int grade) =>
      _run(profileId, () async {
        if (grade < 1 || grade > 4)
          throw RangeError.range(grade, 1, 4, 'grade');
        final current = await _read(profileId);
        return _write(current.copyWith(selectedGrade: grade));
      });

  Future<LogicPuzzleSession> begin({
    required String profileId,
    required LogicPuzzle puzzle,
    required String sessionId,
    DateTime? now,
    bool restart = false,
  }) => _run(profileId, () async {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'A visit is required');
    }
    final progress = await _read(profileId);
    final prior = progress.drafts[puzzle.id];
    if (prior != null && !restart) {
      _checkPuzzle(prior, puzzle);
      return prior;
    }
    final instant = now ?? DateTime.now();
    final attempt = LogicPuzzleSession(
      attemptId: 'logic-${instant.microsecondsSinceEpoch}-${_nextAttempt++}',
      puzzleId: puzzle.id,
      contentVersion: LogicCatalog.contentVersion,
      kind: puzzle.kind,
      grade: puzzle.grade,
      level: puzzle.level,
      sessionId: sessionId,
      startedAt: instant,
      hints: prior?.hints ?? 0,
      errors: prior?.errors ?? 0,
      solutionRevealed: prior?.solutionRevealed ?? false,
      isReplay: prior != null || progress.isCompleted(puzzle.id),
    );
    await _write(
      progress.copyWith(drafts: {...progress.drafts, puzzle.id: attempt}),
    );
    return attempt;
  });

  Future<LogicProgress> saveSession(
    String profileId,
    LogicPuzzleSession session,
  ) => _run(profileId, () async {
    // Validate public constructor input before it reaches persistent bytes.
    LogicPuzzleSession.fromJson(session.toJson());
    final progress = await _read(profileId);
    final current = progress.drafts[session.puzzleId];
    if (current == null) {
      // A delayed answer write after completion must not reopen the puzzle.
      if (progress.results.containsKey(session.puzzleId)) {
        return progress;
      }
      throw StateError('Dieses Logik-Rätsel ist nicht mehr geöffnet');
    }
    _checkIdentity(current, session);
    if (session.revision < current.revision) return progress;
    final merged = session.preservingEvidenceFrom(current);
    return _write(
      progress.copyWith(drafts: {...progress.drafts, session.puzzleId: merged}),
    );
  });

  Future<LogicProgress> complete(
    String profileId,
    LogicPuzzleSession session, {
    required LogicPuzzle puzzle,
    DateTime? now,
  }) => _run(profileId, () async {
    final progress = await _read(profileId);
    final current = progress.drafts[session.puzzleId];
    final existing = progress.results[session.puzzleId];
    if (current == null && existing != null) {
      return progress;
    }
    if (current == null) {
      throw StateError('Dieses Logik-Rätsel ist nicht mehr geöffnet');
    }
    _checkIdentity(current, session);
    if (session.revision < current.revision) {
      throw StateError(
        'Der neueste Logik-Spielstand muss abgeschlossen werden',
      );
    }
    final merged = session.preservingEvidenceFrom(current);
    _checkPuzzle(merged, puzzle);
    if (!puzzle.isComplete(merged.answers)) {
      throw StateError('Das Logik-Rätsel ist noch nicht vollständig gelöst');
    }
    final finishedAt = now ?? DateTime.now();
    if (finishedAt.isBefore(merged.startedAt)) {
      throw StateError('Der Abschluss liegt vor dem Rätselbeginn');
    }
    final drafts = {...progress.drafts}..remove(session.puzzleId);
    return _write(
      progress.copyWith(
        drafts: drafts,
        results: {
          ...progress.results,
          session.puzzleId:
              existing ?? LogicPuzzleResult.fromSession(merged, finishedAt),
        },
      ),
    );
  });

  Future<void> clear(String profileId) =>
      _run(profileId, () async {
        final prefs = await preferences();
        await LearningStorage.remove(prefs, _key(profileId));
      });

  void _checkIdentity(LogicPuzzleSession current, LogicPuzzleSession next) {
    if (current.attemptId != next.attemptId ||
        current.puzzleId != next.puzzleId ||
        current.contentVersion != next.contentVersion ||
        current.kind != next.kind ||
        current.grade != next.grade ||
        current.level != next.level ||
        current.sessionId != next.sessionId ||
        !current.startedAt.isAtSameMomentAs(next.startedAt)) {
      throw StateError('Der Logik-Spielstand gehört zu einem anderen Versuch');
    }
  }

  void _checkPuzzle(LogicPuzzleSession session, LogicPuzzle puzzle) {
    if (session.puzzleId != puzzle.id ||
        session.contentVersion != LogicCatalog.contentVersion ||
        session.kind != puzzle.kind ||
        session.grade != puzzle.grade ||
        session.level != puzzle.level) {
      throw StateError('Der Logik-Spielstand gehört zu einem anderen Rätsel');
    }
    for (final entry in session.answers.entries) {
      if (entry.key < 0 || entry.key >= puzzle.cells.length) {
        throw const FormatException('Invalid logic answer position');
      }
      final cell = puzzle.cells[entry.key];
      if (cell.blocked || cell.given || cell.isOperator) {
        throw const FormatException('Answer targets a fixed logic cell');
      }
    }
  }
}
