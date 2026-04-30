import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

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

  static const int currentBuildNumber = 9;
  static const String currentVersionName = '0.8.0';
  static final Uri latestReleaseApi = Uri.parse(
    'https://api.github.com/repos/Ullmann27/lumo-lernen/releases/tags/lumo-lernen-debug-latest',
  );
  static final Uri fallbackReleaseUrl = Uri.parse(
    'https://github.com/Ullmann27/lumo-lernen/releases/tag/lumo-lernen-debug-latest',
  );

  Future<AppUpdateInfo> checkLatest() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(latestReleaseApi);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'Lumo-Lernen-App-Update-Checker');
      final response = await request.close().timeout(const Duration(seconds: 12));
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
      final latestBuild = _extractLatestBuildNumber(assets);

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

  int _extractLatestBuildNumber(List<Map<String, dynamic>> assets) {
    var latest = currentBuildNumber;
    for (final asset in assets) {
      final name = asset['name']?.toString() ?? '';
      final match = RegExp(r'debug-(\d+)\.apk').firstMatch(name);
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
}
