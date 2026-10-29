import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/core/lumo_personal_daily_tutor_planner.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  test('one difficult skill does not occupy the whole real-grade daily plan', () {
    final key = SkillRecord.makeId('Mathematik', 'Zehner und Einer');
    final skill = SkillRecord(skillId: key, subject: 'Mathematik', unit: 'Zehner und Einer', wrong: 5);
    final plan = const LumoPersonalDailyTutorPlanner().buildEvidencePlan({key: skill}, {}, grade: 2);
    expect(plan, hasLength(3));
    expect(plan.where((s) => s.unit == skill.unit).length, 1);
    expect(plan.any((s) => s.kind == LumoDailyTutorStepKind.confidence), isFalse);
    expect(plan.every((s) => Curriculum.unitsForGrade(s.subject, 2, currentGradeOnly: true).contains(s.unit)), isTrue);
    expect(plan[1].reason, contains('Einstieg'));
  });
  test('a single independent correct answer is not a confirmed daily strength', () {
    final at = DateTime.utc(2026, 10, 29);
    final journey = LearningJourney().recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer',
      now: at, evidence: const LearningEvidence(taskId: 'one', correct: true));
    final plan = const LumoPersonalDailyTutorPlanner().buildEvidencePlan({}, journey.records, grade: 2, now: at);
    expect(plan.any((s) => s.kind == LumoDailyTutorStepKind.confidence), isFalse);
  });
}
