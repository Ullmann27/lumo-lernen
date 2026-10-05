import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/school/attempt.dart';

/// Lokales, offline-fähiges Aufgabenprotokoll. Einzige Quelle für „wann habe
/// ich was geübt“. Doppelte Einträge (gleiche id) werden nie angelegt, damit
/// eine spätere Synchronisierung nichts verdoppelt.
class AttemptLogRepository {
  AttemptLogRepository({this.maxEntries = 3000});

  static const _key = 'lumo_attempt_log_v1';
  final int maxEntries;

  Future<List<Attempt>> load({String? studentId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Attempt>[];
    try {
      final list = (jsonDecode(raw) as List)
          .map(Attempt.tryFromJson)
          .whereType<Attempt>()
          .toList();
      return studentId == null
          ? list
          : list.where((a) => a.studentId == studentId).toList();
    } catch (_) {
      await prefs.remove(_key);
      return <Attempt>[];
    }
  }

  Future<void> append(Attempt attempt) async {
    final all = await load();
    if (all.any((a) => a.id == attempt.id)) return;
    all.add(attempt);
    final kept =
        all.length > maxEntries ? all.sublist(all.length - maxEntries) : all;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(kept.map((a) => a.toJson()).toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
