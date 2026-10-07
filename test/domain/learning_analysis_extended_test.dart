import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlakyLog extends AttemptLogRepository {
  bool fail = true;
  int calls = 0;
  @override
  Future<void> appendAll(List<Attempt> attempts) async {
    calls++;
    if (fail) throw StateError('disk full');
    await super.appendAll(attempts);
  }
}

Attempt _m(int i, bool ok, {String given = '3', String expected = '13'}) =>
    Attempt(
      id: 'm$i',
      studentId: 'self',
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      competency: 'Addition mit Zehnerübergang',
      correct: ok,
      at: DateTime(2026, 10, 1).add(Duration(minutes: i)),
      prompt: '8 + 5 = ?',
      given: ok ? expected : given,
      expected: expected,
      durationMs: 5000,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Trend: früher viele Fehler, zuletzt sicher → positiver Trend', () {
    final list = [
      for (var i = 0; i < 6; i++) _m(i, false),
      for (var i = 6; i < 12; i++) _m(i, true),
    ];
    final r = LearningAnalysis.analyze(list, now: DateTime(2026, 10, 2));
    final s = r.stats.single;
    expect(s.trend, 100);
    expect(r.insights.any((i) => i.kind == InsightKind.trend && i.text.contains('wird besser')),
        isTrue);
  });

  test('Wiederholtes Fehlermuster wird benannt', () {
    final list = [for (var i = 0; i < 5; i++) _m(i, i == 4)];
    final r = LearningAnalysis.analyze(list);
    expect(r.stats.single.patterns.first, ('Zehner beim Übergang vergessen', 4));
    expect(
        r.insights.any((i) =>
            i.kind == InsightKind.pattern &&
            i.text ==
                'Wiederholter Fehler bei „Addition mit Zehnerübergang“: Zehner beim Übergang vergessen (4×).'),
        isTrue);
  });

  test('Lesen: Genauigkeit, Lesetempo und schwierige Wörter', () {
    final list = [
      for (var i = 0; i < 6; i++)
        Attempt(
          id: 'r$i',
          studentId: 'self',
          subject: 'Lesen',
          unit: 'Sätze vorlesen',
          competency: 'Sätze vorlesen',
          correct: i != 0 && i != 1,
          at: DateTime(2026, 10, 1, 9, i),
          prompt: 'Der kleine Igel schläft im Laub.',
          given: i < 2 ? 'Igel' : '',
          durationMs: 6000,
          score: i < 2 ? .6 : .9,
        ),
    ];
    final s = LearningAnalysis.analyze(list).stats.single;
    expect(s.wordsPerMinute, 60); // 6 Wörter in 6 s
    expect(s.avgScore, closeTo(.8, .001));
    expect(s.patterns.first, ('schwieriges Wort „Igel“', 2));
  });

  test('Speicherfehler: Eintrag bleibt erhalten und wird später gespeichert',
      () async {
    final log = FlakyLog();
    final app = LumoAppState(attemptLog: log);
    await app.recordLearningAnswer(
        subject: 'Lesen',
        unit: 'Sätze vorlesen',
        correct: true,
        prompt: 'Lumo liest.',
        score: .95);
    expect(app.unsavedAttempts, 1);
    expect(await log.load(), isEmpty);
    log.fail = false;
    expect(await app.flushAttemptLog(), isTrue);
    expect(app.unsavedAttempts, 0);
    final saved = await log.load();
    expect(saved.single.competency, 'Sätze vorlesen');
    expect(saved.single.score, closeTo(.95, .001));
    app.dispose();
  });

  test('Nach einem Fehler werden beim nächsten Eintrag beide gespeichert',
      () async {
    final log = FlakyLog();
    final app = LumoAppState(attemptLog: log);
    await app.recordLearningAnswer(
        subject: 'Mathematik', unit: 'Plus bis 20', correct: false, prompt: '8 + 5 = ?');
    log.fail = false;
    await app.recordLearningAnswer(
        subject: 'Mathematik', unit: 'Plus bis 20', correct: true, prompt: '8 + 6 = ?');
    expect(app.unsavedAttempts, 0);
    expect((await log.load()).length, 2);
    app.dispose();
  });
}
