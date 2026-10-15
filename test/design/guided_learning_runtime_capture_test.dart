// Genuine Flutter widget-runtime captures, original app art and actual taps.
// These are not Android, physical Samsung, audible voice or measured-FPS proof.
import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:lumo_lernen/features/settings/discovery_settings_card.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';
import 'package:lumo_lernen/features/tutoring/guided_learning_hub.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _boundary = ValueKey('actual-guided-learning-capture');
final _output = Platform.environment['LUMO_GUIDED_CAPTURE_DIR'];

Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, Finder target, {int frames = 30}) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _frames(tester, frames);
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    await Future.wait(find.byType(Image).evaluate().map(
        (element) => precacheImage((element.widget as Image).image, element)));
  });
  await tester.pump();
  expect(tester.takeException(), isNull);
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_output/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<LumoAppState> _app(
    WidgetTester tester, Size size, double density) async {
  tester.view.devicePixelRatio = density;
  tester.view.physicalSize = size * density;
  await tester.binding.setSurfaceSize(size);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late LumoAppState app;
  await tester.runAsync(() async {
    // Real native-storage queue tails are initialized in their real async zone.
    app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state
        .copyWith(childName: 'Testkind', grade: 1, section: LumoSection.learn));
    await app.school.setActiveStudent('guided-visual-test-a');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        soundEnabled: false,
        reduceAnimations: false));
  });
  addTearDown(app.dispose);
  return app;
}

Widget _shell(Widget home, String key) => MaterialApp(
      key: ValueKey(key),
      theme: LumoAppTheme.light(),
      builder: (context, child) =>
          RepaintBoundary(key: _boundary, child: child!),
      home: home,
    );

Future<void> _actualParentGrant(
    WidgetTester tester, LumoAppState app, String name) async {
  await tester.pumpWidget(_shell(
      Scaffold(
        backgroundColor: const Color(0xFF071B3B),
        appBar: AppBar(title: const Text('Elternbereich')),
        body: SettingsContent(appState: app),
      ),
      'parent-$name'));
  await _frames(tester);
  await tester.scrollUntilVisible(
      find.byKey(const ValueKey('discovery-parent-switch')), 240,
      scrollable: find
          .descendant(
              of: find.byType(SettingsContent),
              matching: find.byType(Scrollable))
          .first);
  await _frames(tester, 5);
  final card = find.byType(DiscoverySettingsCard);
  final limit = find.descendant(
      of: card, matching: find.byType(DropdownButtonFormField<int>));
  await _tap(tester, limit);
  await _tap(tester, find.text('Bis zur 2. Schulstufe').last);
  await _tap(tester, find.byKey(const ValueKey('discovery-parent-switch')));
  if (name.startsWith('phone')) {
    await _capture(tester, '$name-actual-adult-confirmation');
  }
  await _tap(tester, find.text('Als Erwachsene:r freigeben'));
  if (name.startsWith('phone')) {
    await tester.ensureVisible(card);
    await _frames(tester, 5);
    await _capture(tester, '$name-actual-parent-permission');
  }
  final owner = await tester.runAsync(app.captureLearningProfile);
  expect(owner!.profile.canDiscover(2), true);
  expect(app.state.settings.aiProxyEnabled, false);
  expect(app.state.settings.cloudVoiceEnabled, false);
  expect(app.state.settings.microphoneEnabled, false);
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
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);

  for (final (name, size, density) in [
    ('phone-360x800', const Size(360, 800), 1.0),
    ('fold-target', const Size(2176 / 2.25, 1812 / 2.25), 2.25),
  ]) {
    for (final (lesson, discovery) in [
      (GuidedLessonCatalog.bridgeTen, false),
      (GuidedLessonCatalog.equalGroups, true),
      (GuidedLessonCatalog.subtractTen, false),
    ]) {
      testWidgets('actual ${lesson.id} example and controls: $name',
          (tester) async {
        final app = await _app(tester, size, density);
        if (discovery) await _actualParentGrant(tester, app, name);
        await tester.pumpWidget(_shell(
            GuidedLearningHub(appState: app, discovery: discovery),
            'hub-$name-${lesson.id}'));
        await _frames(tester);
        if (discovery && name.startsWith('phone')) {
          await _capture(tester, '$name-actual-discovery-hub');
        }
        await _tap(tester, find.byKey(ValueKey('guided-open-${lesson.id}')));
        await _tap(tester, find.widgetWithText(FilledButton, 'Weiter'));
        final foundation = lesson.steps[1];
        await _tap(tester,
            find.byKey(ValueKey('guided-answer-${foundation.expected}')));
        await _tap(tester, find.widgetWithText(FilledButton, 'Weiter'),
            frames: 1);
        expect(find.text(lesson.steps[2].title), findsOneWidget);
        await _frames(tester, 110);
        await _capture(tester, '$name-actual-${lesson.id}-example');
        if (lesson.id == 'bridge_ten' && name == 'fold-target') {
          // The video consists only of frames captured from the actual running
          // TweenAnimationBuilder after the child's real Replay button tap.
          await _tap(tester, find.text('Beispiel noch einmal'), frames: 1);
          for (var frame = 0; frame < 64; frame++) {
            await _capture(tester,
                'bridge-frames/frame-${frame.toString().padLeft(4, "0")}');
            await tester.pump(const Duration(milliseconds: 50));
            expect(tester.takeException(), isNull);
          }
        }
        // Genuine return from course to its hub, not a final-screen mock.
        await _tap(tester, find.byKey(const ValueKey('learning-module-back')));
        expect(find.byType(GuidedLearningHub), findsOneWidget);
        expect(app.state.grade, 1);
        if (discovery) expect(app.learningDailyDone(), 0);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      }, skip: _output == null);
    }
  }
}
