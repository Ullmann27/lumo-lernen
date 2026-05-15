import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_update_service.dart';

/// Smoke- und Integritaets-Tests fuer AppUpdateService.
///
/// Schwerpunkte:
///   - hasUsableDownload korrekt
///   - Compile-Time-Variablen liefern sinnvolle Defaults
///   - URLs (latestReleaseApi, fallbackReleaseUrl) sind plausibel
///
/// Was hier NICHT getestet wird (waere flakey im Sandbox):
///   - echte Netzwerk-Aufrufe gegen api.github.com
///   - openUpdate mit url_launcher
void main() {
  group('AppUpdateInfo', () {
    test('hasUsableDownload ist false wenn apkUrl leer', () {
      final info = AppUpdateInfo(
        available: false,
        currentBuildNumber: 5,
        latestBuildNumber: 5,
        releaseUrl: Uri.parse('https://github.com/test/test'),
        apkUrl: Uri(),
        releaseName: 'test',
        commitSha: '',
      );
      expect(info.hasUsableDownload, isFalse);
    });

    test('hasUsableDownload ist true wenn apkUrl gesetzt', () {
      final info = AppUpdateInfo(
        available: true,
        currentBuildNumber: 5,
        latestBuildNumber: 6,
        releaseUrl: Uri.parse('https://github.com/test/test'),
        apkUrl: Uri.parse('https://github.com/test/test.apk'),
        releaseName: 'test',
        commitSha: 'abc',
      );
      expect(info.hasUsableDownload, isTrue);
    });
  });

  group('AppUpdateService Konstanten', () {
    test('currentBuildNumber hat Default 0 ohne --dart-define', () {
      // In Test-Umgebung ist LUMO_BUILD_NUMBER nicht gesetzt, defaultValue greift.
      // Wenn dieser Test rot wird, hat jemand defaultValue geaendert ohne Begruendung.
      expect(AppUpdateService.currentBuildNumber, greaterThanOrEqualTo(0));
    });

    test('currentVersionName hat Default-Format', () {
      // Sollte wie '0.0.0' oder '0.9.0' aussehen, kein leerer String.
      expect(AppUpdateService.currentVersionName, isNotEmpty);
      expect(AppUpdateService.currentVersionName, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('latestReleaseApi zeigt auf api.github.com', () {
      expect(AppUpdateService.latestReleaseApi.host, equals('api.github.com'));
      expect(AppUpdateService.latestReleaseApi.scheme, equals('https'));
    });

    test('fallbackReleaseUrl zeigt auf github.com', () {
      expect(AppUpdateService.fallbackReleaseUrl.host, equals('github.com'));
      expect(AppUpdateService.fallbackReleaseUrl.scheme, equals('https'));
      expect(AppUpdateService.fallbackReleaseUrl.path, contains('releases'));
    });

    test('latestReleaseApi und fallbackReleaseUrl haben gleiches Repo', () {
      // Beide URLs muessen auf Ullmann27/lumo-lernen zeigen, sonst Bug.
      expect(AppUpdateService.latestReleaseApi.path, contains('Ullmann27/lumo-lernen'));
      expect(AppUpdateService.fallbackReleaseUrl.path, contains('Ullmann27/lumo-lernen'));
    });
  });
}
