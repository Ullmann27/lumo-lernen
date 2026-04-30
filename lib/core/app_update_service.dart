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
        return AppUpdateInfo(
          available: false,
          currentBuildNumber: currentBuildNumber,
          latestBuildNumber: currentBuildNumber,
          releaseUrl: fallbackReleaseUrl,
          apkUrl: Uri(),
          releaseName: 'Lumo Lernen Debug Latest',
          commitSha: '',
          error: 'Update-Pruefung nicht erreichbar (${response.statusCode}).',
        );
      }

      final jsonMap = jsonDecode(body) as Map<String, dynamic>;
      final assets = (jsonMap['assets'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
            (asset) => (asset?['name']?.toString() ?? '') == 'Lumo-Lernen-latest.apk',
            orElse: () => assets.cast<Map<String, dynamic>?>().firstWhere(
                  (asset) => (asset?['name']?.toString() ?? '').endsWith('.apk'),
                  orElse: () => null,
                ),
          );
      final notesAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
            (asset) => (asset?['name']?.toString() ?? '') == 'update-info.txt',
            orElse: () => null,
          );

      final releaseName = jsonMap['name']?.toString() ?? 'Lumo Lernen Debug Latest';
      final commitSha = jsonMap['target_commitish']?.toString() ?? '';
      final releaseUrl = Uri.tryParse(jsonMap['html_url']?.toString() ?? '') ?? fallbackReleaseUrl;
      final apkUrl = Uri.tryParse(apkAsset?['browser_download_url']?.toString() ?? '') ?? Uri();
      final latestBuild = _extractBuildNumber(apkAsset?['name']?.toString(), notesAsset?['browser_download_url']?.toString());

      return AppUpdateInfo(
        available: latestBuild > currentBuildNumber || apkUrl.toString().isNotEmpty,
        currentBuildNumber: currentBuildNumber,
        latestBuildNumber: latestBuild,
        releaseUrl: releaseUrl,
        apkUrl: apkUrl,
        releaseName: releaseName,
        commitSha: commitSha,
      );
    } catch (error) {
      return AppUpdateInfo(
        available: false,
        currentBuildNumber: currentBuildNumber,
        latestBuildNumber: currentBuildNumber,
        releaseUrl: fallbackReleaseUrl,
        apkUrl: Uri(),
        releaseName: 'Lumo Lernen Debug Latest',
        commitSha: '',
        error: 'Update-Pruefung fehlgeschlagen: $error',
      );
    } finally {
      client.close(force: true);
    }
  }

  int _extractBuildNumber(String? apkName, String? notesUrl) {
    final apkMatch = RegExp(r'debug-(\d+)\.apk').firstMatch(apkName ?? '');
    if (apkMatch != null) return int.tryParse(apkMatch.group(1) ?? '') ?? currentBuildNumber;
    final notesMatch = RegExp(r'(\d+)').allMatches(notesUrl ?? '').lastOrNull;
    if (notesMatch != null) return int.tryParse(notesMatch.group(1) ?? '') ?? currentBuildNumber;
    return currentBuildNumber + 1;
  }

  Future<bool> openUpdate(AppUpdateInfo info) async {
    final url = info.hasUsableDownload ? info.apkUrl : info.releaseUrl;
    if (url.toString().isEmpty) return false;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

extension _LastOrNullExtension<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
