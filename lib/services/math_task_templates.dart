import 'dart:math';
import 'class_settings.dart';
import 'quiz_question.dart';

/// The kind of arithmetic operation a math question uses.
enum MathTemplateKind { addition, subtraction, multiplication }

/// Generates [QuizQuestion] objects for Mathematik by computing every valid
/// combination within the numeric range appropriate for each [ClassLevel].
///
/// Grade 1 – addition and subtraction within 20 (no multiplication).
/// Grade 2 – larger round-number addition and subtraction up to 100
///            (still no multiplication).
/// Fortgeschritten – all of the above PLUS multiplication tables (2–10).
class MathTaskTemplates {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the full pool of math questions for [level].
  ///
  /// [rng] is optional; a fresh [Random] is created when omitted.
  /// Answer options are shuffled so the correct answer isn't always in the
  /// same position.
  static List<QuizQuestion> forLevel(ClassLevel level, [Random? rng]) {
    rng ??= Random();
    final qs = <QuizQuestion>[];

    // Grade 1: small-number addition and subtraction
    qs.addAll(_g1Addition(rng));
    qs.addAll(_g1Subtraction(rng));

    // Grade 2+: larger numbers (no multiplication)
    if (level == ClassLevel.klasse2 || level == ClassLevel.fortgeschritten) {
      qs.addAll(_g2Addition(rng));
      qs.addAll(_g2Subtraction(rng));
    }

    // Fortgeschritten only: multiplication tables
    if (level == ClassLevel.fortgeschritten) {
      qs.addAll(_multiplication(rng));
    }

    return qs;
  }

  // ---------------------------------------------------------------------------
  // Grade-1 generators (within 20)
  // ---------------------------------------------------------------------------

  /// a + b where a,b ∈ [1..10]. a+b ≤ 20 is always satisfied → 100 questions.
  static List<QuizQuestion> _g1Addition(Random rng) {
    final qs = <QuizQuestion>[];
    for (int a = 1; a <= 10; a++) {
      for (int b = 1; b <= 10; b++) {
        final c = a + b;
        qs.add(_makeArith(
          id: 'math_add_g1_${a}_$b',
          kind: MathTemplateKind.addition,
          question: 'Was ist $a + $b?',
          correct: c,
          explanation: '$a + $b = $c. Zähle von $a aus $b weiter.',
          rng: rng,
          maxWrong: 20,
        ));
      }
    }
    return qs;
  }

  /// a − b where a ∈ [2..20], b ∈ [1..a−1] → 190 questions.
  static List<QuizQuestion> _g1Subtraction(Random rng) {
    final qs = <QuizQuestion>[];
    for (int a = 2; a <= 20; a++) {
      for (int b = 1; b < a; b++) {
        final c = a - b;
        qs.add(_makeArith(
          id: 'math_sub_g1_${a}_$b',
          kind: MathTemplateKind.subtraction,
          question: 'Was ist $a − $b?',
          correct: c,
          explanation: '$a − $b = $c.',
          rng: rng,
          maxWrong: 20,
        ));
      }
    }
    return qs;
  }

  // ---------------------------------------------------------------------------
  // Grade-2 generators (up to 100, round numbers)
  // ---------------------------------------------------------------------------

  /// Round-tens addition: a,b ∈ {10,15,20,…,50}, a+b ≤ 100 → ≤ 81 questions.
  static List<QuizQuestion> _g2Addition(Random rng) {
    const steps = [10, 15, 20, 25, 30, 35, 40, 45, 50];
    final qs = <QuizQuestion>[];
    for (final a in steps) {
      for (final b in steps) {
        if (a + b > 100) continue;
        final c = a + b;
        qs.add(_makeArith(
          id: 'math_add_g2_${a}_$b',
          kind: MathTemplateKind.addition,
          question: 'Was ist $a + $b?',
          correct: c,
          explanation: '$a + $b = $c.',
          rng: rng,
          maxWrong: 100,
        ));
      }
    }
    return qs;
  }

  /// Round-number subtraction: a ∈ {20…100 step 10}, b ∈ {5,10,15,20,25,30},
  /// b < a → ~43 questions.
  static List<QuizQuestion> _g2Subtraction(Random rng) {
    const aVals = [20, 30, 40, 50, 60, 70, 80, 90, 100];
    const bVals = [5, 10, 15, 20, 25, 30];
    final qs = <QuizQuestion>[];
    for (final a in aVals) {
      for (final b in bVals) {
        if (b >= a) continue;
        final c = a - b;
        qs.add(_makeArith(
          id: 'math_sub_g2_${a}_$b',
          kind: MathTemplateKind.subtraction,
          question: 'Was ist $a − $b?',
          correct: c,
          explanation: '$a − $b = $c.',
          rng: rng,
          maxWrong: 100,
        ));
      }
    }
    return qs;
  }

  // ---------------------------------------------------------------------------
  // Multiplication (Fortgeschritten only)
  // ---------------------------------------------------------------------------

  /// a × b where a,b ∈ [2..10] → 81 questions.
  static List<QuizQuestion> _multiplication(Random rng) {
    final qs = <QuizQuestion>[];
    for (int a = 2; a <= 10; a++) {
      for (int b = 2; b <= 10; b++) {
        final c = a * b;
        qs.add(_makeArith(
          id: 'math_mul_g3_${a}_$b',
          kind: MathTemplateKind.multiplication,
          question: 'Was ist $a × $b?',
          correct: c,
          explanation: '$a × $b = $c.',
          rng: rng,
          maxWrong: 100,
        ));
      }
    }
    return qs;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static QuizQuestion _makeArith({
    required String id,
    required MathTemplateKind kind,
    required String question,
    required int correct,
    required String explanation,
    required Random rng,
    int maxWrong = 100,
  }) {
    final wrongVals = _wrongAnswers(correct, maxVal: maxWrong);
    final opts = [
      correct.toString(),
      ...wrongVals.map((v) => v.toString()),
    ]..shuffle(rng);
    final correctIdx = opts.indexOf(correct.toString());
    return QuizQuestion(
      id: id,
      subject: 'Mathematik',
      question: question,
      options: opts,
      correctIndex: correctIdx,
      explanation: explanation,
    );
  }

  /// Generates [count] plausible but wrong integer answers for [correct].
  static List<int> _wrongAnswers(
    int correct, {
    int count = 3,
    int maxVal = 100,
  }) {
    final result = <int>[];
    final tried = <int>{correct};
    for (final offset in [1, -1, 2, -2, 3, -3, 4, 5, -4, 6, -5, 7, -6]) {
      final v = correct + offset;
      if (v > 0 && !tried.contains(v)) {
        result.add(v);
        tried.add(v);
        if (result.length >= count) break;
      }
    }
    // Fallback: add sequential positives if not enough
    int extra = correct + 8;
    while (result.length < count) {
      while (tried.contains(extra) || extra <= 0) {
        extra++;
      }
      result.add(extra);
      tried.add(extra);
      extra++;
    }
    return result.take(count).toList();
  }
}
