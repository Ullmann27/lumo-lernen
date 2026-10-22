import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/zahlen_bis_100/zahlen_bis_100_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_answer_crystal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
  });

  test('Math stage uses a real, bundled original Lumo pose', () async {
    // The cloud capture once tried to load lumo_math_cutout.png, which does
    // not exist. The production stage uses the approved original book pose.
    final image = await rootBundle.load(
      'assets/lumo_design/fox/fox_book_point.png',
    );
    expect(image.lengthInBytes, greaterThan(1024));
  });

  testWidgets('Answer crystals are neutral before any user answer',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: LumoCrystalAnswerGrid(
              children: [
                for (final n in ['23', '28', '26', '20'])
                  LumoAnswerCrystal(label: n, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LumoAnswerCrystal), findsNWidgets(4));
    for (final item in tester.widgetList<LumoAnswerCrystal>(
        find.byType(LumoAnswerCrystal))) {
      expect(item.state, LumoCrystalState.neutral);
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 800), const Size(320, 740)]) {
    testWidgets('Real Zahlen bis 100 loads without missing fox artwork at $size',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.runAsync(() async {
        await app.hydrateFromWallet();
        await app.loadLearningProfile();
      });
      app.state.settings = app.state.settings.copyWith(
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
      );
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: ZahlenBis100Screen(appState: app),
      ));
      await tester.pump(const Duration(milliseconds: 650));
      await tester.runAsync(() async {
        for (final image in find.byType(Image).evaluate()) {
          final widget = image.widget as Image;
          await precacheImage(widget.image, image);
        }
      });
      await tester.pump();
      expect(find.byType(LumoCrystalAnswerGrid), findsOneWidget);
      expect(find.byType(LumoAnswerCrystal), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
