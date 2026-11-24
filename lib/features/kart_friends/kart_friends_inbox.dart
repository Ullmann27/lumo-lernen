import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../lumo3d/lumo3d_launcher.dart';
import 'kart_friend_ghost.dart';

/// Empfang eines „Lumo-Geists“: über „Öffnen mit Lumo“ / „Teilen an Lumo“ (Android-Host
/// hält die Datei bereit) oder über die Dateiauswahl im Elternbereich.
/// Kein Netz, kein Konto: Die Datei kommt über den Weg, den die Eltern wählen.
class KartFriendsInbox {
  KartFriendsInbox._();

  static const MethodChannel channel =
      MethodChannel('lumo_lernen/kart_friends');
  static bool _showing = false;

  /// Holt eine per Android-Intent angekommene Datei (einmalig) und zeigt die Einladung.
  static Future<void> checkIncoming(
      BuildContext context, LumoAppState appState) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || _showing) {
      return;
    }
    Uint8List? data;
    try {
      data = await channel.invokeMethod<Uint8List>('takeIncomingGhost');
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      if (context.mounted) {
        await showInvitation(
            context,
            appState,
            KartFriendGhostResult.error(
                error.message ?? 'Die Datei konnte nicht gelesen werden.'));
      }
      return;
    }
    if (data == null || !context.mounted) return;
    await showInvitation(context, appState, KartFriendGhost.read(data));
  }

  /// Android-Dateiauswahl (keine Berechtigung nötig), dann dieselbe Einladung.
  static Future<void> pickFile(
      BuildContext context, LumoAppState appState) async {
    Uint8List? data;
    try {
      data = await channel.invokeMethod<Uint8List>('pickGhostFile');
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content:
                Text('Geister öffnen geht in der vollständigen Android-App.')));
      }
      return;
    } on PlatformException catch (error) {
      data = null;
      if (context.mounted) {
        await showInvitation(
            context,
            appState,
            KartFriendGhostResult.error(
                error.message ?? 'Die Datei konnte nicht gelesen werden.'));
      }
      return;
    }
    if (data == null || !context.mounted) return;
    await showInvitation(context, appState, KartFriendGhost.read(data));
  }

  static Future<void> showInvitation(BuildContext context,
      LumoAppState appState, KartFriendGhostResult result) async {
    if (_showing) return;
    _showing = true;
    try {
      // Ohne Elternfreigabe wird ein angekommener Geist weder gezeigt noch gestartet.
      if (result.ghost != null &&
          !appState.state.settings.ghostDuelEnabled) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const ValueKey('kartFriendNotAllowed'),
            icon: const Icon(Icons.lock_outline_rounded),
            title: const Text('Geister-Duell ist noch nicht erlaubt'),
            content: const Text(
                'Eine Geist-Datei für Lumo Kart ist angekommen. Eltern können das '
                'Geister-Duell im Elternbereich unter „Mit Freunden spielen“ erlauben.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Verstanden'),
              ),
            ],
          ),
        );
        return;
      }
      final ghost = result.ghost;
      final start = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const ValueKey('kartFriendInvitation'),
          icon: Icon(ghost == null
              ? Icons.info_outline_rounded
              : Icons.sports_score_rounded),
          title: Text(ghost == null
              ? 'Dieser Geist passt nicht'
              : '${ghost.name} fordert dich heraus!'),
          content: Text(ghost == null
              ? result.message!
              : 'Lumo Kart · ${ghost.trackName} · Zeit ${ghost.timeText}\n\n'
                  '${ghost.name} fährt als goldener Geist mit. Schaffst du es schneller? '
                  'Danach kannst du deinen eigenen Geist zurückschicken.'),
          actions: [
            if (ghost != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Später'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(ghost != null),
              child: Text(
                  ghost == null ? 'Verstanden' : 'Gegen ${ghost.name} fahren'),
            ),
          ],
        ),
      );
      if (start == true && ghost != null && context.mounted) {
        await launchLumo3D(context,
            scene: 'kart',
            appState: appState,
            kartFriendGhost: ghost.launchText);
      }
    } finally {
      _showing = false;
    }
  }
}
