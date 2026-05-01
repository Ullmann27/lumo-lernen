import 'school_exercise_generator.dart';

/// Defensive quality gate for legacy generated LumoTask instances.
///
/// The guard is intentionally small and deterministic. It does not invent new
/// tasks; it only rejects obviously invalid ones so the adapter can sanitize or
/// regenerate later.
class TaskQualityGuard {
  const TaskQualityGuard();

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
    return issues;
  }

  List<String> _numericProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final looksNumeric = RegExp(r'\d+\s*[+\-*/]|=|Wie viele|Haelfte|Doppelte|Zahl', caseSensitive: false).hasMatch(prompt);
    if (!looksNumeric) return issues;
    final answerNumber = int.tryParse(answer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (answerNumber == null && !answer.toLowerCase().contains('uhr') && !answer.toLowerCase().contains('euro')) {
      issues.add('numeric_answer_not_parseable');
    }
    for (final choice in choices) {
      final choiceNumber = int.tryParse(choice.replaceAll(RegExp(r'[^0-9-]'), ''));
      if (choiceNumber == null && RegExp(r'^-?\d+').hasMatch(choice)) issues.add('numeric_choice_not_parseable');
    }
    return issues;
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
