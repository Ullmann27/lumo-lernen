import '../domain/cognitive/cognitive_profile.dart';
import 'cognitive_profile_generator.dart';

class CognitiveProfileScorer {
  const CognitiveProfileScorer._();

  static CognitiveProfileResult score({
    required String id,
    required String studentId,
    required int grade,
    required List<CognitiveQuestion> questions,
    required Map<String, String> answers,
    required DateTime finishedAt,
    required int durationMs,
  }) {
    final domainScores = <CognitiveDomainScore>[];
    var totalCorrect = 0;
    for (final domain in CognitiveDomain.values) {
      final subset = questions.where((q) => q.domain == domain).toList();
      final correct = subset
          .where((q) => answers[q.id] == q.correctAnswer)
          .length;
      totalCorrect += correct;
      domainScores.add(
        CognitiveDomainScore(
          domain: domain,
          correct: correct,
          total: subset.length,
        ),
      );
    }
    return CognitiveProfileResult(
      id: id,
      studentId: studentId,
      grade: grade.clamp(1, 4),
      testVersion: CognitiveProfileGenerator.testVersion,
      finishedAt: finishedAt,
      domainScores: domainScores,
      totalCorrect: totalCorrect,
      totalQuestions: questions.length,
      durationMs: durationMs.clamp(0, 86400000),
    );
  }
}
