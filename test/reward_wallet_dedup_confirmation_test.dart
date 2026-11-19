import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';

const _walletKey = 'lumo_reward_wallet_v1';
const _platformWalletKey = 'flutter.$_walletKey';
const _otherKey = 'flutter.lumo.memory.round.v1.other-owner-fixture';
const _otherValue = '{"unchanged":"other-owner-fixture"}';
const _owner =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _round = '0123456789abcdef0123456789abcdef';
const _initialWallet = RewardWallet(
  stars: 7,
  xp: 40,
  totalEarnedStars: 19,
  streak: 3,
  lumoCardsWinStreak: 2,
);

enum _Reply { success, falseAfterMemory, throwAfterMemory, throwAfterCommit }

enum _Award { game, quiz, cards }

class _Gate {
  final entered = Completer<void>();
  final released = Completer<void>();

  void release() {
    if (!released.isCompleted) released.complete();
  }
}

/// Synthetic platform boundary, not an Android disk-failure experiment.
/// The real Dart SharedPreferences cache remains in use. Native memory changes
/// before the disk result, getAll reads that memory, and a successful commit
/// copies the entire preference file. An identical retry can commit an already
/// outstanding generation without changing native memory again.
class _NativeCachePlatform extends InMemorySharedPreferencesStore {
  _NativeCachePlatform() : super.withData({}) {
    nativeMemory[_otherKey] = _otherValue;
    seedWallet(_initialWallet);
  }

  final nativeMemory = <String, Object>{};
  final durableDisk = <String, Object>{};
  final walletPayloads = <String>[];
  final _gates = <_Gate>[];
  _Gate? _nextWalletGate;
  _Reply walletReply = _Reply.success;
  int writes = 0;
  int positiveWalletReplies = 0;
  int memoryGeneration = 0;
  int diskGeneration = 0;
  int diskWrites = 0;

  void seedWallet(RewardWallet wallet) {
    nativeMemory[_platformWalletKey] = jsonEncode(wallet.toJson());
    durableDisk
      ..clear()
      ..addAll(nativeMemory);
    memoryGeneration = 0;
    diskGeneration = 0;
  }

  _Gate holdNextWalletWrite() {
    final gate = _Gate();
    _gates.add(gate);
    _nextWalletGate = gate;
    return gate;
  }

  RewardWallet get memoryWallet => _decode(nativeMemory);
  RewardWallet get diskWallet => _decode(durableDisk);

  RewardWallet _decode(Map<String, Object> source) => RewardWallet.fromJson(
        jsonDecode(source[_platformWalletKey] as String)
            as Map<String, dynamic>,
      );

  void _commitFile() {
    if (diskGeneration >= memoryGeneration) return;
    durableDisk
      ..clear()
      ..addAll(nativeMemory);
    diskGeneration = memoryGeneration;
    diskWrites++;
  }

  @override
  Future<Map<String, Object>> getAll() async =>
      Map<String, Object>.from(nativeMemory);

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    final isWallet = key == _platformWalletKey;
    if (isWallet) {
      walletPayloads.add(value as String);
      final gate = _nextWalletGate;
      _nextWalletGate = null;
      if (gate != null) {
        gate.entered.complete();
        await gate.released.future;
      }
    }
    if (nativeMemory[key] != value) {
      nativeMemory[key] = value;
      memoryGeneration++;
    }
    final reply = isWallet ? walletReply : _Reply.success;
    if (reply == _Reply.success || reply == _Reply.throwAfterCommit) {
      _commitFile();
    }
    switch (reply) {
      case _Reply.success:
        if (isWallet) positiveWalletReplies++;
        return true;
      case _Reply.falseAfterMemory:
        return false;
      case _Reply.throwAfterMemory:
        throw StateError('Native memory changed; disk commit was not confirmed');
      case _Reply.throwAfterCommit:
        throw StateError('Disk commit completed; the positive reply was lost');
    }
  }

  @override
  Future<bool> remove(String key) async {
    writes++;
    if (nativeMemory.remove(key) != null) memoryGeneration++;
    _commitFile();
    return true;
  }

  @override
  Future<bool> clear() async {
    writes++;
    if (nativeMemory.isNotEmpty) memoryGeneration++;
    nativeMemory.clear();
    _commitFile();
    return true;
  }

  void restartFromDisk() {
    nativeMemory
      ..clear()
      ..addAll(durableDisk);
    memoryGeneration = diskGeneration;
    SharedPreferences.resetStatic();
  }

  void releaseGates() {
    for (final gate in _gates) {
      gate.release();
    }
  }
}

