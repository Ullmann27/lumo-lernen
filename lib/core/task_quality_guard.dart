import 'primary_school_word_data.dart';
import 'school_exercise_generator.dart';

/// Deterministic quality gate for generated school tasks.
/// It blocks tasks with unclear answer logic before they reach the UI.
class TaskQualityGuard {
  const TaskQualityGuard();

  static const _articles = <String>{'der', 'die', 'das'};
  static const _nouns = <String>{
    'hund', 'haus', 'schule', 'sonne', 'buch', 'auto', 'kind', 'lampe',
    'baum', 'blume', 'katze', 'maus', 'fuchs', 'ball', 'apfel', 'rose',
    'biene', 'kerze', 'igel', 'wolke', 'brot', 'stift', 'garten',
  };
  static const _verbs = <String>{
    'lesen', 'laufen', 'malen', 'springen', 'essen', 'singen', 'lachen',
    'spielen', 'tanzen', 'schreiben', 'rechnen', 'kochen', 'bellen',
    'fliegen', 'trinken', 'backen', 'zaehlen', 'zählen',
  };
  static const _adjectives = <String>{
    'gross', 'groß', 'klein', 'warm', 'schnell', 'weich', 'kalt', 'hell',
    'dunkel', 'schoen', 'schön', 'leise', 'rot', 'gelb', 'laut', 'rund',
    'langsam',
  };

  /// Correct unrelated words must not be used as distractors in spelling tasks.
  static const _knownCorrectWords = <String>{
    'und', 'ist', 'mama', 'papa', 'haus', 'ball', 'sonne', 'spielen',
    'kommen', 'schule', 'freund', 'heute', 'klein', 'gross', 'groß',
    'blume', 'kerze', 'biene', 'wolke', 'baum', 'katze', 'apfel', 'rose',
    'igel', 'hund', 'brot', 'stift', 'kind',
  };

  bool validate(LumoTask task) => problems(task).isEmpty;

  List<String> problems(LumoTask task) {
    final issues = <String>[];
    final prompt = task.prompt.trim();
    final answer = task.answer.trim();
    final choices = task.choices.map((c) => c.trim()).where((c) => c.isNotEmpty).toList(growable: false);

    if (prompt.isEmpty) issues.add('empty_prompt');
    if (answer.isEmpty) issues.add('empty_answer');
    if (task.explanation.trim().isEmpty) issues.add('empty_explanation');

    final freeAnswer = task.handwriting || choices.length <= 1;
    if (freeAnswer) return issues;

    if (!_containsChoice(choices, answer)) issues.add('answer_not_in_choices');
    if (_hasDuplicateChoices(choices)) issues.add('duplicate_choices');

    issues.addAll(_numericProblems(prompt, answer, choices));
    issues.addAll(_soundProblems(prompt, answer, choices));
    issues.addAll(_rhymeProblems(prompt, answer, choices));
    issues.addAll(_syllableProblems(prompt, answer, choices));
    issues.addAll(_spellingProblems(prompt, answer, choices));
    issues.addAll(_wordClassProblems(prompt, answer, choices));

    return issues.toSet().toList(growable: false);
  }

  List<String> _numericProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final expected = _expectedNumber(prompt);
    if (expected == null) return issues;
    final actual = _extractInt(answer);
    if (actual == null) {
      issues.add('numeric_answer_not_parseable');
      return issues;
    }
    if (actual != expected) issues.add('numeric_answer_wrong_result');

