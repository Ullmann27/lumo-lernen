import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/legacy_learning_data.dart';
import '../../core/native_profile_key_repository.dart';
import '../../core/reward_wallet_repository.dart';
import '../../core/lumo_voice.dart';
import '../../domain/tutoring/native_learning_activity.dart';
import 'lumo_game_entry_overlay.dart';

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
  NativeLearningActivity? learning,
  String? cardsToken,
  String? connectFourToken,
  String? tableToken,
  String? legacyGameKey,
}) async {
  if (!context.mounted || appState?.resetting == true) return false;
  // Only reviewed, bounded lesson descriptors open the educational route.
  if ((scene == 'learning') != (learning != null)) return false;
  if (legacyGameKey != null &&
      (appState == null ||
          !const ['kart', 'jump', 'puzzle', 'build', 'rhythm', 'treasure']
              .contains(scene))) {
    return false;
  }
  if (scene == 'cards' &&
      (cardsToken == null || !RegExp(r'^[a-f0-9]{32}$').hasMatch(cardsToken))) {
    return false;
  }
  if ((scene == 'connect_four') != (connectFourToken != null) ||
      (connectFourToken != null &&
          !RegExp(r'^[a-f0-9]{32}$').hasMatch(connectFourToken))) return false;
  final tableGame = const {'memory', 'quiz'}.contains(scene);
  if (tableGame != (tableToken != null) ||
      (tableGame && appState == null) ||
      (tableToken != null && !RegExp(r'^[a-f0-9]{32}$').hasMatch(tableToken))) {
    return false;
  }
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
  final previousName = appState?.state.childName ?? '';
  final previousGrade = appState?.state.grade ?? 1;
  LearningProfileLease? owner;
  bool currentOwner() =>
      context.mounted &&
      appState?.resetting != true &&
      appState?.profileGeneration == generation &&
      (originRoute == null || originRoute.isCurrent) &&
      (appState == null ||
          (owner != null &&
              appState.canUseLearningLease(owner) &&
              appState.school.cachedActiveStudentId ==
                  (owner.logStudentId == 'self' ? null : owner.studentId)));
  _launchInProgress = true;
  final entry = LumoGameEntryHandle.show(
    context,
    scene: scene,
    reduceMotion: (appState?.state.settings.reduceAnimations ?? false) ||
        (appState?.state.settings.calmMode ?? false) ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false),
  );
  try {
    // Capture the stable selection before settings, wallet or storage awaits.
    // Display names and school years are descriptions, never owner identities.
    if (appState != null) owner = await appState.captureLearningProfile();
    if (!currentOwner()) return false;
    await appState?.ensureSettingsLoaded();
    if (learning == null &&
        appState?.state.settings.requireDailyMissionForGames == true) {
      await appState!.loadDailyMission();
      if (!appState.canPlayToday) {
        if (context.mounted) {
          _showLaunchMessage(context,
              'Deine Tagesmission wartet auf dich. Hilfen und Pausen sind erlaubt.');
        }
        return false;
      }
    }
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
    entry?.setPhase(LumoGameEntryPhase.preparing);
    final childKey = await _childSaveKey(
      owner: owner,
      previousName: previousName,
      previousGrade: previousGrade,
      legacyGameKey: legacyGameKey,
      isCurrent: currentOwner,
    );
    // Do not open an Activity after leaving the page or resetting the profile
    // while storage was busy. Reward saving itself is never cancelled here.
    if (!currentOwner()) {
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
    if (!currentOwner()) {
      return false;
    }
    if (learning == null && appState != null && !appState.canPlayToday) {
      return false;
    }
    entry?.setPhase(LumoGameEntryPhase.opening);
    final response = await bridge.invokeMapMethod<String, dynamic>('launch3D', {
      'scene': scene,
      'grade': grade ?? appState?.state.grade ?? 1,
      'subject': subject ?? appState?.state.subject ?? 'Mathematik',
      'stars': appState?.state.stars ?? 0,
      'lifetimeStars': lifetimeStars,
      'childKey': childKey,
      'reduceAnimations':
          (appState?.state.settings.reduceAnimations ?? false) ||
              (appState?.state.settings.calmMode ?? false),
      if (learning != null) 'learning': learning.toLaunchOptions(),
      if (learning != null) ...{
        // Preserve the selected voice. Only the existing, licensed local
        // identity is available in the isolated engine; no silent fallback.
        'learningVoiceEnabled': appState?.state.settings.voiceEnabled == true &&
            appState?.state.settings.localVoiceLicenseAccepted == true &&
            LumoVoice.instance.identity == LumoVoiceIdentity.freeOffline,
        'localVoiceLicenseAccepted':
            appState?.state.settings.localVoiceLicenseAccepted == true,
        'learningAutoRead': appState?.state.settings.autoReadEnabled == true &&
            appState?.state.settings.calmMode != true,
        'learningVoiceRate':
            ((appState?.state.settings.voiceRate ?? 0.35) / 0.35)
                .clamp(0.70, 1.60),
      },
      if (scene == 'cards') 'cardsToken': cardsToken,
      if (scene == 'connect_four') 'connectFourToken': connectFourToken,
      if (tableGame) 'tableToken': tableToken,
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
    // A return belongs to the same captured child, even if Android kept the
    // engine open while the Flutter profile was changed by another action.
    if (appState?.resetting == true ||
        appState?.profileGeneration != generation ||
        (appState != null &&
            owner != null &&
            (!appState.canUseLearningLease(owner) ||
                appState.school.cachedActiveStudentId !=
                    (owner.logStudentId == 'self' ? null : owner.studentId)))) {
      return false;
    }
    return true;
  } on NativeProfileKeyException catch (error) {
    if (context.mounted && error.code != 'profile-changed') {
      _showLaunchMessage(
          context,
          'Dein Spielstand konnte nicht sicher zugeordnet werden. '
          'Die vorhandenen Daten bleiben erhalten. Bitte versuche es erneut '
          'oder öffne „Spielstände verwalten“ im Elternbereich.');
    }
    return false;
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
    entry?.close();
    _launchInProgress = false;
  }
}

Future<String> _childSaveKey({
  required LearningProfileLease? owner,
  required String previousName,
  required int previousGrade,
  required String? legacyGameKey,
  required bool Function() isCurrent,
}) async {
  const repository = NativeProfileKeyRepository();
  final ownerId =
      owner?.studentId ?? await LegacyLearningDataRepository().localStudentId();
  if (legacyGameKey != null) {
    return repository.authorizedLegacy(
        ownerId: ownerId, key: legacyGameKey, isCurrent: isCurrent);
  }
  return repository.resolve(
    ownerId: ownerId,
    isLocalProfile: owner?.logStudentId == 'self',
    legacyName: previousName,
    legacyGrade: previousGrade,
    isCurrent: isCurrent,
  );
}

void _showLaunchMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
}
