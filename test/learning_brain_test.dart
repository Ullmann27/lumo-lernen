import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/services/learning_brain.dart';
import 'package:lumo_lernen/services/exercise_factory.dart';

void main() {
  group('LearningBrain', () {
    test('checkAnswer returns true for correct answer', () {
      final brain = LearningBrain();
      const exercise = Exercise(
        subject: 'Mathematik',
        question: '1 + 1 = ?',
        options: ['1', '2', '3', '4'],
        correctAnswer: '2',
        explanation: '1 + 1 = 2',
      );
      expect(brain.checkAnswer(exercise, '2'), isTrue);
    });

    test('checkAnswer returns false for wrong answer', () {
      final brain = LearningBrain();
      const exercise = Exercise(
        subject: 'Mathematik',
        question: '1 + 1 = ?',
        options: ['1', '2', '3', '4'],
        correctAnswer: '2',
        explanation: '1 + 1 = 2',
      );
      expect(brain.checkAnswer(exercise, '3'), isFalse);
    });

    test('wrongAttempts increments on wrong answer', () {
      final brain = LearningBrain();
      const exercise = Exercise(
        subject: 'Mathematik',
        question: '2 + 2 = ?',
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        explanation: '2 + 2 = 4',
      );
      brain.checkAnswer(exercise, '3');
      brain.checkAnswer(exercise, '5');
      expect(brain.wrongAttempts, equals(2));
    });

    test('resetWrongAttempts sets counter to zero', () {
      final brain = LearningBrain();
      const exercise = Exercise(
        subject: 'Mathematik',
        question: '2 + 2 = ?',
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        explanation: '2 + 2 = 4',
      );
      brain.checkAnswer(exercise, '3');
      brain.resetWrongAttempts();
      expect(brain.wrongAttempts, equals(0));
    });

    test('createFollowUpTask preserves question info', () {
      final brain = LearningBrain();
      const exercise = Exercise(
        subject: 'Mathematik',
        question: '3 + 4 = ?',
        options: ['5', '6', '7', '8'],
        correctAnswer: '7',
        explanation: '3 + 4 = 7',
      );
      final follow = brain.createFollowUpTask(exercise);
      expect(follow.subject, equals('Mathematik'));
      expect(follow.correctAnswer, equals('7'));
    });
  });
}
