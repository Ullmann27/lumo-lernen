import 'school_exercise_generator.dart';

/// Defensive quality gate for legacy generated LumoTask instances.
///
/// The guard is intentionally deterministic. It does not invent new tasks; it
/// rejects obviously invalid or didactically weak tasks so the adapter can
/// sanitize or rotate to a safer fallback.
class TaskQualityGuard {
  const TaskQualityGuard();

  static const Set<String> _articles = <String>{'der', 'die', 'das'};
  static const Set<String> _nouns = <String>{
    'hund', 'haus', 'schule', 'sonne', 'buch', 'auto', 'kind', 'lampe',
    'baum', 'blume', 'katze', 'maus', 'fuchs', 'ball', 'apfel', 'rose',
  };
  static const Set<String> _verbs = <String>{
    'lesen', 'laufen', 'malen', 'springen', 'essen', 'singen', 'lachen',
    'spielen', 'tanzen', 'schreiben', 'rechnen', 'kochen', 'bellen',
  };
  static const Set<String> _adjectives = <String>{
    'groß', 'gross', 'klein', 'warm', 'schnell', 'weich', 'kalt', 'hell',
    'dunkel', 'schön', 'schoen', 'leise', 'rot', 'gelb', 'laut', 'fleißig',
    'fleissig',
  };

  bool validate(LumoTask task) => problems(task).isEmpty;

  List<String> problems(LumoTask task) {
    final issues = <String>[];
    final answer = task.answer.trim();
    final choices = task.choices.map((c) => c.trim()).where((c) => c.isNotEmpty).toList(growable: false);

    if (task.prompt.trim().isEmpty) issues.add('empty_prompt');
    if (answer.isEmpty) issues.add('empty_answer');
    if (task.explanation.trim().isEmpty) issues.add('empty_explanation');

    final isFreeAnswer = task.handwriting || choices.length <= 1;
    if (!isFreeAnswer) {
      if (!_containsChoice(choices, answer)) issues.add('answer_not_in_choices');
      if (_hasDuplicateChoices(choices)) issues.add('duplicate_choices');
      issues.addAll(_phonicsProblems(task.prompt, answer, choices));
      issues.addAll(_numericProblems(task.prompt, answer, choices));
      issues.addAll(_germanCategoryProblems(task.prompt, answer, choices));
    }

    return issues;
  }

  List<String> _phonicsProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final ending = RegExp(r'endet\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(prompt);
    if (ending != null) {
      final expected = _normalizeWord(ending.group(1) ?? '');
      final matching = choices.where((c) => _normalizeWord(c).endsWith(expected)).toList(growable: false);
      if (!_normalizeWord(answer).endsWith(expected)) issues.add('answer_wrong_ending');
      if (matching.length != 1) issues.add('ending_not_exactly_one_choice');
    }

    final beginning = RegExp(r'(?:beginnt|anf[aä]ngt)\s+mit\s+([A-Za-zÄÖÜäöüß])\?', caseSensitive: false).firstMatch(prompt);
    if (beginning != null) {
      final expected = _normalizeWord(beginning.group(1) ?? '');
      final matching = choices.where((c) => _normalizeWord(c).startsWith(expected)).toList(growable: false);
      if (!_normalizeWord(answer).startsWith(expected)) issues.add('answer_wrong_beginning');
      if (matching.length != 1) issues.add('beginning_not_exactly_one_choice');
    }

    final rhyme = RegExp(r'reimt\s+sich\s+auf\s+([^?]+)\?', caseSensitive: false).firstMatch(prompt);
    if (rhyme != null) {
      final base = _normalizeWord(rhyme.group(1) ?? '');
      if (base.length >= 2) {
        final tail = base.substring(base.length - 2);
        if (!_normalizeWord(answer).endsWith(tail)) issues.add('answer_does_not_rhyme_basically');
      }
    }

    final article = RegExp(r'Welcher\s+Artikel\s+passt\s+zu\s+', caseSensitive: false).hasMatch(prompt);
    if (article) {
      if (!_articles.contains(_normalizeChoice(answer))) issues.add('article_answer_invalid');
      final articlesInChoices = choices.where((c) => _articles.contains(_normalizeChoice(c))).length;
      if (articlesInChoices < 2) issues.add('article_choices_incomplete');
    }

    final syllables = RegExp(r'Wie\s+viele\s+Silben', caseSensitive: false).hasMatch(prompt);
    if (syllables) {
      final n = int.tryParse(answer.trim());
      if (n == null || n < 1 || n > 6) issues.add('syllable_answer_not_numeric_in_range');
    }

    return issues;
  }

