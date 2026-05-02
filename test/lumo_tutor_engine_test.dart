import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_tutor_contracts.dart';
import 'package:lumo_lernen/core/lumo_tutor_engine.dart';

void main() {
  group('LumoTutorEngine.decideHelpLevel', () {
    const engine = LumoTutorEngine();

    test('returns hintOnly without premium', () {
      expect(
        engine.decideHelpLevel(
          attemptCount: 5,
          hasRepeatedWeakness: true,
          premiumEnabled: false,
        ),
        LumoTutorHelpLevel.hintOnly,
      );
    });

    test('escalates with attemptCount when premium is enabled', () {
      expect(
        engine.decideHelpLevel(
          attemptCount: 1,
          hasRepeatedWeakness: false,
          premiumEnabled: true,
        ),
        LumoTutorHelpLevel.hintOnly,
      );
      expect(
        engine.decideHelpLevel(
          attemptCount: 2,
          hasRepeatedWeakness: false,
          premiumEnabled: true,
        ),
        LumoTutorHelpLevel.guidedStep,
      );
      expect(
        engine.decideHelpLevel(
          attemptCount: 3,
          hasRepeatedWeakness: false,
          premiumEnabled: true,
        ),
        LumoTutorHelpLevel.visualExplanation,
      );
    });

    test('repeated weakness escalates to visualExplanation', () {
      expect(
        engine.decideHelpLevel(
          attemptCount: 1,
          hasRepeatedWeakness: true,
          premiumEnabled: true,
        ),
        LumoTutorHelpLevel.visualExplanation,
      );
    });
  });

  group('LumoTutorEngine.decideMode', () {
    const engine = LumoTutorEngine();

    test('testReview wins when isTestReview is true', () {
      expect(
        engine.decideMode(
          attemptCount: 1,
          hasRepeatedWeakness: false,
          isTestReview: true,
        ),
        LumoTutorMode.testReview,
      );
    });

    test('miniLesson is used at 3+ attempts', () {
      expect(
        engine.decideMode(
          attemptCount: 3,
          hasRepeatedWeakness: false,
          isTestReview: false,
        ),
        LumoTutorMode.miniLesson,
      );
    });

    test('mistakeExplanation is used at 2 attempts', () {
      expect(
        engine.decideMode(
          attemptCount: 2,
          hasRepeatedWeakness: false,
          isTestReview: false,
        ),
        LumoTutorMode.mistakeExplanation,
      );
    });

    test('practiceHint is the default mode', () {
      expect(
        engine.decideMode(
          attemptCount: 1,
          hasRepeatedWeakness: false,
          isTestReview: false,
        ),
        LumoTutorMode.practiceHint,
      );
    });
  });

  group('LumoTutorEngine local fallback', () {
    const engine = LumoTutorEngine();

    test('buildLocalFallback does not give live help in test mode', () {
      final response = engine.buildLocalFallback(
        const LumoTutorRequest(
          mode: LumoTutorMode.testReview,
          subject: LumoTutorSubject.mathematik,
          grade: 1,
          unit: 'Plus bis 10',
          helpLevel: LumoTutorHelpLevel.visualExplanation,
          currentPrompt: '3 + 2 = ?',
          correctAnswer: '5',
          attemptCount: 3,
        ),
      );

      expect(response.source, 'local_tutor_engine_v1');
      expect(response.shortHint, 'Auswertung nach dem Test');
      expect(response.speech, contains('nach dem Test'));
    });

    test('suggestVisualPlan returns tenFrame for small plus tasks', () {
      final visualPlan = engine.suggestVisualPlan(
        const LumoTutorRequest(
          mode: LumoTutorMode.miniLesson,
          subject: LumoTutorSubject.mathematik,
          grade: 1,
          unit: 'Plus bis 10',
          helpLevel: LumoTutorHelpLevel.visualExplanation,
          currentPrompt: '3 + 2 = ?',
          correctAnswer: '5',
          attemptCount: 3,
        ),
      );

      expect(visualPlan.type, LumoTutorVisualType.tenFrame);
      expect(visualPlan.left, 3);
      expect(visualPlan.right, 2);
    });

    test('suggestVisualPlan returns syllable chips for German syllables', () {
      final visualPlan = engine.suggestVisualPlan(
        const LumoTutorRequest(
          mode: LumoTutorMode.miniLesson,
          subject: LumoTutorSubject.deutsch,
          grade: 1,
          unit: 'Silben',
          helpLevel: LumoTutorHelpLevel.visualExplanation,
          currentPrompt: 'Wie viele Silben hat Banane?',
          correctAnswer: 'Banane',
          attemptCount: 3,
        ),
      );

      expect(visualPlan.type, LumoTutorVisualType.syllableChips);
      expect(visualPlan.word, 'Banane');
    });
  });
}
