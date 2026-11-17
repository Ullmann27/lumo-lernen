import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_engine.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_round.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_table_session.dart';

class Store implements ConnectFourStore {
  final data = <String, ConnectFourRound>{};
  bool fail = false, failRewardAck = false;
  Completer<void>? hold;
  Completer<void>? entered;
  @override
  Future<ConnectFourRound?> load(String owner, bool Function() current) async {
    if (!current()) throw StateError('stale');
    return data[owner];
  }

  @override
  Future<void> save(ConnectFourRound next, ConnectFourRound? previous,
      bool Function() current) async {
    if (!current()) throw StateError('stale');
    entered?.complete();
    entered = null;
    await hold?.future;
    if (!current() || fail || (failRewardAck && next.rewarded)) {
      throw StateError('not durable');
    }
    if (data[next.owner]?.toJson().toString() !=
        previous?.toJson().toString()) {
      throw StateError('stale write');
    }
    data[next.owner] =
        ConnectFourRound.decode(jsonEncode(next.toJson()), next.owner);
  }
}

class Transport implements ConnectFourTransport {
  Map<String, dynamic> box = {};
  Map<String, Object?> state = {};
  int closed = 0;
  @override
  Future<void> open(String token, Map<String, Object?> state) async =>
      this.state = Map.of(state);
  @override
  Future<Map<String, dynamic>> poll(String token) async => box;
  @override
  Future<void> publish(String token, Map<String, Object?> state) async =>
      this.state = Map.of(state);
  @override
  Future<void> close(String token) async {
    closed++;
  }
}

