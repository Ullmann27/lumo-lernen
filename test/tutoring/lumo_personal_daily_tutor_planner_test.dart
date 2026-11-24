import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_personal_daily_tutor_planner.dart';
import 'package:lumo_lernen/core/progress_repository.dart';

SkillRecord skill(String subject, String unit,
    {required int correct, required int wrong,
    int misses = 0, int streak = 0}) => SkillRecord(
  skillId: SkillRecord.makeId(subject, unit),
  subject: subject,
  unit: unit,
  correct: correct,
  wrong: wrong,
  currentMisses: misses,
  currentStreak: streak,
);

void main() {
  const planner = LumoPersonalDailyTutorPlanner();

  test('empty/insufficient evidence never invents weaknesses', () {
    expect(planner.build({}), isEmpty);
    final one = skill('Mathematik', 'Zehner und Einer',
        correct: 0, wrong: 1, misses: 1);
    expect(planner.build({one.skillId: one}), isEmpty);
  });

  test('two measured weaknesses and one verified strength become three actions', () {
    final math = skill('Mathematik', 'Zehner und Einer',
        correct: 1, wrong: 6, misses: 4);
    final reading = skill('Lesen', 'Sätze verstehen',
        correct: 1, wrong: 5, misses: 3);
    final mastered = skill('Deutsch', 'Silben',
        correct: 12, wrong: 0, streak: 5);
    final rows = planner.build({
      math.skillId: math,
      reading.skillId: reading,
      mastered.skillId: mastered,
    });
    expect(rows, hasLength(3));
    expect(rows[0].unit, math.unit);
    expect(rows[0].kind, LumoDailyTutorStepKind.revise);
    expect(rows[1].unit, reading.unit);
    expect(rows[1].kind, LumoDailyTutorStepKind.practice);
    expect(rows[2].unit, mastered.unit);
    expect(rows[2].kind, LumoDailyTutorStepKind.confidence);
    expect(rows.map((r) => r.durationMinutes), [5, 5, 3]);
  });

  test('current-grade filtering avoids foreign-grade stale topic', () {
    final old = skill('Mathematik', 'Multiplikation bis 1000',
        correct: 1, wrong: 8, misses: 5);
    final good = skill('Mathematik', 'Plus bis 10',
        correct: 1, wrong: 5, misses: 3);
    final rows = planner.build({
      old.skillId: old, good.skillId: good,
    }, isEligible: (r) => r.unit == 'Plus bis 10');
    expect(rows, hasLength(1));
    expect(rows.single.unit, 'Plus bis 10');
  });

  test('different active child maps never get merged by planner', () {
    final a = skill('Mathematik', 'Zehner und Einer',
        correct: 0, wrong: 5, misses: 5);
    final b = skill('Lesen', 'Silben',
        correct: 0, wrong: 4, misses: 4);
    expect(planner.build({a.skillId: a}).single.subject, 'Mathematik');
    expect(planner.build({b.skillId: b}).single.subject, 'Lesen');
  });

  test('good but not mastered is never labelled as confirmed strength', () {
    final partial = skill('Deutsch', 'Wortarten',
        correct: 3, wrong: 1, streak: 2);
    expect(planner.build({partial.skillId: partial}), isEmpty);
  });
}
