// Explicit local two-process QA driver, invoked with flutter test. The Android
// MethodChannel/Binder is not used here. Production controller and rules are.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_round.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_table_session.dart';

class FileTransport implements ConnectFourTransport {
  FileTransport(this.directory);
  final Directory directory;
  final events = <Map<String, Object?>>[];
  Map<String, dynamic> current = {};
  void atomic(String name, Object value) {
    final file = File('${directory.path}/$name.tmp');
    file.writeAsStringSync(jsonEncode(value), flush: true);
    file.renameSync('${directory.path}/$name');
  }

  @override
  Future<void> open(String token, Map<String, Object?> state) async {
    atomic('session.json',
        {'token': token, 'owner': state['owner'], 'roundId': state['roundId']});
    await publish(token, state);
  }

  @override
  Future<void> publish(String token, Map<String, Object?> state) async {
    events.add({'kind': 'state', 'state': state});
    atomic('state.json', state);
  }

  @override
  Future<Map<String, dynamic>> poll(String token) async {
    final file = File('${directory.path}/input.json');
    if (file.existsSync())
      current = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return current;
  }

  @override
  Future<void> close(String token) async {
    atomic('closed.json', {'token': token});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Real Godot touch intents pass through production Dart rule/save/session controller',
      () async {
    SharedPreferences.setMockInitialValues({});
    final path = Platform.environment['LUMO_C4_RUNTIME_DIR'];
    expect(path, isNotNull,
        reason: 'Explicit IPC directory required; no Android claim');
    final directory = Directory(path!)..createSync(recursive: true);
    final transport = FileTransport(directory);

    print("C4DRIVER before controller");
    final c = await ConnectFourRoundController.open(
        studentId: 'local-runtime-c4-review',
        seed: 31,
        canUseProfile: () => true,
        award: (id, stars, xp) async {
          await RewardWalletRepository()
              .awardGameResult(resultId: id, stars: stars, xp: xp);
        });
    print("C4DRIVER controller ready");
    final s = ConnectFourTableSession(
        controller: c,
        transport: transport,
        token: 'a' * 32,
        now: () => DateTime.fromMillisecondsSinceEpoch(
            (transport.current['clock_ms'] as num?)?.toInt() ?? 100000));
    print("C4DRIVER before session");
    await s.open(automaticPolling: false);
    print("C4DRIVER session ready");
    final deadline = DateTime.now().add(const Duration(minutes: 18));
    while (!File('$path/done.json').existsSync() &&
        DateTime.now().isBefore(deadline)) {
      await s.pump();
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
    expect(File('$path/done.json').existsSync(), isTrue,
        reason: 'Bounded genuine renderer sequence must finish');
    expect(c.round.columns, [0, 6, 1, 6, 2, 5, 3]);
    expect(c.round.rewarded, isTrue);
    expect(transport.events.any((event) {
      final state=event['state'] as Map<String,Object?>;
      return state['twoPlayers']==false && (state['columns'] as List).length==2 && state['turn']==1;
    }),isTrue,reason:'A real single-player human turn receives an unchanged Dart bot response');
    expect((await RewardWalletRepository().load()).stars, 5);
    final previous = c.round.toJson();
    await s.close();
    final reopened = await ConnectFourRoundController.open(
        studentId: 'local-runtime-c4-review',
        canUseProfile: () => true,
        award: (id, stars, xp) async {
          await RewardWalletRepository()
              .awardGameResult(resultId: id, stars: stars, xp: xp);
        });
    expect(reopened.round.toJson(), previous);
    expect((await RewardWalletRepository().load()).stars, 5);
    transport.atomic('dart-result.json', {
      'passed': true,
      'transport': 'local file boundary, not Android',
      'preferences_backend': 'SharedPreferences test backend, same process reopen',
      'single_player_human_and_bot_observed': true,
      'engine_source': 'unchanged production ConnectFourEngine',
      'round': previous,
      'stars': 5,
      'xp': 40,
      'reopened_same_round': true,
      'events': transport.events
    });
    c.dispose();
    reopened.dispose();
  }, timeout: const Timeout(Duration(minutes: 20)));
}
