import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/core/scanned_task_fallback_policy.dart';
import 'package:lumo_lernen/core/scanned_work_analysis.dart';
import 'package:lumo_lernen/core/scanned_work_task_fallback.dart';

void main() {
  group('ScannedTaskFallbackPolicy', () {
    const policy = ScannedTaskFallbackPolicy();

    test('parses simple subtraction and generates multiple-choice answers', () {
      final fallback = policy.analyze(
        rawText: '18 - 5 = ?',
        subject: 'Mathematik',
        unit: 'Minus bis 20',
        grade: 1,
      );

      expect(fallback.route, RecognizedTaskRoute.multipleChoice);
      expect(fallback.correctAnswer, '13');
      expect(fallback.choices, contains('13'));
      expect(fallback.choices.toSet(), hasLength(fallback.choices.length));
      expect(fallback.choices.length, 4);
    });

    test('parses multiplication sign variants', () {
      final result = policy.parseSimpleMath('3 × 4 = ?');

      expect(result, isNotNull);
      expect(result!.answer, 12);
      expect(result.operation, 'multiplication');
    });

    test('routes readable open task to free text fallback', () {
      final fallback = policy.analyze(
        rawText: 'Schreibe ein Wort mit St am Anfang.',
        subject: 'Deutsch',
        unit: 'Rechtschreibung',
        grade: 1,
      );

      expect(fallback.route, RecognizedTaskRoute.freeText);
      expect(fallback.isSolvable, isTrue);
      expect(fallback.choices, isEmpty);
      expect(fallback.requiresParentReview, isFalse);
    });

    test('routes low confidence OCR to parent review', () {
      final fallback = policy.analyze(
        rawText: '18 - ??? ###',
        subject: 'Mathematik',
        unit: 'Minus bis 20',
        grade: 1,
        ocrConfidence: .31,
      );

      expect(fallback.route, RecognizedTaskRoute.parentReview);
      expect(fallback.requiresParentReview, isTrue);
      expect(fallback.isSolvable, isFalse);
    });

    test('ScannedWorkAnalysis exposes recognized task fallback', () {
      final analysis = const ScannedWorkAnalysisEngine().analyze(
        rawText: '7 + 6 = ?',
        grade: 1,
        existingSkills: const {},
      );

      final fallback = analysis.buildRecognizedTaskFallback(grade: 1);

      expect(fallback.route, RecognizedTaskRoute.multipleChoice);
      expect(fallback.correctAnswer, '13');
      expect(fallback.choices, contains('13'));
    });
  });
}
