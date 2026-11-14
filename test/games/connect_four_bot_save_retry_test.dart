import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

/// The production widget, controller and preferences repository stay real.
/// Only a platform write is rejected before persistence. Native optimistic
/// cache durability is a separate contract, not claimed by these UI tests.
class _HeldReward {
  final entered = Completer<void>();
  final release = Completer<void>();
}

class _RejectedMovePlatform extends InMemorySharedPreferencesStore {
  _RejectedMovePlatform() : super.withData({});

  bool rejectSecondMove = true;
  int rejectedMoves = 0;
  bool rejectRewards = false;
  int rejectedRewards = 0;
  _HeldReward? nextRewardGate;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (rejectSecondMove &&
        key.startsWith('flutter.lumo.connect_four.round.v1.') &&
        value is String) {
      final document = jsonDecode(value) as Map<String, dynamic>;
      if ((document['columns'] as List).length == 2) {
        rejectedMoves++;
        return false;
      }
    }
    if (key == 'flutter.lumo_reward_wallet_v1' && value is String) {
      final document = jsonDecode(value) as Map<String, dynamic>;
      final ids = document['gameResultIds'] as List? ?? const [];
      if (ids.any((id) => id is String && id.startsWith('c4:'))) {
        if (rejectRewards) {
          rejectedRewards++;
          return false;
        }
        final gate = nextRewardGate;
        nextRewardGate = null;
        if (gate != null) {
          gate.entered.complete();
          await gate.release.future;
        }
      }
    }
    return super.setValue(valueType, key, value);
  }
}

int _pieces(WidgetTester tester, String player) => find
    .byWidgetPredicate((widget) =>
        widget is Semantics &&
        (widget.properties.label?.startsWith('Reihe ') ?? false) &&
        (widget.properties.label?.endsWith(': $player') ?? false))
    .evaluate()
    .length;

Future<({LumoAppState app, _RejectedMovePlatform platform})> _open(
    WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final platform = _RejectedMovePlatform();
  SharedPreferencesStorePlatform.instance = platform;
  LumoVoice.instance.isEnabled = false;
  await tester.binding.setSurfaceSize(const Size(360, 800));
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  await app.hydrateFromWallet();
  LumoVoice.instance.isEnabled = false;
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: LumoConnectFourScreen(appState: app, seed: 1),
  ));
  await tester.pumpAndSettle();
  return (app: app, platform: platform);
}

Future<void> _failedBotMove(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('connect-column-0')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
  expect(find.text('Spiel pausiert'), findsOneWidget);
  expect(_pieces(tester, 'child'), 1);
  expect(_pieces(tester, 'lumo'), 0);
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox());
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  SharedPreferences.setMockInitialValues({});
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('lumo_lernen/connect_four'),
      (_) async => throw MissingPluginException('Real Flutter fallback fixture'),
    );
  });

  testWidgets('Failed bot save retries once after the child resumes',
      (tester) async {
    final fixture = await _open(tester);
    await _failedBotMove(tester);
    expect(fixture.platform.rejectedMoves, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(_pieces(tester, 'lumo'), 0);
    expect(fixture.platform.rejectedMoves, 1);

    fixture.platform.rejectSecondMove = false;
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(_pieces(tester, 'child'), 1);
    expect(_pieces(tester, 'lumo'), 1);
    expect(find.text('Spiel pausiert'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(_pieces(tester, 'lumo'), 1);
    expect(fixture.app.state.stars, 0);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets('Repeated bot save failure remains paused until explicit retry',
      (tester) async {
    final fixture = await _open(tester);
    await _failedBotMove(tester);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(fixture.platform.rejectedMoves, 2);
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(_pieces(tester, 'lumo'), 0);
    await tester.pump(const Duration(seconds: 5));
    expect(fixture.platform.rejectedMoves, 2);

    fixture.platform.rejectSecondMove = false;
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(_pieces(tester, 'lumo'), 1);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets('Restart cancels the queued failed bot retry for the old round',
      (tester) async {
    final fixture = await _open(tester);
    await _failedBotMove(tester);
    fixture.platform.rejectSecondMove = false;
    await tester.tap(find.text('Neu starten'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(_pieces(tester, 'child'), 0);
    expect(_pieces(tester, 'lumo'), 0);
    expect(fixture.app.state.stars, 0);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets('Failed local Gold move never schedules an automatic bot',
      (tester) async {
    final fixture = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-column-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-column-1')));
    await tester.pump();
    expect(fixture.platform.rejectedMoves, 1);
    expect(find.text('Spiel pausiert'), findsOneWidget);
    fixture.platform.rejectSecondMove = false;
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(_pieces(tester, 'child'), 1);
    expect(_pieces(tester, 'lumo'), 0);

    await tester.tap(find.byKey(const ValueKey('connect-column-1')));
    await tester.pump();
    expect(_pieces(tester, 'lumo'), 1);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets('A saved winning move retries only its unconfirmed reward',
      (tester) async {
    final fixture = await _open(tester);
    fixture.platform.rejectSecondMove = false;
    fixture.platform.rejectRewards = true;
    await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
    await tester.pump();
    for (final column in [0, 6, 1, 6, 2, 5, 3]) {
      await tester.tap(find.byKey(ValueKey('connect-column-$column')));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
    }
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(_pieces(tester, 'child'), 4);
    expect(_pieces(tester, 'lumo'), 3);
    expect(fixture.app.state.stars, 0);
    expect(fixture.platform.rejectedRewards, 1);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(fixture.platform.rejectedRewards, 1);

    fixture.platform.rejectRewards = false;
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(fixture.app.state.stars, 5);
    expect(_pieces(tester, 'child'), 4);
    expect(_pieces(tester, 'lumo'), 3);
    await tester.pump(const Duration(seconds: 5));
    expect(fixture.app.state.stars, 5);
    expect(tester.takeException(), isNull);
    await _close(tester, fixture.app);
  });

  testWidgets('Lifecycle pause during reward retry defers the settled result',
      (tester) async {
    final fixture = await _open(tester);
    final held = _HeldReward();
    try {
      fixture.platform.rejectSecondMove = false;
      fixture.platform.rejectRewards = true;
      await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
      await tester.pump();
      for (final column in [0, 6, 1, 6, 2, 5, 3]) {
        await tester.tap(find.byKey(ValueKey('connect-column-$column')));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
      }
      expect(find.text('Spiel pausiert'), findsOneWidget);
      fixture.platform.rejectRewards = false;
      fixture.platform.nextRewardGate = held;
      await tester.tap(find.text('Fortsetzen'));
      // The resumed production clock queues a zero-delay Timer. Advance fake
      // time so the test reaches the held platform ACK before sending inactive.
      await tester.pump(const Duration(milliseconds: 1));
      expect(held.entered.isCompleted, isTrue);
      expect(held.release.isCompleted, isFalse);
      expect(fixture.app.state.stars, 0);
      expect(find.byType(AlertDialog), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Spiel pausiert'), findsOneWidget);
      held.release.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2500));
      expect(fixture.app.state.stars, 5);
      expect(find.byType(AlertDialog), findsNothing);
      expect(_pieces(tester, 'child'), 4);
      expect(_pieces(tester, 'lumo'), 3);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Spiel pausiert'), findsOneWidget);
      await tester.tap(find.text('Fortsetzen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(fixture.app.state.stars, 5);
      expect(tester.takeException(), isNull);
    } finally {
      if (!held.release.isCompleted) held.release.complete();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.idle();
      await _close(tester, fixture.app);
      await tester.idle();
    }
  });
}
