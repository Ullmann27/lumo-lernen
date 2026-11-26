import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/domain/school/school_model.dart';
import 'package:lumo_lernen/features/teacher/assign_task_sheet.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_class_data.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_homework.dart';
import 'package:lumo_lernen/features/teacher_demo/homework_runner_screen.dart';
import 'package:lumo_lernen/features/teacher_demo/teacher_demo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 24, 9);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Demo-Hausaufgaben je Fach und Schulstufe', () {
    for (final subject in homeworkSubjects) {
      for (final grade in homeworkGrades) {
        test('$subject · $grade. Stufe: Themen sind automatisch prüfbar', () {
          final units = homeworkUnitsFor(subject, grade);
          expect(units, isNotEmpty, reason: '$subject $grade');
          for (final unit in units) {
            final hw = DemoHomework(
              id: 'hw-$subject-$grade-$unit',
              subject: subject,
              grade: grade,
              unit: unit,
              count: 6,
              due: _now,
              note: '',
              studentIds: ['${demoStudentPrefix}1'],
              createdAt: _now,
            );
            final tasks = hw.tasksFor('${demoStudentPrefix}1');
            expect(tasks, hasLength(6));
            for (final t in tasks) {
              expect(t.prompt.trim(), isNotEmpty, reason: unit);
              expect(t.choices.length, greaterThanOrEqualTo(2), reason: unit);
              expect(t.choices, contains(t.answer), reason: '$unit ${t.prompt}');
              expect(
                  checkHomeworkAnswer(given: t.answer, expected: t.answer),
                  isTrue);
            }
            // Mathematik ist je Kind stabil. Der Deutsch-Generator vermeidet
            // Wiederholungen über einen eigenen Verlauf; die Auswertung nutzt
            // ohnehin die gespeicherten Aufgaben und Antworten.
            if (subject == 'Mathematik') {
              expect(
                  hw.tasksFor('${demoStudentPrefix}1').map((t) => t.prompt),
                  tasks.map((t) => t.prompt));
            }
          }
          if (grade > 1) {
            expect(units.length,
                greaterThanOrEqualTo(homeworkUnitsFor(subject, grade - 1).length),
                reason: 'Höhere Stufen behalten frühere Themen');
          }
        });
      }
    }

    test('Schulstufe wird gespeichert; ältere Hausaufgaben bleiben lesbar', () {
      final neu = DemoHomework(
        id: 'hw-g',
        subject: 'Deutsch',
        grade: 3,
        unit: homeworkUnitsFor('Deutsch', 3).last,
        count: 4,
        due: _now,
        note: '',
        studentIds: ['${demoStudentPrefix}1'],
        createdAt: _now,
      );
      final zurueck = DemoHomework.tryFromJson(neu.toJson())!;
      expect(zurueck.grade, 3);
      expect(zurueck.subject, 'Deutsch');
      final alt = Map<String, Object?>.from(neu.toJson())
        ..remove('g')
        ..['sub'] = 'Mathematik'
        ..['unit'] = 'Plus bis 20';
      final altGelesen = DemoHomework.tryFromJson(alt)!;
      expect(altGelesen.grade, isNull);
      expect(altGelesen.tasksFor('${demoStudentPrefix}1', grade: 2), hasLength(4));
    });

    testWidgets('Lehrerin gestaltet Deutsch-Hausaufgabe für Stufe 3, Kind löst sie',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 2400);
      addTearDown(tester.view.reset);
      final store = DemoHomeworkStore();
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: const MediaQueryData(
                  size: Size(900, 2400), disableAnimations: true),
              child: TeacherDemoScreen(now: _now, store: store))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hausaufgaben'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('homework-subject-Deutsch')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('homework-grade-3')));
      await tester.pump();
      final create = find.byKey(const ValueKey('homework-create'));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
      final saved = (await tester.runAsync(store.load))!.single;
      expect(saved.subject, 'Deutsch');
      expect(saved.grade, 3);
      expect(homeworkUnitsFor('Deutsch', 3), contains(saved.unit));
      expect(find.textContaining('Hausaufgabe: Deutsch'), findsOneWidget);

      final child = demoChildren.firstWhere((c) => saved.studentIds.contains(c.id));
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: const MediaQueryData(
                  size: Size(900, 2400), disableAnimations: true),
              child: HomeworkRunnerScreen(
                  homework: saved, child: child, store: store))));
      await tester.pump();
      expect(find.textContaining('Deutsch · ${saved.unit}'), findsOneWidget);
      final choices = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('homework-choice-'));
      for (var i = 0; i < saved.count; i++) {
        expect(choices, findsAtLeastNWidgets(2));
        await tester.tap(choices.first);
        await tester.pump(const Duration(milliseconds: 1000));
      }
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text('Geschafft!'), findsOneWidget);
      final done = (await tester.runAsync(store.load))!.single;
      final items = done.results[child.id]!;
      expect(items, hasLength(saved.count));
      final e = HomeworkEvaluation(done, child.id, items);
      expect(e.correct, items.where((i) => i.given.trim() == i.expected.trim()).length);
      expect(find.textContaining('${e.correct} von ${items.length} richtig'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Aufgabenwechsel ist animiert; die alte Aufgabe nimmt keine Tipps an',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    final store = DemoHomeworkStore();
    final hw = DemoHomework(
      id: 'hw-anim',
      subject: 'Mathematik',
      grade: 2,
      unit: 'Plus bis 20',
      count: 2,
      due: _now,
      note: '',
      studentIds: ['${demoStudentPrefix}1'],
      createdAt: _now,
    );
    final child = demoChildren.first;
    final tasks = hw.tasksFor(child.id);
    await tester.pumpWidget(MaterialApp(
        home: HomeworkRunnerScreen(homework: hw, child: child, store: store)));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('homework-choice-${tasks[0].answer}')).first);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 100));
    IgnorePointer schutz(String key) => tester.widget<IgnorePointer>(find
        .ancestor(
            of: find.byKey(ValueKey(key)), matching: find.byType(IgnorePointer))
        .first);
    expect(find.byKey(const ValueKey('aufgabe-0')), findsOneWidget,
        reason: 'Die alte Aufgabe blendet noch aus');
    expect(schutz('aufgabe-0').ignoring, isTrue);
    expect(schutz('aufgabe-1').ignoring, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('aufgabe-0')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  group('Echte Zuweisung je Fach und Klasse', () {
    for (var grade = 1; grade <= 4; grade++) {
      test('$grade. Klasse: jedes angebotene Thema ist im Übungsbereich lösbar '
          'und zählt für die Aufgabe', () {
        final subjects = assignableSubjects(grade);
        expect(subjects, containsAll(['Mathematik', 'Deutsch', 'Sachunterricht']));
        for (final subject in subjects) {
          final units = Curriculum.unitsForGrade(subject, grade);
          expect(units, isNotEmpty, reason: '$subject $grade');
          for (final unit in units) {
            final task = ExerciseFactory(seed: grade * 31 + unit.length)
                .nextExact(grade: grade, subject: subject, unit: unit);
            expect((task.subject, task.unit), (subject, unit));
            final assignment = Assignment(
              id: 'a',
              classId: 'c',
              targetKind: AssignmentTargetKind.student,
              targetId: 'kind',
              subject: subject,
              unit: unit,
              title: unit,
              createdAt: _now,
              taskCount: 2,
            );
            final progress = AssignmentProgress.of(
                assignment,
                [
                  for (var i = 0; i < 3; i++)
                    Attempt(
                      id: '$subject-$unit-$i',
                      studentId: 'kind',
                      subject: task.subject,
                      unit: task.unit,
                      competency: unit,
                      correct: i != 1,
                      at: _now.add(Duration(minutes: i + 1)),
                    ),
                ],
                studentId: 'kind',
                now: _now.add(const Duration(hours: 1)));
            expect(progress.completed, isTrue, reason: '$subject $unit');
            expect(progress.done, 2);
          }
        }
      });
    }
  });
}
