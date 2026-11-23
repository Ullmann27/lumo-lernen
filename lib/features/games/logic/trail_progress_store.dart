import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/iq/test_history_queue.dart';
import '../../../core/legacy_learning_data.dart';
import '../../../domain/logic/trail_puzzle.dart';

/// Profile-scoped route programs use the same serialized storage boundary as
/// the other learning games, so backup/reset can wait for pending writes.
class TrailProgressStore {
  const TrailProgressStore({this.preferences = SharedPreferences.getInstance});
  final Future<SharedPreferences> Function() preferences;
  static final Set<Future<Object?>> _pending = {};

  String _key(String profileId) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(profileId, 'profileId');
    }
    return TrailProgress.preferencePrefix + Uri.encodeComponent(profileId);
  }

  Future<T> _run<T>(String profileId, Future<T> Function() action) {
    final work = TestHistoryQueue.run(
      _key(profileId),
      () => LearningStorage.run((_) => action()),
    );
    _pending.add(work);
    unawaited(work.then<void>((_) => _pending.remove(work),
        onError: (Object _, StackTrace __) => _pending.remove(work)));
    return work;
  }

  static Future<void> flushPendingWrites() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }

  Future<TrailProgress> load(String profileId) =>
      _run(profileId, () => _read(profileId));

  Future<TrailProgress> _read(String profileId) async {
    final prefs = await preferences();
    final raw = prefs.getString(_key(profileId));
    if (raw == null) return TrailProgress(profileId: profileId);
    final progress = TrailProgress.fromJson(jsonDecode(raw));
    if (progress.profileId != profileId) {
      throw const FormatException('Trail progress belongs to another child');
    }
    return progress;
  }

  Future<TrailProgress> savePlan({
    required String profileId,
    required TrailPuzzle puzzle,
    required List<TrailDirection> commands,
    bool complete = false,
  }) {
    // Copy before waiting on storage: callers may continue editing their queue.
    final plan = List<TrailDirection>.unmodifiable(commands);
    if (!identical(TrailCatalog.fromId(puzzle.id), puzzle) ||
        plan.length > TrailCatalog.maxCommands) {
      throw ArgumentError('Unknown trail board or oversized program');
    }
    if (complete && !TrailExecution.run(puzzle, plan).completed) {
      throw StateError('The picnic has not been reached through every station');
    }
    return _run(profileId, () async {
      final current = await _read(profileId);
      final updated = current.withPlan(puzzle, plan, complete: complete);
      final prefs = await preferences();
      await LearningStorage.write(
        prefs,
        _key(profileId),
        jsonEncode(updated.toJson()),
      );
      return updated;
    });
  }

  Future<void> clear(String profileId) => _run(profileId, () async {
        final prefs = await preferences();
        await LearningStorage.remove(prefs, _key(profileId));
      });
}
