// ════════════════════════════════════════════════════════════════════════
// JOURNAL REPOSITORY — SharedPreferences-Persistenz fuer Tagebuch-Eintraege
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 37: Speichert die Tagebuch-Eintraege der Tochter als
// JSON-Liste in SharedPreferences. Maximal 50 Eintraege (FIFO), bewusst
// nicht persistiert in der Cloud um privacy zu garantieren.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/legacy_learning_data.dart';

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

/// The legacy device journal is available only without a selected school
/// child. Every school child has an independent stable storage key.
class JournalRepository {
  const JournalRepository({required this.schoolOwnerId});

  final String? schoolOwnerId;
  static const deviceKey = 'lumo_journal_entries';
  static const schoolPrefix = 'lumo_journal_entries_v2.';
  static const _maxEntries = 50;

  static String schoolKey(String owner) {
    if (owner.trim().isEmpty || owner.length > 300) {
      throw const FormatException('Ungültiges Kinderprofil.');
    }
    return schoolPrefix + sha256.convert(utf8.encode(owner)).toString();
  }

  String get _key =>
      schoolOwnerId == null ? deviceKey : schoolKey(schoolOwnerId!);

  static List<JournalEntry> _decodeEntries(Object? data) {
    if (data is! List) throw const FormatException('Ungültiges Journal.');
    return [
      for (final row in data)
        if (row is Map<String, dynamic>)
          JournalEntry.fromJson(row)
        else
          throw const FormatException('Ungültiger Journaleintrag.'),
    ];
  }

  static List<JournalEntry> _decodeScoped(String key, Object? data) {
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['ownerId'] is! String ||
        schoolKey(data['ownerId'] as String) != key) {
      throw const FormatException('Das Journal gehört zu einem anderen Profil.');
    }
    return _decodeEntries(data['entries']);
  }

  /// Also used by portable-backup validation. Never infer ownership from
  /// an old entry's content, name, timestamp or the currently selected child.
  static void validateSchoolBackup(String key, Object? data) {
    _decodeScoped(key, data);
  }

  List<JournalEntry> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    return schoolOwnerId == null
        ? _decodeEntries(decoded)
        : _decodeScoped(_key, decoded);
  }

  static void _checkCurrent(bool Function() isCurrent) {
    if (!isCurrent()) {
      throw StateError('Das Kinderprofil hat gewechselt.');
    }
  }

  Future<List<JournalEntry>> load({
    required bool Function() isCurrent,
  }) =>
      LearningStorage.run((prefs) async {
        _checkCurrent(isCurrent);
        final entries = _read(prefs);
        _checkCurrent(isCurrent);
        return List.unmodifiable(entries);
      });

  Future<JournalEntry> add({
    required String text,
    required String title,
    required bool Function() isCurrent,
  }) =>
      LearningStorage.run((prefs) async {
        _checkCurrent(isCurrent);
        // Invalid existing data must never turn into an empty replacement.
        final entries = _read(prefs);
        final now = DateTime.now();
        final random = Random.secure();
        final suffix = List.generate(12,
                (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
            .join();
        final entry = JournalEntry(
          id: 'j_' + now.microsecondsSinceEpoch.toString() + '_' + suffix,
          text: text,
          title: title.trim().isEmpty ? _deriveTitleFromText(text) : title.trim(),
          createdAt: now,
          wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
        );
        final sorted = [entry, ...entries]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final rows = sorted.take(_maxEntries).map((e) => e.toJson()).toList();
        final Object document = schoolOwnerId == null
            ? rows
            : {'version': 1, 'ownerId': schoolOwnerId, 'entries': rows};
        _checkCurrent(isCurrent);
        await LearningStorage.write(prefs, _key, jsonEncode(document));
        // A durable write belongs to its captured key even if selection changes
        // before Android replies. The UI rechecks its lease.
        return entry;
      });

  String _deriveTitleFromText(String text) {
    final firstLine = text.trim().split('\n').first.trim();
    if (firstLine.isEmpty) return 'Mein Tagebuch';
    final words = firstLine.split(RegExp(r'\s+')).take(5).join(' ');
    return words.length > 40 ? words.substring(0, 40) + '…' : words;
  }
}
