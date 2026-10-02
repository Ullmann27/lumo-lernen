// Smoke-Tests fuer die zentralen Lumo-Lernen-Screens.
//
// Heinz-Auftrag: 'Smoke-Tests fuer Home, Games, Lumo Jump, Lumo Kart,
// Settings'. Diese Tests pruefen ob die Widgets ohne Exception bauen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
  });

  test('AppState lasst sich erstellen und disposen', () async {
    final state = LumoAppState();
    expect(state.state.stars, isNonNegative);
    expect(state.state.xp, isNonNegative);
    await state.flushRewards();
    state.dispose();
  });

  test('RewardWallet kann geladen werden ohne Crash', () async {
    final wallet = await RewardWalletRepository.instance.load();
    expect(wallet.stars, isNonNegative);
    expect(wallet.xp, isNonNegative);
  });

  test('RewardWallet addStars erhoeht persistent', () async {
    final w1 = await RewardWalletRepository.instance.addStars(5);
    expect(w1.stars, 5);
    final w2 = await RewardWalletRepository.instance.addStars(3);
    expect(w2.stars, 8);
    expect(w2.totalEarnedStars, greaterThanOrEqualTo(8));
  });

  test('RewardWallet addXp erhoeht und Level steigt', () async {
    final w1 = await RewardWalletRepository.instance.addXp(50);
    expect(w1.xp, 50);
    expect(w1.level, 1);
    final w2 = await RewardWalletRepository.instance.addXp(60);
    expect(w2.xp, 110);
    expect(w2.level, 1);
    final w3 = await RewardWalletRepository.instance.addXp(300);
    expect(w3.level, 2);
  });

  testWidgets(
    'LumoAkademieScreen baut ohne harten Crash',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      final state = LumoAppState();
      await tester.pumpWidget(
        MaterialApp(home: LumoAkademieScreen(appState: state)),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LumoAkademieScreen), findsOneWidget);
      await tester.runAsync(state.flushRewards);
      state.dispose();
      await tester.binding.setSurfaceSize(null);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

  testWidgets(
    'LumoAkademieScreen hat 4 Klassen-Chips im Widget-Tree',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      final state = LumoAppState();
      await tester.pumpWidget(
        MaterialApp(home: LumoAkademieScreen(appState: state)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('1. Klasse'), findsOneWidget);
      expect(find.text('2. Klasse'), findsOneWidget);
      expect(find.text('3. Klasse'), findsOneWidget);
      expect(find.text('4. Klasse'), findsOneWidget);
      await tester.runAsync(state.flushRewards);
      state.dispose();
      await tester.binding.setSurfaceSize(null);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

  test('AppState addStars erhoeht den State', () async {
    final state = LumoAppState();
    final before = state.state.stars;
    state.addStars(7);
    expect(state.state.stars, before + 7);
    await state.flushRewards();
    state.dispose();
  });

  test('AppState addXp erhoeht den State', () async {
    final state = LumoAppState();
    final before = state.state.xp;
    state.addXp(25);
    expect(state.state.xp, before + 25);
    await state.flushRewards();
    state.dispose();
  });

  test('Hydration aus voller Wallet bringt Werte zurueck', () async {
    await RewardWalletRepository.instance.addStars(42);
    await RewardWalletRepository.instance.addXp(150);
    final state = LumoAppState();
    await state.hydrateFromWallet();
    expect(state.state.stars, greaterThanOrEqualTo(42));
    expect(state.state.xp, greaterThanOrEqualTo(150));
    await state.flushRewards();
    state.dispose();
  });
}