String _id(_Award award) => '${switch (award) {
      _Award.game => 'memory',
      _Award.quiz => 'quiz',
      _Award.cards => 'cards',
    }}:$_owner:$_round';

RewardWallet _awarded(_Award award, {String? id}) {
  final resultId = id ?? _id(award);
  return switch (award) {
    _Award.game => RewardWallet(
        stars: 9,
        xp: 56,
        totalEarnedStars: 21,
        streak: 3,
        lumoCardsWinStreak: 2,
        gameResultIds: [resultId],
      ),
    _Award.quiz => RewardWallet(
        stars: 57,
        xp: 40,
        totalEarnedStars: 69,
        streak: 3,
        lumoCardsWinStreak: 2,
        gameResultIds: [resultId],
      ),
    _Award.cards => RewardWallet(
        stars: 12,
        xp: 70,
        totalEarnedStars: 24,
        streak: 3,
        lumoCardsWinStreak: 3,
        gameResultIds: [resultId],
      ),
  };
}

Future<RewardWallet> _deliver(RewardWalletRepository wallet, _Award award) =>
    switch (award) {
      _Award.game => wallet.awardGameResult(
          resultId: _id(award), stars: 2, xp: 16),
      _Award.quiz => wallet.awardQuizResult(resultId: _id(award), stars: 50),
      _Award.cards =>
        wallet.awardLumoCardsResult(resultId: _id(award), won: true),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NativeCachePlatform platform;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = _NativeCachePlatform();
    SharedPreferencesStorePlatform.instance = platform;
  });

  tearDown(() {
    platform.releaseGates();
    SharedPreferences.setMockInitialValues({});
  });

  for (final award in _Award.values) {
    test('${award.name}: known result waits for a positive duplicate commit',
        () async {
      final expected = _awarded(award);
      platform.seedWallet(expected);
      final wallet = RewardWalletRepository();
      final before = await wallet.load();
      final events = <RewardWallet>[];
      final subscription = wallet.changes.listen(events.add);
      addTearDown(subscription.cancel);
      final gate = platform.holdNextWalletWrite();
      var acknowledged = false;
      final result = _deliver(wallet, award).then((value) {
        acknowledged = true;
        return value;
      });
      await gate.entered.future.timeout(const Duration(seconds: 2));
      expect(acknowledged, isFalse);
      expect(wallet.snapshot, same(before));
      expect(platform.positiveWalletReplies, 0);
      gate.release();
      expect(await result, same(before));
      await Future<void>.delayed(Duration.zero);
      expect(platform.positiveWalletReplies, 1);
      expect(platform.walletPayloads, [jsonEncode(expected.toJson())]);
      expect(platform.diskWallet.toJson(), expected.toJson());
      expect(events, isEmpty);
      expect(platform.durableDisk[_otherKey], _otherValue);
    });

    for (final fault in [
      _Reply.falseAfterMemory,
      _Reply.throwAfterMemory,
      _Reply.throwAfterCommit,
    ]) {
      test('${award.name}: ${fault.name} stays unconfirmed in a new wallet',
          () async {
        final first = RewardWalletRepository();
        await first.load();
        final expected = _awarded(award);
        platform.walletReply = fault;
        await expectLater(_deliver(first, award), throwsStateError);
        expect(first.snapshot.toJson(), _initialWallet.toJson());
        expect(platform.memoryWallet.toJson(), expected.toJson());
        expect(
          platform.diskWallet.toJson(),
          fault == _Reply.throwAfterCommit
              ? expected.toJson()
              : _initialWallet.toJson(),
        );
        expect(platform.positiveWalletReplies, 0);

        // Recreate Dart preferences and the repository, but retain native mMap.
        // A successful reload still reads optimistic native memory, not disk.
        SharedPreferences.resetStatic();
        final preferences = await SharedPreferences.getInstance();
        await preferences.reload();
        expect(preferences.getString(_walletKey),
            platform.nativeMemory[_platformWalletKey]);
        final writesBeforeLoad = platform.writes;
        final reopened = RewardWalletRepository();
        final loaded = await reopened.load();
        expect(loaded.toJson(), expected.toJson());
        expect(platform.writes, writesBeforeLoad);
        final events = <RewardWallet>[];
        final subscription = reopened.changes.listen(events.add);
        addTearDown(subscription.cancel);

        await expectLater(_deliver(reopened, award), throwsStateError);
        expect(platform.walletPayloads, hasLength(2));
        expect(platform.positiveWalletReplies, 0);
        expect(reopened.snapshot, same(loaded));
        expect(
          platform.diskWallet.toJson(),
          fault == _Reply.throwAfterCommit
              ? expected.toJson()
              : _initialWallet.toJson(),
        );

        platform.walletReply = _Reply.success;
        expect(await _deliver(reopened, award), same(loaded));
        await Future<void>.delayed(Duration.zero);
        expect(platform.walletPayloads, hasLength(3));
        expect(platform.walletPayloads.toSet(), {jsonEncode(expected.toJson())});
        expect(platform.positiveWalletReplies, 1);
        expect(platform.diskWallet.toJson(), expected.toJson());
        expect(platform.diskWallet.gameResultIds, [_id(award)]);
        expect(events, isEmpty);
        expect(platform.durableDisk[_otherKey], _otherValue);

        platform.restartFromDisk();
        final cold = await RewardWalletRepository().load();
        expect(cold.toJson(), expected.toJson());
        expect(platform.walletPayloads, hasLength(3));
      });
    }
  }

  for (final fault in [_Reply.falseAfterMemory, _Reply.throwAfterMemory]) {
    test('AppState ${fault.name}: fresh wallet cannot clear an unsaved result',
        () async {
      final wallet = RewardWalletRepository();
      await wallet.load();
      final app = LumoAppState(walletRepository: wallet);
      addTearDown(app.dispose);
      await app.school.setActiveStudent('wallet-confirmation-child');
      final lease = await app.captureLearningProfile();
      final owner = sha256.convert(utf8.encode(lease.studentId)).toString();
      final resultId = 'memory:$owner:$_round';
      final expected = _awarded(_Award.game, id: resultId);
      platform.walletReply = fault;
      await expectLater(
        app.recordMemoryResult(
          lease: lease,
          resultId: resultId,
          difficulty: 'leicht',
          kindPairs: 4,
          lumoPairs: 0,
        ),
        throwsStateError,
      );
      expect(app.hasPendingRewards, isTrue);
      expect(app.rewardSaveError, isNotNull);
      expect(wallet.snapshot.toJson(), _initialWallet.toJson());
      expect(platform.memoryWallet.toJson(), expected.toJson());
      expect(platform.diskWallet.toJson(), _initialWallet.toJson());

      // Do not set the profile again: any unrelated positive preference commit
      // could legitimately flush the entire outstanding native-memory file.
      final writesAfterFailure = platform.writes;
      SharedPreferences.resetStatic();
      final reopenedWallet = RewardWalletRepository();
      final reopened = LumoAppState(walletRepository: reopenedWallet);
      addTearDown(reopened.dispose);
      final reopenedLease = await reopened.captureLearningProfile();
      expect(reopenedLease.studentId, lease.studentId);
      expect(platform.writes, writesAfterFailure);
      await expectLater(
        reopened.recordMemoryResult(
          lease: reopenedLease,
          resultId: resultId,
          difficulty: 'leicht',
          kindPairs: 4,
          lumoPairs: 0,
        ),
        throwsStateError,
      );
      expect(platform.writes, writesAfterFailure + 1);
      expect(reopened.hasPendingRewards, isTrue);
      expect(reopened.rewardSaveError, isNotNull);
      expect(platform.diskWallet.toJson(), _initialWallet.toJson());
      expect(platform.positiveWalletReplies, 0);

      platform.walletReply = _Reply.success;
      await reopened.retryRewards();
      expect(reopened.hasPendingRewards, isFalse);
      expect(reopened.rewardSaveError, isNull);
      expect(reopened.state.stars, 9);
      expect(reopened.state.xp, 56);
      expect(platform.diskWallet.toJson(), expected.toJson());
      expect(platform.diskWallet.gameResultIds, [resultId]);
      expect(platform.positiveWalletReplies, 1);
      expect(platform.walletPayloads, hasLength(3));
      expect(platform.durableDisk[_otherKey], _otherValue);
      platform.restartFromDisk();
      expect((await RewardWalletRepository().load()).toJson(), expected.toJson());
    });
  }
}
