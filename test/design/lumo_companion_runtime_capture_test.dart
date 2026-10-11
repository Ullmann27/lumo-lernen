// Actual Flutter test-runtime frames with original app assets and real taps.
// Not an Android screenshot, physical Samsung recording or audible voice test.
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
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _boundary = ValueKey('actual-learning-companion-capture');
final _output = Platform.environment['LUMO_COMPANION_CAPTURE_DIR'];

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
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

  for (final (name, size, density) in [
    ('phone-360x800', const Size(360, 800), 1.0),
    ('fold-target', const Size(2176 / 2.25, 1812 / 2.25), 2.25),
  ]) {
    testWidgets('real task, wrong answer and accepted alternative help: $name',
        (tester) async {
      tester.view.devicePixelRatio = density;
      tester.view.physicalSize = size * density;
      await tester.binding.setSurfaceSize(size);
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
            voiceEnabled: false,
            autoReadEnabled: false,
            reduceAnimations: true));
      });
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: RepaintBoundary(
              key: _boundary, child: PlusBis10Screen(appState: app))));
      await _frames(tester, 30);
      await _capture(tester, '$name-task');
      final prompt = LumoCompanionRequests.instance.taskContext.value!.prompt;
      final correct = RegExp(r'\d+')
          .allMatches(prompt)
          .map((match) => int.parse(match[0]!))
          .reduce((a, b) => a + b);
      final wrong = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(GridView), matching: find.byType(Text)))
          .map((text) => int.parse(text.data!))
          .firstWhere((value) => value != correct);
      final choice = find.descendant(
          of: find.byType(GridView), matching: find.text('$wrong'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await _frames(tester);
      expect(
          LumoCompanionRequests.instance.taskContext.value!.lastCorrect, false);
      await tester.ensureVisible(find.text('Tipp'));
      await tester.tap(find.text('Tipp'));
      await _frames(tester, 10);
      await _capture(tester, '$name-actual-help');
      await tester.ensureVisible(find.text('Anderer Tipp'));
      await tester.tap(find.text('Anderer Tipp'));
      await _frames(tester, 10);
      await _capture(tester, '$name-alternative-help');
      expect(LumoCompanionRequests.instance.taskContext.value!.prompt, prompt);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, skip: _output == null);
  }
}
