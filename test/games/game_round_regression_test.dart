import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';

Finder _memoryBacks() => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('memory-back-'));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoSound.instance.muted = true;
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
