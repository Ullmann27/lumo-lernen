import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_turn_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
  });
  for (final scale in [1.0, 1.4]) {
    testWidgets(
        'short landscape keeps turn and actions inside system bars at $scale',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      LumoSound.instance.muted = true;
      LumoMusic.instance.muted = true;
      LumoVoice.instance.isEnabled = false;
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      await app.hydrateFromWallet();
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.symmetric(vertical: 24),
            viewPadding: const EdgeInsets.symmetric(vertical: 24),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: LumoCardsScreen(appState: app, seed: 10),
      ));
      await tester.pump(const Duration(seconds: 3));
      if (find.byType(LumoIntroSplash).evaluate().isNotEmpty) {
        await tester.tap(find.byType(LumoIntroSplash));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      const safe = Rect.fromLTWH(0, 24, 640, 312);
      final turn = tester.getRect(find.byType(LumoTurnBanner));
      expect(turn.top, greaterThanOrEqualTo(safe.top));
      expect(turn.bottom, lessThanOrEqualTo(safe.bottom));
      for (final tooltip in [
        'Pausieren / Zurück',
        'Am 3D-Tisch spielen',
        'Ton einstellen'
      ]) {
        final rect = tester.getRect(find.byTooltip(tooltip));
        expect(rect.top, greaterThanOrEqualTo(safe.top));
        expect(rect.bottom, lessThanOrEqualTo(safe.bottom));
        expect(rect.left, greaterThanOrEqualTo(safe.left));
        expect(rect.right, lessThanOrEqualTo(safe.right));
        final targetSize = tester.getSize(find.byTooltip(tooltip));
        expect(targetSize.width, greaterThanOrEqualTo(48));
        expect(targetSize.height, greaterThanOrEqualTo(48));
      }
      await tester.tap(find.byTooltip('Pausieren / Zurück'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Spiel pausiert'), findsOneWidget);
      await tester.tap(find.text('Fortsetzen'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Spiel pausiert'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
