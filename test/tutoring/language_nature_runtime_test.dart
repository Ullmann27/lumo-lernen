import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _boundary = ValueKey('language-nature-runtime');
final _captureDirectory =
    Platform.environment['LUMO_LANGUAGE_NATURE_CAPTURE_DIR'];
Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory == null) return;
  await tester.runAsync(() async {
    await Future.wait(find
        .byType(Image)
        .evaluate()
        .map((e) => precacheImage((e.widget as Image).image, e)));
  });
  await tester.pump();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_captureDirectory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _frames(WidgetTester tester, [int count = 35]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _frames(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);
  for (final lesson in [
    GuidedLessonCatalog.syllables,
    GuidedLessonCatalog.plantParts
  ]) {
    for (final (viewport, size, textScale) in [
      ('phone', const Size(390, 844), 1.0),
      ('small-large-type', const Size(320, 568), 2.0),
      ('fold-target', const Size(967, 805), 1.0),
    ]) {
      testWidgets(
          '${lesson.subject}/$viewport: complete real taps and subject-specific saved restart',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await tester.binding.setSurfaceSize(size);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        late LumoAppState app;
        await tester.runAsync(() async {
          app = LumoAppState(walletRepository: RewardWalletRepository());
          app.setSection(LumoSection.learn);
          await app.school.setActiveStudent('language-nature-a');
          await app.hydrateFromWallet();
          await app.loadLearningProfile();
          await app.recordLearningAnswer(
              subject: 'Mathematik',
              unit: 'Plus bis 10',
              correct: true,
              requireSaved: true);
          app.updateSettings(
              const AppSettings(voiceEnabled: false, reduceAnimations: true));
        });
        addTearDown(app.dispose);
        final beforeMath =
            app.learningSkills()['mathematik::plus bis 10']!.toJson();
        final beforeWallet = app.state.stars;
        await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!),
            home: RepaintBoundary(
                key: _boundary,
                child: GuidedLessonScreen(
                    appState: app, lesson: lesson, discovery: false))));
        await _frames(tester);
        var submittedWrong = false;
        for (final step in lesson.steps) {
          expect(
              tester
                  .widget<Text>(find.byKey(const ValueKey('guided-step-title')))
                  .data,
              step.title);
          if (step.type.name == 'showExample') {
            final illustration =
                find.byKey(const ValueKey('guided-flowering-plant'));
            if (illustration.evaluate().isNotEmpty)
              await tester.ensureVisible(illustration);
            await _capture(tester, '${lesson.id}-$viewport-example');
          }
          if (step.isQuestion) {
            expect(LumoCompanionRequests.instance.taskContext.value!.subject,
                lesson.subject);
            if (step.isIndependent) {
              expect(find.byKey(const ValueKey('guided-demonstrated-part')),
                  findsNothing);
              for (var i = 0; i < step.syllables.length; i++) {
                expect(find.byKey(ValueKey('guided-spoken-syllable-$i')),
                    findsNothing);
              }
              if (!submittedWrong) {
                await tester.ensureVisible(
                    find.byKey(const ValueKey('guided-step-title')));
                await _capture(tester, '${lesson.id}-$viewport-independent');
                submittedWrong = true;
                final wrong =
                    step.choices.firstWhere((v) => v != step.expected);
                await _tap(
                    tester, find.byKey(ValueKey('guided-answer-$wrong')));
                await _tap(tester, find.text('Tipp'));
                final first = tester
                    .widget<Text>(
                        find.byKey(const ValueKey('guided-actual-hint')))
                    .data;
                await _tap(tester, find.text('Anderer Tipp'));
                expect(
                    tester
                        .widget<Text>(
                            find.byKey(const ValueKey('guided-actual-hint')))
                        .data,
                    isNot(first));
                expect(app.learningDailyDone(), 1);
                await tester.ensureVisible(
                    find.byKey(const ValueKey('guided-actual-hint')));
                await _capture(
                    tester, '${lesson.id}-$viewport-alternative-help');
              }
            }
            await _tap(
                tester, find.byKey(ValueKey('guided-answer-${step.expected}')));
            expect(
                tester
                    .widget<Text>(find.byKey(const ValueKey('guided-feedback')))
                    .data,
                isNot(contains('gerechnet')));
          }
          if (step != lesson.steps.last)
            await _tap(tester, find.byKey(const ValueKey('guided-continue')));
        }
        expect(find.textContaining('2 neue Aufgaben selbst gelöst.'),
            findsOneWidget);
        final id =
            '${lesson.subject.toLowerCase()}::${lesson.schoolUnit.toLowerCase()}';
        final record = app.learningSkills()[id]!;
        expect(record.correct, 2);
        expect(record.wrong, 1);
        expect(record.hintCount, 1);
        expect(app.learningSkills()['mathematik::plus bis 10']!.toJson(),
            beforeMath);
        expect(app.learningDailyDone(), 3);
        expect(app.state.stars, beforeWallet);
        expect(LumoCompanionRequests.instance.learningEvents.value.last.kind,
            LumoLearningEventKind.lessonCompleted);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          final restarted = LearningProfileEngine(
              repository: ProgressRepository(studentId: 'language-nature-a'));
          await restarted.load();
          expect(restarted.skills[id]!.correct, 2);
          final other = LearningProfileEngine(
              repository: ProgressRepository(studentId: 'language-nature-b'));
          await other.load();
          expect(other.skills, isEmpty);
        });
        expect(tester.takeException(), isNull);
      });
    }
  }
}
