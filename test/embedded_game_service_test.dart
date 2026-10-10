import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/embedded_game_service.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lumo_lernen/bridge');
  late Map<String, dynamic> pending;
  late bool failAcknowledgement;
  late List<String> acknowledged;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    failAcknowledgement = false;
    acknowledged = [];
    pending = {
      'results': [
        {
          'game': 'kart',
          'resultId': 'race-1',
          'status': 'completed',
          'stars': 9,
          'solved': 3
        },
      ],
      'destination': 'games',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'pendingGameEvents':
          return jsonEncode(pending);
        case 'acknowledgeGameEvents':
          if (failAcknowledgement) throw PlatformException(code: 'storage');
          acknowledged = List<String>.from(call.arguments['resultIds']);
          pending['results'] = (pending['results'] as List)
              .where((event) => !acknowledged.contains(event['resultId']))
              .toList();
          if (pending['destination'] == call.arguments['destination']) {
            pending.remove('destination');
          }
          return true;
        case 'clearGameEvents':
          pending = {'results': []};
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('real completed-result contract persists wallet and returns to games',
      () async {
    final wallet = RewardWalletRepository();
    final state = LumoAppState(walletRepository: wallet);
    final destinations = <LumoSection>[];
    final service = EmbeddedGameService(
        appState: state, wallet: wallet, onDestination: destinations.add);
    await service.synchronize();
    expect(state.state.stars, 9);
    expect(state.state.xp, 30);
    expect(destinations, [LumoSection.games]);
    expect(acknowledged, ['race-1']);
    final reloaded = RewardWalletRepository();
    expect((await reloaded.load()).stars, 9);
    expect(reloaded.snapshot.gameResultIds, ['race-1']);
    service.dispose();
    state.dispose();
  });

  test(
      'lost acknowledgement and process restart replay the reward exactly once',
      () async {
    final firstWallet = RewardWalletRepository();
    final firstState = LumoAppState(walletRepository: firstWallet);
    final firstService = EmbeddedGameService(
        appState: firstState, wallet: firstWallet, onDestination: (_) {});
    failAcknowledgement = true;
    await firstService.synchronize();
    firstService.dispose();
    firstState.dispose();
    final nextWallet = RewardWalletRepository();
    final nextState = LumoAppState(walletRepository: nextWallet);
    final nextService = EmbeddedGameService(
        appState: nextState, wallet: nextWallet, onDestination: (_) {});
    failAcknowledgement = false;
    pending['destination'] = 'learn';
    await nextService.synchronize();
    expect(nextState.state.stars, 9);
    expect(nextState.state.xp, 30);
    expect(acknowledged, ['race-1']);
    nextService.dispose();
    nextState.dispose();
  });

  test('simultaneous resumed callbacks share the same replay operation',
      () async {
    final wallet = RewardWalletRepository();
    final state = LumoAppState(walletRepository: wallet);
    var navigations = 0;
    final service = EmbeddedGameService(
        appState: state, wallet: wallet, onDestination: (_) => navigations++);
    await Future.wait(
        [service.synchronize(), service.synchronize(), service.synchronize()]);
    expect(state.state.stars, 9);
    expect(navigations, 1);
    service.dispose();
    state.dispose();
  });

  test(
      'parent reset removes pending engine rewards before resetting the wallet',
      () async {
    final wallet = RewardWalletRepository();
    final state = LumoAppState(walletRepository: wallet);
    final service = EmbeddedGameService(
        appState: state, wallet: wallet, onDestination: (_) {});
    failAcknowledgement = true;
    await service.synchronize();
    expect(state.state.stars, 9);
    await state.resetAllProfile();
    failAcknowledgement = false;
    await service.synchronize();
    expect(state.state.stars, 0);
    expect(wallet.snapshot.stars, 0);
    service.dispose();
    state.dispose();
  });

  test(
      'resume during a stale read drains the newly completed race before returning',
      () async {
    final wallet = RewardWalletRepository();
    final state = LumoAppState(walletRepository: wallet);
    final destinations = <LumoSection>[];
    final service = EmbeddedGameService(
        appState: state, wallet: wallet, onDestination: destinations.add);
    final staleRead = Completer<String>();
    var reads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pendingGameEvents') {
        reads++;
        return reads == 1 ? staleRead.future : jsonEncode(pending);
      }
      if (call.method == 'acknowledgeGameEvents') return true;
      return null;
    });
    final first = service.synchronize();
    await Future<void>.delayed(Duration.zero);
    final resumed = service.synchronize();
    staleRead.complete(jsonEncode({'results': []}));
    await Future.wait([first, resumed]);
    expect(reads, 2);
    expect(state.state.stars, 9);
    expect(destinations, [LumoSection.games]);
    service.dispose();
    state.dispose();
  });
  test('new native games award explicit XP once and reject malformed rewards', () async {
    final wallet = RewardWalletRepository();
    final state = LumoAppState(walletRepository: wallet);
    final service = EmbeddedGameService(appState: state, wallet: wallet, onDestination: (_) {});
    pending['results'] = [
      for (final game in ['build', 'puzzle', 'rhythm', 'treasure'])
        {'game': game, 'resultId': 'creative-$game', 'status': 'completed', 'stars': 3, 'xp': 24},
      {'game': 'build', 'resultId': 'bad-xp', 'status': 'completed', 'stars': 3, 'xp': -1},
      {'game': 'puzzle', 'resultId': 'bad-stars', 'status': 'completed', 'stars': 101, 'xp': 24},
    ];
    failAcknowledgement = true;
    await service.synchronize();
    expect(state.state.stars, 12);
    expect(state.state.xp, 96);
    failAcknowledgement = false;
    await service.synchronize();
    expect(state.state.stars, 12);
    expect(state.state.xp, 96);
    expect(acknowledged, hasLength(4));
    expect((pending['results'] as List).map((e) => e['resultId']), ['bad-xp', 'bad-stars']);
    service.dispose(); state.dispose();
  });

}
