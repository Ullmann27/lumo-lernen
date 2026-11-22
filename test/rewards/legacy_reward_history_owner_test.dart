import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_shop_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'package:lumo_lernen/features/rewards/reward_shop_content.dart';
import 'package:lumo_lernen/widgets/profile_screen.dart';

const _a = 'history-child-a';
const _b = 'history-child-b';
const _legacyKey = 'lumo.reward_shop.local_lena_1';
const _walletKey = 'lumo_reward_wallet_v1';
const _legacyTitle = 'Lenas früherer Gutschein';
const _aTitle = 'Gutschein für Kind A';
const _bTitle = 'Gutschein für Kind B';

RewardShopRedemption _receipt(String owner, String title, String id) =>
    RewardShopRepository.createRedemption(
        ownerId: owner,
        item: CustomRewardDefinition(
                id: 'custom_$id',
                revision: 1,
                title: title,
                emoji: '🎁',
                cost: 50,
                category: CustomRewardCategory.family)
            .item);

Future<void> _frames(WidgetTester tester, [int count = 25]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _visibleHistory(
    WidgetTester tester, String expected, Iterable<String> absent) async {
  final visible = find.text(expected);
  if (visible.evaluate().isEmpty) {
    await tester.scrollUntilVisible(visible, 240,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
  }
  await Scrollable.ensureVisible(tester.element(visible), alignment: .5);
  await _frames(tester, 5);
  expect(visible, findsOneWidget);
  final viewport = tester.getRect(find.byType(Scrollable).first);
  expect(viewport.contains(tester.getCenter(visible)), isTrue);
  for (final title in absent) {
    expect(find.text(title), findsNothing);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final profileScreen in [false, true]) {
    testWidgets(
        '${profileScreen ? 'Profile' : 'Shop'} shows legacy history only for Self across A/B/Self/A without modifying stored data',
        (tester) async {
      WidgetController.hitTestWarningShouldBeFatal = true;
      await tester.binding.setSurfaceSize(const Size(600, 1100));
      final legacy = RewardShopState(
          availableStars: 40,
          availablePoints: 25,
          goalItemId: 'sticker_aussuchen',
          redeemed: [
            RedeemedReward(
                itemId: 'legacy-ticket',
                title: _legacyTitle,
                redeemedAt: DateTime.utc(2026, 11, 21),
                cost: 80,
                currency: RewardCurrency.stars)
          ]);
      final wallet = RewardWallet(
          stars: 200,
          xp: 800,
          level: 3,
          totalEarnedStars: 500,
          shopRedemptions: [
            _receipt(_a, _aTitle, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
            _receipt(_b, _bTitle, 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'),
          ]);
      final legacyRaw = jsonEncode(legacy.toJson());
      final walletRaw = jsonEncode(wallet.toJson());
      SharedPreferences.setMockInitialValues(
          {_legacyKey: legacyRaw, _walletKey: walletRaw});
      late LumoAppState app;
      try {
        await tester.runAsync(() async {
          app = LumoAppState(walletRepository: RewardWalletRepository());
          await app.school.setActiveStudent(_a);
          await app.hydrateFromWallet();
          app.updateSettings(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              reduceAnimations: true,
              calmMode: true));
        });
        final child = profileScreen
            ? ProfileScreen(
                appState: app,
                onSection: (_) {},
                childName: 'Lena',
                grade: 1,
                stars: app.state.stars,
                xp: app.state.xp,
                level: app.state.level)
            : RewardShopContent(appState: app);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
        await _frames(tester);
        await _visibleHistory(tester, _aTitle, [_legacyTitle, _bTitle]);
        await tester.runAsync(() => app.school.setActiveStudent(_b));
        await _frames(tester);
        await _visibleHistory(tester, _bTitle, [_legacyTitle, _aTitle]);
        await tester.runAsync(() => app.school.setActiveStudent(null));
        await _frames(tester);
        await _visibleHistory(tester, _legacyTitle, [_aTitle, _bTitle]);
        await tester.runAsync(() => app.school.setActiveStudent(_a));
        await _frames(tester);
        await _visibleHistory(tester, _aTitle, [_legacyTitle, _bTitle]);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(_legacyKey), legacyRaw,
            reason:
                'Hiding unowned history does not delete or migrate the old file.');
        expect(prefs.getString(_walletKey), walletRaw,
            reason:
                'Reading history neither spends stars nor changes receipts.');
        expect(app.state.stars, 200);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
        await tester.binding.setSurfaceSize(null);
      }
    });
  }
}
