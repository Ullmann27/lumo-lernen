import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';
import 'package:lumo_lernen/features/learning/widgets/math_explanation_film.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';
import 'story_inquiry_workbench_test.dart' show adapt, story;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  final dir = Platform.environment['LUMO_FILM_CAPTURES'];
  const boundary = ValueKey('whole-lesson');

  test(
      'authored two- and three-step stories retain every verified arithmetic relation',
      () {
    for (final id in ['g3_two_step', 'g4_three_step']) {
      for (var n = 0; n < 96; n++) {
        final task = story(id, n);
        final plan = MathFilmPlan.forTask(task)!;
        expect(
            plan.shots.length, id == 'g3_two_step' ? 2 : inInclusiveRange(3, 4),
            reason: task.prompt);
        for (final shot in plan.shots) {
          expect(shot.caption, contains('${shot.equation.b}'),
              reason: task.prompt);
        }
        final e = plan.shots.last.equation;
        final result = switch (e.sign) {
          '+' => e.a + e.b,
          '−' => e.a - e.b,
          '·' => e.a * e.b,
          _ => e.a ~/ e.b
        };
        expect(result.toString(), task.correctAnswer.toString(),
            reason: task.prompt);
        expect(plan.question, endsWith('?'));
      }
    }
  });
  for (final (grade, unit) in [
    (1, 'Plus bis 10'),
    (2, 'Minus bis 20'),
    (3, 'Sachaufgaben zwei Schritte'),
    (4, 'Sachaufgaben drei Schritte')
  ]) {
    testWidgets('grade $grade enters its real lesson, plays, pauses and steps',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      var lessonSeed = 23;
      if (grade <= 2) {
        for (var seed = 0; seed < 100; seed++) {
          final task = adapt(ExerciseFactory(seed: seed)
              .nextExact(grade: grade, subject: 'Mathematik', unit: unit));
          final data = task.visualPayload.data;
          final a = data['left'], b = data['right'];
          if (a is int &&
              b is int &&
              (grade == 1
                  ? a >= 3 && b >= 3
                  : a > 10 && b >= 4 && a - b < 10)) {
            lessonSeed = seed;
            break;
          }
        }
      }
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: LumoAppTheme.light(),
              home: CrossGradePracticeScreen(
                  profileName: 'Filmprobe',
                  taskSeed: lessonSeed,
                  enrolledGrade: grade,
                  lessonGrade: grade,
                  subject: 'Mathematik',
                  unit: unit))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final task = tester
          .widget<InteractiveTaskWorkspace>(
              find.byType(InteractiveTaskWorkspace))
          .task;
      expect(task.parameters['grade'], grade);
      expect(task.parameters['unit'], unit);
      final plan = MathFilmPlan.forTask(task)!;
      if (grade >= 3) {
        final builder = find.byKey(const ValueKey('story-plan-open'));
        await tester.ensureVisible(builder);
        await tester.tap(builder);
        await tester.pump();
        for (var i = 0; i < plan.shots.length; i++) {
          expect(find.byKey(ValueKey('story-notes-${task.taskInstanceId}-$i')),
              findsOneWidget);
        }
      }
      final open = find.byKey(const ValueKey('math-film-open'));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pump();
      final play = find.byKey(const ValueKey('math-film-play'));
      Future<void> frame(String label) async {
        await Scrollable.ensureVisible(
            tester.element(find.byType(MathExplanationFilm)),
            alignment: .42);
        await tester.pump();
        if (dir != null) {
          await captureLumoBoundary(tester, boundary, '$dir/$label.png',
              pixelRatio: 1);
        }
      }

      await frame('g${grade}_01');
      await tester.tap(play);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.tap(play);
      await tester.pump();
      final bar = find.descendant(
          of: find.byType(MathExplanationFilm),
          matching: find.byType(LinearProgressIndicator));
      final frozen = tester.widget<LinearProgressIndicator>(bar).value;
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<LinearProgressIndicator>(bar).value, frozen);
      expect(frozen, greaterThan(0));
      for (var i = 1; i < plan.shots.length; i++) {
        final next = find.byKey(const ValueKey('math-film-next'));
        await tester.tap(next);
        await tester.pump();
        expect(find.textContaining('Schritt ${i + 1} von ${plan.shots.length}'),
            findsOneWidget);
        await frame('g${grade}_0${i + 1}');
      }
      final back = find.byKey(const ValueKey('math-film-back'));
      await tester.tap(back);
      await tester.pump();
      expect(find.textContaining('Schritt ${plan.shots.length - 1} von'),
          findsOneWidget);
      if (grade == 1 && dir != null) {
        await tester.tap(play);
        await tester.pump();
        for (var i = 0; i < 7; i++) {
          await frame('rechnen_bewegung_$i');
        }
      }
      expect(
          tester
              .widget<FilledButton>(
                  find.byKey(const ValueKey('cross-grade-next')))
              .onPressed,
          isNull);
      expect(
          (await SharedPreferences.getInstance())
              .getKeys()
              .where((k) => k.endsWith(':answered')),
          isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
  for (final id in [
    'g4_fraction_add',
    'g4_decimal',
    'g4_written_mul',
    'g4_written_div'
  ]) {
    testWidgets('exact advanced arithmetic film for $id', (tester) async {
      final task = story(id, 27), plan = MathFilmPlan.forTask(story(id, 27))!;
      final original = task.visualPayload.data;
      if (id == 'g4_written_div') {
        final rest = (original['left'] as int) % (original['right'] as int);
        expect(rest, greaterThan(0));
        expect(plan.shots.last.equation.a, rest);
        expect(plan.shots.last.caption, contains('Rest'));
      }
      if (id == 'g4_fraction_add') {
        expect(plan.denominator, original['denominator']);
      }
      if (id == 'g4_decimal') expect(plan.decimals, original['decimalPlaces']);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MathExplanationFilm(
                  plan: plan, enabled: true, quiet: true, slow: false))));
      await tester.tap(find.byKey(const ValueKey('math-film-open')));
      await tester.pump();
      if (plan.expression case final expression?) {
        expect(find.text(expression), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('reduced motion displays the completed step on demand',
      (tester) async {
    final plan = MathFilmPlan.forTask(story('g1_word_problem', 7))!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MathExplanationFilm(
                plan: plan, enabled: true, quiet: true, slow: false))));
    await tester.tap(find.byKey(const ValueKey('math-film-open')));
    await tester.pump();
    expect(find.byKey(const ValueKey('math-film-play')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('math-film-next')));
    await tester.pump();
    expect(find.textContaining('Schritt 2 von 3'), findsOneWidget);
  });
}
