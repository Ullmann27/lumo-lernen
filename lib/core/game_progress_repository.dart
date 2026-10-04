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

  String _starsKey(String childId) => 'lumo.games.stars.$childId';
  String _backupKey(String childId) => 'lumo.games.stars.backup.$childId';

  Future<Map<int, int>> loadStars(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(_starsKey(childId));
      Object? decoded;
      try {
        decoded = (raw == null || raw.isEmpty) ? null : jsonDecode(raw);
      } catch (_) {
        decoded = null;
      }
      if (raw != null && raw.isNotEmpty && decoded is! Map) {
        // Beschaedigter Stand: letzte gute Sicherung verwenden.
        raw = prefs.getString(_backupKey(childId));
        try {
          decoded = (raw == null || raw.isEmpty) ? null : jsonDecode(raw);
        } catch (_) {
          decoded = null;
        }
      }
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
      return result;
    } catch (_) {
      return <int, int>{};
    }
  }

  Future<void> saveStars(String childId, Map<int, int> stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = stars.map((k, v) => MapEntry('$k', v));
      final previous = prefs.getString(_starsKey(childId));
      if (previous != null && previous.isNotEmpty) {
        try {
          if (jsonDecode(previous) is Map) {
            await prefs.setString(_backupKey(childId), previous);
          }
        } catch (_) {}
      }
      await prefs.setString(_starsKey(childId), jsonEncode(mapped));
    } catch (_) {
      // Silent fail
    }
  }

  /// Speichert das Ergebnis eines Level-Durchgangs.
  /// Behaelt den hoeheren Stern-Wert (kein Downgrade).
  Future<Map<int, int>> recordResult({
    required String childId,
    required int levelId,
    required int starsEarned,
  }) async {
    final current = await loadStars(childId);
    final level = GameLevelCatalog.byId(levelId);
    if (level == null || !level.miniType.isPlayable) return current;
    final earned = starsEarned.clamp(0, level.maxStars);
    final updated = Map<int, int>.from(current);
    final existing = updated[levelId] ?? 0;
    if (earned > existing) {
      updated[levelId] = earned;
    }
    await saveStars(childId, updated);
    return updated;
  }

  /// Berechnet die Laufzeit-Snapshots aller 50 Level.
  /// Ein Level ist unlocked wenn ID 1 ist, ODER das vorherige Level
  /// mindestens 1 Stern hat.
  List<GameLevelRuntime> buildRuntime(Map<int, int> stars) {
    final result = <GameLevelRuntime>[];
    var currentMarked = false;
    int? previousPlayableId;
    for (final level in GameLevelCatalog.playableLevels) {
      final prevStars =
          previousPlayableId == null ? 1 : (stars[previousPlayableId] ?? 0);
      previousPlayableId = level.id;
      final locked = prevStars <= 0;
      final earned = (stars[level.id] ?? 0).clamp(0, level.maxStars);
      final isCurrent = !currentMarked && !locked && earned == 0;
      if (isCurrent) currentMarked = true;
      result.add(GameLevelRuntime(
        level: level,
        locked: locked,
        starsEarned: earned,
        isCurrent: isCurrent,
      ));
    }
    return result;
  }

  Future<void> reset(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_starsKey(childId));
      await prefs.remove(_backupKey(childId));
    } catch (_) {}
  }
}
