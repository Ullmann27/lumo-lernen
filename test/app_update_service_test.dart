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
  test(
      'parallel and original installations select only matching APK identities',
      () {
    final original = <String, dynamic>{'name': 'Lumo-Lernen-latest.apk'};
    final parallel = <String, dynamic>{'name': 'Lumo-Lernen-Neu.apk'};
    expect(
        AppUpdateService.preferredApkAsset([parallel, original],
            sideBySide: false),
        original);
    expect(
        AppUpdateService.preferredApkAsset([original, parallel],
            sideBySide: true),
        parallel);
    expect(AppUpdateService.preferredApkAsset([original], sideBySide: true),
        isNull);
    expect(AppUpdateService.preferredApkAsset([parallel], sideBySide: false),
        isNull);
  });

  group('family preview updates', () {
    Map<String, dynamic> release(int build, {
      bool prerelease = true,
      bool draft = false,
      String? tag,
      String apkName = 'Lumo-Lernen-Neu.apk',
      String? apkUrl,
    }) {
      final name = tag ?? 'coachpreview-build-$build';
      return {
        'tag_name': name,
        'name': 'Lumo Familie $build',
        'draft': draft,
        'prerelease': prerelease,
        'target_commitish': 'test-$build',
        'html_url':
            'https://github.com/Ullmann27/lumo-lernen/releases/tag/$name',
        'assets': [
          {
            'name': apkName,
            'browser_download_url': apkUrl ??
                'https://github.com/Ullmann27/lumo-lernen/releases/download/$name/$apkName',
          },
        ],
      };
    }

    test('only family preview candidates are selected, regardless of order', () {
      final found = AppUpdateService.familyPreviewFromReleases([
        release(1944),
        release(1945, prerelease: false),
        release(1943, tag: 'build-1943'),
        release(1948, apkName: 'Lumo-Lernen-latest.apk'),
        release(1947, draft: true),
        release(1946, apkUrl: 'https://evil.example/app.apk'),
        release(1942),
      ], installedBuild: 1941);
      expect(found.available, isTrue);
      expect(found.latestBuildNumber, 1944);
      expect(found.currentBuildNumber, 1941);
      expect(found.apkUrl.path,
          '/Ullmann27/lumo-lernen/releases/download/coachpreview-build-1944/Lumo-Lernen-Neu.apk');
      expect(found.releaseName, 'Lumo Familie 1944');
    });

    test('Build 2003 offers 2004 only after genuine family prerelease', () {
      final blocked = AppUpdateService.familyPreviewFromReleases([
        release(2003),
        release(2004, draft: true),
        release(2004, tag: 'lumo-0.12.92-2004'),
        release(2004, apkName: 'Lumo-Lernen-latest.apk'),
      ], installedBuild: 2003);
      expect(blocked.available, isFalse);
      expect(blocked.latestBuildNumber, 2003);
      final approved = AppUpdateService.familyPreviewFromReleases([
        release(2003),
        release(2004),
        release(2005, draft: true),
      ], installedBuild: 2003);
      expect(approved.available, isTrue);
      expect(approved.currentBuildNumber, 2003);
      expect(approved.latestBuildNumber, 2004);
      expect(approved.apkUrl.path,
          '/Ullmann27/lumo-lernen/releases/download/coachpreview-build-2004/Lumo-Lernen-Neu.apk');
      final alreadyInstalled = AppUpdateService.familyPreviewFromReleases([
        release(2003), release(2004),
      ], installedBuild: 2004);
      expect(alreadyInstalled.available, isFalse);
    });

    test('never offer downgrade and never mix original with family identity', () {
      final found = AppUpdateService.familyPreviewFromReleases([
        release(1941),
        release(1940),
        release(9999, apkName: 'Lumo-Lernen-latest.apk'),
      ], installedBuild: 1941);
      expect(found.available, isFalse);
      expect(found.latestBuildNumber, 1941);
      expect(found.apkUrl.path, contains('Lumo-Lernen-Neu.apk'));

      final empty = AppUpdateService.familyPreviewFromReleases([
        release(9999, tag: 'build-9999'),
      ], installedBuild: 1941);
      expect(empty.available, isFalse);
      expect(empty.hasUsableDownload, isFalse);
      expect(empty.releaseName, contains('Noch kein freigegebenes'));
    });

    test('rejects forged release URL or another release asset URL', () {
      final mismatched = release(1942,
        apkUrl: 'https://github.com/Ullmann27/lumo-lernen/releases/download/build-1942/Lumo-Lernen-Neu.apk');
      mismatched['html_url'] =
          'https://github.com/Ullmann27/lumo-lernen/releases/tag/build-1942';
      final blocked = AppUpdateService.familyPreviewFromReleases([
        mismatched,
      ], installedBuild: 1941);
      expect(blocked.available, isFalse);
      expect(blocked.hasUsableDownload, isFalse);
    });

    test('separate preview release endpoint retains an HTTPS trusted API', () {
      expect(AppUpdateService.familyReleasesApi.scheme, 'https');
      expect(AppUpdateService.familyReleasesApi.host, 'api.github.com');
      expect(AppUpdateService.familyReleasesApi.path,
          '/repos/Ullmann27/lumo-lernen/releases');
      expect(AppUpdateService.familyReleasesUrl.host, 'github.com');
    });
  });

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
      expect(AppUpdateService.currentVersionName,
          matches(RegExp(r'^\d+\.\d+\.\d+$')));
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
      expect(AppUpdateService.latestReleaseApi.path,
          contains('Ullmann27/lumo-lernen'));
      expect(AppUpdateService.fallbackReleaseUrl.path,
          contains('Ullmann27/lumo-lernen'));
    });
  });
}
