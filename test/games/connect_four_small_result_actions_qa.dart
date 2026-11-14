// Explicit QA overlay: real Godot inputs and production Dart state transitions.
// File transport and SharedPreferences test backend; no Android or FPS claim.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_round.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_table_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connect_four_runtime_bridge.dart' show FileTransport;

const _history = [0, 6, 1, 6, 2, 5, 3];

class ObservedFileTransport extends FileTransport {
  ObservedFileTransport(Directory directory) : super(directory);

  final receivedRequests = <Map<String, dynamic>>[];
  String? _lastRequest;

  @override
  Future<Map<String, dynamic>> poll(String token) async {
    final value = await super.poll(token);
    final request = value['request'];
    if (request is Map<String, dynamic> && request['sequence'] is int) {
      final encoded = jsonEncode(request);
      if (encoded != _lastRequest) {
        receivedRequests.add(jsonDecode(encoded) as Map<String, dynamic>);
        _lastRequest = encoded;
      }
    }
    return value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('640x360 won-dialog scroll, restart and solo-mode actions reach Dart',
      () async {
    SharedPreferences.setMockInitialValues({});
    final path = Platform.environment['LUMO_C4_RUNTIME_DIR'];
    expect(path, isNotNull, reason: 'Explicit isolated QA evidence directory');
    final directory = Directory(path!);
    expect(directory.existsSync(), isTrue);
    final transport = ObservedFileTransport(directory);
    final awards = <Map<String, Object?>>[];
    final report = <String, Object?>{
      'schema': 1,
      'passed': false,
      'transport': 'local file boundary; not Android Binder',
      'preferences_backend': 'SharedPreferences test backend, same process reopen',
      'production_controller': 'unchanged ConnectFourRoundController and session',
    };
    ConnectFourRoundController? controller;
    ConnectFourRoundController? reopened;
    ConnectFourTableSession? session;
    try {
      final c = await ConnectFourRoundController.open(
        studentId: 'synthetic-small-result-actions-qa',
        seed: 31,
        canUseProfile: () => true,
        award: (id, stars, xp) async {
          awards.add({'resultId': id, 'stars': stars, 'xp': xp});
          await RewardWalletRepository()
              .awardGameResult(resultId: id, stars: stars, xp: xp);
        },
      );
      controller = c;
      final s = ConnectFourTableSession(
        controller: c,
        transport: transport,
        token: 'a' * 32,
        now: () => DateTime.fromMillisecondsSinceEpoch(
            (transport.current['clock_ms'] as num?)?.toInt() ?? 100000),
      );
      session = s;
      await s.open(automaticPolling: false);
      final deadline = DateTime.now().add(const Duration(minutes: 10));
      while (!File('$path/done.json').existsSync() &&
          DateTime.now().isBefore(deadline)) {
        await s.pump();
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
      expect(File('$path/done.json').existsSync(), isTrue,
          reason: 'The actual bounded renderer sequence must finish');
      final native = jsonDecode(File('$path/native-result.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(native['schema'], 1);
      expect(native['passed'], isTrue);
      expect(native['errors'], isEmpty);
      expect(native['viewport_px'], [640, 360]);
      expect(native['return_acknowledged'], isTrue);
      final actions = (native['actions'] as List)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();
      expect(actions.map((a) => a['action']).toList(), ['restart', 'mode']);
      expect(native['submitted_requests'], transport.receivedRequests,
          reason: 'Every native intent must actually cross the file boundary');
      final requests = transport.receivedRequests;
      expect(requests.map((r) => r['action']).toList(), [
        'pause', 'mode',
        for (final _ in _history) 'drop',
        'pause', 'restart',
        for (final _ in _history) 'drop',
        'pause', 'mode', 'exit',
      ]);
      expect(requests[1]['twoPlayers'], isTrue);
      expect(requests.where((r) => r['action'] == 'drop').map((r) => r['column']),
          [..._history, ..._history]);
      final states = transport.events
          .map((event) => Map<String, Object?>.from(event['state'] as Map))
          .toList();
      expect(states, isNotEmpty);
      for (var index = 0; index < states.length; index++) {
        expect(states[index]['rejected'], 0);
        expect(states[index]['error'], isNull);
        if (index > 0) {
          expect(states[index]['revision'], greaterThan(states[index - 1]['revision'] as int));
        }
      }
      var previousSequence = 0;
      for (final request in requests) {
        final sequence = request['sequence'] as int;
        expect(sequence, greaterThan(previousSequence));
        previousSequence = sequence;
        final before = states.singleWhere((state) => state['revision'] == request['revision']);
        expect(request['token'], before['token']);
        expect(request['roundId'], before['roundId']);
        expect(states.any((state) => state['ack'] == sequence), isTrue,
            reason: 'Each actual touch request needs a production ACK');
      }
      for (final action in actions) {
        final before = Map<String, dynamic>.from(action['before_state'] as Map);
        final after = Map<String, dynamic>.from(action['after_state'] as Map);
        final request = Map<String, dynamic>.from(action['request'] as Map);
        expect(states.singleWhere((state) => state['revision'] == before['revision']), before);
        expect(states.singleWhere((state) => state['revision'] == after['revision']), after);
        expect(requests.singleWhere((r) => r['sequence'] == request['sequence']), request);
        expect(before['phase'], 'won');
        expect(before['paused'], isTrue);
        expect(before['twoPlayers'], isTrue);
        expect(before['rewarded'], isTrue);
        expect(before['columns'], _history);
        expect(request['action'], action['action']);
        expect(request['revision'], before['revision']);
        expect(request['roundId'], before['roundId']);
        expect(after['ack'], request['sequence']);
        expect(after['roundId'], isNot(before['roundId']));
        expect(after['owner'], before['owner']);
        expect(after['token'], before['token']);
        expect(after['phase'], 'playing');
        expect(after['paused'], isFalse);
        expect(after['exit'], isFalse);
        expect(after['canDrop'], isTrue);
        expect(after['turn'], 1);
        expect(after['rewarded'], isFalse);
        expect(after['columns'], isEmpty);
        expect(after['winningLine'], isEmpty);
        expect(after['board'], List<int>.filled(42, 0));
        expect(after['twoPlayers'], action['action'] == 'restart');
        if (action['action'] == 'mode') expect(request['twoPlayers'], isFalse);
      }
      expect(actions[1]['before_state']['roundId'], actions[0]['after_state']['roundId']);
      expect(native['final_state'], states.last);
      expect(states.last['exit'], isTrue);
      expect(states.last['ack'], requests.last['sequence']);
      expect(c.round.columns, isEmpty);
      expect(c.round.twoPlayers, isFalse);
      expect(c.round.rewarded, isFalse);
      final expectedAwards = actions.map((action) => {
        'resultId': 'c4:${action['before_state']['owner']}:${action['before_state']['roundId']}',
        'stars': 5,
        'xp': 40,
      }).toList();
      expect(awards, expectedAwards);
      final wallet = await RewardWalletRepository().load();
      expect(wallet.stars, 10);
      expect(wallet.xp, 80);
      final previous = c.round.toJson();
      await s.close();
      final restored = await ConnectFourRoundController.open(
        studentId: 'synthetic-small-result-actions-qa',
        canUseProfile: () => true,
        award: (id, stars, xp) async {
          awards.add({'resultId': id, 'stars': stars, 'xp': xp});
          await RewardWalletRepository()
              .awardGameResult(resultId: id, stars: stars, xp: xp);
        },
      );
      reopened = restored;
      expect(restored.round.toJson(), previous);
      expect(awards, expectedAwards, reason: 'No repeated award on same-process reopen');
      expect((await RewardWalletRepository().load()).stars, 10);
      expect((await RewardWalletRepository().load()).xp, 80);
      report.addAll({
        'passed': true,
        'verified_actions': ['restart', 'mode'],
        'round': previous,
        'stars': wallet.stars,
        'xp': wallet.xp,
        'reopened_same_round': true,
      });
    } catch (error, stack) {
      report['error'] = '$error';
      report['stack'] = '$stack';
      rethrow;
    } finally {
      report['received_requests'] = transport.receivedRequests;
      report['events'] = transport.events;
      report['awards'] = awards;
      transport.atomic('dart-result.json', report);
      await session?.close();
      controller?.dispose();
      reopened?.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
