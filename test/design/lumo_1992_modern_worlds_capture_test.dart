// Real Flutter-rendered premium worlds, never synthetic reference pictures.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/magic_hub/lumo_magic_hub_screen.dart';
import 'package:lumo_lernen/features/story/lumo_quest_hub_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['LUMO_MODERN_WORLDS_CAPTURES'];
  setUpAll(() async {
    await loadLumoCaptureFonts();
    if (out != null) await loadLumoCaptureEmojiFont();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final layout in lumoCaptureSizes.entries) {
    testWidgets('Magic, Mirror and Quest use real premium graphics on ${layout.key}',
        (tester) async {
      await tester.binding.setSurfaceSize(layout.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      const boundary = ValueKey('modern-worlds-capture');

      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: boundary,
          child: LumoMagicHubScreen(appState: app),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(LumoMagicHubScreen), findsOneWidget);
      expect(find.byType(LumoSceneBackground), findsOneWidget);
      expect(find.text('Lumo Magic'), findsOneWidget);
      if (out != null) {
        await captureLumoBoundary(
            tester, boundary, '$out/magic-${layout.key}.png',
            pixelRatio: 1.5);
      }

      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: boundary,
          child: const LumoMirrorShowcaseScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(LumoMirrorShowcaseScreen), findsOneWidget);
      expect(find.byType(LumoSceneBackground), findsOneWidget);
      expect(find.text('Lumo Mirror'), findsOneWidget);
      if (out != null) {
        await captureLumoBoundary(
            tester, boundary, '$out/mirror-${layout.key}.png',
            pixelRatio: 1.5);
      }
      // Quest must remain readable and free of horizontal overflow on the
      // smallest Fold cover, not just be linked from Magic.
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: boundary,
          child: LumoQuestHubScreen(appState: app),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(LumoQuestHubScreen), findsOneWidget);
      expect(find.byType(LumoSceneBackground), findsOneWidget);
      expect(find.text('Lumo Quest'), findsOneWidget);
      if (out != null) {
        await captureLumoBoundary(
            tester, boundary, '$out/quest-${layout.key}.png',
            pixelRatio: 1.5);
      }
      expect(tester.takeException(), isNull,
          reason: 'Quest must not overflow on ${layout.key}');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
