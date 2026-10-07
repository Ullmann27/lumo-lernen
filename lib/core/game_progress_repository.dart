import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/games/game_level_catalog.dart';
import '../domain/games/game_level_model.dart';

/// Persistenz des Spielfortschritts in der Lumo Spielewelt.
///
/// Speichert pro Kind:
///   - earnedStars: Map<int, int>  Level-ID -> 0/1/2/3 Sterne
///   - currentLevelId: int          (das naechste unlocked Level)
///
/// Schaltet Level progressiv frei: ein Level ist unlocked wenn das vorherige
/// mindestens 1 Stern hat. Level 1 ist immer unlocked.
class GameProgressRepository {
  const GameProgressRepository();

  // All instances share each child's read-modify-write order. Otherwise a
  // delayed result can erase another level or resurrect progress after reset.
  static final Map<String, Future<void>> _pendingByChild = {};

  String _starsKey(String childId) => 'lumo.games.stars.$childId';
  String _unlocksKey(String childId) => 'lumo.games.curriculum50.$childId';

  // The previous 24-level path skipped these newly implemented lesson types.
  // Preserve its already available levels once, without skipping new lessons
  // for profiles created after this upgrade.
  Future<void> _migrateUnlocks(SharedPreferences prefs, String childId,
      Map<int, int> stars) async {
    final key = _unlocksKey(childId);
    if (prefs.containsKey(key)) return;
    const legacyTypes = {
      GameMiniType.starsPath,
      GameMiniType.colorBoxes,
      GameMiniType.numberHouse,
      GameMiniType.letterFill,
    };
    final open = <int>{};
    int? previous;
    for (final level in GameLevelCatalog.levels) {
      if (!legacyTypes.contains(level.miniType)) continue;
      if ((stars[level.id] ?? 0) > 0 ||
          (previous != null && (stars[previous] ?? 0) > 0)) {
        open.add(level.id);
      }
      previous = level.id;
    }
    await prefs.setString(key, jsonEncode(open.toList()..sort()));
  }

  Future<Set<int>> loadUnlocked(String childId) => _ordered(childId, () async {
    await _readStars(childId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = jsonDecode(prefs.getString(_unlocksKey(childId)) ?? '[]');
      if (decoded is! List) return <int>{};
      return decoded.whereType<int>()
          .where((id) => GameLevelCatalog.byId(id) != null).toSet();
    } catch (_) {
      return <int>{};
    }
  });

  Future<T> _ordered<T>(String childId, Future<T> Function() operation) {
    final previous = _pendingByChild[childId] ?? Future<void>.value();
    final result = previous.then<T>((_) => operation());
    final completed = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _pendingByChild[childId] = completed;
    unawaited(
      completed.then((_) {
        if (identical(_pendingByChild[childId], completed)) {
          _pendingByChild.remove(childId);
        }
      }),
    );
    return result;
  }

  Future<Map<int, int>> loadStars(String childId) =>
      _ordered(childId, () => _readStars(childId));

  Future<Map<int, int>> _readStars(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_starsKey(childId));
      if (raw == null || raw.isEmpty) {
        await _migrateUnlocks(prefs, childId, const {});
        return <int, int>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <int, int>{};
      final result = <int, int>{};
      decoded.forEach((k, v) {
        final id = int.tryParse('$k');
        final stars = (v is num) ? v.toInt() : null;
        final level = id == null ? null : GameLevelCatalog.byId(id);
        if (level != null && stars != null) {
          result[id!] = stars.clamp(0, level.maxStars);
        }
      });
      await _migrateUnlocks(prefs, childId, result);
      return result;
    } catch (_) {
      return <int, int>{};
    }
  }

  Future<void> saveStars(String childId, Map<int, int> stars) {
    final snapshot = Map<int, int>.from(stars);
    return _ordered(childId, () => _writeStars(childId, snapshot));
  }

  Future<void> _writeStars(String childId, Map<int, int> stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateUnlocks(prefs, childId, const {});
      final mapped = stars.map((k, v) => MapEntry('$k', v));
      await prefs.setString(_starsKey(childId), jsonEncode(mapped));
    } catch (_) {
      // Preserve the existing best-effort storage contract. Durable write-error
      // reporting needs coordinated changes in the mini-game callers.
    }
  }

  /// Speichert das Ergebnis eines Level-Durchgangs.
  /// Behaelt den hoeheren Stern-Wert (kein Downgrade).
  Future<Map<int, int>> recordResult({
    required String childId,
    required int levelId,
    required int starsEarned,
  }) => _ordered(childId, () async {
    final current = await _readStars(childId);
    final level = GameLevelCatalog.byId(levelId);
    if (level == null || !level.miniType.isPlayable) return current;
    final earned = starsEarned.clamp(0, level.maxStars);
    final updated = Map<int, int>.from(current);
    final existing = updated[levelId] ?? 0;
    if (earned > existing) {
      updated[levelId] = earned;
    }
    await _writeStars(childId, updated);
    return updated;
  });

  /// Berechnet die Laufzeit-Snapshots aller 50 Level.
  /// Ein Level ist unlocked wenn ID 1 ist, ODER das vorherige Level
  /// mindestens 1 Stern hat.
  List<GameLevelRuntime> buildRuntime(Map<int, int> stars,
      {Set<int> preservedUnlocked = const {}}) {
    final result = <GameLevelRuntime>[];
    var currentMarked = false;
    int? previousPlayableId;
    for (final level in GameLevelCatalog.playableLevels) {
      final prevStars = previousPlayableId == null
          ? 1
          : (stars[previousPlayableId] ?? 0);
      previousPlayableId = level.id;
      final earned = (stars[level.id] ?? 0).clamp(0, level.maxStars);
      final locked = prevStars <= 0 && earned <= 0 &&
          !preservedUnlocked.contains(level.id);
      final isCurrent = !currentMarked && !locked && earned == 0;
      if (isCurrent) currentMarked = true;
      result.add(
        GameLevelRuntime(
          level: level,
          locked: locked,
          starsEarned: earned,
          isCurrent: isCurrent,
        ),
      );
    }
    return result;
  }

  Future<void> reset(String childId) => _ordered(childId, () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_starsKey(childId));
      await prefs.remove(_unlocksKey(childId));
    } catch (_) {}
  });
}
