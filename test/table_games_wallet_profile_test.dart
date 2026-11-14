import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';

const _initialWallet = RewardWallet(
  stars: 7,
  xp: 40,
  totalEarnedStars: 19,
  streak: 3,
  lumoCardsWinStreak: 2,
);

class _WalletStore extends InMemorySharedPreferencesStore {
  _WalletStore()
    : super.withData({
        'flutter.lumo_reward_wallet_v1': jsonEncode(_initialWallet.toJson()),
      });

  bool failNextWalletWrite = false;
  Completer<void>? heldWriteEntered;
  Completer<void>? releaseHeldWrite;

  void holdNextWalletWrite() {
    heldWriteEntered = Completer<void>();
    releaseHeldWrite = Completer<void>();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.lumo_reward_wallet_v1') {
      if (heldWriteEntered != null && !heldWriteEntered!.isCompleted) {
        heldWriteEntered!.complete();
        await releaseHeldWrite!.future;
      }
      if (failNextWalletWrite) {
        failNextWalletWrite = false;
        return false;
      }
    }
    return super.setValue(valueType, key, value);
  }

  Future<RewardWallet> durableWallet() async => RewardWallet.fromJson(
    jsonDecode((await getAll())['flutter.lumo_reward_wallet_v1'] as String)
        as Map<String, dynamic>,
  );
}

class _Account {
  _Account(this.app, this.wallet, this.lease);
  final LumoAppState app;
  final RewardWalletRepository wallet;
  final LearningProfileLease lease;
}

Future<_Account> _account() async {
  final wallet = RewardWalletRepository();
  await wallet.load();
  final app = LumoAppState(walletRepository: wallet);
  addTearDown(app.dispose);
  await app.school.setActiveStudent('table-child-a');
  return _Account(app, wallet, await app.captureLearningProfile());
}

String _resultId(String game, LearningProfileLease lease, int round) =>
    '$game:${sha256.convert(utf8.encode(lease.studentId))}:'
    '${round.toRadixString(16).padLeft(32, '0')}';

