import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

final _output = Platform.environment['LUMO_CARDS_OPPONENT_CAPTURE'];
const _boundary = ValueKey('cards-opponent-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadLumoCaptureFonts();
    await loadLumoCaptureEmojiFont();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });
  for (final entry in {
    'phone': const Size(412, 915),
    'fold': const Size(690, 829),
  }.entries) {
    testWidgets('Actual Cards opponent controls on ${entry.key}',
        (tester) async {
      await tester.binding.setSurfaceSize(entry.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      app.updateSettings(const AppSettings(
          voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: LumoAppTheme.light(),
            home: LumoCardsScreen(appState: app, seed: 10, skipIntro: true)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await captureLumoBoundary(
          tester, _boundary, '$_output/cards_board_${entry.key}.png',
          pixelRatio: 1.5);
      await tester.tap(find.byKey(const ValueKey('cards-opponent-settings')));
      await tester.pumpAndSettle();
      await captureLumoBoundary(
          tester, _boundary, '$_output/cards_opponent_${entry.key}.png',
          pixelRatio: 1.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, skip: _output == null);
  }
}
