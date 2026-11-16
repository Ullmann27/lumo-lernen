import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_round.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_table_session.dart';

// Only storage/transport latency is controlled. The round controller, session,
// ownership checks, board actions and acknowledgement logic are production code.
class _Store implements ConnectFourStore {
  final rounds = <String, ConnectFourRound>{};

  @override
  Future<ConnectFourRound?> load(String owner, bool Function() current) async {
    if (!current()) throw StateError('stale profile');
    return rounds[owner];
  }

  @override
  Future<void> save(ConnectFourRound next, ConnectFourRound? previous,
      bool Function() current) async {
    if (!current()) throw StateError('stale profile');
    if (jsonEncode(rounds[next.owner]?.toJson()) !=
        jsonEncode(previous?.toJson())) {
      throw StateError('stale round');
    }
    rounds[next.owner] =
        ConnectFourRound.decode(jsonEncode(next.toJson()), next.owner);
  }
}

class _HeldTransport implements ConnectFourTransport {
  Completer<void>? openGate;
  Completer<void>? closeGate;
  final openEntered = Completer<void>();
  final closeEntered = Completer<void>();
  final liveTokens = <String>{};
  final closedTokens = <String>[];
  Map<String, Object?> state = {};
  Map<String, dynamic> box = {};
  int opens = 0;
  bool loseOpenReply = false;

  @override
  Future<void> open(String token, Map<String, Object?> value) async {
    opens++;
    if (!openEntered.isCompleted) openEntered.complete();
    await openGate?.future;
    state = Map.of(value);
    liveTokens.add(token);
    if (loseOpenReply) throw StateError('open committed but reply lost');
  }

  @override
  Future<Map<String, dynamic>> poll(String token) async => box;

  @override
  Future<void> publish(String token, Map<String, Object?> value) async {
    if (!liveTokens.contains(token)) throw StateError('authority closed');
    state = Map.of(value);
  }

  @override
  Future<void> close(String token) async {
    closedTokens.add(token);
    if (!closeEntered.isCompleted) closeEntered.complete();
    await closeGate?.future;
    liveTokens.remove(token);
  }

  void release() {
    if (openGate != null && !openGate!.isCompleted) openGate!.complete();
    if (closeGate != null && !closeGate!.isCompleted) closeGate!.complete();
  }
}

class _Fixture {
  final transport = _HeldTransport();
  bool current = true;
  int awards = 0;
  late ConnectFourRoundController controller;
  late ConnectFourTableSession session;

  Future<void> initialize() async {
    controller = await ConnectFourRoundController.open(
      studentId: 'c4-race-synthetic-child',
      seed: 7,
      store: _Store(),
      canUseProfile: () => current,
      award: (id, stars, xp) async { awards++; },
    );
    session = ConnectFourTableSession(
      controller: controller,
      transport: transport,
      token: 'a' * 32,
    );
  }

  Future<void> dispose() async {
    transport.release();
    await session.close();
    controller.dispose();
  }
}

Future<Object?> _outcome(Future<void> operation) => operation.then<Object?>(
      (_) => null,
      onError: (Object error, StackTrace stack) => error,
    );

