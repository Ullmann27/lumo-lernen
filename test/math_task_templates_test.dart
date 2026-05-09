import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  group('MathTaskTemplates', () {
    test('all grades expose many primary-school math templates', () {
      expect(MathTaskTemplates.templatesForGrade(1), hasLength(greaterThanOrEqualTo(9)));
      expect(MathTaskTemplates.templatesForGrade(2), hasLength(greaterThanOrEqualTo(18)));
      expect(MathTaskTemplates.templatesForGrade(3), hasLength(greaterThanOrEqualTo(25)));
      expect(MathTaskTemplates.templatesForGrade(4), hasLength(greaterThanOrEqualTo(30)));
    });

    test('each template range can create more than 30 concrete variants', () {
      for (final template in MathTaskTemplates.templates) {
        final variants = (template.validRangeA.last - template.validRangeA.first + 1) *
            (template.validRangeB.last - template.validRangeB.first + 1);
        expect(variants, greaterThan(30), reason: template.id);
      }
    });

    test('generated tasks always include answer and distinct distractors', () {
      for (final template in MathTaskTemplates.templates) {
        for (var seed = 1; seed <= 12; seed++) {
          final task = template.concretize(seed * 37);
          expect(task.prompt.trim(), isNotEmpty, reason: template.id);
          expect(task.answer.trim(), isNotEmpty, reason: template.id);
          expect(task.choices, contains(task.answer), reason: template.id);
          expect(task.choices.toSet(), hasLength(task.choices.length), reason: template.id);
          expect(task.choices.length, greaterThanOrEqualTo(3), reason: template.id);
          expect(task.explanation.trim(), isNotEmpty, reason: template.id);
        }
      }
    });

    test('grade 1 generated numeric answers are age-appropriate and non-negative', () {
      final factory = ExerciseFactory(seed: 11);
      for (var i = 0; i < 60; i++) {
        final task = factory.next(grade: 1, subject: 'Mathematik');
        final numeric = int.tryParse(task.answer.replaceAll(RegExp('[^0-9-]'), ''));
        if (numeric != null) {
          expect(numeric, greaterThanOrEqualTo(0), reason: task.prompt);
          expect(numeric, lessThanOrEqualTo(100), reason: task.prompt);
        }
        expect(task.choices, contains(task.answer));
      }
    });

    test('template selector respects explicit modern and legacy units', () {
      final modern = MathTaskTemplates.generate(grade: 1, unit: 'Zahlenstrahl', seed: 5);
      final legacy = MathTaskTemplates.generate(grade: 2, unit: 'Zahlenreihe', seed: 5);

      expect(modern.unit, 'Zahlenstrahl');
      expect(legacy.prompt.trim(), isNotEmpty);
      expect(legacy.choices, contains(legacy.answer));
    });
  });
}
