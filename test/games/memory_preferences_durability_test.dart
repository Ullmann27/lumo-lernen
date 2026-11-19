import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/features/games/memory/memory_flutter_adapter.dart';
import 'package:lumo_lernen/features/games/memory/memory_round.dart';

const _ownerA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _ownerB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _legacy = '{"difficulty":"profi","best":{"profi":41}}';

enum _WriteFault { falseBeforeCommit, throwBeforeCommit, throwAfterCommit }

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

/// Only the platform boundary is replaced. SharedPreferences keeps its real
/// optimistic cache, and the production adapter/controller perform every read,
/// write, profile check, state transition and reward acknowledgement.
class _PlatformStore extends InMemorySharedPreferencesStore {
  _PlatformStore()
      : super.withData({'flutter.lumo_memory_v2': _legacy});

  final faults = <String, _WriteFault>{};
  final writeGates = <String, _Gate>{};
  final gates = <_Gate>[];
  _Gate? readGate;
  bool rejectReads = false;
  bool rejectReadsAfterFault = false;
  int reads = 0;
  int writes = 0;

  _Gate holdRead() {
    final gate = _Gate();
    gates.add(gate);
    readGate = gate;
    return gate;
  }

  _Gate holdWrite(String key) {
    final gate = _Gate();
    gates.add(gate);
    writeGates['flutter.$key'] = gate;
    return gate;
  }

  void failWrite(String key, _WriteFault fault) {
    faults['flutter.$key'] = fault;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    reads++;
    final gate = readGate;
    readGate = null;
    if (gate != null) await gate.wait();
    if (rejectReads) throw StateError('Platform read failed');
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    final gate = writeGates.remove(key);
    if (gate != null) await gate.wait();
    final fault = faults.remove(key);
    if (fault != null && rejectReadsAfterFault) {
      rejectReads = true;
      rejectReadsAfterFault = false;
    }
    switch (fault) {
      case _WriteFault.falseBeforeCommit:
        return false;
      case _WriteFault.throwBeforeCommit:
        throw StateError('Platform rejected write before commit');
      case _WriteFault.throwAfterCommit:
        await super.setValue(valueType, key, value);
        throw StateError('Platform reply lost after commit');
      case null:
        return super.setValue(valueType, key, value);
    }
  }

  /// Independent test-backend state; bypasses the adapter and its Dart cache.
  Future<Map<String, Object>> persisted() => super.getAll();

  void releaseGates() {
    for (final gate in gates) {
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

  late _PlatformStore platform;
  late SharedPreferences preferences;
  late PreferencesMemoryStore adapter;
  late List<MemoryRoundController> controllers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    platform = _PlatformStore();
    SharedPreferencesStorePlatform.instance = platform;
    preferences = await SharedPreferences.getInstance();
    adapter = PreferencesMemoryStore(preferences, _ownerA);
    controllers = [];
  });

  tearDown(() {
    for (final controller in controllers) {
      controller.dispose();
    }
    platform.releaseGates();
    SharedPreferences.setMockInitialValues({});
  });

  Future<MemoryRoundController> open({
    String owner = _ownerA,
    bool Function()? current,
    MemoryAward? award,
  }) async {
    final controller = await MemoryRoundController.open(
      owner: owner,
      catalog: const FlutterMemoryCatalog(),
      store: PreferencesMemoryStore(preferences, owner),
      canUseProfile: current ?? () => true,
      award: award ?? (_, __, ___, ____) async {},
      difficulty: 'leicht',
      pack: 'alle',
      seed: 73,
    );
    controllers.add(controller);
    return controller;
  }

  Future<String?> raw(String key) async =>
      (await platform.persisted())['flutter.$key'] as String?;

  test('Rejected initial round is not accepted from the optimistic cache',
      () async {
    platform.failWrite(adapter.roundKey, _WriteFault.falseBeforeCommit);
    await expectLater(open(), throwsStateError);
    expect(await raw(adapter.roundKey), isNull);
    expect(await adapter.readRound(), isNull);
    expect(await raw('lumo_memory_v2'), _legacy);

    final recovered = await open();
    expect(recovered.state.faceUp.every((value) => !value), isTrue);
    expect(await raw(adapter.roundKey), jsonEncode(recovered.round.toJson()));
  });

