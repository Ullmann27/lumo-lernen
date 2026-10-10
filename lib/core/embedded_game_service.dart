import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../app/app_state.dart';
import 'reward_wallet_repository.dart';

/// Coordinates the private Godot activity and durable finish-line events.
class EmbeddedGameService with WidgetsBindingObserver {
  EmbeddedGameService({
    required this.appState,
    required this.onDestination,
    this.channel = const MethodChannel('lumo_lernen/bridge'),
    RewardWalletRepository? wallet,
  }) : wallet = wallet ?? RewardWalletRepository.instance;

  final LumoAppState appState;
  final ValueChanged<LumoSection> onDestination;
  final MethodChannel channel;
  final RewardWalletRepository wallet;
  Future<void>? _draining;
  bool _readAgain = false;
  bool _disposed = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(synchronize());
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(synchronize());
  }

  Future<void> synchronize() {
    if (_disposed ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return Future<void>.value();
    }
    _readAgain = true;
    return _draining ??= _drain().whenComplete(() => _draining = null);
  }

  Future<void> _drain() async {
    do {
      _readAgain = false;
      await _readEvents();
    } while (_readAgain && !_disposed);
  }

  Future<void> _readEvents() async {
    if (appState.resetting) return;
    final generation = appState.profileGeneration;
    try {
      final raw = await channel.invokeMethod<String>('pendingGameEvents');
      if (raw == null ||
          _disposed ||
          appState.resetting ||
          generation != appState.profileGeneration) {
        return;
      }
      final pending = jsonDecode(raw) as Map<String, dynamic>;
      final ids = <String>[];
      await appState.flushRewards();
      for (final event in pending['results'] as List? ?? const []) {
        if (_disposed ||
            appState.resetting ||
            generation != appState.profileGeneration) {
          return;
        }
        if (event is! Map ||
            event['status'] != 'completed' ||
            !const ['kart', 'jump', 'puzzle', 'build', 'rhythm', 'treasure']
                .contains(event['game'])) {
          continue;
        }
        final id = event['resultId'];
        final stars = event['stars'];
        final solved = event['solved'];
        final xp = event.containsKey('xp')
            ? event['xp']
            : (solved is int && solved >= 0 && solved <= 100 ? solved * 10 : null);
        if (id is! String ||
            stars is! int ||
            stars < 0 || stars > 100 ||
            xp is! int || xp < 0 || xp > 1000) {
          continue;
        }
        await wallet.awardGameResult(
            resultId: id, stars: stars, xp: xp);
        ids.add(id);
      }
      if (_disposed ||
          appState.resetting ||
          generation != appState.profileGeneration) {
        return;
      }
      await appState.hydrateFromWallet();
      if (_disposed ||
          appState.resetting ||
          generation != appState.profileGeneration) {
        return;
      }
      final destination = pending['destination'];
      if (destination == 'learn' || destination == 'games') {
        onDestination(
            destination == 'learn' ? LumoSection.learn : LumoSection.games);
      }
      await channel.invokeMethod<bool>('acknowledgeGameEvents', {
        'resultIds': ids,
        if (destination is String) 'destination': destination,
      });
    } on MissingPluginException {
      // Non-Android preview/test hosts have no engine activity.
    } catch (error) {
      // Do not acknowledge unpersisted rewards. Next resume retries the events.
      debugPrint(
          'Lumo-Spielstände werden beim nächsten Start erneut synchronisiert: $error');
    }
  }
}
