import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/learning/learning_dna_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const engine = LearningDnaEngine();

  for (final grade in [1, 2, 3, 4]) {
    test('new grade $grade profile has no invented strengths or weaknesses',
        () {
      final dna = engine.compute(state: LumoSessionState(grade: grade));
      expect(dna.strengths, isEmpty);
      expect(dna.weaknesses, isEmpty);
      expect(dna.totalCorrect, 0);
      expect(dna.totalIncorrect, 0);
      expect(dna.recentProgress.toLowerCase(), contains('keine antwortdaten'));
      expect(dna.totalSessions, isNull);
    });
  }

  test('untimed legacy counters cannot create competency or current-day claims',
      () {
    final dna = engine.compute(
        state: LumoSessionState(
      grade: 4,
      solved: {'Mathematik': 999},
      weakSkills: {'Deutsch:Artikel': 8},
      stars: 800,
    ));
    expect(dna.strengths, isEmpty);
    expect(dna.weaknesses, isEmpty);
    expect(dna.totalCorrect + dna.totalIncorrect, 0);
    expect(dna.recentProgress, isNot(contains('Heute')));
    expect(dna.recentProgress, isNot(contains('Woche')));
    expect(dna.frustrationSignals, isEmpty);
  });

  test(
      'answer ratios use actual subject, topic and counts without mutating records',
      () {
    final id = SkillRecord.makeId('Mathematik', 'Plus bis 20');
    final record = SkillRecord(
        skillId: id,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        correct: 7,
        wrong: 3);
    final before = record.toJson();
    final dna = engine.compute(
        state: LumoSessionState(solved: {'legacy': 900}), skills: {id: record});
    final entry = dna.skillObservations.single;
    expect(entry.subject, 'Mathematik');
    expect(entry.skillLabel, 'Plus bis 20');
    expect(entry.score, closeTo(0.7, 0.00001));
    expect(entry.answerCount, 10);
    expect(entry.answerSummary, '70% · 7 von 10 Antworten richtig');
    expect(entry.confidence, 0);
    expect(dna.strengths, hasLength(1));
    expect(dna.totalCorrect, 7);
    expect(dna.totalIncorrect, 3);
    expect(record.toJson(), before);
    expect(dna.recentProgress, contains('Gesamt: 10 Antworten'));
    expect(dna.recentProgress, isNot(contains('Heute')));
  });

  for (final count in [1, 2, 9]) {
    test(
        '$count correct answers remain a small sample, not a strength diagnosis',
        () {
      final record = SkillRecord(
          skillId: 'small',
          subject: 'Deutsch',
          unit: 'Artikel',
          correct: count);
      final dna =
          engine.compute(state: LumoSessionState(), skills: {'small': record});
      final entry = dna.skillObservations.single;
      expect(entry.score, 1);
      expect(entry.answerCount, count);
      expect(entry.sampleNote, contains('Kleine Stichprobe'));
      expect(entry.answerSummary, contains('$count von $count'));
      expect(dna.strengths, isEmpty);
      expect(dna.weaknesses, isEmpty);
    });
  }

  test(
      'unanswered topics have no percentage or weakness; wrong answers preserve recommendations',
      () {
    final empty =
        SkillRecord(skillId: 'empty', subject: 'Lesen', unit: 'Geschichten');
    final wrong = SkillRecord(
        skillId: 'wrong',
        subject: 'Deutsch',
        unit: 'Artikel',
        correct: 2,
        wrong: 8);
    final dna = engine.compute(
        state: LumoSessionState(), skills: {'empty': empty, 'wrong': wrong});
    final noData =
        dna.skillObservations.firstWhere((e) => e.subject == 'Lesen');
    expect(noData.answerSummary, 'Noch keine Antworten');
    expect(noData.isWeakness, false);
    expect(dna.weaknesses.single.skillLabel, 'Artikel');
    expect(dna.nextRecommendation!.suggestedUnit, 'Artikel');
    expect(dna.nextRecommendation!.reason, contains('2 von 10'));
    expect(dna.frustrationSignals, isEmpty);
    expect(dna.totalSessions, isNull);
  });

  test(
      'profile switch and restart use isolated saved SkillRecord data, even with the same name',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(childName: 'Testkind'));
    await app.school.setActiveStudent('dna-student-a');
    for (var i = 0; i < 10; i++) {
      await app.recordLearningAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          correct: i < 7,
          requireSaved: true);
    }
    final a = engine.compute(state: app.state, skills: app.learningSkills());
    expect(a.totalCorrect, 7);
    expect(a.totalIncorrect, 3);
    await app.school.setActiveStudent('dna-student-b');
    await app.loadLearningProfile();
    final b = engine.compute(state: app.state, skills: app.learningSkills());
    expect(b.skillObservations, isEmpty);
    expect(b.strengths, isEmpty);
    await app.recordLearningAnswer(
        subject: 'Deutsch',
        unit: 'Artikel',
        correct: false,
        requireSaved: true);
    final savedB =
        engine.compute(state: app.state, skills: app.learningSkills());
    expect(savedB.totalCorrect, 0);
    expect(savedB.totalIncorrect, 1);
    expect(savedB.skillObservations.single.subject, 'Deutsch');
    final restarted = LumoAppState();
    addTearDown(restarted.dispose);
    await restarted.school.setActiveStudent('dna-student-a');
    await restarted.loadLearningProfile();
    final restored = engine.compute(
        state: restarted.state, skills: restarted.learningSkills());
    expect(restored.totalCorrect, 7);
    expect(restored.totalIncorrect, 3);
    expect(restored.skillObservations.single.subject, 'Mathematik');
  });

  test(
      'parent prompt carries measured counts and excludes fabricated time periods',
      () {
    final entry = SkillRecord(
        skillId: 's',
        subject: 'Deutsch',
        unit: 'Artikel',
        correct: 1,
        wrong: 1);
    final dna = engine.compute(
        state: LumoSessionState(childName: 'PrivateTestName'),
        skills: {'s': entry});
    final prompt = dna.parentAnalysisPrompt(grade: 2);
    expect(prompt, contains('Gesamt: 2 Antworten, 1 richtig, 1 falsch'));
    expect(prompt, contains('50% · 1 von 2'));
    expect(prompt, contains('Kleine Stichprobe'));
    expect(prompt, contains('ohne abgegrenzten Zeitraum'));
    expect(prompt, contains('Keine Aussagen über heute, diese Woche'));
    expect(prompt, isNot(contains('Was lief diese Woche gut')));
    expect(prompt, isNot(contains('PrivateTestName')));
  });
  test(
      'large profile prompt respects transport budget without losing evidence limits',
      () {
    final records = <String, SkillRecord>{
      for (var i = 0; i < 40; i++)
        '$i': SkillRecord(
            skillId: '$i',
            subject: 'Mathematik',
            unit: 'Lernthema Nummer $i',
            correct: 7,
            wrong: 3),
    };
    final dna = engine.compute(state: LumoSessionState(), skills: records);
    final prompt = dna.parentAnalysisPrompt(grade: 4);
    expect(prompt.length, lessThanOrEqualTo(1200));
    expect(prompt, contains('Gesamt: 400 Antworten, 280 richtig, 120 falsch'));
    expect(prompt, contains('ohne abgegrenzten Zeitraum'));
    expect(prompt, contains('Keine Aussagen über heute, diese Woche'));
    expect(prompt, contains('70% · 7 von 10 Antworten richtig'));
    expect(prompt, contains('Themen nicht einzeln aufgeführt'));
    expect(prompt, endsWith('keine Kompetenzdiagnose.\n'));
  });
}