  List<String> _numericProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final looksNumeric = RegExp(r'\d+\s*[+\-*/]|=|Wie viele|Hälfte|Haelfte|Doppelte|Zahl', caseSensitive: false).hasMatch(prompt);
    if (!looksNumeric) return issues;
    final answerNumber = int.tryParse(answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (answerNumber == null && !answer.toLowerCase().contains('uhr') && !answer.toLowerCase().contains('euro')) {
      issues.add('numeric_answer_not_parseable');
    }
    final seenNumbers = <int>{};
    for (final choice in choices) {
      final choiceNumber = int.tryParse(choice.replaceAll(RegExp(r'[^0-9-]'), ''));
      if (choiceNumber == null && RegExp(r'^-?\d+').hasMatch(choice)) issues.add('numeric_choice_not_parseable');
      if (choiceNumber != null && !seenNumbers.add(choiceNumber)) issues.add('duplicate_numeric_choice');
    }
    return issues;
  }

  List<String> _germanCategoryProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final lowerPrompt = prompt.toLowerCase();
    final normalizedAnswer = _normalizeChoice(answer);

    if (lowerPrompt.contains('welcher satz ist richtig')) {
      final sentenceLikeChoices = choices.where(_looksLikeSentenceOrSentencePart).length;
      if (sentenceLikeChoices != choices.length) issues.add('sentence_choices_not_sentence_like');
      if (!_looksLikeCorrectSentence(answer)) issues.add('answer_not_correct_sentence_like');
    }

    if (lowerPrompt.contains('namenswort') || lowerPrompt.contains('nomen') || lowerPrompt.contains('hauptwort')) {
      if (!_nouns.contains(normalizedAnswer)) issues.add('nomen_answer_not_known_noun');
      final hasVerbOrAdjDistractor = choices
          .where((c) => _normalizeChoice(c) != normalizedAnswer)
          .any((c) => _verbs.contains(_normalizeChoice(c)) || _adjectives.contains(_normalizeChoice(c)));
      if (!hasVerbOrAdjDistractor) issues.add('nomen_choices_missing_wordclass_distractor');
    }

    if (lowerPrompt.contains('tunwort') || lowerPrompt.contains('verb')) {
      if (!_verbs.contains(normalizedAnswer)) issues.add('verb_answer_not_known_verb');
      final badAllVerbChoices = choices.every((c) => _verbs.contains(_normalizeChoice(c)));
      if (badAllVerbChoices) issues.add('verb_choices_not_contrasting_wordclasses');
    }

    if (lowerPrompt.contains('wiewort') || lowerPrompt.contains('eigenschaft') || lowerPrompt.contains('beschreibt, wie')) {
      if (!_adjectives.contains(normalizedAnswer)) issues.add('adjective_answer_not_known_adjective');
      final badAllAdjectiveChoices = choices.every((c) => _adjectives.contains(_normalizeChoice(c)));
      if (badAllAdjectiveChoices) issues.add('adjective_choices_not_contrasting_wordclasses');
    }

    return issues;
  }

  bool _looksLikeSentenceOrSentencePart(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final wordCount = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return wordCount >= 2;
  }

  bool _looksLikeCorrectSentence(String value) {
    final trimmed = value.trim();
    if (!_looksLikeSentenceOrSentencePart(trimmed)) return false;
    final startsUpper = RegExp(r'^[A-ZÄÖÜ]').hasMatch(trimmed);
    final endsSentence = RegExp(r'[.!?]$').hasMatch(trimmed);
    return startsUpper && endsSentence;
  }

  bool _containsChoice(List<String> choices, String answer) {
    final normalizedAnswer = _normalizeChoice(answer);
    return choices.any((c) => _normalizeChoice(c) == normalizedAnswer);
  }

  bool _hasDuplicateChoices(List<String> choices) {
    final seen = <String>{};
    for (final choice in choices) {
      final normalized = _normalizeChoice(choice);
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) return true;
    }
    return false;
  }

  String _normalizeChoice(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _normalizeWord(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');
}