class HeldWallet extends RewardWalletRepository {
  final entered = Completer<void>(), release = Completer<void>();
  final resultIds = <String>[];
  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0}) async {
    entered.complete();
    await release.future;
    return super.applyRewardDelta(starsDelta: starsDelta, xpDelta: xpDelta);
  }

  @override
  Future<RewardWallet> awardGameResult(
      {required String resultId, required int stars, required int xp}) {
    resultIds.add(resultId);
    return super.awardGameResult(resultId: resultId, stars: stars, xp: xp);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ConnectFourRoundController> open(
          {ConnectFourStore? store,
          String child = 'local-stable-child',
          bool Function()? current,
          ConnectFourAward? award}) =>
      ConnectFourRoundController.open(
          studentId: child,
          seed: 31,
          store: store,
          canUseProfile: current ?? () => true,
          award: award ??
              (id, stars, xp) async {
                await RewardWalletRepository()
                    .awardGameResult(resultId: id, stars: stars, xp: xp);
              });

  test(
      'Two stable child IDs have distinct durable rounds, even with the same presentation',
      () async {
    final a = await open(child: 'school-id-A');
    final b = await open(child: 'school-id-B');
    await a.play(4);
    await b.play(1);
    final savedA = await open(child: 'school-id-A');
    final savedB = await open(child: 'school-id-B');
    expect(savedA.round.id, a.round.id);
    expect(savedB.round.id, b.round.id);
    expect(savedA.round.columns, [4]);
    expect(savedB.round.columns, [1]);
    expect(savedA.round.owner, isNot(savedB.round.owner));
    expect(savedA.engine.turn, ConnectPiece.lumo);
  });

  test('Class/name changes do not change stable ID save keys', () async {
    final first = await open(child: 'persistent-student-42');
    await first.play(2);
    final restarted = await open(child: 'persistent-student-42');
    expect(restarted.round.toJson(), first.round.toJson());
    expect((await SharedPreferences.getInstance()).getKeys(),
        contains(ConnectFourRoundRepository.key(first.round.owner)));
  });

  test(
      'Completed round reopens without a second reward; repeated result is idempotent',
      () async {
    final app = LumoAppState();
    final lease = await app.captureLearningProfile();
    final c = await open(
        child: lease.studentId,
        current: () => app.canUseLearningLease(lease),
        award: (id, s, x) => app.recordConnectFourResult(
            lease: lease, resultId: id, stars: s, xp: x));
    await c.restart(twoPlayers: true);
    for (final col in [0, 6, 1, 6, 2, 5, 3]) {
      await c.play(col);
    }
    expect(c.engine.phase, ConnectPhase.won);
    expect(c.round.rewarded, isTrue);
    expect(app.state.stars, 5);
    expect(app.state.xp, 40);
    await app.recordConnectFourResult(
        lease: lease,
        resultId: 'c4:${c.round.owner}:${c.round.id}',
        stars: 5,
        xp: 40);
    final reopened = await open(child: lease.studentId);
    expect(reopened.round.id, c.round.id);
    expect(reopened.engine.winningLine, hasLength(4));
    final wallet = await RewardWalletRepository().load();
    expect(wallet.stars, 5);
    expect(wallet.xp, 40);
    expect(wallet.gameResultIds, hasLength(1));
    app.dispose();
  });

  test(
      'Process interruption after wallet commit before round ACK retries the same result ID',
      () async {
    final store = Store();
    final c = await open(store: store);
    await c.restart(twoPlayers: true);
    for (final col in [0, 6, 1, 6, 2, 5]) {
      await c.play(col);
    }
    store.failRewardAck = true;
    await expectLater(c.play(3), throwsStateError);
    expect(store.data[c.round.owner]!.columns, hasLength(7));
    expect(store.data[c.round.owner]!.rewarded, isFalse);
    expect((await RewardWalletRepository().load()).stars, 5);
    c.dispose();
    store.failRewardAck = false;
    final resumed = await open(store: store);
    expect(resumed.round.rewarded, isTrue);
    expect((await RewardWalletRepository().load()).stars, 5);
    expect((await RewardWalletRepository().load()).gameResultIds, hasLength(1));
  });

  test('Failed move save never installs a visible piece or advances its turn',
      () async {
    final store = Store();
    final c = await open(store: store);
    final original = jsonEncode(c.round.toJson());
    store.fail = true;
    await expectLater(c.play(3), throwsStateError);
    expect(c.engine.moves, 0);
    expect(jsonEncode(c.round.toJson()), original);
    store.fail = false;
    await c.play(3);
    expect(c.engine.moves, 1);
  });

  test(
      'Profile switch during a held bot write cannot replace either child round',
      () async {
    var current = true;
    final store = Store();
    final c = await open(store: store, current: () => current);
    final b = await open(store: store, child: 'different-child');
    await b.play(6);
    await c.play(3);
    store.hold = Completer<void>();
    store.entered = Completer<void>();
    final entered = store.entered!.future;
    final pending = expectLater(c.playBot(), throwsStateError);
    await entered;
    current = false;
    store.hold!.complete();
    await pending;
    expect(c.engine.moves, 1);
    expect(store.data[c.round.owner]!.columns, [3]);
    expect(store.data[b.round.owner]!.columns, [6]);
  });

  test(
      'Profile switch during reward allows no stale round ACK or foreign ownership',
      () async {
    var current = true;
    final store = Store();
    final started = Completer<void>(), release = Completer<void>();
    final c = await open(
        store: store,
        current: () => current,
        award: (id, s, x) async {
          started.complete();
          await release.future;
          await RewardWalletRepository()
              .awardGameResult(resultId: id, stars: s, xp: x);
        });
    await c.restart(twoPlayers: true);
    for (final col in [0, 6, 1, 6, 2, 5]) {
      await c.play(col);
    }
    final pending = expectLater(c.play(3), throwsStateError);
    await started.future;
    current = false;
    release.complete();
    await pending;
    expect(store.data[c.round.owner]!.rewarded, isFalse);
    final other = await open(store: store, child: 'second-child');
    expect(other.engine.moves, 0);
    final resumed = await open(store: store);
    expect(resumed.round.rewarded, isTrue);
    expect((await RewardWalletRepository().load()).stars, 5);
  });

  for (final level in ConnectLumoLevel.values) {
    test('Native bot uses unchanged ${level.name} policy and legal replay',
        () async {
      final c = await open(store: Store());
      await c.setLevel(level);
      await c.play(2);
      final expected = c.engine.chooseLumoColumn(
          Random(c.round.seed ^ (c.engine.moves * 7919)),
          level: level);
      await c.playBot();
      expect(c.round.columns, [2, expected]);
      expect(c.round.replay().moves, 2);
    });
  }

  test('Corrupt, post-win and foreign-owner saves fail without modifying bytes',
      () async {
    final c = await open();
    final prefs = await SharedPreferences.getInstance();
    final key = ConnectFourRoundRepository.key(c.round.owner);
    for (final change in <Map<String, Object?>>[
      {
        'columns': [0, 0, 0, 0, 0, 0, 0]
      },
      {
        'columns': [0, 6, 1, 6, 2, 5, 3, 4]
      },
      {'owner': 'another-child'},
      {'rewarded': true},
      {'revision': 1.0},
    ]) {
      final raw = jsonEncode({...c.round.toJson(), ...change});
      await prefs.setString(key, raw);
      await expectLater(open(), throwsFormatException);
      expect(prefs.getString(key), raw);
    }
  });

  test('Existing unrelated preferences remain byte-identical', () async {
    SharedPreferences.setMockInitialValues(
        {'old-child': 'raw value', 'learning.profile': 'retained'});
    final c = await open();
    await c.play(5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('old-child'), 'raw value');
    expect(prefs.getString('learning.profile'), 'retained');
  });

  test(
      'AppState rejects foreign result ID, stale lease and changed reward amounts',
      () async {
    final app = LumoAppState();
    final lease = await app.captureLearningProfile();
    final id = 'c4:${ConnectFourRound.ownerKey(lease.studentId)}:${'a' * 32}';
    await expectLater(
        app.recordConnectFourResult(
            lease: lease, resultId: 'c4:foreign:${'a' * 32}', stars: 5, xp: 40),
        throwsStateError);
    await expectLater(
        app.recordConnectFourResult(
            lease: lease, resultId: id, stars: 99, xp: 999),
        throwsStateError);
    await app.prepareLearningLease(lease);
    expect(await app.resetTutorObservations(lease: lease), isTrue);
    await expectLater(
        app.recordConnectFourResult(
            lease: lease, resultId: id, stars: 5, xp: 40),
        throwsStateError);
    expect((await RewardWalletRepository().load()).stars, 0);
    app.dispose();
  });

  test(
      'A stale child result is never enqueued behind an existing held wallet write',
      () async {
    final wallet = HeldWallet();
    final ownerApp = LumoAppState(walletRepository: wallet);
    await ownerApp.hydrateFromWallet();
    final lease = await ownerApp.captureLearningProfile();
    await ownerApp.prepareLearningLease(lease);
    ownerApp.addStars(1);
    await wallet.entered.future;
    final id = 'c4:${ConnectFourRound.ownerKey(lease.studentId)}:${'e' * 32}';
    final pending = expectLater(
        ownerApp.recordConnectFourResult(
            lease: lease, resultId: id, stars: 5, xp: 40),
        throwsStateError);
    expect(await ownerApp.resetTutorObservations(lease: lease), isTrue);
    wallet.release.complete();
    await pending;
    expect(wallet.resultIds, isEmpty);
    expect(wallet.snapshot.stars, 1);
    ownerApp.dispose();
  });

  test(
      'Loaded round determines the announcement for restored bot, local Gold and finished game',
      () async {
    final c = await open(store: Store());
    expect(c.announcement, contains('Du bist dran'));
    await c.play(3);
    expect(c.announcement, endsWith('Lumo ist dran.'));
    await c.restart(twoPlayers: true);
    await c.play(0);
    expect(c.announcement, contains('Ihr spielt zu zweit'));
    expect(c.announcement, endsWith('Gold ist dran.'));
    for (final col in [6, 1, 6, 2, 5, 3]) {
      await c.play(col);
    }
    expect(c.announcement,
        'Deine gespeicherte Runde ist beendet. Cyan hat gewonnen.');
  });

  test('An invalid new-round seed cannot create an undecodable saved record',
      () async {
    final store = Store();
    for (final seed in [-1, 0x80000000]) {
      await expectLater(
          ConnectFourRoundController.open(
              studentId: 'a',
              canUseProfile: () => true,
              award: (id, s, x) async {},
              store: store,
              seed: seed),
          throwsArgumentError);
    }
    expect(store.data, isEmpty);
  });

  Future<
      ({
        ConnectFourRoundController c,
        ConnectFourTableSession s,
        Transport t,
        void Function(int) step
      })> session({Store? store, bool Function()? current}) async {
    var now = DateTime.fromMillisecondsSinceEpoch(100000);
    final c = await open(store: store ?? Store(), current: current),
        t = Transport();
    final s =
        ConnectFourTableSession(controller: c, transport: t, now: () => now);
    await s.open(automaticPolling: false);
    void step(int milliseconds) {
      now = now.add(Duration(milliseconds: milliseconds));
      t.box['lifecycle'] = {
        'active': true,
        'stamp': now.millisecondsSinceEpoch,
        'pauseEpoch': 0
      };
    }

    step(0);
    await s.pump();
    addTearDown(s.close);
    return (c: c, s: s, t: t, step: step);
  }

  Map<String, dynamic> request(
          ConnectFourTableSession s, int sequence, String action,
          [Map<String, dynamic> extra = const {}]) =>
      {
        'token': s.token,
        'roundId': s.controller.round.id,
        'revision': s.view['revision'],
        'sequence': sequence,
        'action': action,
        ...extra
      };

  test(
      'Actual session drop is durable before ACK; duplicate sequence cannot add a piece',
      () async {
    final h = await session();
    final req = request(h.s, 1, 'drop', {'column': 3});
    h.t.box['request'] = req;
    await h.s.pump();
    expect(h.s.view['ack'], 1);
    expect(h.c.engine.moves, 1);
    await h.s.pump();
    expect(h.c.engine.moves, 1);
    expect(h.s.view['board'], contains(1));
  });

  test('Pause, stale heartbeat and explicit resume preserve bot/round history',
      () async {
    final h = await session();
    h.t.box['request'] = request(h.s, 1, 'drop', {'column': 3});
    await h.s.pump();
    h.t.box['request'] = request(h.s, 2, 'pause');
    await h.s.pump();
    for (var i = 0; i < 8; i++) {
      h.step(500);
      await h.s.pump();
    }
    expect(h.c.engine.moves, 1);
    expect(h.s.paused, isTrue);
    h.t.box['request'] = request(h.s, 3, 'resume');
    await h.s.pump();
    for (var i = 0; i < 3; i++) {
      h.step(500);
      await h.s.pump();
    }
    expect(h.c.engine.moves, 2);
    final saved = List.of(h.c.round.columns);
    h.t.box.remove('request');
    h.step(3000);
    (h.t.box['lifecycle'] as Map)['stamp'] =
        (h.t.box['lifecycle']['stamp'] as int) - 3000;
    await h.s.pump();
    expect(h.s.paused, isTrue);
    expect(h.c.round.columns, saved);
    h.step(1);
    await h.s.pump();
    expect(h.s.paused, isTrue);
    h.t.box['request'] = request(h.s, 4, 'resume');
    await h.s.pump();
    expect(h.s.paused, isFalse);
  });

  test('Render stall with fresh lifecycle keeps authoritative session live',
      () async {
    final h = await session();
    h.step(4000);
    await h.s.pump();
    expect(h.s.paused, isFalse);
    expect(h.s.canDrop, isTrue);
  });

  test('Pause epoch while no render poll requires explicit resume', () async {
    final h = await session();
    h.step(5000);
    h.t.box['lifecycle']['pauseEpoch'] = 2;
    await h.s.pump();
    expect(h.s.paused, isTrue);
    h.t.box['request'] = request(h.s, 1, 'resume');
    await h.s.pump();
    expect(h.s.paused, isFalse);
  });

  test(
      'Foreign token, round, revision, opcode, column cannot change existing board',
      () async {
    final h = await session();
    for (final extra in <Map<String, dynamic>>[
      {'token': 'foreign'},
      {'roundId': 'foreign'},
      {'revision': 0},
      {'action': 'reward'},
      {'column': -1},
      {'column': 7},
      {'sequence': 1.0},
    ]) {
      h.t.box['request'] = request(h.s, 1, 'drop', {'column': 0, ...extra});
      await h.s.pump();
      expect(h.c.engine.moves, 0);
      expect(h.s.view['ack'], 0);
    }
  });

  test('Save failure gives negative result, no ACK, and explicit retry is safe',
      () async {
    final store = Store();
    final h = await session(store: store);
    store.fail = true;
    h.t.box['request'] = request(h.s, 1, 'drop', {'column': 2});
    await h.s.pump();
    expect(h.c.engine.moves, 0);
    expect(h.s.view['ack'], 0);
    expect(h.s.view['rejected'], 1);
    expect(h.s.paused, isTrue);
    store.fail = false;
    h.t.box['request'] = request(h.s, 2, 'resume');
    await h.s.pump();
    h.t.box['request'] = request(h.s, 3, 'drop', {'column': 2});
    await h.s.pump();
    expect(h.c.round.columns, [2]);
    expect(h.s.view['ack'], 3);
  });

  test('Accepted drop invalidated by Activity pause releases slot for Resume',
      () async {
    final h = await session();
    h.t.box['request'] = request(h.s, 1, 'drop', {'column': 3});
    h.t.box['lifecycle']['active'] = false;
    h.t.box['lifecycle']['pauseEpoch'] = 1;
    await h.s.pump();
    expect(h.s.view['ack'], 0);
    expect(h.s.view['rejected'], 1);
    expect(h.c.engine.moves, 0);
    h.step(100);
    h.t.box['lifecycle']['pauseEpoch'] = 1;
    h.t.box['request'] = request(h.s, 2, 'resume');
    await h.s.pump();
    expect(h.s.view['ack'], 2);
    expect(h.s.paused, isFalse);
    h.t.box['request'] = request(h.s, 3, 'drop', {'column': 3});
    await h.s.pump();
    expect(h.c.round.columns, [3]);
  });

  test(
      'Old profile lease closes transport before processing pending human/bot input',
      () async {
    var current = true;
    final h = await session(current: () => current);
    h.t.box['request'] = request(h.s, 1, 'drop', {'column': 4});
    current = false;
    await h.s.pump();
    expect(h.t.closed, 1);
    expect(h.s.isOpen, isFalse);
    expect(h.c.engine.moves, 0);
  });

  test(
      'Exit stores same round; reopen has new session token and explicit active lease',
      () async {
    final h = await session();
    h.t.box['request'] = request(h.s, 1, 'drop', {'column': 4});
    await h.s.pump();
    h.t.box['request'] = request(h.s, 2, 'exit');
    await h.s.pump();
    expect(h.s.view['exit'], isTrue);
    expect(h.s.paused, isTrue);
    await h.s.close();
    final t = Transport(),
        next = ConnectFourTableSession(controller: h.c, transport: Transport());
    await next.open(automaticPolling: false);
    expect(next.token, isNot(h.s.token));
    expect(next.view['roundId'], h.s.view['roundId']);
    expect(next.view['columns'], [4]);
    expect(next.paused, isTrue);
    await next.close();
    expect(t.closed, 0);
  });
}
