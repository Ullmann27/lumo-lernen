class ReadingAnalysisSummary {
  const ReadingAnalysisSummary({
    required this.id,
    required this.childId,
    required this.storyTitle,
    required this.startedAt,
    required this.updatedAt,
    required this.completedSentences,
    required this.totalSentences,
    required this.averageAlignmentScore,
    required this.interventionCount,
    required this.problemWords,
  });

  final String id;
  final String childId;
  final String storyTitle;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int completedSentences;
  final int totalSentences;
  final double averageAlignmentScore;
  final int interventionCount;
  final List<String> problemWords;

  bool get completed => totalSentences > 0 && completedSentences >= totalSentences;
  double get progress => totalSentences == 0 ? 0 : (completedSentences / totalSentences).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'storyTitle': storyTitle,
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedSentences': completedSentences,
        'totalSentences': totalSentences,
        'averageAlignmentScore': averageAlignmentScore,
        'interventionCount': interventionCount,
        'problemWords': problemWords,
      };

  factory ReadingAnalysisSummary.fromJson(Map<String, dynamic> json) => ReadingAnalysisSummary(
        id: json['id']?.toString() ?? 'reading.unknown',
        childId: json['childId']?.toString() ?? 'local_kind_1',
        storyTitle: json['storyTitle']?.toString() ?? 'Lumo liest',
        startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        completedSentences: (json['completedSentences'] as num?)?.toInt() ?? 0,
        totalSentences: (json['totalSentences'] as num?)?.toInt() ?? 0,
        averageAlignmentScore: (json['averageAlignmentScore'] as num?)?.toDouble() ?? 0,
        interventionCount: (json['interventionCount'] as num?)?.toInt() ?? 0,
        problemWords: (json['problemWords'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false),
      );
}

class SubjectAnalysisBlock {
  const SubjectAnalysisBlock({
    required this.subject,
    required this.strengths,
    required this.weaknesses,
    required this.errorPatterns,
    required this.recommendedAction,
    required this.priority,
  });

  final String subject;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> errorPatterns;
  final String recommendedAction;
  final int priority;
}

class DailyRecommendationBlock {
  const DailyRecommendationBlock({
    required this.title,
    required this.description,
    required this.subject,
    required this.unit,
    required this.minutes,
    required this.kind,
    required this.priority,
  });

  final String title;
  final String description;
  final String subject;
  final String unit;
  final int minutes;
  final RecommendationKind kind;
  final int priority;
}

enum RecommendationKind {
  practice,
  reading,
  tutoring,
  success,
  review,
}

class DailyRecommendationPlan {
  const DailyRecommendationPlan({
    required this.childId,
    required this.date,
    required this.headline,
    required this.lumoMessage,
    required this.blocks,
    required this.parentNote,
  });

  final String childId;
  final DateTime date;
  final String headline;
  final String lumoMessage;
  final List<DailyRecommendationBlock> blocks;
  final String parentNote;

  int get totalMinutes => blocks.fold<int>(0, (sum, block) => sum + block.minutes);
}

class ParentReportSummary {
  const ParentReportSummary({
    required this.childName,
    required this.generatedAt,
    required this.summary,
    required this.reading,
    required this.math,
    required this.german,
    required this.nextSteps,
  });

  final String childName;
  final DateTime generatedAt;
  final String summary;
  final SubjectAnalysisBlock reading;
  final SubjectAnalysisBlock math;
  final SubjectAnalysisBlock german;
  final List<String> nextSteps;
}
