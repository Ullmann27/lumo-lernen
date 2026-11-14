import '../learning/lumo_learning_domain.dart';

/// The first bounded set with an actual, distinguishable native 3D object.
/// These words already occur in the local exercise generator. This is help
/// for the current task, not a second exercise generator or answer channel.
abstract final class NativeEnglishVocabulary {
  static const meanings = <String, Set<String>>{
    'book': {'Buch'},
    'pen': {'Kugelschreiber', 'Stift'},
    'ruler': {'Lineal'},
    'ball': {'Ball'},
    'car': {'Auto'},
    'sun': {'Sonne'},
    'apple': {'Apfel'},
  };

  static Map<String, Object>? illustrationFor(TaskInstance task) {
    if (task.subject != LearningSubject.englisch ||
        task.taskType != TaskType.multipleChoice ||
        task.correctAnswer is! String) {
      return null;
    }
    // Match only the two actual reviewed local prompt forms. Free text,
    // a coincidental word in another question, and a wrong answer fail closed.
    final prompt = task.prompt;
    final generated = RegExp(r'^Was bedeutet „([a-z]+)“\?$').firstMatch(prompt);
    final fallback = RegExp(
      r'^Was heißt ([a-z]+) auf Deutsch\?$',
    ).firstMatch(prompt);
    final word = generated?.group(1) ?? fallback?.group(1);
    final accepted = meanings[word];
    final answer = task.correctAnswer as String;
    if (word == null || accepted == null || !accepted.contains(answer)) {
      return null;
    }
    if (task.options.length < 2 ||
        task.options.length > 6 ||
        task.options.where((option) => option.payload == answer).length != 1 ||
        task.options.any(
          (option) =>
              option.payload is! String || option.label != option.payload,
        ) ||
        task.options.map((option) => option.label).toSet().length !=
            task.options.length) {
      return null;
    }

    // Prefer distractor objects which are already among this task's choices.
    // Fill only from the same small, reviewed local object catalogue.
    final objects = <String>[word];
    for (final option in task.options) {
      for (final entry in meanings.entries) {
        if (entry.value.contains(option.payload) &&
            !objects.contains(entry.key) &&
            objects.length < 3) {
          objects.add(entry.key);
        }
      }
    }
    var seed = 0;
    for (final unit in task.seedHash.codeUnits) {
      seed = (seed * 31 + unit) & 0x7fffffff;
    }
    final keys = meanings.keys.toList(growable: false);
    for (var offset = 0; objects.length < 3; offset++) {
      final candidate = keys[(seed + offset) % keys.length];
      if (!objects.contains(candidate)) objects.add(candidate);
    }
    final shift = seed % objects.length;
    final ordered = <String>[...objects.skip(shift), ...objects.take(shift)];
    return <String, Object>{
      'kind': 'english_objects',
      'word': word,
      'meaning': answer,
      'objects': List<String>.unmodifiable(ordered),
    };
  }
}
