import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/backup/local_backup.dart';
import 'package:lumo_lernen/features/settings/kart_online_settings_card.dart';

void main() {
  test('older settings never grant Internet races', () {
    final old = AppSettings.fromJson({'lanPlayEnabled': true, 'ghostDuelEnabled': true});
    expect(old.kartOnlineEnabled, isFalse);
    expect(old.kartOnlineUrl, AppSettings.defaultKartOnlineUrl);
    expect(old.lanPlayEnabled, isTrue);
    expect(old.ghostDuelEnabled, isTrue);
  });

  test('explicit consent and a TLS endpoint survive settings roundtrip', () {
    final value = const AppSettings().copyWith(
      kartOnlineEnabled: true, kartOnlineUrl: ' wss://kart.example.test/ws ');
    final restored = AppSettings.fromJson(value.toJson());
    expect(restored.kartOnlineEnabled, isTrue);
    expect(restored.kartOnlineUrl, 'wss://kart.example.test/ws');
    expect(restored.lanPlayEnabled, isFalse);
    expect(restored.ghostDuelEnabled, isFalse);
  });

  test('unsafe or credential-bearing endpoints are rejected', () {
    for (final raw in [
      '', 'http://kart.example.test/ws', 'https://kart.example.test/ws',
      'ws://127.0.0.1:8080/ws', 'wss://name:secret@kart.example.test/ws',
      'wss://kart.example.test/ws?token=secret', 'wss://kart.example.test/ws#secret',
      'wss:///ws', 'wss://kart.example.test:0/ws',
      'wss://kart.example.test:65536/ws', 'not a URI',
    ]) {
      expect(AppSettings.sanitizeKartOnlineUrl(raw), '', reason: raw);
    }
    expect(AppSettings.sanitizeKartOnlineUrl('wss://kart.example.test'),
        'wss://kart.example.test/ws');
    expect(AppSettings.sanitizeKartOnlineUrl('wss://kart.example.test:8443/ws'),
        'wss://kart.example.test:8443/ws');
  });

  test('backup does not transfer online consent or server configuration', () {
    final preferences = LocalBackupPolicy.portablePreferences({
      LocalBackupPolicy.settingsKey: jsonEncode(const AppSettings(
        kartOnlineEnabled: true,
        kartOnlineUrl: 'wss://kart.example.test/ws',
        lanPlayEnabled: true,
      ).toJson()),
    });
    final settings = jsonDecode(preferences[LocalBackupPolicy.settingsKey] as String);
    expect(settings['kartOnlineEnabled'], isFalse);
    expect(settings['kartOnlineUrl'], '');
    expect(settings['lanPlayEnabled'], isFalse);
    expect(LocalBackupPolicy.allowsNativePath('lumo_kart_online_identity.cfg'), isFalse);
    expect(LocalBackupPolicy.allowsNativePath('lumo_kart_online_friends.cfg'), isFalse);
  });

  testWidgets('unconfigured relay cannot silently enable online racing', (tester) async {
    var saves = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: KartOnlineSettingsCard(
        settings: const AppSettings(),
        onSave: (_) async { saves++; },
      )),
    )));
    await tester.ensureVisible(find.byKey(const ValueKey('kartOnlineConsent')));
    await tester.tap(find.byKey(const ValueKey('kartOnlineConsent')));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.byKey(const ValueKey('kartOnlineSettingsError')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving a server does not implicitly grant consent', (tester) async {
    AppSettings? saved;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: KartOnlineSettingsCard(
        settings: const AppSettings(),
        onSave: (value) async { saved = value; },
      )),
    )));
    await tester.enterText(find.byKey(const ValueKey('kartOnlineEndpoint')),
        'wss://kart.example.test/ws');
    await tester.ensureVisible(find.byKey(const ValueKey('kartOnlineSave')));
    await tester.tap(find.byKey(const ValueKey('kartOnlineSave')));
    await tester.pumpAndSettle();
    expect(saved?.kartOnlineUrl, 'wss://kart.example.test/ws');
    expect(saved?.kartOnlineEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
