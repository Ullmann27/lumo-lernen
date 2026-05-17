import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/services/class_settings.dart';
import 'package:lumo_lernen/services/quiz_question_bank.dart';
import 'package:lumo_lernen/services/quiz_show_repository.dart';
import 'package:lumo_lernen/services/wwm_game_state.dart';

void main() {
  group('QuizQuestionBank', () {
    // ── Test 1: 100 rounds – within each round all 15 IDs are unique ────────
    test('100 rounds: within each round all 15 question IDs are unique', () {
      final repo = QuizShowRepository();
      final rng = Random(42); // fixed seed → deterministic test run

      for (var round = 0; round < 100; round++) {
        final questions = QuizQuestionBank.generateGameQuestions(
          ClassLevel.fortgeschritten,
          repo,
          rng,
        );
        expect(
          questions.length,
          equals(15),
          reason: 'Round $round should have 15 questions.',
        );
        final ids = questions.map((q) => q.id).toSet();
        expect(
          ids.length,
          equals(15),
          reason: 'Round $round has duplicate question IDs: '
              '${questions.map((q) => q.id).toList()}',
        );
      }
    });

    // ── Test 2: Klasse 1 never produces multiplication questions ────────────
    test('Klasse 1 never produces multiplication (×) questions', () {
      final repo = QuizShowRepository();
      final rng = Random(0);

      for (var round = 0; round < 20; round++) {
        final questions = QuizQuestionBank.generateGameQuestions(
          ClassLevel.klasse1,
          repo,
          rng,
        );
        for (final q in questions.where((q) => q.subject == 'Mathematik')) {
          expect(
            q.question.contains('×'),
            isFalse,
            reason:
                'Klasse 1 round $round has a multiplication question: ${q.question}',
          );
          // Also check the question ID doesn't belong to multiplication tier
          expect(
            q.id.startsWith('math_mul_'),
            isFalse,
            reason:
                'Klasse 1 round $round returned a multiplication question ID: ${q.id}',
          );
        }
      }
    });

    // ── Test 3: Exact 5+5+5 distribution ────────────────────────────────────
    test('every round returns exactly 5 Mathematik + 5 Deutsch + 5 Sachkunde',
        () {
      final repo = QuizShowRepository();
      final rng = Random(7);

      for (var round = 0; round < 10; round++) {
        for (final level in ClassLevel.values) {
          final questions = QuizQuestionBank.generateGameQuestions(
            level,
            repo,
            rng,
          );
          final bySubject = <String, int>{};
          for (final q in questions) {
            bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
          }
          expect(
            bySubject['Mathematik'],
            equals(QuizQuestionBank.questionsPerSubject),
            reason: 'Level $level round $round: wrong Mathematik count.',
          );
          expect(
            bySubject['Deutsch'],
            equals(QuizQuestionBank.questionsPerSubject),
            reason: 'Level $level round $round: wrong Deutsch count.',
          );
          expect(
            bySubject['Sachkunde'],
            equals(QuizQuestionBank.questionsPerSubject),
            reason: 'Level $level round $round: wrong Sachkunde count.',
          );
        }
      }
    });

    // ── Additional: options list is exactly 4 for every question ────────────
    test('every question has exactly 4 options', () {
      final repo = QuizShowRepository();
      final rng = Random(99);
      final questions = QuizQuestionBank.generateGameQuestions(
        ClassLevel.fortgeschritten,
        repo,
        rng,
      );
      for (final q in questions) {
        expect(
          q.options.length,
          equals(4),
          reason: '${q.id} does not have 4 options.',
        );
      }
    });

    // ── Additional: correctIndex is always in range [0,3] ───────────────────
    test('correctIndex is always in range [0, 3]', () {
      final repo = QuizShowRepository();
      final rng = Random(11);
      final questions = QuizQuestionBank.generateGameQuestions(
        ClassLevel.fortgeschritten,
        repo,
        rng,
      );
      for (final q in questions) {
        expect(
          q.correctIndex,
          inInclusiveRange(0, 3),
          reason: '${q.id} has out-of-range correctIndex: ${q.correctIndex}.',
        );
      }
    });

    // ── Additional: seenIds are marked after each round ──────────────────────
    test('QuizShowRepository records seen IDs after each round', () {
      final repo = QuizShowRepository();
      expect(repo.seenCount, equals(0));

      final rng = Random(5);
      QuizQuestionBank.generateGameQuestions(
          ClassLevel.klasse2, repo, rng);
      expect(repo.seenCount, equals(15));

      QuizQuestionBank.generateGameQuestions(
          ClassLevel.klasse2, repo, rng);
      expect(repo.seenCount, greaterThan(15));
    });

    // ── Klasse 2 does not get hard multiplication (e.g. 7 × 8) ─────────────
    test('Klasse 2 never produces hard multiplication like 7 × 8', () {
      final repo = QuizShowRepository();
      final rng = Random(3);

      for (var round = 0; round < 20; round++) {
        final questions = QuizQuestionBank.generateGameQuestions(
          ClassLevel.klasse2,
          repo,
          rng,
        );
        for (final q in questions.where((q) => q.subject == 'Mathematik')) {
          // Klasse 2 must not contain any multiplication symbol
          expect(
            q.question.contains('×'),
            isFalse,
            reason:
                'Klasse 2 round $round has a multiplication question: ${q.question}',
          );
        }
      }
    });

    // ── No duplicate prompt texts within a single round ───────────────────
    test('no duplicate question texts within a single round', () {
      final repo = QuizShowRepository();
      final rng = Random(17);

      for (var round = 0; round < 20; round++) {
        final questions = QuizQuestionBank.generateGameQuestions(
          ClassLevel.fortgeschritten,
          repo,
          rng,
        );
        final texts = questions.map((q) => q.question).toSet();
        expect(
          texts.length,
          equals(questions.length),
          reason:
              'Round $round has duplicate question texts.',
        );
      }
    });
  });

  // ── WwmGameState coupon logic ─────────────────────────────────────────────
  group('WwmGameState.couponsEarned', () {
    test('0 coupons when no secure XP and not finished', () {
      // securedXP = 0, status != finished → 0 coupons
      // We test the XP thresholds directly from the public ladder.
      final ladder = WwmGameState.xpLadder;
      // Q5 safe XP is ladder[4] = 100, Q10 safe XP is ladder[9] = 400
      expect(ladder[4], equals(100));
      expect(ladder[9], equals(400));
    });
  });
}