Future<void> _award(String game, _Account account, String id) =>
    game == 'memory'
    ? account.app.recordMemoryResult(
        lease: account.lease,
        resultId: id,
        difficulty: 'leicht',
        kindPairs: 4,
        lumoPairs: 0,
      )
    : account.app.recordQuizShowResult(
        lease: account.lease,
        resultId: id,
        stars: 50,
      );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _WalletStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = _WalletStore();
    SharedPreferencesStorePlatform.instance = store;
  });
  tearDown(() {
    final release = store.releaseHeldWrite;
    if (release != null && !release.isCompleted) release.complete();
  });

  // These amounts are independent snapshots of the existing Memory contract.
  const amounts = <String, (int pairs, int won, int draw, int lost)>{
    'leicht': (4, 2, 1, 1),
    'mittel': (6, 3, 1, 1),
    'schwer': (8, 3, 1, 1),
    'knifflig': (10, 4, 2, 1),
    'profi': (12, 5, 3, 2),
  };
  for (final level in amounts.entries) {
    test(
      'Memory ${level.key}: old amounts persist once per owned round',
      () async {
        final account = await _account();
        final values = level.value;
        var earned = 0;
        var round = 1;
        for (final result in [
          (values.$1, 0, values.$2),
          (values.$1 ~/ 2, values.$1 ~/ 2, values.$3),
          (0, values.$1, values.$4),
        ]) {
          final id = _resultId('memory', account.lease, round++);
          Future<void> deliver() => account.app.recordMemoryResult(
            lease: account.lease,
            resultId: id,
            difficulty: level.key,
            kindPairs: result.$1,
            lumoPairs: result.$2,
          );
          await deliver();
          await deliver();
          earned += result.$3;
          final saved = await store.durableWallet();
          expect(saved.stars, 7 + earned);
          expect(saved.xp, 40 + earned * 8);
          expect(saved.totalEarnedStars, 19 + earned);
          expect(saved.streak, 3);
          expect(saved.lumoCardsWinStreak, 2);
          expect(
            saved.gameResultIds.where((value) => value == id),
            hasLength(1),
          );
        }
        final cold = await RewardWalletRepository().load();
        expect(cold.stars, account.wallet.snapshot.stars);
        expect(cold.xp, account.wallet.snapshot.xp);
        expect(cold.gameResultIds, hasLength(3));
      },
    );
  }

  for (final stars in [50, 200, 800, 5000]) {
    test('Quiz $stars-star milestone persists once without new XP', () async {
      final account = await _account();
      final id = _resultId('quiz', account.lease, stars);
      for (var replay = 0; replay < 2; replay++) {
        await account.app.recordQuizShowResult(
          lease: account.lease,
          resultId: id,
          stars: stars,
        );
      }
      final saved = await store.durableWallet();
      expect(saved.stars, 7 + stars);
      expect(saved.totalEarnedStars, 19 + stars);
      expect(saved.xp, 40);
      expect(saved.streak, 3);
      expect(saved.lumoCardsWinStreak, 2);
      expect(saved.gameResultIds, [id]);
      expect((await RewardWalletRepository().load()).gameResultIds, [id]);
    });
  }

  test(
    'Unfinished Memory, unknown difficulty and arbitrary Quiz amounts fail',
    () async {
      final account = await _account();
      final before = (await store.getAll())['flutter.lumo_reward_wallet_v1'];
      for (final invalid in [
        ('leicht', 3, 0),
        ('leicht', -1, 5),
        ('leicht', 4, -1),
        ('leicht', 4, 1),
        ('unknown', 4, 0),
      ]) {
        await expectLater(
          account.app.recordMemoryResult(
            lease: account.lease,
            resultId: _resultId('memory', account.lease, 1),
            difficulty: invalid.$1,
            kindPairs: invalid.$2,
            lumoPairs: invalid.$3,
          ),
          throwsStateError,
        );
      }
      for (final stars in [-1, 0, 1, 51, 5001]) {
        await expectLater(
          account.app.recordQuizShowResult(
            lease: account.lease,
            resultId: _resultId('quiz', account.lease, 1),
            stars: stars,
          ),
          throwsStateError,
        );
      }
      expect((await store.getAll())['flutter.lumo_reward_wallet_v1'], before);
      expect(account.app.hasPendingRewards, isFalse);
    },
  );

  for (final game in ['memory', 'quiz']) {
    test(
      '$game rejects foreign owner, wrong game and malformed round identity',
      () async {
        final account = await _account();
        final valid = _resultId(game, account.lease, 1);
        final parts = valid.split(':');
        final foreign = sha256.convert(utf8.encode('table-child-b')).toString();
        for (final id in [
          '$game:$foreign:${parts.last}',
          '${game == 'memory' ? 'quiz' : 'memory'}:${parts[1]}:${parts.last}',
          '$game:${parts[1]}:short',
          '$valid:extra',
        ]) {
          await expectLater(_award(game, account, id), throwsStateError);
        }
        expect((await store.durableWallet()).toJson(), _initialWallet.toJson());
        expect(account.app.hasPendingRewards, isFalse);
      },
    );

    test(
      '$game cannot pay using a lease captured before a child switch',
      () async {
        final account = await _account();
        final id = _resultId(game, account.lease, 1);
        await account.app.school.setActiveStudent('table-child-b');
        await expectLater(_award(game, account, id), throwsStateError);
        expect((await store.durableWallet()).toJson(), _initialWallet.toJson());
        expect(account.app.hasPendingRewards, isFalse);
      },
    );

    test(
      '$game rechecks its child after waiting for an earlier wallet write',
      () async {
        final account = await _account();
        store.holdNextWalletWrite();
        final older = account.app.recordLumoCardsBonus(
          resultId: 'existing-cards',
        );
        await store.heldWriteEntered!.future.timeout(
          const Duration(seconds: 2),
        );
        final rejected = expectLater(
          _award(game, account, _resultId(game, account.lease, 1)),
          throwsStateError,
        );
        await account.app.school.setActiveStudent('table-child-b');
        store.releaseHeldWrite!.complete();
        await older;
        await rejected;
        final saved = await store.durableWallet();
        expect(saved.stars, 8);
        expect(saved.xp, 40);
        expect(saved.gameResultIds, ['existing-cards']);
        expect(account.app.hasPendingRewards, isFalse);
      },
    );

    test(
      '$game false storage acknowledgement is retryable without double pay',
      () async {
        final account = await _account();
        final id = _resultId(game, account.lease, 1);
        store.failNextWalletWrite = true;
        await expectLater(_award(game, account, id), throwsStateError);
        expect((await store.durableWallet()).toJson(), _initialWallet.toJson());
        expect(account.wallet.snapshot.stars, 7);
        expect(account.app.hasPendingRewards, isTrue);
        await _award(game, account, id);
        final saved = await store.durableWallet();
        expect(saved.stars, 7 + (game == 'memory' ? 2 : 50));
        expect(saved.xp, 40 + (game == 'memory' ? 16 : 0));
        expect(saved.gameResultIds, [id]);
        expect(account.app.hasPendingRewards, isFalse);
        expect(account.app.rewardSaveError, isNull);
      },
    );
  }

  test(
    'Memory and Quiz keep separate result identities for the same round bytes',
    () async {
      final account = await _account();
      final memoryId = _resultId('memory', account.lease, 9);
      final quizId = _resultId('quiz', account.lease, 9);
      await _award('memory', account, memoryId);
      await _award('quiz', account, quizId);
      final saved = await store.durableWallet();
      expect(saved.stars, 59);
      expect(saved.xp, 56);
      expect(saved.gameResultIds, [memoryId, quizId]);
    },
  );
}
