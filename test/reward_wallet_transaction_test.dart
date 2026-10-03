import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/core/reward_wallet_repository.dart';

enum _Outcome { success, falseResult, exception }

/// Models the actual platform store, independently of SharedPreferences' cache.
class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore(
      {this.firstOutcome = _Outcome.success, Map<String, Object>? seed})
      : super.withData((seed ??
                {
                  'lumo_reward_wallet_v1':
                      jsonEncode(const RewardWallet().toJson()),
                })
            .map((key, value) => MapEntry('flutter.$key', value)));

  final _Outcome firstOutcome;
  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  final writtenSnapshots = <Map<String, dynamic>>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writtenSnapshots.add(jsonDecode(value as String) as Map<String, dynamic>);
    if (writtenSnapshots.length == 1) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
      if (firstOutcome == _Outcome.falseResult) return false;
      if (firstOutcome == _Outcome.exception) {
        throw StateError('Disk unavailable');
      }
    }
    return super.setValue(valueType, key, value);
  }

  Future<Map<String, dynamic>> persistedWallet() async =>
      jsonDecode((await getAll())['flutter.lumo_reward_wallet_v1'] as String)
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Old flat wallet JSON keeps balances, levels, streak and earned stars',
      () async {
    SharedPreferences.setMockInitialValues({
      'lumo_reward_wallet_v1': jsonEncode({
        'stars': 40,
        'xp': 875,
        'level': 9, // Legacy stored level is recalculated from actual XP.
        'streak': 4,
        'totalEarnedStars': 55,
        'lastDailyKey': '2026-10-02',
      }),
    });
    final wallet = RewardWalletRepository();
    final old = await wallet.load();
    expect(old.stars, 40);
    expect(old.xp, 875);
    expect(old.level, 3);
    expect(old.streak, 4);
    expect(old.totalEarnedStars, 55);
    expect(old.lastDailyKey, '2026-10-02');
    expect(old.gameResultIds, isEmpty);
    await wallet.awardGameResult(resultId: 'first-race', stars: 6, xp: 20);
    final restarted = await RewardWalletRepository().load();
    expect(restarted.stars, 46);
    expect(restarted.xp, 895);
    expect(restarted.streak, 4);
    expect(restarted.gameResultIds, ['first-race']);
  });

  for (final failure in [_Outcome.falseResult, _Outcome.exception]) {
    test(
        'Failed game write ($failure) preserves concurrent learning and allows replay',
        () async {
      final store = _ControlledStore(firstOutcome: failure);
      SharedPreferencesStorePlatform.instance = store;
      final wallet = RewardWalletRepository();
      await wallet.load();
      final emitted = <RewardWallet>[];
      final subscription = wallet.changes.listen(emitted.add);
      final award =
          wallet.awardGameResult(resultId: 'race-1', stars: 6, xp: 20);
      final rejected = expectLater(award, throwsStateError);
      await store.firstWriteStarted.future;
      final lessonStars = wallet.addStars(3);
      final lessonXp = wallet.addXp(5);
      // The platform has not accepted the award: consumers still see zero.
      expect(wallet.snapshot.stars, 0);
      expect(wallet.snapshot.gameResultIds, isEmpty);
      expect(emitted, isEmpty);
      expect(store.writtenSnapshots, hasLength(1));
      store.releaseFirstWrite.complete();
      await rejected;
      await Future.wait([lessonStars, lessonXp]);
      expect(wallet.snapshot.stars, 3);
      expect(wallet.snapshot.xp, 5);
      final savedLesson = await store.persistedWallet();
      expect(savedLesson['stars'], 3);
      expect(savedLesson['xp'], 5);
      expect(savedLesson['gameResultIds'], isEmpty);
      await wallet.awardGameResult(resultId: 'race-1', stars: 6, xp: 20);
      expect(wallet.snapshot.stars, 9);
      expect(wallet.snapshot.xp, 25);
      final savedAward = await store.persistedWallet();
      expect(savedAward['stars'], 9);
      expect(savedAward['xp'], 25);
      expect(savedAward['gameResultIds'], ['race-1']);
      await wallet.awardGameResult(resultId: 'race-1', stars: 6, xp: 20);
      expect(wallet.snapshot.stars, 9);
      expect(store.writtenSnapshots, hasLength(4));
      await subscription.cancel();
    });
  }

  test(
      'Successful game write commits balance and identity together before queued changes',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();
    final award = wallet.awardGameResult(resultId: 'race-2', stars: 6, xp: 20);
    await store.firstWriteStarted.future;
    final stars = wallet.addStars(3);
    final xp = wallet.addXp(5);
    final daily = wallet.markDailyActivity();
    expect(wallet.snapshot.stars, 0);
    expect(store.writtenSnapshots, hasLength(1));
    store.releaseFirstWrite.complete();
    await Future.wait([award, stars, xp, daily]);
    expect(wallet.snapshot.stars, 9);
    expect(wallet.snapshot.xp, 25);
    expect(wallet.snapshot.streak, 1);
    expect(wallet.snapshot.totalEarnedStars, 9);
    for (final saved in store.writtenSnapshots) {
      expect(saved['gameResultIds'], ['race-2']);
      expect(saved['stars'], greaterThanOrEqualTo(6));
      expect(saved['xp'], greaterThanOrEqualTo(20));
    }
  });

  test(
      'Concurrent duplicate awards and a fresh-process replay grant one reward',
      () async {
    final wallet = RewardWalletRepository();
    await Future.wait(List.generate(
        8,
        (_) => wallet.awardGameResult(
              resultId: 'same-race',
              stars: 9,
              xp: 30,
            )));
    expect(wallet.snapshot.stars, 9);
    expect(wallet.snapshot.xp, 30);
    expect(wallet.snapshot.gameResultIds, ['same-race']);
    final restarted = RewardWalletRepository();
    await restarted.awardGameResult(resultId: 'same-race', stars: 9, xp: 30);
    expect(restarted.snapshot.stars, 9);
    expect(restarted.snapshot.xp, 30);
  });

  test(
      'Reset waits for an in-flight award and does not restore its old snapshot',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    final award =
        wallet.awardGameResult(resultId: 'before-reset', stars: 6, xp: 20);
    await store.firstWriteStarted.future;
    final stars = wallet.addStars(3);
    final daily = wallet.markDailyActivity();
    final reset = wallet.reset();
    final afterReset = wallet.addStars(2);
    expect(store.writtenSnapshots, hasLength(1));
    store.releaseFirstWrite.complete();
    await award;
    await stars;
    await daily;
    await reset;
    await afterReset;
    final saved = await store.persistedWallet();
    expect(wallet.snapshot.stars, 2);
    expect(wallet.snapshot.xp, 0);
    expect(wallet.snapshot.streak, 0);
    expect(wallet.snapshot.gameResultIds, isEmpty);
    expect(saved['stars'], 2);
    expect(saved['gameResultIds'], isEmpty);
  });

  test('A failed reset reports failure and preserves the existing balance',
      () async {
    final store = _ControlledStore(firstOutcome: _Outcome.falseResult, seed: {
      'lumo_reward_wallet_v1': jsonEncode(const RewardWallet(
        stars: 40,
        xp: 400,
        gameResultIds: ['earned-race'],
      ).toJson()),
    });
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();
    final reset = expectLater(wallet.reset(), throwsStateError);
    await store.firstWriteStarted.future;
    expect(wallet.snapshot.stars, 40);
    store.releaseFirstWrite.complete();
    await reset;
    expect(wallet.snapshot.stars, 40);
    expect(wallet.snapshot.gameResultIds, ['earned-race']);
    expect((await store.persistedWallet())['stars'], 40);
    await wallet.addStars(1);
    expect(wallet.snapshot.stars, 41);
  });

  test(
      'A failed lesson mutation does not poison later XP or its explicit retry',
      () async {
    final store = _ControlledStore(firstOutcome: _Outcome.falseResult);
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();
    final failed = expectLater(wallet.addStars(3), throwsStateError);
    await store.firstWriteStarted.future;
    final xp = wallet.addXp(5);
    store.releaseFirstWrite.complete();
    await failed;
    await xp;
    expect(wallet.snapshot.stars, 0);
    expect(wallet.snapshot.xp, 5);
    await wallet.addStars(3);
    expect(wallet.snapshot.stars, 3);
    expect((await store.persistedWallet())['stars'], 3);
  });

  test('Failed legacy migration keeps saved rewards for the next transaction',
      () async {
    final store = _ControlledStore(firstOutcome: _Outcome.falseResult, seed: {
      'lumo_legacy_stars': 12,
      'lumo_legacy_xp': 80,
    });
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    final loading = wallet.load();
    await store.firstWriteStarted.future;
    store.releaseFirstWrite.complete();
    expect((await loading).stars, 12);
    await wallet.awardGameResult(resultId: 'post-migration', stars: 3, xp: 20);
    expect(wallet.snapshot.stars, 15);
    expect(wallet.snapshot.xp, 100);
    expect((await store.persistedWallet())['stars'], 15);
  });

  test('Invalid native rewards cannot write balances or poison the queue',
      () async {
    final wallet = RewardWalletRepository();
    for (final values in [
      ('', 3, 20),
      (List.filled(161, 'x').join(), 3, 20),
      ('invalid-stars', 101, 20),
      ('negative-stars', -1, 20),
      ('invalid-xp', 3, 1001),
    ]) {
      await expectLater(
          wallet.awardGameResult(
            resultId: values.$1,
            stars: values.$2,
            xp: values.$3,
          ),
          throwsArgumentError);
    }
    expect(wallet.snapshot.stars, 0);
    expect(wallet.snapshot.gameResultIds, isEmpty);
    await wallet.awardGameResult(resultId: 'valid', stars: 3, xp: 20);
    expect(wallet.snapshot.stars, 3);
  });
}
