import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistiert das Fehler-Histogramm pro Kind (Phase 2 - Fehlerdetektiv).
///
/// Format: Map<String, int> z.B. {'Zaehlfehler': 5, 'Plus/Minus verwechselt': 2}.
/// Wird vom ErrorDetective gefuettert und vom DnaEngine (Phase 1) gelesen.
class ErrorBreakdownRepository {
  const ErrorBreakdownRepository();

  String _key(String childId) => 'lumo.error_breakdown.$childId';

  Future<Map<String, int>> load(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(childId));
      if (raw == null || raw.isEmpty) return <String, int>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      final result = <String, int>{};
      decoded.forEach((k, v) {
        if (k is String && v is num) {
          result[k] = v.toInt();
        }
      });
      return result;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> save(String childId, Map<String, int> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(childId), jsonEncode(data));
    } catch (_) {
      // Silent fail
    }
  }

  /// Inkrementiert einen Fehler-Typ um 1. Aggregiert mit bestehenden Daten.
  Future<Map<String, int>> increment(String childId, String errorLabel) async {
    final current = await load(childId);
    final updated = Map<String, int>.from(current);
    updated[errorLabel] = (updated[errorLabel] ?? 0) + 1;
    await save(childId, updated);
    return updated;
  }

  /// Setzt alle Fehler-Zaehler zurueck (z.B. nach Eltern-Reset).
  Future<void> reset(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(childId));
    } catch (_) {}
  }
}
