import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/attempt_log_repository.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';
import 'package:lumo_lernen/features/teacher/assignment_evidence_summary.dart';
import 'package:lumo_lernen/features/teacher/student_assignments_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Attempt> _answers(String student, DateTime at) => [
      Attempt(
        id: '$student-first',
        studentId: student,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        competency: 'Addition',
        prompt: 'Mia hat acht rote Bausteine und bekommt fünf blaue dazu. '
            'Wie viele Bausteine hat sie zusammen?',
        given: '12',
        expected: '13',
        correct: false,
        hintUsed: true,
        at: at,
      ),
      Attempt(
        id: '$student-second',
        studentId: student,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        competency: 'Addition',
        prompt: '6 + 3 = ?',
        given: '9',
        expected: '9',
        correct: true,
        at: at.add(const Duration(seconds: 1)),
      ),
      Attempt(
        id: '$student-third',
        studentId: student,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        competency: 'Addition',
        prompt: '4 + 3 = ?',
        given: '6',
        expected: '7',
        correct: false,
        at: at.add(const Duration(seconds: 2)),
      ),
    ];

Assignment _assignment(String classId, DateTime createdAt) => Assignment(
      id: 'completed-homework',
      classId: classId,
      targetKind: AssignmentTargetKind.wholeClass,
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      title: 'Bausteine und Plusaufgaben',
      taskCount: 3,
      createdAt: createdAt,
    );

Future<void> _frames(WidgetTester tester) async {
  for (var index = 0; index < 25; index++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 840.0]) {
    testWidgets('Homework answers open at width $width with large text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final now = DateTime(2026, 11, 25, 12);
      final progress = AssignmentProgress.of(
        _assignment('class', now.subtract(const Duration(days: 1))),
        _answers('child-a', now.subtract(const Duration(hours: 1))),
        studentId: 'child-a',
        now: now,
      );
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: const TextScaler.linear(1.8),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AssignmentEvidenceSummary(progress: progress),
            ),
          ),
        ),
      ));
      expect(find.textContaining('1 von 2 ohne Hilfe richtig'), findsOneWidget);
      expect(find.textContaining('1 mit Hilfe bearbeitet'), findsOneWidget);
      await tester.tap(find.text('Antworten ansehen'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mia hat acht rote Bausteine'), findsOneWidget);
      expect(find.text('Antwort: 12'), findsOneWidget);
      expect(find.text('Lösung: 13'), findsOneWidget);
      expect(find.text('Mit Unterstützung bearbeitet'), findsOneWidget);
      expect(find.text('Selbstständig beantwortet'), findsNWidgets(2));
      await tester.ensureVisible(find.text('Lösung: 7'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Completed answers disappear immediately when changing school child',
      (tester) async {
    final log = _DelayedSecondChildLog();
    late LumoAppState app;
    late String first;
    late String second;
    await tester.runAsync(() async {
      app = LumoAppState(attemptLog: log);
      app.updateSettings(AppSettings(
        voiceEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
        calmMode: true,
      ));
      var directory = await app.school.addClass('2a', 2);
      final classId = directory.classes.single.id;
      directory = await app.school.addStudent(classId, 'Mia');
      first = directory.students.single.id;
      directory = await app.school.addStudent(classId, 'Lena');
      second = directory.students.last.id;
      log.firstStudent = first;
      log.secondStudent = second;
      await app.school.addAssignment(_assignment(
          classId, log.observedAt.subtract(const Duration(hours: 1))));
      await app.school.setActiveStudent(first);
    });
    addTearDown(() {
      if (!log.secondGate.isCompleted) log.secondGate.complete();
      app.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StudentAssignmentsCard(
            appState: app,
            onStart: (_, __) {},
          ),
        ),
      ),
    ));
    await _frames(tester);
    expect(find.byKey(const ValueKey('completed-assignment-completed-homework')),
        findsOneWidget);
    await tester.tap(find.text('Antworten ansehen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Antwort: 12'), findsOneWidget);

    await tester.runAsync(() => app.school.setActiveStudent(second));
    // The second child's log is still blocked: privacy cannot wait for it.
    await tester.pump();
    expect(log.secondGate.isCompleted, isFalse);
    expect(find.byKey(const ValueKey('completed-assignment-completed-homework')),
        findsNothing);
    expect(find.text('Antwort: 12'), findsNothing);
    expect(find.textContaining('Mia hat acht rote Bausteine'), findsNothing);

    await tester.runAsync(() async => log.secondGate.complete());
    await _frames(tester);
    expect(find.byKey(const ValueKey('completed-assignment-completed-homework')),
        findsNothing);
    expect(find.byKey(const ValueKey('assignment-Plus bis 20')), findsOneWidget);
    expect(find.text('0 von 3 Aufgaben'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _DelayedSecondChildLog extends AttemptLogRepository {
  final observedAt = DateTime.now().subtract(const Duration(hours: 2));
  final secondGate = Completer<void>();
  String? firstStudent;
  String? secondStudent;

  @override
  Future<List<Attempt>> load({String? studentId}) async {
    if (studentId == null) return [];
    if (studentId == secondStudent) {
      await secondGate.future;
      return [];
    }
    return studentId == firstStudent
        ? _answers(studentId, observedAt)
        : [];
  }
}
