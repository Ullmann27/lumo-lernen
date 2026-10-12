import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/domain/quiz/quiz_show.dart';

void main() {
  const bank = QuizQuestionBank();
  const engine = QuizShowEngine();

  group('Wer wird Lumo-Meister', () {
    test('jede Schulstufe erzeugt exakt 20 altersgerechte Fragen', () {
      final grade1 = bank.generateGameQuestions(
        grade: 1,
        random: math.Random(1),
      );
      final grade2 = bank.generateGameQuestions(
        grade: 2,
        random: math.Random(2),
      );
      final grade3 = bank.generateGameQuestions(
        grade: 3,
        random: math.Random(3),
      );
      final grade4 = bank.generateGameQuestions(
        grade: 4,
        random: math.Random(4),
      );

      expect(grade1, hasLength(20));
      expect(grade2, hasLength(20));
      expect(grade3, hasLength(20));
      expect(grade4, hasLength(20));

      expect(
        grade1.where((q) => q.difficulty == QuizDifficulty.hard),
        isEmpty,
      );
      expect(
        grade1.where((q) => q.id.startsWith('m_math_mul_')),
        isEmpty,
      );
      expect(
        grade2.where((q) => q.difficulty == QuizDifficulty.hard),
        isEmpty,
      );

      expect(
        grade3.where((q) => q.difficulty == QuizDifficulty.hard),
        hasLength(8),
      );
      expect(
        grade4.where((q) => q.difficulty == QuizDifficulty.hard),
        hasLength(12),
      );

      expect(grade1.last.id, startsWith('final_g1_'));
      expect(grade2.last.id, startsWith('final_g2_'));
      expect(grade3.last.id, startsWith('final_g3_'));
      expect(grade4.last.id, startsWith('final_g4_'));
      expect(grade1.last.subject, 'Logik-Finale');
      expect(grade4.last.subject, 'Logik-Finale');
    });

    test('Finalfrage wiederholt sich nicht solange eine frische Variante existiert', () {
      final first = bank.generateGameQuestions(
        grade: 4,
        random: math.Random(21),
      );
      final firstFinal = first.last;

      final second = bank.generateGameQuestions(
        grade: 4,
        seenIds: <String>{firstFinal.id},
        random: math.Random(21),
      );

      expect(second.last.id, startsWith('final_g4_'));
      expect(second.last.id, isNot(firstFinal.id));
    });

    test('Anti-Wiederholung behält frische Fragen bei Teilpool-Fallback', () {
      final baseline = bank.generateGameQuestions(
        grade: 1,
        random: math.Random(11),
      );
      final easyIds = baseline
          .where((q) => q.difficulty == QuizDifficulty.easy)
          .map((q) => q.id)
          .toSet();

      // 13 der 14 zuvor gezogenen Easy-Fragen gelten als gesehen.
      // Die eine frische Frage muss in der nächsten Runde erhalten bleiben.
      final seen = easyIds.take(13).toSet();
      final freshId = easyIds.difference(seen).single;

      final next = bank.generateGameQuestions(
        grade: 1,
        seenIds: seen,
        random: math.Random(12),
      );

      expect(next.map((q) => q.id), contains(freshId));
    });

    test('Stern-Leiter ist 50, 200, 800 und 5000', () {
      expect(engine.safeSpotStarsForIndex(4), 50);
      expect(engine.safeSpotStarsForIndex(9), 200);
      expect(engine.safeSpotStarsForIndex(14), 800);
      expect(engine.safeSpotStarsForIndex(19), 5000);
      expect(engine.safeSpotStarsForIndex(18), 0);
    });

    test('falsche Antwort nach Frage 5 sichert genau 50 Sterne', () {
      var state = engine.start(questions: _questions());

      for (var i = 0; i < 5; i++) {
        state = engine.selectAnswer(state, 0);
        state = engine.reveal(state);
        if (i < 4) {
          state = engine.nextQuestion(state);
        }
      }

      expect(state.securedStars, 50);
      expect(state.gameOver, isFalse);

      state = engine.nextQuestion(state);
      state = engine.selectAnswer(state, 1);
      state = engine.reveal(state);

      expect(state.gameOver, isTrue);
      expect(state.won, isFalse);
      expect(state.awardedStars, 50);
    });

    test('20 richtige Antworten ergeben 5000 Sterne und Lumo-Meister', () {
      var state = engine.start(questions: _questions());

      for (var i = 0; i < 20; i++) {
        state = engine.selectAnswer(state, 0);
        state = engine.reveal(state);
        if (!state.gameOver) {
          state = engine.nextQuestion(state);
        }
      }

      expect(state.gameOver, isTrue);
      expect(state.won, isTrue);
      expect(state.securedStars, 5000);
      expect(state.awardedStars, 5000);
    });
  });
}

List<QuizQuestion> _questions() {
  return List<QuizQuestion>.generate(
    20,
    (i) => QuizQuestion(
      id: 'meister_test_$i',
      prompt: 'Testfrage ${i + 1}',
      options: const <String>['Richtig', 'Falsch A', 'Falsch B', 'Falsch C'],
      correctIndex: 0,
      difficulty: i < 7
          ? QuizDifficulty.easy
          : i < 14
              ? QuizDifficulty.medium
              : QuizDifficulty.hard,
      subject: 'Mix',
    ),
  );
}