  for (final fault in [
    _WriteFault.falseBeforeCommit,
    _WriteFault.throwBeforeCommit,
  ]) {
    test('Round ' + fault.name + ' cannot acknowledge an unsaved flip',
        () async {
      final controller = await open();
      final before = await raw(adapter.roundKey);
      final previousRound = controller.round;
      platform.failWrite(adapter.roundKey, fault);

      await expectLater(controller.flip(0), throwsStateError);

      expect(identical(controller.round, previousRound), isTrue);
      expect(controller.state.faceUp[0], isFalse);
      expect(await raw(adapter.roundKey), before);
      controller.dispose();
      final reopened = await open();
      expect(reopened.round.id, previousRound.id);
      expect(reopened.state.faceUp[0], isFalse);
      expect(await raw('lumo_memory_v2'), _legacy);
    });

    for (final target in ['round', 'stats']) {
      test(target + ' ' + fault.name +
          ' stays untrusted across failed reloads and new instances', () async {
        final controller = await open();
        final oldStats = jsonEncode({
          'difficulty': 'leicht',
          'best': {'leicht': 7},
        });
        await adapter.writeStats(oldStats);
        final key = target == 'round' ? adapter.roundKey : adapter.statsKey;
        final before = await raw(key);
        final changedRound = Map<String, Object?>.from(controller.round.toJson())
          ..['revision'] = controller.round.revision + 1
          ..['paused'] = true;
        final attempted = target == 'round'
            ? jsonEncode(changedRound)
            : jsonEncode({
                'difficulty': 'profi',
                'best': {'profi': 1},
              });
        platform.failWrite(key, fault);
        platform.rejectReadsAfterFault = true;

        await expectLater(
          target == 'round'
              ? adapter.writeRound(attempted)
              : adapter.writeStats(attempted),
          throwsStateError,
        );
        expect(preferences.getString(key), attempted,
            reason: 'The real legacy Preferences cache changed before failure.');
        expect(await raw(key), before,
            reason: 'The independent platform backend did not commit.');

        final secondPreferences = await SharedPreferences.getInstance();
        expect(identical(secondPreferences, preferences), isTrue);
        final reopenedStore = PreferencesMemoryStore(secondPreferences, _ownerA);
        for (final store in [adapter, reopenedStore]) {
          await expectLater(store.readRound(), throwsStateError);
          await expectLater(store.readStats(), throwsStateError);
          await expectLater(
            target == 'round' ? store.readRound() : store.readStats(),
            throwsStateError,
          );
        }
        await expectLater(open(), throwsStateError,
            reason: 'A fresh controller cannot adopt the same poisoned cache.');

        platform.rejectReads = false;
        expect(await (target == 'round'
            ? reopenedStore.readRound()
            : reopenedStore.readStats()), before);
        controller.dispose();
        final recovered = await open();
        expect(recovered.round.id, controller.round.id);
        expect(recovered.state.faceUp.every((value) => !value), isTrue);
        expect(recovered.best, {'leicht': 7});
        expect(await raw('lumo_memory_v2'), _legacy);
      });
    }
  }

  test('Actual round commit followed by a lost reply is recovered from platform',
      () async {
    final controller = await open();
    platform.failWrite(adapter.roundKey, _WriteFault.throwAfterCommit);
    expect(await controller.flip(0), isTrue);
    expect(controller.state.faceUp[0], isTrue);
    expect(await raw(adapter.roundKey), jsonEncode(controller.round.toJson()));

    controller.dispose();
    final reopened = await open();
    expect(reopened.round.id, controller.round.id);
    expect(reopened.round.paused, isTrue);
    expect(reopened.state.faceUp[0], isTrue);
  });

  test('A lost round reply and failed reload expose no state until fresh recovery',
      () async {
    final controller = await open();
    final before = controller.round;
    platform.failWrite(adapter.roundKey, _WriteFault.throwAfterCommit);
    platform.rejectReadsAfterFault = true;

    await expectLater(controller.flip(0), throwsStateError);
    expect(identical(controller.round, before), isTrue);
    expect(controller.state.faceUp[0], isFalse);
    final committed = MemoryRound.read(
        (await raw(adapter.roundKey))!, const FlutterMemoryCatalog(), _ownerA);
    expect(committed.rules.faceUp[0], isTrue);
    await expectLater(controller.flush(), throwsStateError);
    expect(identical(controller.round, before), isTrue);

    platform.rejectReads = false;
    await controller.flush();
    expect(controller.round.id, before.id);
    expect(controller.state.faceUp[0], isTrue);
    expect(await raw(adapter.roundKey), jsonEncode(controller.round.toJson()));
  });

