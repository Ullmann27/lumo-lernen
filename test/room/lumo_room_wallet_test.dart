import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_room_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/room/lumo_room.dart';
import '../rewards/reward_test_store.dart';

const _key = 'lumo_reward_wallet_v1';
const _owner = 'room-child-a';
const _other = 'room-child-b';
const _initial = RewardWallet(stars: 2000, xp: 500, totalEarnedStars: 3000);
const _repository = LumoRoomRepository();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {_key: jsonEncode(_initial.toJson())}));
  tearDown(LumoRoomRepository.flushPendingWrites);

  test('Catalog preserves all eight original IDs and star prices', () {
    expect({
      for (final item in LumoRoomCatalog.items) item.id: item.cost
    }, {
      'plant': 80,
      'rug': 120,
      'pet': 180,
      'star': 220,
      'scarf_blue': 0,
      'scarf_green': 160,
      'scarf_rose': 160,
      'room_space': 300,
    });
  });

  test(
      'Concurrent purchase and restart retain one quote, one debit and owner inventory',
      () async {
    final item = LumoRoomCatalog.byId('plant');
    final staged = await Future.wait([
      _repository.stagePurchase(
          ownerId: _owner, item: item, validateOwner: () {}),
      _repository.stagePurchase(
          ownerId: _owner, item: item, validateOwner: () {}),
    ]);
    final quote = staged.first.purchases.single.receipt;
    expect(staged.last.purchases.single.receipt.toJson(), quote.toJson());
    final wallet = RewardWalletRepository();
    await Future.wait([
      wallet.redeemShopReward(redemption: quote, validateOwner: () {}),
      wallet.redeemShopReward(redemption: quote, validateOwner: () {}),
    ]);
    final restarted = RewardWalletRepository();
    final confirmed = await restarted.redeemShopReward(
        redemption: quote, validateOwner: () {});
    expect(confirmed.stars, 1920);
    expect(confirmed.shopRedemptions, hasLength(1));
    expect(confirmed.roomActions, isEmpty);
    expect(confirmed.gameResultIds, isEmpty);
    expect(confirmed.totalEarnedStars, 3000);
    expect(confirmed.earnedStarsByOwner, isEmpty);
    expect(
        LumoRoomCatalog.owns(_owner, item, confirmed.shopRedemptions), isTrue);
    expect(
        LumoRoomCatalog.owns(_other, item, confirmed.shopRedemptions), isFalse);
    await _repository.confirmPurchase(
        ownerId: _owner, itemId: item.id, validateOwner: () {});
    await _repository.equip(
        ownerId: _owner,
        item: item,
        receipts: confirmed.shopRedemptions,
        validateOwner: () {});
    final saved = await const LumoRoomRepository().load(_owner);
    expect(saved.purchases.single.receipt.toJson(), quote.toJson());
    expect(saved.purchases.single.confirmed, isTrue);
    expect(saved.equipped, {'scarf_blue', 'plant'});
    expect((await _repository.load(_other)).equipped, {'scarf_blue'});
  });

  test('Only the original free blue scarf is available without a paid receipt',
      () async {
    final wallet = await RewardWalletRepository().load();
    for (final item in LumoRoomCatalog.items.where((v) => v.cost > 0)) {
      await expectLater(
          _repository.equip(
              ownerId: _owner,
              item: item,
              receipts: wallet.shopRedemptions,
              validateOwner: () {}),
          throwsStateError);
    }
    await expectLater(
        _repository.equip(
            ownerId: _owner,
            item: const LumoRoomItem(
                'plant', 'Lumo-Pflanze', '🌱', 0, LumoRoomItemKind.decoration),
            receipts: [],
            validateOwner: () {}),
        throwsStateError);
    final saved = await _repository.equip(
        ownerId: _owner,
        item: LumoRoomCatalog.byId('scarf_blue'),
        receipts: [],
        validateOwner: () {});
    expect(saved.equipped, {'scarf_blue'});
    expect((await RewardWalletRepository().load()).stars, 2000);
  });

  test(
      'Praise cooldown is persistent per child and survives wall-clock rollback',
      () async {
    var now = DateTime.utc(2026, 11, 22, 12);
    final wallet = RewardWalletRepository(clock: () => now);
    final request =
        LumoRoomRepository.newAction(_owner, LumoRoomActionKind.pet);
    await wallet.performLumoRoomAction(request: request, validateOwner: () {});
    await wallet.performLumoRoomAction(request: request, validateOwner: () {});
    expect(wallet.snapshot.stars, 2005);
    final next = LumoRoomRepository.newAction(_owner, LumoRoomActionKind.pet);
    for (final time in [
      DateTime.utc(2026, 11, 22, 12, 4, 59),
      DateTime.utc(2026, 11, 21)
    ]) {
      now = time;
      await expectLater(
          RewardWalletRepository(clock: () => now)
              .performLumoRoomAction(request: next, validateOwner: () {}),
          throwsA(isA<LumoRoomActionUnavailable>()));
    }
    now = DateTime.utc(2026, 11, 22, 12, 5);
    final restarted = RewardWalletRepository(clock: () => now);
    await restarted.performLumoRoomAction(request: next, validateOwner: () {});
    final both = await restarted.performLumoRoomAction(
        request: LumoRoomRepository.newAction(_other, LumoRoomActionKind.pet),
        validateOwner: () {});
    expect(both.stars, 2015);
    expect(both.roomActions, hasLength(3));
    expect(both.earnedStarsByOwner, {_owner: 10, _other: 5});
    expect(both.totalEarnedStars, 3015);
    expect(both.gameResultIds, isEmpty);
  });

  test(
      'Snack commits its -10 stars and +20 XP together and rejects a changed action',
      () async {
    final wallet = RewardWalletRepository();
    final request =
        LumoRoomRepository.newAction(_owner, LumoRoomActionKind.feed);
    await Future.wait([
      wallet.performLumoRoomAction(request: request, validateOwner: () {}),
      wallet.performLumoRoomAction(request: request, validateOwner: () {}),
    ]);
    final saved = await RewardWalletRepository()
        .performLumoRoomAction(request: request, validateOwner: () {});
    expect(saved.stars, 1990);
    expect(saved.xp, 520);
    expect(saved.roomActions, hasLength(1));
    expect(saved.totalEarnedStars, 3000);
    expect(saved.earnedStarsByOwner, isEmpty);
    await expectLater(
        wallet.performLumoRoomAction(
            request: LumoRoomActionRequest(
                actionId: request.actionId,
                ownerId: _owner,
                kind: LumoRoomActionKind.pet),
            validateOwner: () {}),
        throwsStateError);
  });

  test('Insufficient stars reject a snack before XP or a receipt changes',
      () async {
    SharedPreferences.setMockInitialValues(
        {_key: jsonEncode(const RewardWallet(stars: 9, xp: 399).toJson())});
    final wallet = RewardWalletRepository();
    await expectLater(
        wallet.performLumoRoomAction(
            request:
                LumoRoomRepository.newAction(_owner, LumoRoomActionKind.feed),
            validateOwner: () {}),
        throwsA(isA<LumoRoomActionUnavailable>()));
    expect(wallet.snapshot.stars, 9);
    expect(wallet.snapshot.xp, 399);
    expect(wallet.snapshot.level, 1);
    expect(wallet.snapshot.roomActions, isEmpty);
  });

  for (final kind in LumoRoomActionKind.values) {
    for (final reply in [
      RewardWriteReply.falseAfterMemory,
      RewardWriteReply.throwAfterMemory,
      RewardWriteReply.throwAfterCommit
    ]) {
      test(
          '$kind with $reply requires positive persistence and never pays twice',
          () async {
        final store = RewardTestStore({_key: jsonEncode(_initial.toJson())})
          ..failingPrefix = 'flutter.$_key'
          ..reply = reply
          ..failuresLeft = 1;
        SharedPreferencesStorePlatform.instance = store;
        final request = LumoRoomRepository.newAction(_owner, kind);
        final wallet = RewardWalletRepository();
        await expectLater(
            wallet.performLumoRoomAction(
                request: request, validateOwner: () {}),
            throwsStateError);
        expect(wallet.snapshot.stars, 2000);
        expect(wallet.snapshot.xp, 500);
        expect(store.confirmedTargetWrites, 0);
        final saved = await RewardWalletRepository()
            .performLumoRoomAction(request: request, validateOwner: () {});
        final expectedStars = kind == LumoRoomActionKind.pet ? 2005 : 1990;
        final expectedXp = kind == LumoRoomActionKind.feed ? 520 : 500;
        expect(saved.stars, expectedStars);
        expect(saved.xp, expectedXp);
        expect(saved.roomActions, hasLength(1));
        expect(store.confirmedTargetWrites, 1);
        SharedPreferences.setMockInitialValues(store.disk
            .map((k, v) => MapEntry(k.substring('flutter.'.length), v)));
        final cold = await RewardWalletRepository()
            .performLumoRoomAction(request: request, validateOwner: () {});
        expect(cold.stars, expectedStars);
        expect(cold.xp, expectedXp);
        expect(cold.roomActions, hasLength(1));
        expect(cold.earnedStarsByOwner,
            kind == LumoRoomActionKind.pet ? {_owner: 5} : isEmpty);
      });
    }
  }

  test('A stale child lease cannot perform an action after a profile switch',
      () async {
    final wallet = RewardWalletRepository();
    final app = LumoAppState(walletRepository: wallet);
    await app.school.setActiveStudent(_owner);
    final lease = await app.captureLearningProfile();
    await app.school.setActiveStudent(_other);
    await expectLater(
        app.performLumoRoomAction(
            lease: lease,
            request:
                LumoRoomRepository.newAction(_owner, LumoRoomActionKind.pet)),
        throwsStateError);
    expect((await wallet.load()).stars, 2000);
    expect(wallet.snapshot.roomActions, isEmpty);
    app.dispose();
  });

  test(
      'Owner lifetime credits record actual positive changes without assigning legacy stars',
      () async {
    SharedPreferences.setMockInitialValues({
      _key: jsonEncode(
          const RewardWallet(stars: 999997, totalEarnedStars: 1000000).toJson())
    });
    final wallet = RewardWalletRepository();
    await wallet.applyRewardDelta(starsDelta: 20, ownerId: _owner);
    expect(wallet.snapshot.earnedStarsByOwner, {_owner: 2});
    await wallet.applyRewardDelta(starsDelta: -9, ownerId: _owner);
    await wallet.awardGameResult(
        resultId: 'game-proof', stars: 7, xp: 0, ownerId: _other);
    await wallet.awardGameResult(
        resultId: 'game-proof', stars: 7, xp: 0, ownerId: _other);
    expect((await RewardWalletRepository().load()).earnedStarsByOwner,
        {_owner: 2, _other: 7});
  });

  test('Malformed room data stays intact and blocks replacement writes',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final key = LumoRoomRepository.profileKey(_owner);
    const broken = '{"version":99,"kept":"original"}';
    await prefs.setString(key, broken);
    await expectLater(
        _repository.stagePurchase(
            ownerId: _owner,
            item: LumoRoomCatalog.byId('plant'),
            validateOwner: () {}),
        throwsA(isA<FormatException>()));
    expect(prefs.getString(key), broken);
  });

  test('A rejected equipment write reloads the previous platform state',
      () async {
    final store = _RejectRoomStore({_key: jsonEncode(_initial.toJson())});
    SharedPreferencesStorePlatform.instance = store;
    final item = LumoRoomCatalog.byId('scarf_green');
    final quote = (await _repository.stagePurchase(
            ownerId: _owner, item: item, validateOwner: () {}))
        .purchases
        .single
        .receipt;
    final wallet = await RewardWalletRepository()
        .redeemShopReward(redemption: quote, validateOwner: () {});
    store.reject = true;
    await expectLater(
        _repository.equip(
            ownerId: _owner,
            item: item,
            receipts: wallet.shopRedemptions,
            validateOwner: () {}),
        throwsStateError);
    expect((await _repository.load(_owner)).equipped, {'scarf_blue'});
    store.reject = false;
    expect(
        (await _repository.loadConfirmed(ownerId: _owner, validateOwner: () {}))
            .equipped,
        {'scarf_blue'});
    expect((await RewardWalletRepository().load()).stars, 1840);
  });

  test(
      'An uncertain native equipment cache requires a positive reopen acknowledgement',
      () async {
    final store = RewardTestStore({_key: jsonEncode(_initial.toJson())});
    SharedPreferencesStorePlatform.instance = store;
    final item = LumoRoomCatalog.byId('scarf_green');
    final quote = (await _repository.stagePurchase(
            ownerId: _owner, item: item, validateOwner: () {}))
        .purchases
        .single
        .receipt;
    final wallet = await RewardWalletRepository()
        .redeemShopReward(redemption: quote, validateOwner: () {});
    store
      ..failingPrefix = 'flutter.${LumoRoomRepository.profileKey(_owner)}'
      ..reply = RewardWriteReply.falseAfterMemory
      ..failuresLeft = 2;
    await expectLater(
        _repository.equip(
            ownerId: _owner,
            item: item,
            receipts: wallet.shopRedemptions,
            validateOwner: () {}),
        throwsStateError);
    await expectLater(
        _repository.loadConfirmed(ownerId: _owner, validateOwner: () {}),
        throwsStateError);
    expect(store.confirmedTargetWrites, 0);
    final confirmed =
        await _repository.loadConfirmed(ownerId: _owner, validateOwner: () {});
    expect(confirmed.equipped, {'scarf_green'});
    expect(store.confirmedTargetWrites, 1);
    final disk = LumoRoomProfile.fromJson((jsonDecode(
            store.disk['flutter.${LumoRoomRepository.profileKey(_owner)}']
                as String) as Map)
        .cast<String, Object?>());
    expect(disk.equipped, {'scarf_green'});
    expect((await RewardWalletRepository().load()).stars, 1840);
  });
}

class _RejectRoomStore extends InMemorySharedPreferencesStore {
  _RejectRoomStore(Map<String, Object> values)
      : super.withData(values.map((k, v) => MapEntry('flutter.$k', v)));
  bool reject = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (reject && key.startsWith('flutter.lumo.room.profile.')) return false;
    return super.setValue(type, key, value);
  }
}
