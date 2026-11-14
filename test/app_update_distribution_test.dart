import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_install_helper.dart';
import 'package:lumo_lernen/core/app_update_service.dart';

class _ChannelInstaller extends AppInstallHelper {
  const _ChannelInstaller(this.channel);
  final AppDistribution channel;

  @override
  Future<AppDistribution> distribution() async => channel;

  @override
  Future<bool> canInstall() async =>
      throw StateError('APK permission was queried');

  @override
  Future<bool> requestInstallPermission() async =>
      throw StateError('Unknown-source settings were opened');

  @override
  Future<bool> install(String apkPath) async =>
      throw StateError('APK installer was called');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldFamilyRelease = AppUpdateInfo(
    available: true,
    currentBuildNumber: 2020,
    latestBuildNumber: 9999,
    releaseUrl: Uri.parse(
        'https://github.com/Ullmann27/lumo-lernen/releases/tag/build-9999'),
    apkUrl: Uri.parse(
        'https://github.com/Ullmann27/lumo-lernen/releases/download/build-9999/Lumo.apk'),
    releaseName: 'Previously loaded family update',
    commitSha: '',
  );

  for (final channel in [AppDistribution.play, AppDistribution.unavailable]) {
    test('$channel checks and downloads never contact the APK endpoint',
        () async {
      final service = AppUpdateService(installer: _ChannelInstaller(channel));
      await HttpOverrides.runZoned(() async {
        final info = await service.checkLatest();
        expect(info.distribution, channel);
        expect(info.available, isFalse);
        expect(info.hasUsableDownload, isFalse);
        if (channel == AppDistribution.play) {
          expect(info.managedByPlay, isTrue);
          expect(info.error, isNull);
          expect(info.releaseUrl, AppUpdateService.playStoreUrl);
        } else {
          expect(info.error, isNotNull);
          expect(info.releaseUrl.toString(), isEmpty);
        }
        final result = await service.downloadAndInstall(oldFamilyRelease);
        expect(result.success, isFalse);
        expect(result.needsPermission, isFalse);
        expect(result.error, isNotEmpty);
      },
          createHttpClient: (_) =>
              throw StateError('APK network request attempted'));
    });
  }

  test('unknown channel also rejects the browser APK fallback', () async {
    const service = AppUpdateService(
        installer: _ChannelInstaller(AppDistribution.unavailable));
    expect(await service.openUpdate(oldFamilyRelease), isFalse);
  });

  test('Play browser fallback opens only the canonical store listing',
      () async {
    const service =
        AppUpdateService(installer: _ChannelInstaller(AppDistribution.play));
    final opened = <String>[];
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, (call) async {
      if (call.method == 'launch') {
        opened.add((call.arguments as Map)['url'] as String);
        return true;
      }
      return false;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcher, null));
    expect(await service.openUpdate(oldFamilyRelease), isTrue);
    expect(opened, [AppUpdateService.playStoreUrl.toString()]);
    expect(AppUpdateService.playStoreUrl.queryParameters['id'],
        'dev.ullmann.lumo.lumo_lernen');
  });
}
