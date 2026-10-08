import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/reward_wallet_repository.dart';

// The native channel completes only when the game returns. Keep the guard
// outside a screen State: navigation/Fold rebuilds may replace that State.
bool _launchInProgress = false;

/// Opens the bundled Godot world after saving rewards and awaits its return.
/// A cancelled, overlapping or failed request returns false.
Future<bool> launchLumo3D(
  BuildContext context, {
  String scene = 'kart',
  int? grade,
  String? subject,
  LumoAppState? appState,
}) async {
  if (!context.mounted || appState?.resetting == true) return false;
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    _showLaunchMessage(
      context,
      'Die 3D-Spielwelten sind in der vollständigen Android-App enthalten.',
    );
    return false;
  }
  if (_launchInProgress) return false;

  final originRoute = ModalRoute.of(context);
  final generation = appState?.profileGeneration;
  _launchInProgress = true;
  try {
    try {
      await appState?.flushRewards();
    } catch (_) {
      if (context.mounted) {
        _showLaunchMessage(
          context,
          'Deine Sterne konnten noch nicht gespeichert werden. '
          'Bitte versuche den Spielstart erneut.',
        );
      }
      return false;
    }
    final childKey = await _childSaveKey(appState);
    // Do not open an Activity after leaving the page or resetting the profile
    // while storage was busy. Reward saving itself is never cancelled here.
    if (!context.mounted ||
        appState?.resetting == true ||
        appState?.profileGeneration != generation ||
        (originRoute != null && !originRoute.isCurrent)) {
      return false;
    }
    const bridge = MethodChannel('lumo_lernen/bridge');
    // Alle je verdienten Sterne (nur steigend): Die Kart-Werkstatt rechnet damit, ohne dass
    // Tuning dem Kind die Sterne für Belohnungen wegnimmt. Fehlt der Wallet-Stand, gilt der Kontostand.
    var lifetimeStars = appState?.state.stars ?? 0;
    try {
      final wallet = await RewardWalletRepository.instance.load();
      if (wallet.totalEarnedStars > lifetimeStars) {
        lifetimeStars = wallet.totalEarnedStars;
      }
    } catch (_) {}
    // Loading lifetime earnings may wait on storage too. Recheck the same
    // request immediately before launching: its page/profile may have changed
    // since the child save identity was resolved.
    if (!context.mounted ||
        appState?.resetting == true ||
        appState?.profileGeneration != generation ||
        (originRoute != null && !originRoute.isCurrent)) {
      return false;
    }
    final response = await bridge.invokeMapMethod<String, dynamic>('launch3D', {
      'scene': scene,
      'grade': grade ?? appState?.state.grade ?? 1,
      'subject': subject ?? appState?.state.subject ?? 'Mathematik',
      'stars': appState?.state.stars ?? 0,
      'lifetimeStars': lifetimeStars,
      'childKey': childKey,
    });
    // MainActivity returns a destination map on actual Activity return.
    // Null/malformed replies must not masquerade as successful game returns.
    final destination = response?['destination'];
    if (destination is! String || destination.isEmpty) {
      if (context.mounted) {
        _showLaunchMessage(
          context,
          'Die Rückkehr aus dem Spiel wurde nicht bestätigt. '
          'Bitte versuche es erneut.',
        );
      }
      return false;
    }
    return true;
  } on PlatformException catch (error) {
    if (context.mounted) {
      _showLaunchMessage(
        context,
        error.code == 'game_running'
            ? 'Ein Spiel ist bereits geöffnet oder wird gerade beendet. '
                  'Bitte versuche es nach der Rückkehr erneut.'
            : 'Das Spiel konnte nicht starten. Bitte versuche es erneut.',
      );
    }
    return false;
  } on MissingPluginException {
    if (context.mounted) {
      _showLaunchMessage(
        context,
        'Dieser App-Version fehlt die Verbindung zum 3D-Spiel. '
        'Bitte verwende die vollständige Android-App.',
      );
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      _showLaunchMessage(
        context,
        'Das Spiel konnte nicht starten. Bitte versuche es erneut.',
      );
    }
    return false;
  } finally {
    // No timeout: a healthy race may run for any duration. Unlock on return,
    // cancellation or error, not while the native game is still active.
    _launchInProgress = false;
  }
}

Future<String> _childSaveKey(LumoAppState? appState) async {
  final preferences = await SharedPreferences.getInstance();
  const key = 'lumo_3d_save_salt_v1';
  var salt = preferences.getString(key);
  if (salt == null) {
    final random = Random.secure();
    salt = List.generate(24, (_) => random.nextInt(256)
        .toRadixString(16).padLeft(2, '0')).join();
    if (!await preferences.setString(key, salt)) {
      throw StateError('Save identity could not be persisted');
    }
  }
  final state = appState?.state;
  return 'p_${sha256.convert(utf8.encode('$salt|${state?.childName ?? ''}|${state?.grade ?? 1}')).toString().substring(0, 32)}';
}

void _showLaunchMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
}
