import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/iq/iq_puzzle.dart';
import 'test_history_queue.dart';

/// Speichert die letzten zwölf IQ-Rätsel-Ergebnisse je Kind auf dem Gerät.
class IqTestRepository {
  const IqTestRepository();

  static const _prefix = 'lumo.iq_test.v1.';
  static const keep = 12;

  String _key(String studentId) => _prefix + studentId;

  Future<List<IqTestResult>> loadAll(String studentId) =>
      TestHistoryQueue.run(_key(studentId), () async {
        try {
          return await _read(studentId);
        } catch (_) {
          return const <IqTestResult>[];
        }
      });

  Future<List<IqTestResult>> _read(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(studentId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Invalid IQ puzzle history');
    }
    final values = decoded.map(IqTestResult.fromJson).toList();
    if (values.any((value) => value == null || value.studentId != studentId)) {
      throw const FormatException('Invalid IQ puzzle result');
    }
    return values.cast<IqTestResult>();
  }

  Future<IqTestResult?> latest(String studentId) async {
    final all = await loadAll(studentId);
    if (all.isEmpty) return null;
    return all.reduce((a, b) => b.finishedAt.isAfter(a.finishedAt) ? b : a);
  }

  Future<void> save(IqTestResult result) =>
      TestHistoryQueue.run(_key(result.studentId), () async {
        if (result.id.isEmpty || result.studentId.isEmpty) {
          throw ArgumentError(
              'A result must keep its test and student identity');
        }
        final current = await _read(result.studentId);
        final next = <IqTestResult>[
          ...current.where((item) => item.id != result.id),
          result,
        ]..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
        final kept =
            next.length > keep ? next.sublist(next.length - keep) : next;
        final prefs = await SharedPreferences.getInstance();
        final ok = await prefs.setString(
          _key(result.studentId),
          jsonEncode(kept.map((item) => item.toJson()).toList(growable: false)),
        );
        if (!ok) {
          throw StateError(
              'IQ-Rätsel-Ergebnis konnte nicht gespeichert werden');
        }
      });
}
