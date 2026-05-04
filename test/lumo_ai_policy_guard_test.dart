import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_ai_learning_access.dart';
import 'package:lumo_lernen/core/lumo_ai_policy_guard.dart';

void main() {
  const guard = LumoAiPolicyGuard();

  group('LumoAiPolicyGuard', () {
    test('blocks all areas when AI proxy is disabled', () {
      const settings = AppSettings(
        aiProxyEnabled: false,
        aiLearningMode: AiLearningMode.fullCoach,
      );

      for (final area in LumoAiLearningArea.values) {
        expect(guard.allows(settings, area), isFalse);
      }
    });

    test('chatOnly allows only chat', () {
      const settings = AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.chatOnly,
      );

      expect(guard.allows(settings, LumoAiLearningArea.chat), isTrue);
      expect(guard.allows(settings, LumoAiLearningArea.taskHelp), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.readingHelp), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.testReview), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.scanner), isFalse);
    });

    test('learningHelp allows chat and task help', () {
      const settings = AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.learningHelp,
      );

      expect(guard.allows(settings, LumoAiLearningArea.chat), isTrue);
      expect(guard.allows(settings, LumoAiLearningArea.taskHelp), isTrue);
      expect(guard.allows(settings, LumoAiLearningArea.readingHelp), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.testReview), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.scanner), isFalse);
    });

    test('readingHelp allows chat and reading help', () {
      const settings = AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.readingHelp,
      );

      expect(guard.allows(settings, LumoAiLearningArea.chat), isTrue);
      expect(guard.allows(settings, LumoAiLearningArea.taskHelp), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.readingHelp), isTrue);
      expect(guard.allows(settings, LumoAiLearningArea.testReview), isFalse);
      expect(guard.allows(settings, LumoAiLearningArea.scanner), isFalse);
    });

    test('fullCoach allows all areas', () {
      const settings = AppSettings(
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.fullCoach,
      );

      for (final area in LumoAiLearningArea.values) {
        expect(guard.allows(settings, area), isTrue);
      }
    });

    test('returns friendly blocked messages for every area', () {
      expect(guard.blockedMessageFor(LumoAiLearningArea.chat), contains('KI-Chat'));
      expect(guard.blockedMessageFor(LumoAiLearningArea.taskHelp), contains('Aufgabenhilfe'));
      expect(guard.blockedMessageFor(LumoAiLearningArea.readingHelp), contains('Lesehilfe'));
      expect(guard.blockedMessageFor(LumoAiLearningArea.testReview), contains('Tests'));
      expect(guard.blockedMessageFor(LumoAiLearningArea.scanner), contains('Scannerhilfe'));
    });
  });
}
