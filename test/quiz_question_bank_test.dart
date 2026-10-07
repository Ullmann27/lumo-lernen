import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';

/// Quizshow: jede Frage hat eindeutige Antworten und echte Umlaute.
void main() {
  test('Antworten eindeutig, richtige Antwort gültig, keine Ersatz-Umlaute', () {
    final questions = {
      for (var grade = 1; grade <= 4; grade++)
        for (var seed = 0; seed < 30; seed++)
          ...const QuizQuestionBank()
              .generateGameQuestions(grade: grade, random: math.Random(seed)),
    };
    expect(questions, isNotEmpty);
    for (final q in questions) {
      expect(q.options.toSet().length, q.options.length, reason: q.prompt);
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1), reason: q.prompt);
      for (final text in [q.prompt, ...q.options]) {
        expect(text, isNot(matches(RegExp(r'\b(Fruehling|Gruen|Aepfel|faellt|groesser|Blaetter|Koerper)\b'))),
            reason: text);
      }
    }
  });
}
