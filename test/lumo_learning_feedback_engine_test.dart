import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_feedback_engine.dart';

void main() {
  group('LumoLearningFeedbackEngine', () {
    test('uses coaching tone on first wrong answer', () {
      final engine = LumoLearningFeedbackEngine();

      final turn = engine.record(_wrongEvent(taskIndex: 1));

      expect(turn.tone, LumoFeedbackTone.coaching);
      expect(turn.autoAdvanceDelayMs, 0);
      expect(turn.cardMessage, isNot(contains('Ich helfe dir wie ein Lehrer')));
    });

    test('uses teacher-like rescue tone from second wrong answer', () {
      final engine = LumoLearningFeedbackEngine();

      engine.record(_wrongEvent(taskIndex: 1));
      final turn = engine.record(_wrongEvent(taskIndex: 2));

      expect(turn.tone, LumoFeedbackTone.rescue);
      expect(turn.title, 'Lumo hilft Schritt für Schritt');
      expect(turn.autoAdvanceDelayMs, 0);
      expect(
        turn.cardMessage,
        anyOf(
          contains('Ich helfe dir wie ein Lehrer'),
          contains('zweimal schwer'),
          contains('Lumo bremst kurz'),
        ),
      );
      expect(turn.learningTip, contains('Lerntipp:'));
    });

    test('resets wrong streak after correct answer', () {
      final engine = LumoLearningFeedbackEngine();

      engine.record(_wrongEvent(taskIndex: 1));
      engine.record(_correctEvent(taskIndex: 2));
      final turn = engine.record(_wrongEvent(taskIndex: 3));

      expect(turn.tone, LumoFeedbackTone.coaching);
    });
  });
}

LumoInteractionEvent _wrongEvent({required int taskIndex}) {
  return LumoInteractionEvent(
    subject: 'Mathematik',
    unit: 'Plus bis 10',
    prompt: '3 + 2 = ?',
    correctAnswer: 5,
    givenAnswer: 4,
    correct: false,
    helpUsed: false,
    responseTimeMs: 8200,
    errorTypes: const <ErrorType>[ErrorType.countingError],
    masteryBefore: .2,
    masteryAfter: .18,
    taskIndex: taskIndex,
    totalTasks: 10,
    sessionKind: 'exerciseSet',
  );
}

LumoInteractionEvent _correctEvent({required int taskIndex}) {
  return LumoInteractionEvent(
    subject: 'Mathematik',
    unit: 'Plus bis 10',
    prompt: '3 + 2 = ?',
    correctAnswer: 5,
    givenAnswer: 5,
    correct: true,
    helpUsed: false,
    responseTimeMs: 5200,
    errorTypes: const <ErrorType>[],
    masteryBefore: .2,
    masteryAfter: .25,
    taskIndex: taskIndex,
    totalTasks: 10,
    sessionKind: 'exerciseSet',
  );
}
