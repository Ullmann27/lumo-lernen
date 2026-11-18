import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/shape_question_data.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Mittlere Befunde der Fachprüfung Mathematik (17.11.2026) an einzelnen
/// Einheiten. Jeder Test nennt den Befund, den er verhindert.
void main() {
  MathTaskTemplate byId(String id) =>
      MathTaskTemplates.templates.singleWhere((item) => item.id == id);
  List<int> numbers(String text) => RegExp(r'\d+')
      .allMatches(text)
      .map((match) => int.parse(match.group(0)!))
      .toList();
  const guard = TaskQualityGuard();
  LumoTask asLumoTask(MathConcreteTask task, int grade) => LumoTask(
        id: 'content-fix',
        grade: grade,
        subject: 'Mathematik',
        unit: task.unit,
        prompt: task.prompt,
        choices: task.choices,
        answer: task.answer,
        explanation: task.explanation,
        visual: task.visual,
      );

  test('M10: Mittelwert ist nicht mehr „zweite Zahl minus 1“', () {
    var secondMinusOne = 0, ascending = 0, meanIsValue = 0;
    const count = 300;
    for (var i = 0; i < count; i++) {
      final task = byId('g4_average').concretize(i * 7919 + 13);
      final values = numbers(task.prompt).take(3).toList();
      final sum = values.reduce((a, b) => a + b);
      expect(sum % 3, 0, reason: task.prompt);
      expect(task.answer, '${sum ~/ 3}', reason: task.prompt);
      expect(values.every((value) => value >= 1), isTrue, reason: task.prompt);
      expect(task.prompt, startsWith('Knobelaufgabe: '));
      expect(task.prompt, contains('gerecht'));
      expect(task.prompt, isNot(contains('im Mittelwert')));
      expect(task.explanation, contains('$sum : 3 = ${sum ~/ 3}'));
      expect(guard.problems(asLumoTask(task, 4)), isEmpty, reason: task.prompt);
      if (values[1] - 1 == sum ~/ 3) secondMinusOne++;
      if (values[0] <= values[1] && values[1] <= values[2]) ascending++;
      if (values.contains(sum ~/ 3)) meanIsValue++;
    }
    // Früher 300 von 300.
    expect(secondMinusOne, lessThan(count * .25));
    expect(ascending, lessThan(count * .4));
    expect(meanIsValue, lessThan(count * .4));
  });

  test('M16: Geld vergleicht zwei Dinge mit Preis, immer drei Karten', () {
    final answers = <String>{};
    for (var i = 0; i < 400; i++) {
      final task = byId('g1_money_more').concretize(i * 7919 + 13);
      final match = RegExp(
              r'^(Der|Die|Das) (\S+) kostet (\d+) €, (der|die|das) (\S+) kostet (\d+) €\. Was kostet mehr\?$')
          .firstMatch(task.prompt);
      expect(match, isNotNull, reason: task.prompt);
      final first = '${match![1]!.toLowerCase()} ${match[2]}';
      final second = '${match[4]} ${match[5]}';
      expect(first, isNot(second), reason: task.prompt);
      final left = int.parse(match[3]!), right = int.parse(match[6]!);
      // Früher blieben bei gleichen Preisen nur zwei Karten übrig.
      expect(task.choices, [first, second, 'gleich viel']);
      expect(task.answer,
          left == right ? 'gleich viel' : left > right ? first : second);
      expect(guard.problems(asLumoTask(task, 1)), isEmpty, reason: task.prompt);
      answers.add(left == right ? '=' : left > right ? '>' : '<');
    }
    expect(answers, {'=', '>', '<'});
  });

  test('M14/L16: Zahlenstrahl mit wechselnder Lücke und Schritten 1, 2, 5', () {
    final prompts = <String>{};
    final gaps = <int>{};
    final steps = <int>{};
    for (var i = 0; i < 600; i++) {
      final task = byId('g1_number_line').concretize(i * 7919 + 13);
      prompts.add(task.prompt);
      final items = task.prompt.substring('Welche Zahl fehlt? '.length).split(', ');
      expect(items, hasLength(4), reason: task.prompt);
      final gap = items.indexOf('_');
      gaps.add(gap);
      final full = [
        for (var index = 0; index < 4; index++)
          index == gap ? int.parse(task.answer) : int.parse(items[index]),
      ];
      final step = full[1] - full[0];
      steps.add(step);
      expect(full[2] - full[1], step, reason: task.prompt);
      expect(full[3] - full[2], step, reason: task.prompt);
      expect(full.last, lessThanOrEqualTo(20), reason: task.prompt);
      expect(task.explanation, contains('= ${task.answer}.'));
      expect(guard.problems(asLumoTask(task, 1)), isEmpty, reason: task.prompt);
    }
    expect(gaps, {0, 1, 2, 3});
    expect(steps, {1, 2, 5});
    // Früher 18 verschiedene Aufgaben.
    expect(prompts.length, greaterThan(100));
  });

  test('Qualitätsprüfung erkennt eine Zahlenreihe ohne festen Schritt', () {
    LumoTask line(String prompt, String answer) => LumoTask(
          id: 'line',
          grade: 1,
          subject: 'Mathematik',
          unit: 'Zahlenstrahl',
          prompt: prompt,
          answer: answer,
          choices: [answer, '1', '19', '20'],
          explanation: 'Probe.',
        );
    expect(guard.problems(line('Welche Zahl fehlt? 5, _, 15, 20', '10')), isEmpty);
    expect(guard.problems(line('Welche Zahl fehlt? _, 6, 8, 10', '4')), isEmpty);
    expect(guard.problems(line('Welche Zahl fehlt? 5, _, 15, 20', '11')),
        contains('numeric_answer_wrong_result'));
    expect(guard.problems(line('Welche Zahl fehlt? 5, _, 14, 20', '10')),
        contains('number_line_rule_unproved'));
  });

  test('M14/M13: Symmetrie Klasse 1 fragt nach dem Falten, ja und nein ausgewogen',
      () {
    expect(symmetryFoldExamples.length, greaterThanOrEqualTo(30));
    final yes = symmetryFoldExamples.where((entry) => entry.$2).length;
    expect(yes * 2, symmetryFoldExamples.length);
    final prompts = <String>{};
    var answeredYes = 0;
    for (var i = 0; i < 600; i++) {
      final task = byId('g1_symmetry').concretize(i * 7919 + 13);
      prompts.add(task.prompt);
      expect(task.choices, ['ja', 'nein']);
      if (task.answer == 'ja') answeredYes++;
      for (final word in ['gleichseitig', 'Spiegelachse', 'gleichschenklig']) {
        expect(task.prompt, isNot(contains(word)), reason: task.prompt);
      }
      expect(task.prompt.split(' ').length, lessThanOrEqualTo(14),
          reason: task.prompt);
    }
    // Früher 4 Aufgaben, drei Viertel davon „ja“.
    expect(prompts.length, symmetryFoldExamples.length);
    expect(answeredYes / 600, inInclusiveRange(.4, .6));
  });

  test('M14: Zeit (Klasse 1) und Minuten-Umrechnung haben viele Aufgaben', () {
    final facts = <String>{};
    for (var i = 0; i < 3000; i++) {
      final task = byId('g1_day_hours').concretize(i * 131 + 7);
      facts.add(task.prompt);
      expect(task.choices, contains(task.answer));
      expect(task.choices.toSet(), hasLength(3), reason: task.prompt);
    }
    expect(facts.length, greaterThanOrEqualTo(24));
    final minutes = <String>{};
    for (var i = 0; i < 1500; i++) {
      final task = byId('g4_time_minutes').concretize(i * 7919 + 13);
      minutes.add(task.prompt);
      final parts = numbers(task.prompt);
      expect(task.answer, '${parts[0] * 60 + (parts.length > 1 ? parts[1] : 0)}');
    }
    // Früher 20 verschiedene Aufgaben.
    expect(minutes.length, greaterThanOrEqualTo(60));
  });

  test('M13: Formenfragen der 1. Klasse sind kurz und ohne Fachwörter', () {
    expect(shapeQuestions, hasLength(20));
    for (final question in shapeQuestions) {
      for (final sentence in question.$1.split(RegExp(r'(?<=[.?])\s'))) {
        expect(sentence.split(' ').length, lessThanOrEqualTo(12),
            reason: sentence);
      }
      for (final word in [
        'rechte Winkel', 'rechten Winkel', 'Mittelpunkt', 'Geraden',
        'geschlossene', 'gleichseitig', 'Fläche',
      ]) {
        expect(question.$1, isNot(contains(word)), reason: question.$1);
        expect(question.$4, isNot(contains(word)), reason: question.$4);
      }
      expect(question.$3, contains(question.$2));
      expect(question.$3.toSet(), hasLength(3));
      // Kreis und Oval haben beide keine Ecke: nie gemeinsam bei „keine Ecke“.
      if (question.$1.contains('keine Ecke')) {
        expect(question.$3, isNot(contains('Oval')));
      }
    }
  });

  test('M12: Längen in Klasse 2 bleiben im Zahlenraum 100', () {
    final prompts = <String>{};
    for (var i = 0; i < 400; i++) {
      final task = byId('g2_length').concretize(i * 7919 + 13);
      prompts.add(task.prompt);
      expect(int.parse(task.answer), inInclusiveRange(1, 100),
          reason: task.prompt);
      for (final number in numbers(task.prompt)) {
        expect(number, lessThanOrEqualTo(100), reason: task.prompt);
      }
      expect(guard.problems(asLumoTask(task, 2)), isEmpty, reason: task.prompt);
      // Die Rechnung in der Erklärung stimmt.
      final step = RegExp(r'(\d+) ([+−]) (\d+) = (\d+)').firstMatch(task.explanation);
      if (step != null) {
        final x = int.parse(step[1]!), y = int.parse(step[3]!);
        expect(step[2] == '+' ? x + y : x - y, int.parse(step[4]!),
            reason: task.explanation);
      }
    }
    expect(prompts.length, greaterThan(40));
    // Ab Klasse 3 bleibt die Umrechnung mehrerer Meter erhalten.
    final older = MathTaskTemplates.generate(grade: 3, unit: 'Längen', seed: 5);
    expect(older.prompt, startsWith('Wie viele Zentimeter sind '));
    final younger = <String>{
      for (var seed = 0; seed < 60; seed++)
        MathTaskTemplates.generate(grade: 2, unit: 'Längen', seed: seed).answer,
    };
    expect(younger.every((answer) => int.parse(answer) <= 100), isTrue);
  });

  test('M8: Brüche Vorbereitung übt Hälfte, Viertel und Achtel', () {
    final kinds = <String, int>{};
    for (var i = 0; i < 400; i++) {
      final task = byId('g3_fraction_half').concretize(i * 7919 + 13);
      final match = RegExp(r'^Was ist (die Hälfte|ein Viertel|ein Achtel) von (\d+)\?$')
          .firstMatch(task.prompt);
      expect(match, isNotNull, reason: task.prompt);
      final parts = switch (match![1]) { 'die Hälfte' => 2, 'ein Viertel' => 4, _ => 8 };
      final whole = int.parse(match[2]!);
      expect(whole % parts, 0, reason: task.prompt);
      expect(task.answer, '${whole ~/ parts}');
      expect(task.explanation, contains('$whole : $parts = ${task.answer}.'));
      expect(guard.problems(asLumoTask(task, 3)), isEmpty, reason: task.prompt);
      kinds[match[1]!] = (kinds[match[1]!] ?? 0) + 1;
    }
    // Früher 300 von 300 „Was ist die Hälfte von X?“.
    expect(kinds.keys.toSet(), {'die Hälfte', 'ein Viertel', 'ein Achtel'});
    expect(kinds.values.every((count) => count >= 40), isTrue, reason: '$kinds');
  });

  test('M6: Diagramme lesen fragt nach meisten, wenigsten, Unterschied, Summe',
      () {
    final questions = <String>{};
    for (var i = 0; i < 400; i++) {
      final task = byId('g4_chart').concretize(i * 7919 + 13);
      final values = <String, int>{
        for (final match in RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag) (\d+)')
            .allMatches(task.prompt.substring(0, task.prompt.indexOf('.'))))
          match[1]!: int.parse(match[2]!),
      };
      expect(values, hasLength(4), reason: task.prompt);
      expect(values.values.toSet(), hasLength(4), reason: task.prompt);
      final sorted = values.values.toList()..sort();
      if (task.prompt.contains('meisten')) {
        questions.add('meisten');
        expect(values[task.answer], sorted.last, reason: task.prompt);
        expect(task.choices, values.keys.toList());
      } else if (task.prompt.contains('wenigsten')) {
        questions.add('wenigsten');
        expect(values[task.answer], sorted.first, reason: task.prompt);
      } else if (task.prompt.contains('mehr da als')) {
        questions.add('Unterschied');
        final days = RegExp(r'am (\S+) mehr da als am (\S+)\?').firstMatch(task.prompt)!;
        expect(task.answer, '${values[days[1]]! - values[days[2]]!}');
        expect(int.parse(task.answer), greaterThan(0), reason: task.prompt);
      } else {
        questions.add('Summe');
        expect(task.prompt, contains('zusammen?'));
        expect(task.answer, '${sorted.reduce((a, b) => a + b)}');
      }
      expect(guard.problems(asLumoTask(task, 4)), isEmpty, reason: task.prompt);
    }
    expect(questions, {'meisten', 'wenigsten', 'Unterschied', 'Summe'});
  });

  test('M7: Zahlenvergleich mit genauem Hinschauen, „=“ kommt vor, Lücke als ⬜',
      () {
    for (final id in ['g4_compare', 'g4_compare_1mio']) {
      final answers = <String, int>{};
      var sameLengthSameLead = 0;
      const count = 400;
      for (var i = 0; i < count; i++) {
        final task = byId(id).concretize(i * 7919 + 13);
        final match = comparePromptPattern.firstMatch(task.prompt);
        expect(match, isNotNull, reason: task.prompt);
        // Das Fragezeichen der Frage steht nicht mehr neben einem zweiten.
        expect('?'.allMatches(task.prompt), hasLength(1), reason: task.prompt);
        expect(task.prompt, contains('⬜'));
        final left = parseGroupedNumber(match![1]!)!;
        final right = parseGroupedNumber(match[2]!)!;
        expect(task.answer, left > right ? '>' : left < right ? '<' : '=');
        expect(task.choices, ['<', '>', '=']);
        answers[task.answer] = (answers[task.answer] ?? 0) + 1;
        if ('$left'.length == '$right'.length && '$left'[0] == '$right'[0]) {
          sameLengthSameLead++;
        }
        if (left >= 10000) {
          expect(match[1], groupedNumber(left));
          expect(match[1], contains('\u00A0'), reason: task.prompt);
        }
        expect(guard.problems(asLumoTask(task, 4)), isEmpty, reason: task.prompt);
      }
      // Früher war „=“ in 600 Aufgaben nie richtig.
      expect(answers['='], greaterThan(count * .04), reason: '$id $answers');
      expect(answers['<'], greaterThan(count * .25), reason: '$id $answers');
      expect(answers['>'], greaterThan(count * .25), reason: '$id $answers');
      // Früher hatten bei der Million nur 29 von 300 Paaren gleiche
      // Stellenzahl und gleiche erste Ziffer.
      expect(sameLengthSameLead, greaterThan(count * .5), reason: id);
    }
    expect(groupedNumber(925407), '925\u00A0407');
    expect(groupedNumber(9999), '9999');
    expect(groupedNumber(1000000), '1\u00A0000\u00A0000');
    expect(parseGroupedNumber('27\u00A0441'), 27441);
  });

  test('M33: Einmaleins Klasse 2 beginnt leicht, Klasse 3 kennt 0 und 1', () {
    final rows = <int>{};
    for (var i = 0; i < 300; i++) {
      final task = byId('g2_tables').concretize(i * 7919 + 13);
      final factors = numbers(task.prompt);
      rows.add(factors[0]);
      expect(task.answer, '${factors[0] * factors[1]}');
      // Eine Deutung überall: a × b heißt „a-mal die b“.
      expect(task.explanation,
          startsWith('${factors[0]} × ${factors[1]} heißt ${factors[0]}-mal die ${factors[1]}.'));
      expect(task.explanation, endsWith('= ${task.answer}.'));
    }
    expect(rows, {2, 3, 4, 5, 10});
    final thirdGrade = <String>{};
    for (var i = 0; i < 2000; i++) {
      thirdGrade.add(byId('g3_tables').concretize(i * 131 + 7).prompt);
    }
    expect(thirdGrade, contains('0 × 7 = ?'));
    expect(thirdGrade, contains('1 × 9 = ?'));
    expect(thirdGrade, contains('9 × 7 = ?'));
    expect(thirdGrade.length, 121);
  });
}
