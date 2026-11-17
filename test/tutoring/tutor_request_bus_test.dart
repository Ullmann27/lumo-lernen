import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  final bus = LumoCompanionRequests.instance;
  setUp(() {
    bus.clearLearningScope();
    bus.tutor.activateProfile(10);
  });
  LumoCompanionTaskContext task(int generation,
          {int attempts = 0, bool exam = false}) =>
      LumoCompanionTaskContext(
          subject: 'Mathematik',
          unit: 'Zehner und Einer',
          prompt: 'Wie viele Zehner stecken in 84?',
          taskId: 'task-$generation',
          profileGeneration: generation,
          attempts: attempts,
          isExam: exam);
  test('late event cannot enter another profile trace or active tutor', () {
    final old = task(10, attempts: 2);
    bus.publishTask(old);
    bus.tutor.activateProfile(11);
    bus.clearLearningScope();
    bus.publishTask(task(11));
    final before = bus.learningEvents.value;
    expect(
        bus.recordLearningEvent(LumoLearningEventKind.answerIncorrect,
            context: old),
        isNull);
    expect(bus.learningEvents.value, before);
    expect(bus.tutor.mistakes, 0);
    bus.publishTask(old);
    expect(bus.taskContext.value!.profileGeneration, 11);
  });
  test(
      'actual bus events feed central policy, safe task trace excludes answers',
      () {
    bus.publishTask(task(10));
    for (var i = 1; i <= 2; i++) {
      bus.recordLearningEvent(LumoLearningEventKind.answerIncorrect,
          context: task(10, attempts: i));
    }
    expect(bus.tutor.shouldOffer, isTrue);
    bus.recordLearningEvent(LumoLearningEventKind.hintDeclined);
    expect(bus.tutor.shouldOffer, isFalse);
  });
}
