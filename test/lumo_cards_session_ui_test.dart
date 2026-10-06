import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/shared/lumo_game_pause_scope.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_assets.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_avatar_picker.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_card_fly.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_discard_pile.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_draw_pile.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_player_hud.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_player_hand.dart';

LumoGameTurnClock _clock(WidgetTester tester) => tester
    .widget<LumoGamePauseScope>(find.byType(LumoGamePauseScope))
    .clock;

List<Object> _board(WidgetTester tester) => [
      tester.widget<LumoDiscardPile>(find.byType(LumoDiscardPile)).topCard.id,
      tester.widget<LumoDrawPile>(find.byType(LumoDrawPile)).cardsLeft,
      // Solo mode renders Lumo himself instead of the old opponent fan.
      tester.widgetList<LumoPlayerHud>(find.byType(LumoPlayerHud)).first.cardCount,
    ];

Future<void> _open(WidgetTester tester,
    {Size size = const Size(360, 780), bool reduceMotion = false}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  await app.hydrateFromWallet();
  app.updateSettings(
      app.state.settings.copyWith(reduceAnimations: reduceMotion));
  addTearDown(app.dispose);
  await tester.pumpWidget(MaterialApp(
    home: LumoCardsScreen(appState: app, seed: 10),
  ));
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  if (find.byType(LumoIntroSplash).evaluate().isNotEmpty) {
    await tester.tap(find.byType(LumoIntroSplash));
  }
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.takeException(), isNull);
}

Future<String> _tapLegalCard(WidgetTester tester) async {
  final hand = tester.widget<LumoPlayerHand>(find.byType(LumoPlayerHand));
  final card = hand.cards.firstWhere((card) => LumoCardsRules.isPlayable(
      card: card, topCard: hand.topCard, selectedColor: hand.selectedColor));
  final finder = find.byKey(ValueKey('hand-${card.id}'));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  return card.id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final folder =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final file = File('$folder/${entry.value}');
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('Audio sheet freezes the bot until explicit resume', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Ziehen'));
    await tester.pump();
    final before = _board(tester);
    await tester.tap(find.byTooltip('Ton einstellen'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(_clock(tester).value, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 5));
    expect(_board(tester), before);
    await tester.tap(find.text('Fertig'));
    await tester.pump(const Duration(milliseconds: 350));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(_clock(tester).value, isTrue);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump(const Duration(milliseconds: 1700));
    expect(_board(tester), isNot(before));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Pausing cancels an uncommitted flight across Fold resize',
      (tester) async {
    await _open(tester);
    final before = _board(tester);
    final originalHand = tester
        .widget<LumoPlayerHand>(find.byType(LumoPlayerHand))
        .cards
        .map((card) => card.id)
        .toList();
    await _tapLegalCard(tester);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LumoCardFly), findsOneWidget);
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.pump();
    expect(find.byType(LumoCardFly), findsNothing);
    for (final size in [
      const Size(720, 840),
      const Size(1024, 800),
      const Size(840, 400),
      const Size(360, 780),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_board(tester), before);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_board(tester), before);
    expect(
        tester.widget<LumoPlayerHand>(find.byType(LumoPlayerHand)).cards.map(
            (card) => card.id),
        originalHand);
    final played = await _tapLegalCard(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester.widget<LumoDiscardPile>(find.byType(LumoDiscardPile)).topCard.id,
        played);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reduced motion commits the legal card without a flight delay',
      (tester) async {
    await _open(tester, reduceMotion: true);
    final played = await _tapLegalCard(tester);
    await tester.pump();
    expect(find.byType(LumoCardFly), findsNothing);
    expect(
        tester.widget<LumoDiscardPile>(find.byType(LumoDiscardPile)).topCard.id,
        played);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Landscape avatar picker scrolls, saves and leaves the game paused',
      (tester) async {
    await _open(tester, size: const Size(840, 400));
    await tester.tap(find.byTooltip('Avatar wechseln'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(LumoAvatarPicker), findsOneWidget);
    expect(_clock(tester).value, isTrue);
    expect(tester.takeException(), isNull);
    final path = LumoCardsAssets.allPlayerAvatars.last;
    final choice = find.byKey(ValueKey('cards-avatar-$path'));
    await tester.ensureVisible(choice);
    await tester.pump();
    await tester.tap(choice);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(LumoAvatarPicker), findsNothing);
    expect(find.text('Spiel pausiert'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_cards_player_avatar'), path);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
