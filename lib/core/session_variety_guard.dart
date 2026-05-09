import 'school_exercise_generator.dart';
import 'writing_target_parser.dart';

/// Lightweight in-memory guard for one learning session.
///
/// It prevents visible repetition beyond exact task IDs by tracking:
/// - full task keys
/// - recent correct answers
/// - normalized prompt patterns
/// - significant words from prompt and answer
///
/// The guard is intentionally local-only and does not persist child data.
class SessionVarietyGuard {
  SessionVarietyGuard({
    this.maxTaskKeys = 80,
    this.maxAnswers = 10,
    this.maxPromptPatterns = 14,
    this.maxWords = 24,
  });

  final int maxTaskKeys;
  final int maxAnswers;
  final int maxPromptPatterns;
  final int maxWords;

  final List<String> _taskKeys = <String>[];
  final List<String> _answers = <String>[];
  final List<String> _promptPatterns = <String>[];
  final List<String> _words = <String>[];

  bool allows(LumoTask task, {bool relaxed = false}) {
    final key = taskKey(task);
    if (_taskKeys.contains(key)) return false;

    final answer = _normalize(task.answer);
    if (!relaxed && answer.isNotEmpty && _answers.contains(answer)) {
      return false;
    }

    final pattern = promptPattern(task.prompt);
    if (!relaxed && pattern.isNotEmpty && _promptPatterns.contains(pattern)) {
      return false;
    }

    if (!relaxed) {
      final taskWords = significantWords(task);
      if (taskWords.any(_words.contains)) return false;
    }

    return true;
  }

  void remember(LumoTask task) {
    _pushUnique(_taskKeys, taskKey(task), maxTaskKeys);
    _pushUnique(_answers, _normalize(task.answer), maxAnswers);
    _pushUnique(_promptPatterns, promptPattern(task.prompt), maxPromptPatterns);
    for (final word in significantWords(task)) {
      _pushUnique(_words, word, maxWords);
    }
  }

  void reset() {
    _taskKeys.clear();
    _answers.clear();
    _promptPatterns.clear();
    _words.clear();
  }

  String taskKey(LumoTask task) {
    final choices = task.choices
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toList(growable: false)
      ..sort();
    return <String>[
      _normalize(task.subject),
      _normalize(task.unit),
      _normalize(task.prompt),
      _normalize(task.answer),
      _normalize(task.visual),
      _normalize(task.missionTag),
      task.handwriting ? 'handwriting' : 'choice',
      task.difficulty.toString(),
      task.handwriting ? _normalize(WritingTargetParser.parse(task.prompt)) : '',
      choices.join(','),
    ].join('|');
  }

  /// Stable, separator-safe markers that can be persisted between app starts.
  ///
  /// The exact marker blocks identical tasks. The family marker blocks near
  /// repeats such as the same normalized prompt pattern plus answer, even when
  /// choice order or generated IDs differ.
  List<String> taskMemoryKeys(LumoTask task) => <String>[
        'task-${_stableHash(taskKey(task))}',
        'family-${_stableHash(taskFamilyKey(task))}',
      ];

  String taskFamilyKey(LumoTask task) {
    return <String>[
      _normalize(task.subject),
      _normalize(task.unit),
      promptPattern(task.prompt),
      _normalize(task.answer),
      _normalize(task.visual),
      _normalize(task.missionTag),
      task.handwriting ? _normalize(WritingTargetParser.parse(task.prompt)) : '',
    ].join('|');
  }

  String promptPattern(String prompt) {
    return _normalize(prompt)
        .replaceAll(RegExp(r'\b\d+\b'), '#')
        .replaceAll(RegExp(r'\b[a-zäöüß]{6,}\b', caseSensitive: false), '*')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> significantWords(LumoTask task) {
    final text = '${task.prompt} ${task.answer}';
    final matches = RegExp(r'[A-Za-zÄÖÜäöüß]{4,}').allMatches(text);
    final words = <String>{};
    for (final match in matches) {
      final word = _normalize(match.group(0) ?? '');
      if (word.length < 4) continue;
      if (_stopWords.contains(word)) continue;
      words.add(word);
    }
    return words;
  }

  void _pushUnique(List<String> list, String value, int maxLength) {
    if (value.trim().isEmpty) return;
    list.remove(value);
    list.add(value);
    while (list.length > maxLength) {
      list.removeAt(0);
    }
  }

  String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.!?;:,]'), '');
  }

  static const Set<String> _stopWords = <String>{
    'aufgabe',
    'welche',
    'welcher',
    'welches',
    'wieviel',
    'viele',
    'kommt',
    'direkt',
    'passt',
    'richtig',
    'falsch',
    'lumo',
    'eine',
    'einen',
    'einem',
    'einer',
    'oder',
    'und',
    'der',
    'die',
    'das',
    'dem',
    'den',
    'was',
    'wie',
    'mit',
    'hat',
    'ist',
    'sich',
    'wort',
    'satz',
  };
}
