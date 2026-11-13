import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'legacy_learning_data.dart';

/// Persistiert das Fehler-Histogramm pro Kind (Phase 2 - Fehlerdetektiv).
///
/// Format: Map<String, int> z.B. {'Zaehlfehler': 5, 'Plus/Minus verwechselt': 2}.
/// Wird vom ErrorDetective gefuettert und vom DnaEngine (Phase 1) gelesen.
class ErrorBreakdownRepository {
  const ErrorBreakdownRepository();

  String _key(String childId) => 'lumo.error_breakdown.$childId';

  /// A distinct namespace for verified profile IDs. Legacy name/grade keys
  /// remain untouched because their owner cannot be inferred safely.
  String _profileScope(String studentId) =>
      'profile_v1_${sha256.convert(utf8.encode(studentId))}';

  Future<Map<String, int>> loadForProfile(String studentId) =>
      load(_profileScope(studentId));

  Future<void> resetForProfile(String studentId) =>
      LearningStorage.run((prefs) async {
        await LearningStorage.remove(prefs, _key(_profileScope(studentId)));
      });

  Future<void> incrementForProfile(String studentId, String errorLabel,
          {required bool Function() mayWrite}) =>
      LearningStorage.run((prefs) async {
        if (!mayWrite()) return;
        final key = _key(_profileScope(studentId));
        final current = _decode(prefs.getString(key));
        current[errorLabel] = (current[errorLabel] ?? 0) + 1;
        // No await separates ownership validation and the actual write.
        if (mayWrite()) {
          await LearningStorage.write(prefs, key, jsonEncode(current));
        }
      });

  Map<String, int> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String, int>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Expected an error histogram');
    }
    final result = <String, int>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! int || entry.value < 0) {
        throw const FormatException('Unknown error histogram entry');
      }
      result[entry.key as String] = entry.value as int;
    }
    return result;
  }

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
