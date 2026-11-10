// Raster captures of the real Lumo Cards screen for Paket-E visual matching.
// Skipped unless LUMO_STREAM_E_CAPTURE points at an output directory.
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

final String? _directory = Platform.environment['LUMO_STREAM_E_CAPTURE'];
const _boundary = ValueKey('lumo-cards-optik-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('Cards overview on phone', (tester) async {
    await _open(tester, const Size(412, 915));
    await captureLumoBoundary(
        tester, _boundary, '$_directory/cards_overview_phone.png',
        pixelRatio: 1.5);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);

  testWidgets('Cards overview on fold-open', (tester) async {
    await _open(tester, const Size(690, 829));
    await captureLumoBoundary(
        tester, _boundary, '$_directory/cards_overview_fold.png',
        pixelRatio: 1.5);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);

  testWidgets('Cards overview on phone landscape', (tester) async {
    await _open(tester, const Size(850, 392));
    await captureLumoBoundary(
        tester, _boundary, '$_directory/cards_overview_landscape.png',
        pixelRatio: 1.5);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);
}

Future<void> _open(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState();
  addTearDown(app.dispose);
  app.updateSettings(const AppSettings(
    voiceEnabled: false,
    soundEnabled: false,
    reduceAnimations: true,
  ));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LumoAppTheme.light(),
    home: RepaintBoundary(
      key: _boundary,
      child: LumoCardsScreen(
        appState: app,
        seed: 10,
        skipIntro: true,
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}
