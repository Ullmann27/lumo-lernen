import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/memory/memory_flutter_adapter.dart';
import 'package:lumo_lernen/features/games/memory/memory_round.dart';

const _owner =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _otherOwner =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _legacy = '{"difficulty":"profi","best":{"profi":41}}';
const _otherRound = '{"other-child":"untouched"}';
const _walletKey = 'lumo_reward_wallet_v1';
const _initialWallet = RewardWallet(
  stars: 7,
  xp: 40,
  totalEarnedStars: 19,
  streak: 3,
  lumoCardsWinStreak: 2,
);

class _Account {
  _Account(this.app, this.wallet, this.lease);
  final LumoAppState app;
  final RewardWalletRepository wallet;
  final LearningProfileLease lease;

  String get owner => sha256.convert(utf8.encode(lease.studentId)).toString();
  bool get current => app.canUseLearningLease(lease) &&
      app.profileGeneration == lease.generation &&
      app.school.cachedActiveStudentId == lease.studentId;

  Future<void> award(String id, String difficulty, int kind, int lumo) =>
      app.recordMemoryResult(
        lease: lease,
        resultId: id,
        difficulty: difficulty,
        kindPairs: kind,
        lumoPairs: lumo,
      );
}

enum _Reply { success, falseAfterMemory, throwAfterMemory, throwAfterCommit }

class _Gate {
  final entered = Completer<void>();
  final release = Completer<void>();

  Future<void> wait() async {
    entered.complete();
    await release.future;
  }

  void complete() {
    if (!release.isCompleted) release.complete();
  }
}

/// Models the relevant AOSP SharedPreferencesImpl boundary, not Android itself:
/// commitToMemory precedes the disk attempt, getAll reads native memory, and a
/// successful synchronous retry writes an outstanding generation even when the
/// identical value does not advance that generation. The real Dart preferences,
/// production adapter, controller, rules and profile checks remain in use.
class _NativeCachePlatform extends InMemorySharedPreferencesStore {
  _NativeCachePlatform() : super.withData({}) {
    seed('lumo_memory_v2', _legacy);
    seed('lumo.memory.round.v1.' + _otherOwner, _otherRound);
  }

  final nativeMemory = <String, Object>{};
  final durableDisk = <String, Object>{};
  final writes = <Map<String, Object?>>[];
  final _persistentReplies = <String, _Reply>{};
  final _onceReplies = <String, List<_Reply>>{};
  final _writeGates = <String, _Gate>{};
  final _gates = <_Gate>[];
  _Gate? _readGate;
  int? _readGateAt;
  bool rejectReads = false;
  int reads = 0;
  int memoryGeneration = 0;
  int diskGeneration = 0;
  int diskWrites = 0;
  _Reply Function(String key, Object value)? replyFor;

  void seed(String key, Object value) {
    nativeMemory['flutter.' + key] = value;
    durableDisk['flutter.' + key] = value;
    memoryGeneration++;
    diskGeneration = memoryGeneration;
  }

  void fail(String key, _Reply reply) {
    _persistentReplies['flutter.' + key] = reply;
  }

  void once(String key, _Reply reply) {
    _onceReplies.putIfAbsent('flutter.' + key, () => []).add(reply);
  }

  void accept(String key) {
    _persistentReplies.remove('flutter.' + key);
  }

  String? memory(String key) => nativeMemory['flutter.' + key] as String?;
  String? disk(String key) => durableDisk['flutter.' + key] as String?;

  List<Map<String, Object?>> writesFor(String key) => writes
      .where((row) => row['key'] == 'flutter.' + key)
      .toList();

  _Gate holdRead({int after = 1}) {
    final gate = _Gate();
    _gates.add(gate);
    _readGate = gate;
    _readGateAt = reads + after;
    return gate;
  }

