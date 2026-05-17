import 'dart:math';
import 'class_settings.dart';
import 'quiz_question.dart';
import 'quiz_show_repository.dart';
import 'math_task_templates.dart';
import 'german_task_templates.dart';
import 'sachkunde_task_templates.dart';

/// Generates a balanced set of quiz questions for one game session.
///
/// Rules
/// ─────
/// • 5 Mathematik + 5 Deutsch + 5 Sachkunde = 15 questions per round.
/// • Class filter:
///     Klasse 1       → Math: grade-1 add/sub only (never multiplication).
///     Klasse 2       → Math: grade-1 + grade-2 add/sub (still no ×).
///     Fortgeschritten → all tiers including multiplication.
/// • Anti-repetition: questions seen in previous rounds (tracked via
///   [QuizShowRepository]) are skipped. When a pool is exhausted the full
///   pool is used again (no infinite loop).
/// • No duplicate correct answers within a subject pick (soft constraint:
///   satisfied when possible, ignored when pool is too small).
class QuizQuestionBank {
  /// Number of questions per subject in each game session.
  static const int questionsPerSubject = 5;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns exactly [questionsPerSubject] × 3 = 15 shuffled [QuizQuestion]s.
  ///
  /// The returned questions are recorded in [repo] so they are deprioritised
  /// in the next call.
  static List<QuizQuestion> generateGameQuestions(
    ClassLevel level,
    QuizShowRepository repo, [
    Random? rng,
  ]) {
    rng ??= Random();

    final mathPool = MathTaskTemplates.forLevel(level, rng);
    final germanPool = GermanTaskTemplates.forLevel(level, rng);
    final sachkundePool = SachkundeTaskTemplates.forLevel(level, rng);

    final math = _pick(mathPool, repo, questionsPerSubject, rng);
    final german = _pick(germanPool, repo, questionsPerSubject, rng);
    final sachkunde = _pick(sachkundePool, repo, questionsPerSubject, rng);

    final all = [...math, ...german, ...sachkunde]..shuffle(rng);
    repo.markSeen(all.map((q) => q.id));
    return all;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Picks exactly [count] questions from [pool].
  ///
  /// Preference order:
  ///   1. Unseen questions (not in [repo]).
  ///   2. If fewer than [count] unseen, fall back to the full pool.
  ///
  /// Soft constraint: tries to avoid reusing the same correct-answer string
  /// within the [count] picks. Falls back to unrestricted if the soft
  /// constraint cannot be satisfied.
  static List<QuizQuestion> _pick(
    List<QuizQuestion> pool,
    QuizShowRepository repo,
    int count,
    Random rng,
  ) {
    if (pool.isEmpty) return [];

    // Prefer unseen; fall back to full pool when exhausted.
    final unseen = pool.where((q) => !repo.hasSeen(q.id)).toList()
      ..shuffle(rng);
    final source =
        unseen.length >= count ? unseen : (List<QuizQuestion>.from(pool)..shuffle(rng));

    // Soft constraint: no duplicate correct-answer strings within this pick.
    final usedAnswers = <String>{};
    final result = <QuizQuestion>[];

    for (final q in source) {
      if (result.length >= count) break;
      final answer = q.options[q.correctIndex];
      if (!usedAnswers.contains(answer)) {
        usedAnswers.add(answer);
        result.add(q);
      }
    }

    // If the soft constraint prevented filling, top up without it.
    if (result.length < count) {
      for (final q in source) {
        if (result.length >= count) break;
        if (!result.contains(q)) {
          result.add(q);
        }
      }
    }

    return result;
  }
}
