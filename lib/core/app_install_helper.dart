// ════════════════════════════════════════════════════════════════════════
// APP INSTALL HELPER — bridge zu Android-PackageInstaller
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Heinz: "Ich will dass meine Tochter nur den Update-Button
// drueckt und alles passiert automatisch."
//
// Vorher: AppUpdateService.openUpdate() rief launchUrl(apkUrl,
// externalApplication) auf - das oeffnete den Browser, der die APK
// downloadete, der User musste dann die Notification antippen, den
// "Unknown sources"-Dialog bestaetigen, etc.
//
// Jetzt: Dart-Seite downloaded die APK in den App-Cache, dann ruft
// dieser Helper via MethodChannel die native Kotlin-Seite an, die per
// FileProvider + Intent.ACTION_VIEW direkt den System-Installer
// triggert. Ein Klick zum Update.
//
// Native-Seite: android/app/src/main/kotlin/dev/ullmann/lumo/
//   MainActivity.kt (vom CI release-apk.yml ueberschrieben)
// FileProvider: res/xml/lumo_file_paths.xml (vom CI generiert)
// Permission: REQUEST_INSTALL_PACKAGES (vom CI in Manifest gesetzt)
// ════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppInstallHelper {
  const AppInstallHelper();

  static const _channel = MethodChannel('lumo_lernen/installer');

  /// Liefert true, wenn die App das Recht hat, externe APKs zu installieren.
  /// Auf Android 8+ braucht die App das REQUEST_INSTALL_PACKAGES-Recht plus
  /// den User-Toggle 'Aus dieser Quelle installieren'.
  Future<bool> canInstall() async {
    if (!_isAndroid()) return false;
    try {
      final result = await _channel.invokeMethod<bool>('canInstall');
      return result ?? false;
    } catch (e) {
      debugPrint('AppInstallHelper.canInstall error: $e');
      return false;
    }
  }

  /// Oeffnet die System-Einstellung, wo der User die Berechtigung
  /// 'Apps installieren' fuer diese App aktivieren kann.
  Future<bool> requestInstallPermission() async {
    if (!_isAndroid()) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestInstallPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('AppInstallHelper.requestInstallPermission error: $e');
      return false;
    }
  }

  /// Startet den System-Installer fuer eine bereits heruntergeladene APK.
  /// Gibt true zurueck, wenn der Intent erfolgreich gestartet wurde
  /// (der User sieht dann den 'Installieren?'-Dialog). False bei Fehler.
  Future<bool> install(String apkPath) async {
    if (!_isAndroid()) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'install',
        <String, String>{'path': apkPath},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('AppInstallHelper.install error: $e');
      return false;
    }
  }

  bool _isAndroid() {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }
}
