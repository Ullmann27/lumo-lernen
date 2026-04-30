import 'package:shared_preferences/shared_preferences.dart';

/// Stores recently used generated reading-story signatures locally.
///
/// The generator creates many combinations, but a small recency block prevents
/// children from seeing the same content pattern again too soon. The stored
/// values are content signatures, not personal transcripts.
class ReadingStoryMemoryRepository {
  static const int _maxRecentStories = 40;
  static const String _prefix = 'lumo.reading.recent_story_signatures';

  String _key({required String childId, required int grade}) {
    return '$_prefix.$childId.grade$grade';
  }

  Future<List<String>> loadRecent({required String childId, required int grade}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_key(childId: childId, grade: grade));
      if (values == null) return const <String>[];
      return values.where((value) => value.trim().isNotEmpty).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> remember({required String childId, required int grade, required String signature}) async {
    final clean = signature.trim();
    if (clean.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(childId: childId, grade: grade);
      final recent = prefs.getStringList(key) ?? <String>[];
      recent.remove(clean);
      recent.add(clean);
      while (recent.length > _maxRecentStories) {
        recent.removeAt(0);
      }
      await prefs.setStringList(key, recent);
    } catch (_) {
      // Story memory is helpful, but never critical. Reading must still work.
    }
  }
}
