import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/checked_task_patterns.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Befunde M23, M24 und M25 der Fachprüfung (Logik): Beim Muster war die
/// Lösung immer die erste Form, beim Schlussfolgern standen die Namen schon
/// in der richtigen Reihenfolge da, das Zahlenmuster hatte oft den Schritt 1
/// und ging nie zurück.
void main() {
  const guard = TaskQualityGuard();
  List<LumoTask> generate(String unit, int grade, {int count = 300}) => [
        for (var seed = 0; seed < 6; seed++)
          for (var i = 0; i < count ~/ 6; i++)
            ExerciseFactory(seed: seed * 1000 + i)
                .nextExact(grade: grade, subject: 'Logik', unit: unit),
      ];

  test('M23: Muster – Lösung ist nicht immer die erste Form, mehrere Arten', () {
    for (var grade = 1; grade <= 4; grade++) {
      var first = 0;
      final periods = <int>{};
      final kinds = <String>{};
      final tasks = generate('Muster', grade);
      for (final task in tasks) {
        expect(guard.problems(task), isEmpty, reason: task.prompt);
        final pattern = CheckedShapePattern.fromPrompt(task.prompt)!;
        expect(task.answer, pattern.next, reason: task.prompt);
        if (task.answer == pattern.sequence.first) first++;
        periods.add(pattern.period);
        // Art des Musters: A-B, A-A-B, A-B-B, A-B-C, A-B-C-D.
        final names = <String, String>{};
        kinds.add(pattern.group
            .map((shape) => names.putIfAbsent(
                shape, () => String.fromCharCode(65 + names.length)))
            .join());
        expect(task.choices, hasLength(4));
      }
      // Früher 300 von 300.
      expect(first, lessThan(tasks.length * .75), reason: 'Klasse $grade');
      expect(kinds, grade == 1
          ? {'AB'}
          : grade == 2
              ? {'AB', 'AAB', 'ABC'}
              : {'AB', 'AAB', 'ABC', 'ABB', 'ABCD'});
      expect(periods.length, grade == 1 ? 1 : greaterThan(1));
    }
  });

  test('M25: Zahlenmuster ohne Schritt 1, auch rückwärts', () {
    for (final grade in [2, 3, 4]) {
      var backwards = 0;
      final tasks = generate('Zahlenmuster', grade);
      for (final task in tasks) {
        expect(guard.problems(task), isEmpty, reason: task.prompt);
        final pattern = CheckedNumberPattern.fromPrompt(task.prompt)!;
        expect(pattern.step.abs(), greaterThanOrEqualTo(2), reason: task.prompt);
        expect(task.answer, '${pattern.next}');
        expect(pattern.next, greaterThanOrEqualTo(0), reason: task.prompt);
        if (pattern.step < 0) {
          backwards++;
          expect(task.prompt, contains('Schritte zurück'));
          expect(task.explanation, contains(' − '));
        } else {
          expect(task.prompt, contains('Schritte weiter'));
        }
        for (final choice in task.choices.where((c) => c != task.answer)) {
          expect(pattern.sequence, isNot(contains(int.parse(choice))),
              reason: '${task.prompt} ${task.choices}');
        }
      }
      expect(backwards / tasks.length, inInclusiveRange(.15, .5));
    }
  });

  test('Zahlenmuster: „weiter“ und „zurück“ müssen zur Reihe passen', () {
    const head = 'Gehe jedes Mal gleich viele Schritte';
    expect(CheckedNumberPattern.fromPrompt('$head weiter: 2 – 4 – 6 – 8 – ? Welche Zahl folgt?')?.next, 10);
    expect(CheckedNumberPattern.fromPrompt('$head zurück: 20 – 17 – 14 – 11 – ? Welche Zahl folgt?')?.next, 8);
    expect(CheckedNumberPattern.fromPrompt('$head weiter: 20 – 17 – 14 – 11 – ? Welche Zahl folgt?'), isNull);
    expect(CheckedNumberPattern.fromPrompt('$head zurück: 2 – 4 – 6 – 8 – ? Welche Zahl folgt?'), isNull);
  });

  test('M24: Schlussfolgern – Angaben gemischt, Lösung folgt nur aus dem Schluss',
      () {
    for (final grade in [3, 4]) {
      final wordings = <String>{};
      var firstMentioned = 0;
      final tasks = generate('Schlussfolgern', grade);
      for (final task in tasks) {
        expect(task.prompt, startsWith('Drei Freunde stehen nebeneinander. '));
        expect(task.prompt, isNot(contains('Figuren')));
        final clues = RegExp(r'(\S+) steht (links|rechts) von (\S+)\.')
            .allMatches(task.prompt)
            .toList();
        expect(clues, hasLength(2), reason: task.prompt);
        // Reihenfolge aus den zwei Angaben herleiten.
        final before = <String, String>{}; // links → rechts
        for (final clue in clues) {
          final left = clue[2] == 'links' ? clue[1]! : clue[3]!;
          final right = clue[2] == 'links' ? clue[3]! : clue[1]!;
          before[left] = right;
        }
        final start = before.keys.singleWhere((name) => !before.values.contains(name));
        final order = <String>[start, before[start]!, before[before[start]!]!];
        final asked = RegExp(r'Wer steht (ganz links|in der Mitte|ganz rechts)\?$')
            .firstMatch(task.prompt)![1]!;
        final expected = order[const ['ganz links', 'in der Mitte', 'ganz rechts'].indexOf(asked)];
        expect(task.answer, expected, reason: task.prompt);
        expect(task.choices.toSet(), order.toSet());
        wordings.add(clues.map((clue) => clue[2]).join('/'));
        if (task.prompt.indexOf(task.answer) ==
            task.prompt.indexOf(RegExp(r'(?<=nebeneinander\. )\S+')) ) {
          firstMentioned++;
        }
      }
      expect(wordings, {'links/links', 'links/rechts', 'rechts/links', 'rechts/rechts'});
      expect(firstMentioned, lessThan(tasks.length * .6));
    }
  });
}
