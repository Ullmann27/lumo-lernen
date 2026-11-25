import 'attempt.dart';
import 'learning_analysis.dart';

/// Observed independent answers for one competency; time is never a score.
class LearningChartCount {
  const LearningChartCount({
    required this.subject,
    required this.competency,
    required this.total,
    required this.correct,
  });

  final String subject;
  final String competency;
  final int total;
  final int correct;
  double get accuracy => total == 0 ? 0 : correct / total;
  bool get hasEnoughEvidence => total >= LearningAnalysis.minReliable;
}

/// Actual recorded activity in one subject, separate from mastery estimates.
/// Duration is an independent-response median, not a speed score.
class LearningSubjectActivity {
  const LearningSubjectActivity({
    required this.subject,
    required this.total,
    required this.assisted,
    required this.independentCorrect,
    required this.timedIndependent,
    required this.medianIndependentMs,
  });

  final String subject;
  final int total;
  final int assisted;
  final int independentCorrect;
  final int timedIndependent;
  final double? medianIndependentMs;

  int get independent => total - assisted;
  double? get independentAccuracy =>
      independent == 0 ? null : independentCorrect / independent;
  double? get helpRate => total == 0 ? null : assisted / total;
}

/// A calendar week-sized window. A missing measurement stays null.
class LearningChartWeek {
  LearningChartWeek({
    required this.start,
    required this.endExclusive,
    required Map<String, LearningChartCount> subjects,
  }) : subjects = Map.unmodifiable(subjects);

  final DateTime start;
  final DateTime endExclusive;
  final Map<String, LearningChartCount> subjects;

  double? accuracyFor(String subject) => subjects[subject]?.accuracy;
}

/// Read-only projection of the stored answer log, scoped to an explicit owner.
/// Demo data and aggregate counters are never used to invent dated answers.
class LearningChartData {
  LearningChartData._({
    required this.studentId,
    required this.asOf,
    required this.total,
    required this.correct,
    required this.assistedTotal,
    required this.independentCorrect,
    required List<LearningChartCount> competencies,
    required List<LearningSubjectActivity> subjectActivity,
    required List<String> subjects,
    required List<LearningChartWeek> weeks,
  })  : competencies = List.unmodifiable(competencies),
        subjectActivity = List.unmodifiable(subjectActivity),
        subjects = List.unmodifiable(subjects),
        weeks = List.unmodifiable(weeks);

  final String studentId;
  final DateTime asOf;
  final int total;
  final int correct;
  final int assistedTotal;
  final int independentCorrect;
  int get independentTotal => total - assistedTotal;
  final List<LearningChartCount> competencies;
  final List<LearningSubjectActivity> subjectActivity;
  final List<String> subjects;
  final List<LearningChartWeek> weeks;
  /// The plotted rate uses only independent answers. Assisted work remains
  /// visible in the activity count, never as proof of independent competence.
  double? get accuracy =>
      independentTotal == 0 ? null : independentCorrect / independentTotal;

  factory LearningChartData.fromAttempts(
    Iterable<Attempt> source, {
    required String studentId,
    DateTime? now,
  }) {
    final asOf = (now ?? DateTime.now()).toLocal();
    final seen = <String>{};
    final attempts = <Attempt>[];
    if (studentId.trim().isNotEmpty) {
      for (final attempt in source) {
        if (attempt.studentId != studentId ||
            attempt.id.trim().isEmpty ||
            attempt.subject.trim().isEmpty ||
            attempt.competency.trim().isEmpty ||
            LearningAnalysis.assessmentSubjects.contains(attempt.subject) ||
            attempt.at.isAfter(asOf) ||
            !seen.add(attempt.id)) {
          continue;
        }
        attempts.add(attempt);
      }
    }

    // Reuse the same validated, owner-scoped, deduplicated attempts.
    final activityGroups = <String, List<Attempt>>{};
    for (final attempt in attempts) {
      activityGroups.putIfAbsent(attempt.subject, () => []).add(attempt);
    }
    final activity = <LearningSubjectActivity>[];
    for (final entry in activityGroups.entries) {
      final independent = entry.value.where((a) => !a.hintUsed).toList();
      final times = independent
          .map((a) => a.durationMs)
          .whereType<int>()
          .where((ms) => ms > 0)
          .toList()..sort();
      final middle = times.length ~/ 2;
      final double? median = times.isEmpty
          ? null
          : times.length.isOdd
              ? times[middle].toDouble()
              : times[middle - 1] / 2 + times[middle] / 2;
      activity.add(LearningSubjectActivity(
        subject: entry.key,
        total: entry.value.length,
        assisted: entry.value.length - independent.length,
        independentCorrect: independent.where((a) => a.correct).length,
        timedIndependent: times.length,
        medianIndependentMs: median,
      ));
    }
    activity.sort((a, b) => a.subject.compareTo(b.subject));

    final groups = <(String, String), List<Attempt>>{};
    for (final attempt in attempts) {
      if (attempt.hintUsed) continue;
      groups
          .putIfAbsent((attempt.subject, attempt.competency), () => <Attempt>[])
          .add(attempt);
    }
    final competencies = [
      for (final group in groups.entries)
        LearningChartCount(
          subject: group.key.$1,
          competency: group.key.$2,
          total: group.value.length,
          correct: group.value.where((attempt) => attempt.correct).length,
        ),
    ]..sort((a, b) {
        final countOrder = b.total.compareTo(a.total);
        if (countOrder != 0) return countOrder;
        final subjectOrder = a.subject.compareTo(b.subject);
        return subjectOrder != 0
            ? subjectOrder
            : a.competency.compareTo(b.competency);
      });
    final weeks = <LearningChartWeek>[];
    for (var index = 0; index < 4; index++) {
      // Calendar constructors keep midnight boundaries across DST changes.
      final start =
          DateTime(asOf.year, asOf.month, asOf.day - 27 + index * 7);
      final end = DateTime(start.year, start.month, start.day + 7);
      final weekGroups = <String, List<Attempt>>{};
      for (final attempt in attempts) {
        if (attempt.hintUsed) continue;
        final at = attempt.at.toLocal();
        if (!at.isBefore(start) && at.isBefore(end)) {
          weekGroups
              .putIfAbsent(attempt.subject, () => <Attempt>[])
              .add(attempt);
        }
      }
      weeks.add(LearningChartWeek(
        start: start,
        endExclusive: end,
        subjects: {
          for (final group in weekGroups.entries)
            group.key: LearningChartCount(
              subject: group.key,
              competency: '',
              total: group.value.length,
              correct: group.value.where((attempt) => attempt.correct).length,
            ),
        },
      ));
    }
    final recentTotals = <String, int>{};
    for (final week in weeks) {
      for (final entry in week.subjects.entries) {
        recentTotals.update(entry.key, (count) => count + entry.value.total,
            ifAbsent: () => entry.value.total);
      }
    }
    final subjects = recentTotals.keys.toList()
      ..sort((a, b) {
        final countOrder = recentTotals[b]!.compareTo(recentTotals[a]!);
        return countOrder != 0 ? countOrder : a.compareTo(b);
      });
    return LearningChartData._(
      studentId: studentId,
      asOf: asOf,
      total: attempts.length,
      correct: attempts.where((attempt) => attempt.correct).length,
      assistedTotal: attempts.where((attempt) => attempt.hintUsed).length,
      independentCorrect: attempts
          .where((attempt) => !attempt.hintUsed && attempt.correct).length,
      competencies: competencies,
      subjectActivity: activity,
      subjects: subjects,
      weeks: weeks,
    );
  }
}
