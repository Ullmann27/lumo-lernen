import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
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
}
