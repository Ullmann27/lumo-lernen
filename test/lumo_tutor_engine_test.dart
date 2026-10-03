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

    test('multiplication help uses equal groups instead of a plus visual', () {
      const request = LumoTutorRequest(
        mode: LumoTutorMode.mistakeExplanation,
        subject: LumoTutorSubject.mathematik,
        grade: 2,
        unit: 'Einmaleins',
        helpLevel: LumoTutorHelpLevel.guidedStep,
        currentPrompt: '3 × 4 = ?',
        correctAnswer: '12',
        attemptCount: 2,
      );
      final response = engine.buildLocalFallback(request);
      expect(
          response.speech, contains('3 gleich große Gruppen mit je 4 Dingen'));
      expect(response.speech, isNot(contains('12')));
      expect(response.visualPlan.type, LumoTutorVisualType.none);
    });

    test(
        'fraction and non-arithmetic questions do not become unrelated apple sums',
        () {
      const request = LumoTutorRequest(
        mode: LumoTutorMode.miniLesson,
        subject: LumoTutorSubject.mathematik,
        grade: 4,
        unit: 'Brüche erweitern',
        helpLevel: LumoTutorHelpLevel.visualExplanation,
        currentPrompt: 'Erweitere 1/2 mit 3.',
        correctAnswer: '3/6',
      );
      expect(engine.suggestVisualPlan(request).type, LumoTutorVisualType.none);
    });

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
          correctAnswer: '3',
          attemptCount: 3,
        ),
      );

      expect(visualPlan.type, LumoTutorVisualType.syllableChips);
      expect(visualPlan.word, 'Banane');
      expect(visualPlan.parts, ['Ba', 'na', 'ne']);
    });

    test('sound visuals use the questioned word and do not reveal a choice answer', () {
      final target = engine.suggestVisualPlan(const LumoTutorRequest(
        mode: LumoTutorMode.miniLesson, subject: LumoTutorSubject.deutsch,
        grade: 1, unit: 'Endlaute', helpLevel: LumoTutorHelpLevel.visualExplanation,
        currentPrompt: 'Mit welchem Laut endet Hund?', correctAnswer: 'T',
      ));
      expect(target.word, 'Hund');
      expect(target.highlight, 'end');
      final chooseWord = engine.suggestVisualPlan(const LumoTutorRequest(
        mode: LumoTutorMode.practiceHint, subject: LumoTutorSubject.deutsch,
        grade: 1, unit: 'Endlaute', helpLevel: LumoTutorHelpLevel.hintOnly,
        currentPrompt: 'Welches Wort endet mit T?', correctAnswer: 'Hund',
      ));
      expect(chooseWord.type, LumoTutorVisualType.none);
    });
  });
}
