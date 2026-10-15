import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/school/attempt.dart';
import 'legacy_learning_data.dart';

/// Lokales, offline-fähiges Aufgabenprotokoll. Einzige Quelle für „wann habe
/// ich was geübt“. Doppelte Einträge (gleiche id) werden nie angelegt, damit
/// eine spätere Synchronisierung nichts verdoppelt.
class AttemptLogRepository {
  AttemptLogRepository({this.maxEntries = 3000});

  static const _key = 'lumo_attempt_log_v1';
  final int maxEntries;

  Future<List<Attempt>> load({String? studentId}) =>
      LearningStorage.run((prefs) async {
        final list = await _read(prefs);
        return studentId == null
            ? list
            : list.where((a) => a.studentId == studentId).toList();
      });

  Future<List<Attempt>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Attempt>[];
    try {
      return (jsonDecode(raw) as List)
          .map(Attempt.tryFromJson)
          .whereType<Attempt>()
          .toList();
    } catch (_) {
      await LearningStorage.remove(prefs, _key);
      return <Attempt>[];
    }
  }

  /// Hängt Einträge an. Wirft [StateError], wenn der Speicher nicht
  /// schreibt; der Aufrufer behält die Einträge dann und versucht es erneut.
  Future<void> append(Attempt attempt) => appendAll([attempt]);

  Future<void> appendAll(List<Attempt> attempts) =>
      LearningStorage.run((prefs) async {
        final all = await _read(prefs);
        final known = {for (final a in all) a.id};
        var added = false;
        for (final a in attempts) {
          if (known.add(a.id)) {
            all.add(a);
            added = true;
          }
        }
        if (!added) return;
        final kept = all.length > maxEntries
            ? all.sublist(all.length - maxEntries)
            : all;
        await LearningStorage.write(
            prefs, _key, jsonEncode(kept.map((a) => a.toJson()).toList()));
      });

  Future<void> clear({String? studentId}) => LearningStorage.run((prefs) async {
        if (studentId == null) {
          await LearningStorage.remove(prefs, _key);
          return;
        }
        final all = await _read(prefs);
        final kept =
            all.where((attempt) => attempt.studentId != studentId).toList();
        if (kept.length == all.length) return;
        await LearningStorage.write(prefs, _key,
            jsonEncode(kept.map((attempt) => attempt.toJson()).toList()));
      });
}
