import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/learning/reward_engine.dart';

void main() {
  const engine = RewardEngine();
  const before = SkillState(childId: 'child', skillId: SkillId('addition'));

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

  test(
    'incorrect final exam answer deducts stars without completion bonuses',
    () {
      final delta = engine.calculateAnswerReward(
        result: result(correct: false),
        before: before,
        after: before,
        allowRetry: false,
        firstAttempt: true,
        mode: LearningMode.exam,
        completedSession: true,
      );

      expect(delta.stars, -2);
      expect(delta.xp, 0);
      expect(delta.deductionAmount, 2);
      expect(delta.reasons, isEmpty);
      expect(
        const RewardState(
          childId: 'child',
          stars: 1,
          xp: 10,
        ).apply(delta).stars,
        0,
      );
    },
  );

  test('incorrect retryable answers remain neutral in learning sessions', () {
    for (final mode in [
      LearningMode.practice,
      LearningMode.tutoring,
      LearningMode.subjectTest,
    ]) {
      for (final firstAttempt in [true, false]) {
        final delta = engine.calculateAnswerReward(
          result: result(correct: false),
          before: before,
          after: before,
          allowRetry: true,
          firstAttempt: firstAttempt,
          mode: mode,
          completedSession: true,
        );
        expect(delta.isEmpty, isTrue, reason: '$mode / $firstAttempt');
      }
    }
  });

  test('correct exam answers still receive correctness and exam bonuses', () {
    final delta = engine.calculateAnswerReward(
      result: result(correct: true),
      before: before,
      after: before,
      allowRetry: false,
      firstAttempt: true,
      mode: LearningMode.exam,
    );
    expect(delta.stars, 4);
    expect(delta.xp, 35);
    expect(delta.reasons, contains(RewardReason.correctAnswer));
    expect(delta.reasons, contains(RewardReason.completedTest));
  });

  test(
    'final wrong answer after a hint follows the existing no-deduction rule',
    () {
      final delta = engine.calculateAnswerReward(
        result: result(correct: false, helpUsed: true),
        before: before,
        after: before,
        allowRetry: false,
        firstAttempt: false,
        mode: LearningMode.exam,
      );
      expect(delta.isEmpty, isTrue);
    },
  );
}
