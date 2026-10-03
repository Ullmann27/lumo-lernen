import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/domain/learning/reward_engine.dart';
import 'package:lumo_lernen/features/rewards/test_photo_entry_card.dart';
import 'package:lumo_lernen/widgets/parent_approval_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Fresh settings require explicit microphone, camera and online choices',
      () async {
    for (final settings in [
      const AppSettings(),
      await SettingsRepository.load()
    ]) {
      expect(settings.microphoneEnabled, isFalse);
      expect(settings.scannerEnabled, isFalse);
      expect(settings.aiProxyEnabled, isFalse);
      expect(settings.toJson().keys, isNot(contains('parentPin')));
      expect(settings.toJson().keys, isNot(contains('parentRecoveryCodeHash')));
    }
  });

  test(
      'Migration removes all old credentials and preserves progress and preferences',
      () async {
    const wallet = '{"stars":123,"xp":500}';
    const profile = '{"name":"Alina","grade":2}';
    SharedPreferences.setMockInitialValues({
      'lumo_reward_wallet_v1': wallet,
      'lumo_active_profile': profile,
      'lumo_app_settings_v1': jsonEncode({
        'parentPin': '07391',
        'parentPinConfigured': true,
        'parentRecoveryCodeHash': List.filled(64, 'a').join(),
        'voiceEnabled': false,
        'dailyGoal': 10,
        'microphoneEnabled': true,
        'scannerEnabled': false,
        'aiProxyEnabled': false,
        'largeText': true,
      }),
    });
    final state = LumoAppState();
    await state.ensureSettingsLoaded();
    expect(state.settingsLoaded, isTrue);
    expect(state.state.settings.voiceEnabled, isFalse);
    expect(state.state.settings.dailyGoal, 10);
    expect(state.state.settings.largeText, isTrue);
    expect(state.state.settings.microphoneEnabled, isTrue);
    expect(state.state.settings.scannerEnabled, isFalse);
    expect(state.state.settings.aiProxyEnabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('lumo_app_settings_v1')!) as Map;
    expect(stored.keys, isNot(contains('parentPin')));
    expect(stored.keys, isNot(contains('parentPinConfigured')));
    expect(stored.keys, isNot(contains('parentRecoveryCodeHash')));
    expect(prefs.getString('lumo_reward_wallet_v1'), wallet);
    expect(prefs.getString('lumo_active_profile'), profile);
    state.dispose();
  });

  test('Saved permissions remain authoritative across repeated loads',
      () async {
    await SettingsRepository.save(const AppSettings(
      microphoneEnabled: true,
      scannerEnabled: true,
      aiProxyEnabled: true,
    ));
    final allowed = await SettingsRepository.load();
    expect(allowed.microphoneEnabled, isTrue);
    expect(allowed.scannerEnabled, isTrue);
    expect(allowed.aiProxyEnabled, isTrue);
    await SettingsRepository.save(allowed.copyWith(
      microphoneEnabled: false,
      scannerEnabled: false,
      aiProxyEnabled: false,
    ));
    for (var restart = 0; restart < 2; restart++) {
      final saved = await SettingsRepository.load();
      expect(saved.microphoneEnabled, isFalse);
      expect(saved.scannerEnabled, isFalse);
      expect(saved.aiProxyEnabled, isFalse);
    }
  });

  testWidgets(
      'Family approval is an explicit choice without a code or question',
      (tester) async {
    bool? approved;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      approved = await ParentApprovalDialog.show(context,
                          rewardTitle: 'Familienausflug',
                          costLabel: '80 Sterne');
                    },
                    child: const Text('Einlösen'),
                  ),
                ))));
    await tester.tap(find.text('Einlösen'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Familienausflug'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(approved, isFalse);
    await tester.tap(find.text('Einlösen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Als Erwachsene:r bestätigen'));
    await tester.pumpAndSettle();
    expect(approved, isTrue);
  });

  testWidgets('A test grade can be entered with camera access disabled',
      (tester) async {
    final state = LumoAppState();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(child: TestPhotoEntryCard(appState: state)),
    )));
    final camera = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Foto vom Test machen (optional)'));
    expect(camera.onPressed, isNull);
    expect(find.textContaining('ohne Foto speichern'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  test(
      'Voucher approval needs an explicit yes and keeps balances on cancellation',
      () {
    const voucher = Voucher(
        id: 'family',
        familyId: 'local',
        title: 'Ausflug',
        category: VoucherCategory.family,
        starPrice: 80,
        minLevel: 1);
    const state = RewardState(childId: 'local', stars: 100, xp: 55);
    const engine = RewardEngine();
    expect(
        () => engine.redeemVoucher(
            voucher: voucher, rewardState: state, parentApproved: false),
        throwsStateError);
    expect(state.stars, 100);
    final redeemed = engine.redeemVoucher(
        voucher: voucher, rewardState: state, parentApproved: true);
    expect(redeemed.stars, 20);
    expect(redeemed.xp, 55);
  });
}
