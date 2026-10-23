import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RejectSettingsStore extends InMemorySharedPreferencesStore {
  _RejectSettingsStore() : super.withData({});
  bool reject = false;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (reject && key == 'flutter.lumo_app_settings_v1') return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parent mission setting becomes effective only after saving',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _RejectSettingsStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
        calmMode: true));
    LumoVoice.instance.isEnabled = false;
    await SettingsRepository.save(app.state.settings);
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SettingsContent(appState: app)),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    final toggle =
        find.widgetWithText(SwitchListTile, 'Tagesmission vor dem Spielen');
    store.reject = true;
    tester.widget<SwitchListTile>(toggle).onChanged!(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.state.settings.requireDailyMissionForGames, isFalse);
    expect(tester.takeException(), isNull);
    store.reject = false;
    tester.widget<SwitchListTile>(toggle).onChanged!(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.state.settings.requireDailyMissionForGames, isTrue);
    expect(
        (await SettingsRepository.load()).requireDailyMissionForGames, isTrue);
    final six = find.widgetWithText(ChoiceChip, '6');
    tester.widget<ChoiceChip>(six).onSelected!(true);
    await tester.pump();
    expect((await SettingsRepository.load()).missionTasksPerStation, 6);
    expect(app.state.settings.dailyGoal, 3);
    await tester.pumpWidget(const SizedBox());
  });
}
