import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/core/reward_wallet_repository.dart';

const _walletKey = 'lumo_reward_wallet_v1';

/// Holds only the originating zone's real microtasks. A later caller runs in
/// the ordinary test zone, independently of whether this queue is pumped.
class _HeldMicrotasks {
  _HeldMicrotasks() {
    _zone = Zone.current.fork(
      specification: ZoneSpecification(
        scheduleMicrotask: (self, parent, zone, callback) {
          _callbacks.add(() => zone.run(callback));
        },
      ),
    );
  }

  late final Zone _zone;
  final _callbacks = <void Function()>[];

  int get pending => _callbacks.length;

  T run<T>(T Function() body) => _zone.run(body);

  void drain() {
    var remaining = 1000;
    while (_callbacks.isNotEmpty && remaining-- > 0) {
      _callbacks.removeAt(0)();
    }
    expect(_callbacks, isEmpty, reason: 'The controlled queue must be bounded.');
  }

  Future<void> settle() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      drain();
      // Allow the real Preferences stub's ordinary-zone continuations to run.
      await Future<void>.delayed(Duration.zero);
      if (_callbacks.isEmpty) return;
    }
    fail('The original zone did not settle within 50 event-loop turns.');
  }
}

/// A real SharedPreferences platform store with explicit durability barriers.
/// The repository and its transaction implementation are never mocked.
class _GatedStore extends InMemorySharedPreferencesStore {
  _GatedStore({this.gates = const <int, Completer<bool>>{}})
      : super.withData({
          'flutter.$_walletKey':
              jsonEncode(const RewardWallet().toJson()),
        });

  final Map<int, Completer<bool>> gates;
  final writes = <Map<String, dynamic>>[];
  final _started = <int, Completer<void>>{};

  Future<void> started(int number) =>
      _started.putIfAbsent(number, Completer<void>.new).future;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key != 'flutter.$_walletKey') {
      throw StateError('Unexpected Preferences write: $key');
    }
    final number = writes.length + 1;
    writes.add(jsonDecode(value as String) as Map<String, dynamic>);
    _started.putIfAbsent(number, Completer<void>.new).complete();
    final gate = gates[number];
    if (gate != null && !await gate.future) return false;
    return super.setValue(valueType, key, value);
  }

  Future<Map<String, dynamic>> persisted() async =>
      jsonDecode((await getAll())['flutter.$_walletKey'] as String)
          as Map<String, dynamic>;
}

