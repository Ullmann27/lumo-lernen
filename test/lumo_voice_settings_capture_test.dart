import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/settings/settings_content.dart';

import 'design/parent_games_polish_test.dart' as capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('real parent voice controls stay readable at 360x800',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    final state = await capture.stateFor(tester);
    await capture.mount(tester, SettingsContent(appState: state));
    await tester.ensureVisible(find.text('Online-Lumo-Stimme (Sulafat)'));
    await tester.pump();
    expect(find.text('Stimme testen'), findsOneWidget);
    expect(state.state.settings.cloudVoiceEnabled, isFalse);
    await capture.capture(tester, 'voice-settings-360x800');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
