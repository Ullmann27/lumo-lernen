// ════════════════════════════════════════════════════════════════════════
// JOURNAL REPOSITORY — SharedPreferences-Persistenz fuer Tagebuch-Eintraege
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 37: Speichert die Tagebuch-Eintraege der Tochter als
// JSON-Liste in SharedPreferences. Maximal 50 Eintraege (FIFO), bewusst
// nicht persistiert in der Cloud um privacy zu garantieren.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.text,
    required this.title,
    required this.createdAt,
    required this.wordCount,
  });

  final String id;
  final String text;
  final String title;
  final DateTime createdAt;
  final int wordCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'wordCount': wordCount,
      };

  static JournalEntry fromJson(Map<String, dynamic> j) {
    return JournalEntry(
      id: j['id'] as String,
      text: j['text'] as String,
      title: j['title'] as String? ?? 'Mein Tagebuch',
      createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      wordCount: j['wordCount'] as int? ?? 0,
    );
  }
}

class JournalRepository {
  const JournalRepository();

  static const _key = 'lumo_journal_entries';
  static const _maxEntries = 50;

  Future<List<JournalEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(JournalEntry.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    // Neueste zuerst, dann FIFO-trimmen
    final sorted = List<JournalEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trimmed = sorted.take(_maxEntries).toList();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  Future<JournalEntry> add({
    required String text,
    required String title,
  }) async {
    final entries = await load();
    final entry = JournalEntry(
      id: 'j_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      title: title.trim().isEmpty ? _deriveTitleFromText(text) : title.trim(),
      createdAt: DateTime.now(),
      wordCount:
          text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    );
    final updated = [entry, ...entries];
    await save(updated);
    return entry;
  }

  String _deriveTitleFromText(String text) {
    final firstLine = text.trim().split('\n').first.trim();
    if (firstLine.isEmpty) return 'Mein Tagebuch';
    final words = firstLine.split(RegExp(r'\s+')).take(5).join(' ');
    return words.length > 40 ? '${words.substring(0, 40)}…' : words;
  }
}
