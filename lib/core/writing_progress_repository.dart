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

  /// Serialisiert alle Schreib-Operationen. recordAttempt /
  /// recordCompletedWord werden von den Coach-Screens via unawaited(...)
  /// aufgerufen und koennen bei schnellen Wiederholungen ineinander
  /// laufen. Ohne Lock liest Operation B den Snapshot von vor Operation A
  /// und ueberschreibt deren save() - der Versuch geht verloren.
  Future<void> _writeLock = Future<void>.value();

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

  /// Fuehrt einen read-modify-write Zyklus seriell mit allen anderen
  /// Mutationen auf diesem Repository aus.
  Future<WritingProgress> _mutate(
      WritingProgress Function(WritingProgress current) update) {
    final next = _writeLock.then((_) async {
      final current = await load();
      final updated = update(current);
      await save(updated);
      return updated;
    });
    // Lock immer auf den letzten Schritt setzen, Fehler aber schlucken
    // damit eine fehlgeschlagene Operation nachfolgende nicht blockiert.
    _writeLock = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<WritingProgress> recordAttempt({
    required String letter,
    required bool correct,
  }) =>
      _mutate((current) =>
          current.withAttempt(letter: letter, correct: correct));

  Future<WritingProgress> recordCompletedWord(String word) =>
      _mutate((current) => current.withCompletedWord(word));

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
