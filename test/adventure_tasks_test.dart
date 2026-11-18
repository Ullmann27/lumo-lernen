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

  // Fachprüfung Mathematik (17.11.2026), Abenteuer-Aufgaben.
  group('Fachprüfung Mathematik', () {
    AdventureTask next(LumoAdventureTasks generator, String unit, int grade,
            {String subject = 'Mathematik'}) =>
        generator.generate(subject: subject, unit: unit, grade: grade);

    test('M22: große Zahlen zählen Punkte, Meter, Zuschauer, Schritte', () {
      final generator = LumoAdventureTasks(Random(3));
      for (final grade in [3, 4]) {
        for (var i = 0; i < 400; i++) {
          final task = next(generator, 'Rechengeschichten', grade);
          final numbers = _numbers(task.prompt);
          if (numbers.every((n) => n < 100)) continue;
          // Früher: „Hoppel hat 902 Erdbeeren“, „fährt 471 Runden“.
          for (final thing in ['Erdbeeren', 'Runden', 'Äpfel', 'Kekse', 'Murmeln']) {
            final counted = RegExp('(\\d+) $thing').allMatches(task.prompt);
            for (final match in counted) {
              expect(int.parse(match[1]!), lessThanOrEqualTo(1000),
                  reason: task.prompt);
            }
          }
          expect(task.prompt, isNot(matches(RegExp(r'fährt \S+ \d{3,} Runden'))));
        }
      }
    });

    test('M20: mehrstufige Geschichte ohne mehrdeutiges „Davon“, richtiger Fall',
        () {
      final generator = LumoAdventureTasks(Random(8));
      var seen = 0;
      for (var i = 0; i < 600; i++) {
        final task = next(generator, 'Rechengeschichten', 4);
        if (!task.prompt.contains('Packungen')) continue;
        seen++;
        expect(task.prompt, isNot(contains('Davon')));
        expect(task.prompt, isNot(contains('mit je')));
        expect(task.prompt, contains('In jeder Packung sind'));
        expect(task.prompt, contains('Von allen'));
        final n = _numbers(task.prompt);
        expect(int.parse(task.answer), n[0] * n[1] + n[2] - n[3],
            reason: task.prompt);
      }
      expect(seen, greaterThan(20));
    });

    test('M21: Zahlenmauer ohne das Fachwort „Summe“', () {
      final generator = LumoAdventureTasks(Random(4));
      for (var grade = 1; grade <= 4; grade++) {
        for (var i = 0; i < 100; i++) {
          final task = next(generator, 'Zahlenmauer', grade);
          expect(task.prompt, isNot(contains('Summe')));
          expect(task.prompt,
              contains('Zwei Steine nebeneinander ergeben zusammen den Stein darüber.'));
        }
      }
    });

    test('L7: Klasse 1 hat keine Karten über 20 und wechselnde Waren', () {
      final generator = LumoAdventureTasks(Random(6));
      final goods = <String>{};
      for (final unit in ['Rechengeschichten', 'Zahlenmauer', 'Marktstand']) {
        for (var i = 0; i < 300; i++) {
          final task = next(generator, unit, 1);
          for (final choice in task.choices) {
            expect(_numbers(choice).single, lessThanOrEqualTo(20),
                reason: '${task.prompt} ${task.choices}');
          }
          expect(task.choices.toSet(), hasLength(4), reason: task.prompt);
          if (unit == 'Marktstand') {
            goods.add(RegExp(r'am Markt (.+?) um').firstMatch(task.prompt)![1]!);
          }
        }
      }
      // Früher immer „einen Ball“ und „ein Buch“.
      expect(goods.length, greaterThan(4));
      final second = <String>{
        for (var i = 0; i < 100; i++)
          RegExp(r'kauft (.+?) um').firstMatch(next(generator, 'Marktstand', 2).prompt)![1]!,
      };
      expect(second.length, greaterThan(3));
    });

    test('L1: Geschichten zählen nie „1“ Dinge in der Mehrzahl', () {
      final generator = LumoAdventureTasks(Random(12));
      for (var grade = 1; grade <= 4; grade++) {
        for (var i = 0; i < 400; i++) {
          final task = next(generator, 'Rechengeschichten', grade);
          expect(RegExp(r'(?<![\d,])1 [A-ZÄÖÜ]').hasMatch(task.prompt), isFalse,
              reason: task.prompt);
        }
      }
    });

    test('L6: Erklärungen bei „=“ und beim Uhr-Abenteuer', () {
      final generator = LumoAdventureTasks(Random(2));
      var equal = 0;
      for (var i = 0; i < 600; i++) {
        final task = next(generator, 'Größer, kleiner, gleich', 2);
        if (task.answer != '=') continue;
        equal++;
        expect(task.explanation, contains('Beide Seiten sind gleich groß.'));
        expect(task.explanation, isNot(contains('Krokodil')));
      }
      expect(equal, greaterThan(10));
      for (var i = 0; i < 100; i++) {
        final task = next(generator, 'Uhr-Abenteuer', 2);
        expect(task.explanation, isNot(contains(' + ')));
        expect(task.explanation, startsWith('Von '));
        expect(task.explanation, endsWith('${task.answer}.'));
      }
    });

    test('L13: „gehört zu den Möbelstücken“ statt „gehört zu Möbelstücke“', () {
      final generator = LumoAdventureTasks(Random(9));
      for (var i = 0; i < 300; i++) {
        final task = next(generator, 'Was passt nicht?', 2, subject: 'Logik');
        expect(task.explanation, isNot(matches(RegExp(r'gehör(t|en) zu [A-ZÄÖÜ]'))),
            reason: task.explanation);
        expect(
            task.explanation,
            matches(RegExp(r'gehören (zum|zu den|zur Gruppe) .+\. \S+ gehört (zum|zu den|zur Gruppe) ')),
            reason: task.explanation);
      }
    });
  });
}
