import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/test_result_repository.dart';
import 'package:lumo_lernen/features/tests/lumo_tests_screen.dart';

TestResult _result(String subject, int correct, int day) => TestResult(
      subject: subject,
      correct: correct,
      total: kLumoTestQuestions,
      finishedAt: DateTime(2026, 10, day),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Ergebnisse: letztes Ergebnis und Bestleistung pro Fach', () async {
    const repo = TestResultRepository();
    expect((await repo.load('Mia')).last, isNull);
    await repo.record('Mia', _result('Mathematik', 7, 1));
    await repo.record('Mia', _result('Mathematik', 5, 2));
    await repo.record('Mia', _result('Deutsch', 9, 3));
    final summary = await repo.load('Mia');
    expect(summary.last!.subject, 'Deutsch');
    expect(summary.last!.correct, 9);
    expect(summary.best['Mathematik']!.correct, 7,
        reason: 'ein schlechteres Ergebnis ersetzt die Bestleistung nicht');
    expect((await repo.load('Ben')).last, isNull,
        reason: 'jedes Kind hat seine eigenen Ergebnisse');
  });

  Future<LumoAppState> pumpScreen(WidgetTester tester,
      {required List<LumoSection> sections}) async {
    await tester.binding.setSurfaceSize(const Size(392, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    app.update(app.state.copyWith(childName: 'Mia', grade: 2));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoTestsScreen(appState: app, onSection: sections.add),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    return app;
  }

  testWidgets('Kategorie und Schwierigkeit starten einen echten Test',
      (tester) async {
    final sections = <LumoSection>[];
    final app = await pumpScreen(tester, sections: sections);
    for (final title in ['Mathe', 'Deutsch', 'Sachkunde', 'Englisch']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Kreatives\nDenken'), findsOneWidget);
    expect(
        find.text('Noch kein Test gemacht. Starte deinen ersten Test – '
            'Lumo hebt dein Ergebnis hier auf.'),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('test-category-Logik')));
    await tester.tap(find.byKey(const ValueKey('test-level-1')));
    await tester.pump();
    expect(find.text('Denk-Test'), findsOneWidget);
    expect(find.text('Klasse 3 · ohne Hilfe'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('tests-start')));
    await tester.tap(find.byKey(const ValueKey('tests-start')));
    expect(app.state.subject, 'Logik');
    expect(app.state.sessionKind, LumoSessionKind.test);
    expect(app.state.testLevel, 1);
    expect(sections, [LumoSection.exercises]);
  });

  testWidgets('Gespeichertes Ergebnis erscheint mit Bestleistung',
      (tester) async {
    await tester.runAsync(() async {
      const repo = TestResultRepository();
      await repo.record('Mia', _result('Mathematik', 9, 1));
      await repo.record('Mia', _result('Mathematik', 6, 4));
    });
    await pumpScreen(tester, sections: []);
    expect(find.text('6 / 10 richtig!'), findsOneWidget);
    expect(find.text('9 / 10'), findsOneWidget);
    expect(find.text('Mathe – Mathe-Test'), findsOneWidget);
    expect(find.text('4. Oktober 2026'), findsOneWidget);
  });
}