  _Gate holdWrite(String key) {
    final gate = _Gate();
    _gates.add(gate);
    _writeGates['flutter.' + key] = gate;
    return gate;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    reads++;
    if (reads == _readGateAt) {
      final gate = _readGate!;
      _readGate = null;
      _readGateAt = null;
      await gate.wait();
    }
    if (rejectReads) throw StateError('Native snapshot unavailable');
    return Map<String, Object>.from(nativeMemory);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final gate = _writeGates.remove(key);
    if (gate != null) await gate.wait();
    final sequence = _onceReplies[key];
    final reply = sequence != null && sequence.isNotEmpty
        ? sequence.removeAt(0)
        : replyFor?.call(key, value) ??
            _persistentReplies[key] ??
            _Reply.success;
    final changed = nativeMemory[key] != value;
    if (changed) {
      nativeMemory[key] = value;
      memoryGeneration++;
    }
    final behind = diskGeneration < memoryGeneration;
    final commits = reply == _Reply.success || reply == _Reply.throwAfterCommit;
    if (commits && behind) {
      durableDisk
        ..clear()
        ..addAll(nativeMemory);
      diskGeneration = memoryGeneration;
      diskWrites++;
    }
    writes.add({
      'key': key,
      'value': value,
      'reply': reply.name,
      'memory_changed': changed,
      'disk_was_behind': behind,
      'disk_committed': commits && behind,
      'memory_generation': memoryGeneration,
      'disk_generation': diskGeneration,
    });
    switch (reply) {
      case _Reply.success:
        return true;
      case _Reply.falseAfterMemory:
        return false;
      case _Reply.throwAfterMemory:
        throw StateError('Native memory changed; commit was not acknowledged');
      case _Reply.throwAfterCommit:
        throw StateError('Native commit completed; its reply was lost');
    }
  }

  @override
  Future<bool> remove(String key) async {
    nativeMemory.remove(key);
    memoryGeneration++;
    durableDisk
      ..clear()
      ..addAll(nativeMemory);
    diskGeneration = memoryGeneration;
    return true;
  }

  @override
  Future<bool> clear() async {
    nativeMemory.clear();
    durableDisk.clear();
    memoryGeneration++;
    diskGeneration = memoryGeneration;
    return true;
  }

  void restartNativeProcess() {
    nativeMemory
      ..clear()
      ..addAll(durableDisk);
    memoryGeneration = diskGeneration;
  }

  void releaseGates() {
    for (final gate in _gates) {
      gate.complete();
    }
  }
}

Future<Object?> _outcome(Future<Object?> operation) =>
    operation.then<Object?>((value) => value,
        onError: (Object error, StackTrace _) => error);

