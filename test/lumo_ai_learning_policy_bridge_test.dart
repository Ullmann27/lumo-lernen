import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_ai_learning_access.dart';
import 'package:lumo_lernen/core/lumo_ai_learning_policy_bridge.dart';

void main() {
  group('AppSettingsAiLearningPolicy', () {
    test('returns off when proxy is disabled even if mode is fullCoach', () {
      const settings = AppSettings(aiLearningMode: AiLearningMode.fullCoach);

      expect(settings.lumoAiLearningMode, LumoAiLearningMode.off);
      expect(settings.lumoAiLearningAccess.allows(LumoAiLearningArea.chat), isFalse);
    });

    test('maps chatOnly when proxy is enabled', () {
      const settings = AppSettings(aiProxyEnabled: true);

      expect(settings.lumoAiLearningMode, LumoAiLearningMode.chatOnly);
      expect(settings.lumoAiLearningAccess.allows(LumoAiLearningArea.chat), isTrue);
      expect(settings.lumoAiLearningAccess.allows(LumoAiLearningArea.taskHelp), isFalse);
    });

    test('maps every enabled parent mode to runtime policy', () {
      const cases = <AiLearningMode, LumoAiLearningMode>{
        AiLearningMode.chatOnly: LumoAiLearningMode.chatOnly,
        AiLearningMode.learningHelp: LumoAiLearningMode.learningHelp,
        AiLearningMode.readingHelp: LumoAiLearningMode.readingHelp,
        AiLearningMode.fullCoach: LumoAiLearningMode.fullCoach,
      };

      for (final entry in cases.entries) {
        final settings = AppSettings(aiProxyEnabled: true, aiLearningMode: entry.key);
        expect(settings.lumoAiLearningMode, entry.value);
      }
    });

    test('maps runtime mode back to persistable app mode', () {
      expect(LumoAiLearningMode.off.toAppAiLearningMode(), AiLearningMode.chatOnly);
      expect(LumoAiLearningMode.chatOnly.toAppAiLearningMode(), AiLearningMode.chatOnly);
      expect(LumoAiLearningMode.learningHelp.toAppAiLearningMode(), AiLearningMode.learningHelp);
      expect(LumoAiLearningMode.readingHelp.toAppAiLearningMode(), AiLearningMode.readingHelp);
      expect(LumoAiLearningMode.fullCoach.toAppAiLearningMode(), AiLearningMode.fullCoach);
    });
  });
}
