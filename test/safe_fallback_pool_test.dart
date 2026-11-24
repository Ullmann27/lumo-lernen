import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/safe_fallback_pool.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  const pool = SafeFallbackPool();

  test('math fallback stays math', () {
    final task = pool.pick(
      subject: 'Mathematik',
      grade: 1,
      counter: 0,
      unit: 'Plus bis 10',
      difficulty: 1,
    );

    expect(task.subject, 'Mathematik');
    expect(task.answer, isNotEmpty);
    expect(task.choices, contains(task.answer));
  });

  test('an ambiguous topic name never changes the selected German subject', () {
    final task = pool.pick(
      subject: 'Deutsch',
      grade: 1,
      counter: 0,
      unit: 'Farben',
      difficulty: 1,
    );

    expect(task.subject, 'Deutsch');
    expect(task.prompt, isNot(contains('heißt')));
    expect(task.choices, contains(task.answer));
  });

  test('fallback does not infer science from the selected topic name', () {
    final task = pool.pick(
      subject: 'Deutsch',
      grade: 2,
      counter: 0,
      unit: 'Pflanzen',
      difficulty: 1,
    );

    expect(task.subject, 'Deutsch');
    expect(task.choices, contains(task.answer));
  });

  test(
    'spelling fallback uses spelling variants, not unrelated correct words',
    () {
      final task = pool.pick(
        subject: 'Rechtschreibung',
        grade: 1,
        counter: 0,
        unit: 'Dehnungen',
        difficulty: 1,
      );

      expect(task.prompt, 'Welche Schreibweise ist richtig?');
      expect(task.choices, contains(task.answer));
      expect(
        task.choices,
        isNot(containsAll(<String>['Ball', 'Blume', 'Kerze'])),
      );
    },
  );

  // Fachprüfung 2026-11 (S-L12, D-L13, E-M4, E-L7): Ersatzaufgaben passen
  // zur Klasse, nutzen die Begriffe der App und schreiben Farben klein.
  test('fallbacks fit the grade and use the app\'s terms', () {
    List<LumoTask> all(String subject, int grade) => [
          for (var counter = 0; counter < 12; counter++)
            pool.pick(
                subject: subject,
                grade: grade,
                counter: counter,
                unit: 'Alle',
                difficulty: grade),
        ];
    final grade1Science = all('Sachunterricht', 1).map((t) => t.prompt).toSet();
    for (var grade = 1; grade <= 4; grade++) {
      for (final subject in <String>['Deutsch', 'Englisch', 'Sachunterricht']) {
        for (final task in all(subject, grade)) {
          expect(task.choices.toSet(), hasLength(task.choices.length));
          expect(task.choices.where((c) => c == task.answer), hasLength(1));
          expect(task.prompt, isNot(contains('Hauptwort')));
          if (subject == 'Englisch') {
            final english =
                RegExp(r'heißt (.+) auf Deutsch').firstMatch(task.prompt)!;
            expect(english.group(1)!.toLowerCase(),
                isNot(task.answer.toLowerCase()));
            expect(<String>{'Rot', 'Blau', 'Grün', 'Gelb'},
                isNot(contains(task.answer)));
          }
          if (subject == 'Sachunterricht' && grade >= 3) {
            expect(grade1Science, isNot(contains(task.prompt)));
            expect(task.prompt, isNot(contains('Fahrradhelm')));
          }
        }
      }
    }
  });
}

