import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';
import 'package:lumo_lernen/features/teacher/teacher_dashboard_screen.dart';
import 'package:lumo_lernen/features/teacher/teacher_student_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(LumoAppState, String, String)> seed() async {
  final app = LumoAppState();
  final repo = app.school;
  var d = await repo.addClass('2a mit sehr langem Klassennamen', 2);
  final c = d.classes.single.id;
  for (final n in ['Alina', 'Benedikt-Maximilian', 'Cem', 'Dora']) {
    d = await repo.addStudent(c, n);
  }
  d = await repo.addGroup(c, 'Rechengruppe mit langem Namen');
  final alina = d.students.first.id;
  await repo.setActiveStudent(alina);
  for (var i = 0; i < 14; i++) {
    await app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        correct: i < 4,
        prompt: '${i % 5 + 5} + ${i % 4 + 6} = ?',
        given: '1',
        expected: '2',
        durationMs: 6000);
  }
  for (var i = 0; i < 8; i++) {
    await app.recordLearningAnswer(
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        correct: true,
        prompt: '${10 + i} + 2 = ?');
  }
  d = await repo.addAssignment(Assignment(
      id: 'a1',
      classId: c,
      targetKind: AssignmentTargetKind.wholeClass,
      subject: 'Mathematik',
      unit: 'Plus bis 20',
      title: 'Plus bis 20',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueAt: DateTime.now().add(const Duration(days: 3)),
      goal: 'Zehnerübergang sicher können'));
  return (app, c, alina);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [
    Size(280, 640),
    Size(392, 850),
    Size(673, 841),
    Size(1280, 800)
  ]) {
    for (final scale in const [1.0, 1.6]) {
      testWidgets('Lehrerbereich ohne Überlauf bei $size, Schrift $scale',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        late (LumoAppState, String, String) s;
        await tester.runAsync(() async => s = await seed());
        Widget wrap(Widget child) => MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                    size: size, textScaler: TextScaler.linear(scale)),
                child: child,
              ),
            );
        await tester.pumpWidget(wrap(TeacherDashboardScreen(appState: s.$1)));
        await _settle(tester);
        expect(find.text('Lehrerbereich'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Dashboard');
        await tester.pumpWidget(wrap(TeacherStudentScreen(
            appState: s.$1, studentId: s.$3, classId: s.$2)));
        await _settle(tester);
        expect(find.text('Alina'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Einzelansicht');
        await tester.pumpWidget(const SizedBox());
        s.$1.dispose();
      });
    }
  }
}
