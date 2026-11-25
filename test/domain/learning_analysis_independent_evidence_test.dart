import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_analysis.dart';

Attempt _answer(
  int index, {
  bool correct = false,
  bool hintUsed = false,
  String subject = 'Mathematik',
  String unit = 'Plus bis 20',
  String competency = 'Gemeinsame Kompetenz',
  int durationMs = 1000,
  double? score,
}) =>
    Attempt(
      id: '$subject-$index',
      studentId: 'self',
      subject: subject,
      unit: unit,
      competency: competency,
      correct: correct,
      hintUsed: hintUsed,
      at: DateTime(2026, 11, 25, 12).add(Duration(minutes: index)),
      prompt: 'Das kleine Kind liest diesen Satz.',
      durationMs: durationMs,
      score: score,
    );

LearningAnalysis _analyze(List<Attempt> attempts) =>
    LearningAnalysis.analyze(attempts, now: DateTime(2026, 11, 25, 18));

void main() {
  test('Hilfen bleiben Aktivität, belegen aber keine sichere Kompetenz', () {
    final result = _analyze([
      for (var i = 0; i < 20; i++)
        _answer(i, correct: true, hintUsed: true),
    ]);
    final stat = result.stats.single;
    expect(stat.attempts, 20);
    expect(stat.correct, 20);
    expect(stat.hints, 20);
    expect(stat.independentAttempts, 0);
    expect(stat.independentCorrect, 0);
    expect(stat.level, MasteryLevel.unknown);
    expect(stat.trend, isNull);
    expect(result.totalAttempts, 20);
    expect(result.days.last.total, 20);
    expect(result.days.last.correct, 20);
    expect(result.coachMessage, isNull);
    expect(result.suggestion, isNull);
    expect(result.secure, isEmpty);
  });

  test('Vier unabhängige Fehler plus Hilfen bleiben unter der Mindestmenge', () {
    final result = _analyze([
      for (var i = 0; i < 4; i++) _answer(i),
      for (var i = 4; i < 6; i++) _answer(i, hintUsed: true),
    ]);
    final stat = result.stats.single;
    expect(stat.wrong, 6);
    expect(stat.independentAttempts, 4);
    expect(stat.independentWrong, 4);
    expect(stat.level, MasteryLevel.unknown);
    expect(result.weak, isEmpty);
    expect(result.coachMessage, isNull);
    expect(result.suggestion, isNull);
  });

  test('Viele richtige Antworten mit Hilfe verdecken unabhängige Fehler nicht',
      () {
    final result = _analyze([
      for (var i = 0; i < 5; i++) _answer(i),
      for (var i = 5; i < 55; i++)
        _answer(i, correct: true, hintUsed: true),
    ]);
    final stat = result.stats.single;
    expect(stat.attempts, 55);
    expect(stat.correct, 50);
    expect(stat.hints, 50);
    expect(stat.independentAttempts, 5);
    expect(stat.independentCorrect, 0);
    expect(stat.accuracy, 0);
    expect(stat.percent, 0);
    expect(stat.level, MasteryLevel.needsHelp);
    expect(result.coachMessage?.isHelp, isTrue);
    expect(result.suggestion?.subject, 'Mathematik');
    expect(result.insights.singleWhere((i) => i.kind == InsightKind.weakness).text,
        contains('5 Aufgaben ohne Hilfe'));
  });

  test('Fehler mit Hilfe entwerten unabhängig belegte Kompetenz nicht', () {
    final result = _analyze([
      for (var i = 0; i < 5; i++) _answer(i, correct: true),
      for (var i = 5; i < 25; i++) _answer(i, hintUsed: true),
    ]);
    final stat = result.stats.single;
    expect(stat.wrong, 20);
    expect(stat.independentWrong, 0);
    expect(stat.percent, 100);
    expect(stat.level, MasteryLevel.secure);
    expect(result.coachMessage?.isHelp, isFalse);
  });

  test('Hilfen können die Mindestmenge für einen Trend nicht auffüllen', () {
    final result = _analyze([
      for (var i = 0; i < 4; i++) _answer(i),
      for (var i = 4; i < 8; i++)
        _answer(i, correct: true, hintUsed: true),
    ]);
    expect(result.stats.single.trend, isNull);
    expect(result.insights.where((i) => i.kind == InsightKind.trend), isEmpty);
  });

  test('Trend vergleicht chronologisch nur unabhängige Antworten', () {
    final attempts = [
      for (var i = 0; i < 6; i++) _answer(i),
      for (var i = 6; i < 12; i++) _answer(i, correct: true),
      for (var i = 12; i < 32; i++) _answer(i, hintUsed: true),
    ].reversed.toList();
    final result = _analyze(attempts);
    expect(result.stats.single.independentAttempts, 12);
    expect(result.stats.single.trend, 100);
    expect(result.stats.single.percent, 50);
    expect(result.insights.singleWhere((i) => i.kind == InsightKind.trend).text,
        contains('100 Prozentpunkte ohne Hilfe'));
  });

  test('Lesegenauigkeit und Lesetempo schließen unterstützte Antworten aus',
      () {
    final result = _analyze([
      _answer(0, subject: 'Lesen', durationMs: 6000, score: .5),
      _answer(1,
          subject: 'Lesen',
          correct: true,
          hintUsed: true,
          durationMs: 600,
          score: 1),
    ]);
    final stat = result.stats.single;
    expect(stat.avgScore, .5);
    expect(stat.wordsPerMinute, 60);
    expect(stat.avgMs, 3300);
    expect(stat.attempts, 2);
    expect(stat.independentAttempts, 1);
    final assistedOnly = _analyze([
      _answer(2,
          subject: 'Lesen',
          correct: true,
          hintUsed: true,
          durationMs: 600,
          score: 1),
    ]).stats.single;
    expect(assistedOnly.avgScore, isNull);
    expect(assistedOnly.wordsPerMinute, isNull);
  });

  test('Gleichnamige Kompetenzen verschiedener Fächer bleiben getrennt', () {
    final result = _analyze([
      for (var i = 0; i < 5; i++) _answer(i),
      for (var i = 5; i < 10; i++)
        _answer(i, subject: 'Deutsch', unit: 'Silben', correct: true),
    ]);
    expect(result.stats.length, 2);
    final math = result.stats.singleWhere((s) => s.subject == 'Mathematik');
    final german = result.stats.singleWhere((s) => s.subject == 'Deutsch');
    expect(math.attempts, 5);
    expect(math.level, MasteryLevel.needsHelp);
    expect(german.attempts, 5);
    expect(german.level, MasteryLevel.secure);
    expect(result.suggestion?.subject, 'Mathematik');
    expect(result.coachMessage?.unit, 'Plus bis 20');
  });

  test('Antworten fremder Fächer erfüllen keine Mindestmenge', () {
    final result = _analyze([
      for (var i = 0; i < 4; i++) _answer(i),
      for (var i = 4; i < 8; i++) _answer(i, subject: 'Deutsch'),
    ]);
    expect(result.stats.length, 2);
    expect(result.stats.every((s) => s.level == MasteryLevel.unknown), isTrue);
    expect(result.coachMessage, isNull);
    expect(result.suggestion, isNull);
  });

  test('Vergleichskompetenz benötigt dasselbe Fach und unabhängige Antworten',
      () {
    final weak = [
      for (var i = 0; i < 5; i++)
        _answer(i, competency: 'Rechnen mit Hilfsmittel'),
    ];
    final foreign = [
      for (var i = 5; i < 10; i++)
        _answer(i,
            competency: 'Rechnen ohne Hilfsmittel',
            subject: 'Deutsch',
            correct: true),
    ];
    final assisted = [
      for (var i = 10; i < 15; i++)
        _answer(i,
            competency: 'Rechnen ohne Hilfsmittel',
            correct: true,
            hintUsed: true),
    ];
    final result = _analyze([...weak, ...foreign, ...assisted]);
    expect(result.insights.where((i) => i.kind == InsightKind.comparison),
        isEmpty);
    final independent = [
      for (var i = 15; i < 20; i++)
        _answer(i, competency: 'Rechnen ohne Hilfsmittel', correct: true),
    ];
    final withComparison = _analyze([...weak, ...independent]);
    expect(withComparison.insights
        .singleWhere((i) => i.kind == InsightKind.comparison).text,
        contains('Trefferquote ohne Hilfe'));
  });

  test('Neueste Einheit folgt dem Zeitpunkt und lässt Eingabereihenfolge intakt',
      () {
    final latest = _answer(9, unit: 'Plus bis 100');
    final attempts = [latest, for (var i = 0; i < 5; i++) _answer(i)];
    final ids = attempts.map((a) => a.id).toList();
    final result = _analyze(attempts);
    expect(result.stats.single.unit, 'Plus bis 100');
    expect(result.stats.single.lastAt, latest.at);
    expect(result.coachMessage?.unit, 'Plus bis 100');
    expect(attempts.map((a) => a.id), orderedEquals(ids));
  });

  test('Bearbeitungszeit ändert keine Kompetenzstufe', () {
    final fast = _analyze([
      for (var i = 0; i < 5; i++)
        _answer(i, correct: true, durationMs: 100),
    ]).stats.single;
    final slow = _analyze([
      for (var i = 0; i < 5; i++)
        _answer(i, correct: true, durationMs: 300000),
    ]).stats.single;
    expect(slow.level, fast.level);
    expect(slow.percent, fast.percent);
    expect(slow.avgMs, isNot(fast.avgMs));
  });
}
