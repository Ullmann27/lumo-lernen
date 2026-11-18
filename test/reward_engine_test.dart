import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/learning/reward_engine.dart';

void main() {
  const engine = RewardEngine();

  TaskResult result({required bool correct, bool helpUsed = false}) =>
      TaskResult(
        taskInstanceId: 'task',
        childId: 'child',
        skillId: const SkillId('addition'),
        correct: correct,
        responseTimeMs: 1200,
        helpUsed: helpUsed,
        // A writing score must not accidentally award an incorrect answer.
        handwritingScore: correct ? null : .60,
      );

  test('a wrong test or schoolwork answer never costs stars', () {
    // Previously this deducted 2 stars. Rewards reflect what succeeded; a
    // mistake in a test is information, not something to be punished.
    for (final mode in [
      LearningMode.exam,
      LearningMode.subjectTest,
      LearningMode.blitzTest,
      LearningMode.weaknessTest,
    ]) {
      final delta = engine.calculateAnswerReward(
        result: result(correct: false),
        mode: mode,
        completedSession: true,
      );
      expect(delta.stars, 0, reason: '$mode');
      expect(delta.xp, 0, reason: '$mode');
      expect(delta.reasons, isEmpty, reason: '$mode');
      expect(
        const RewardState(childId: 'child', stars: 1, xp: 10)
            .apply(delta)
            .stars,
        1,
        reason: 'the stars the child already has stay untouched',
      );
    }
  });

  test('wrong answers remain neutral in learning sessions', () {
    for (final mode in [
      LearningMode.practice,
      LearningMode.tutoring,
      LearningMode.subjectTest,
    ]) {
      for (final helpUsed in [true, false]) {
        final delta = engine.calculateAnswerReward(
          result: result(correct: false, helpUsed: helpUsed),
          mode: mode,
          completedSession: true,
        );
        expect(delta.isEmpty, isTrue, reason: '$mode / $helpUsed');
      }
    }
  });

  test('solved alone is worth clearly more than solved together', () {
    final alone = engine.calculateAnswerReward(result: result(correct: true));
    final together = engine.calculateAnswerReward(
        result: result(correct: true, helpUsed: true));

    expect(alone.stars, RewardEngine.independentStars);
    expect(alone.stars, 6);
    expect(alone.xp, 25);
    expect(alone.reasons, contains(RewardReason.correctAnswer));

    expect(together.stars, RewardEngine.assistedStars);
    expect(together.stars, 2);
    expect(together.xp, 10);
    expect(together.reasons, contains(RewardReason.usedHelpAndFinished));
    expect(together.reasons, isNot(contains(RewardReason.correctAnswer)));

    // No bonus may bring a helped answer close to an independent one.
    expect(alone.stars, greaterThanOrEqualTo(together.stars * 3));
  });

  test('correct exam answers receive the independent reward and exam XP', () {
    final delta = engine.calculateAnswerReward(
      result: result(correct: true),
      mode: LearningMode.exam,
    );
    expect(delta.stars, 6);
    expect(delta.xp, 35);
    expect(delta.reasons, contains(RewardReason.correctAnswer));
    expect(delta.reasons, contains(RewardReason.completedTest));
  });

  test('finishing a tutoring session adds its bonus to both kinds', () {
    final alone = engine.calculateAnswerReward(
      result: result(correct: true),
      mode: LearningMode.tutoring,
      completedSession: true,
    );
    final together = engine.calculateAnswerReward(
      result: result(correct: true, helpUsed: true),
      mode: LearningMode.tutoring,
      completedSession: true,
    );
    expect(alone.stars, 9);
    expect(together.stars, 5);
    expect(alone.reasons, contains(RewardReason.tutoringSessionFinished));
  });
}
