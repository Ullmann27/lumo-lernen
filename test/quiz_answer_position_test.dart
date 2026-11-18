import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/domain/quiz/quiz_show.dart';

/// Befund M31 der Fachprüfung Mathematik (17.11.2026): Die richtige Antwort
/// stand in der Quiz-Show fast immer an Platz 2, nie an Platz 1 oder 4.
void main() {
  test('richtige Antwort an jedem Platz, Antwort bleibt dieselbe', () {
    const bank = QuizQuestionBank();
    final positions = List<int>.filled(4, 0);
    final answerById = <String, String>{};
    for (var grade = 1; grade <= 4; grade++) {
      for (var round = 0; round < 50; round++) {
        final questions = bank.generateGameQuestions(
            grade: grade, random: math.Random(grade * 1000 + round));
        for (final q in questions) {
          expect(QuizQuestionBank.acceptsQuestion(q), isTrue, reason: q.id);
          positions[q.correctIndex]++;
          final previous = answerById.putIfAbsent(q.id, () => q.correctAnswer);
          expect(q.correctAnswer, previous, reason: q.id);
        }
      }
    }
    final total = positions.reduce((a, b) => a + b);
    for (var i = 0; i < 4; i++) {
      expect(positions[i], greaterThan(total * 0.18),
          reason: 'Platz ${i + 1}: $positions');
    }
  });

  test('Mischen führt den Index mit', () {
    const question = QuizQuestion(
      id: 't',
      prompt: '3 + 4 = ?',
      options: ['6', '7', '8', '9'],
      correctIndex: 1,
      difficulty: QuizDifficulty.easy,
      subject: 'Mathematik',
    );
    for (var seed = 0; seed < 20; seed++) {
      final shuffled =
          QuizQuestionBank.shuffledOptions(question, math.Random(seed));
      expect(shuffled.correctAnswer, '7');
      expect(shuffled.options.toSet(), question.options.toSet());
    }
  });
}
