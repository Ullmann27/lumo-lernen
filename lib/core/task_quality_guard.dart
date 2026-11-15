import 'primary_school_word_data.dart';
import 'school_exercise_generator.dart';
import 'checked_task_patterns.dart';

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

  /// The accepted card is resolved with the same comparison used by the gate.
  /// The adapter may then retain its original label and unit without turning
  /// e.g. "1,5", "15" or "1:05 Uhr" into the same integer payload.
  bool matchesAnswer(LumoTask task, String candidate) =>
      _choiceKey(candidate, preserveCase: _preserveAnswerCase(task)) ==
      _choiceKey(task.answer, preserveCase: _preserveAnswerCase(task));

  bool _preserveAnswerCase(LumoTask task) =>
      task.subject == 'Rechtschreibung' ||
      task.prompt.toLowerCase().contains('schreibweise') ||
      task.prompt.toLowerCase().contains('schreibt man');

  List<String> problems(LumoTask task) {
    final issues = <String>[];
    final prompt = task.prompt.trim();
    final answer = task.answer.trim();
    final choices = task.choices.map((c) => c.trim()).where((c) => c.isNotEmpty).toList(growable: false);

    if (prompt.isEmpty) issues.add('empty_prompt');
    if (answer.isEmpty) issues.add('empty_answer');
    if (task.explanation.trim().isEmpty) issues.add('empty_explanation');
    if (task.grade < 1 || task.grade > 4) issues.add('grade_out_of_range');
    if (task.difficulty < 1) issues.add('difficulty_out_of_range');
    if (task.difficulty > task.grade) issues.add('difficulty_above_grade');

    final freeAnswer = task.handwriting || task.visual == 'shape_trace';
    if (freeAnswer) return issues;
    if (choices.length < 2) issues.add('not_enough_choices');
    // Groß-/Kleinschreibung ist in Rechtschreibaufgaben gerade die Frage.
    final preserveCase = _preserveAnswerCase(task);
    if (!choices.any((choice) => _choiceKey(choice, preserveCase: preserveCase) ==
        _choiceKey(answer, preserveCase: preserveCase))) {
      issues.add('answer_not_in_choices');
    }
    if (_hasDuplicateChoices(choices, preserveCase: preserveCase)) issues.add('duplicate_choices');

    issues.addAll(_numericProblems(prompt, answer, choices));
    issues.addAll(_mathPropertyProblems(task));
    issues.addAll(_logicProblems(task, choices));
    issues.addAll(_soundProblems(prompt, answer, choices));
    issues.addAll(_rhymeProblems(prompt, answer, choices));
    issues.addAll(_syllableProblems(prompt, answer, choices));
    issues.addAll(_spellingProblems(prompt, answer, choices));
    issues.addAll(_wordClassProblems(prompt, answer, choices));

    return issues.toSet().toList(growable: false);
  }

  List<String> _mathPropertyProblems(LumoTask task) {
    if (task.subject != 'Mathematik') return const [];
    final prompt = task.prompt.trim();
    final answer = task.answer.trim();
    final compare = RegExp(r'^Welches Zeichen passt\? (\d+) \? (\d+)$')
        .firstMatch(prompt);
    if (compare != null) {
      final left = int.parse(compare[1]!);
      final right = int.parse(compare[2]!);
      final expected = left < right ? '<' : left > right ? '>' : '=';
      return answer == expected ? const [] : const ['comparison_answer_wrong'];
    }
    final parity = RegExp(r'^Ist (\d+) gerade oder ungerade\?$').firstMatch(prompt);
    if (parity != null) {
      final expected = int.parse(parity[1]!).isEven ? 'gerade' : 'ungerade';
      return answer == expected ? const [] : const ['parity_answer_wrong'];
    }
    final quantities = RegExp(r'^(🍎+) oder (🍎+) – wo ist mehr\?$', unicode: true)
        .firstMatch(prompt);
    if (quantities != null) {
      final left = '🍎'.allMatches(quantities[1]!).length;
      final right = '🍎'.allMatches(quantities[2]!).length;
      final expected = left == right ? 'gleich' : left > right ? 'links' : 'rechts';
      return answer == expected ? const [] : const ['quantity_answer_wrong'];
    }
    final clock = RegExp(
        r'^Welche Uhrzeit ist gemeint: Stunde (\d+) und Minute (\d+)\?$')
        .firstMatch(prompt);
    if (clock != null) {
      final hour = int.parse(clock[1]!);
      final minute = int.parse(clock[2]!);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return const ['clock_values_out_of_range'];
      }
      final expected = '$hour:${minute.toString().padLeft(2, '0')} Uhr';
      return _choiceKey(answer, preserveCase: false) ==
              _choiceKey(expected, preserveCase: false)
          ? const [] : const ['clock_answer_wrong'];
    }
    final money = RegExp(r'^Was kostet mehr: (\d+) € oder (\d+) €\?$')
        .firstMatch(prompt);
    if (money != null) {
      final left = int.parse(money[1]!);
      final right = int.parse(money[2]!);
      final expected = left == right ? 'gleich viel' : '${left > right ? left : right} €';
      return answer == expected ? const [] : const ['money_comparison_wrong'];
    }
    final change = RegExp(r'^Wie viele (\d+)-€-(Münzen|Scheine) ergeben (\d+) €\?$')
        .firstMatch(prompt);
    if (change != null) {
      final denomination = int.parse(change[1]!);
      final total = int.parse(change[3]!);
      if (denomination == 0 || total % denomination != 0) {
        return const ['money_change_not_divisible'];
      }
      final count = RegExp(r'^(\d+) (?:Münze[n]?|Schein[e]?)$').firstMatch(answer);
      return count != null && int.parse(count[1]!) == total ~/ denomination
          ? const [] : const ['money_change_wrong_count'];
    }
    final line = RegExp(r'^Welche Zahl fehlt\? (\d+), (\d+), _, (\d+)$')
        .firstMatch(prompt);
    if (line != null) {
      final first = int.parse(line[1]!);
      final second = int.parse(line[2]!);
      final last = int.parse(line[3]!);
      if (last != second + 2 * (second - first)) {
        return const ['number_line_rule_unproved'];
      }
    }
    return const [];
  }

  List<String> _logicProblems(LumoTask task, List<String> choices) {
    if (task.subject != 'Logik') return const [];
    if (task.unit == 'Muster' || task.visual == 'pattern') {
      final pattern = CheckedShapePattern.fromPrompt(task.prompt);
      if (pattern == null) return const ['shape_pattern_rule_unproved'];
      return [
        if (task.answer.trim() != pattern.next) 'shape_pattern_wrong_answer',
        if (choices.where((choice) => choice == pattern.next).length != 1)
          'shape_pattern_not_exactly_one_choice',
      ];
    }
    if (task.unit == 'Zahlenmuster') {
      final pattern = CheckedNumberPattern.fromPrompt(task.prompt);
      if (pattern == null) return const ['number_pattern_rule_unproved'];
      return [
        if (int.tryParse(task.answer.trim()) != pattern.next)
          'number_pattern_wrong_answer',
        if (choices.where((choice) => int.tryParse(choice) == pattern.next)
                .length !=
            1)
          'number_pattern_not_exactly_one_choice',
      ];
    }
    if (task.unit == 'Regeln kombinieren') {
      final rule = RegExp(
        r'größer als (\d+), kleiner als (\d+) und gerade\?',
      ).firstMatch(task.prompt);
      if (rule == null) return const ['combined_rule_unproved'];
      final lower = int.parse(rule[1]!);
      final upper = int.parse(rule[2]!);
      final matching = choices.where((choice) {
        final value = int.tryParse(choice);
        return value != null && value > lower && value < upper && value.isEven;
      }).toList(growable: false);
      return [
        if (matching.length != 1) 'combined_rule_not_exactly_one_choice',
        if (!matching.contains(task.answer.trim())) 'combined_rule_wrong_answer',
      ];
    }
    return const [];
  }

  List<String> _numericProblems(String prompt, String answer, List<String> choices) {
    if (RegExp(r'[:÷]\s*0\s*=').hasMatch(prompt)) {
      return const <String>['division_by_zero'];
    }
    if ([prompt, answer, ...choices].any(
        (value) => RegExp(r'/0(?:\D|$)').hasMatch(value))) {
      return const <String>['zero_fraction_denominator'];
    }
    final fractionExpansion = RegExp(
        r'^Erweitere den Bruch (\d+)/(\d+) mit (\d+)\. Wie heißt der neue Bruch\?$')
        .firstMatch(prompt);
    if (fractionExpansion != null) {
      final numerator = int.parse(fractionExpansion[1]!);
      final denominator = int.parse(fractionExpansion[2]!);
      final factor = int.parse(fractionExpansion[3]!);
      if (denominator <= 0 || factor <= 0) {
        return const ['fraction_expansion_invalid_factor'];
      }
      // Here the requested *representation*, not just an equal value, is the
      // learning goal: expanding 1/2 by 3 requires 3/6, not the unchanged 1/2.
      return answer.replaceAll(' ', '') ==
              '${numerator * factor}/${denominator * factor}'
          ? const []
          : const ['fraction_expansion_wrong_representation'];
    }
    final expected = _expectedValue(prompt);
    if (expected == null) return const <String>[];
    final actual = _MathValue.parse(answer);
    if (actual == null) return const <String>['numeric_answer_not_parseable'];
    return actual.key == expected.key
        ? const <String>[]
        : const <String>['numeric_answer_wrong_result'];
  }

  List<String> _soundProblems(String prompt, String answer, List<String> choices) {
    final issues = <String>[];
    final wordEnding = RegExp(r'Welches\s+Wort\s+endet\s+mit\s+([A-Za-zÄÖÜäöüß]+)\?', caseSensitive: false).firstMatch(prompt);
    if (wordEnding != null) {
      final sound = _word(wordEnding.group(1) ?? '');
      final matching = choices.where((c) => _word(PrimarySchoolWordData.finalSoundFor(c) ?? '') == sound).length;
      if (_word(PrimarySchoolWordData.finalSoundFor(answer) ?? '') != sound) issues.add('answer_wrong_ending');
      if (matching != 1) issues.add('ending_not_exactly_one_choice');
    }

    final wordBeginning = RegExp(r'Welches\s+Wort\s+beginnt\s+mit\s+([A-Za-zÄÖÜäöüß]+)\?', caseSensitive: false).firstMatch(prompt);
    if (wordBeginning != null) {
      final sound = _word(wordBeginning.group(1) ?? '');
      final matching = choices.where((c) => _word(PrimarySchoolWordData.initialSoundFor(c) ?? '') == sound).length;
      if (_word(PrimarySchoolWordData.initialSoundFor(answer) ?? '') != sound) issues.add('answer_wrong_beginning');
      if (matching != 1) issues.add('beginning_not_exactly_one_choice');
    }

    final letterStart = RegExp(r'Mit\s+welchem\s+Laut\s+beginnt\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
    if (letterStart != null) {
      final word = _word(letterStart.group(1) ?? '');
      final expected = _word(PrimarySchoolWordData.initialSoundFor(word) ?? '');
      if (expected.isEmpty) return issues;
      if (_word(answer) != expected) issues.add('answer_wrong_initial_sound');
      if (choices.where((c) => _word(c) == expected).length != 1) issues.add('initial_sound_not_exactly_one_choice');
    }

    final letterEnd = RegExp(r'Mit\s+welchem\s+Laut\s+endet\s+(.+?)\?', caseSensitive: false).firstMatch(prompt);
    if (letterEnd != null) {
      final word = _word(letterEnd.group(1) ?? '');
      final expected = _word(PrimarySchoolWordData.finalSoundFor(word) ?? '');
      if (expected.isEmpty) return issues;
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
    final partners = PrimarySchoolWordData.rhymePartnersFor(base).map(_choice).toSet();
    if (partners.isEmpty) return const <String>[];
    final issues = <String>[];
    if (!partners.contains(_choice(answer))) issues.add('rhyme_answer_not_known_partner');
    if (choices.where((c) => partners.contains(_choice(c))).length != 1) {
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
    if (lower.contains('welches wort ist ein namenswort') || lower.contains('welches wort ist ein namenwort') || lower.contains('welches wort ist ein nomen') || lower.contains('welches wort ist ein hauptwort')) {
      if (!_isKnownNoun(answer)) issues.add('nomen_answer_not_known_noun');
      if (choices.where(_isKnownNoun).length != 1) issues.add('nomen_not_exactly_one_choice');
      if (!choices.where((c) => _choice(c) != a).any((c) => _isKnownVerb(c) || _isKnownAdjective(c))) {
        issues.add('nomen_choices_missing_wordclass_distractor');
      }
    }
    if (lower.contains('welches wort ist ein tunwort') || lower.contains('welches wort ist ein verb')) {
      if (!_isKnownVerb(answer)) issues.add('verb_answer_not_known_verb');
      if (choices.where(_isKnownVerb).length != 1) issues.add('verb_not_exactly_one_choice');
      if (choices.every(_isKnownVerb)) issues.add('verb_choices_not_contrasting_wordclasses');
    }
    if (lower.contains('welches wort ist ein wiewort') || lower.contains('welches wort beschreibt, wie') || lower.contains('welches wort ist eine eigenschaft')) {
      if (!_isKnownAdjective(answer)) issues.add('adjective_answer_not_known_adjective');
      if (choices.where(_isKnownAdjective).length != 1) issues.add('adjective_not_exactly_one_choice');
      if (choices.every(_isKnownAdjective)) issues.add('adjective_choices_not_contrasting_wordclasses');
    }

    return issues;
  }

  _MathValue? _expectedValue(String prompt) {
    const number = r'(-?\d+(?:[.,]\d+)?(?:/\d+)?)';
    final basic = RegExp(
        '^(?:(?:Schriftlich|Blitzlicht):\\s*)?$number\\s*([+\\-−×·*÷:]|mal)\\s*$number\\s*=\\s*\\?\\s*\$')
        .firstMatch(prompt.trim());
    if (basic != null) {
      final left = _MathValue.parse(basic.group(1)!);
      final right = _MathValue.parse(basic.group(3)!);
      if (left == null || right == null) return null;
      return switch (basic.group(2)) {
        '+' => left.add(right),
        '-' || '−' => left.add(right.negated),
        '×' || '·' || '*' || 'mal' => left.multiply(right),
        ':' || '÷' => right.numerator == 0 ? null : left.divide(right),
        _ => null,
      };
    }
    final before = RegExp(r'direkt\s+vor\s+(\d+)', caseSensitive: false).firstMatch(prompt);
    if (before != null) return _MathValue(int.parse(before.group(1)!) - 1, 1);
    final after = RegExp(r'direkt\s+nach\s+(\d+)', caseSensitive: false).firstMatch(prompt);
    if (after != null) return _MathValue(int.parse(after.group(1)!) + 1, 1);

    final half = RegExp(r'^Was ist die Hälfte von (\d+)\?$').firstMatch(prompt);
    if (half != null) return _MathValue(int.parse(half[1]!), 2);
    final twice = RegExp(r'^Was ist das Doppelte von (\d+)\?$').firstMatch(prompt);
    if (twice != null) return _MathValue(int.parse(twice[1]!) * 2, 1);
    final places = RegExp(r'^Wie viele (Zehner|Einer) hat (\d{2})\?$').firstMatch(prompt);
    if (places != null) {
      final value = int.parse(places[2]!);
      return _MathValue(places[1] == 'Zehner' ? value ~/ 10 : value % 10, 1);
    }
    final rectangle = RegExp(
        r'^Ein Rechteck ist (\d+) cm lang und (\d+) cm breit\. Wie groß ist der (Umfang|Flächeninhalt)\?$')
        .firstMatch(prompt);
    if (rectangle != null) {
      final length = int.parse(rectangle[1]!);
      final width = int.parse(rectangle[2]!);
      return _MathValue(rectangle[3] == 'Umfang'
          ? 2 * (length + width) : length * width, 1);
    }
    final average = RegExp(
        r'^Drei Kinder sammeln Sterne: (\d+), (\d+) und (\d+)\. Wie viele Sterne im Mittelwert\?$')
        .firstMatch(prompt);
    if (average != null) {
      return _MathValue(int.parse(average[1]!) + int.parse(average[2]!) +
          int.parse(average[3]!), 3);
    }
    final chart = RegExp(
        r'^Diagramm: Montag (\d+) Kinder, Dienstag (\d+) Kinder\. Wie viele zusammen\?$')
        .firstMatch(prompt);
    if (chart != null) {
      return _MathValue(int.parse(chart[1]!) + int.parse(chart[2]!), 1);
    }
    final times = RegExp(r'^Wie oft (\d+) ist (\d+)\?$').firstMatch(prompt);
    if (times != null && int.parse(times[1]!) > 0) {
      return _MathValue(int.parse(times[2]!), int.parse(times[1]!));
    }
    final line = RegExp(r'^Welche Zahl fehlt\? (\d+), (\d+), _, (\d+)$')
        .firstMatch(prompt);
    if (line != null) {
      final first = int.parse(line[1]!);
      final second = int.parse(line[2]!);
      final last = int.parse(line[3]!);
      final step = second - first;
      if (last == second + 2 * step) return _MathValue(second + step, 1);
    }
    const conversions = [
      (r'^Wie viele Zentimeter sind (\d+) Meter(?: und (\d+) Zentimeter)?\?$', 100),
      (r'^Wie viele Gramm sind (\d+) kg(?: und (\d+) g)?\?$', 1000),
      (r'^Wie viele Milliliter sind (\d+) Liter(?: und (\d+) Milliliter)?\?$', 1000),
      (r'^Wie viele Minuten sind (\d+) Stunde[n]?(?: und (\d+) Minuten)?\?$', 60),
    ];
    for (final conversion in conversions) {
      final match = RegExp(conversion.$1).firstMatch(prompt);
      if (match != null) {
        return _MathValue(int.parse(match[1]!) * conversion.$2 +
            int.parse(match[2] ?? '0'), 1);
      }
    }
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

  String _stripPunctuation(String value) => value.trim().replaceAll(RegExp(r'[„“".:;!,]+$'), '').trim();

  String _choiceKey(String value, {required bool preserveCase}) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final number = _MathValue.parse(normalized);
    if (number != null) return 'number:${number.key}';
    final clock = RegExp(r'^(\d{1,2})(?::(\d{2}))? Uhr$', caseSensitive: false).firstMatch(normalized);
    if (clock != null) {
      return 'clock:${int.parse(clock[1]!)}:${int.parse(clock[2] ?? '0')}';
    }
    return preserveCase ? normalized : normalized.toLowerCase();
  }

  bool _hasDuplicateChoices(List<String> choices, {required bool preserveCase}) {
    final seen = <String>{};
    for (final choice in choices) {
      if (!seen.add(_choiceKey(choice, preserveCase: preserveCase))) return true;
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


/// Exact arithmetic for integer, decimal and fraction answer cards.
class _MathValue {
  const _MathValue(this.numerator, this.denominator);
  final int numerator;
  final int denominator;

  String get key {
    final divisor = numerator.gcd(denominator);
    final sign = denominator < 0 ? -1 : 1;
    return '${sign * numerator ~/ divisor}/${sign * denominator ~/ divisor}';
  }

  static _MathValue? parse(String text) {
    final value = text.trim().replaceAll(',', '.');
    final fraction = RegExp(r'^(-?\d+)/(\d+)$').firstMatch(value);
    if (fraction != null) {
      final denominator = int.parse(fraction.group(2)!);
      if (denominator == 0) return null;
      return _MathValue(int.parse(fraction.group(1)!), denominator);
    }
    if (!RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(value)) return null;
    final parts = value.split('.');
    if (parts.length == 1) return _MathValue(int.parse(value), 1);
    final denominator = int.parse('1${'0' * parts[1].length}');
    return _MathValue(int.parse(parts.join()), denominator);
  }

  _MathValue get negated => _MathValue(-numerator, denominator);
  _MathValue add(_MathValue other) => _MathValue(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator);
  _MathValue multiply(_MathValue other) => _MathValue(
      numerator * other.numerator, denominator * other.denominator);
  _MathValue divide(_MathValue other) => _MathValue(
      numerator * other.denominator, denominator * other.numerator);
}
