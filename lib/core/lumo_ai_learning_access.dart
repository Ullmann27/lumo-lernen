enum LumoAiLearningMode {
  off,
  chatOnly,
  learningHelp,
  readingHelp,
  fullCoach,
}

enum LumoAiLearningArea {
  chat,
  taskHelp,
  readingHelp,
  testReview,
  scanner,
}

class LumoAiLearningAccess {
  const LumoAiLearningAccess({required this.mode});

  final LumoAiLearningMode mode;

  bool allows(LumoAiLearningArea area) {
    switch (mode) {
      case LumoAiLearningMode.off:
        return false;
      case LumoAiLearningMode.chatOnly:
        return area == LumoAiLearningArea.chat;
      case LumoAiLearningMode.learningHelp:
        return area == LumoAiLearningArea.chat || area == LumoAiLearningArea.taskHelp;
      case LumoAiLearningMode.readingHelp:
        return area == LumoAiLearningArea.chat || area == LumoAiLearningArea.readingHelp;
      case LumoAiLearningMode.fullCoach:
        return true;
    }
  }

  bool get allowsAnyLearningHelp =>
      allows(LumoAiLearningArea.taskHelp) || allows(LumoAiLearningArea.readingHelp);

  static LumoAiLearningMode fromSettings({
    required bool aiEnabled,
    bool allowLearningHelp = false,
    bool allowReadingHelp = false,
    bool allowTestReview = false,
    bool allowScanner = false,
  }) {
    if (!aiEnabled) return LumoAiLearningMode.off;
    if (allowLearningHelp && allowReadingHelp && allowTestReview && allowScanner) {
      return LumoAiLearningMode.fullCoach;
    }
    if (allowLearningHelp) return LumoAiLearningMode.learningHelp;
    if (allowReadingHelp) return LumoAiLearningMode.readingHelp;
    return LumoAiLearningMode.chatOnly;
  }
}
