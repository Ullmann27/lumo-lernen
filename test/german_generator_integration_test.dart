import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  group('ExerciseFactory German generator', () {
    const units = <String>[
      'Anfangslaute',
      'Endlaute',
      'Silben',
      'Reime',
      'Wortschatz',
      'Satz verstehen',
      'Artikel',
      'Namenwoerter',
      'Namenswoerter',
      'Hauptwoerter',
      'Tunwoerter',
      'Wiewoerter',
      'Satz bauen',
      'St oder Sp',
      'Einzahl und Mehrzahl',
      'Wort-Bild schreiben',
    ];

    test('all German units produce valid multiple-choice tasks', () {
      final factory = ExerciseFactory(seed: 27);

      for (final unit in units) {
        final task = factory.next(grade: 2, subject: 'Deutsch', unit: unit);
        final normalizedChoices = task.choices.map((choice) => choice.trim()).where((choice) => choice.isNotEmpty).toList();

        expect(task.subject, 'Deutsch', reason: unit);
        expect(task.unit, unit == 'Namenswoerter' || unit == 'Hauptwoerter' ? unit : isNotEmpty, reason: unit);
        expect(task.prompt.trim(), isNotEmpty, reason: unit);
        expect(task.answer.trim(), isNotEmpty, reason: unit);
        expect(task.explanation.trim(), isNotEmpty, reason: unit);
        expect(normalizedChoices, contains(task.answer), reason: unit);
        expect(normalizedChoices.toSet(), hasLength(normalizedChoices.length), reason: unit);
      }
    });

    test('buildSession returns the requested number of German tasks', () {
      final factory = ExerciseFactory(seed: 42);
      final tasks = factory.buildSession(grade: 2, count: 12, subject: 'Deutsch');

      expect(tasks, hasLength(12));
      expect(tasks.every((task) => task.subject == 'Deutsch'), isTrue);
      expect(tasks.every((task) => task.prompt.trim().isNotEmpty), isTrue);
      expect(tasks.every((task) => task.choices.contains(task.answer)), isTrue);
    });
  });
}
