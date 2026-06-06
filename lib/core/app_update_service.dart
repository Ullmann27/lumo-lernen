import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_install_helper.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.available,
    required this.currentBuildNumber,
    required this.latestBuildNumber,
    required this.releaseUrl,
    required this.apkUrl,
    required this.releaseName,
    required this.commitSha,
    this.error,
  });

  final bool available;
  final int currentBuildNumber;
  final int latestBuildNumber;
  final Uri releaseUrl;
  final Uri apkUrl;
  final String releaseName;
  final String commitSha;
  final String? error;

  bool get hasUsableDownload => apkUrl.toString().isNotEmpty;
}

class AppUpdateService {
  const AppUpdateService();

  /// Build-Nummer wird zur Compile-Zeit ueber --dart-define gesetzt.
  /// Der Release-Workflow uebergibt:
  ///   flutter build apk --dart-define=LUMO_BUILD_NUMBER=$GITHUB_RUN_NUMBER
  ///                     --dart-define=LUMO_VERSION_NAME=0.8.0
  /// Default 0 / '0.0.0' damit Dev-Builds als 'aelter als alles' gelten.
  static const int currentBuildNumber = int.fromEnvironment('LUMO_BUILD_NUMBER', defaultValue: 0);
  static const String currentVersionName = String.fromEnvironment('LUMO_VERSION_NAME', defaultValue: '0.0.0');
  /// GitHub-API fuer das neueste Release.
  /// /releases/latest ist robust gegen Tag-Umbenennungen und
  /// funktioniert auch wenn der Workflow andere Tag-Namen vergibt.
  /// Vorher: /releases/tags/lumo-lernen-debug-latest -> 404 wenn Tag nicht existiert.
  static final Uri latestReleaseApi = Uri.parse(
    'https://api.github.com/repos/Ullmann27/lumo-lernen/releases/latest',
  );
  static final Uri fallbackReleaseUrl = Uri.parse(
    'https://github.com/Ullmann27/lumo-lernen/releases/latest',
  );

