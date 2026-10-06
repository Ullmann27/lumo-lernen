enum CognitiveDomain {
  patternReasoning,
  quantitativeReasoning,
  verbalReasoning,
  spatialReasoning,
  workingMemory,
}

extension CognitiveDomainLabel on CognitiveDomain {
  String get label => switch (this) {
        CognitiveDomain.patternReasoning => 'Muster & Regeln',
        CognitiveDomain.quantitativeReasoning => 'Quantitatives Denken',
        CognitiveDomain.verbalReasoning => 'Sprachliches Denken',
        CognitiveDomain.spatialReasoning => 'Räumliches Denken',
        CognitiveDomain.workingMemory => 'Arbeitsgedächtnis',
      };

  String get shortLabel => switch (this) {
        CognitiveDomain.patternReasoning => 'Muster',
        CognitiveDomain.quantitativeReasoning => 'Zahlen',
        CognitiveDomain.verbalReasoning => 'Sprache',
        CognitiveDomain.spatialReasoning => 'Raum',
        CognitiveDomain.workingMemory => 'Merken',
      };
}

class CognitiveQuestion {
  const CognitiveQuestion({
    required this.id,
    required this.grade,
    required this.domain,
    required this.prompt,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    this.stimulus,
    this.stimulusVisibleMs = 0,
  });

  final String id;
  final int grade;
  final CognitiveDomain domain;
  final String prompt;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;
  final int difficulty;
  final String? stimulus;
  final int stimulusVisibleMs;
}

class CognitiveDomainScore {
  const CognitiveDomainScore({
    required this.domain,
    required this.correct,
    required this.total,
  });

  final CognitiveDomain domain;
  final int correct;
  final int total;

  double get ratio => total <= 0 ? 0 : correct / total;
}

class CognitiveProfileResult {
  const CognitiveProfileResult({
    required this.id,
    required this.studentId,
    required this.grade,
    required this.testVersion,
    required this.finishedAt,
    required this.domainScores,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.durationMs,
  });

  final String id;
  final String studentId;
  final int grade;
  final String testVersion;
  final DateTime finishedAt;
  final List<CognitiveDomainScore> domainScores;
  final int totalCorrect;
  final int totalQuestions;
  final int durationMs;

  double get ratio =>
      totalQuestions <= 0 ? 0 : totalCorrect / totalQuestions;

  Map<String, Object> toJson() => {
        'id': id,
        'studentId': studentId,
        'grade': grade,
        'testVersion': testVersion,
        'finishedAt': finishedAt.toIso8601String(),
        'totalCorrect': totalCorrect,
        'totalQuestions': totalQuestions,
        'durationMs': durationMs,
        'domains': [
          for (final score in domainScores)
            {
              'domain': score.domain.name,
              'correct': score.correct,
              'total': score.total,
            },
        ],
      };

  static CognitiveProfileResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final sid = raw['studentId'];
    final grade = raw['grade'];
    final version = raw['testVersion'];
    final finishedAt = DateTime.tryParse('${raw['finishedAt']}');
    final totalCorrect = raw['totalCorrect'];
    final totalQuestions = raw['totalQuestions'];
    final durationMs = raw['durationMs'];
    final domains = raw['domains'];
    if (id is! String ||
        sid is! String ||
        grade is! int ||
        version is! String ||
        finishedAt == null ||
        totalCorrect is! int ||
        totalQuestions is! int ||
        durationMs is! int ||
        domains is! List) {
      return null;
    }
    final scores = <CognitiveDomainScore>[];
    for (final item in domains) {
      if (item is! Map) continue;
      final domainName = item['domain'];
      final correct = item['correct'];
      final total = item['total'];
      if (domainName is! String || correct is! int || total is! int) continue;
      CognitiveDomain? domain;
      for (final candidate in CognitiveDomain.values) {
        if (candidate.name == domainName) {
          domain = candidate;
          break;
        }
      }
      if (domain == null) continue;
      scores.add(
        CognitiveDomainScore(
          domain: domain,
          correct: correct.clamp(0, total),
          total: total,
        ),
      );
    }
    if (scores.length != CognitiveDomain.values.length) return null;
    return CognitiveProfileResult(
      id: id,
      studentId: sid,
      grade: grade.clamp(1, 4),
      testVersion: version,
      finishedAt: finishedAt,
      domainScores: scores,
      totalCorrect: totalCorrect.clamp(0, totalQuestions),
      totalQuestions: totalQuestions,
      durationMs: durationMs.clamp(0, 86400000),
    );
  }
}
