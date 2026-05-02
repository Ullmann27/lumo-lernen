import 'package:shared_preferences/shared_preferences.dart';

/// Persistiert zuletzt gesehene Aufgaben und Units pro Kind und Fach.
///
/// Wird verwendet, damit nach Section-Wechsel oder App-Neustart nicht sofort
/// dieselben Aufgaben wieder auftauchen. Speicherung ist bewusst simpel,
/// lokal und best-effort: keine Cloud, keine personenbezogenen Daten extern.
class RecentTaskRepository {
  const RecentTaskRepository();

  static const int maxTaskKeys = 150;
  static const int maxUnits = 16;
  static const String _separator = '|';

  Future<List<String>> loadTaskKeys({
    required String childId,
    required String subject,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_taskKey(childId, subject)));
  }

  Future<List<String>> loadUnits({
    required String childId,
    required String subject,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_unitKey(childId, subject)));
  }

  Future<void> saveTaskKeys({
    required String childId,
    required String subject,
    required List<String> keys,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _trim(keys, maxTaskKeys);
    await prefs.setString(_taskKey(childId, subject), _encode(trimmed));
  }

  Future<void> saveUnits({
    required String childId,
    required String subject,
    required List<String> units,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _trim(units, maxUnits);
    await prefs.setString(_unitKey(childId, subject), _encode(trimmed));
  }

  List<String> _trim(List<String> values, int maxLength) {
    final seen = <String>{};
    final reversed = <String>[];
    for (final raw in values.reversed) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final normalized = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (seen.add(normalized)) reversed.add(value);
    }
    final unique = reversed.reversed.toList(growable: false);
    if (unique.length <= maxLength) return unique;
    return unique.sublist(unique.length - maxLength);
  }

  String _taskKey(String childId, String subject) =>
      'lumo_recent_tasks_${_sanitize(childId)}_${_sanitize(subject)}';

  String _unitKey(String childId, String subject) =>
      'lumo_recent_units_${_sanitize(childId)}_${_sanitize(subject)}';

  String _sanitize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _encode(List<String> values) =>
      values.map((v) => v.replaceAll(_separator, ' ')).join(_separator);

  List<String> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String>[];
    return raw
        .split(_separator)
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);
  }
}
