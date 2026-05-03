import 'lumo_ai_learning_access.dart';
import 'lumo_tutor_contracts.dart';
import 'lumo_tutor_engine.dart';

class LumoLearningHelpDecision {
  const LumoLearningHelpDecision({
    required this.shouldShowHelp,
    required this.shouldSpeakHelp,
    required this.aiAllowed,
    required this.response,
  });

  const LumoLearningHelpDecision.none()
      : shouldShowHelp = false,
        shouldSpeakHelp = false,
        aiAllowed = false,
        response = null;

  final bool shouldShowHelp;
  final bool shouldSpeakHelp;
  final bool aiAllowed;
  final LumoTutorResponse? response;
}

class LumoLearningHelpOrchestrator {
  const LumoLearningHelpOrchestrator({
    this.engine = const LumoTutorEngine(),
  });

  final LumoTutorEngine engine;

  LumoLearningHelpDecision decideAfterWrongAnswer({
    required int attemptCount,
    required bool helpAllowed,
    required bool isTestLike,
    required LumoAiLearningAccess aiAccess,
    required LumoTutorSubject subject,
    required int grade,
    required String unit,
    required String prompt,
    required String childAnswer,
    required String correctAnswer,
    List<String> weaknessTags = const <String>[],
  }) {
    if (!helpAllowed || isTestLike || attemptCount < 2) {
      return const LumoLearningHelpDecision.none();
    }

    final helpLevel = engine.decideHelpLevel(
      attemptCount: attemptCount,
      hasRepeatedWeakness: weaknessTags.isNotEmpty && attemptCount >= 2,
      premiumEnabled: true,
    );
    final mode = engine.decideMode(
      attemptCount: attemptCount,
      hasRepeatedWeakness: weaknessTags.isNotEmpty && attemptCount >= 2,
      isTestReview: false,
    );
    final request = LumoTutorRequest(
      mode: mode,
      subject: subject,
      grade: grade,
      unit: unit,
      helpLevel: helpLevel,
      currentPrompt: prompt,
      childAnswer: childAnswer,
      correctAnswer: correctAnswer,
      attemptCount: attemptCount,
      weaknessTags: weaknessTags,
    );
    final response = engine.buildLocalFallback(request);
    return LumoLearningHelpDecision(
      shouldShowHelp: true,
      shouldSpeakHelp: true,
      aiAllowed: aiAccess.allows(LumoAiLearningArea.taskHelp),
      response: response,
    );
  }
}
