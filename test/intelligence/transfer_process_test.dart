import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';

void main() {
  test(
      'correct total with unbundled ones is not a valid place-value explanation',
      () {
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'source-84');
    lesson.beginTransfer();
    final result = lesson.submitConstruction(tens: 4, ones: 17);
    expect(result.resultCorrect, isTrue);
    expect(result.processCorrect, isFalse);
    expect(lesson.submitComprehension(7), isNull);
    expect(lesson.completion, isNull);
  });
  test(
      'fresh construction and matching explanation produce one verifiable receipt',
      () {
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'source-84');
    expect(lesson.submitComprehension(7), isNull);
    lesson.beginTransfer();
    expect(lesson.submitConstruction(tens: 5, ones: 7).processCorrect, isTrue);
    final proof = lesson.submitComprehension(7)!;
    expect(proof.independent, isTrue);
    expect(proof.sourceNumber, 84);
    expect(proof.number, 57);
    expect(proof.evidence.transferCheck, isTrue);
    expect(proof.evidence.helpLevel, 0);
    expect(lesson.submitComprehension(7), isNull);
  });
  test(
      'guessing or correcting an earlier construction never becomes independent',
      () {
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'source-84');
    lesson.beginTransfer();
    lesson.submitConstruction(tens: 7, ones: 5);
    lesson.submitConstruction(tens: 5, ones: 7);
    lesson.submitComprehension(4);
    final proof = lesson.submitComprehension(7)!;
    expect(proof.independent, isFalse);
    expect(proof.evidence.transferCheck, isFalse);
    expect(proof.evidence.helpLevel, greaterThan(0));
  });
  test(
      'same-number followup and malformed task ranges cannot manufacture transfer',
      () {
    expect(
        () => PlaceValueLessonSession(
            sourceNumber: 84, targetNumber: 84, sourceProblemId: 'source-84'),
        throwsArgumentError);
    expect(
        () => PlaceValueLessonSession(
            sourceNumber: 184, targetNumber: 57, sourceProblemId: 'source-184'),
        throwsArgumentError);
  });
}
