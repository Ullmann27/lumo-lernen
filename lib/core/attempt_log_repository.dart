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

  /// Hängt Einträge an. Wirft [StateError], wenn der Speicher nicht
  /// schreibt; der Aufrufer behält die Einträge dann und versucht es erneut.
  Future<void> append(Attempt attempt) => appendAll([attempt]);

  Future<void> appendAll(List<Attempt> attempts) async {
    final all = await load();
    final known = {for (final a in all) a.id};
    var added = false;
    for (final a in attempts) {
      if (known.add(a.id)) {
        all.add(a);
        added = true;
      }
    }
    if (!added) return;
    final kept =
        all.length > maxEntries ? all.sublist(all.length - maxEntries) : all;
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
        _key, jsonEncode(kept.map((a) => a.toJson()).toList()));
    if (!ok) throw StateError('Aufgabenprotokoll wurde nicht gespeichert');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
