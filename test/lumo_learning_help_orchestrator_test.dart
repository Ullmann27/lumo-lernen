import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_ai_learning_access.dart';
import 'package:lumo_lernen/core/lumo_learning_help_orchestrator.dart';
import 'package:lumo_lernen/core/lumo_tutor_contracts.dart';

void main() {
  const orchestrator = LumoLearningHelpOrchestrator();

  group('LumoLearningHelpOrchestrator', () {
    test('does not show help before the second wrong attempt', () {
      final decision = orchestrator.decideAfterWrongAnswer(
        attemptCount: 1,
        helpAllowed: true,
        isTestLike: false,
        aiAccess: const LumoAiLearningAccess(mode: LumoAiLearningMode.fullCoach),
        subject: LumoTutorSubject.mathematik,
        grade: 1,
        unit: 'Plus bis 10',
        prompt: '3 + 2 = ?',
        childAnswer: '4',
        correctAnswer: '5',
      );

      expect(decision.shouldShowHelp, isFalse);
      expect(decision.response, isNull);
    });

    test('shows and speaks local help from the second wrong attempt', () {
      final decision = orchestrator.decideAfterWrongAnswer(
        attemptCount: 2,
        helpAllowed: true,
        isTestLike: false,
        aiAccess: const LumoAiLearningAccess(mode: LumoAiLearningMode.chatOnly),
        subject: LumoTutorSubject.deutsch,
        grade: 1,
        unit: 'Silben',
        prompt: 'Wie viele Silben hat Banane?',
        childAnswer: '2',
        correctAnswer: '3',
      );

      expect(decision.shouldShowHelp, isTrue);
      expect(decision.shouldSpeakHelp, isTrue);
      expect(decision.aiAllowed, isFalse);
      expect(decision.response, isNotNull);
      expect(decision.response!.speech, isNotEmpty);
    });

    test('allows ai task help only when parent mode permits learning help', () {
      final decision = orchestrator.decideAfterWrongAnswer(
        attemptCount: 2,
        helpAllowed: true,
        isTestLike: false,
        aiAccess: const LumoAiLearningAccess(mode: LumoAiLearningMode.learningHelp),
        subject: LumoTutorSubject.mathematik,
        grade: 1,
        unit: 'Plus bis 10',
        prompt: '7 + 1 = ?',
        childAnswer: '9',
        correctAnswer: '8',
      );

      expect(decision.shouldShowHelp, isTrue);
      expect(decision.aiAllowed, isTrue);
    });

    test('blocks help during tests or schoolwork-like sessions', () {
      final decision = orchestrator.decideAfterWrongAnswer(
        attemptCount: 3,
        helpAllowed: true,
        isTestLike: true,
        aiAccess: const LumoAiLearningAccess(mode: LumoAiLearningMode.fullCoach),
        subject: LumoTutorSubject.mathematik,
        grade: 1,
        unit: 'Test',
        prompt: '5 + 2 = ?',
        childAnswer: '6',
        correctAnswer: '7',
      );

      expect(decision.shouldShowHelp, isFalse);
      expect(decision.aiAllowed, isFalse);
    });
  });
}
