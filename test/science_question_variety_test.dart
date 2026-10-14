import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  for (final scenario in [
    (grade: 1, unit: 'Jahreszeiten', count: 4),
    (grade: 2, unit: 'Tiere', count: 9),
    (grade: 3, unit: 'Bundesländer Österreichs', count: 8),
    (grade: 3, unit: 'Wetter', count: 6),
    (grade: 3, unit: 'Verkehr', count: 6),
    (grade: 3, unit: 'Zeit und Kalender', count: 6),
    (grade: 3, unit: 'Familie und Gemeinschaft', count: 6),
    (grade: 3, unit: 'Berufe', count: 6),
    (grade: 3, unit: 'Pflanzen', count: 6),
    (grade: 4, unit: 'Kontinente und Ozeane', count: 6),
    (grade: 4, unit: 'Diagramme lesen', count: 6),
  ]) {
    test('Sachunterricht grade ${scenario.grade} / ${scenario.unit}: '
        'use distinct real questions until the bank is depleted', () {
      final factory = ExerciseFactory(seed: 42);
      final prompts = <String>{};
      for (var i = 0; i < scenario.count; i++) {
        final task = factory.next(
            grade: scenario.grade,
            subject: 'Sachunterricht',
            unit: scenario.unit);
        expect(task.subject, 'Sachunterricht');
        expect(task.unit, scenario.unit);
        expect(task.choices.contains(task.answer), isTrue);
        expect(task.choices.toSet().length, task.choices.length);
        expect(prompts.add('${task.prompt}|${task.answer}'), isTrue,
            reason: 'Repeated real content at turn ${i + 1}.');
      }
      final firstAfterExhaustion = factory.next(
          grade: scenario.grade,
          subject: 'Sachunterricht',
          unit: scenario.unit);
      expect(firstAfterExhaustion.prompt, isNotEmpty);
    });
  }

  test('different third- and fourth-grade units do not collapse to one topic', () {
    for (final grade in [3, 4]) {
      final factory = ExerciseFactory(seed: grade);
      final units = Curriculum.unitsForGrade(
          'Sachunterricht', grade, currentGradeOnly: true);
      expect(units.length, greaterThanOrEqualTo(3));
      for (final unit in units) {
        final task = factory.next(
            grade: grade, subject: 'Sachunterricht', unit: unit);
        expect(task.unit, unit,
            reason: 'visible subject must not silently show unrelated tasks');
      }
    }
  });
}
