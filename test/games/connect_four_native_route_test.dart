import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Actual Android Flutter route opens independent C4, returns paused and reopens exact round',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    LumoVoice.instance.isEnabled = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const table = MethodChannel('lumo_lernen/connect_four'),
        bridge = MethodChannel('lumo_lernen/bridge');
    Map<String, dynamic> state = {}, request = {};
    final launches = <Map<String, dynamic>>[], tokens = <String>[];
    final returns = <Completer<Map<String, dynamic>>>[];
    var closed = 0;
    messenger.setMockMethodCallHandler(table, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      switch (call.method) {
        case 'open':
          tokens.add(args['token'] as String);
          state = jsonDecode(args['state'] as String) as Map<String, dynamic>;
          request = {};
          return true;
        case 'publish':
          state = jsonDecode(args['state'] as String) as Map<String, dynamic>;
          return true;
        case 'poll':
          return jsonEncode({
            'lifecycle': {
              'active': true,
              'stamp': DateTime.now().millisecondsSinceEpoch,
              'pauseEpoch': 0
            },
            'request': request
          });
        case 'close':
          closed++;
          return true;
      }
      throw MissingPluginException();
    });
    messenger.setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'launch3D') {
        launches.add(Map<String, dynamic>.from(call.arguments as Map));
        final result = Completer<Map<String, dynamic>>();
        returns.add(result);
        return result.future;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(table, null);
      messenger.setMockMethodCallHandler(bridge, null);
      app.dispose();
    });
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        MaterialApp(home: LumoConnectFourScreen(appState: app, seed: 7)));
    Future<void> until(bool Function() condition) async {
      for (var i = 0; i < 50 && !condition(); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(condition(), isTrue);
    }

    await until(() => launches.length == 1 && state['canDrop'] == true);
    expect(launches.single['scene'], 'connect_four');
    expect(launches.single['connectFourToken'], tokens.single);
    expect(launches.single.containsKey('cardsToken'), isFalse);
    void send(int sequence, String action, Map<String, dynamic> extra) {
      request = {
        'token': tokens.last,
        'roundId': state['roundId'],
        'revision': state['revision'],
        'sequence': sequence,
        'action': action,
        ...extra
      };
    }

    send(1, 'mode', {'twoPlayers': true});
    await until(() => state['ack'] == 1);
    send(2, 'drop', {'column': 3});
    await until(() => state['ack'] == 2);
    final round = state['roundId'];
    expect(state['columns'], [3]);
    returns.first.complete({'destination': 'games'});
    await until(
        () => closed == 1 && find.text('Spiel pausiert').evaluate().isNotEmpty);
    expect(find.byKey(const ValueKey('connect-cell-5-3')), findsOneWidget);
    expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('connect-cell-5-3')))
            .properties
            .label,
        endsWith(': child'));
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-open-native')));
    await until(() => launches.length == 2);
    expect(tokens[1], isNot(tokens[0]));
    expect(state['roundId'], round);
    expect(state['columns'], [3]);
    returns.last.complete({'destination': 'games'});
    await until(() => closed == 2);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
