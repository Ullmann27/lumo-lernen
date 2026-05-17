/// A question used in the quiz show / QuizQuestionBank.
///
/// Distinct from [Exercise] (flashcard learning) and [WwmQuestion] (old static
/// fallback) so that the two systems can evolve independently.
class QuizQuestion {
  /// Stable, unique identifier (e.g. 'math_add_g1_5_3', 'de_g1_01').
  final String id;

  /// Display category: 'Mathematik', 'Deutsch', or 'Sachkunde'.
  final String subject;

  final String question;

  /// Exactly 4 answer options.
  final List<String> options;

  /// 0-based index of the correct answer within [options].
  final int correctIndex;

  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.subject,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
