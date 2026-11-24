import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_tutor_contracts.dart';
import 'package:lumo_lernen/core/lumo_tutor_engine.dart';
import 'package:lumo_lernen/domain/learning/error_detective.dart';
import 'package:lumo_lernen/domain/learning/whole_arithmetic.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/error_patterns.dart';

void main() {
  const detective = ErrorDetective();
  const teacher = ErrorPatternDetector();
  const tutor = LumoTutorEngine();

  ErrorDetection detect(String prompt, String expected, String given) =>
      detective.analyze(subject: 'Mathematik', prompt: prompt,
          correctAnswer: expected, givenAnswer: given);

  Attempt attempt(String prompt, String expected, String given) => Attempt(
    id: 'test', studentId: 'demo', subject: 'Mathematik', unit: 'Plus und Minus',
    competency: 'test', correct: false, at: DateTime.utc(2026),
    prompt: prompt, expected: expected, given: given,
  );

  LumoTutorRequest request(String prompt, String expected, String given,
          {LumoTutorMode mode = LumoTutorMode.mistakeExplanation}) =>
      LumoTutorRequest(mode: mode, subject: LumoTutorSubject.mathematik,
          grade: 2, unit: 'Plus bis 100',
          helpLevel: LumoTutorHelpLevel.guidedStep, currentPrompt: prompt,
          correctAnswer: expected, childAnswer: given, attemptCount: 1);

  test('whole-number parser verifies entire prompt and stored solution', () {
    expect(WholeArithmetic.parse('37 + 25 = ?', expected: '62')!.result, 62);
    expect(WholeArithmetic.parse('Schriftlich: 52 − 27 = ?', expected: '25')!.result, 25);
    expect(WholeArithmetic.parse('Rechne 12 : 3.', expected: '4')!.result, 4);
    expect(WholeArithmetic.parse('37 + 25 = ?', expected: '52'), isNull);
    expect(WholeArithmetic.parse('7 : 2 = ?'), isNull);
    expect(WholeArithmetic.parse('7 : 0 = ?'), isNull);
    for (final bad in ['1,5 + 2 = ?', '1/2 + 1/4 = ?', '0.5 + 2 = ?',
      'Vergleiche 8 + 5 = ? und 2 + 3.', '8 + ? = 13', '8 + 5 = 13']) {
      expect(WholeArithmetic.parse(bad), isNull, reason: bad);
    }
    for (final bad in ['3,5', '2.5', '1/2', '3 Euro', 'zwei 2']) {
      expect(WholeArithmetic.integerAnswer(bad), isNull, reason: bad);
    }
  });

  test('carry and borrow produce different, task-bound explanations', () {
    final carry = detect('37 + 25 = ?', '62', '52');
    final borrow = detect('52 − 27 = ?', '25', '35');
    expect(carry.pattern, ErrorPattern.placeValueError);
    expect(carry.childFriendlyMessage, contains('zehn Einer gegen eine Zehnerstange'));
    expect(borrow.pattern, ErrorPattern.placeValueError);
    expect(borrow.childFriendlyMessage, contains('einen Zehner gegen zehn Einer'));
    expect(carry.childFriendlyMessage, isNot(contains('62')));
    expect(borrow.childFriendlyMessage, isNot(contains('25')));
    expect(teacher.detect(attempt('37 + 25 = ?', '62', '52')),
        'Zehner beim Übergang vergessen');
    expect(teacher.detect(attempt('42 − 8 = ?', '34', '44')),
        'Zehner beim Übergang nicht abgezogen');
    expect(teacher.detect(attempt('34 + 12 = ?', '46', '36')), isNull);
    expect(teacher.detect(attempt('42 − 2 = ?', '40', '50')), isNull);
  });

  test('non-arithmetic, malformed and already correct answers are neutral', () {
    for (final row in [
      ('1,5 + 2 = ?', '3,5', '3,4'),
      ('1/2 + 1/4 = ?', '3/4', '1/4'),
      ('37 + 25 = ?', '52', '42'),
      ('37 + 25 = ?', '62', '52 Euro'),
      ('37 + 25 = ?', '62', '62'),
      ('Wie viele Bücher bleiben nach 8 + 5?', '13', '3'),
    ]) {
      expect(detect(row.$1, row.$2, row.$3).isRecognised, isFalse);
      expect(teacher.detect(attempt(row.$1, row.$2, row.$3)), isNull);
    }
  });

  test('tutor adapts requested help without revealing result or leaking to tests', () {
    final carry = tutor.buildLocalFallback(request('37 + 25 = ?', '62', '52'));
    final borrow = tutor.buildLocalFallback(request('52 − 27 = ?', '25', '35'));
    expect(carry.speech, contains('zehn Einer gegen eine Zehnerstange'));
    expect(borrow.speech, contains('einen Zehner gegen zehn Einer'));
    expect(carry.speech, isNot(contains('62')));
    expect(borrow.speech, isNot(contains('25')));
    expect(tutor.suggestVisualPlan(request('1,5 + 2 = ?', '3,5', '3,4')).type,
        LumoTutorVisualType.none);
    expect(tutor.suggestVisualPlan(request('37 + 25 = ?', '52', '42')).type,
        LumoTutorVisualType.none);
    final exam = request('37 + 25 = ?', '62', '52', mode: LumoTutorMode.testReview);
    expect(tutor.buildLocalFallback(exam).shortHint, 'Auswertung nach dem Test');
    expect(tutor.suggestVisualPlan(exam).type, LumoTutorVisualType.none);
  });
}
