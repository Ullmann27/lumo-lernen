import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_ai_learning_access.dart';

void main() {
  group('LumoAiLearningAccess', () {
    test('off blocks every area', () {
      const access = LumoAiLearningAccess(mode: LumoAiLearningMode.off);
      for (final area in LumoAiLearningArea.values) {
        expect(access.allows(area), isFalse);
      }
    });

    test('chatOnly allows only chat', () {
      const access = LumoAiLearningAccess(mode: LumoAiLearningMode.chatOnly);
      expect(access.allows(LumoAiLearningArea.chat), isTrue);
      expect(access.allows(LumoAiLearningArea.taskHelp), isFalse);
      expect(access.allows(LumoAiLearningArea.readingHelp), isFalse);
    });

    test('learningHelp allows task help but not scanner', () {
      const access = LumoAiLearningAccess(mode: LumoAiLearningMode.learningHelp);
      expect(access.allows(LumoAiLearningArea.chat), isTrue);
      expect(access.allows(LumoAiLearningArea.taskHelp), isTrue);
      expect(access.allows(LumoAiLearningArea.scanner), isFalse);
    });

    test('fullCoach allows every area', () {
      const access = LumoAiLearningAccess(mode: LumoAiLearningMode.fullCoach);
      for (final area in LumoAiLearningArea.values) {
        expect(access.allows(area), isTrue);
      }
    });
  });
}
