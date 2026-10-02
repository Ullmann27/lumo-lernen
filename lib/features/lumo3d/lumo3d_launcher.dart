// Lumo 3D Launcher
//
// Verbindet die Flutter-App "lumo_lernen" mit der separaten Godot-App
// "Lumo 3D" (dev.ullmann.lumo3d).
//
// Logik:
//   1. Versuche die installierte Lumo-3D-Android-App per Intent zu oeffnen.
//   2. Wenn nicht installiert (kein Intent-Resolver): falle zurueck auf
//      die gehostete Web-Version unter https://ullmann27.github.io/lumo-godot/
//   3. Wenn beides scheitert: zeige eine Snackbar mit Fehlerhinweis.
//
// Dependency: url_launcher (schon in pubspec.yaml).

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Package-Name der separaten Godot-App.
const String lumo3DAndroidPackage = 'dev.ullmann.lumo3d';

/// Permanente Web-URL (GitHub Pages) als Fallback wenn die native App
/// nicht installiert ist.
const String lumo3DWebUrl = 'https://ullmann27.github.io/lumo-godot/';

/// Versucht die Lumo-3D-Welt zu oeffnen.
///
/// Reihenfolge:
///   - Android-Intent auf das Lumo-3D-Package
///   - Fallback: Web-URL im Browser
///
/// Gibt true zurueck wenn irgendetwas geoeffnet wurde, sonst false.
Future<bool> launchLumo3D(BuildContext context, {
  String scene = 'home',
  int grade = 1,
  String subject = 'Mathematik',
}) async {
  // Die native Host-Bridge startet Godot mit dem gewünschten Spiel.
  try {
    if (!kIsWeb && defaultTargetPlatform = = TargetPlatform.android) {
      const bridge = MethodChannel(
    'lumo_lernen/bridge');
  final ok = await bridge.invokeMethod<bool>(
      'launch3D',
      {
        'scene': scene,
    'grade': grade,
        'subject': subject,
      });
    if (ok== true) return true;
  }
  } catch (_) {
    // Intent-URL nicht resolvbar, weiter zu Versuch 2
  }

  // Versuch 2: Web-Version direkt
  final webUri = Uri.parse(lumo3DWebUrl).replace(
    queryParameters: {'scene': scene, 'grade': '$grade', 'subject': subject},
  );
  try {
    final ok = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication);
    if (ok) return true;
  } catch (_) {
    // ignore
  }

  // Beides gescheitert: Snackbar
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Lumo 3D konnte nicht geoeffnet werden. '
          'Pruefe deine Internetverbindung.',
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  return false;
}
