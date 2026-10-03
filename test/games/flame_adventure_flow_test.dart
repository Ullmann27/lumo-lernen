import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/flame/lumo_jump_game.dart';

class _BlockedWallet extends RewardWalletRepository {
  bool rejectWrites = true;
  final gate = Completer<void>();
  final transactions = <(int, int)>[];

  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0}) async {
    transactions.add((starsDelta, xpDelta));
    if (rejectWrites) throw StateError('Test storage temporarily unavailable');
    await gate.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }
}

Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

Future<LumoFlameJumpGame> _menuAndCollect(
    WidgetTester tester, LumoAppState app) async {
  await tester.binding.setSurfaceSize(const Size(800, 900));
  await app.hydrateFromWallet();
  await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
  await tester.pump();
  await tester.pump();
  final card = find.text('Lumos Jump Adventure · 2D');
  await tester.ensureVisible(card);
  await tester.pump();
  await tester.tap(card);
  await _frames(tester);
  expect(find.byType(LumoJumpFlameScreen), findsOneWidget);
  final game = tester
      .widget<GameWidget<LumoFlameJumpGame>>(
          find.byType(GameWidget<LumoFlameJumpGame>))
      .game!;
  await tester.runAsync(() => game.ready());
  await tester.pump();
  final joystick = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_VirtualJoystick');
  final stick = await tester.startGesture(
      tester.getRect(joystick).topLeft + const Offset(164, 100),
      pointer: 1);
  for (var frame = 0; frame < 240 && game.totalEarnedStars == 0; frame++) {
    await _frames(tester, 1);
  }
  await stick.up();
  await tester.pump();
  expect(game.totalEarnedStars, greaterThan(0),
      reason:
          'Only real joystick movement and collision physics may earn this reward');
  return game;
}

Future<void> _dispose(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf'
    }.entries) {
      final file = File('$fonts/${entry.value}');
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(
          Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  for (final exit in ['Android Back', 'X']) {
    testWidgets(
        '$exit preserves actual adventure collision reward after pause and return',
        (tester) async {
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      final game = await _menuAndCollect(tester, app);
      final earned = game.totalEarnedStars;
      await tester.binding.handlePopRoute();
      await _frames(tester);
      expect(find.text('Spiel verlassen?'), findsOneWidget);
      expect(game.paused, isTrue);
      final pausedPosition = game.fox.position.clone();
      await _frames(tester, 60);
      expect(game.fox.position, pausedPosition);
      await tester.tap(find.text('Weiterspielen'));
      await _frames(tester);
      expect(game.paused, isFalse);
      if (exit == 'Android Back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byIcon(Icons.close_rounded));
      }
      await _frames(tester);
      expect(find.text('Spiel verlassen?'), findsOneWidget);
      await tester.tap(find.text('Verlassen'));
      await _frames(tester);
      expect(find.byType(LumoJumpFlameScreen), findsNothing);
      expect(find.text('Lumos Jump Adventure · 2D'), findsOneWidget);
      final stored = await RewardWalletRepository().load();
      expect(stored.stars, earned);
      expect(stored.xp, earned * 2);
      final reloaded = LumoAppState(walletRepository: RewardWalletRepository());
      await reloaded.hydrateFromWallet();
      expect(reloaded.state.stars, earned);
      expect(reloaded.state.xp, earned * 2);
      reloaded.dispose();
      await _dispose(tester, app);
    });
  }

  testWidgets(
      'failed adventure storage stays open and retries once before returning',
      (tester) async {
    final repository = _BlockedWallet();
    final app = LumoAppState(walletRepository: repository);
    final game = await _menuAndCollect(tester, app);
    final earned = game.totalEarnedStars;
    await tester.binding.handlePopRoute();
    await _frames(tester);
    await tester.tap(find.text('Verlassen'));
    await _frames(tester);
    expect(find.byType(LumoJumpFlameScreen), findsOneWidget);
    expect(game.paused, isTrue);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(app.hasPendingRewards, isTrue);
    expect((await RewardWalletRepository().load()).stars, 0);
    repository.rejectWrites = false;
    final retry = tester.getCenter(find.text('Erneut versuchen'));
    await tester.tapAt(retry);
    await tester.tapAt(retry);
    await _frames(tester);
    expect(find.byType(LumoJumpFlameScreen), findsOneWidget,
        reason: 'The route must wait until the actual wallet write completes');
    repository.gate.complete();
    await _frames(tester);
    expect(find.byType(LumoJumpFlameScreen), findsNothing);
    final stored = await RewardWalletRepository().load();
    expect(stored.stars, earned);
    expect(stored.xp, earned * 2);
    expect(stored.totalEarnedStars, earned,
        reason: 'Rapid retry taps must never book a second reward');
    expect(repository.transactions, everyElement((earned, earned * 2)),
        reason: 'Stars and XP must be retried together in one wallet transaction');
    await _dispose(tester, app);
  });
}
