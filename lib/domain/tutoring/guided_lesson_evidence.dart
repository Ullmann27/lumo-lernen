import '../../core/learning_journey.dart';
import '../../core/discovery_progress.dart';
import '../../core/tutor_coordination_engine.dart';
import 'guided_lesson_catalog.dart';

/// An answer pattern is an observation, never a diagnosis of its cause.
/// Retrying after correctness feedback is accompanied practice too.
abstract final class GuidedLessonEvidence {
  /// A targeted question follows a visible answer relationship. It does not
  /// assert why the child answered that way or label their general ability.
  static String? hintForAnswer({
    required GuidedLesson lesson,
    required GuidedLessonStep step,
    required String? answer,
  }) {
    if (lesson.concept != GuidedLessonConcept.bridgeTen ||
        step.answerKind != GuidedAnswerKind.sum ||
        answer == null)
      return null;
    final value = int.tryParse(answer.trim());
    if (value == step.a + step.b - 10) {
      return 'Diese Zahl passt zu den Äpfeln neben dem vollen Zehnerfeld. '
          'Prüfe, ob du den vollen Zehner auch mitgezählt hast.';
    }
    if (value == 10 - step.a) {
      return 'Diese Zahl füllt die freien Plätze bis zehn. '
          'Welche Äpfel bleiben danach noch von den ${step.b} übrig?';
    }
    if (value == 10) {
      return 'Der Zehner ist voll. Prüfe jetzt die Äpfel daneben: '
          'Sind von den ${step.b} noch welche übrig?';
    }
    return null;
  }

  static bool isIndependent({required int attempts, required int helpLevel}) =>
      attempts == 1 && helpLevel == 0;

  static LearningEvidence observation({
    required GuidedLesson lesson,
    required GuidedLessonStep step,
    required String attemptId,
    required String answer,
    required int attempts,
    required int helpLevel,
  }) {
    if (!step.isIndependent || attempts < 1 || helpLevel < 0 || helpLevel > 3) {
      throw ArgumentError('Expected a real independent lesson question');
    }
    final correct = step.accepts(answer);
    final independent = isIndependent(attempts: attempts, helpLevel: helpLevel);
    final number = int.tryParse(answer.trim());
    String? pattern;
    if (!correct && lesson.concept == GuidedLessonConcept.bridgeTen) {
      if (number == step.a + step.b - 10) {
        pattern = 'answer_equals_remainder';
      } else if (number == 10 - step.a) {
        pattern = 'answer_equals_gap_to_ten';
      } else if (number == 10) {
        pattern = 'answer_stops_at_ten';
      } else {
        pattern = 'bridge_ten_other_answer';
      }
    }
    return LearningEvidence(
      taskId: attemptId,
      problemId: TutorTaskScope.problemIdentity(
        lesson.subject,
        lesson.schoolUnit,
        step.instruction,
      ),
      correct: correct,
      helpLevel: independent ? 0 : (helpLevel == 0 ? 1 : helpLevel),
      transferCheck:
          correct && independent && step.observation == DiscoveryStepKind.check,
      errorTag: pattern,
    );
  }
}