  Future<AppUpdateInfo> checkLatest() async {
    // Manuelles Redirect-Following: jedes Redirect-Ziel wird gegen die
    // Whitelist geprueft. Damit kann ein boeswillig manipulierter
    // 302-Location-Header NICHT auf eine fremde Domain umleiten.
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    client.autoUncompress = true;
    try {
      final request = await client.getUrl(latestReleaseApi);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'Lumo-Lernen-App-Update-Checker');
      HttpClientResponse response = await request.close().timeout(const Duration(seconds: 12));

      // Bis zu 3 Redirects manuell folgen, jedes Mal Whitelist pruefen.
      var redirectCount = 0;
      while (response.isRedirect && redirectCount < 3) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) break;
        final redirectTarget = _trustedUri(location);
        if (redirectTarget == null) {
          return _fallbackInfo(error: 'Update-Pruefung blockiert: unsicheres Redirect-Ziel.');
        }
        await response.drain<void>();
        final nextRequest = await client.getUrl(redirectTarget);
        nextRequest.followRedirects = false;
        nextRequest.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
        nextRequest.headers.set(HttpHeaders.userAgentHeader, 'Lumo-Lernen-App-Update-Checker');
        response = await nextRequest.close().timeout(const Duration(seconds: 12));
        redirectCount++;
      }

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackInfo(error: 'Update-Pruefung nicht erreichbar (${response.statusCode}).');
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return _fallbackInfo(error: 'Update-Antwort konnte nicht gelesen werden.');
      }

      final assets = (decoded['assets'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final apkAsset = _findPreferredApkAsset(assets);

      final releaseName = decoded['name']?.toString() ?? 'Lumo Lernen Debug Latest';
      final commitSha = decoded['target_commitish']?.toString() ?? '';
      final releaseUrl = _trustedUri(decoded['html_url']?.toString()) ?? fallbackReleaseUrl;
      final apkUrl = _trustedUri(apkAsset?['browser_download_url']?.toString()) ?? Uri();
      final tagName = decoded['tag_name']?.toString();
      final latestBuild = _extractLatestBuildNumber(tagName, assets);

      return AppUpdateInfo(
        available: latestBuild > currentBuildNumber && apkUrl.toString().isNotEmpty,
        currentBuildNumber: currentBuildNumber,
        latestBuildNumber: latestBuild,
        releaseUrl: releaseUrl,
        apkUrl: apkUrl,
        releaseName: releaseName,
        commitSha: commitSha,
      );
    } catch (error) {
      return _fallbackInfo(error: 'Update-Pruefung fehlgeschlagen: $error');
    } finally {
      client.close(force: true);
    }
  }

  AppUpdateInfo _fallbackInfo({String? error}) {
    return AppUpdateInfo(
      available: false,
      currentBuildNumber: currentBuildNumber,
      latestBuildNumber: currentBuildNumber,
      releaseUrl: fallbackReleaseUrl,
      apkUrl: Uri(),
      releaseName: 'Lumo Lernen Debug Latest',
      commitSha: '',
      error: error,
    );
  }

  Map<String, dynamic>? _findPreferredApkAsset(List<Map<String, dynamic>> assets) {
    final direct = assets.where((asset) => asset['name']?.toString() == 'Lumo-Lernen-latest.apk');
    if (direct.isNotEmpty) return direct.first;
    final apks = assets.where((asset) => (asset['name']?.toString() ?? '').endsWith('.apk'));
    if (apks.isEmpty) return null;
    return apks.first;
  }

  /// Heinz Bug 2026-05-21: Update-Pruefung sagte 'neueste Version'
  /// obwohl Build 156 schon draussen war. Ursache: das alte Regex
  /// suchte 'debug-NUMBER.apk', aber die APKs heissen jetzt
  /// 'Lumo-Lernen-156-abc1234.apk' und der Release-Tag heisst
  /// 'build-156'. Beide Namensschemas werden jetzt erkannt;
  /// primaer wird der Release-Tag genommen (robuster).
  int _extractLatestBuildNumber(
    String? tagName,
    List<Map<String, dynamic>> assets,
  ) {
    // Primaer: aus Release-Tag (z.B. 'build-156').
    if (tagName != null && tagName.isNotEmpty) {
      final match = RegExp(r'(?:build|debug)-(\d+)').firstMatch(tagName);
      if (match != null) {
        final parsed = int.tryParse(match.group(1) ?? '');
        if (parsed != null) return parsed;
      }
    }
    // Fallback: aus Asset-Datei-Namen. Erkennt sowohl das alte
    // 'debug-NUMBER.apk' als auch das neue
    // 'Lumo-Lernen-NUMBER-sha.apk' Schema.
    var latest = currentBuildNumber;
    final pattern = RegExp(r'(?:debug|Lumo-Lernen)-(\d+)');
    for (final asset in assets) {
      final name = asset['name']?.toString() ?? '';
      final match = pattern.firstMatch(name);
      if (match == null) continue;
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > latest) latest = parsed;
    }
    return latest;
  }

  Uri? _trustedUri(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme.isEmpty) return null;
    final host = uri.host.toLowerCase();
    final allowed = host == 'github.com' || host.endsWith('.github.com') || host == 'objects.githubusercontent.com';
    if (!allowed) return null;
    return uri;
  }

  Future<bool> openUpdate(AppUpdateInfo info) async {
    final url = info.hasUsableDownload ? info.apkUrl : info.releaseUrl;
    if (url.toString().isEmpty || _trustedUri(url.toString()) == null) return false;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// 2026-06-06 Heinz: 'einfach Update-Button druecken, alles automatisch'.
  /// Diese Methode laedt die APK direkt in den App-Cache und startet
  /// dann den System-Installer ueber den AppInstallHelper (MethodChannel
  /// zu Kotlin/PackageInstaller). Liefert Status + ggf. Fehlertext.
  ///
  /// Reihenfolge:
  ///   1. Berechtigungs-Check ('REQUEST_INSTALL_PACKAGES')
  ///   2. APK-URL whitelisten (gleiche Logik wie checkLatest)
  ///   3. Download mit Progress-Callback in den App-Cache
  ///   4. install() ruft Android-Installer auf
  Future<AppUpdateDownloadResult> downloadAndInstall(
    AppUpdateInfo info, {
    ValueChanged<double>? onProgress,
    AppInstallHelper installer = const AppInstallHelper(),
  }) async {
    if (!Platform.isAndroid) {
      return const AppUpdateDownloadResult(
        success: false,
        error:
            'Update wird nur auf Android unterstuetzt - oeffne den Link im Browser.',
      );
    }
    if (!info.hasUsableDownload) {
      return const AppUpdateDownloadResult(
        success: false,
        error: 'Keine gueltige APK-URL im Release.',
      );
    }
    if (_trustedUri(info.apkUrl.toString()) == null) {
      return const AppUpdateDownloadResult(
        success: false,
        error: 'Download-URL ist nicht aus dem offiziellen GitHub-Repo.',
      );
    }
    final canInstall = await installer.canInstall();
    if (!canInstall) {
      await installer.requestInstallPermission();
      return const AppUpdateDownloadResult(
        success: false,
        error: 'Bitte "Aus dieser Quelle installieren" fuer Lumo Lernen freigeben.',
        needsPermission: true,
      );
    }
    final tempPath = await _downloadApk(info.apkUrl, onProgress: onProgress);
    if (tempPath == null) {
      return const AppUpdateDownloadResult(
        success: false,
        error: 'Download der neuen Version fehlgeschlagen.',
      );
    }
    final started = await installer.install(tempPath);
    if (!started) {
      return AppUpdateDownloadResult(
        success: false,
        error: 'Installer konnte nicht gestartet werden (Datei: $tempPath).',
      );
    }
    return const AppUpdateDownloadResult(success: true);
  }

  /// Laedt die APK in den Anwendungs-Cache. Manuelles Redirect-Following
  /// mit Whitelist (gleiche Logik wie checkLatest), plus ProgressCallback
  /// alle ~5% damit die UI einen Fortschritts-Indikator zeigen kann.
  Future<String?> _downloadApk(
    Uri apkUrl, {
    ValueChanged<double>? onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    client.autoUncompress = true;
    try {
      Uri current = apkUrl;
      HttpClientResponse response = await _openWithRedirects(client, current);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        return null;
      }

      // Anwendungs-Cache erfragen (ohne path_provider Plugin direkt
      // ueber Platform.environment - das ist nicht zuverlaessig auf
      // Android. Stattdessen: Directory.systemTemp - reicht fuer die
      // einmalige APK-Datei, wird vom System aufgeraeumt).
      final tmpDir = Directory.systemTemp;
      final apkFile = File(
          '${tmpDir.path}/lumo-lernen-update-${DateTime.now().millisecondsSinceEpoch}.apk');
      final sink = apkFile.openWrite();
      final total = response.contentLength;
      var received = 0;
      var lastReported = -0.06;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          final pct = received / total;
          if (pct - lastReported >= 0.05) {
            onProgress(pct.clamp(0.0, 1.0));
            lastReported = pct;
          }
        }
      }
      await sink.flush();
      await sink.close();
      if (onProgress != null) onProgress(1.0);
      return apkFile.path;
    } catch (e) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<HttpClientResponse> _openWithRedirects(
      HttpClient client, Uri start) async {
    Uri current = start;
    var redirectCount = 0;
    while (true) {
      final request = await client.getUrl(current);
      request.followRedirects = false;
      request.headers
          .set(HttpHeaders.userAgentHeader, 'Lumo-Lernen-App-Update-Checker');
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (!response.isRedirect || redirectCount >= 4) {
        return response;
      }
      final location = response.headers.value(HttpHeaders.locationHeader);
      if (location == null) return response;
      await response.drain<void>();
      final next = _trustedUri(location);
      if (next == null) {
        // Unsicheres Redirect - abbrechen
        final req = await client.getUrl(current);
        req.followRedirects = false;
        return req.close();
      }
      current = next;
      redirectCount++;
    }
  }
}

/// Ergebnis-Struktur fuer downloadAndInstall().
class AppUpdateDownloadResult {
  const AppUpdateDownloadResult({
    required this.success,
    this.error,
    this.needsPermission = false,
  });
  final bool success;
  final String? error;
  /// True wenn der User erst die Berechtigung 'Apps installieren'
  /// in den System-Einstellungen aktivieren muss.
  final bool needsPermission;
}

