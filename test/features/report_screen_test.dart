import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_analysis.dart';
import 'package:lumo_lernen/features/report/lernbericht_screen.dart';
import 'package:lumo_lernen/features/report/student_report_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Attempt> _sample() => [
      for (var i = 0; i < 14; i++)
        Attempt(
          id: 'a$i',
          studentId: 'self',
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          competency: 'Addition mit Zehnerübergang',
          correct: i >= 7,
          at: DateTime.now().subtract(Duration(hours: i)),
          prompt: '${i + 3} + 9 = ?',
          given: '${i + 11}',
          expected: '${i + 12}',
          durationMs: 6000,
        ),
      for (var i = 0; i < 10; i++)
        Attempt(
          id: 'b$i',
          studentId: 'self',
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          competency: 'Addition ohne Zehnerübergang',
          correct: true,
          at: DateTime.now().subtract(Duration(days: 1, minutes: i)),
          durationMs: 4000,
        ),
    ];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [Size(280, 640), Size(392, 850), Size(673, 841)]) {
    for (final scale in const [1.0, 1.6]) {
      testWidgets('Bericht ohne Überlauf bei $size, Schrift $scale',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final attempts = _sample();
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                size: size, textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: StudentReportView(
                  analysis: LearningAnalysis.analyze(attempts),
                  attempts: attempts),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('report-suggestion')), findsOneWidget);
        expect(
            find.textContaining('gab es 7 Fehler', findRichText: true, skipOffstage: false),
            findsOneWidget);
      });
    }
  }

  testWidgets('Leerer Bericht erklärt freundlich, was fehlt', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StudentReportView(
            analysis: LearningAnalysis.analyze(const []), attempts: const []),
      ),
    ));
    expect(find.textContaining('Noch keine Aufgaben gelöst'), findsOneWidget);
  });

  testWidgets('Antwort speichern -> Bericht zeigt sie (End-to-End lokal)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late final LumoAppState app;
    await tester.runAsync(() async {
      app = LumoAppState();
      for (var i = 0; i < 6; i++) {
        await app.recordLearningAnswer(
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          correct: i % 2 == 0,
          prompt: '8 + ${i + 3} = ?',
          given: '1',
          expected: '${11 + i}',
          durationMs: 5000,
        );
      }
    });
    await tester.pumpWidget(MaterialApp(home: LernberichtScreen(appState: app)));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Mein Lernbericht'), findsOneWidget);
    expect(find.text('6'), findsWidgets); // Aufgabenzahl
    expect(find.textContaining('Addition mit Zehnerübergang'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
