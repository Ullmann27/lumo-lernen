import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  group('Exact curriculum selection is never silently rerouted', () {
    test('grade out of range is rejected rather than clamped', () {
      for (final grade in [-2, 0, 5, 99]) {
        expect(
            () => ExerciseFactory(seed: 7).nextExact(
                grade: grade, subject: 'Mathematik', unit: 'Plus bis 10'),
            throwsArgumentError);
      }
    });
    test('unknown subject does not become Mathematics', () {
      expect(
          () => ExerciseFactory(seed: 3).nextExact(
              grade: 2, subject: 'Fantasiefach', unit: 'Plus bis 10'),
          throwsArgumentError);
    });
    test('unknown topic does not become random question', () {
      expect(
          () => ExerciseFactory(seed: 3).nextExact(
              grade: 1, subject: 'Mathematik', unit: 'Nicht vorhanden'),
          throwsArgumentError);
    });
    test('all or mixed is invalid for explicit selection', () {
      expect(
          () => ExerciseFactory(seed: 1)
              .nextExact(grade: 1, subject: 'Mathematik', unit: 'Alle'),
          throwsArgumentError);
    });
    test('explicit first-grade addition returns the selected lesson', () {
      for (var seed = 0; seed < 12; seed++) {
        final task = ExerciseFactory(seed: seed)
            .nextExact(grade: 1, subject: 'Mathematik', unit: 'Plus bis 10');
        expect(task.grade, 1);
        expect(task.subject, 'Mathematik');
        expect(task.unit, 'Plus bis 10');
        expect(task.choices, contains(task.answer));
      }
    });
    test('mixed existing generation remains a separate API', () {
      final task = ExerciseFactory(seed: 1).next(grade: 1);
      expect(task.grade, 1);
      expect(task.prompt, isNotEmpty);
    });
    test('current-grade filter excludes earlier subjects and units', () {
      const grade = 4;
      final mathUnits =
          Curriculum.unitsForGrade('Mathematik', grade, currentGradeOnly: true);
      expect(mathUnits, isNotEmpty);
      expect(mathUnits, isNot(contains('Plus bis 10')));
      expect(
        () => ExerciseFactory(seed: 14).nextExact(
          grade: grade,
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          currentGradeOnly: true,
        ),
        throwsArgumentError,
      );
      final task = ExerciseFactory(seed: 14).nextExact(
          grade: grade,
          subject: 'Mathematik',
          unit: mathUnits.first,
          currentGradeOnly: true);
      expect(task.grade, grade);
      expect(task.unit, mathUnits.first);
      expect(task.subject, 'Mathematik');
    });
  });
}
