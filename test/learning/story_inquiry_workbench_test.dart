import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';
import 'package:lumo_lernen/features/learning/widgets/inquiry_workbench.dart';
import 'package:lumo_lernen/features/learning/widgets/math_explanation_film.dart';
import 'package:lumo_lernen/features/learning/widgets/symmetry_workbench.dart';

import '../helpers/lumo_capture.dart';

TaskInstance adapt(LumoTask task) =>
    const LegacyLumoTaskAdapter().toTaskInstance(
        task: task,
        childId: 'werkbank',
        difficulty: task.grade,
        now: DateTime.utc(2026, 11, 22));

TaskInstance story(String id, int seed) {
  final template = MathTaskTemplates.templates.firstWhere((t) => t.id == id);
  final t = template.concretize(seed);
  return adapt(LumoTask(
      id: id,
      grade: template.grade,
      subject: 'Mathematik',
      unit: t.unit,
      prompt: t.prompt,
      choices: t.choices,
      answer: t.answer,
      explanation: t.explanation,
      visual: t.visual));
}

TaskInstance selectWhere(int grade, String subject, String unit,
    bool Function(TaskInstance) predicate) {
  final factory = ExerciseFactory(seed: 73);
  for (var n = 0; n < 250; n++) {
    final task =
        adapt(factory.nextExact(grade: grade, subject: subject, unit: unit));
    if (predicate(task)) return task;
  }
  throw StateError('No matching task for $unit');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final directory = Platform.environment['LUMO_MATH_CAPTURES'];
  setUpAll(loadLumoCaptureFonts);
  const boundary = ValueKey('story-capture');

  Future<void> open(WidgetTester tester, TaskInstance task) async {
    await tester.binding.setSurfaceSize(const Size(418, 875));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Nunito'),
        home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
                backgroundColor: const Color(0xff102847),
                body: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(task.prompt,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InteractiveTaskWorkspace(
                      key: ValueKey(task.taskInstanceId),
                      task: task,
                      enabled: true),
                ])))));
    await tester.pump();
  }

  test(
      'real selectable math, science and logic units yield an exact task for all four grades',
      () {
    final coverage = <String, Object?>{};
    for (var grade = 1; grade <= 4; grade++) {
      final subjects = <String, Object?>{};
      for (final subject in ['Mathematik', 'Sachunterricht', 'Logik']) {
        final units = <String, Object?>{};
        for (final unit in Curriculum.unitsForGrade(subject, grade,
            currentGradeOnly: true)) {
          final factory = ExerciseFactory(seed: 20265);
          final examples = <String>{};
          final visuals = <String>{};
          final inquiries = <String>{};
          final native = <String>{};
          var filmCount = 0;
          for (var n = 0; n < 8; n++) {
            final t = factory.nextExact(
                grade: grade,
                subject: subject,
                unit: unit,
                currentGradeOnly: true);
            expect(t.unit, unit);
            final task = adapt(t);
            expect(task.parameters['unit'], unit);
            examples.add(task.prompt);
            if (MathFilmPlan.forTask(task) != null) filmCount++;
            visuals.add(task.visualPayload.type.name);
            final kind = InquiryWorkbench.kindFor(task) ??
                (SymmetryWorkbench.shapeFor(task) == null ? null : 'mirror');
            if (kind != null) inquiries.add(kind);
            final activity = NativeLearningActivity.fromTask(task);
            if (activity != null) native.add(activity.kind);
          }
          units[unit] = {
            'distinctPrompts': examples.length,
            'arithmeticFilmsInEightTasks': filmCount,
            'rendererTypes': visuals.toList(),
            'inquiry': inquiries.toList(),
            'native': native.toList()
          };
        }
        subjects[subject] = units;
      }
      subjects['Praktische Aktivitäten'] =
          PrimaryActivityCatalog.forGrade(grade)
              .map((a) => a.subject)
              .toSet()
              .toList();
      coverage['$grade'] = subjects;
    }
    if (directory != null) Directory(directory).createSync(recursive: true);
    if (directory != null) {
      File('$directory/curriculum.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(coverage));
    }
  });

  for (final id in ['g1_word_problem', 'g2_sub_story']) {
    testWidgets('exact count model and native counters for $id',
        (tester) async {
      final task = story(id, 7);
      await open(tester, task);
      final data = task.visualPayload.data;
      expect(data['storyStart'], isA<int>());
      expect(
          NativeLearningActivity.fromTask(task)
              ?.toLaunchOptions()['storyPrompt'],
          task.prompt);
      final first = find.byKey(const ValueKey('story-counter-0'));
      await tester.tap(first);
      await tester.pump();
      expect(
          find.descendant(
              of: first,
              matching: find
                  .byIcon(id == 'g2_sub_story' ? Icons.close : Icons.check)),
          findsOneWidget);
      if (directory != null) {
        await captureLumoBoundary(tester, boundary, '$directory/$id.png',
            pixelRatio: 1);
      }
    });
  }
  for (final id in ['g3_two_step', 'g4_three_step']) {
    testWidgets('independent, editable plan for $id', (tester) async {
      final task = story(id, id == 'g3_two_step' ? 11 : 7);
      await open(tester, task);
      await tester.tap(find.byKey(const ValueKey('story-fact-1')));
      await tester.tap(find.byKey(const ValueKey('story-plan-open')));
      await tester.pump();
      expect(
          find.byType(TextField), findsNWidgets(id == 'g3_two_step' ? 2 : 3));
      final note = id == 'g4_three_step'
          ? '56 + 12 = 68 Personen'
          : 'Wie viele Jacken bleiben zuerst?';
      await tester.enterText(find.byType(TextField).first, note);
      tester.testTextInput.hide();
      await tester.pump();
      expect(find.text(note), findsOneWidget);
      if (directory != null) {
        await captureLumoBoundary(tester, boundary, '$directory/$id.png',
            pixelRatio: 1);
      }
    });
  }
  testWidgets('a chosen axis really changes the reflected model',
      (tester) async {
    final t = selectWhere(4, 'Mathematik', 'Symmetrieachsen',
        (t) => SymmetryWorkbench.shapeFor(t) == 'trapezoid');
    await open(tester, t);
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mirror-preview')));
    await tester.drag(slider, const Offset(100, 0));
    await tester.pump();
    expect(find.text('Decken sich die beiden Umrisse?'), findsOneWidget);
    expect(tester.widget<Slider>(slider).value, isNot(90));
    if (directory != null) {
      await captureLumoBoundary(tester, boundary, '$directory/symmetry.png',
          pixelRatio: 1);
    }
  });
  testWidgets('rearrange real children and experiment with a broken circuit',
      (tester) async {
    final line = selectWhere(4, 'Logik', 'Schlussfolgern',
        (t) => InquiryWorkbench.kindFor(t) == 'lineup');
    await open(tester, line);
    final label = line.options.last.label;
    await tester.tap(find.widgetWithText(ActionChip, label));
    await tester.pump();
    expect(find.text('1 · $label'), findsOneWidget);
    if (directory != null) {
      await captureLumoBoundary(tester, boundary, '$directory/lineup.png',
          pixelRatio: 1);
    }
    final circuit = selectWhere(4, 'Sachunterricht', 'Stromkreise',
        (t) => InquiryWorkbench.kindFor(t) == 'circuit');
    await open(tester, circuit);
    await tester.tap(find.byKey(const ValueKey('circuit-switch')));
    await tester.pump();
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('circuit-wire')));
    await tester.pump();
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    if (directory != null) {
      await captureLumoBoundary(tester, boundary, '$directory/circuit.png',
          pixelRatio: 1);
    }
  });
}
