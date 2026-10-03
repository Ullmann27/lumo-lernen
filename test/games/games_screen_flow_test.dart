import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';
import 'package:lumo_lernen/features/games/dice_race/lumo_dice_race_game.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_player_hand.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_color_picker.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_learning_card_overlay.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_result_dialog.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_playing_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets(
      'Cards outer/inner Fold layouts, full touch game, result, replay, back',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: Center(
                      child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute<void>(
                                builder: (_) =>
                                    LumoCardsScreen(appState: app, seed: 10)));
                          },
                          child: const Text('Spielauswahl'))),
                ))));
    await tester.tap(find.text('Spielauswahl'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    if (find.byType(LumoIntroSplash).evaluate().isNotEmpty) {
      await tester.tap(find.byType(LumoIntroSplash));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(720, 840));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(360, 780));
    await tester.pump();
    var moves = 0;
    while (find.byType(LumoResultDialog).evaluate().isEmpty && moves < 1000) {
      if (find.byType(LumoColorPicker).evaluate().isNotEmpty) {
        await tester.tap(find.descendant(
            of: find.byType(LumoColorPicker), matching: find.text('Rot')));
      } else if (find.byType(LumoLearningCardOverlay).evaluate().isNotEmpty) {
        final overlay = tester.widget<LumoLearningCardOverlay>(
            find.byType(LumoLearningCardOverlay));
        await tester.tap(find.descendant(
            of: find.byType(LumoLearningCardOverlay),
            matching: find.text(
                overlay.question.options[overlay.question.correctIndex])));
      } else if (find.byType(LumoPlayerHand).evaluate().isNotEmpty) {
        final hand = tester.widget<LumoPlayerHand>(find.byType(LumoPlayerHand));
        final playable = hand.cards.where((card) => LumoCardsRules.isPlayable(
            card: card,
            topCard: hand.topCard,
            selectedColor: hand.selectedColor));
        if (playable.isEmpty) {
          await tester.tap(find.text('Ziehen'));
        } else {
          final card = find.byKey(ValueKey('hand-${playable.first.id}'));
          await tester.ensureVisible(card);
          await tester.pump();
          final rendered = tester.widget<LumoPlayingCard>(find.descendant(
              of: card, matching: find.byType(LumoPlayingCard)));
          final accessible = find.bySemanticsLabel(rendered.semanticLabel);
          expect(accessible, findsWidgets);
          await tester.tap(accessible.first);
        }
      }
      await tester.pump(const Duration(milliseconds: 1700));
      expect(tester.takeException(), isNull,
          reason: 'Move $moves must render without overflow');
      moves++;
    }
    expect(find.byType(LumoResultDialog), findsOneWidget,
        reason: 'The actual Cards UI must complete a game');
    expect(app.state.stars, greaterThanOrEqualTo(1));
    await app.flushRewards();
    expect((await RewardWalletRepository().load()).stars, app.state.stars);
    final rewards = app.state.stars;
    await tester.tap(find.text('Nochmal'));
    await tester.pump();
    expect(find.byType(LumoResultDialog), findsNothing);
    expect(
        tester.widget<LumoPlayerHand>(find.byType(LumoPlayerHand)).cards.length,
        7);
    expect(app.state.stars, rewards);
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.pump();
    expect(find.text('Spiel pausiert'), findsOneWidget);
    await tester.tap(find.text('Zur Spieleauswahl'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Spielauswahl'), findsOneWidget);
    expect(Navigator.of(tester.element(find.text('Spielauswahl'))).canPop(),
        isFalse);
    expect(find.byType(LumoCardsScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    app.dispose();
  });
  testWidgets(
      'Four in a row completes a full touch game and restart cancels old bot',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    await tester.pumpWidget(
        MaterialApp(home: LumoConnectFourScreen(appState: app, seed: 1)));
    await tester.pump();
    var turns = 0;
    while (find.byType(AlertDialog).evaluate().isEmpty && turns < 60) {
      final buttons = [
        for (var c = 0; c < 7; c++) find.byKey(ValueKey('connect-column-$c'))
      ];
      final enabled =
          buttons.where((f) => tester.widget<IconButton>(f).onPressed != null);
      expect(enabled, isNotEmpty);
      await tester.tap(enabled.first);
      await tester.pump(const Duration(milliseconds: 1000));
      turns++;
    }
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(app.state.stars, greaterThanOrEqualTo(2));
    await app.flushRewards();
    expect((await RewardWalletRepository().load()).stars, app.state.stars);
    await tester.tap(find.text('Nochmal!'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-column-0')));
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.pump();
    await tester.tap(find.text('Neu starten'));
    await tester.pump(const Duration(seconds: 4));
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('connect-column-0')))
            .onPressed,
        isNotNull);
    expect(find.text('Lumo denkt... 🦊'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets(
      'Dice full touch game, saved result, restart and pause during rolling',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    await tester.pumpWidget(
        MaterialApp(home: LumoDiceRaceScreen(appState: app, seed: 7)));
    await tester.pump();
    var turns = 0;
    while (find.byType(AlertDialog).evaluate().isEmpty && turns < 120) {
      await tester.tap(find.byKey(const ValueKey('dice-roll')));
      await tester.pump(const Duration(milliseconds: 3500));
      turns++;
    }
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(app.state.stars, greaterThanOrEqualTo(2));
    await app.flushRewards();
    expect((await RewardWalletRepository().load()).stars, app.state.stars);
    await tester.tap(find.text('Nochmal!'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dice-roll')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(find.text('0 / 30'), findsNWidgets(2));
    await tester.tap(find.text('Neu starten'));
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('0 / 30'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
