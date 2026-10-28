import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/lumo_personal_daily_tutor_planner.dart';
import 'package:lumo_lernen/core/progress_repository.dart';

void main() {
  const planner = LumoPersonalDailyTutorPlanner();
  final at = DateTime.utc(2026, 10, 28);
  LearningJourney add(LearningJourney j, String id,
          {bool correct = true,
          int help = 0,
          bool transfer = false,
          DateTime? time,
          String unit = 'Plus bis 10'}) =>
      j.recordEvidence(
          subject: 'Mathematik',
          unit: unit,
          now: time ?? at,
          evidence: LearningEvidence(
              taskId: id,
              problemId: 'problem-$id',
              correct: correct,
              helpLevel: help,
              transferCheck: transfer));

  test('one mistake is insufficient evidence; assistance is not a strength',
      () {
    var j = add(LearningJourney(), 'one', correct: false);
    expect(planner.knowledge(j.records.values.single),
        LumoKnowledgeStatus.insufficient);
    j = add(j, 'two', help: 2);
    expect(planner.knowledge(j.records.values.single),
        LumoKnowledgeStatus.assisted);
    final steps = planner.buildEvidencePlan({}, j.records, now: at);
    expect(steps, hasLength(3));
    expect(
        steps.any((s) => s.kind == LumoDailyTutorStepKind.confidence), isFalse);
    expect(steps.last.kind, LumoDailyTutorStepKind.check);
    expect(steps.every((s) => s.unit == 'Plus bis 10'), isTrue);
    expect(steps.every((s) => s.durationMinutes >= 3 && s.durationMinutes <= 5),
        isTrue);
  });

  test('review, independent and retained statuses follow actual observations',
      () {
    var j = add(LearningJourney(), 'one', correct: false);
    j = add(j, 'two', correct: false);
    j = add(j, 'three', correct: false);
    expect(
        planner.knowledge(j.records.values.single), LumoKnowledgeStatus.review);
    j = add(j, 'four');
    expect(planner.knowledge(j.records.values.single),
        LumoKnowledgeStatus.independent);
    j = add(j, 'five', transfer: true);
    j = add(j, 'six', time: at.add(const Duration(days: 2)));
    expect(planner.knowledge(j.records.values.single),
        LumoKnowledgeStatus.retained);
  });

  test(
      'profile evidence, current grade and real durations guide all three actions',
      () {
    var j = add(LearningJourney(), 'a', correct: false);
    j = add(j, 'b', correct: false);
    j = add(j, 'c', correct: false);
    j = add(j, 'd', unit: 'Brüche');
    final records = {
      for (final r in j.records.values)
        SkillRecord.makeId(r.subject, r.unit): SkillRecord(
            skillId: SkillRecord.makeId(r.subject, r.unit),
            subject: r.subject,
            unit: r.unit,
            wrong: 3)
    };
    final plan = planner.buildEvidencePlan(records, j.records,
        now: at, isEligible: (r) => r.unit == 'Plus bis 10');
    expect(plan, hasLength(3));
    expect(plan.every((s) => s.unit == 'Plus bis 10'), isTrue);
    expect(plan.first.reason, contains('Wiederholungsbedarf'));
    expect(plan.first.description, contains('Min.'));
    expect(planner.buildEvidencePlan({}, {}), isEmpty);
  });
}
