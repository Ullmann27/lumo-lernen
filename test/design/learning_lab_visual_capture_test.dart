import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_screen.dart';

import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);

  for (final config in <(String, Size, double)>[
    ('phone', const Size(412, 915), 1.0),
    ('fold-open', const Size(840, 900), 1.0),
    ('fold-cover-large-text', const Size(344, 882), 1.4),
  ]) {
    testWidgets('real child-safe atelier renders example and build: ${config.$1}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(config.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      final wasVoice = LumoVoice.instance.isEnabled;
      LumoVoice.instance.isEnabled = false;
      addTearDown(() => LumoVoice.instance.isEnabled = wasVoice);
      await tester.runAsync(() async {
        await app.school.setActiveStudent('atelier-visual-only');
        await app.hydrateFromWallet();
        await app.loadLearningProfile();
        app.updateSettings(const AppSettings(
          voiceEnabled: false,
          autoReadEnabled: false,
          soundEnabled: false,
          reduceAnimations: true,
          calmMode: true,
        ));
      });
      const boundary = ValueKey('lab-real-capture');
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(config.$3),
            disableAnimations: true),
          child: child!,
        ),
        home: RepaintBoundary(
          key: boundary,
          child: LearningLabScreen(
            appState: app,
            topic: LabCatalog.topics[0],
          ),
        ),
      ));

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(find.byKey(const ValueKey('lab-phase-example')), findsOneWidget);
      expect(find.text('Beispiel'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final directory = Platform.environment['LUMO_LAB_CAPTURES'];
      if (directory != null) {
        await captureLumoBoundary(tester, boundary,
            '$directory/${config.$1}-example.png');
      }

      final next = find.byKey(const ValueKey('lab-next'));
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 25));
      }
      expect(find.byKey(const ValueKey('lab-phase-build')), findsOneWidget);
      expect(find.byKey(const ValueKey('lab-model')), findsOneWidget);
      final model = find.byKey(const ValueKey('lab-check-model'));
      await tester.ensureVisible(model);
      await tester.pump();
      expect(tester.getSize(model).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      if (directory != null) {
        await captureLumoBoundary(tester, boundary,
            '$directory/${config.$1}-build.png');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
