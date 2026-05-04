import 'app_settings.dart';
import 'lumo_ai_learning_access.dart';
import 'lumo_ai_learning_policy_bridge.dart';

class LumoAiPolicyGuard {
  const LumoAiPolicyGuard();

  bool allows(AppSettings settings, LumoAiLearningArea area) {
    return settings.lumoAiLearningAccess.allows(area);
  }

  String blockedMessageFor(LumoAiLearningArea area) {
    switch (area) {
      case LumoAiLearningArea.chat:
        return 'Der KI-Chat ist im Elternbereich ausgeschaltet.';
      case LumoAiLearningArea.taskHelp:
        return 'Die KI-Aufgabenhilfe ist im Elternbereich ausgeschaltet.';
      case LumoAiLearningArea.readingHelp:
        return 'Die KI-Lesehilfe ist im Elternbereich ausgeschaltet.';
      case LumoAiLearningArea.testReview:
        return 'Die KI-Auswertung für Tests und Schularbeiten ist im Elternbereich ausgeschaltet.';
      case LumoAiLearningArea.scanner:
        return 'Die KI-Scannerhilfe ist im Elternbereich ausgeschaltet.';
    }
  }
}
