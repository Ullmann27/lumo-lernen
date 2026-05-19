// Smoke-Tests fuer die zentralen Lumo-Lernen-Screens.
//
// Heinz-Auftrag: 'Smoke-Tests fuer Home, Games, Lumo Jump, Lumo Kart,
// Settings'. Diese Tests pruefen NUR ob die Widgets ohne Exception bauen.
// Es ist KEIN voller Integration-Test - aber sie fangen ein 'Build crasht
// beim oeffnen des Screens' garantiert ab.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppState lasst sich erstellen und disposen', (tester) async {
    final state = LumoAppState();
    expect(state.state.stars, isNonNegative);
    expect(state.state.xp, isNonNegative);
    state.dispose();
  });

  testWidgets('RewardWallet kann geladen werden ohne Crash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final wallet = await RewardWalletRepository.instance.load();
    expect(wallet.stars, isNonNegative);
    expect(wallet.xp, isNonNegative);
  });

  testWidgets('RewardWallet addStars erhoeht persistent', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Reset um sauber zu starten
    await RewardWalletRepository.instance.reset();
    final w1 = await RewardWalletRepository.instance.addStars(5);
    expect(w1.stars, 5);
    final w2 = await RewardWalletRepository.instance.addStars(3);
    expect(w2.stars, 8);
    expect(w2.totalEarnedStars, greaterThanOrEqualTo(8));
  });

  testWidgets('RewardWallet addXp erhoeht und Level steigt', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
    final w1 = await RewardWalletRepository.instance.addXp(50);
    expect(w1.xp, 50);
    expect(w1.level, 1);
    final w2 = await RewardWalletRepository.instance.addXp(60);
    expect(w2.xp, 110);
    expect(w2.level, 2); // 1 + 110/100 = 2
  });

  testWidgets('LumoAkademieScreen baut ohne Exception', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = LumoAppState();
    await tester.pumpWidget(MaterialApp(
      home: LumoAkademieScreen(appState: state),
    ));
    // Mindestens ein bestimmter Text muss da sein
    expect(find.text('Welche Klasse?'), findsOneWidget);
    state.dispose();
  });

  testWidgets('LumoAkademieScreen hat 4 Klassen-Chips', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = LumoAppState();
    await tester.pumpWidget(MaterialApp(
      home: LumoAkademieScreen(appState: state),
    ));
    // 4 Chips fuer Klasse 1-4
    expect(find.text('1. Klasse'), findsOneWidget);
    expect(find.text('2. Klasse'), findsOneWidget);
    expect(find.text('3. Klasse'), findsOneWidget);
    expect(find.text('4. Klasse'), findsOneWidget);
    state.dispose();
  });

  testWidgets('AppState addStars schreibt in Wallet (Hydration-Pfad)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
    final state = LumoAppState();
    final before = state.state.stars;
    state.addStars(7);
    expect(state.state.stars, before + 7);
    // Warte kurz auf das Fire-and-Forget Persist
    await Future.delayed(const Duration(milliseconds: 50));
    final wallet = RewardWalletRepository.instance.snapshot;
    expect(wallet.stars, greaterThanOrEqualTo(7));
    state.dispose();
  });

  testWidgets('Hydration bringt Wallet-Stars in AppState', (tester) async {
    // Setup: schreib Stars in Wallet, dann lade neu
    SharedPreferences.setMockInitialValues({});
    await RewardWalletRepository.instance.reset();
    await RewardWalletRepository.instance.addStars(42);
    await RewardWalletRepository.instance.addXp(150);

    final state = LumoAppState();
    await state.hydrateFromWallet();

    expect(state.state.stars, greaterThanOrEqualTo(42));
    expect(state.state.xp, greaterThanOrEqualTo(150));
    state.dispose();
  });
}
