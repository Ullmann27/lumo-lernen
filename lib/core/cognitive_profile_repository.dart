import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cognitive/cognitive_profile.dart';

class CognitiveProfileRepository {
  const CognitiveProfileRepository();

  static const _prefix = 'lumo.cognitive_profile.v1.';

  String _key(String studentId) => _prefix + studentId;

  Future<List<CognitiveProfileResult>> loadAll(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(studentId));
      if (raw == null || raw.isEmpty) return const <CognitiveProfileResult>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <CognitiveProfileResult>[];
      return decoded
          .map(CognitiveProfileResult.fromJson)
          .whereType<CognitiveProfileResult>()
          .toList(growable: false);
    } catch (_) {
      return const <CognitiveProfileResult>[];
    }
  }

  Future<CognitiveProfileResult?> latest(String studentId) async {
    final all = await loadAll(studentId);
    if (all.isEmpty) return null;
    final copy = [...all]..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return copy.first;
  }

  Future<void> save(CognitiveProfileResult result) async {
    final current = await loadAll(result.studentId);
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
  }

  Future<void> clear(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(studentId));
  }
}
