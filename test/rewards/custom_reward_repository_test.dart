import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/core/reward_shop_repository.dart';
import 'package:lumo_lernen/domain/rewards/reward_catalog.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'reward_test_store.dart';

const _owner = 'gutschein-kind-a';
const _definition = CustomRewardDefinition(
  id: 'custom_11111111111111111111111111111111',
  revision: 1,
  title: 'Picknick am Bach',
  emoji: '🧺',
  cost: 80,
  minLevel: 2,
  category: CustomRewardCategory.leisure,
  description: 'Wir suchen den Platz gemeinsam aus.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(RewardShopRepository.flushPendingWrites);
  const repo = RewardShopRepository();

  test(
      'Own vouchers survive a new repository and remain separate by stable child',
      () async {
    await repo.saveDefinition(
        ownerId: _owner, definition: _definition, validateOwner: () {});
    final restarted = await const RewardShopRepository().loadProfile(_owner);
    expect(restarted.currentDefinitions.single.toJson(), _definition.toJson());
    expect((await repo.loadProfile('gutschein-kind-b')).currentDefinitions,
        isEmpty);
    final all = const RewardShopEngine().availableRewards(
        customRewards: restarted.currentDefinitions,
        now: DateTime(2026, 11, 22));
    expect(RewardCatalog.all, hasLength(33));
    expect(all.any((v) => v.id == _definition.id), isTrue);
    expect(
        all.where((v) => !v.isCustom).length,
        const RewardShopEngine()
            .availableRewards(now: DateTime(2026, 11, 22))
            .length);
    expect(
        const RewardShopEngine().canAfford(
            const RewardShopState(availableStars: 100), _definition.item,
            level: 1),
        isFalse);
    expect(
        const RewardShopEngine().canAfford(
            const RewardShopState(availableStars: 100), _definition.item,
            level: 2),
        isTrue);
  });

  test('Editing and deactivation preserve original pending price and revision',
      () async {
    await repo.saveDefinition(
        ownerId: _owner, definition: _definition, validateOwner: () {});
    final pending = RewardShopRepository.createRedemption(
        ownerId: _owner, item: _definition.item);
    await repo.stageRedemption(redemption: pending, validateOwner: () {});
    final edited =
        _definition.nextRevision(title: 'Picknick im Park', cost: 200);
    await repo.saveDefinition(
        ownerId: _owner, definition: edited, validateOwner: () {});
    await repo.saveDefinition(
        ownerId: _owner,
        definition: edited.nextRevision(active: false),
        validateOwner: () {});
    final saved = await repo.loadProfile(_owner);
    expect(saved.revisions, hasLength(3));
    expect(saved.currentDefinitions.single.active, isFalse);
    expect(saved.pendingRedemptions.single.title, 'Picknick am Bach');
    expect(saved.pendingRedemptions.single.cost, 80);
    expect(saved.pendingRedemptions.single.itemRevision, 1);
    expect(
        const RewardShopEngine()
            .availableRewards(customRewards: saved.currentDefinitions)
            .any((v) => v.id == _definition.id),
        isFalse);
    await repo.stageRedemption(redemption: pending, validateOwner: () {});
    expect((await repo.loadProfile(_owner)).pendingRedemptions, hasLength(1));
  });

  test('Invalid values never create a profile document', () async {
    for (final invalid in [
      _definition.nextRevision(cost: 0),
      _definition.nextRevision(cost: -4),
      _definition.nextRevision(cost: 1000000),
      _definition.nextRevision(minLevel: 0),
      _definition.nextRevision(minLevel: 25001),
      _definition.nextRevision(title: '   '),
      _definition.nextRevision(emoji: ''),
    ]) {
      expect(
          () => repo.saveDefinition(
              ownerId: _owner, definition: invalid, validateOwner: () {}),
          throwsFormatException);
    }
    expect(
        (await SharedPreferences.getInstance())
            .getString(RewardShopRepository.profileKey(_owner)),
        isNull);
  });

  test('Concurrent stale edits cannot overwrite a newer definition', () async {
    await repo.saveDefinition(
        ownerId: _owner, definition: _definition, validateOwner: () {});
    final accepted = repo.saveDefinition(
        ownerId: _owner,
        definition: _definition.nextRevision(cost: 90),
        validateOwner: () {});
    final stale = repo.saveDefinition(
        ownerId: _owner,
        definition: _definition.nextRevision(cost: 99),
        validateOwner: () {});
    await accepted;
    await expectLater(stale, throwsStateError);
    expect((await repo.loadProfile(_owner)).currentDefinitions.single.cost, 90);
  });

  for (final reply in [
    RewardWriteReply.falseAfterMemory,
    RewardWriteReply.throwAfterMemory
  ]) {
    test('An uncertain definition save ($reply) retries the same revision once',
        () async {
      final store = RewardTestStore({})
        ..failingPrefix = 'flutter.lumo.reward_shop.profile.'
        ..reply = reply
        ..failuresLeft = 1;
      SharedPreferencesStorePlatform.instance = store;
      await expectLater(
          repo.saveDefinition(
              ownerId: _owner, definition: _definition, validateOwner: () {}),
          throwsStateError);
      expect(store.confirmedTargetWrites, 0);
      await repo.saveDefinition(
          ownerId: _owner, definition: _definition, validateOwner: () {});
      final raw = store
          .disk['flutter.${RewardShopRepository.profileKey(_owner)}'] as String;
      final durable = RewardShopProfile.fromJson(
          (jsonDecode(raw) as Map).cast<String, Object?>());
      expect(durable.revisions, hasLength(1));
      expect(durable.currentDefinitions.single.toJson(), _definition.toJson());
      expect(store.confirmedTargetWrites, 1);
    });
  }

  test('A captured owner rejected by the guard cannot be retargeted', () async {
    await expectLater(
        repo.saveDefinition(
            ownerId: _owner,
            definition: _definition,
            validateOwner: () => throw StateError('Profile changed')),
        throwsStateError);
    expect((await repo.loadProfile(_owner)).currentDefinitions, isEmpty);
    expect((await repo.loadProfile('gutschein-kind-b')).currentDefinitions,
        isEmpty);
  });

  test('Corrupt profile data is retained and cannot be overwritten by an edit',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(RewardShopRepository.profileKey(_owner), '{broken');
    await expectLater(repo.loadProfile(_owner), throwsFormatException);
    await expectLater(
        repo.saveDefinition(
            ownerId: _owner, definition: _definition, validateOwner: () {}),
        throwsFormatException);
    expect(prefs.getString(RewardShopRepository.profileKey(_owner)), '{broken');
  });
}
