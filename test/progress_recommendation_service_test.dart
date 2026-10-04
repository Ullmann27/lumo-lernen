import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/progress_recommendation_service.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  const service = ProgressRecommendationService();
  final now = DateTime(2026, 10, 2, 12);

  SkillRecord record(
    String subject,
    String unit, {
    int correct = 0,
    int wrong = 0,
    int misses = 0,
    int streak = 0,
    int daysAgo = 0,
  }) =>
      SkillRecord(
        skillId: SkillRecord.makeId(subject, unit),
        subject: subject,
        unit: unit,
        correct: correct,
        wrong: wrong,
        currentMisses: misses,
        currentStreak: streak,
        difficulty: 3,
        lastSeen: now.subtract(Duration(days: daysAgo)),
      );

  LearningActivityRecommendation recommend(
    List<SkillRecord> records, {
    int grade = 2,
    String? subject,
  }) =>
      service.recommend(
        grade: grade,
        skills: {for (final record in records) record.skillId: record},
        preferredSubject: subject,
        now: now,
      );

  test('empty progress gives an honest concrete start for each grade', () {
    const units = [
      'Plus bis 10',
      'Plus bis 20',
      'Einmaleins',
      'Schriftliche Multiplikation'
    ];
    for (var grade = 1; grade <= 4; grade++) {
      final result = recommend([], grade: grade);
      expect(result.kind, LearningRecommendationKind.firstSteps);
      expect(result.grade, grade);
      expect(result.unit, units[grade - 1]);
      expect(result.evidenceAttempts, 0);
      expect(result.reason, contains('noch keine'));
    }
  });

  test('repeated errors take priority and carry real evidence', () {
    final weak = record('Deutsch', 'Silben', correct: 1, wrong: 4, misses: 3);
    final result = recommend(
        [weak, record('Mathematik', 'Plus bis 20', correct: 2, daysAgo: 4)]);
    expect(result.kind, LearningRecommendationKind.support);
    expect(result.subject, 'Deutsch');
    expect(result.unit, 'Silben');
    expect(result.isTutoring, isTrue);
    expect(result.suggestedDifficulty, 2);
    expect(result.reason, contains('4 von 5'));
    expect(weak.correct, 1);
    expect(weak.difficulty, 3);
  });

  test('one error does not label a child as needing remediation', () {
    final result =
        recommend([record('Mathematik', 'Plus bis 20', wrong: 1, misses: 1)]);
    expect(result.kind, LearningRecommendationKind.continueTopic);
    expect(result.isTutoring, isFalse);
  });

  test('recent successes release a child from historical remediation', () {
    final result = recommend([
      record('Mathematik', 'Plus bis 20', correct: 3, wrong: 15, streak: 3)
    ]);
    expect(result.kind, LearningRecommendationKind.continueTopic);
  });

  test('stale topics are refreshed before untried ones', () {
    final result = recommend([
      record('Mathematik', 'Plus bis 20', correct: 8, streak: 5, daysAgo: 4),
      record('Deutsch', 'Silben', correct: 1),
    ]);
    expect(result.kind, LearningRecommendationKind.refresh);
    expect(result.unit, 'Plus bis 20');
    expect(result.reason, contains('4 Tage'));
  });

  test('unavailable future-grade topics and unknown keys are excluded', () {
    final result = recommend([
      record('Mathematik', 'Schriftliche Division', wrong: 20, misses: 20),
      record('Deutsch', 'Not a real unit', wrong: 20, misses: 20),
      record('Unknown subject', 'Silben', wrong: 20, misses: 20),
    ], grade: 1);
    expect(result.kind, LearningRecommendationKind.firstSteps);
    expect(result.unit, 'Plus bis 10');
  });

  test('a preferred subject keeps suggestions inside the selected subject', () {
    final result = recommend([
      record('Mathematik', 'Plus bis 20', wrong: 9, misses: 9),
      record('Deutsch', 'Silben', correct: 2),
    ], subject: 'Deutsch');
    expect(result.subject, 'Deutsch');
    expect(result.kind, LearningRecommendationKind.continueTopic);
  });

  test('fresh mastered topics lead to a different, untried topic', () {
    final result = recommend(
        [record('Mathematik', 'Plus bis 20', correct: 10, streak: 5)]);
    expect(result.kind, LearningRecommendationKind.explore);
    expect(result.unit, isNot('Plus bis 20'));
    expect(result.evidenceAttempts, 0);
  });

  test('grade and counters are normalized without modifying the input', () {
    final bad = record('Mathematik', 'Plus bis 10', correct: -2, wrong: -3);
    expect(recommend([bad], grade: -1).grade, 1);
    expect(recommend([], grade: 99).grade, 4);
    expect(bad.correct, -2);
    expect(bad.wrong, -3);
  });

  test('tie breaking does not depend on map insertion order', () {
    final a = record('Mathematik', 'Plus bis 20', wrong: 3, misses: 3);
    final b = record('Deutsch', 'Silben', wrong: 3, misses: 3);
    expect(recommend([a, b]).subject, recommend([b, a]).subject);
    expect(recommend([a, b]).unit, recommend([b, a]).unit);
  });

  test(
      'new recommendations generate tasks in their advertised subject and unit',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final subject in Curriculum.subjects.keys) {
        final result = recommend([], grade: grade, subject: subject);
        final task = ExerciseFactory(seed: 42).next(
          grade: result.grade,
          subject: result.subject,
          unit: result.unit,
        );
        expect(task.subject, result.subject, reason: '$grade/$subject');
        expect(task.unit, result.unit, reason: '$grade/$subject');
      }
    }
  });
}