  test('Failed stats commit keeps the real finish pending with one result ID',
      () async {
    final ids = <String>{};
    var attempts = 0;
    final controller = await open(
      award: (id, difficulty, kindPairs, lumoPairs) async {
        attempts++;
        ids.add(id);
        expect(difficulty, 'leicht');
        expect(kindPairs, 4);
        expect(lumoPairs, 0);
      },
    );
    final oldStats = jsonEncode({'difficulty': 'leicht', 'best': <String, int>{}});
    await adapter.writeStats(oldStats);
    platform.failWrite(adapter.statsKey, _WriteFault.falseBeforeCommit);

    await expectLater(_finish(controller), throwsStateError);
    expect(controller.state.complete, isTrue);
    expect(controller.round.rewarded, isFalse);
    expect(controller.best, isEmpty);
    expect(await raw(adapter.statsKey), oldStats);
    expect(ids, {controller.round.resultId});

    await controller.settleReward();
    expect(controller.round.rewarded, isTrue);
    expect(controller.best, {'leicht': 4});
    expect(attempts, 2, reason: 'The unresolved result is explicitly retried.');
    expect(ids, {controller.round.resultId},
        reason: 'The authority supplies the identical deduplication identity.');
    final confirmed = MemoryRound.read(
        (await raw(adapter.roundKey))!, const FlutterMemoryCatalog(), _ownerA);
    expect(confirmed.rewarded, isTrue);
  });

  test('Actual stats commit followed by error preserves the real completed round',
      () async {
    var awards = 0;
    final controller = await open(award: (_, __, ___, ____) async {
      awards++;
    });
    platform.failWrite(adapter.statsKey, _WriteFault.throwAfterCommit);
    await _finish(controller);

    expect(controller.round.rewarded, isTrue);
    expect(controller.best, {'leicht': 4});
    expect(awards, 1);
    expect(jsonDecode((await raw(adapter.statsKey))!), {
      'difficulty': 'leicht',
      'best': {'leicht': 4},
    });
    controller.dispose();
    final next = await open(award: (_, __, ___, ____) async {
      awards++;
    });
    expect(next.round.id, isNot(controller.round.id));
    expect(next.best, {'leicht': 4});
    expect(awards, 1);
  });

  test('Revoked profile cannot begin another platform read or write', () async {
    var current = true;
    final controller = await open(current: () => current);
    final before = await platform.persisted();
    final reads = platform.reads;
    final writes = platform.writes;
    current = false;

    await expectLater(controller.flip(0), throwsStateError);
    expect(platform.reads, reads);
    expect(platform.writes, writes);
    expect(await platform.persisted(), before);
  });

  test('Profile switch during a fresh read prevents the following write',
      () async {
    var current = true;
    final controller = await open(current: () => current);
    final before = await platform.persisted();
    final writes = platform.writes;
    final gate = platform.holdRead();
    final outcome = _outcome(controller.flip(0));
    try {
      await gate.entered.future.timeout(const Duration(seconds: 2));
      current = false;
    } finally {
      gate.complete();
    }

    expect(await outcome, isA<StateError>());
    expect(controller.state.faceUp[0], isFalse);
    expect(platform.writes, writes);
    expect(await platform.persisted(), before);
  });

  test('Late accepted write stays with its old owner and cannot expose a result',
      () async {
    var current = true;
    var awards = 0;
    final controller = await open(
      current: () => current,
      award: (_, __, ___, ____) async { awards++; },
    );
    final other = await open(owner: _ownerB);
    final otherKey = 'lumo.memory.round.v1.' + _ownerB;
    final otherBefore = await raw(otherKey);
    final previousRound = controller.round;
    final gate = platform.holdWrite(adapter.roundKey);
    final outcome = _outcome(controller.flip(0));
    try {
      await gate.entered.future.timeout(const Duration(seconds: 2));
      current = false;
    } finally {
      gate.complete();
    }

    expect(await outcome, isA<StateError>());
    expect(identical(controller.round, previousRound), isTrue);
    expect(controller.state.faceUp[0], isFalse);
    expect(awards, 0);
    final oldChild = MemoryRound.read(
        (await raw(adapter.roundKey))!, const FlutterMemoryCatalog(), _ownerA);
    expect(oldChild.owner, _ownerA);
    expect(oldChild.rules.faceUp[0], isTrue,
        reason: 'An already accepted write may finish only in its captured key.');
    expect(await raw(otherKey), otherBefore);
    expect(other.state.faceUp.every((value) => !value), isTrue);
    expect(await raw('lumo_memory_v2'), _legacy);
  });
}
