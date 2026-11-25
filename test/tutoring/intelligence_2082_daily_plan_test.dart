import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/lumo_personal_daily_tutor_planner.dart';
import 'package:lumo_lernen/core/progress_repository.dart';

LearningJourney observe(
  LearningJourney journey,
  String id,
  DateTime at, {
  String unit = 'Plus bis 10',
  bool correct = true,
  bool transfer = false,
  int help = 0,
}) =>
    journey.recordEvidence(
      subject: 'Mathematik',
      unit: unit,
      now: at,
      evidence: LearningEvidence(
        taskId: id,
        problemId: 'problem-$id',
        correct: correct,
        transferCheck: transfer,
        helpLevel: help,
      ),
    );

SkillRecord unknownSkill(String unit) => SkillRecord(
      skillId: SkillRecord.makeId('Mathematik', unit),
      subject: 'Mathematik',
      unit: unit,
      lastSeen: DateTime.utc(2026, 1, 1),
    );

LearningJourney retainedJourney(DateTime at) {
  var journey = observe(LearningJourney(), 'retained-a', at);
  journey = observe(journey, 'retained-b', at, transfer: true);
  return observe(
      journey, 'retained-c', at.add(const Duration(days: 2)));
}

void main() {
  const planner = LumoPersonalDailyTutorPlanner();
  final at = DateTime.utc(2026, 11, 20);

  test('due recall precedes an old unassessed topic without claiming forgetting',
      () {
    final journey = retainedJourney(at);
    final due = journey.records.values.single.dueAt;
    expect(journey.records.values.single.status, JourneyStatus.retained);
    final unknown = unknownSkill('Minus bis 10');
    final plan = planner.buildEvidencePlan(
      {unknown.skillId: unknown},
      journey.records,
      grade: 1,
      now: due,
    );
    expect(plan.first.unit, 'Plus bis 10');
    expect(plan.first.kind, LumoDailyTutorStepKind.revise);
    expect(plan.first.reason, contains('Wiederholung'));
    expect(plan.first.reason, isNot(contains('vergessen')));
    expect(plan.first.reason, isNot(contains('Wiederholungsbedarf')));
  });

  test('a not-yet-due successful skill remains practice', () {
    final journey = retainedJourney(at);
    final beforeDue = journey.records.values.single.dueAt
        .subtract(const Duration(seconds: 1));
    final plan = planner.buildEvidencePlan(
      {},
      journey.records,
      grade: 1,
      now: beforeDue,
    );
    expect(plan.first.kind, LumoDailyTutorStepKind.practice);
    expect(plan.first.reason, LumoKnowledgeStatus.retained.label);
  });

  test('repeated observed errors remain the first supported learning action',
      () {
    var journey = retainedJourney(at);
    for (var i = 0; i < 3; i++) {
      journey = observe(journey, 'minus-$i',
          at.add(const Duration(days: 5)),
          unit: 'Minus bis 10', correct: false);
    }
    final plan = planner.buildEvidencePlan(
      {},
      journey.records,
      grade: 1,
      now: at.add(const Duration(days: 5)),
    );
    expect(plan.first.unit, 'Minus bis 10');
    expect(plan.first.kind, LumoDailyTutorStepKind.revise);
    expect(plan.first.reason, LumoKnowledgeStatus.review.label);
  });

  test('grade balancing respects an eligibility limit for every new unit', () {
    var journey = LearningJourney();
    for (var i = 0; i < 3; i++) {
      journey = observe(journey, 'wrong-$i', at, correct: false);
    }
    final plan = planner.buildEvidencePlan(
      {},
      journey.records,
      grade: 1,
      now: at,
      isEligible: (record) =>
          record.subject == 'Mathematik' && record.unit == 'Plus bis 10',
    );
    expect(plan, hasLength(1));
    expect(plan.single.unit, 'Plus bis 10');
    expect(plan.single.kind, LumoDailyTutorStepKind.revise);
    expect(plan.single.reason, LumoKnowledgeStatus.review.label);
  });

  test('balancing cannot reintroduce a rejected stored or curriculum topic', () {
    var journey = observe(LearningJourney(), 'plus', at);
    journey = observe(journey, 'minus', at, unit: 'Minus bis 10');
    final plan = planner.buildEvidencePlan(
      {},
      journey.records,
      grade: 1,
      now: at,
      isEligible: (record) =>
          record.subject == 'Mathematik' &&
          {'Plus bis 10', 'Mengenvergleich'}.contains(record.unit),
    );
    expect(plan, isNotEmpty);
    expect(plan.every((step) =>
        step.subject == 'Mathematik' &&
        {'Plus bis 10', 'Mengenvergleich'}.contains(step.unit)), isTrue);
  });

  test('one correct answer without transfer is never a confirmed strength', () {
    final journey = observe(LearningJourney(), 'one-answer', at);
    final plan =
        planner.buildEvidencePlan({}, journey.records, now: at);
    expect(plan, isNotEmpty);
    expect(plan.any((step) =>
        step.kind == LumoDailyTutorStepKind.confidence), isFalse);
    expect(plan.last.kind, LumoDailyTutorStepKind.check);
  });

  test('an old single error remains unassessed and plans do not mutate evidence',
      () {
    final journey =
        observe(LearningJourney(), 'single-error', at, correct: false);
    final before = journey.records.values.single.toJson();
    final plan = planner.buildEvidencePlan(
      {},
      journey.records,
      now: at.add(const Duration(days: 30)),
      grade: 1,
    );
    expect(plan.first.kind, LumoDailyTutorStepKind.check);
    expect(plan.first.reason, LumoKnowledgeStatus.insufficient.label);
    expect(journey.records.values.single.toJson(), before);
  });
}