    final seen = <int>{};
    for (final choice in choices) {
      final value = _extractInt(choice);
      if (value != null && !seen.add(value)) issues.add('duplicate_numeric_choice');
    }
    return issues;
  }

  List<String> _soundProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final wordEnding = RegExp(r'Welches\s+Wort\s+endet\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(prompt);
    if (wordEnding != null) {
      final sound = _word(wordEnding.group(1) ?? '');
      final matching = choices.where((c) => _word(c).endsWith(sound)).length;
      if (!_word(answer).endsWith(sound)) issues.add('answer_wrong_ending');
      if (matching != 1) issues.add('ending_not_exactly_one_choice');
    }

    final wordBeginning = RegExp(r'Welches\s+Wort\s+beginnt\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(prompt);
    if (wordBeginning != null) {
      final sound = _word(wordBeginning.group(1) ?? '');
      final matching = choices.where((c) => _word(c).startsWith(sound)).length;
      if (!_word(answer).startsWith(sound)) issues.add('answer_wrong_beginning');
      if (matching != 1) issues.add('beginning_not_exactly_one_choice');
    }

    final letterStart = RegExp(r'Mit\s+welchem\s+Laut\s+beginnt\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
    if (letterStart != null) {
      final word = _word(letterStart.group(1) ?? '');
      final expected = word.isEmpty ? '' : word.substring(0, 1);
      if (_word(answer) != expected) issues.add('answer_wrong_initial_sound');
      if (choices.where((c) => _word(c) == expected).length != 1) issues.add('initial_sound_not_exactly_one_choice');
    }

    final letterEnd = RegExp(r'Mit\s+welchem\s+Laut\s+endet\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
    if (letterEnd != null) {
      final word = _word(letterEnd.group(1) ?? '');
      final expected = word.isEmpty ? '' : word.substring(word.length - 1);
      if (_word(answer) != expected) issues.add('answer_wrong_final_sound');
      if (choices.where((c) => _word(c) == expected).length != 1) issues.add('final_sound_not_exactly_one_choice');
    }

    if (RegExp(r'Welcher\s+Artikel\s+passt', caseSensitive: false).hasMatch(prompt)) {
      if (!_articles.contains(_choice(answer))) issues.add('article_answer_invalid');
      if (choices.where((c) => _articles.contains(_choice(c))).length < 2) issues.add('article_choices_incomplete');
      final nounMatch = RegExp(r'passt\s+zu\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
      final noun = nounMatch == null ? '' : _stripPunctuation(nounMatch.group(1) ?? '');
      final expected = PrimarySchoolWordData.articleFor(noun);
      if (expected != null && _choice(answer) != expected) issues.add('article_answer_wrong_for_noun');
      if (expected != null && choices.where((c) => _choice(c) == expected).length != 1) issues.add('article_not_exactly_one_correct_choice');
    }

    return issues;
  }


  List<String> _rhymeProblems(String prompt, String answer, List<String> choices) {
    final match = RegExp(r'Was\s+reimt\s+sich\s+auf\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
    if (match == null) return const <String>[];
    final base = _stripPunctuation(match.group(1) ?? '');
    final expected = _knownRhymePartner(base);
    if (expected == null) return const <String>[];
    final issues = <String>[];
    if (_choice(answer) != _choice(expected)) issues.add('rhyme_answer_not_known_partner');
    if (choices.where((c) => _choice(c) == _choice(expected)).length != 1) {
      issues.add('rhyme_not_exactly_one_known_partner');
    }
    return issues;
  }

  List<String> _syllableProblems(String prompt, String answer, List<String> choices) {
    final match = RegExp(r'Wie\s+viele\s+Silben\s+hat\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
    if (match == null) return const <String>[];
    final word = _stripPunctuation(match.group(1) ?? '');
    final syllables = PrimarySchoolWordData.syllablesFor(word);
    if (syllables == null) return const <String>[];
    final expected = syllables.length;
    final issues = <String>[];
    if (_extractInt(answer) != expected) issues.add('syllable_answer_wrong_count');
    if (choices.where((c) => _extractInt(c) == expected).length != 1) {
      issues.add('syllable_not_exactly_one_correct_choice');
    }
    return issues;
  }

  List<String> _spellingProblems(String prompt, String answer, List<String> choices) {
    if (!RegExp(r'Schreibweise\s+ist\s+richtig', caseSensitive: false).hasMatch(prompt)) {
      return const <String>[];
    }

    final issues = <String>[];
    final wrongChoices = choices.where((c) => _choice(c) != _choice(answer)).toList(growable: false);
    if (wrongChoices.length < 2) issues.add('spelling_not_enough_distractors');

    var hasMisspelling = false;
    for (final wrong in wrongChoices) {
      final variant = _looksLikeMisspelling(answer, wrong);
      hasMisspelling = hasMisspelling || variant;
      if (!variant) issues.add('spelling_distractor_not_variant');
      if (_knownCorrectWords.contains(_spelling(wrong)) && !variant) {
        issues.add('spelling_distractor_is_unrelated_correct_word');
      }
    }
    if (!hasMisspelling) issues.add('spelling_missing_misspelling_variant');
    return issues;
  }

  List<String> _wordClassProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final lower = prompt.toLowerCase();
    final a = _choice(answer);

    if (lower.contains('welcher satz ist richtig')) {
      if (!_isCorrectSentence(answer)) issues.add('answer_not_correct_sentence_like');
      if (!choices.every(_isSentencePart)) issues.add('sentence_choices_not_sentence_like');
    }
    if (_isNounQuestion(lower)) {
      if (!_isKnownNoun(answer)) issues.add('nomen_answer_not_known_noun');
      if (!choices.where((c) => _choice(c) != a).any((c) => _isKnownVerb(c) || _isKnownAdjective(c))) {
        issues.add('nomen_choices_missing_wordclass_distractor');
      }
    }
    if (_isVerbQuestion(lower)) {
      if (!_isKnownVerb(answer)) issues.add('verb_answer_not_known_verb');
      if (choices.every(_isKnownVerb)) issues.add('verb_choices_not_contrasting_wordclasses');
    }
    if (_isAdjectiveQuestion(lower)) {
      if (!_isKnownAdjective(answer)) issues.add('adjective_answer_not_known_adjective');
      if (choices.every(_isKnownAdjective)) issues.add('adjective_choices_not_contrasting_wordclasses');
    }

    return issues;
  }

  bool _isNounQuestion(String prompt) =>
      prompt.contains('welches wort ist ein namenswort') ||
      prompt.contains('welches wort ist ein namenwort') ||
      prompt.contains('welches wort ist ein nomen') ||
      prompt.contains('welches wort ist ein hauptwort');

  bool _isVerbQuestion(String prompt) =>
      prompt.contains('welches wort ist ein tunwort') ||
      prompt.contains('welches wort ist ein verb');

  bool _isAdjectiveQuestion(String prompt) =>
      prompt.contains('welches wort ist ein wiewort') ||
      prompt.contains('welches wort beschreibt, wie') ||
      prompt.contains('welches wort ist eine eigenschaft');

  int? _expectedNumber(String prompt) {
    final basic = RegExp(r'(\d+)\s*([+\-])\s*(\d+)\s*=\s*\?').firstMatch(prompt);
    if (basic != null) {
      final left = int.tryParse(basic.group(1) ?? '');
      final op = basic.group(2);
      final right = int.tryParse(basic.group(3) ?? '');
      if (left == null || right == null) return null;
      return op == '+' ? left + right : left - right;
    }
    final before = RegExp(r'direkt\s+vor\s+(\d+)', caseSensitive: false).firstMatch(prompt);
    if (before != null) return (int.tryParse(before.group(1) ?? '') ?? 0) - 1;
    final after = RegExp(r'direkt\s+nach\s+(\d+)', caseSensitive: false).firstMatch(prompt);
    if (after != null) return (int.tryParse(after.group(1) ?? '') ?? 0) + 1;
    return null;
  }

  bool _isKnownNoun(String value) => _nouns.contains(_choice(value)) || _wordType(value) == WordType.noun;

  bool _isKnownVerb(String value) => _verbs.contains(_choice(value)) || _wordType(value) == WordType.verb;

  bool _isKnownAdjective(String value) => _adjectives.contains(_choice(value)) || _wordType(value) == WordType.adjective;

  WordType? _wordType(String value) {
    final normalized = _choice(value);
    for (final entry in PrimarySchoolWordData.dictionary.values) {
      if (_choice(entry.word) == normalized) return entry.wordType;
    }
    return null;
  }

  String? _knownRhymePartner(String word) {
    final normalized = _choice(word);
    for (final pair in PrimarySchoolWordData.rhymePairs) {
      if (pair.length < 2) continue;
      if (_choice(pair.first) == normalized) return pair.last;
      if (_choice(pair.last) == normalized) return pair.first;
    }
    return null;
  }

  String _stripPunctuation(String value) => value.trim().replaceAll(RegExp(r'[„“".:;!,]+$'), '').trim();

  bool _containsChoice(List<String> choices, String answer) => choices.any((c) => _choice(c) == _choice(answer));

  bool _hasDuplicateChoices(List<String> choices) {
    final seen = <String>{};
    for (final choice in choices) {
      if (!seen.add(_choice(choice))) return true;
    }
    return false;
  }

  bool _looksLikeMisspelling(String correct, String candidate) {
    final a = _spelling(correct);
    final b = _spelling(candidate);
    if (a.isEmpty || b.isEmpty || a == b) return false;
    if ((a.length - b.length).abs() > 2) return false;
    if (_collapse(a) == _collapse(b)) return true;
    return _distance(a, b) <= 2;
  }

  bool _isSentencePart(String value) => value.trim().split(RegExp(r'\s+')).length >= 2;

  bool _isCorrectSentence(String value) {
    final trimmed = value.trim();
    return _isSentencePart(trimmed) && RegExp(r'^[A-ZÄÖÜ]').hasMatch(trimmed) && RegExp(r'[.!?]$').hasMatch(trimmed);
  }

  int? _extractInt(String value) => int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));

  String _choice(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _word(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');

  String _spelling(String value) => _word(value)
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');

  String _collapse(String value) => value.replaceAllMapped(RegExp(r'([a-z])\1+'), (m) => m.group(1)!);

  int _distance(String a, String b) {
    final row = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var previous = i;
      for (var j = 1; j <= b.length; j++) {
        final old = row[j];
        final replace = a[i - 1] == b[j - 1] ? row[j - 1] : row[j - 1] + 1;
        final insert = previous + 1;
        final delete = row[j] + 1;
        row[j - 1] = previous;
        previous = replace < insert ? (replace < delete ? replace : delete) : (insert < delete ? insert : delete);
      }
      row[b.length] = previous;
    }
    return row[b.length];
  }
}
