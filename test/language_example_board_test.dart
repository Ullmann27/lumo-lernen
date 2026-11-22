import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/features/learning/widgets/language_practice_material.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_english_vocabulary.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';
import 'package:lumo_lernen/features/learning/widgets/language_example_board.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final captureDir = Platform.environment['LUMO_LANGUAGE_CAPTURE_DIR'];
  if (captureDir != null) {
    setUpAll(() async {
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
          .load();
    });
  }
  test(
      'Every locally selectable German and English exercise has a language model',
      () {
    for (final activity in PrimaryActivityCatalog.all
        .where((a) => ['Deutsch', 'Englisch'].contains(a.subject))) {
      expect(LanguagePracticeMaterial.supports(activity.id), isTrue,
          reason: activity.id);
    }
    for (final grade in [1, 2, 3, 4]) {
      for (final subject in [
        'Deutsch',
        'Englisch',
        'Lesen',
        'Schreiben',
        'Rechtschreibung'
      ]) {
        final language = subject == 'Englisch'
            ? LearningSubject.englisch
            : LearningSubject.deutsch;
        for (final unit in Curriculum.unitsForGrade(subject, grade)) {
          expect(LanguageExample.forUnit(unit, language), isNotNull,
              reason: '$grade / $subject / $unit');
        }
      }
    }
  });

  test('English animal illustrations are bound to their real current words',
      () {
    final factory = ExerciseFactory(seed: 2065);
    final animals = <String>{};
    for (var i = 0; i < 220; i++) {
      final task =
          factory.nextExact(grade: 2, subject: 'Englisch', unit: 'Tiere');
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
          task: task, childId: 'animal-check', difficulty: task.difficulty);
      final object = NativeEnglishVocabulary.illustrationFor(instance);
      if (object != null) {
        expect(object['meaning'], task.answer);
        animals.add(object['word']! as String);
      }
    }
    expect(animals, containsAll(['lion', 'cow', 'sheep']));
  });

  testWidgets('Picture cards reveal one word and report a help action',
      (tester) async {
    final task = LumoTask(
        id: 'picture-test',
        grade: 1,
        subject: 'Englisch',
        unit: 'Farben',
        prompt: 'Was bedeutet „red“?',
        answer: 'rot',
        choices: ['rot', 'blau', 'gelb', 'grün'],
        explanation: 'Red bedeutet rot.');
    final instance = const LegacyLumoTaskAdapter()
        .toTaskInstance(task: task, childId: 'test', difficulty: 1);
    final actions = <TaskWorkspaceInteraction>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InteractiveTaskWorkspace(
                task: instance, onInteraction: actions.add))));
    expect(find.byType(CircleAvatar), findsNWidgets(4));
    expect(find.text('rot'), findsNothing);
    await tester.tap(find.byType(CircleAvatar).first);
    await tester.pump();
    expect(actions.last.action, 'inspectLanguageExample');
    expect(actions.last.isHelp, isTrue);
  });

  for (final grade in [1, 2, 3, 4]) {
    testWidgets(
        'Grade $grade sees and explores the example in the real workspace',
        (tester) async {
      final task = ExerciseFactory(seed: 43)
          .nextExact(grade: grade, subject: 'Englisch', unit: 'Begruessung');
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
          task: task, childId: 'local-test', difficulty: task.difficulty);
      expect(instance.parameters['grade'], grade);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: InteractiveTaskWorkspace(task: instance)))));
      if (grade >= 3) {
        expect(find.text('Hello!'), findsNothing);
        await tester.tap(find.text('Beispiel erkunden'));
        await tester.pump();
      }
      await tester.tap(find.text('Hello!'));
      await tester.pump();
      expect(find.text('Hi, Mia!'), findsOneWidget);
      if (grade == 2) expect(find.text('Beispiel · 2 von 2'), findsOneWidget);
    });
  }
  for (final item in [
    (1, 'Deutsch', 'Silben'),
    (1, 'Englisch', 'Zahlen'),
    (2, 'Deutsch', 'Tunwoerter'),
    (2, 'Englisch', 'Tiere'),
    (3, 'Deutsch', 'Zeitformen'),
    (3, 'Englisch', 'Wetter'),
    (4, 'Deutsch', 'Die 4 Fälle'),
    (4, 'Englisch', 'Wochentage'),
  ]) {
    final (grade, subject, unit) = item;
    testWidgets('Normal lesson demonstrates $subject $grade / $unit',
        (tester) async {
      final task = ExerciseFactory(seed: 53)
          .nextExact(grade: grade, subject: subject, unit: unit);
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
          task: task, childId: 'grade-check', difficulty: task.difficulty);
      final answers = <AdaptiveTaskAnswer>[];
      await tester.binding.setSurfaceSize(const Size(412, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: 'Nunito'),
          home: RepaintBoundary(
              key: const ValueKey('lesson-sample'),
              child: Scaffold(
                  backgroundColor: const Color(0xff12365c),
                  body: SingleChildScrollView(
                      child: AdaptiveTaskRenderer(
                    task: instance,
                    onAnswered: answers.add,
                  ))))));
      if (grade >= 3) {
        await tester.ensureVisible(find.text('Beispiel erkunden'));
        await tester.tap(find.text('Beispiel erkunden'));
        await tester.pump();
      }
      final play = find.byKey(const ValueKey('language-play-steps'));
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pump();
      expect(find.byKey(const ValueKey('language-beat-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('language-beat-1')), findsNothing);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(find.byKey(const ValueKey('language-beat-1')), findsOneWidget);
      expect(answers, isEmpty);
      if (captureDir != null) {
        await tester.pump(const Duration(seconds: 6));
        await tester.ensureVisible(find.byType(LanguageStepSequence));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('lesson-sample')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(captureDir).create(recursive: true);
            await File('$captureDir/$grade-$subject.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'Every oral or written assignment shows a static worked sequence in reduced motion',
      (tester) async {
    final activities = PrimaryActivityCatalog.all
        .where((a) => ['Deutsch', 'Englisch'].contains(a.subject));
    for (final activity in activities) {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: const MediaQueryData(
                  disableAnimations: true, textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      child: LanguagePracticeMaterial(activity,
                          key: ValueKey(activity.id)))))));
      final play = find.byKey(const ValueKey('language-play-steps'));
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pump();
      final player = tester
          .widget<LanguageStepSequence>(find.byType(LanguageStepSequence));
      expect(player.reduceMotion, isTrue, reason: activity.id);
      expect(find.byKey(ValueKey('language-beat-${player.steps.length - 1}')),
          findsOneWidget,
          reason: activity.id);
      expect(tester.takeException(), isNull, reason: activity.id);
    }
  });
}
