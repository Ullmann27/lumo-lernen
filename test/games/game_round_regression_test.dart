import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';

Finder _memoryBacks() => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('memory-back-'));

List<LumoCard> _allCards(LumoCardsGameState state) => [
      ...state.players.expand((p) => p.hand),
      ...state.drawPile,
      ...state.discardPile,
    ];

void _checkDeck(LumoCardsGameState state, Set<String> expected) {
  final cards = _allCards(state);
  expect(cards.map((c) => c.id).toSet(), expected);
  expect(cards.length, expected.length, reason: 'No card may exist twice');
}

LumoCard _number(String id, int n) => LumoCard(
      id: id,
      color: LumoCardColor.orange,
      type: LumoCardType.number,
      number: n,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoSound.instance.muted = true;
  });

  test('Recycling keeps exactly one copy and the newly played penalty on top',
      () {
    final older = _number('older', 3);
    final top = _number('top', 5);
    final penalty = LumoCard(
        id: 'rain', color: LumoCardColor.orange, type: LumoCardType.starRain);
    final state = LumoCardsGameState(
      players: [
        LumoPlayer(id: 'a', name: 'A', hand: [penalty, _number('held', 6)]),
        LumoPlayer(id: 'b', name: 'B', hand: [_number('opponent', 8)]),
      ],
      currentPlayerIndex: 0,
      drawPile: [],
      discardPile: [older, top],
      selectedColor: top.color,
      phase: GamePhase.playing,
    );
    final next =
        LumoCardsRules.applyPlay(state: state, card: penalty, rng: Random(4));
    _checkDeck(next, _allCards(state).map((c) => c.id).toSet());
    expect(next.topCard, penalty);
    expect(next.discardPile, [penalty]);
    expect(next.players[1].hand.length, 3);
    // An old callback or a fabricated card must not get into the game.
    expect(LumoCardsRules.applyPlay(state: state, card: _number('foreign', 2)),
        same(state));
    final drawn = LumoCardsRules.applyDraw(state: state, rng: Random(5));
    _checkDeck(drawn, _allCards(state).map((c) => c.id).toSet());
    expect(drawn.topCard, top);
    expect(drawn.discardPile, [top]);
  });

  testWidgets(
      '16 complete solo Cards rounds handle bot color and learning phases',
      (tester) async {
    final botPhases = <GamePhase>{};
    for (var seed = 0; seed < 16; seed++) {
      final controller = LumoCardsGameController(
        player1Name: 'Du',
        player2Name: 'Lumo',
        seed: seed,
        grade: seed % 4 + 1,
        enableVoice: false,
      );
      final expected = _allCards(controller.state).map((c) => c.id).toSet();
      controller.addListener(() {
        if (controller.state.currentPlayerIndex == 1) {
          botPhases.add(controller.state.phase);
        }
      });
      var moves = 0;
      while (controller.state.phase != GamePhase.gameOver && moves < 3000) {
        _checkDeck(controller.state, expected);
        final s = controller.state;
        if (s.currentPlayerIndex == 1) {
          await tester.pump(const Duration(milliseconds: 1700));
        } else {
          switch (s.phase) {
            case GamePhase.playing:
              final playable = s.currentPlayer.hand.where((c) =>
                  LumoCardsRules.isPlayable(
                      card: c,
                      topCard: s.topCard!,
                      selectedColor: s.selectedColor));
              if (playable.isEmpty) {
                controller.drawCard();
              } else {
                controller.playCard(playable.first);
              }
            case GamePhase.chooseColor:
              controller.selectColor(LumoCardColor.orange);
            case GamePhase.learningQuestion:
              final unchanged = controller.state;
              controller.answerLearningQuestion(-1);
              expect(controller.state, same(unchanged));
              controller.answerLearningQuestion(
                  s.pendingLearningQuestion!.correctIndex);
            case GamePhase.passDevice:
              controller.confirmHandover();
            case GamePhase.gameOver:
              break;
          }
        }
        moves++;
      }
      expect(controller.state.phase, GamePhase.gameOver,
          reason: 'Seed $seed must reach a result rather than hang');
      _checkDeck(controller.state, expected);
      expect(controller.state.players[controller.state.winnerIndex!].hand,
          isEmpty);
      controller.restart();
      expect(controller.state.phase, GamePhase.playing);
      expect(controller.state.players[0].hand.length, 7);
      expect(controller.state.players[1].hand.length, 7);
      controller.dispose();
    }
    expect(botPhases,
        containsAll([GamePhase.chooseColor, GamePhase.learningQuestion]));
  });

  testWidgets('Cards bot waits on pause; restart cancels the pending old turn',
      (tester) async {
    final controller = LumoCardsGameController(
        player1Name: 'Du', player2Name: 'Lumo', seed: 20, enableVoice: false);
    controller.drawCard(); // pass to Lumo, timer is now armed
    expect(controller.state.currentPlayerIndex, 1);
    controller.turnClock.pause();
    final paused = controller.state;
    await tester.pump(const Duration(seconds: 8));
    expect(controller.state, same(paused));
    controller.turnClock.resume();
    await tester.pump(const Duration(milliseconds: 1700));
    expect(controller.state, isNot(same(paused)));
    controller.restart();
    final restarted = controller.state;
    await tester.pump(const Duration(seconds: 8));
    expect(controller.state, same(restarted));
    controller.dispose();
  });

  testWidgets(
      'Memory complete 12-pair game rewards once, persists, and restarts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    await app.hydrateFromWallet();
    final deck = MemoryBoard.deal(MemoryDifficulty.profi, Random(9));
    final symbols = deck.toSet().toList();
    await tester.pumpWidget(MaterialApp(
        home: LumoMemoryScreen(
            appState: app, seed: 9, difficulty: MemoryDifficulty.profi)));
    await tester.pump();
    for (final symbol in symbols) {
      final indices = [
        for (var i = 0; i < deck.length; i++)
          if (deck[i] == symbol) i
      ];
      expect(indices.length, 2);
      for (final index in indices) {
        await tester.tap(find.byKey(ValueKey('memory-card-$index')));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 900));
    }
    expect(find.text('Du hast gewonnen!'), findsOneWidget);
    expect(find.text('Du: 12 Paare    Lumo: 0 Paare'), findsOneWidget);
    expect(app.state.stars, 5);
    await app.flushRewards();
    expect((await RewardWalletRepository().load()).stars, 5);
    await tester.tap(find.text('Nochmal!'));
    await tester.pump();
    expect(_memoryBacks(), findsNWidgets(24));
    expect(app.state.stars, 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets(
      'Memory Fold resize and restart during a mismatch cancel old actions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    await tester.pumpWidget(MaterialApp(
        home: LumoMemoryScreen(
            appState: app, seed: 9, difficulty: MemoryDifficulty.profi)));
    await tester.pump();
    // Seed 9: find two different symbols rather than depending on chance.
    final deck = MemoryBoard.deal(MemoryDifficulty.profi, Random(9));
    final other = deck.indexWhere((s) => s != deck.first);
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(ValueKey('memory-card-$other')));
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Spiel pausiert'), findsOneWidget);
    await tester.tap(find.text('Neu starten'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(_memoryBacks(), findsNWidgets(24),
        reason: 'Old mismatch/bot cannot open new board');
    await tester.binding.setSurfaceSize(const Size(720, 840));
    await tester.pump();
    expect(find.byKey(const ValueKey('memory-card-23')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
  testWidgets(
      'Android back and background pause preserve an unfinished Memory turn',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await tester.pumpWidget(MaterialApp(
        home: LumoMemoryScreen(
            appState: app, seed: 9, difficulty: MemoryDifficulty.profi)));
    await tester.pump();
    final deck = MemoryBoard.deal(MemoryDifficulty.profi, Random(9));
    final other = deck.indexWhere((s) => s != deck.first);
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(ValueKey('memory-card-$other')));
    await tester.pump(const Duration(milliseconds: 900)); // now Lumo thinks
    await tester.pump(const Duration(milliseconds: 450)); // cards flipped back
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 8));
    expect(_memoryBacks(), findsNWidgets(24));
    expect(find.text('Spiel pausiert'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600)); // flip finishes
    expect(_memoryBacks(), findsNWidgets(23)); // only bot's first card is open
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Spiel pausiert'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
