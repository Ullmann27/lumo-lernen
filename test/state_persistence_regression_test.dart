import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_shop_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'package:lumo_lernen/features/rewards/reward_shop_content.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';

class _DelayedWallet extends RewardWalletRepository {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<RewardWallet> load() async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return super.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Rewards arriving during wallet load remain visible and persisted',
    () async {
      final wallet = _DelayedWallet();
      final state = LumoAppState(walletRepository: wallet);
      final hydration = state.hydrateFromWallet();
      await wallet.started.future;
      state.correctAnswer('Plus', stars: 7, xp: 45);
      wallet.release.complete();
      await hydration;
      await state.flushRewards();
      expect(state.state.stars, 7);
      expect(state.state.xp, 45);
      final restarted = await RewardWalletRepository().load();
      expect(restarted.stars, 7);
      expect(restarted.xp, 45);
      state.dispose();
    },
  );

  test(
    'Profile reset drains pending rewards and clears the cached wallet',
    () async {
      final wallet = RewardWalletRepository();
      await wallet.addStars(40);
      await wallet.addXp(400);
      final state = LumoAppState(walletRepository: wallet);
      await state.hydrateFromWallet();
      state.correctAnswer('Plus', stars: 7, xp: 45);
      final reset = state.resetAllProfile();
      state.addStars(100); // Old screen callbacks during reset must be ignored.
      await reset;
      expect(state.state.stars, 0);
      expect(state.state.xp, 0);
      expect(state.settingsLoaded, isTrue);
      state.addStars(1);
      await state.flushRewards();
      expect(wallet.snapshot.stars, 1);
      expect(wallet.snapshot.xp, 0);
      final restarted = await RewardWalletRepository().load();
      expect(restarted.stars, 1);
      expect(restarted.xp, 0);
      state.dispose();
    },
  );

  test('A reset invalidates an older hydration waiting on disk', () async {
    SharedPreferences.setMockInitialValues({
      'lumo_reward_wallet_v1': jsonEncode(
        const RewardWallet(stars: 80).toJson(),
      ),
    });
    final wallet = _DelayedWallet();
    final state = LumoAppState(walletRepository: wallet);
    final hydration = state.hydrateFromWallet();
    await wallet.started.future;
    final reset = state.resetAllProfile();
    wallet.release.complete();
    await reset;
    await hydration;
    expect(state.state.stars, 0);
    expect(wallet.snapshot.stars, 0);
    state.dispose();
  });

  test('Legacy shop stars migrate once for the active child', () async {
    SharedPreferences.setMockInitialValues({
      'lumo_active_profile': jsonEncode({'name': 'Alina', 'grade': 2}),
      'lumo_legacy_stars': 12,
      'lumo.reward_shop.local_alina_2': jsonEncode(
        const RewardShopState(availableStars: 40).toJson(),
      ),
      'lumo.reward_shop.local_other_2': jsonEncode(
        const RewardShopState(availableStars: 900).toJson(),
      ),
    });
    final wallet = RewardWalletRepository();
    expect((await wallet.load()).stars, 40);
    await wallet.addStars(-40);
    // A real saved zero takes precedence over the now stale legacy shop.
    expect((await RewardWalletRepository().load()).stars, 0);
  });

  testWidgets('Opening the shop keeps legacy stars and the other shop fields', (
    tester,
  ) async {
    const repo = RewardShopRepository();
    await repo.save(
      'local_lena_1',
      const RewardShopState(
        availableStars: 40,
        availablePoints: 25,
        goalItemId: 'goal',
      ),
    );
    final state = LumoAppState(walletRepository: RewardWalletRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RewardShopContent(appState: state)),
      ),
    );
    await tester.pumpAndSettle();
    final saved = await repo.load('local_lena_1');
    expect(state.state.stars, 40);
    expect(saved.availableStars, 40);
    expect(saved.availablePoints, 25);
    expect(saved.goalItemId, 'goal');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
      'A settings deep link opens without a code and uses saved permissions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(
        {
          ...const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            aiProxyEnabled: false,
          ).toJson(),
          'parentPin': '7291',
          'parentPinConfigured': true
        },
      ),
    });
    await RewardWalletRepository.instance.reset();
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialSection: LumoSection.settings)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SettingsContent), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('PIN'), findsNothing);
    final settings =
        tester.widget<SettingsContent>(find.byType(SettingsContent));
    expect(settings.appState.settingsLoaded, isTrue);
    expect(settings.appState.state.settings.voiceEnabled, isFalse);
    for (final size in [
      const Size(360, 740),
      const Size(840, 720),
      const Size(280, 640),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'Settings at $size');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    expect(tester.takeException(), isNull);
  });
}
