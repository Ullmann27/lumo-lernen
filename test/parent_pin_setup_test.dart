import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/parent_pin_recovery.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/widgets/parent_pin_setup_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'Default PIN is explicitly unconfigured; legacy custom PINs remain configured',
      () {
    expect(const AppSettings().parentPin, '2468');
    expect(const AppSettings().parentPinConfigured, isFalse);
    expect(AppSettings.fromJson({'parentPin': '2468'}).parentPinConfigured,
        isFalse);
    for (final extra in [
      {},
      {'parentPinConfigured': false}
    ]) {
      final stored = AppSettings.fromJson({'parentPin': '07391', ...extra});
      expect(stored.parentPin, '07391');
      expect(stored.parentPinConfigured, isTrue);
    }
    expect(
        AppSettings.fromJson({
          'parentPin': '2468',
          'parentPinConfigured': true,
        }).parentPinConfigured,
        isTrue);
  });

  test('Hydration keeps a saved PIN even if an unrelated setting is malformed',
      () async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode({
        'parentPin': '07391',
        'voiceEnabled': 'broken',
        'aiLearningMode': 8,
      }),
    });
    final state = LumoAppState();
    expect(state.settingsLoaded, isFalse);
    await state.ensureSettingsLoaded();
    expect(state.settingsLoaded, isTrue);
    expect(state.state.settings.parentPin, '07391');
    expect(state.state.settings.parentPinConfigured, isTrue);
    state.dispose();
  });

  test('First setup never overwrites an existing custom PIN', () async {
    await SettingsRepository.save(const AppSettings(parentPin: '7291'));
    await expectLater(
        SettingsRepository.setParentPin(
          pin: '9371',
          recoveryCodeHash:
              ParentPinRecovery.hash(ParentPinRecovery.generateCode()),
          firstSetupOnly: true,
        ),
        throwsStateError);
    expect((await SettingsRepository.load()).parentPin, '7291');
  });

  test(
      'Recovery requires the private code, rotates it and preserves learning data',
      () async {
    final oldCode = ParentPinRecovery.generateCode();
    final newCode = ParentPinRecovery.generateCode();
    SharedPreferences.setMockInitialValues({
      'lumo_reward_wallet_v1': '{"stars":123,"xp":500}',
      'lumo_active_profile': '{"name":"Alina","grade":2}',
    });
    await SettingsRepository.save(AppSettings(
      parentPin: '7291',
      parentRecoveryCodeHash: ParentPinRecovery.hash(oldCode),
      voiceEnabled: false,
      dailyGoal: 10,
    ));
    await expectLater(
        SettingsRepository.recoverParentPin(
          recoveryCode: '2468',
          newPin: '9371',
          newRecoveryCodeHash: ParentPinRecovery.hash(newCode),
        ),
        throwsStateError);
    expect((await SettingsRepository.load()).parentPin, '7291');
    final next = await SettingsRepository.recoverParentPin(
      recoveryCode: oldCode.toLowerCase().replaceAll('-', ' '),
      newPin: '9371',
      newRecoveryCodeHash: ParentPinRecovery.hash(newCode),
    );
    expect(next.parentPin, '9371');
    expect(next.voiceEnabled, isFalse);
    expect(next.dailyGoal, 10);
    expect(ParentPinRecovery.matches(oldCode, next.parentRecoveryCodeHash),
        isFalse);
    expect(ParentPinRecovery.matches(newCode, next.parentRecoveryCodeHash),
        isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_reward_wallet_v1'), '{"stars":123,"xp":500}');
    expect(
        prefs.getString('lumo_active_profile'), '{"name":"Alina","grade":2}');
    expect(prefs.getString('lumo_app_settings_v1'), isNot(contains(newCode)));
  });

  test('Requested coach activation happens once and preserves parent choices',
      () async {
    final recoveryHash =
        ParentPinRecovery.hash(ParentPinRecovery.generateCode());
    final original = AppSettings(
      parentPin: '7291',
      parentRecoveryCodeHash: recoveryHash,
      voiceEnabled: false,
      dailyGoal: 10,
    );
    await SettingsRepository.save(original);
    expect((await SettingsRepository.load()).aiProxyEnabled, isFalse);
    final activated = await SettingsRepository.activateRequestedCoachOnce(
      original,
      requested: true,
    );
    expect(activated.aiProxyEnabled, isTrue);
    expect(activated.aiLearningMode, AiLearningMode.fullCoach);
    expect(activated.parentPin, '7291');
    expect(activated.parentRecoveryCodeHash, recoveryHash);
    expect(activated.voiceEnabled, isFalse);
    expect(activated.dailyGoal, 10);
    await SettingsRepository.save(activated.copyWith(aiProxyEnabled: false));
    final loaded = await SettingsRepository.load();
    final later = await SettingsRepository.activateRequestedCoachOnce(loaded,
        requested: true);
    expect(later.aiProxyEnabled, isFalse);
    expect(later.parentPin, '7291');
  });

  testWidgets(
      'First setup saves only after matching PIN and recovery-code acknowledgement',
      (tester) async {
    AppSettings? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        result = await ParentPinSetupDialog.show(context,
                            settings: const AppSettings());
                      },
                      child: const Text('Einrichten')),
                ))));
    await tester.tap(find.text('Einrichten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '7291');
    await tester.enterText(find.byType(TextField).at(1), '7292');
    await tester.tap(find.text('Weiter'));
    await tester.pump();
    expect(find.text('Bitte 4 bis 8 Ziffern zweimal gleich eingeben.'),
        findsOneWidget);
    expect((await SettingsRepository.load()).parentPinConfigured, isFalse);
    await tester.enterText(find.byType(TextField).at(1), '7291');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    final code =
        tester.widget<SelectableText>(find.byType(SelectableText)).data!;
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'PIN speichern'))
            .onPressed,
        isNull);
    expect((await SettingsRepository.load()).parentPinConfigured, isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('PIN speichern'));
    await tester.pumpAndSettle();
    expect(result?.parentPin, '7291');
    expect(result?.parentPinConfigured, isTrue);
    expect(
        ParentPinRecovery.matches(
            code, (await SettingsRepository.load()).parentRecoveryCodeHash),
        isTrue);
  });

  testWidgets(
      'Existing custom PIN without recovery code exposes no reset action',
      (tester) async {
    await SettingsRepository.save(const AppSettings(parentPin: '7291'));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => ParentPinRecoveryDialog.show(context),
                      child: const Text('Hilfe')),
                ))));
    await tester.tap(find.text('Hilfe'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Code prüfen'), findsNothing);
    expect((await SettingsRepository.load()).parentPin, '7291');
  });
}
