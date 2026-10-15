import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/school/learning_analysis.dart';

/// Prüfauftrag §3: Arbeiten Lernstand, Lernanalyse und Empfehlung wirklich
/// zusammen – über wiederholte Fehler, mehrere Runden und einen Neustart?
/// Echte Klassen, echte Speicherung (SharedPreferences-Testspeicher); ein
/// „Neustart“ ist eine neue LumoAppState über demselben Speicher.
Future<LumoAppState> _start() async {
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  await app.loadLearningProfile();
  return app;
}

Future<void> _answer(LumoAppState app, String unit, bool correct,
    {int times = 1, bool hint = false}) async {
  for (var i = 0; i < times; i++) {
    await app.recordLearningAnswer(
      subject: 'Mathematik',
      unit: unit,
      correct: correct,
      hintUsed: hint,
      requireSaved: true,
      prompt: '$unit Aufgabe $i',
      given: correct ? 'richtig' : 'falsch',
      expected: 'richtig',
    );
  }
  await app.flushAttemptLog();
}

CompetencyStat _stat(LearningAnalysis analysis, String unit) =>
    analysis.stats.singleWhere((s) => s.unit == unit);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('wiederholte Fehler führen zu Empfehlung, überstehen Neustart, Üben ändert sie',
      () async {
    // Runde 1: Minus bis 10 sechsmal falsch (zweimal mit Tipp), Plus bis 10 sicher.
    var app = await _start();
    await _answer(app, 'Minus bis 10', false, times: 4);
    await _answer(app, 'Minus bis 10', false, times: 2, hint: true);
    await _answer(app, 'Plus bis 10', true, times: 6);

    final minusId = SkillRecord.makeId('Mathematik', 'Minus bis 10');
    final plusId = SkillRecord.makeId('Mathematik', 'Plus bis 10');
    expect(app.learningSkills()[minusId]!.wrong, 6);
    expect(app.learningSkills()[minusId]!.hintCount, 2);
    expect(app.learningSkills()[plusId]!.correct, 6);
    expect(app.learningWeaknessesBySubject()['Mathematik'], contains('Minus bis 10'));
    final first = app.topLearningRecommendation();
    expect(first, isNotNull);
    expect(first!.unit, 'Minus bis 10');

    var analysis = LearningAnalysis.analyze(await app.attemptLog.load());
    expect(_stat(analysis, 'Minus bis 10').level, MasteryLevel.needsHelp);
    expect(_stat(analysis, 'Plus bis 10').level, MasteryLevel.secure);
    app.dispose();

    // Neustart: neue App über demselben Speicher.
    app = await _start();
    expect(app.learningSkills()[minusId]!.wrong, 6);
    expect(app.learningSkills()[plusId]!.correct, 6);
    expect(app.topLearningRecommendation()?.unit, 'Minus bis 10');
    analysis = LearningAnalysis.analyze(await app.attemptLog.load());
    expect(_stat(analysis, 'Minus bis 10').attempts, 6);

    // Runde 2 nach dem Neustart: zwölfmal richtig geübt.
    await _answer(app, 'Minus bis 10', true, times: 12);
    expect(app.learningSkills()[minusId]!.correct, 12);
    analysis = LearningAnalysis.analyze(await app.attemptLog.load());
    final minus = _stat(analysis, 'Minus bis 10');
    expect(minus.attempts, 18);
    expect(minus.level, isNot(MasteryLevel.needsHelp));
    app.dispose();

    // Zweiter Neustart: der verbesserte Stand bleibt erhalten.
    app = await _start();
    expect(app.learningSkills()[minusId]!.correct, 12);
    expect(app.learningSkills()[minusId]!.wrong, 6);
    app.dispose();
  });
}
