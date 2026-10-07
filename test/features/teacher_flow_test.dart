import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';
import 'package:lumo_lernen/features/teacher/student_assignments_card.dart';
import 'package:lumo_lernen/features/teacher/teacher_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _enterText(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('teacher-text-input')), text);
  await tester.pump();
  await tester.tap(find.text('Speichern'));
  await _settle(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'Lehrer: Klasse → Kind → Schwäche erkennen → Aufgabe zuweisen → Kind erledigt → Lehrer sieht Ergebnis',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late final LumoAppState app;
    await tester.runAsync(() async => app = LumoAppState());

    await tester.pumpWidget(MaterialApp(home: TeacherDashboardScreen(appState: app)));
    await _settle(tester);

    // Leerer Zustand → Klasse anlegen
    expect(find.text('Willkommen im Lehrerbereich'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('create-first-class')));
    await tester.pump();
    await _enterText(tester, '2a');
    await tester.tap(find.byKey(const ValueKey('class-grade-2')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('class-2a')), findsOneWidget);

    // Kind hinzufügen
    await tester.tap(find.byKey(const ValueKey('add-student')));
    await tester.pump();
    await _enterText(tester, 'Alina');
    expect(find.byKey(const ValueKey('student-Alina')), findsOneWidget);

    // Kind öffnen und Gerät zuordnen
    await tester.tap(find.byKey(const ValueKey('student-Alina')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('student-link-device')));
    await _settle(tester);
    expect(find.text('Zuordnung lösen'), findsOneWidget);

    // Das Kind übt: viele Fehler mit Zehnerübergang, sicher ohne
    await tester.runAsync(() async {
      for (var i = 0; i < 12; i++) {
        await app.recordLearningAnswer(
            subject: 'Mathematik',
            unit: 'Plus bis 20',
            correct: i < 3,
            prompt: '${i % 5 + 5} + ${i % 4 + 6} = ?',
            given: '1',
            expected: '2',
            durationMs: 6000);
      }
      for (var i = 0; i < 6; i++) {
        await app.recordLearningAnswer(
            subject: 'Mathematik',
            unit: 'Plus bis 20',
            correct: true,
            prompt: '${10 + i} + 2 = ?',
            durationMs: 4000);
      }
    });

    // Zurück zum Dashboard: Hilfebedarf sichtbar
    await tester.tap(find.byTooltip('Zurück'));
    await _settle(tester);
    expect(find.text('Unterstützung nötig'), findsOneWidget);
    expect(find.byKey(const ValueKey('help-Alina')), findsOneWidget);

    // Einzelansicht: Empfehlung bestätigen und zuweisen
    await tester.tap(find.byKey(const ValueKey('student-Alina')));
    await _settle(tester);
    expect(find.textContaining('Empfehlung: 10 Minuten'), findsOneWidget);
    await tester.tap(find.text('Bestätigen und zuweisen'));
    await _settle(tester);
    expect(find.text('Aufgabe zuweisen'), findsOneWidget);
    await tester.ensureVisible(find.text('Zuweisen').last);
    await tester.tap(find.text('Zuweisen').last);
    await _settle(tester);
    expect(find.textContaining('0 von 10 Aufgaben'), findsOneWidget);

    // Das Kind erledigt die zugewiesenen Aufgaben
    await tester.runAsync(() async {
      for (var i = 0; i < 10; i++) {
        await app.recordLearningAnswer(
            subject: 'Mathematik',
            unit: 'Plus bis 20',
            correct: true,
            prompt: '${10 + i} + 3 = ?',
            durationMs: 4000);
      }
    });
    await tester.tap(find.byTooltip('Zurück'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('student-Alina')));
    await _settle(tester);
    expect(find.textContaining('10 von 10 Aufgaben'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Kind sieht offene Lehrer-Aufgabe, Tippen startet das Thema',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late final LumoAppState app;
    await tester.runAsync(() async {
      app = LumoAppState();
      var d = await app.school.addClass('1a', 1);
      final c = d.classes.single.id;
      d = await app.school.addStudent(c, 'Mia');
      await app.school.setActiveStudent(d.students.single.id);
      await app.school.addAssignment(Assignment(
          id: 'x',
          classId: c,
          targetKind: AssignmentTargetKind.wholeClass,
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          title: 'Plus bis 10',
          taskCount: 3,
          createdAt: DateTime.now().subtract(const Duration(hours: 1))));
    });
    String? started;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StudentAssignmentsCard(
            appState: app, onStart: (s, u) => started = '$s/$u'),
      ),
    ));
    await _settle(tester);
    expect(find.text('Von deiner Lehrerin'), findsOneWidget);
    expect(find.text('0 von 3 Aufgaben'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assignment-Plus bis 10')));
    expect(started, 'Mathematik/Plus bis 10');

    // Nach drei Aufgaben ist sie erledigt und verschwindet.
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        await app.recordLearningAnswer(
            subject: 'Mathematik', unit: 'Plus bis 10', correct: true,
            prompt: '2 + $i = ?');
      }
    });
    await _settle(tester);
    expect(find.text('Von deiner Lehrerin'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Ohne Zuordnung bleibt das Feld unsichtbar', (tester) async {
    late final LumoAppState app;
    await tester.runAsync(() async => app = LumoAppState());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StudentAssignmentsCard(appState: app, onStart: (s, u) {}),
      ),
    ));
    await _settle(tester);
    expect(find.text('Von deiner Lehrerin'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
