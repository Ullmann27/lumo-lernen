import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/legacy_learning_data.dart';
import '../../core/app_settings.dart';
import '../../core/native_profile_key_repository.dart';
import '../../core/reward_wallet_repository.dart';
import '../../core/lumo_voice.dart';
import '../../domain/tutoring/native_learning_activity.dart';
import '../../domain/world/world_school_mission.dart';
import '../../widgets/fox/lumo_companion_requests.dart';
import '../kart_friends/kart_friend_ghost.dart';
import 'lumo_game_entry_overlay.dart';

// The native channel completes only when the game returns. Keep the guard
// outside a screen State: navigation/Fold rebuilds may replace that State.
bool _launchInProgress = false;

/// Opens the bundled Godot world after saving rewards and awaits its return.
/// A cancelled, overlapping or failed request returns false.
Future<bool> launchLumo3D(
  BuildContext context, {
  String scene = 'kart',
  bool livingVillage = false,
  int? grade,
  String? subject,
  LumoAppState? appState,
  NativeLearningActivity? learning,
  String? connectFourToken,
  String? tableToken,
  String? legacyGameKey,
  ValueChanged<Map<String, Object?>>? onLearningResult,
  String? kartFriendGhost,
  Map<String, Object>? worldLearningReceipt,
  ValueChanged<Map<String, Object?>>? onWorldMission,
}) async {
  if (!context.mounted || appState?.resetting == true) return false;
  if ((worldLearningReceipt != null || onWorldMission != null) &&
      scene != 'world') {
    return false;
  }
  final launchGrade = grade ?? appState?.state.grade ?? 1;
  final checkedWorldReceipt = worldLearningReceipt == null
      ? null
      : parseWorldLearningReceipt(worldLearningReceipt, grade: launchGrade);
  if (scene == 'world' &&
      (launchGrade < 1 ||
          launchGrade > 4 ||
          (worldLearningReceipt != null && checkedWorldReceipt == null))) {
    return false;
  }
  // Only reviewed, bounded lesson descriptors open the educational route.
  if ((scene == 'learning') != (learning != null)) return false;
  if (scene == 'learning' && learning?.kind == 'task_card') {
    return false;
  }
  // The economy is opt-in. Never silently open Kart or classic settlements.
  if ((scene == 'settlement') != livingVillage) return false;
  if (legacyGameKey != null &&
      (appState == null ||
          !const ['kart', 'jump', 'puzzle', 'build', 'rhythm', 'treasure']
              .contains(scene))) {
    return false;
  }
  if ((scene == 'connect_four') != (connectFourToken != null) ||
      (connectFourToken != null &&
          !RegExp(r'^[a-f0-9]{32}$').hasMatch(connectFourToken))) {
    return false;
  }
  final tableGame = const {'memory', 'quiz'}.contains(scene);
  if (tableGame != (tableToken != null) ||
      (tableGame && appState == null) ||
      (tableToken != null && !RegExp(r'^[a-f0-9]{32}$').hasMatch(tableToken))) {
    return false;
  }
  // Ein Freundes-Geist gehört nur ins Kart, nur in der geprüften Textform und nur mit
  // der Elternfreigabe „Geister-Duell“.
  if (kartFriendGhost != null &&
      (scene != 'kart' ||
          !KartFriendGhost.isLaunchText(kartFriendGhost) ||
          appState?.state.settings.ghostDuelEnabled != true)) {
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
  final learningIdentity = learning == null
      ? null
      : LumoCompanionRequests.instance.learningIdentity.value;
  bool sameLearningTask() {
    if (learningIdentity == null) return true;
    final current = LumoCompanionRequests.instance.learningIdentity.value;
    // Recording this illustration as help can advance the snapshot while
    // storage is awaited. Keep that same task; reject a different task/step.
    return current != null &&
        current.sessionId == learningIdentity.sessionId &&
        current.taskId == learningIdentity.taskId &&
        current.stepId == learningIdentity.stepId &&
        current.cancelEpoch - learningIdentity.cancelEpoch ==
            current.revision - learningIdentity.revision;
  }

  LearningProfileLease? owner;
  bool currentOwner() =>
      context.mounted &&
      appState?.resetting != true &&
      appState?.profileGeneration == generation &&
      sameLearningTask() &&
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
    final launchLearningIdentity = learning == null
        ? null
        : LumoCompanionRequests.instance.learningIdentity.value;
    final launchTask = LumoCompanionRequests.instance.taskContext.value;
    final allowedLearningActions = launchLearningIdentity != null &&
            launchTask != null &&
            !launchTask.isExam
        ? launchTask.allowedActions.map((action) => action.name).toList()
        : const <String>['stop'];
    final response = await bridge.invokeMapMethod<String, dynamic>('launch3D', {
      'scene': scene,
      if (livingVillage) ...{
        'livingVillage': true,
        'settlementMode': 'settlement',
      },
      'grade': launchGrade,
      'subject': subject ?? appState?.state.subject ?? 'Mathematik',
      'stars': appState?.state.stars ?? 0,
      'lifetimeStars': lifetimeStars,
      'childKey': childKey,
      if (checkedWorldReceipt != null)
        'worldLearningReceipt': checkedWorldReceipt,
      'reduceAnimations':
          (appState?.state.settings.reduceAnimations ?? false) ||
              (appState?.state.settings.calmMode ?? false),
      if (learning != null) ...{
        'learning': {
          ...learning.toLaunchOptions(),
          'allowedActions': allowedLearningActions,
          if (launchLearningIdentity != null)
            'scope': launchLearningIdentity.toJson(),
        },
        'learningMicrophoneEnabled':
            appState?.state.settings.microphoneEnabled == true,
      },
      if (learning != null ||
          scene == 'build' ||
          scene == 'settlement' ||
          scene == 'world') ...{
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
      if (scene == 'kart') ...{
        // Der Vorname (Namensschild im WLAN-Rennen, verschickter Geist) geht nur mit
        // einer der beiden Elternfreigaben ins Spiel; beide sind als Vorgabe aus.
        'playerName': (appState?.state.settings.lanPlayEnabled == true ||
                appState?.state.settings.ghostDuelEnabled == true)
            ? (appState?.state.childName ?? '')
            : '',
        'friendsLan': appState?.state.settings.lanPlayEnabled == true,
        'friendsOnline': appState?.state.settings.kartOnlineEnabled == true,
        'kartOnlineEndpoint': appState?.state.settings.kartOnlineEnabled == true
            ? AppSettings.sanitizeKartOnlineUrl(
                appState?.state.settings.kartOnlineUrl)
            : '',
        'friendsGhostShare': appState?.state.settings.ghostDuelEnabled == true,
        if (kartFriendGhost != null) ...{
          'kartFriendGhost': kartFriendGhost,
          'kartFriendStart': true,
        },
      },
      if (scene == 'connect_four') 'connectFourToken': connectFourToken,
      if (tableGame) 'tableToken': tableToken,
    });
    // MainActivity returns a destination map on actual Activity return.
    // Null/malformed replies must not masquerade as successful game returns.
    final destination = response?['destination'];
    if (destination != 'games' && destination != 'learn') {
      if (context.mounted) {
        _showLaunchMessage(
          context,
          'Die Rückkehr aus dem Spiel wurde nicht bestätigt. '
          'Bitte versuche es erneut.'
          '$gameStartLogHint',
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
    // Holo-Lernräume melden eine geprüfte Zusammenfassung zurück. Die
    // Aufgabe bucht sie selbst (einmal je Ergebnis-ID) nach ihren Regeln.
    final summary = learning == null
        ? null
        : parseLearningResult(response?['learningResult']);
    if (summary != null && onLearningResult != null) {
      onLearningResult(summary);
    }
    if (scene == 'world' &&
        destination == 'learn' &&
        onWorldMission != null &&
        currentOwner()) {
      final mission =
          parseWorldMission(response?['worldMission'], grade: launchGrade);
      if (mission != null) onWorldMission(mission);
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
        (error.code == 'game_running'
                ? 'Ein Spiel ist bereits geöffnet oder wird gerade beendet. '
                    'Bitte versuche es nach der Rückkehr erneut.'
                : 'Das Spiel konnte nicht starten. Bitte versuche es erneut.') +
            gameStartLogHint,
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
        'Das Spiel konnte nicht starten. Bitte versuche es erneut.'
        '$gameStartLogHint',
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

/// Accept only the bounded local request. A restored Godot integer may be
/// serialized as 1.0; its canonical Dart representation remains an int.
@visibleForTesting
Map<String, Object>? parseWorldMission(Object? raw, {required int grade}) {
  if (raw is! String || raw.isEmpty || raw.length > 2000) return null;
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map ||
      decoded.length != 6 ||
      decoded['grade'] is! num ||
      decoded['grade'] != grade) {
    return null;
  }
  final request =
      WorldSchoolMissionRequest.tryParse({...decoded, 'grade': grade});
  return request?.toJson();
}

/// A receipt never supplies owner identity or rewards. Those remain controlled
/// by the captured child lease and the world's matching pending request ID.
@visibleForTesting
Map<String, Object>? parseWorldLearningReceipt(Object? raw,
    {required int grade}) {
  if (raw is! Map ||
      raw.length != 7 ||
      raw['completed'] != true ||
      raw['missionId'] != WorldSchoolMissionRequest.missionId ||
      raw['grade'] is! num ||
      raw['grade'] != grade) {
    return null;
  }
  final request = WorldSchoolMissionRequest.tryParse({
    'version': raw['version'],
    'id': raw['missionId'],
    'requestId': raw['requestId'],
    'subject': raw['subject'],
    'grade': grade,
    'returnGame': raw['returnGame'],
  });
  if (request == null) return null;
  return {
    'version': WorldSchoolMissionRequest.version,
    'missionId': WorldSchoolMissionRequest.missionId,
    'requestId': request.requestId,
    'subject': WorldSchoolMissionRequest.subject,
    'grade': request.grade,
    'returnGame': WorldSchoolMissionRequest.returnGame,
    'completed': true,
  };
}

const _tutorWays = {
  'rechenrahmen',
  'zahlenstrahl',
  'zerlegen',
  'verdoppeln',
  'tauschen',
};

/// Strenge Prüfung der Holo-Zusammenfassung aus dem nativen Rückgabewert.
/// Unbekannte oder unplausible Daten werden verworfen (dann gilt die alte
/// Regel: das Kind antwortet in der App).
@visibleForTesting
Map<String, Object?>? parseLearningResult(Object? raw) {
  if (raw is! String || raw.isEmpty || raw.length > 4000) return null;
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  final holo = decoded['holo'] is Map ? decoded['holo'] as Map : decoded;
  final resultId = holo['resultId'];
  final taskId = holo['taskId'];
  final kind = holo['kind'];
  final answer = holo['originalAnswer'];
  final correct = holo['originalCorrect'];
  final hint = holo['hintLevel'];
  final attempts = holo['originalAttempts'];
  final twinSolved = holo['twinSolved'];
  final twinAttempts = holo['twinAttempts'];
  final twinPrompt = holo['twinPrompt'];
  if (resultId is! String ||
      resultId.isEmpty ||
      resultId.length > 160 ||
      taskId is! String ||
      taskId.isEmpty ||
      taskId.length > 120 ||
      (kind != 'holo_word_problem' &&
          kind != 'holo_sentence' &&
          kind != 'tutor') ||
      answer is! String ||
      answer.length > 240 ||
      correct is! bool ||
      hint is! int ||
      hint < 0 ||
      hint > (kind == 'tutor' ? 3 : 2) ||
      attempts is! int ||
      attempts < 0 ||
      attempts > 50 ||
      twinSolved is! bool ||
      twinAttempts is! int ||
      twinAttempts < 0 ||
      twinAttempts > 50 ||
      twinPrompt is! String ||
      twinPrompt.length > 240 ||
      (correct && answer.isEmpty)) {
    return null;
  }
  // Die Nachhilfe beantwortet die Originalaufgabe nie: nur Hilfestufe und
  // Zwillingsaufgabe dürfen zurückkommen.
  if (kind == 'tutor' &&
      (correct ||
          answer.isNotEmpty ||
          attempts != 0 ||
          !_tutorWays.contains(holo['mode']))) {
    return null;
  }
  return <String, Object?>{
    'resultId': resultId,
    'taskId': taskId,
    'kind': kind,
    'originalAnswer': answer,
    'originalCorrect': correct,
    'hintLevel': hint,
    'originalAttempts': attempts,
    'twinSolved': twinSolved,
    'twinAttempts': twinAttempts,
    'twinPrompt': twinPrompt,
  };
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

/// Hinweis in jeder Fehlermeldung eines gescheiterten nativen Spielstarts.
const gameStartLogHint = '\nDetails im Elternbereich → Spiel-Startprotokoll.';

void _showLaunchMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
}
