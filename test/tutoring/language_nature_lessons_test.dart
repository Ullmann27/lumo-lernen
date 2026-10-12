import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';

void main() {
  test('syllable answers have independently checked spoken segmentation', () {
    const expected = {'Sonne': 2, 'Tomate': 3, 'Blume': 2, 'Rakete': 3};
    for (final step
        in GuidedLessonCatalog.syllables.steps.where((s) => s.isQuestion)) {
      expect(step.syllables.join(), step.word);
      expect(int.parse(step.expected), expected[step.word]);
      expect(step.help(level: 1), isNot(step.help(level: 2)));
    }
  });
  test('plant course teaches four real parts and checks a different plant', () {
    final questions = GuidedLessonCatalog.plantParts.steps
        .where((s) => s.isQuestion)
        .toList();
    expect(questions.map((s) => s.expected),
        ['Wurzel', 'Stängel', 'Blüte', 'Blatt']);
    expect(questions.last.plantVariant, 1);
    for (final step in questions) {
      expect(step.choices.where(step.accepts), [step.expected]);
      expect(step.help(level: 1), isNot(step.help(level: 2)));
    }
  });
  for (final (subject, unit) in [
    ('Deutsch', 'Silben'),
    ('Sachunterricht', 'Pflanzen')
  ]) {
    test('$subject has a real matching guided introduction', () {
      final lesson = GuidedLessonCatalog.schoolIntroduction(
          subject: subject, unit: unit, grade: 1);
      expect(lesson, isNotNull);
      expect(lesson!.schoolUnit, unit);
      expect(lesson.steps.first.type, TutoringStepType.greeting);
      expect(lesson.steps.last.type, TutoringStepType.recap);
      expect(lesson.steps.where((s) => s.isIndependent).length, 2);
      expect(
          GuidedLessonCatalog.schoolIntroduction(
              subject: 'Mathematik', unit: unit, grade: 1),
          isNull);
    });
  }
}
