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

  /// Liefert die lesbaren Einträge und belässt beschädigte Daten im Speicher.
  Future<List<Attempt>> load({String? studentId}) =>
      LearningStorage.run((prefs) async {
        final list = _read(prefs);
        return studentId == null
            ? list
            : list.where((a) => a.studentId == studentId).toList();
      });

  List<Attempt> _read(SharedPreferences prefs, {bool forWrite = false}) {
    final raw = prefs.get(_key);
    final attempts = <Attempt>[];
    if (raw == null || raw == '') return attempts;

    final rows = _decodeRows(raw);
    var damaged = rows == null;
    for (final row in rows ?? const <Object?>[]) {
      Attempt? attempt;
      try {
        attempt = Attempt.tryFromJson(row);
      } on TypeError {
        // A stored field has an incompatible type.
      } on UnsupportedError {
        // A number outside the supported range cannot be converted to int.
      }
      if (attempt == null || attempt.score?.isFinite == false) {
        damaged = true;
        continue;
      }
      attempts.add(attempt);
    }
    if (damaged && forWrite) {
      throw StateError('Learning attempt log is damaged');
    }
    return attempts;
  }

  List<Object?>? _decodeRows(Object raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List<Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Hängt Einträge an. Bei Speicherfehlern oder einem beschädigten Protokoll
  /// behält der Aufrufer die ausstehenden Einträge und kann es erneut versuchen.
  Future<void> append(Attempt attempt) => appendAll([attempt]);

  Future<void> appendAll(List<Attempt> attempts) =>
      LearningStorage.run((prefs) async {
        if (attempts.isEmpty) return;
        final all = _read(prefs, forWrite: true);
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

  /// Gezieltes Löschen setzt ein lesbares Protokoll voraus. Ohne [studentId]
  /// wird das ganze Protokoll ausdrücklich aus dem Speicher entfernt.
  Future<void> clear({String? studentId}) => LearningStorage.run((prefs) async {
        if (studentId == null) {
          await LearningStorage.remove(prefs, _key);
          return;
        }
        final all = _read(prefs, forWrite: true);
        final kept =
            all.where((attempt) => attempt.studentId != studentId).toList();
        if (kept.length == all.length) return;
        await LearningStorage.write(prefs, _key,
            jsonEncode(kept.map((attempt) => attempt.toJson()).toList()));
      });
}
