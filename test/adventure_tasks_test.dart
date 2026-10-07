import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/adventure/lumo_adventure_tasks.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

List<int> _numbers(String text) => RegExp(r'\d+')
    .allMatches(text.replaceAll(RegExp(r'\d+:\d+'), ''))
    .map((m) => int.parse(m.group(0)!))
    .toList();

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

void main() {
  const guard = TaskQualityGuard();

  test('jede Abenteuer-Aufgabe ist eindeutig lösbar und klassengerecht', () {
    for (final subject in LumoAdventureTasks.units.keys) {
      for (final unit in LumoAdventureTasks.units[subject]!.keys) {
        for (var grade = 1; grade <= 4; grade++) {
          if (LumoAdventureTasks.units[subject]![unit]! > grade) continue;
          final generator =
              LumoAdventureTasks(Random(grade * 97 + unit.length), childName: 'Mia');
          for (var i = 0; i < 400; i++) {
            final t = generator.generate(subject: subject, unit: unit, grade: grade);
            final where = 'K$grade $unit: ${t.prompt} -> ${t.answer} ${t.choices}';
            expect(t.subject, subject, reason: where);
            expect(t.unit, unit, reason: where);
            expect(t.choices, contains(t.answer), reason: where);
            expect(t.choices.length, greaterThanOrEqualTo(2), reason: where);
            final keys = t.choices.map((c) => c.trim().toLowerCase()).toSet();
            expect(keys.length, t.choices.length, reason: 'doppelt: $where');
            expect(t.explanation.trim(), isNotEmpty, reason: where);
            expect(t.prompt, isNot(contains('Aepfel')), reason: where);
            if (subject == 'Mathematik' && int.tryParse(t.answer) != null) {
              final value = int.parse(t.answer);
              expect(value, inInclusiveRange(0, LumoAdventureTasks.maxNumber(grade)),
                  reason: 'Zahlenraum: $where');
            }
            final task = LumoTask(
                id: 'x', grade: grade, subject: subject, unit: unit,
                prompt: t.prompt, choices: t.choices, answer: t.answer,
                explanation: t.explanation, difficulty: grade);
            expect(guard.problems(task), isEmpty, reason: where);
          }
        }
      }
    }
  });

  test('Rechenproben: Zahlenmauer, Platzhalter und Zahlenrätsel stimmen', () {
    final generator = LumoAdventureTasks(Random(5));
    for (var grade = 1; grade <= 4; grade++) {
      for (var i = 0; i < 300; i++) {
        final wall = generator.generate(subject: 'Mathematik', unit: 'Zahlenmauer', grade: grade);
        final n = _numbers(wall.prompt);
        final answer = int.parse(wall.answer);
        if (wall.prompt.contains('ganz oben')) {
          expect(answer, n[0] + 2 * n[1] + n[2], reason: wall.prompt);
        } else {
          expect(answer, n[0] + n[1], reason: wall.prompt);
          expect(n[3], n[0] + 2 * n[1] + n[2], reason: wall.prompt);
        }
        final star = generator.generate(subject: 'Mathematik', unit: 'Platzhalter-Rätsel', grade: grade);
        final s = _numbers(star.prompt);
        final x = int.parse(star.answer);
        if (star.prompt.contains('+ ★')) expect(s[0] + x, s[1], reason: star.prompt);
        if (star.prompt.contains('★ −')) expect(x - s[0], s[1], reason: star.prompt);
        if (star.prompt.contains('· ★')) expect(s[0] * x, s[1], reason: star.prompt);
      }
    }
  });

  test('praktisch unendlich: viele verschiedene Aufgaben je Einheit', () {
    final generator = LumoAdventureTasks(Random(11), childName: 'Mia');
    for (final unit in ['Rechengeschichten', 'Zahlenmauer', 'Marktstand', 'Wortarten-Jagd', 'Satzbaustelle']) {
      final subject = LumoAdventureTasks.units.entries
          .firstWhere((e) => e.value.containsKey(unit))
          .key;
      final prompts = {
        for (var i = 0; i < 300; i++)
          (generator.generate(subject: subject, unit: unit, grade: 3))
              .let((t) => '${t.prompt}|${t.answer}'),
      };
      expect(prompts.length, greaterThan(200), reason: unit);
    }
  });

  test('der Name des Kindes kommt in Geschichten vor', () {
    final generator = LumoAdventureTasks(Random(2), childName: 'Mia');
    final prompts = [
      for (var i = 0; i < 100; i++)
        generator.generate(subject: 'Mathematik', unit: 'Rechengeschichten', grade: 2).prompt,
    ];
    expect(prompts.where((p) => p.contains('Mia')).length, greaterThan(15));
  });

  test('der Aufgaben-Generator mischt die Abenteuer in jede Klasse', () {
    for (var grade = 1; grade <= 4; grade++) {
      final units = Curriculum.unitsForGrade('Mathematik', grade);
      expect(units, contains('Rechengeschichten'));
      expect(units, contains('Zahlenmauer'));
      expect(Curriculum.unitsForGrade('Deutsch', grade), contains('Wortdetektiv'));
      expect(Curriculum.unitsForGrade('Sachunterricht', grade), contains('Wer bin ich?'));
    }
    expect(Curriculum.unitsForGrade('Sachunterricht', 2), isNot(contains('Österreich-Reise')));
    final factory = ExerciseFactory(seed: 1);
    final task = factory.next(grade: 3, subject: 'Mathematik', unit: 'Marktstand', childName: 'Mia');
    expect(task.unit, 'Marktstand');
    expect(task.choices, contains(task.answer));
  });
}
