import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:lumo_lernen/features/tutoring/guided_language_nature_illustration.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';

void main() {
  test('the targeted leaf retains the green surface described in its hint',
      () async {
    final recorder = ui.PictureRecorder();
    const painter = GuidedFlowerPainter(
        target: GuidedPlantPart.leaf, variant: 1, highlight: 1);
    painter.paint(Canvas(recorder), const Size(280, 230));
    final picture = recorder.endRecording();
    final image = await picture.toImage(280, 230);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = (115 * 280 + 105) * 4;
      expect(bytes!.buffer.asUint8List().sublist(offset, offset + 3),
          [0x43, 0xBA, 0x77]);
      final step = GuidedLessonCatalog.plantParts.steps.firstWhere(
          (s) => s.isIndependent && s.plantPart == GuidedPlantPart.leaf);
      expect(step.help(level: 1), contains('grünen Flächen'));
      expect(step.help(level: 1), isNot(contains('Blatt')));
    } finally {
      image.dispose();
      picture.dispose();
    }
  });
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
