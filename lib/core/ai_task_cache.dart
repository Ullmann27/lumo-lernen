import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_ai_proxy_client.dart';

/// Persistenter Cache fuer KI-generierte Aufgaben pro (childId, subject).
///
/// Aufgaben-Vorrat wird einmal generiert und solange genutzt, bis er
/// aufgebraucht ist. Erst dann wird neu generiert. Das spart OpenAI-
/// Kosten und Render-Free-Tier-Aufrufe.
///
/// Speicherort: SharedPreferences als JSON-Liste.
/// Schluessel: lumo_ai_tasks_<childId>_<subject>
///
/// Aufgaben werden als gesehen markiert (consumed=true) statt geloescht,
/// damit eine kurze Historie bleibt fuer Wiederholungs-Vermeidung.
class AiTaskCache {
  const AiTaskCache();

  static const int _keepHistory = 40;

  String _storageKey(String childId, String subject) {
    final sChild = childId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final sSubj = subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'lumo_ai_tasks_${sChild}_$sSubj';
  }

  String _metaKey(String childId, String subject) {
    final sChild = childId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final sSubj = subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'lumo_ai_tasks_meta_${sChild}_$sSubj';
  }

  /// Laedt unverbrauchte Aufgaben aus dem Cache.
  Future<List<LumoAiTaskDraft>> loadFresh({
    required String childId,
    required String subject,
  }) async {
    final all = await _loadAll(childId: childId, subject: subject);
    return all.where((e) => !e.consumed).map((e) => e.draft).toList(growable: false);
  }

  /// Anzahl unverbrauchter Aufgaben im Cache.
  Future<int> freshCount({
    required String childId,
    required String subject,
  }) async {
    final fresh = await loadFresh(childId: childId, subject: subject);
    return fresh.length;
  }

  /// Speichert eine neue Charge. Bestehende verbrauchte Aufgaben
  /// werden auf _keepHistory begrenzt.
  Future<void> saveBatch({
    required String childId,
    required String subject,
    required List<LumoAiTaskDraft> drafts,
  }) async {
    if (drafts.isEmpty) return;
    final all = await _loadAll(childId: childId, subject: subject);
    final consumed = all.where((e) => e.consumed).toList();
    final keepConsumed = consumed.length > _keepHistory
        ? consumed.sublist(consumed.length - _keepHistory)
        : consumed;
    final fresh = all.where((e) => !e.consumed).toList();
    final existingPrompts = <String>{
      ...keepConsumed.map((e) => e.draft.prompt.toLowerCase()),
      ...fresh.map((e) => e.draft.prompt.toLowerCase()),
    };
    for (final d in drafts) {
      final repaired = _repairVisualMathDraft(d);
      if (existingPrompts.contains(repaired.prompt.toLowerCase())) continue;
      fresh.add(_CachedDraft(draft: repaired, consumed: false));
      existingPrompts.add(repaired.prompt.toLowerCase());
    }
    final all2 = [...keepConsumed, ...fresh];
    await _persistAll(childId: childId, subject: subject, entries: all2);
    await _writeMeta(childId: childId, subject: subject, generatedAtIso: DateTime.now().toIso8601String());
  }

  /// Markiert eine Aufgabe als verbraucht (Kind hat sie gesehen).
  Future<void> markConsumed({
    required String childId,
    required String subject,
    required String prompt,
  }) async {
    final all = await _loadAll(childId: childId, subject: subject);
    final lowered = prompt.toLowerCase();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (!all[i].consumed && all[i].draft.prompt.toLowerCase() == lowered) {
        all[i] = _CachedDraft(draft: all[i].draft, consumed: true);
        changed = true;
        break;
      }
    }
    if (changed) {
      await _persistAll(childId: childId, subject: subject, entries: all);
    }
  }

  /// Wann wurde zuletzt generiert? Null wenn noch nie.
  Future<DateTime?> lastGeneratedAt({
    required String childId,
    required String subject,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey(childId, subject));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Loescht alle Cache-Eintraege fuer ein Kind. Nutzbar im Elternbereich.
  Future<void> clear({
    required String childId,
    required String subject,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(childId, subject));
    await prefs.remove(_metaKey(childId, subject));
  }

  Future<List<_CachedDraft>> _loadAll({
    required String childId,
    required String subject,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(childId, subject));
    if (raw == null || raw.isEmpty) return <_CachedDraft>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_CachedDraft>[];
      final out = <_CachedDraft>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final draftJson = item['draft'];
        if (draftJson is! Map) continue;
        final draft = _repairVisualMathDraft(LumoAiTaskDraft.fromJson(Map<String, dynamic>.from(draftJson)));
        if (draft.prompt.isEmpty || draft.answer.isEmpty) continue;
        out.add(_CachedDraft(
          draft: draft,
          consumed: item['consumed'] == true,
        ));
      }
      return out;
    } catch (_) {
      return <_CachedDraft>[];
    }
  }

  LumoAiTaskDraft _repairVisualMathDraft(LumoAiTaskDraft draft) {
    final visual = draft.visual.trim().toLowerCase();
    if (visual != 'dots' && visual != 'line') return draft;
    if (RegExp(r'\d+\s*[+\-]\s*\d+').hasMatch(draft.prompt)) return draft;

    final numbers = RegExp(r'\d+')
        .allMatches(draft.prompt)
        .map((m) => int.tryParse(m.group(0) ?? ''))
        .whereType<int>()
        .toList(growable: false);
    if (numbers.length < 2) return draft;

    final answer = int.tryParse(draft.answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (answer == null) return draft;

    final left = numbers[0];
    final right = numbers[1];
    final lower = draft.prompt.toLowerCase();
    final isMinus = lower.contains('weg') || lower.contains('weniger') || lower.contains('verliert') || lower.contains('gibt') || lower.contains('minus');
    final computed = isMinus ? left - right : left + right;
    if (computed != answer) return draft;

    final op = isMinus ? '-' : '+';
    final repairedPrompt = '${draft.prompt.trim()}\n\nRechenbild: $left $op $right = ?';
    return LumoAiTaskDraft(
      prompt: repairedPrompt,
      answer: draft.answer,
      choices: draft.choices,
      explanation: draft.explanation,
      visual: isMinus ? 'line' : 'dots',
    );
  }

  Future<void> _persistAll({
    required String childId,
    required String subject,
    required List<_CachedDraft> entries,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries
        .map((e) => <String, dynamic>{
              'draft': e.draft.toJson(),
              'consumed': e.consumed,
            })
        .toList(growable: false));
    await prefs.setString(_storageKey(childId, subject), raw);
  }

  Future<void> _writeMeta({
    required String childId,
    required String subject,
    required String generatedAtIso,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_metaKey(childId, subject), generatedAtIso);
  }
}

class _CachedDraft {
  const _CachedDraft({required this.draft, required this.consumed});
  final LumoAiTaskDraft draft;
  final bool consumed;
}
