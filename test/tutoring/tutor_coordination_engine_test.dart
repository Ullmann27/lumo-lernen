import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/tutor_coordination_engine.dart';

void main() {
  late TutorCoordinationEngine tutor;
  TutorTaskScope task(
          {int generation = 1, String id = 'task-a', bool exam = false}) =>
      TutorTaskScope(
          generation: generation,
          taskId: id,
          problemId: 'problem-$id',
          subject: 'Mathematik',
          unit: 'Zehner und Einer',
          isExam: exam);
  setUp(() {
    tutor = TutorCoordinationEngine()..activateProfile(1);
  });

  test('two errors invite once; declining never inserts or repeats help', () {
    tutor.enterTask(task());
    tutor.answer(attempt: 1, correct: false);
    expect(tutor.shouldOffer, isFalse);
    tutor.answer(attempt: 2, correct: false);
    expect(tutor.shouldOffer, isTrue);
    tutor.declineHelp();
    tutor.answer(attempt: 3, correct: false);
    expect(tutor.shouldOffer, isFalse);
    expect(tutor.helpLevel, 0);
    tutor.enterTask(task(id: 'task-b'));
    tutor.answer(attempt: 1, correct: false);
    tutor.answer(attempt: 2, correct: false);
    expect(tutor.shouldOffer, isTrue);
  });

  test('requested methods advance; successful answer keeps assisted evidence',
      () {
    tutor.enterTask(task());
    expect(tutor.requestHelp(), 1);
    expect(tutor.requestHelp(), 2);
    expect(tutor.requestHelp(), 3);
    final evidence = tutor.answer(attempt: 1, correct: true)!;
    expect(evidence.helpLevel, 3);
    expect(evidence.transferCheck, isFalse);
    expect(tutor.events.last.kind, TutorEventKind.assistedSuccess);
    expect(tutor.requestHelp(), isNull);
  });

  test('exams reject help and stale generations cannot change current task',
      () {
    tutor.enterTask(task(exam: true));
    tutor.answer(attempt: 1, correct: false);
    tutor.answer(attempt: 2, correct: false);
    expect(tutor.shouldOffer, isFalse);
    expect(tutor.requestHelp(), isNull);
    tutor.activateProfile(2);
    tutor.enterTask(task(generation: 2, id: 'child-b'));
    expect(tutor.enterTask(task()), isFalse);
    expect(tutor.matches(task()), isFalse);
    expect(tutor.scope!.taskId, 'child-b');
    expect(tutor.helpLevel, 0);
    expect(tutor.events.length, 1);
  });

  test('replayed attempts and current problem cannot manufacture transfer', () {
    tutor.enterTask(task());
    final first = tutor.answer(attempt: 1, correct: false)!;
    expect(tutor.answer(attempt: 1, correct: false), isNull);
    expect(tutor.mistakes, 1);
    expect(first.transferCheck, isFalse);
    tutor.requestHelp();
    expect(
        tutor.checkTransfer(
            problemId: 'problem-task-a', correct: true, independent: true),
        isNull);
    final transfer = tutor.checkTransfer(
        problemId: 'place-value-57', correct: true, independent: true)!;
    expect(transfer.helpLevel, 3);
    expect(transfer.transferCheck, isFalse);
    expect(
        tutor.checkTransfer(
            problemId: 'place-value-57', correct: true, independent: true),
        isNull);
    expect(
        tutor
            .checkTransfer(
                problemId: 'place-value-62', correct: true, independent: false)!
            .transferCheck,
        isFalse);
  });

  test('external renderer assistance remains sticky and trace is bounded', () {
    tutor.enterTask(task());
    tutor.answer(attempt: 1, correct: false, assisted: true);
    expect(tutor.answer(attempt: 2, correct: true)!.helpLevel, greaterThan(0));
    for (var i = 0; i < 40; i++) {
      tutor.enterTask(task(id: 'task-$i'));
    }
    expect(tutor.events.length, lessThanOrEqualTo(24));
    expect(() => tutor.events.clear(), throwsUnsupportedError);
  });
}
