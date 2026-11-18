import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/domain/analysis/daily_recommendation_engine.dart';
import 'package:lumo_lernen/domain/learning/independent_evidence.dart';
import 'package:lumo_lernen/domain/learning/skill_evidence.dart';
import 'package:shared_preferences/shared_preferences.dart';

SkillRecord _record({
  String unit = 'Plus bis 10',
  int correct = 0,
  int wrong = 0,
  int hints = 0,
  IndependentEvidence? independent,
  List<String> days = const [],
}) =>
    SkillRecord(
      skillId: SkillRecord.makeId('Mathematik', unit),
      subject: 'Mathematik',
      unit: unit,
      correct: correct,
      wrong: wrong,
      hintCount: hints,
      independentEvidence: independent,
      independentDays: days,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SkillEvidence stages', () {
    test('below five recorded answers: am Anfang, never a percentage', () {
      for (var answers = 1; answers < 5; answers++) {
        final evidence = SkillEvidence.from(
          answers: answers,
          independent: IndependentEvidence(correct: answers),
          independentDays: 3,
        );
        expect(evidence.stage, SkillEvidenceStage.starting);
        expect(evidence.label, 'am Anfang ($answers von 5)');
        expect(evidence.label, isNot(contains('%')));
      }
    });

    test('sicher needs enough tasks solved alone on two different days', () {
      SkillEvidence at({required int alone, required int days, int wrong = 0}) =>
          SkillEvidence.from(
            answers: alone + wrong,
            independent: IndependentEvidence(correct: alone, wrong: wrong),
            independentDays: days,
          );

      // Enough tasks, but all on one day: not yet.
      expect(at(alone: 9, days: 1).stage, SkillEvidenceStage.practicing);
      expect(at(alone: 9, days: 1).facts,
          '9 Aufgaben allein gelöst · noch an einem zweiten Tag zeigen');
      // Two days, but too few tasks solved alone.
      expect(at(alone: 5, days: 2).stage, SkillEvidenceStage.practicing);
      // Enough of both.
      final secure = at(alone: 6, days: 2);
      expect(secure.stage, SkillEvidenceStage.secure);
      expect(secure.label, 'sicher');
      expect(secure.facts, '6 Aufgaben allein gelöst an 2 Tagen');
      // Many mistakes keep the topic "in Übung".
      expect(at(alone: 6, days: 3, wrong: 4).stage,
          SkillEvidenceStage.practicing);
    });

    test('answers with help never make a topic sicher', () {
      // Twelve right answers, every one with help.
      final record = _record(
          correct: 12, hints: 12, independent: const IndependentEvidence());
      expect(record.evidence.stage, SkillEvidenceStage.practicing);
      expect(record.evidence.label, 'in Übung');
      expect(record.evidence.facts, '0 Aufgaben allein gelöst');
    });
  });

  group('SkillRecord day evidence', () {
    test('a record saved before days were kept counts as one day', () {
      final legacy = _record(correct: 8);
      expect(legacy.independentDays, isEmpty);
      expect(legacy.independentDayCount, 1);
      // Honest default: one more day of solving alone confirms "sicher".
      expect(legacy.evidence.stage, SkillEvidenceStage.practicing);
      legacy
        ..noteIndependentDay('2026-11-16')
        ..noteIndependentDay('2026-11-17');
      expect(legacy.evidence.stage, SkillEvidenceStage.secure);
    });

    test('days are distinct, valid and bounded', () {
      final record = _record(correct: 1);
      for (var day = 1; day <= 12; day++) {
        record.noteIndependentDay('2026-11-${day.toString().padLeft(2, '0')}');
      }
      record.noteIndependentDay('2026-11-12');
      expect(record.independentDays.length, SkillRecord.maxIndependentDays);
      expect(record.independentDays.last, '2026-11-12');
      expect(SkillRecord.cleanDays(['x', 7, '2026-01-02', '2026-01-02']),
          ['2026-01-02']);
    });

    test('the skill record format itself is unchanged', () {
      final json = _record(correct: 2, days: ['2026-11-17']).toJson();
      expect(json.keys.toSet(), {
        'skillId',
        'subject',
        'unit',
        'correct',
        'wrong',
        'hintCount',
        'currentStreak',
        'currentMisses',
        'difficulty',
        'lastSeen',
        'independentEvidence',
      });
    });

    test('days survive a reload and only count answers solved alone',
        () async {
      final engine = LearningProfileEngine(
          repository: ProgressRepository(studentId: 'child-1'));
      await engine.recordAnswer(
          subject: 'Mathematik', unit: 'Plus bis 10', isCorrect: true);
      await engine.recordAnswer(
          subject: 'Mathematik',
          unit: 'Minus bis 10',
          isCorrect: true,
          hintUsed: true);
      await engine.recordAnswer(
          subject: 'Mathematik', unit: 'Zahlenreihe', isCorrect: false);

      final reloaded = LearningProfileEngine(
          repository: ProgressRepository(studentId: 'child-1'));
      await reloaded.load();
      final skills = reloaded.skills;
      expect(
          skills[SkillRecord.makeId('Mathematik', 'Plus bis 10')]!
              .independentDays,
          hasLength(1));
      expect(
          skills[SkillRecord.makeId('Mathematik', 'Minus bis 10')]!
              .independentDays,
          isEmpty,
          reason: 'solved together is not independent evidence');
      expect(
          skills[SkillRecord.makeId('Mathematik', 'Zahlenreihe')]!
              .independentDays,
          isEmpty);

      await reloaded.reset();
      final afterReset = LearningProfileEngine(
          repository: ProgressRepository(studentId: 'child-1'));
      await afterReset.load();
      expect(afterReset.skills, isEmpty);
    });

    test('unreadable day data never blocks the saved answers', () async {
      final repository = ProgressRepository(studentId: 'child-2');
      await repository.saveSkills({
        'a': _record(correct: 3, days: ['2026-11-17'])
      });
      final prefs = await SharedPreferences.getInstance();
      final key = prefs
          .getKeys()
          .singleWhere((k) => k.startsWith('lumo_progress_independent_days_v1'));
      await prefs.setString(key, '{broken');
      final loaded = await repository.loadSkills();
      expect(loaded.values.single.correct, 3);
      expect(loaded.values.single.independentDays, isEmpty);
    });
  });

  group('parent strengths', () {
    test('one right answer is not a strength; secured evidence is', () {
      const engine = ParentReportEngine();
      final lucky = _record(unit: 'Plus bis 10', correct: 1);
      final secured = _record(
        unit: 'Minus bis 10',
        correct: 8,
        days: ['2026-11-15', '2026-11-17'],
      );
      final report = engine.buildReport(
        childName: 'Mia',
        skills: {lucky.skillId: lucky, secured.skillId: secured},
        readingSummaries: const [],
      );
      final math = report.math;
      expect(math.strengths,
          ['Minus bis 10 (8 Aufgaben allein gelöst an 2 Tagen)']);
      expect(math.strengths.join(), isNot(contains('%')));
    });
  });
}
