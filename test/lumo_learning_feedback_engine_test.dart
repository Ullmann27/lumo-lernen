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

    test('guided successes receive practice praise without capability claims',
        () {
      final engine = LumoLearningFeedbackEngine();
      for (var i = 1; i <= 6; i++) {
        final turn = engine.record(
            _correctEvent(taskIndex: i, helpUsed: true, responseTimeMs: 1000));
        expect(turn.tone, LumoFeedbackTone.encouraging);
        expect(turn.title, 'Gemeinsam geschafft!');
        expect(turn.badgeLabel, isNull);
        expect(turn.cardMessage, isNot(contains('schwerer')));
        expect(turn.rewardLabel, isNot(contains('Serie')));
        expect(turn.rewardLabel, isNot(contains('Verbesserung')));
      }
    });

    test('guided answers cannot seed a later independent success streak', () {
      final engine = LumoLearningFeedbackEngine();
      for (var i = 1; i <= 3; i++) {
        engine.record(_correctEvent(taskIndex: i, helpUsed: true));
      }
      final next = engine.record(_correctEvent(taskIndex: 4));
      expect(next.tone, isNot(LumoFeedbackTone.streak));
      expect(next.badgeLabel, isNull);
      engine.record(_correctEvent(taskIndex: 5));
      expect(engine.record(_correctEvent(taskIndex: 6)).badgeLabel,
          'Mini-Abzeichen: 3er-Fuchsserie');
      expect(engine.record(_correctEvent(taskIndex: 7)).tone,
          LumoFeedbackTone.streak);
    });

    test('practice does not erase an existing independent series', () {
      final engine = LumoLearningFeedbackEngine();
      engine.record(_correctEvent(taskIndex: 1));
      engine.record(_correctEvent(taskIndex: 2));
      final guided = engine.record(_correctEvent(taskIndex: 3, helpUsed: true));
      expect(guided.badgeLabel, isNull);
      engine.record(_wrongEvent(taskIndex: 4, helpUsed: true));
      expect(engine.record(_correctEvent(taskIndex: 5)).badgeLabel,
          'Mini-Abzeichen: 3er-Fuchsserie');
    });

    test('guided mistakes do not produce an independent wrong-answer series',
        () {
      final engine = LumoLearningFeedbackEngine();
      for (var i = 1; i <= 3; i++) {
        final guided = engine.record(_wrongEvent(taskIndex: i, helpUsed: true));
        expect(guided.tone, LumoFeedbackTone.coaching);
        expect(guided.autoAdvanceDelayMs, 0);
      }
      expect(engine.record(_wrongEvent(taskIndex: 4)).tone,
          LumoFeedbackTone.coaching);
    });

    test('fast guided answers cannot seed an independent speed badge', () {
      final engine = LumoLearningFeedbackEngine();
      for (var i = 1; i <= 3; i++) {
        engine.record(
            _correctEvent(taskIndex: i, helpUsed: true, responseTimeMs: 1000));
      }
      final next =
          engine.record(_correctEvent(taskIndex: 4, responseTimeMs: 1000));
      expect(next.badgeLabel, isNull);
      expect(next.tone, isNot(LumoFeedbackTone.streak));
    });
  });
}

LumoInteractionEvent _wrongEvent(
    {required int taskIndex, bool helpUsed = false}) {
  return LumoInteractionEvent(
    subject: 'Mathematik',
    unit: 'Plus bis 10',
    prompt: '3 + 2 = ?',
    correctAnswer: 5,
    givenAnswer: 4,
    correct: false,
    helpUsed: helpUsed,
    responseTimeMs: 8200,
    errorTypes: const <ErrorType>[ErrorType.countingError],
    masteryBefore: .2,
    masteryAfter: .18,
    taskIndex: taskIndex,
    totalTasks: 10,
    sessionKind: 'exerciseSet',
  );
}

LumoInteractionEvent _correctEvent({
  required int taskIndex,
  bool helpUsed = false,
  int responseTimeMs = 5200,
}) {
  return LumoInteractionEvent(
    subject: 'Mathematik',
    unit: 'Plus bis 10',
    prompt: '3 + 2 = ?',
    correctAnswer: 5,
    givenAnswer: 5,
    correct: true,
    helpUsed: helpUsed,
    responseTimeMs: responseTimeMs,
    errorTypes: const <ErrorType>[],
    masteryBefore: .2,
    masteryAfter: .25,
    taskIndex: taskIndex,
    totalTasks: 10,
    sessionKind: 'exerciseSet',
  );
}
