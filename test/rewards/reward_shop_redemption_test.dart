import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_shop_repository.dart';
import 'package:lumo_lernen/core/reward_shop_session.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'reward_test_store.dart';

const _key = 'lumo_reward_wallet_v1';
const _before = RewardWallet(
    stars: 200,
    xp: 800,
    level: 3,
    totalEarnedStars: 500,
    streak: 4,
    lumoCardsWinStreak: 2,
    gameResultIds: ['one-existing-game']);
const _item = RewardItem(
    id: 'custom_22222222222222222222222222222222',
    title: 'Gemeinsame Schatzsuche',
    emoji: '🗺️',
    description: 'Im Garten',
    cost: 80,
    minLevel: 2,
    revision: 1,
    category: CustomRewardCategory.leisure,
    currency: RewardCurrency.stars,
    seasons: [],
    parentApprovalRequired: true);

RewardShopRedemption _receipt([String owner = 'child-a']) =>
    RewardShopRepository.createRedemption(ownerId: owner, item: _item);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {_key: jsonEncode(_before.toJson())}));

  test(
      'Concurrent retries and process restart debit one price and retain all other wallet facts',
      () async {
    final wallet = RewardWalletRepository();
    final receipt = _receipt();
    await Future.wait([
      wallet.redeemShopReward(redemption: receipt, validateOwner: () {}),
      wallet.redeemShopReward(redemption: receipt, validateOwner: () {}),
    ]);
    final restarted = RewardWalletRepository();
    final saved = await restarted.redeemShopReward(
        redemption: receipt, validateOwner: () {});
    expect(saved.stars, 120);
    expect(saved.xp, 800);
    expect(saved.level, 3);
    expect(saved.totalEarnedStars, 500);
    expect(saved.streak, 4);
    expect(saved.lumoCardsWinStreak, 2);
    expect(saved.gameResultIds, ['one-existing-game']);
    expect(saved.shopRedemptions, hasLength(1));
    expect(saved.shopRedemptions.single.toJson(), receipt.toJson());
  });

  test('An existing transaction rejects a changed title or price', () async {
    final wallet = RewardWalletRepository();
    final receipt = _receipt();
    await wallet.redeemShopReward(redemption: receipt, validateOwner: () {});
    for (final patch in [
      <String, Object?>{'cost': 5},
      <String, Object?>{'title': 'Anderes Geschenk'}
    ]) {
      final changed =
          RewardShopRedemption.fromJson({...receipt.toJson(), ...patch});
      await expectLater(
          wallet.redeemShopReward(redemption: changed, validateOwner: () {}),
          throwsStateError);
    }
    expect(wallet.snapshot.stars, 120);
    expect(wallet.snapshot.shopRedemptions.single.title, _item.title);
  });

  test('Insufficient stars or level never partially debit or create history',
      () async {
    for (final initial in [
      const RewardWallet(stars: 79, xp: 800),
      const RewardWallet(stars: 200, xp: 0),
    ]) {
      SharedPreferences.setMockInitialValues(
          {_key: jsonEncode(initial.toJson())});
      final wallet = RewardWalletRepository();
      await expectLater(
          wallet.redeemShopReward(redemption: _receipt(), validateOwner: () {}),
          throwsStateError);
      expect(wallet.snapshot.stars, initial.stars);
      expect(wallet.snapshot.shopRedemptions, isEmpty);
      expect((await SharedPreferences.getInstance()).getString(_key),
          jsonEncode(initial.toJson()));
    }
  });

  for (final reply in [
    RewardWriteReply.falseAfterMemory,
    RewardWriteReply.throwAfterMemory,
    RewardWriteReply.throwAfterCommit
  ]) {
    test(
        'An uncertain wallet reply ($reply) requires durable retry without a second debit',
        () async {
      final store = RewardTestStore({_key: jsonEncode(_before.toJson())})
        ..failingPrefix = 'flutter.$_key'
        ..reply = reply
        ..failuresLeft = 1;
      SharedPreferencesStorePlatform.instance = store;
      final receipt = _receipt();
      final wallet = RewardWalletRepository();
      await expectLater(
          wallet.redeemShopReward(redemption: receipt, validateOwner: () {}),
          throwsStateError);
      expect(wallet.snapshot.stars, 200);
      expect(store.confirmedTargetWrites, 0);
      // A new repository sees the native/Dart cache from the uncertain reply.
      // Deduplication must still obtain a positive durable confirmation.
      final retry = RewardWalletRepository();
      final confirmed = await retry.redeemShopReward(
          redemption: receipt, validateOwner: () {});
      expect(confirmed.stars, 120);
      expect(confirmed.shopRedemptions, hasLength(1));
      expect(store.confirmedTargetWrites, 1);
      final disk = RewardWallet.fromJson(
          jsonDecode(store.disk['flutter.$_key'] as String)
              as Map<String, dynamic>);
      expect(disk.stars, 120);
      expect(disk.shopRedemptions.single.toJson(), receipt.toJson());
    });
  }

  test('AppState rejects the original receipt after child selection changes',
      () async {
    final wallet = RewardWalletRepository();
    final app = LumoAppState(walletRepository: wallet);
    await app.school.setActiveStudent('child-a');
    final owner = await app.captureLearningProfile();
    final receipt = _receipt(owner.studentId);
    await app.school.setActiveStudent('child-b');
    await expectLater(app.redeemShopReward(lease: owner, redemption: receipt),
        throwsStateError);
    expect((await wallet.load()).stars, 200);
    expect(wallet.snapshot.shopRedemptions, isEmpty);
    app.dispose();
  });

  test(
      'Malformed stored receipt cannot erase the existing wallet on the next award',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final broken = jsonEncode({
      ..._before.toJson(),
      'shopRedemptions': [
        {'cost': 1}
      ]
    });
    await prefs.setString(_key, broken);
    final wallet = RewardWalletRepository();
    await expectLater(wallet.load(), throwsA(anything));
    await expectLater(wallet.addStars(3), throwsA(anything));
    expect(prefs.getString(_key), broken);
  });

  test(
      'A cached pending receipt stays unconfirmed until the session gets a positive write reply',
      () async {
    final store = RewardTestStore({_key: jsonEncode(_before.toJson())});
    SharedPreferencesStorePlatform.instance = store;
    const repository = RewardShopRepository();
    final definition = CustomRewardDefinition(
        id: _item.id,
        revision: 1,
        title: _item.title,
        emoji: _item.emoji,
        description: _item.description,
        cost: _item.cost,
        minLevel: _item.minLevel,
        category: _item.category!);
    await repository.saveDefinition(
        ownerId: 'child-a', definition: definition, validateOwner: () {});
    final receipt = _receipt();
    await repository.stageRedemption(redemption: receipt, validateOwner: () {});
    store
      ..failingPrefix = 'flutter.$_key'
      ..reply = RewardWriteReply.falseAfterMemory
      ..failuresLeft = 1;
    await expectLater(
        RewardWalletRepository()
            .redeemShopReward(redemption: receipt, validateOwner: () {}),
        throwsStateError);
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.school.setActiveStudent('child-a');
    store.failuresLeft = 1;
    final session = RewardShopSession(app);
    await session.load();
    expect(session.ready, isFalse);
    expect(session.error, isNotNull);
    expect(store.confirmedTargetWrites, 0);
    await session.load();
    expect(session.ready, isTrue);
    expect(session.wallet!.stars, 120);
    expect(session.history, hasLength(1));
    expect(session.pending, isEmpty);
    expect(store.confirmedTargetWrites, 1);
    session.dispose();
    app.dispose();
  });
}