Future<void> _finish(MemoryRoundController controller) async {
  final cards = List<String>.from(controller.state.cards);
  for (final motif in cards.toSet()) {
    final first = cards.indexOf(motif);
    final second = cards.lastIndexOf(motif);
    if (controller.state.matched[first]) continue;
    expect(await controller.flip(first), isTrue);
    expect(await controller.flip(second), isTrue);
    expect(await controller.advance(850), isTrue);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _NativeCachePlatform platform;
  late SharedPreferences preferences;
  late PreferencesMemoryStore adapter;
  late List<MemoryRoundController> controllers;

  Future<void> newDartPreferences() async {
    // Only the Dart singleton is replaced. Native memory and disk stay distinct.
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = platform;
    preferences = await SharedPreferences.getInstance();
    adapter = PreferencesMemoryStore(preferences, _owner);
  }

  setUp(() async {
    platform = _NativeCachePlatform();
    controllers = [];
    await newDartPreferences();
  });

  tearDown(() {
    for (final controller in controllers) {
      controller.dispose();
    }
    platform.releaseGates();
    SharedPreferences.setMockInitialValues({});
  });

  Future<MemoryRoundController> open({
    bool Function()? current,
    MemoryAward? award,
  }) async {
    final controller = await MemoryRoundController.open(
      owner: _owner,
      catalog: const FlutterMemoryCatalog(),
      store: PreferencesMemoryStore(preferences, _owner),
      canUseProfile: current ?? () => true,
      award: award ?? (_, __, ___, ____) async {},
      difficulty: 'leicht',
      pack: 'alle',
      seed: 73,
    );
    controllers.add(controller);
    return controller;
  }

  void untouchedKeys() {
    expect(platform.disk('lumo_memory_v2'), _legacy);
    expect(platform.memory('lumo_memory_v2'), _legacy);
    expect(platform.disk('lumo.memory.round.v1.' + _otherOwner), _otherRound);
    expect(platform.memory('lumo.memory.round.v1.' + _otherOwner), _otherRound);
  }

  Future<_Account> account({bool selectProfile = true}) async {
    final wallet = RewardWalletRepository();
    await wallet.load();
    final app = LumoAppState(walletRepository: wallet);
    addTearDown(app.dispose);
    if (selectProfile) {
      await app.school.setActiveStudent('memory-commit-child-a');
    }
    return _Account(app, wallet, await app.captureLearningProfile());
  }

  Future<MemoryRoundController> ownedController(
      _Account owner, {MemoryAward? award}) async {
    final controller = await MemoryRoundController.open(
      owner: owner.owner,
      catalog: const FlutterMemoryCatalog(),
      store: PreferencesMemoryStore(preferences, owner.owner),
      canUseProfile: () => owner.current,
      award: award ?? owner.award,
      difficulty: 'leicht',
      pack: 'alle',
      seed: 73,
    );
    controllers.add(controller);
    return controller;
  }

  RewardWallet durableWallet() => RewardWallet.fromJson(
      jsonDecode(platform.disk(_walletKey)!) as Map<String, dynamic>);

  void oneRealReward(String id) {
    final saved = durableWallet();
    expect(saved.stars, 9);
    expect(saved.xp, 56);
    expect(saved.totalEarnedStars, 21);
    expect(saved.streak, 3);
    expect(saved.lumoCardsWinStreak, 2);
    expect(saved.gameResultIds, [id]);
  }

  for (final reply in [_Reply.falseAfterMemory, _Reply.throwAfterMemory]) {
    for (final target in ['round', 'stats']) {
      test(target + ' ' + reply.name +
          ' is unconfirmed while reload remains a read-only native snapshot',
          () async {
        final key = target == 'round' ? adapter.roundKey : adapter.statsKey;
        platform.seed(key, 'old');
        platform.fail(key, reply);
        final result = await _outcome(target == 'round'
            ? adapter.writeRound('attempted')
            : adapter.writeStats('attempted'));
        expect(result, isA<MemoryStorageUnconfirmed>());
        if (reply == _Reply.falseAfterMemory) {
          expect(result, isA<MemoryStorageRejected>());
        } else {
          expect(result, isNot(isA<MemoryStorageRejected>()));
        }
        expect(platform.memory(key), 'attempted');
        expect(platform.disk(key), 'old');
        final count = platform.writes.length;
        expect(await (target == 'round'
            ? adapter.readRound()
            : adapter.readStats()), 'attempted');
        expect(platform.writes.length, count,
            reason: 'Reading may expose a snapshot, never manufacture an ACK.');
        expect(platform.disk(key), 'old');
        untouchedKeys();
      });
    }

    test('Initial ' + reply.name +
        ' requires a positive barrier even after a new Dart store',
        () async {
      platform.fail(adapter.roundKey, reply);
      await expectLater(open(), throwsA(isA<MemoryStorageUnconfirmed>()));
      final candidate = platform.memory(adapter.roundKey)!;
      final parsed = MemoryRound.read(
          candidate, const FlutterMemoryCatalog(), _owner);
      expect(platform.disk(adapter.roundKey), isNull);
      expect(platform.writesFor(adapter.roundKey).length, 2,
          reason: 'One initial write and one bounded recovery barrier.');

      await newDartPreferences();
      final before = platform.writes.length;
      await expectLater(open(), throwsA(isA<MemoryStorageUnconfirmed>()));
      expect(platform.writes.length - before, 1);
      expect(platform.disk(adapter.roundKey), isNull);
      expect(platform.memory(adapter.roundKey), candidate);

      platform.accept(adapter.roundKey);
      final recovered = await open();
      expect(recovered.round.id, parsed.id);
      expect(jsonEncode(recovered.round.toJson()), candidate);
      expect(platform.disk(adapter.roundKey), candidate);
      final confirmation = platform.writesFor(adapter.roundKey).last;
      expect(confirmation['value'], candidate);
      expect(confirmation['memory_changed'], isFalse);
      expect(confirmation['disk_was_behind'], isTrue);
      expect(confirmation['disk_committed'], isTrue);
      untouchedKeys();
    });

    test('Flip ' + reply.name +
        ' and uncertain follow-up cannot expose native cache without ACK',
        () async {
      var awards = 0;
      final controller = await open(award: (_, __, ___, ____) async {
        awards++;
      });
      final previous = controller.round;
      final previousText = platform.disk(adapter.roundKey);
      platform.fail(adapter.roundKey, reply);
      final before = platform.writesFor(adapter.roundKey).length;
      await expectLater(
          controller.flip(0), throwsA(isA<MemoryStorageUnconfirmed>()));
      final candidate = platform.memory(adapter.roundKey)!;
      final parsed = MemoryRound.read(
          candidate, const FlutterMemoryCatalog(), _owner);
      expect(parsed.rules.faceUp[0], isTrue);
      expect(parsed.revision, previous.revision + 1);
      expect(identical(controller.round, previous), isTrue);
      expect(platform.disk(adapter.roundKey), previousText);
      expect(platform.writesFor(adapter.roundKey).length - before, 2);

      final retryBefore = platform.writes.length;
      await expectLater(
          controller.flush(), throwsA(isA<MemoryStorageUnconfirmed>()));
      expect(platform.writes.length - retryBefore, 1);
      expect(identical(controller.round, previous), isTrue);
      expect(platform.disk(adapter.roundKey), previousText);

      platform.accept(adapter.roundKey);
      await controller.flush();
      expect(controller.round.id, previous.id);
      expect(jsonEncode(controller.round.toJson()), candidate,
          reason: 'Retry confirms the original action, not another flip or RNG draw.');
      expect(platform.disk(adapter.roundKey), candidate);
      expect(awards, 0);
      final confirmation = platform.writesFor(adapter.roundKey).last;
      expect(confirmation['value'], candidate);
      expect(confirmation['memory_changed'], isFalse);
      expect(confirmation['disk_committed'], isTrue);
      untouchedKeys();
    });
  }

  test('New controller cannot adopt an unsaved flip from shared native memory',
      () async {
    final first = await open();
    final originalText = platform.disk(adapter.roundKey);
    platform.fail(adapter.roundKey, _Reply.falseAfterMemory);
    await expectLater(
        first.flip(0), throwsA(isA<MemoryStorageUnconfirmed>()));
    final pending = MemoryRound.read(
        platform.memory(adapter.roundKey)!,
        const FlutterMemoryCatalog(), _owner);
    first.dispose();
    await newDartPreferences();
    await expectLater(open(), throwsA(isA<MemoryStorageUnconfirmed>()));
    expect(platform.disk(adapter.roundKey), originalText);

    platform.accept(adapter.roundKey);
    final resumed = await open();
    expect(resumed.round.id, pending.id);
    expect(resumed.state.faceUp[0], isTrue);
    expect(resumed.round.paused, isTrue);
    expect(resumed.state.toJson(), pending.rules.toJson());
    expect(platform.disk(adapter.roundKey), jsonEncode(resumed.round.toJson()));
    untouchedKeys();
  });

  test('Modeled native process restart reloads disk instead of the failed map',
      () async {
    final first = await open();
    final original = platform.disk(adapter.roundKey);
    platform.fail(adapter.roundKey, _Reply.falseAfterMemory);
    await expectLater(
        first.flip(0), throwsA(isA<MemoryStorageUnconfirmed>()));
    first.dispose();
    platform.restartNativeProcess();
    platform.accept(adapter.roundKey);
    await newDartPreferences();
    final reopened = await open();
    expect(reopened.round.id, first.round.id);
    expect(reopened.state.faceUp.every((value) => !value), isTrue);
    expect(platform.disk(adapter.roundKey), original);
    untouchedKeys();
  });

  test('Lost reply after actual commit needs one positive identical retry',
      () async {
    final controller = await open();
    platform.once(adapter.roundKey, _Reply.throwAfterCommit);
    final before = platform.writesFor(adapter.roundKey).length;
    expect(await controller.flip(0), isTrue);
    final attempts = platform.writesFor(adapter.roundKey).skip(before).toList();
    expect(attempts.length, 2);
    expect(attempts[0]['reply'], _Reply.throwAfterCommit.name);
    expect(attempts[1]['reply'], _Reply.success.name);
    expect(attempts[1]['value'], attempts[0]['value']);
    expect(attempts[1]['memory_changed'], isFalse);
    expect(attempts[1]['disk_was_behind'], isFalse);
    expect(controller.state.faceUp.where((value) => value).length, 1);
    expect(platform.disk(adapter.roundKey), jsonEncode(controller.round.toJson()));
    untouchedKeys();
  });

  test('A committed value with no positive reply remains unconfirmed on failure',
      () async {
    final controller = await open();
    final before = controller.round;
    platform.once(adapter.roundKey, _Reply.throwAfterCommit);
    platform.fail(adapter.roundKey, _Reply.falseAfterMemory);
    await expectLater(
        controller.flip(0), throwsA(isA<MemoryStorageUnconfirmed>()));
    final actualCommit = platform.disk(adapter.roundKey)!;
    expect(MemoryRound.read(actualCommit, const FlutterMemoryCatalog(), _owner)
        .rules.faceUp[0], isTrue);
    expect(identical(controller.round, before), isTrue);
    await expectLater(
        controller.flush(), throwsA(isA<MemoryStorageUnconfirmed>()));
    expect(identical(controller.round, before), isTrue);
    platform.accept(adapter.roundKey);
    await controller.flush();
    expect(jsonEncode(controller.round.toJson()), actualCommit);
    untouchedKeys();
  });

  for (final reply in [_Reply.falseAfterMemory, _Reply.throwAfterMemory]) {
    test('Initial statistics ' + reply.name +
        ' is not swallowed as corrupt legacy data', () async {
      final stats = jsonEncode({
        'difficulty': 'leicht',
        'best': {'leicht': 7},
      });
      platform.seed(adapter.statsKey, stats);
      platform.fail(adapter.statsKey, reply);
      await expectLater(open(), throwsA(isA<MemoryStorageUnconfirmed>()));
      expect(platform.writesFor(adapter.statsKey).length, 1);
      expect(platform.writesFor(adapter.roundKey), isEmpty);
      expect(platform.disk(adapter.statsKey), stats);
      untouchedKeys();
    });
  }

  test('Unconfirmed finish statistics blocks reopen instead of skipping stats',
      () async {
    final ids = <String>[];
    final controller = await open(award: (id, _, __, ___) async {
      ids.add(id);
    });
    platform.fail(adapter.statsKey, _Reply.falseAfterMemory);
    await expectLater(
        _finish(controller), throwsA(isA<MemoryStorageUnconfirmed>()));
    expect(controller.state.complete, isTrue);
    expect(controller.round.rewarded, isFalse);
    expect(controller.best, isEmpty);
    expect(platform.disk(adapter.statsKey), isNull);
    expect(platform.memory(adapter.statsKey), isNotNull);
    final roundId = controller.round.id;
    final resultId = controller.round.resultId;
    controller.dispose();
    await newDartPreferences();
    await expectLater(open(award: (id, _, __, ___) async {
      ids.add(id);
    }), throwsA(isA<MemoryStorageUnconfirmed>()));
    expect(ids, [resultId]);
    final stored = MemoryRound.read(
        platform.disk(adapter.roundKey)!,
        const FlutterMemoryCatalog(), _owner);
    expect(stored.rewarded, isFalse);

    platform.accept(adapter.statsKey);
    final resumed = await open(award: (id, _, __, ___) async {
      ids.add(id);
    });
    expect(resumed.round.id, roundId);
    expect(resumed.round.rewarded, isFalse);
    await resumed.settleReward();
    expect(resumed.round.rewarded, isTrue);
    expect(resumed.best, {'leicht': 4});
    expect(ids, [resultId, resultId],
        reason: 'The actual wallet must deduplicate this same result identity.');
    untouchedKeys();
  });

  test('Corrupt historical statistics remain unchanged without a write barrier',
      () async {
    const corrupt = '{"best":{"leicht":"invalid"}}';
    platform.seed(adapter.statsKey, corrupt);
    final controller = await open();
    expect(controller.statsWritable, isFalse);
    expect(platform.writesFor(adapter.statsKey), isEmpty);
    expect(platform.memory(adapter.statsKey), corrupt);
    expect(platform.disk(adapter.statsKey), corrupt);
    untouchedKeys();
  });

  test('Foreign round payload is rejected before any confirming write',
      () async {
    final first = await open();
    first.dispose();
    final foreign = Map<String, Object?>.from(first.round.toJson())
      ..['owner'] = _otherOwner;
    platform.seed(adapter.roundKey, jsonEncode(foreign));
    final before = platform.writes.length;
    await expectLater(open(), throwsFormatException);
    expect(platform.writes.length, before);
    expect(platform.disk(adapter.roundKey), jsonEncode(foreign));
    untouchedKeys();
  });

  for (final target in ['round', 'stats']) {
    test('Profile revocation during ' + target +
        ' snapshot prevents a new confirmation write', () async {
      final first = await open();
      first.dispose();
      if (target == 'stats') {
        platform.seed(adapter.statsKey,
            '{"difficulty":"leicht","best":{"leicht":7}}');
      }
      var current = true;
      final gate = platform.holdRead(after: target == 'stats' ? 1 : 2);
      final before = platform.writes.length;
      final result = _outcome(open(current: () => current));
      try {
        await gate.entered.future.timeout(const Duration(seconds: 2));
        current = false;
      } finally {
        gate.complete();
      }
      expect(await result, isA<StateError>());
      expect(platform.writes.length, before);
      untouchedKeys();
    });
  }

  test('Profile revoked during confirmation cannot expose its late ACK',
      () async {
    final first = await open();
    first.dispose();
    var current = true;
    var awards = 0;
    final gate = platform.holdWrite(adapter.roundKey);
    final before = platform.writes.length;
    final result = _outcome(open(
      current: () => current,
      award: (_, __, ___, ____) async { awards++; },
    ));
    try {
      await gate.entered.future.timeout(const Duration(seconds: 2));
      current = false;
    } finally {
      gate.complete();
    }
    expect(await result, isA<StateError>());
    expect(platform.writes.length - before, 1,
        reason: 'The already accepted old-owner write may complete only once.');
    expect(awards, 0);
    untouchedKeys();
  });

  test('Profile loss on uncertain recovery blocks its confirming retry',
      () async {
    var current = true;
    final controller = await open(current: () => current);
    platform.fail(adapter.roundKey, _Reply.falseAfterMemory);
    await expectLater(
        controller.flip(0), throwsA(isA<MemoryStorageUnconfirmed>()));
    platform.accept(adapter.roundKey);
    final gate = platform.holdRead();
    final before = platform.writes.length;
    final result = _outcome(controller.flush());
    try {
      await gate.entered.future.timeout(const Duration(seconds: 2));
      current = false;
    } finally {
      gate.complete();
    }
    expect(await result, isA<StateError>());
    expect(platform.writes.length, before);
    expect(controller.state.faceUp[0], isFalse);
    untouchedKeys();
  });

  test('Uncertain recovery confirms the observed newer revision exactly',
      () async {
    final controller = await open();
    platform.fail(adapter.roundKey, _Reply.falseAfterMemory);
    await expectLater(
        controller.flip(0), throwsA(isA<MemoryStorageUnconfirmed>()));
    final pending = MemoryRound.read(
        platform.memory(adapter.roundKey)!,
        const FlutterMemoryCatalog(), _owner);
    final newer = pending.copy(const FlutterMemoryCatalog(), paused: true);
    final text = jsonEncode(newer.toJson());
    platform.accept(adapter.roundKey);
    await adapter.writeRound(text);
    final before = platform.writesFor(adapter.roundKey).length;
    await controller.flush();
    final confirmations =
        platform.writesFor(adapter.roundKey).skip(before).toList();
    expect(confirmations.length, 1);
    expect(confirmations.single['value'], text);
    expect(jsonEncode(controller.round.toJson()), text);
    expect(controller.round.paused, isTrue);
    expect(platform.disk(adapter.roundKey), text);
    untouchedKeys();
  });

  for (final target in ['stats', 'rewarded receipt']) {
    test('Real AppState reward stays once after unconfirmed ' + target,
        () async {
      platform.seed(_walletKey, jsonEncode(_initialWallet.toJson()));
      await preferences.reload();
      final owner = await account();
      final controller = await ownedController(owner);
      final store = PreferencesMemoryStore(preferences, owner.owner);
      final id = controller.round.resultId;
      final roundId = controller.round.id;
      var block = true;
      platform.replyFor = (key, value) {
        if (!block) return _Reply.success;
        if (target == 'stats' && key == 'flutter.' + store.statsKey) {
          return _Reply.falseAfterMemory;
        }
        if (target == 'rewarded receipt' &&
            key == 'flutter.' + store.roundKey &&
            (jsonDecode(value as String) as Map)['rewarded'] == true) {
          return _Reply.falseAfterMemory;
        }
        return _Reply.success;
      };

      await expectLater(
          _finish(controller), throwsA(isA<MemoryStorageUnconfirmed>()));
      expect(controller.state.complete, isTrue);
      expect(controller.round.rewarded, isFalse);
      expect(controller.round.id, roundId);
      oneRealReward(id);
      expect(owner.wallet.snapshot.gameResultIds, [id]);
      final failedSnapshot = platform.memory(
          target == 'stats' ? store.statsKey : store.roundKey);
      expect(failedSnapshot, isNotNull);
      // A newly constructed controller must not skip an unconfirmed statistic
      // or accept a native-cache receipt without its own positive barrier.
      await expectLater(
          ownedController(owner), throwsA(isA<MemoryStorageUnconfirmed>()));
      oneRealReward(id);
      expect(controller.round.rewarded, isFalse);

      block = false;
      await controller.settleReward();
      expect(controller.round.id, roundId);
      expect(controller.round.rewarded, isTrue);
      expect(controller.best, {'leicht': 4});
      oneRealReward(id);
      controller.dispose();
      final next = await ownedController(owner);
      expect(next.round.id, isNot(roundId));
      expect(next.state.complete, isFalse);
      expect(next.state.difficulty, 'leicht');
      expect(next.best, {'leicht': 4});
      oneRealReward(id);
      untouchedKeys();
    });
  }

  test('Real completed Memory cannot accept an unconfirmed duplicate wallet ID',
      () async {
    platform.seed(_walletKey, jsonEncode(_initialWallet.toJson()));
    await preferences.reload();
    final firstAccount = await account();
    var deliveryAccount = firstAccount;
    final controller = await ownedController(
      firstAccount,
      award: (id, difficulty, kind, lumo) =>
          deliveryAccount.award(id, difficulty, kind, lumo),
    );
    final store = PreferencesMemoryStore(preferences, firstAccount.owner);
    final id = controller.round.resultId;
    platform.fail(_walletKey, _Reply.falseAfterMemory);
    await expectLater(_finish(controller), throwsStateError);
    expect(controller.state.complete, isTrue);
    expect(controller.round.rewarded, isFalse);
    expect(durableWallet().stars, 7);
    expect(durableWallet().xp, 40);
    expect(durableWallet().gameResultIds, isEmpty);
    final optimistic = RewardWallet.fromJson(
        jsonDecode(platform.memory(_walletKey)!) as Map<String, dynamic>);
    expect(optimistic.gameResultIds, [id]);

    // A fresh real AppState/Wallet may load the same native optimistic value.
    // Keep the existing controller and selection; no successful preference
    // write is allowed to incidentally persist the dirty whole-file snapshot.
    final beforeNewAccount = platform.writes.length;
    deliveryAccount = await account(selectProfile: false);
    expect(deliveryAccount.owner, firstAccount.owner);
    expect(platform.writes.length, beforeNewAccount);
    expect(deliveryAccount.wallet.snapshot.gameResultIds, [id]);
    final statsBefore = platform.writesFor(store.statsKey).length;
    final roundBefore = platform.writesFor(store.roundKey).length;
    await expectLater(controller.settleReward(), throwsStateError);
    expect(platform.writesFor(store.statsKey).length, statsBefore);
    expect(platform.writesFor(store.roundKey).length, roundBefore);
    expect(controller.round.rewarded, isFalse);
    expect(durableWallet().stars, 7);
    expect(durableWallet().gameResultIds, isEmpty);

    platform.accept(_walletKey);
    await controller.settleReward();
    expect(controller.round.rewarded, isTrue);
    expect(controller.best, {'leicht': 4});
    oneRealReward(id);
    untouchedKeys();
  });
}
