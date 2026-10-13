import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

void main() {
  group('ExerciseFactory German generator', () {
    const guard = TaskQualityGuard();

    test('every current-grade German unit produces a valid task', () {
      for (var grade = 1; grade <= 4; grade++) {
        final units = Curriculum.unitsForGrade(
          'Deutsch',
          grade,
          currentGradeOnly: true,
        );
        expect(units, isNotEmpty, reason: 'Deutsch Klasse $grade');

        for (final unit in units) {
          for (var seed = 1; seed <= 20; seed++) {
            final task = ExerciseFactory(seed: seed).next(
              grade: grade,
              subject: 'Deutsch',
              unit: unit,
            );
            final normalizedChoices = task.choices
                .map((choice) => choice.trim())
                .where((choice) => choice.isNotEmpty)
                .toList();

            expect(task.subject, 'Deutsch', reason: '$grade/$unit');
            expect(task.unit, unit, reason: '$grade/$unit seed=$seed');
            expect(task.difficulty, grade, reason: '$grade/$unit seed=$seed');
            expect(task.prompt.trim(), isNotEmpty, reason: '$grade/$unit');
            expect(task.answer.trim(), isNotEmpty, reason: '$grade/$unit');
            expect(task.explanation.trim(), isNotEmpty,
                reason: '$grade/$unit');
            expect(normalizedChoices, contains(task.answer),
                reason: '$grade/$unit');
            expect(normalizedChoices.toSet(), hasLength(normalizedChoices.length),
                reason: '$grade/$unit');
            expect(
              guard.problems(task),
              isEmpty,
              reason:
                  '$grade/$unit seed=$seed: ${task.prompt} / ${task.choices} -> ${task.answer}',
            );
          }
        }
      }
    });

    test('grade-one sound rhyme syllable and article tasks stay correct', () {
      for (final unit in <String>[
        'Anfangslaute',
        'Endlaute',
        'Silben',
        'Reime',
        'Artikel',
      ]) {
        expect(
          Curriculum.unitsForGrade(
            'Deutsch',
            1,
            currentGradeOnly: true,
          ),
          contains(unit),
        );
        for (var seed = 1; seed <= 24; seed++) {
          final task = ExerciseFactory(seed: seed).next(
            grade: 1,
            subject: 'Deutsch',
            unit: unit,
          );
          expect(
            guard.problems(task),
            isEmpty,
            reason:
                'seed=$seed unit=$unit task=${task.prompt} choices=${task.choices} answer=${task.answer}',
          );
          expect(task.unit, unit);
          if (unit == 'Endlaute') {
            expect(
              task.prompt,
              startsWith('Mit welchem Laut endet'),
              reason: task.prompt,
            );
          }
        }
      }
    });

    test('grade-two word classes remain in grade two', () {
      for (final unit in <String>[
        'Namenwoerter',
        'Tunwoerter',
        'Wiewoerter',
      ]) {
        final task = ExerciseFactory(seed: 31).next(
          grade: 2,
          subject: 'Deutsch',
          unit: unit,
        );
        expect(task.unit, unit);
        expect(task.difficulty, 2);
        expect(guard.problems(task), isEmpty);
      }
    });

    test('stale lower-grade German unit cannot bypass selected grade', () {
      final current =
          Curriculum.unitsForGrade('Deutsch', 4, currentGradeOnly: true);
      for (var seed = 0; seed < 30; seed++) {
        final task = ExerciseFactory(seed: seed).next(
          grade: 4,
          subject: 'Deutsch',
          unit: 'Endlaute',
        );
        expect(current, contains(task.unit));
        expect(task.unit, isNot('Endlaute'));
        expect(task.difficulty, 4);
      }
    });

    test('spelling generator avoids duplicate or unrelated choices', () {
      for (final entry in <(int, String)>[
        (1, 'Haeufige Woerter'),
        (3, 'Doppelmitlaut'),
      ]) {
        for (var seed = 1; seed <= 16; seed++) {
          final task = ExerciseFactory(seed: seed).next(
            grade: entry.$1,
            subject: 'Rechtschreibung',
            unit: entry.$2,
          );
          final normalized =
              task.choices.map((choice) => choice.toLowerCase().trim()).toSet();

          expect(normalized, hasLength(task.choices.length),
              reason: task.prompt);
          expect(
            guard.problems(task),
            isEmpty,
            reason:
                'seed=$seed unit=${entry.$2} task=${task.prompt} choices=${task.choices} answer=${task.answer}',
          );
        }
      }
    });

    test('buildSession returns only current-grade German tasks', () {
      final factory = ExerciseFactory(seed: 42);
      final current =
          Curriculum.unitsForGrade('Deutsch', 2, currentGradeOnly: true).toSet();
      final tasks =
          factory.buildSession(grade: 2, count: 12, subject: 'Deutsch');

      expect(tasks, hasLength(12));
      expect(tasks.every((task) => task.subject == 'Deutsch'), isTrue);
      expect(tasks.every((task) => task.difficulty == 2), isTrue);
      expect(tasks.every((task) => current.contains(task.unit)), isTrue);
      expect(tasks.every((task) => task.prompt.trim().isNotEmpty), isTrue);
      expect(tasks.every((task) => task.choices.contains(task.answer)), isTrue);
    });
  });
}
