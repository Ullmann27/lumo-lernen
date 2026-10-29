import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/tutor_coordination_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';

void main() {
  test('a receipt without the active task and profile scope cannot be applied',
      () {
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84, targetNumber: 57, sourceProblemId: 'same-problem')
      ..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    final tutor = TutorCoordinationEngine()
      ..activateProfile(2)
      ..enterTask(const TutorTaskScope(
          generation: 2,
          taskId: 'reused-task-id',
          problemId: 'same-problem',
          subject: 'Mathematik',
          unit: 'Zehner und Einer'))
      ..requestHelp();
    expect(tutor.checkSceneTransfer(proof), isNull);
  });
  test(
      'a previous child receipt is rejected even when the task IDs are identical',
      () {
    final lesson = PlaceValueLessonSession(
        sourceNumber: 84,
        targetNumber: 57,
        sourceProblemId: 'same-problem',
        sourceTaskId: 'reused-task-id',
        generation: 1)
      ..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    final tutor = TutorCoordinationEngine()
      ..activateProfile(2)
      ..enterTask(const TutorTaskScope(
          generation: 2,
          taskId: 'reused-task-id',
          problemId: 'same-problem',
          subject: 'Mathematik',
          unit: 'Zehner und Einer'))
      ..requestHelp();
    expect(tutor.checkSceneTransfer(proof), isNull);
  });

  test('legacy boolean-only transfer is never independent competence', () {
    final tutor = TutorCoordinationEngine()
      ..activateProfile(1)
      ..enterTask(const TutorTaskScope(
          generation: 1,
          taskId: 'task',
          problemId: 'source',
          subject: 'Mathematik',
          unit: 'Zehner und Einer'))
      ..requestHelp();
    final unverified = tutor.checkTransfer(
        problemId: 'other', correct: true, independent: true)!;
    expect(unverified.transferCheck, isFalse);
    expect(unverified.helpLevel, greaterThan(0));
  });
}
