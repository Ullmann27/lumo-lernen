// ════════════════════════════════════════════════════════════════════════
// LUMO ACHIEVEMENT REPOSITORY — Persistence der freigeschalteten Badges.
// ════════════════════════════════════════════════════════════════════════
// Speichert per SharedPreferences:
//   - Set freigeschalteter Achievement-IDs
//   - Pro Metric einen aktuellen Counter (totalTasks, mathCorrect, ...)
//   - Unlock-Datum pro Achievement (fuer Wall-Sortierung)
//
// Best-Effort: Fehler beim Speichern blockieren nie den App-Flow.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_achievement.dart';

class AchievementRepository {
  const AchievementRepository();

  static const String _kUnlocked = 'lumo.achievements.unlocked';
  static const String _kCounters = 'lumo.achievements.counters';

  Future<Map<String, DateTime>> loadUnlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUnlocked);
      if (raw == null) return <String, DateTime>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, DateTime>{};
      final result = <String, DateTime>{};
      decoded.forEach((k, v) {
        if (k is String && v is String) {
          final dt = DateTime.tryParse(v);
          if (dt != null) result[k] = dt;
        }
      });
      return result;
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  Future<void> setUnlocked(String achievementId, DateTime when) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await loadUnlocked();
      current[achievementId] = when;
      final mapStr = <String, String>{
        for (final e in current.entries) e.key: e.value.toIso8601String(),
      };
      await prefs.setString(_kUnlocked, jsonEncode(mapStr));
    } catch (_) {
      // ignore - kein App-Block bei Persistence-Fehler
    }
  }

  Future<Map<AchievementMetric, int>> loadCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCounters);
      if (raw == null) return <AchievementMetric, int>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <AchievementMetric, int>{};
      final result = <AchievementMetric, int>{};
      for (final m in AchievementMetric.values) {
        final v = decoded[m.name];
        if (v is num) result[m] = v.toInt();
      }
      return result;
    } catch (_) {
      return <AchievementMetric, int>{};
    }
  }

  Future<void> saveCounters(Map<AchievementMetric, int> counters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, int>{
        for (final e in counters.entries) e.key.name: e.value,
      };
      await prefs.setString(_kCounters, jsonEncode(map));
    } catch (_) {
      // ignore
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUnlocked);
      await prefs.remove(_kCounters);
    } catch (_) {
      // ignore
    }
  }
}
