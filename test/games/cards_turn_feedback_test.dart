import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_turn_pill.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_draw_pile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoMusic.instance.muted = true;
    LumoSound.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });
  setUpAll(loadLumoCaptureFonts);

  testWidgets('Draw feedback respects reduced motion without delaying input',
      (tester) async {
    var draws = 0;
    Future<void> show(int left) => tester.pumpWidget(MaterialApp(
        home: Center(
            child: LumoDrawPile(
                cardsLeft: left, reduceMotion: true, onDraw: () => draws++))));
    await show(97);
    await tester.tap(find.byType(LumoDrawPile));
    expect(draws, 1);
    await tester.pumpAndSettle(); // Finish InkWell's independent tap ripple.
    await show(96);
    await tester.pump(const Duration(milliseconds: 140));
    final transforms = tester.widgetList<Transform>(find.descendant(
        of: find.byType(LumoDrawPile), matching: find.byType(Transform)));
    expect(transforms.first.transform.getTranslation().y, 0);
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('96 Karten'), findsOneWidget);
  });

  testWidgets('Cards real turn feedback remains readable in calm mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
    await app.hydrateFromWallet();
    const boundary = ValueKey('cards-turn-feedback-capture');
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
            key: boundary, child: LumoCardsScreen(appState: app, seed: 10))));
    await tester.pump(const Duration(seconds: 3));
    if (find.byType(LumoIntroSplash).evaluate().isNotEmpty) {
      await tester.tap(find.byType(LumoIntroSplash));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LumoTurnPill), findsOneWidget);
    final pill = tester.widget<Text>(find.text('DEIN ZUG'));
    for (final background in const [Color(0xFF38BDF8), Color(0xFF0EA5E9)]) {
      final foregroundLuminance = pill.style!.color!.computeLuminance();
      final contrast =
          (background.computeLuminance() + .05) / (foregroundLuminance + .05);
      expect(contrast, greaterThan(4.5),
          reason: 'Turn text must stay readable across the cyan gradient.');
    }
    expect(tester.widget<LumoDrawPile>(find.byType(LumoDrawPile)).reduceMotion,
        isTrue);
    final deckCount = tester.widget<Text>(find.text('97 Karten'));
    expect(deckCount.style!.color!.computeLuminance(), greaterThan(.7));
    final folder = Platform.environment['LUMO_CARDS_CAPTURES'];
    if (folder != null) {
      await captureLumoBoundary(
          tester, boundary, '$folder/cards-turn-phone.png',
          pixelRatio: 1.5);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
