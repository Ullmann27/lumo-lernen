// ════════════════════════════════════════════════════════════════════════
// WRITING PROGRESS REPOSITORY — persistiert WritingProgress lokal.
// ════════════════════════════════════════════════════════════════════════
// Muster wie ReadingProgressRepository: SharedPreferences + JSON.
// Keine Cloud, keine externe KI - Schreibdaten bleiben lokal auf dem Geraet.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/writing/writing_progress.dart';

class WritingProgressRepository {
  static const _key = 'lumo_writing_progress_v1';

  Future<WritingProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return WritingProgress.empty;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return WritingProgress.empty;
      return WritingProgress.fromJson(decoded);
    } catch (_) {
      return WritingProgress.empty;
    }
  }

  Future<void> save(WritingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(progress.toJson()));
    } catch (_) {
      // Best-effort. Wenn Storage scheitert, soll der Coach nicht crashen.
    }
  }

  Future<WritingProgress> recordAttempt({
    required String letter,
    required bool correct,
  }) async {
    final current = await load();
    final next = current.withAttempt(letter: letter, correct: correct);
    await save(next);
    return next;
  }

  Future<WritingProgress> recordCompletedWord(String word) async {
    final current = await load();
    final next = current.withCompletedWord(word);
    await save(next);
    return next;
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
