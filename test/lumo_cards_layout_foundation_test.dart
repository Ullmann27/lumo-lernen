import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_turn_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  for (final size in [
    const Size(640, 360),
    const Size(840, 400),
    const Size(360, 800),
    const Size(1200, 896),
  ]) {
    testWidgets('Cards playable layout and pause at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.hydrateFromWallet();
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: LumoCardsScreen(appState: app, seed: 10),
      ));
      await tester.pump(const Duration(seconds: 3));
      if (find.byType(LumoIntroSplash).evaluate().isNotEmpty) {
        await tester.tap(find.byType(LumoIntroSplash));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      final arena = tester.getRect(find.byKey(const ValueKey('cards-arena')));
      expect(arena.height, greaterThanOrEqualTo(160));
      final title = tester.renderObject<RenderParagraph>(
        find.text('🦊 Lumo Cards'),
      );
      expect(title.didExceedMaxLines, isFalse);
      for (final tooltip in [
        'Ton einstellen',
        'Pausieren / Zurück',
        'Avatar wechseln',
      ]) {
        final rect = tester.getRect(find.byTooltip(tooltip));
        expect((Offset.zero & size).contains(rect.topLeft), isTrue);
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      final beforeStars = app.state.stars;
      await tester.tap(find.byTooltip('Pausieren / Zurück'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Spiel pausiert'), findsOneWidget);
      await tester.tap(find.text('Fortsetzen'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Spiel pausiert'), findsNothing);
      expect(app.state.stars, beforeStars);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Turn pill stops and restarts when calm mode changes', (
    tester,
  ) async {
    Future<void> show({bool reduceMotion = false, bool isMyTurn = true}) async {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: LumoTurnPill(
            isMyTurn: isMyTurn,
            reduceMotion: reduceMotion,
          ),
        ),
      ));
    }

    await show(reduceMotion: true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await show(isMyTurn: false);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show(reduceMotion: true);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
