/// Assessed answers are separate from accompanied practice totals. Historical
/// mixed totals cannot reveal which answers were independent.
class IndependentEvidence {
  const IndependentEvidence({
    this.correct = 0,
    this.wrong = 0,
    this.correctStreak = 0,
    this.wrongStreak = 0,
  });

  final int correct;
  final int wrong;
  final int correctStreak;
  final int wrongStreak;

  int get attempts => correct + wrong;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  factory IndependentEvidence.fromLegacy({
    required int correct,
    required int wrong,
    required int helpCount,
    required int correctStreak,
    required int wrongStreak,
  }) {
    if (helpCount != 0) return const IndependentEvidence();
    return IndependentEvidence(
      correct: correct.clamp(0, 10000),
      wrong: wrong.clamp(0, 10000),
      correctStreak:
          wrongStreak > 0 ? 0 : correctStreak.clamp(0, correct.clamp(0, 1000)),
      wrongStreak:
          correctStreak > 0 ? 0 : wrongStreak.clamp(0, wrong.clamp(0, 1000)),
    );
  }

  IndependentEvidence record(bool isCorrect) => IndependentEvidence(
        correct: (correct + (isCorrect ? 1 : 0)).clamp(0, 10000),
        wrong: (wrong + (isCorrect ? 0 : 1)).clamp(0, 10000),
        correctStreak: isCorrect ? (correctStreak + 1).clamp(0, 1000) : 0,
        wrongStreak: isCorrect ? 0 : (wrongStreak + 1).clamp(0, 1000),
      );

  Map<String, Object> toJson() => {
        'version': 1,
        'correct': correct,
        'wrong': wrong,
        'correctStreak': correctStreak,
        'wrongStreak': wrongStreak,
      };

  factory IndependentEvidence.fromJson(Object? raw) {
    const fields = {
      'version',
      'correct',
      'wrong',
      'correctStreak',
      'wrongStreak'
    };
    if (raw is! Map<String, dynamic> ||
        raw.length != fields.length ||
        raw.keys.any((key) => !fields.contains(key)) ||
        raw['version'] is! int ||
        raw['version'] != 1) {
      throw const FormatException('Unsupported independent evidence');
    }
    int count(String key, int maximum) {
      final value = raw[key];
      if (value is! int || value < 0 || value > maximum) {
        throw const FormatException('Invalid independent evidence count');
      }
      return value;
    }

    final correct = count('correct', 10000);
    final wrong = count('wrong', 10000);
    final correctStreak = count('correctStreak', 1000);
    final wrongStreak = count('wrongStreak', 1000);
    if (correctStreak > correct ||
        wrongStreak > wrong ||
        (correctStreak > 0 && wrongStreak > 0)) {
      throw const FormatException('Conflicting independent evidence');
    }
    return IndependentEvidence(
        correct: correct,
        wrong: wrong,
        correctStreak: correctStreak,
        wrongStreak: wrongStreak);
  }
}
