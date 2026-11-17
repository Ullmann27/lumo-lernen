// Raster captures of the real Memory screen for Paket-E visual matching.
// Skipped unless LUMO_STREAM_E_CAPTURE points at an output directory.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

final String? _directory = Platform.environment['LUMO_STREAM_E_CAPTURE'];
const _boundary = ValueKey('lumo-memory-optik-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Memory overview 4x4 on phone', (tester) async {
    await _open(
      tester,
      const Size(412, 915),
      MemoryDifficulty.schwer,
    );
    await captureLumoBoundary(
        tester, _boundary, '$_directory/memory_overview_phone.png',
        pixelRatio: 1.5);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);

  testWidgets('Memory overview leicht on phone (Lumo and table)',
      (tester) async {
    await _open(
      tester,
      const Size(412, 915),
      MemoryDifficulty.leicht,
    );
    await captureLumoBoundary(
        tester, _boundary, '$_directory/memory_overview_leicht.png',
        pixelRatio: 1.5);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);

  testWidgets('Memory one card flipped on phone', (tester) async {
    await _open(
      tester,
      const Size(412, 915),
      MemoryDifficulty.leicht,
    );
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await captureLumoBoundary(
        tester, _boundary, '$_directory/memory_flipped_phone.png',
        pixelRatio: 1.5);
    expect(find.byKey(const ValueKey('memory-back-0')), findsNothing);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);

  testWidgets('Memory matched pair on phone', (tester) async {
    await _open(
      tester,
      const Size(412, 915),
      MemoryDifficulty.leicht,
    );
    final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
    final partner = deck.indexOf(deck[0], 1);
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(ValueKey('memory-card-$partner')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    await captureLumoBoundary(
        tester, _boundary, '$_directory/memory_matched_phone.png',
        pixelRatio: 1.5);
    expect(find.byKey(const ValueKey('memory-matched-mark')), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);

  testWidgets('Memory overview 4x4 on fold-open', (tester) async {
    await _open(
      tester,
      const Size(690, 829),
      MemoryDifficulty.schwer,
    );
    await captureLumoBoundary(
        tester, _boundary, '$_directory/memory_overview_fold.png',
        pixelRatio: 1.5);
    expect(tester.takeException(), isNull);
    await _close(tester);
  }, skip: _directory == null);
}

Future<void> _open(
  WidgetTester tester,
  Size size,
  MemoryDifficulty difficulty,
) async {
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
      child: LumoMemoryScreen(
        appState: app,
        seed: 4,
        difficulty: difficulty,
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}