void main() {
  Future<_Fixture> fixture() async {
    final value = _Fixture();
    await value.initialize();
    addTearDown(value.dispose);
    return value;
  }

  test('close during settlement cancels before any native open', () async {
    final f = await fixture();
    final opening = _outcome(f.session.open(automaticPolling: false));
    await f.session.close();
    final error = await opening;
    expect(error, isA<StateError>());
    expect(f.transport.opens, 0);
    expect(f.session.isOpen, isFalse);
    expect(f.session.canDrop, isFalse);
    expect(f.transport.liveTokens, isEmpty);
    expect(f.awards, 0);
  });

  test('late native open is cleaned after close without reviving authority',
      () async {
    final f = await fixture();
    f.transport.openGate = Completer<void>();
    final opening = _outcome(f.session.open(automaticPolling: false));
    await f.transport.openEntered.future;
    await f.session.close();
    expect(f.session.isOpen, isFalse);
    f.transport.openGate!.complete();
    final error = await opening;
    expect(error, isA<StateError>());
    expect(f.transport.liveTokens, isEmpty);
    expect(f.transport.closedTokens, everyElement(f.session.token));
    expect(f.session.isOpen, isFalse);
    expect(f.controller.round.columns, isEmpty);
  });

  test('concurrent opens cannot create two native authorities', () async {
    final f = await fixture();
    f.transport.openGate = Completer<void>();
    final first = _outcome(f.session.open(automaticPolling: false));
    final second = _outcome(f.session.open(automaticPolling: false));
    await f.transport.openEntered.future;
    f.transport.openGate!.complete();
    final results = await Future.wait([first, second]);
    expect(results[0], isNull);
    expect(results[1], isA<StateError>());
    expect(f.transport.opens, 1);
    expect(f.session.isOpen, isTrue);
  });

  test('a lost open reply still cleans only the opening token', () async {
    final f = await fixture();
    final foreign = 'b' * 32;
    f.transport.liveTokens.add(foreign);
    f.transport.loseOpenReply = true;
    final error = await _outcome(f.session.open(automaticPolling: false));
    expect(error, isA<StateError>());
    expect(f.session.isOpen, isFalse);
    expect(f.transport.liveTokens, {foreign});
    expect(f.transport.closedTokens, [f.session.token]);
  });

  test('opening cannot overtake a pending close for the same token', () async {
    final f = await fixture();
    await f.session.open(automaticPolling: false);
    f.transport.closeGate = Completer<void>();
    final closing = f.session.close();
    await f.transport.closeEntered.future;
    final error = await _outcome(f.session.open(automaticPolling: false));
    f.transport.closeGate!.complete();
    await closing;
    expect(error, isA<StateError>());
    expect(f.transport.opens, 1);
    expect(f.session.isOpen, isFalse);
    expect(f.transport.liveTokens, isEmpty);
  });

  test('all close callers await the same pending transport close', () async {
    final f = await fixture();
    await f.session.open(automaticPolling: false);
    f.transport.closeGate = Completer<void>();
    final first = f.session.close();
    await f.transport.closeEntered.future;
    var secondFinished = false;
    final second = f.session.close().then((_) { secondFinished = true; });
    await Future<void>.delayed(Duration.zero);
    final finishedBeforeRelease = secondFinished;
    f.transport.closeGate!.complete();
    await Future.wait([first, second]);
    expect(finishedBeforeRelease, isFalse);
    expect(secondFinished, isTrue);
    expect(f.transport.closedTokens, [f.session.token]);
    expect(f.transport.liveTokens, isEmpty);
  });

  test('profile revocation during native open cleans without changing a round',
      () async {
    final f = await fixture();
    final before = jsonEncode(f.controller.round.toJson());
    f.transport.openGate = Completer<void>();
    final opening = _outcome(f.session.open(automaticPolling: false));
    await f.transport.openEntered.future;
    f.current = false;
    f.transport.openGate!.complete();
    final error = await opening;
    expect(error, isA<StateError>());
    expect(f.transport.liveTokens, isEmpty);
    expect(f.session.isOpen, isFalse);
    expect(jsonEncode(f.controller.round.toJson()), before);
    expect(f.awards, 0);
  });

  test('normal native request still commits exactly one real C4 move', () async {
    final f = await fixture();
    await f.session.open(automaticPolling: false);
    f.transport.box = {
      'lifecycle': {
        'active': true,
        'pauseEpoch': 0,
        'stamp': DateTime.now().millisecondsSinceEpoch,
      },
    };
    await f.session.pump();
    expect(f.session.canDrop, isTrue);
    f.transport.box['request'] = {
      'token': f.session.token,
      'roundId': f.controller.round.id,
      'revision': f.session.view['revision'],
      'sequence': 1,
      'action': 'drop',
      'column': 3,
    };
    await f.session.pump();
    await f.session.pump();
    expect(f.controller.round.columns, [3]);
    expect(f.transport.state['ack'], 1);
    expect(f.awards, 0);
    await f.session.close();
    expect(f.transport.liveTokens, isEmpty);
  });
}
