import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/reading/lumo_reading_buddy_screen.dart';
import '../helpers/lumo_capture.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var index = 0; index < 24; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  for (final config in <(String, Size, double)>[
    ('phone', const Size(412, 915), 1),
    ('fold-open', const Size(840, 900), 1),
    ('cover-large-text', const Size(344, 882), 1.4),
  ]) {
    testWidgets('reading comprehension actual taps and renderer ${config.$1}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(config.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      late final LumoAppState app;
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        await app.school.setActiveStudent('reading-capture-child');
        await app.loadLearningProfile();
        app.updateSettings(const AppSettings(
            voiceEnabled: false,
            microphoneEnabled: false,
            reduceAnimations: true));
      });
      addTearDown(app.dispose);
      final voice = LumoVoice.instance.isEnabled;
      LumoVoice.instance.isEnabled = false;
      addTearDown(() => LumoVoice.instance.isEnabled = voice);
      const boundary = ValueKey('nextgen-reading-capture');
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(config.$3)),
              child: child!),
          home: RepaintBoundary(
              key: boundary, child: LumoReadingBuddyScreen(appState: app))));
      await _frames(tester);
      await tester.tap(find.text('Mama und Tom'));
      await _frames(tester);
      final finish = find.byKey(const ValueKey('reading-finish'));
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await _frames(tester);
      expect(find.text('Was backt Mama?'), findsOneWidget);
      final answer = find.byKey(const ValueKey('reading-answer-1'));
      await tester.ensureVisible(answer);
      await _frames(tester);
      expect(tester.getSize(answer).height, greaterThanOrEqualTo(48));
      final output = Platform.environment['LUMO_NEXTGEN_READING_CAPTURES'];
      if (output != null) {
        await captureLumoBoundary(
            tester, boundary, '$output/${config.$1}-question.png');
      }
      await tester.tap(answer);
      await _frames(tester);
      await tester
          .ensureVisible(find.byKey(const ValueKey('reading-answer-feedback')));
      await _frames(tester);
      if (output != null) {
        await captureLumoBoundary(
            tester, boundary, '$output/${config.$1}-explanation.png');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
    });
  }
}
