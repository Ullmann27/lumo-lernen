import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/learning_analysis.dart';
import 'package:lumo_lernen/features/report/student_report_view.dart';
import 'package:lumo_lernen/features/teacher/teacher_dashboard_screen.dart';
import 'package:lumo_lernen/features/teacher/teacher_student_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Attempt _answer(int index,
        {String studentId = 'self',
        String subject = 'Mathematik',
        String unit = 'Plus bis 10',
        bool correct = false,
        bool hintUsed = false}) =>
    Attempt(
      id: '$studentId-$subject-$index',
      studentId: studentId,
      subject: subject,
      unit: unit,
      competency: 'Gemeinsame Kompetenz',
      correct: correct,
      hintUsed: hintUsed,
      at: DateTime.now().subtract(Duration(minutes: 100 - index)),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scale in [1.0, 1.6]) {
    for (final assistedOnly in [false, true]) {
      testWidgets(
          'Bericht trennt Hilfe und Kompetenz bei Schrift $scale, nur Hilfe $assistedOnly',
          (tester) async {
        const size = Size(280, 900);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final attempts = [
          for (var i = 0; i < 8; i++)
            _answer(i,
                correct: assistedOnly || i == 0 || i >= 5,
                hintUsed: assistedOnly || i >= 5),
        ];
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
        expect(find.text('Mathematik · Gemeinsame Kompetenz'), findsOneWidget);
        if (assistedOnly) {
          expect(find.text('noch offen · noch keine Antworten ohne Hilfe'),
              findsOneWidget);
          expect(find.text('8 Aufgaben insgesamt · 8 mit Hilfe'), findsOneWidget);
          expect(find.byKey(const ValueKey('report-suggestion')), findsNothing);
          expect(find.text('100 %'), findsNothing);
        } else {
          expect(find.text('braucht Hilfe · 1 von 5 ohne Hilfe richtig'),
              findsOneWidget);
          expect(find.text('8 Aufgaben insgesamt · 3 mit Hilfe'), findsOneWidget);
          expect(find.text('20 %'), findsWidgets);
          expect(find.byKey(const ValueKey('report-suggestion')), findsOneWidget);
        }
      });
    }
  }

  for (final foreignSubjectLast in [false, true]) {
    testWidgets(
        'Lehrerempfehlung wählt neueste Einheit im richtigen Fach, Fremdfach $foreignSubjectLast',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(392, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final units = Curriculum.unitsForGrade('Deutsch', 1);
      expect(units.length, greaterThan(1));
      final latestUnit = units.last;
      late final LumoAppState app;
      late final String studentId;
      late final String classId;
      await tester.runAsync(() async {
        app = LumoAppState();
        var directory = await app.school.addClass('1a', 1);
        classId = directory.classes.single.id;
        directory = await app.school.addStudent(classId, 'Mia');
        studentId = directory.students.single.id;
        await app.attemptLog.appendAll([
          // Die neueste fachgleiche Aufgabe steht absichtlich zuerst im Log.
          _answer(90,
              studentId: studentId, subject: 'Deutsch', unit: latestUnit),
          for (var i = 0; i < 5; i++)
            _answer(i,
                studentId: studentId, subject: 'Deutsch', unit: units.first),
          if (foreignSubjectLast)
            _answer(95,
                studentId: studentId, correct: true, hintUsed: true),
        ]);
      });
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
          home: TeacherStudentScreen(
              appState: app, studentId: studentId, classId: classId)));
      await _settle(tester);
      await tester.tap(find.text('Bestätigen und zuweisen'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      final selectedSubject = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('assign-Deutsch')));
      expect(selectedSubject.selected, isTrue);
      final unitField = tester.widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('assign-unit')));
      expect(unitField.initialValue, latestUnit);

      await tester.ensureVisible(find.text('Zuweisen').last);
      await tester.tap(find.text('Zuweisen').last);
      await _settle(tester);
      final directory = await tester.runAsync(() => app.school.load());
      final assignment = directory!.assignments.single;
      expect(assignment.subject, 'Deutsch');
      expect(assignment.unit, latestUnit);
      expect(assignment.targetId, studentId);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Klassenübersicht zählt Hilfebedarf getrennt nach Fach',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(673, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late final LumoAppState app;
    await tester.runAsync(() async {
      app = LumoAppState();
      var directory = await app.school.addClass('1a', 1);
      directory = await app.school.addStudent(directory.classes.single.id, 'Mia');
      final studentId = directory.students.single.id;
      await app.attemptLog.appendAll([
        for (var i = 0; i < 5; i++) _answer(i, studentId: studentId),
        for (var i = 5; i < 10; i++)
          _answer(i, studentId: studentId, subject: 'Deutsch', unit: 'Silben'),
      ]);
    });
    addTearDown(app.dispose);
    await tester.pumpWidget(
        MaterialApp(home: TeacherDashboardScreen(appState: app)));
    await _settle(tester);
    final heading = find.text('Kompetenzen mit Hilfebedarf');
    await tester.scrollUntilVisible(heading, 350,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.text('Mathematik · Gemeinsame Kompetenz: 1 Kind'), findsOneWidget);
    expect(find.text('Deutsch · Gemeinsame Kompetenz: 1 Kind'), findsOneWidget);
    expect(find.text('Gemeinsame Kompetenz: 2 Kinder'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
