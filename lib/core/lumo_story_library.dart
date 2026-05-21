// ════════════════════════════════════════════════════════════════════════
// LUMO STORY LIBRARY — Persistente Bibliothek aller erstellten Geschichten
// ════════════════════════════════════════════════════════════════════════
// Speichert Stories als JSON in SharedPreferences.
// Heinz' Premium-Wert: 'Heft sammeln, wieder lesen, an Eltern weitergeben'.
// ════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'lumo_story_generator.dart';

class StoredStory {
  const StoredStory({
    required this.id,
    required this.story,
    required this.createdAt,
    required this.timesRead,
    required this.isFavorite,
  });

  final String id;
  final LumoStory story;
  final DateTime createdAt;
  final int timesRead;
  final bool isFavorite;

  Map<String, dynamic> toJson() => {
        'id': id,
        'story': _serializeStory(story),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'timesRead': timesRead,
        'isFavorite': isFavorite,
      };

  static StoredStory fromJson(Map<String, dynamic> j) {
    return StoredStory(
      id: j['id'] as String,
      story: _deserializeStory(j['story'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      timesRead: j['timesRead'] as int? ?? 0,
      isFavorite: j['isFavorite'] as bool? ?? false,
    );
  }

  StoredStory copyWith({int? timesRead, bool? isFavorite}) {
    return StoredStory(
      id: id,
      story: story,
      createdAt: createdAt,
      timesRead: timesRead ?? this.timesRead,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

Map<String, dynamic> _serializeStory(LumoStory s) => {
      'title': s.title,
      'hero': s.heroName,
      'location': s.location,
      'theme': s.theme,
      'grade': s.gradeLevel,
      'words': s.newWords,
      'pages': s.pages.map((p) => {
            'n': p.pageNum,
            't': p.text,
            'i': p.imagePrompt,
            'w': p.newWord,
            'e': p.exercise == null
                ? null
                : {
                    'type': p.exercise!.type.index,
                    'prompt': p.exercise!.prompt,
                    'answer': p.exercise!.correctAnswer,
                    'opts': p.exercise!.options,
                  },
          }).toList(),
    };

LumoStory _deserializeStory(Map<String, dynamic> j) {
  return LumoStory(
    title: j['title'] as String,
    heroName: j['hero'] as String,
    location: j['location'] as String,
    theme: j['theme'] as String,
    gradeLevel: j['grade'] as int,
    newWords: (j['words'] as List).cast<String>(),
    pages: (j['pages'] as List).map((p) {
      final pp = p as Map<String, dynamic>;
      final e = pp['e'] as Map<String, dynamic>?;
      return LumoStoryPage(
        pageNum: pp['n'] as int,
        text: pp['t'] as String,
        imagePrompt: pp['i'] as String,
        newWord: pp['w'] as String?,
        exercise: e == null
            ? null
            : StoryExercise(
                type: StoryExerciseType.values[e['type'] as int],
                prompt: e['prompt'] as String,
                correctAnswer: e['answer'] as String,
                options: (e['opts'] as List?)?.cast<String>(),
              ),
      );
    }).toList(),
  );
}

class LumoStoryLibrary {
  LumoStoryLibrary._();
  static final LumoStoryLibrary instance = LumoStoryLibrary._();

  static const _key = 'lumo_story_library_v1';
  List<StoredStory> _stories = [];
  bool _loaded = false;

  List<StoredStory> get all =>
      List.unmodifiable(_stories.reversed); // neueste zuerst
  List<StoredStory> get favorites =>
      _stories.where((s) => s.isFavorite).toList();
  int get count => _stories.length;

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _stories = list.map(StoredStory.fromJson).toList();
      } catch (_) {
        _stories = [];
      }
    }
    _loaded = true;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(_stories.map((s) => s.toJson()).toList()));
  }

  Future<StoredStory> addStory(LumoStory story) async {
    await load();
    final id = 'story_${DateTime.now().millisecondsSinceEpoch}';
    final stored = StoredStory(
      id: id,
      story: story,
      createdAt: DateTime.now(),
      timesRead: 0,
      isFavorite: false,
    );
    _stories.add(stored);
    await save();
    return stored;
  }

  Future<void> incrementRead(String id) async {
    await load();
    final idx = _stories.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _stories[idx] = _stories[idx].copyWith(
          timesRead: _stories[idx].timesRead + 1);
      await save();
    }
  }

  Future<void> toggleFavorite(String id) async {
    await load();
    final idx = _stories.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _stories[idx] = _stories[idx].copyWith(
          isFavorite: !_stories[idx].isFavorite);
      await save();
    }
  }

  Future<void> delete(String id) async {
    await load();
    _stories.removeWhere((s) => s.id == id);
    await save();
  }

  /// Alle Worte aus allen Geschichten - fuer Schreibcoach.
  List<String> get allNewWords {
    final words = <String>{};
    for (final s in _stories) {
      words.addAll(s.story.newWords);
    }
    return words.toList();
  }
}
