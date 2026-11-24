import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';

import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);

  for (final config in <(String, Size, double)>[
    ('phone', const Size(412, 915), 1),
    ('fold-open', const Size(840, 900), 1),
    ('cover-large-text', const Size(344, 882), 1.4),
  ]) {
    testWidgets('actual plus lesson premium ${config.$1}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(config.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      final wasEnabled = LumoVoice.instance.isEnabled;
      LumoVoice.instance.isEnabled = false;
      addTearDown(() => LumoVoice.instance.isEnabled = wasEnabled);
      await tester.runAsync(() async {
        await app.ensureSettingsLoaded();
        app.updateSettings(
          const AppSettings(
            voiceEnabled: false,
            soundEnabled: false,
            autoReadEnabled: false,
            microphoneEnabled: false,
            aiProxyEnabled: false,
            reduceAnimations: true,
            calmMode: true,
          ),
        );
      });
      const boundary = ValueKey('lesson-premium-capture');
      await tester.pumpWidget(
        MaterialApp(
          theme: LumoAppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(config.$3),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: boundary,
            child: PlusBis10Screen(appState: app),
          ),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(find.text('Mathe-Abenteuer'), findsOneWidget);
      expect(find.text('Aufgabe 1 / 30'), findsOneWidget);
      if (config.$1 == 'fold-open') {
        expect(find.byTooltip('Zur Lernübersicht'), findsWidgets);
      } else {
        expect(find.text('Lernen'), findsWidgets);
      }
      final output = Platform.environment['LUMO_LESSON_CAPTURES'];
      if (output != null) {
        await captureLumoBoundary(tester, boundary, '$output/${config.$1}.png');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
