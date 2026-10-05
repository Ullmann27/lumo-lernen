import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/competency.dart';
import 'package:lumo_lernen/domain/school/learning_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

Attempt _a(int i, String comp, bool ok, {DateTime? at, int? ms}) => Attempt(
      id: 't$i',
      studentId: 'self',
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      competency: comp,
      correct: ok,
      at: at ?? DateTime(2026, 10, 5, 10, i % 60),
      durationMs: ms,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CompetencyClassifier', () {
    const c = CompetencyClassifier();
    String k(String prompt, [String subject = 'Mathematik']) =>
        c.classify(subject: subject, unit: 'Plus bis 20', prompt: prompt);

    test('Addition mit und ohne Zehnerübergang', () {
      expect(k('8 + 5 = ?'), 'Addition mit Zehnerübergang');
      expect(k('12 + 5 = ?'), 'Addition ohne Zehnerübergang');
      expect(k('9+1'), 'Addition mit Zehnerübergang');
    });

    test('Subtraktion mit und ohne Zehnerübergang', () {
      expect(k('13 − 5 = ?'), 'Subtraktion mit Zehnerübergang');
      expect(k('15 - 3 = ?'), 'Subtraktion ohne Zehnerübergang');
    });

    test('Einmaleins, Division und Rückfall auf das Thema', () {
      expect(k('3 × 4 = ?'), 'Einmaleins');
      expect(k('12 : 3 = ?'), 'Division');
      expect(k('Welcher Buchstabe fehlt?', 'Deutsch'), 'Plus bis 20');
    });
  });

  group('LearningAnalysis', () {
    final list = <Attempt>[
      for (var i = 0; i < 14; i++)
        _a(i, 'Addition mit Zehnerübergang', i >= 7, ms: 8000),
      for (var i = 20; i < 33; i++)
        _a(i, 'Addition ohne Zehnerübergang', i != 22 && i != 23 ? true : i == 99),
    ];

    test('erkennt Schwäche und vergleicht mit dem sicheren Gegenstück', () {
      final r = LearningAnalysis.analyze(list, now: DateTime(2026, 10, 5, 12));
      final texts = r.insights.map((i) => i.text).toList();
      expect(texts.first,
          'Bei 14 Aufgaben zu „Addition mit Zehnerübergang“ gab es 7 Fehler.');
      expect(
          texts.any((t) => t.contains('„Addition ohne Zehnerübergang“') &&
              t.contains('dagegen bei 85\u00A0%')),
          isTrue);
      expect(r.suggestion!.text,
          'Empfehlung: 10 Minuten „Addition mit Zehnerübergang“ mit visuellen Zehnerfeldern.');
    });

    test('unter fünf Versuchen gibt es kein Urteil', () {
      final r = LearningAnalysis.analyze(
          [_a(1, 'Einmaleins', false), _a(2, 'Einmaleins', false)]);
      expect(r.stats.single.level, MasteryLevel.unknown);
      expect(r.insights, isEmpty);
      expect(r.suggestion, isNull);
    });

    test('Lernzeit, letzte Aktivität und 14-Tage-Verlauf', () {
      final r = LearningAnalysis.analyze(list, now: DateTime(2026, 10, 5, 12));
      expect(r.totalAttempts, 27);
      expect(r.totalMinutes, 2); // 14 × 8 s = 112 s
      expect(r.lastActivity, isNotNull);
      expect(r.days.length, 14);
      expect(r.days.last.total, 27);
    });

    test('Leere Liste ist harmlos', () {
      final r = LearningAnalysis.analyze(const []);
      expect(r.totalAttempts, 0);
      expect(r.lastActivity, isNull);
      expect(r.stats, isEmpty);
    });
  });

  group('AttemptLogRepository', () {
    test('speichert, lädt und vermeidet Duplikate', () async {
      final repo = AttemptLogRepository();
      final a = _a(1, 'Einmaleins', true);
      await repo.append(a);
      await repo.append(a);
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.single.competency, 'Einmaleins');
    });

    test('kappt auf maxEntries und behält die neuesten', () async {
      final repo = AttemptLogRepository(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        await repo.append(_a(i, 'Einmaleins', true));
      }
      expect((await repo.load()).map((a) => a.id), ['t2', 't3', 't4']);
    });

    test('kaputte Daten werden verworfen statt zu crashen', () async {
      SharedPreferences.setMockInitialValues({'lumo_attempt_log_v1': '{kaputt'});
      expect(await AttemptLogRepository().load(), isEmpty);
    });
  });

  test('recordLearningAnswer schreibt ein Protokoll mit Kompetenz', () async {
    final app = LumoAppState();
    await app.recordLearningAnswer(
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      correct: false,
      prompt: '8 + 5 = ?',
      given: '12',
      expected: '13',
      durationMs: 7000,
    );
    final log = await app.attemptLog.load();
    expect(log.length, 1);
    expect(log.single.competency, 'Addition mit Zehnerübergang');
    expect(log.single.given, '12');
    expect(log.single.correct, isFalse);
    app.dispose();
  });
}