/// Capture the failure before resuming the old zone. Resuming is only cleanup:
/// it lets the unchanged broken repository fail an assertion instead of hanging.
Future<RewardWallet> _fromCurrentZone(
  _HeldMicrotasks oldZone,
  Future<RewardWallet> Function() operation,
) async {
  expect(oldZone.pending, 0);
  var completed = false;
  final result = operation();
  final observed = result.then<void>(
    (_) => completed = true,
    onError: (Object _, StackTrace __) => completed = true,
  );
  await Future<void>.delayed(Duration.zero);
  final completedWithoutOldZone = completed;
  final scheduledOnOldZone = oldZone.pending;
  await oldZone.settle();
  await observed;
  final value = await result;
  expect(scheduledOnOldZone, 0,
      reason: 'An idle wallet must not retain the previous caller\'s zone.');
  expect(completedWithoutOldZone, isTrue,
      reason: 'A new transaction must complete without pumping an old zone.');
  return value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      _walletKey: jsonEncode(const RewardWallet().toJson()),
    });
  });

  test('An unused wallet constructed in another zone starts in its caller zone',
      () async {
    final constructionZone = _HeldMicrotasks();
    final wallet = constructionZone.run(RewardWalletRepository.new);
    constructionZone.drain();
    await wallet.load();

    final saved = await _fromCurrentZone(
      constructionZone,
      () => wallet.awardGameResult(
        resultId: 'first-memory-round',
        stars: 2,
        xp: 16,
      ),
    );
    expect(saved.stars, 2);
    expect(saved.xp, 16);
    expect(saved.gameResultIds, ['first-memory-round']);
    final reopened = await RewardWalletRepository().load();
    expect(reopened.toJson(), saved.toJson());
  });

  test('A fully committed wallet tail releases its completed originating zone',
      () async {
    final wallet = RewardWalletRepository();
    await wallet.load();
    final originalZone = _HeldMicrotasks();
    RewardWallet? first;
    Object? firstError;
    originalZone.run(() {
      unawaited(wallet
          .awardGameResult(resultId: 'round-one', stars: 2, xp: 16)
          .then<void>((value) => first = value,
              onError: (Object error, StackTrace _) => firstError = error));
    });
    await originalZone.settle();
    expect(firstError, isNull);
    expect(first?.gameResultIds, ['round-one']);

    final second = await _fromCurrentZone(
      originalZone,
      () => wallet.awardGameResult(
        resultId: 'round-two',
        stars: 3,
        xp: 24,
      ),
    );
    expect(second.stars, 5);
    expect(second.xp, 40);
    expect(second.gameResultIds, ['round-one', 'round-two']);
    final replay = await wallet.awardGameResult(
      resultId: 'round-one',
      stars: 2,
      xp: 16,
    );
    expect(replay.toJson(), second.toJson());
    final reopened = await RewardWalletRepository().load();
    expect(reopened.toJson(), second.toJson());
  });

  test('A failed durable write releases its zone and the exact reward can retry',
      () async {
    final rejectedWrite = Completer<bool>()..complete(false);
    final store = _GatedStore(gates: {1: rejectedWrite});
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();
    final originalZone = _HeldMicrotasks();
    Object? failure;
    var incorrectlySucceeded = false;
    originalZone.run(() {
      unawaited(wallet
          .awardGameResult(resultId: 'retry-round', stars: 2, xp: 16)
          .then<void>((_) => incorrectlySucceeded = true,
              onError: (Object error, StackTrace _) => failure = error));
    });
    await originalZone.settle();
    expect(incorrectlySucceeded, isFalse);
    expect(failure, isA<StateError>());
    expect(wallet.snapshot.stars, 0);
    expect(wallet.snapshot.gameResultIds, isEmpty);
    expect((await store.persisted())['stars'], 0);

    final retried = await _fromCurrentZone(
      originalZone,
      () => wallet.awardGameResult(
        resultId: 'retry-round',
        stars: 2,
        xp: 16,
      ),
    );
    expect(retried.stars, 2);
    expect(retried.xp, 16);
    expect(retried.gameResultIds, ['retry-round']);
    expect(store.writes, [retried.toJson(), retried.toJson()]);
    final replayEvents = <RewardWallet>[];
    final replaySubscription = wallet.changes.listen(replayEvents.add);
    try {
      final replay = await wallet.awardGameResult(
        resultId: 'retry-round',
        stars: 2,
        xp: 16,
      );
      await Future<void>.delayed(Duration.zero);
      expect(replay.toJson(), retried.toJson());
      expect(store.writes,
          [retried.toJson(), retried.toJson(), retried.toJson()]);
      expect(replayEvents, isEmpty);
      expect(await store.persisted(), retried.toJson());
    } finally {
      await replaySubscription.cancel();
    }
  });

  test('An older completion cannot release a younger pending durable write',
      () async {
    final firstGate = Completer<bool>();
    final secondGate = Completer<bool>();
    final store = _GatedStore(gates: {1: firstGate, 2: secondGate});
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();

    final first = wallet.awardGameResult(
      resultId: 'first',
      stars: 3,
      xp: 24,
    );
    await store.started(1);
    var secondAcknowledged = false;
    final second = wallet
        .awardGameResult(resultId: 'second', stars: 5, xp: 40)
        .then((value) {
      secondAcknowledged = true;
      return value;
    });
    expect(store.writes, hasLength(1));
    expect(wallet.snapshot.gameResultIds, isEmpty);
    firstGate.complete(true);
    await store.started(2);
    await first;

    var thirdAcknowledged = false;
    final third = wallet
        .awardGameResult(resultId: 'third', stars: 2, xp: 16)
        .then((value) {
      thirdAcknowledged = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    final writesBeforeSecondCommit = store.writes.length;
    final acknowledgedBeforeSecondCommit =
        secondAcknowledged || thirdAcknowledged;
    final visibleBeforeSecondCommit = wallet.snapshot.toJson();
    secondGate.complete(true);
    await Future.wait([second, third]);

    expect(writesBeforeSecondCommit, 2,
        reason: 'The third write must wait for the second durability barrier.');
    expect(acknowledgedBeforeSecondCommit, isFalse);
    expect(visibleBeforeSecondCommit['stars'], 3);
    expect(visibleBeforeSecondCommit['gameResultIds'], ['first']);
    expect(
      store.writes
          .map((entry) => [entry['stars'], entry['xp'], entry['gameResultIds']])
          .toList(),
      [
        [3, 24, ['first']],
        [8, 64, ['first', 'second']],
        [10, 80, ['first', 'second', 'third']],
      ],
    );
    expect(wallet.snapshot.stars, 10);
    expect(wallet.snapshot.totalEarnedStars, 10);
    expect(wallet.snapshot.xp, 80);
    expect(await store.persisted(), wallet.snapshot.toJson());
    final writesBeforeReplay = List<Map<String, dynamic>>.of(store.writes);
    expect(writesBeforeReplay, hasLength(3));
    final confirmed = wallet.snapshot.toJson();
    final reopened = RewardWalletRepository();
    final replayEvents = <RewardWallet>[];
    final replaySubscription = reopened.changes.listen(replayEvents.add);
    try {
      final replay = await reopened.awardGameResult(
        resultId: 'second',
        stars: 5,
        xp: 40,
      );
      await Future<void>.delayed(Duration.zero);
      expect(replay.stars, 10);
      expect(replay.gameResultIds, ['first', 'second', 'third']);
      expect(replay.toJson(), confirmed);
      expect(store.writes, [...writesBeforeReplay, confirmed]);
      expect(await store.persisted(), confirmed);
      expect(replayEvents, isEmpty);
    } finally {
      await replaySubscription.cancel();
    }
  });
}
