import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:lumo_lernen/features/lumo3d/native_table_transport.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnavailableTable implements NativeTableTransport {
  bool closed = false;

  @override
  Future<void> open(String token, Map<String, Object?> state) async {
    throw MissingPluginException('The widget test exercises the real fallback');
  }

  @override
  Future<Map<String, dynamic>> poll(String token) async => {};

  @override
  Future<void> publish(String token, Map<String, Object?> state) async {}

  @override
  Future<void> close(String token) async {
    closed = true;
  }
}

class _HeldMemoryAward extends LumoAppState {
  _HeldMemoryAward() : super(walletRepository: RewardWalletRepository());

  final entered = Completer<void>();
  final confirmed = Completer<void>();
  int awardCalls = 0;

  @override
  Future<void> recordMemoryResult({
    required LearningProfileLease lease,
    required String resultId,
    required String difficulty,
    required int kindPairs,
    required int lumoPairs,
  }) async {
    awardCalls++;
    if (!entered.isCompleted) entered.complete();
    await confirmed.future;
    // Only the timing boundary is controlled. Validation, the real reward
    // formula, owner lease and durable wallet write remain production code.
    await super.recordMemoryResult(
      lease: lease,
      resultId: resultId,
      difficulty: difficulty,
      kindPairs: kindPairs,
      lumoPairs: lumoPairs,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Memory result waits for durable reward then appears in the next frame',
      (tester) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final app = _HeldMemoryAward();
      final transport = _UnavailableTable();
      addTearDown(() {
        if (!app.confirmed.isCompleted) app.confirmed.complete();
        app.dispose();
      });
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      app.updateSettings(const AppSettings(
        voiceEnabled: false, soundEnabled: false, reduceAnimations: true,
      ));
      await app.school.setActiveStudent('memory-result-frame-child');
      await app.hydrateFromWallet();
      final lease = await app.captureLearningProfile();
      final owner = sha256.convert(utf8.encode(lease.studentId));
      final key = 'lumo.memory.round.v1.$owner';
      final preferences = await SharedPreferences.getInstance();
      Map<String, dynamic> savedRound() =>
          jsonDecode(preferences.getString(key)!) as Map<String, dynamic>;

      await tester.pumpWidget(MaterialApp(home: LumoMemoryScreen(
        appState: app, seed: 4, difficulty: MemoryDifficulty.leicht,
        nativeTransport: transport,
      )));
      for (var i = 0; i < 50 && !transport.closed; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(transport.closed, true, reason: 'Actual automatic fallback has finished');
      expect(find.byKey(const ValueKey('memory-card-7')).hitTestable(), findsOneWidget);
      final firstRound = savedRound()['id'];
      final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
      for (final motif in deck.toSet()) {
        for (var index = 0; index < deck.length; index++) {
          if (deck[index] != motif) continue;
          await tester.tap(find.byKey(ValueKey('memory-card-$index')));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 900));
      }

      expect(app.entered.isCompleted, true);
      expect(app.confirmed.isCompleted, false);
      expect(app.awardCalls, 1);
      final waiting = savedRound();
      expect((waiting['rules'] as Map)['phase'], 'complete');
      expect((waiting['rules'] as Map)['kindPairs'], 4);
      expect(waiting['rewarded'], false);
      expect(app.state.stars, 0);
      expect(find.text('Du hast gewonnen!'), findsNothing,
          reason: 'A complete board is not a confirmed durable reward');

      app.confirmed.complete();
      // One real frame must include the completed action's result route.
      // No pumpAndSettle or extra frame hides a post-frame navigation delay.
      await tester.pump();
      expect(savedRound()['rewarded'], true);
      expect(find.text('Du hast gewonnen!'), findsOneWidget);
      expect(find.text('Du: 4 Paare    Lumo: 0 Paare'), findsOneWidget);
      expect(app.state.stars, 2);
      await app.flushRewards();
      expect((await RewardWalletRepository().load()).stars, 2);
      await tester.tap(find.text('Nochmal!'));
      await tester.pump();
      expect(savedRound()['id'], isNot(firstRound));
      expect((savedRound()['rules'] as Map)['phase'], 'select');
      expect((savedRound()['rules'] as Map)['faceUp'], everyElement(false));
      expect(app.awardCalls, 1);
      expect(app.state.stars, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      // Flutter checks this invariant before the external tearDown callbacks.
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}
