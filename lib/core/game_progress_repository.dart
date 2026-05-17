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

  Future<Map<int, int>> loadStars(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_starsKey(childId));
      if (raw == null || raw.isEmpty) return <int, int>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <int, int>{};
      final result = <int, int>{};
      decoded.forEach((k, v) {
        final id = int.tryParse('$k');
        final stars = (v is num) ? v.toInt() : null;
        if (id != null && stars != null) result[id] = stars;
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
    final updated = Map<int, int>.from(current);
    final existing = updated[levelId] ?? 0;
    if (starsEarned > existing) {
      updated[levelId] = starsEarned;
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
    for (final level in GameLevelCatalog.levels) {
      final prevStars = level.id == 1 ? 1 : (stars[level.id - 1] ?? 0);
      final locked = prevStars == 0;
      final earned = stars[level.id] ?? 0;
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
    } catch (_) {}
  }
}
