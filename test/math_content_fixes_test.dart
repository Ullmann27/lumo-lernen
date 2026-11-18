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
}
