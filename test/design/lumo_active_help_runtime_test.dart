// Actual Flutter frames and answer taps; never physical-device evidence.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _boundary = ValueKey('active-help-runtime');
final _output = Platform.environment['LUMO_ACTIVE_HELP_CAPTURE_DIR'];

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_output == null) return;
  await tester.runAsync(() async {
    await Future.wait(find.byType(Image).evaluate().map(
        (element) => precacheImage((element.widget as Image).image, element)));
  });
  await tester.pump();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_output/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);

  for (final (name, size, textScale) in [
    ('phone', const Size(360, 800), 1.0),
    ('fold-outer', const Size(344, 882), 1.0),
    ('fold-inner', const Size(2176 / 2.25, 1812 / 2.25), 1.0),
    ('landscape', const Size(800, 360), 1.0),
    ('large-text', const Size(390, 844), 1.6),
  ]) {
    testWidgets(
        'real Plus help offer is usable at $name',
        (tester) => withClock(tester.binding.clock, () async {
              await tester.binding.setSurfaceSize(size);
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = size;
              addTearDown(tester.view.resetDevicePixelRatio);
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(() => tester.binding.setSurfaceSize(null));
              late LumoAppState app;
              await tester.runAsync(() async {
                app = LumoAppState(walletRepository: RewardWalletRepository());
                app.setSection(LumoSection.learn);
                await app.hydrateFromWallet();
                await app.loadLearningProfile();
                app.updateSettings(const AppSettings(
                    voiceEnabled: false, reduceAnimations: true));
              });
              addTearDown(app.dispose);
              await tester.pumpWidget(MaterialApp(
                  theme: LumoAppTheme.light(),
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(textScale)),
                      child: child!),
                  home: RepaintBoundary(
                      key: _boundary, child: PlusBis10Screen(appState: app))));
              await _frames(tester);
              final requests = LumoCompanionRequests.instance;
              final original = requests.taskContext.value!;
              final answer = RegExp(r'\d+')
                  .allMatches(original.prompt)
                  .map((match) => int.parse(match[0]!))
                  .reduce((a, b) => a + b);
              final wrong = tester
                  .widgetList<Text>(find.descendant(
                      of: find.byType(GridView), matching: find.byType(Text)))
                  .map((text) => int.parse(text.data!))
                  .firstWhere((v) => v != answer);
              final choice = find.descendant(
                  of: find.byType(GridView), matching: find.text('$wrong'));
              for (var i = 0; i < 2; i++) {
                await tester.ensureVisible(choice);
                await tester.tap(choice);
                await _frames(tester);
              }
              expect(find.byKey(const ValueKey('plus10-actual-companion-hint')),
                  findsNothing);
              await _capture(tester, '$name-before-offer');
              await tester.pump(const Duration(seconds: 18));
              final offer =
                  find.byKey(const ValueKey('lumo-inline-help-accept'));
              expect(offer, findsOneWidget);
              await tester.ensureVisible(offer);
              await tester.pump();
              expect(offer.hitTestable(), findsOneWidget);
              expect(tester.getSize(offer).height, greaterThanOrEqualTo(48));
              expect(tester.takeException(), isNull);
              await _capture(tester, '$name-offer');
              await tester.tap(offer);
              await _frames(tester, 10);
              expect(requests.taskContext.value!.taskId, original.taskId);
              expect(requests.taskContext.value!.helpLevel, 1);
              expect(app.learningDailyDone(), 0);
              expect(app.learningSkills()['mathematik::plus bis 10']!.wrong, 2);
              expect(tester.takeException(), isNull);
              await _capture(tester, '$name-accepted-help');
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
            }));
  }

  testWidgets(
      'actual guided Minus offers help without changing the task',
      (tester) => withClock(tester.binding.clock, () async {
            await tester.binding.setSurfaceSize(const Size(600, 1100));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            late LumoAppState app;
            await tester.runAsync(() async {
              app = LumoAppState(walletRepository: RewardWalletRepository());
              app.setSection(LumoSection.learn);
              await app.hydrateFromWallet();
              await app.loadLearningProfile();
              app.updateSettings(const AppSettings(
                  voiceEnabled: false, reduceAnimations: true));
            });
            addTearDown(app.dispose);
            const lesson = GuidedLessonCatalog.subtractTen;
            await tester.pumpWidget(MaterialApp(
                home: GuidedLessonScreen(
                    appState: app, lesson: lesson, discovery: false)));
            await _frames(tester);
            for (final step in lesson.steps) {
              if (step.isQuestion) {
                final original =
                    LumoCompanionRequests.instance.taskContext.value!;
                final wrong = step.choices
                    .firstWhere((answer) => answer != step.expected);
                final choice = find.byKey(ValueKey('guided-answer-$wrong'));
                for (var i = 0; i < 2; i++) {
                  await tester.ensureVisible(choice);
                  await tester.tap(choice);
                  await _frames(tester);
                }
                expect(find.byKey(const ValueKey('guided-actual-hint')),
                    findsNothing);
                await tester.pump(const Duration(seconds: 18));
                final offer =
                    find.byKey(const ValueKey('lumo-inline-help-accept'));
                expect(offer, findsOneWidget);
                await tester.ensureVisible(offer);
                await tester.tap(offer);
                await _frames(tester, 10);
                expect(find.byKey(const ValueKey('guided-actual-hint')),
                    findsOneWidget);
                expect(LumoCompanionRequests.instance.taskContext.value!.taskId,
                    original.taskId);
                expect(app.learningDailyDone(), 0);
                break;
              }
              final next = find.byKey(const ValueKey('guided-continue'));
              await tester.ensureVisible(next);
              await tester.tap(next);
              await _frames(tester);
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            expect(tester.takeException(), isNull);
          }));
}
