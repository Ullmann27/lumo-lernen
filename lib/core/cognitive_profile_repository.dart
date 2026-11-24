import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cognitive/cognitive_profile.dart';
import 'iq/test_history_queue.dart';

class CognitiveProfileRepository {
  const CognitiveProfileRepository();

  static const _prefix = 'lumo.cognitive_profile.v1.';

  String _key(String studentId) => _prefix + studentId;

  Future<List<CognitiveProfileResult>> loadAll(String studentId) =>
      TestHistoryQueue.run(_key(studentId), () async {
        try {
          return await _read(studentId);
        } catch (_) {
          return const <CognitiveProfileResult>[];
        }
      });

  Future<List<CognitiveProfileResult>> _read(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(studentId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Invalid Denkprofil history');
    }
    final values = decoded.map(CognitiveProfileResult.fromJson).toList();
    if (values.any((value) => value == null || value.studentId != studentId)) {
      throw const FormatException('Invalid Denkprofil result');
    }
    return values.cast<CognitiveProfileResult>();
  }

  Future<CognitiveProfileResult?> latest(String studentId) async {
    final all = await loadAll(studentId);
    if (all.isEmpty) return null;
    final copy = [...all]..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return copy.first;
  }

  Future<void> save(CognitiveProfileResult result) =>
      TestHistoryQueue.run(_key(result.studentId), () async {
        if (result.id.isEmpty || result.studentId.isEmpty) {
          throw ArgumentError(
              'A result must keep its test and student identity');
        }
        final current = await _read(result.studentId);
        final next = <CognitiveProfileResult>[
          ...current.where((item) => item.id != result.id),
          result,
        ]..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
        final kept = next.length > 12 ? next.sublist(next.length - 12) : next;
        final prefs = await SharedPreferences.getInstance();
        final ok = await prefs.setString(
          _key(result.studentId),
          jsonEncode(kept.map((item) => item.toJson()).toList(growable: false)),
        );
        if (!ok) throw StateError('Denkprofil konnte nicht gespeichert werden');
      });

  Future<void> clear(String studentId) =>
      TestHistoryQueue.run(_key(studentId), () async {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.remove(_key(studentId))) {
          throw StateError('Denkprofil konnte nicht gelöscht werden');
        }
      });
}
