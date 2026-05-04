import 'app_settings.dart';
import 'lumo_ai_learning_access.dart';

extension AppSettingsAiLearningPolicy on AppSettings {
  LumoAiLearningMode get lumoAiLearningMode {
    if (!aiProxyEnabled) return LumoAiLearningMode.off;
    return aiLearningMode.toLumoAiLearningMode();
  }

  LumoAiLearningAccess get lumoAiLearningAccess {
    return LumoAiLearningAccess(mode: lumoAiLearningMode);
  }
}

extension AiLearningModeBridge on AiLearningMode {
  LumoAiLearningMode toLumoAiLearningMode() {
    switch (this) {
      case AiLearningMode.chatOnly:
        return LumoAiLearningMode.chatOnly;
      case AiLearningMode.learningHelp:
        return LumoAiLearningMode.learningHelp;
      case AiLearningMode.readingHelp:
        return LumoAiLearningMode.readingHelp;
      case AiLearningMode.fullCoach:
        return LumoAiLearningMode.fullCoach;
    }
  }
}

extension LumoAiLearningModeBridge on LumoAiLearningMode {
  AiLearningMode toAppAiLearningMode() {
    switch (this) {
      case LumoAiLearningMode.off:
      case LumoAiLearningMode.chatOnly:
        return AiLearningMode.chatOnly;
      case LumoAiLearningMode.learningHelp:
        return AiLearningMode.learningHelp;
      case LumoAiLearningMode.readingHelp:
        return AiLearningMode.readingHelp;
      case LumoAiLearningMode.fullCoach:
        return AiLearningMode.fullCoach;
    }
  }
}
