import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/cognitive_profile_repository.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';
import 'package:lumo_lernen/features/teacher/teacher_student_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Lehrkraft sieht letztes Denkprofil des zugeordneten Kindes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late final LumoAppState app;
    late String classId;
    late String studentId;
    await tester.runAsync(() async {
      app = LumoAppState();
      var dir = await app.school.addClass('3a', 3);
      classId = dir.classes.single.id;
      dir = await app.school.addStudent(classId, 'Mia');
      studentId = dir.students.single.id;
      await const CognitiveProfileRepository().save(
        CognitiveProfileResult(
          id: 'cog-teacher-test',
          studentId: studentId,
          grade: 3,
          testVersion: 'test-v1',
          finishedAt: DateTime(2026, 10, 6),
          domainScores: const [
            CognitiveDomainScore(
              domain: CognitiveDomain.patternReasoning,
              correct: 8,
              total: 10,
            ),
            CognitiveDomainScore(
              domain: CognitiveDomain.quantitativeReasoning,
              correct: 7,
              total: 10,
            ),
            CognitiveDomainScore(
              domain: CognitiveDomain.verbalReasoning,
              correct: 9,
              total: 10,
            ),
            CognitiveDomainScore(
              domain: CognitiveDomain.spatialReasoning,
              correct: 6,
              total: 10,
            ),
            CognitiveDomainScore(
              domain: CognitiveDomain.workingMemory,
              correct: 7,
              total: 10,
            ),
          ],
          totalCorrect: 37,
          totalQuestions: 50,
          durationMs: 420000,
        ),
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherStudentScreen(
          appState: app,
          studentId: studentId,
          classId: classId,
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Denkprofil · 50 Aufgaben'), findsOneWidget);
    expect(find.textContaining('37 von 50 gelöst'), findsOneWidget);
    expect(find.text('Sprachliches Denken'), findsOneWidget);
    expect(find.text('9/10'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
