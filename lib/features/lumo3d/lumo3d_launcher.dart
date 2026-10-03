import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';

/// Opens the Godot world bundled in this APK and awaits its return to Flutter.
Future<bool> launchLumo3D(
  BuildContext context, {
  String scene = 'kart',
  int? grade,
  String? subject,
  LumoAppState? appState,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Lumo Kart und Wolkeninseln sind in der Android-App enthalten.'),
      ));
    }
    return false;
  }
  try {
    await appState?.flushRewards();
    const bridge = MethodChannel('lumo_lernen/bridge');
    await bridge.invokeMethod<Map>('launch3D', {
      'scene': scene,
      'grade': grade ?? appState?.state.grade ?? 1,
      'subject': subject ?? appState?.state.subject ?? 'Mathematik',
      'stars': appState?.state.stars ?? 0,
    });
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Das Spiel konnte nicht starten. Bitte schließe Lumo und öffne es erneut.'),
      ));
    }
    return false;
  }
}
