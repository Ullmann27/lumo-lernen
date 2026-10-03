import 'package:flutter/material.dart';

import '../app/app_state.dart';

/// All sensor entry points honour the same saved, explicit parent choice.
/// Android's runtime permission is requested only after this check and a tap.
class LumoFeaturePermissions {
  static Future<bool> microphone(
      BuildContext context, LumoAppState state) async {
    await state.ensureSettingsLoaded();
    if (!context.mounted) return false;
    if (state.state.settings.microphoneEnabled) return true;
    _show(context,
        'Das Mikrofon ist ausgeschaltet. Deine Eltern können es in den Einstellungen freigeben. Texteingabe bleibt möglich.');
    return false;
  }

  static Future<bool> camera(BuildContext context, LumoAppState state) async {
    await state.ensureSettingsLoaded();
    if (!context.mounted) return false;
    if (state.state.settings.scannerEnabled) return true;
    _show(context,
        'Die Kamera ist ausgeschaltet. Deine Eltern können sie in den Einstellungen freigeben.');
    return false;
  }

  static void _show(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }
}
