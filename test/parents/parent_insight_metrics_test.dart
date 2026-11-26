import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_guidance.dart';
import 'package:lumo_lernen/domain/school/parent_insight_metrics.dart';

import 'parent_insight_fixtures.dart';

/// Kennzahlen oben im Elternbereich: dieselbe Grundlage wie „Auf einen
/// Blick“, ältere Zähler bleiben gültig, nichts wird doppelt gezählt.
void main() {
  final now = DateTime.now();

  test('Leeres Profil: echte Null, Stärken/Förderbedarf noch offen', () {
    final m = ParentInsightMetrics.from(
        attempts: const [], studentId: 'kind-leer', now: now);
    expect(m.isEmpty, isTrue);
    expect(m.answers, 0);
    expect(m.streakDays, 0);
    expect(m.lastPracticeDay, isNull);
    expect(m.strengths, isNull);
    expect(m.needs, isNull);
  });

  test('36 Antworten: Kennzahlen gleich „Auf einen Blick“', () {
    final attempts = sechsunddreissigAntworten('kind-mia');
    final m = ParentInsightMetrics.from(
        attempts: attempts, studentId: 'kind-mia', now: now);
    final g = LearningGuidance.fromAttempts(attempts,
        studentId: 'kind-mia', now: now);
    expect(m.answers, 36);
    expect(m.answers, g.total);
    expect(m.loggedIndependent, 33);
    expect(m.loggedIndependent, g.independentTotal);
    expect(m.loggedIndependentCorrect, 23);
    // Addition sicher (11/12); Subtraktion (2/7), Einmaleins (5/8) und
    // Silben (5/6) unter 85 % – genau die Listen von „Auf einen Blick“.
    expect(m.strengths, 1);
    expect(m.strengths, g.strengths.length);
    expect(m.needs, 3);
    expect(m.needs, g.needs.length);
    // Heute noch nicht geübt: die Folge zählt wie in der App nur bis heute.
    expect(m.streakDays, 0);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    expect(m.lastPracticeDay, yesterday);
  });

  test('Eine richtige Antwort heute verlängert die Folge über alle Lerntage',
      () {
    final attempts = [
      ...sechsunddreissigAntworten('kind-mia'),
      antwort('kind-mia', 'heute', 'Mathematik', 'Plus bis 20',
          'Addition ohne Zehnerübergang', true, 0),
    ];
    final m = ParentInsightMetrics.from(
        attempts: attempts, studentId: 'kind-mia', now: now);
    // Richtige Antworten heute und an den Tagen 1 bis 8 davor.
    expect(m.streakDays, 9);
    expect(m.lastPracticeDay, DateTime(now.year, now.month, now.day));
  });

  test('Hilfenutzung zählt als Antwort, nicht als Nachweis', () {
    final attempts = [
      for (var i = 0; i < 6; i++)
        antwort('kind-h', 'h$i', 'Mathematik', 'Minus bis 20',
            'Subtraktion mit Zehnerübergang', true, 1,
            hilfe: true),
      for (var i = 0; i < 4; i++)
        antwort('kind-h', 'o$i', 'Mathematik', 'Minus bis 20',
            'Subtraktion mit Zehnerübergang', i > 0, 1),
    ];
    final m = ParentInsightMetrics.from(
        attempts: attempts, studentId: 'kind-h', now: now);
    expect(m.answers, 10);
    expect(m.loggedIndependent, 4);
    expect(m.loggedAssisted, 6);
    expect(m.loggedIndependentCorrect, 3);
    // Vier Antworten ohne Hilfe reichen noch nicht für eine Einordnung.
    expect(m.strengths, isNull);
    expect(m.needs, isNull);

    // Fünf richtige ohne Hilfe: sicher, auch wenn mit Hilfe Fehler passierten.
    final more = [
      ...attempts,
      antwort('kind-h', 'o4', 'Mathematik', 'Minus bis 20',
          'Subtraktion mit Zehnerübergang', true, 1),
      for (var i = 0; i < 3; i++)
        antwort('kind-h', 'hf$i', 'Mathematik', 'Minus bis 20',
            'Subtraktion mit Zehnerübergang', false, 1,
            hilfe: true),
    ];
    final sure = ParentInsightMetrics.from(
        attempts: more, studentId: 'kind-h', now: now);
    expect(sure.answers, 14);
    expect(sure.strengths, 0, reason: '4 von 5 ohne Hilfe = 80 %');
    expect(sure.needs, 1);
  });

  test('Fremde, Demo-, doppelte, zukünftige und Mess-Antworten zählen nicht',
      () {
    final echt = antwort('kind-a', 'x1', 'Mathematik', 'Plus bis 10',
        'Addition ohne Zehnerübergang', true, 1);
    final attempts = [
      echt,
      echt, // doppelt
      antwort('kind-b', 'x2', 'Mathematik', 'Plus bis 10',
          'Addition ohne Zehnerübergang', true, 1),
      antwort('kind-a', 'x3', 'IQ-Rätsel', 'Muster', 'Logisches Schließen',
          true, 1),
      Attempt(
          id: 'x4',
          studentId: 'kind-a',
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          competency: 'Addition ohne Zehnerübergang',
          correct: true,
          at: now.add(const Duration(days: 3))),
    ];
    final m = ParentInsightMetrics.from(
        attempts: attempts,
        studentId: 'kind-a',
        now: now,
        // Der Zähler kennt die echte und die zukünftige Antwort.
        skills: {
          'mathematik::plus bis 10': SkillRecord(
              skillId: 'mathematik::plus bis 10',
              subject: 'Mathematik',
              unit: 'Plus bis 10',
              correct: 2),
        });
    expect(m.loggedAnswers, 1);
    expect(m.olderAnswers, 0,
        reason: 'die zukünftige Antwort steht im Protokoll, nicht doppelt');
    expect(m.answers, 1);

    final demo = ParentInsightMetrics.from(
        attempts: [
          antwort('${LearningGuidance.demoStudentPrefix}1', 'd1', 'Mathematik',
              'Plus bis 10', 'Addition ohne Zehnerübergang', true, 1),
        ],
        studentId: '${LearningGuidance.demoStudentPrefix}1',
        now: now);
    expect(demo.answers, 0);
  });

  test('Ältere Zähler ohne Protokoll bleiben gültig und zählen einmal', () {
    String day(int back) {
      final d = DateTime(now.year, now.month, now.day - back);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    final skills = {
      'mathematik::plus bis 10': SkillRecord(
          skillId: 'mathematik::plus bis 10',
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          correct: 30,
          wrong: 10),
      'mathematik::uhrzeit': SkillRecord(
          skillId: 'mathematik::uhrzeit',
          subject: 'Mathematik',
          unit: 'Uhrzeit',
          correct: 9,
          wrong: 3),
      // Protokoll hat hier mehr als der Zähler: nie negativ.
      'deutsch::silben': SkillRecord(
          skillId: 'deutsch::silben',
          subject: 'Deutsch',
          unit: 'Silben',
          correct: 1),
    };
    final attempts = [
      for (var i = 0; i < 5; i++)
        antwort('kind-alt', 'p$i', 'Mathematik', 'Plus bis 10',
            'Addition ohne Zehnerübergang', true, 3),
      for (var i = 0; i < 2; i++)
        antwort('kind-alt', 's$i', 'Deutsch', 'Silben', 'Silben', true, 3),
    ];
    final m = ParentInsightMetrics.from(
        attempts: attempts,
        studentId: 'kind-alt',
        now: now,
        skills: skills,
        daily: {day(1): 4, day(2): 2, day(5): 1});
    expect(m.loggedAnswers, 7);
    expect(m.olderAnswers, 35 + 12);
    expect(m.answers, 54);
    // Heute noch nichts; gestern war der letzte Lerntag.
    expect(m.streakDays, 0);
    expect(m.lastPracticeDay, DateTime(now.year, now.month, now.day - 1));
    // Stärken nur aus datierten Protokollantworten (Addition 5/5).
    expect(m.strengths, 1);
    expect(m.needs, 0);

    final today = ParentInsightMetrics.from(
        attempts: attempts,
        studentId: 'kind-alt',
        now: now,
        skills: skills,
        daily: {day(0): 1, day(1): 4, day(2): 2, day(5): 1});
    // Heute, gestern, vorgestern aus dem Tageszähler, Tag 3 aus dem Protokoll.
    expect(today.streakDays, 4);
  });

  test('Nur ältere Zähler: Antworten sichtbar, Stärken noch offen', () {
    final m = ParentInsightMetrics.from(
        attempts: const [],
        studentId: 'kind-nur-alt',
        now: now,
        skills: {
          'mathematik::plus bis 10': SkillRecord(
              skillId: 'mathematik::plus bis 10',
              subject: 'Mathematik',
              unit: 'Plus bis 10',
              correct: 18,
              wrong: 2),
        });
    expect(m.isEmpty, isFalse);
    expect(m.loggedAnswers, 0);
    expect(m.olderAnswers, 20);
    expect(m.strengths, isNull);
    expect(m.needs, isNull);
  });
}
