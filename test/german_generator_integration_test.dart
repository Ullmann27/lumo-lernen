import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

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
      const guard = TaskQualityGuard();

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
        expect(guard.problems(task), isEmpty, reason: '${task.unit}: ${task.prompt} / ${task.choices} -> ${task.answer}');
      }
    });

    test('German sound, rhyme, syllable and article tasks stay deterministic and correct', () {
      const guard = TaskQualityGuard();

      for (final unit in <String>['Anfangslaute', 'Endlaute', 'Silben', 'Reime', 'Artikel', 'Namenwoerter', 'Tunwoerter', 'Wiewoerter']) {
        for (var seed = 1; seed <= 24; seed++) {
          final factory = ExerciseFactory(seed: seed);
          final task = factory.next(grade: 2, subject: 'Deutsch', unit: unit);

          expect(guard.problems(task), isEmpty, reason: 'seed=$seed unit=$unit task=${task.prompt} choices=${task.choices} answer=${task.answer}');
          if (unit == 'Endlaute') {
            expect(task.prompt, startsWith('Mit welchem Laut endet'), reason: task.prompt);
          }
        }
      }
    });

    test('spelling generator avoids case-only duplicates and unrelated distractors', () {
      const guard = TaskQualityGuard();

      for (final unit in <String>['Haeufige Woerter', 'Doppelmitlaut']) {
        for (var seed = 1; seed <= 16; seed++) {
          final factory = ExerciseFactory(seed: seed);
          final task = factory.next(grade: 2, subject: 'Rechtschreibung', unit: unit);
          final normalized = task.choices.map((choice) => choice.toLowerCase().trim()).toSet();

          expect(normalized, hasLength(task.choices.length), reason: task.prompt);
          expect(guard.problems(task), isEmpty, reason: 'seed=$seed unit=$unit task=${task.prompt} choices=${task.choices} answer=${task.answer}');
        }
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
