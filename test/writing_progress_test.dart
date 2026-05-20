import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/domain/writing/writing_progress.dart';

void main() {
  group('WritingProgress', () {
    test('withAttempt zaehlt Versuche und richtige Antworten', () {
      var p = WritingProgress.empty;
      p = p.withAttempt(letter: 'A', correct: true);
      p = p.withAttempt(letter: 'A', correct: false);
      p = p.withAttempt(letter: 'B', correct: true);

      expect(p.totalAttempts, 3);
      expect(p.totalCorrect, 2);
      expect(p.letterStats['A']!.attempts, 2);
      expect(p.letterStats['A']!.correct, 1);
      expect(p.letterStats['A']!.accuracy, closeTo(0.5, 0.0001));
      expect(p.letterStats['B']!.attempts, 1);
      expect(p.letterStats['B']!.correct, 1);
    });

    test('normalisiert Buchstaben auf Grossschreibung', () {
      final p = WritingProgress.empty.withAttempt(letter: 'a', correct: true);
      expect(p.letterStats.containsKey('A'), isTrue);
      expect(p.letterStats.containsKey('a'), isFalse);
    });

    test('weakLetters nur bei min 3 Versuchen und accuracy < 0.7', () {
      var p = WritingProgress.empty;
      // M: 4 Versuche, 1 richtig -> schwach (0.25)
      p = p.withAttempt(letter: 'M', correct: false);
      p = p.withAttempt(letter: 'M', correct: true);
      p = p.withAttempt(letter: 'M', correct: false);
      p = p.withAttempt(letter: 'M', correct: false);
      // N: 5 Versuche, 4 richtig -> stark (0.8)
      for (var i = 0; i < 5; i++) {
        p = p.withAttempt(letter: 'N', correct: i != 0);
      }
      // O: 2 Versuche, 0 richtig -> noch keine Statistik (unter Schwelle)
      p = p.withAttempt(letter: 'O', correct: false);
      p = p.withAttempt(letter: 'O', correct: false);

      expect(p.weakLetters, contains('M'));
      expect(p.weakLetters, isNot(contains('N')));
      expect(p.weakLetters, isNot(contains('O')));
    });

    test('completedWords werden auf Grossschreibung normalisiert und dedupliziert', () {
      var p = WritingProgress.empty
          .withCompletedWord('Mama')
          .withCompletedWord('mama')
          .withCompletedWord('Papa');
      expect(p.completedWords, {'MAMA', 'PAPA'});
    });

    test('toJson/fromJson Roundtrip erhaelt Daten', () {
      var p = WritingProgress.empty;
      p = p.withAttempt(letter: 'A', correct: true);
      p = p.withAttempt(letter: 'B', correct: false);
      p = p.withCompletedWord('Hund');

      final json = p.toJson();
      final restored = WritingProgress.fromJson(json);

      expect(restored.totalAttempts, p.totalAttempts);
      expect(restored.totalCorrect, p.totalCorrect);
      expect(restored.letterStats['A']!.attempts, 1);
      expect(restored.letterStats['A']!.correct, 1);
      expect(restored.letterStats['B']!.attempts, 1);
      expect(restored.letterStats['B']!.correct, 0);
      expect(restored.completedWords, contains('HUND'));
    });

    test('leeres fromJson liefert empty Progress', () {
      final restored = WritingProgress.fromJson(<String, dynamic>{});
      expect(restored.totalAttempts, 0);
      expect(restored.letterStats, isEmpty);
      expect(restored.completedWords, isEmpty);
    });

    test('overallAccuracy ist 0 wenn keine Versuche', () {
      expect(WritingProgress.empty.overallAccuracy, 0.0);
    });
  });
}
