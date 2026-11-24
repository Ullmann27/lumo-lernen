// Unretouched Flutter renders of the production shell, including its header,
// helper dock and navigation. The profile is a test fixture; no demo data is
// introduced into the app. Reuses the project's font and raster capture helper.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        soundEnabled: false,
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });

  for (final (device, size, scale) in [
    ('phone', const Size(393, 852), 1.0),
    ('small-phone', const Size(360, 800), 1.0),
    ('fold-cover', const Size(320, 740), 1.2),
    ('fold-open', const Size(840, 960), 1.0),
    ('landscape', const Size(840, 560), 1.0),
    ('large-text', const Size(393, 852), 2.0),
  ]) {
    testWidgets('Next Gen production home $device', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const boundary = ValueKey('nextgen-home-capture');
      final date = DateTime(2026, 10, 20);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: boundary,
          child: AppShell(
            profile: UserProfile(
              id: 'nextgen-visual-fixture',
              name: 'Mia',
              age: 8,
              grade: 2,
              createdAt: date,
              lastActiveAt: date,
            ),
          ),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      final out = Platform.environment['LUMO_NEXTGEN_CAPTURES'];
      if (out != null) {
        await captureLumoBoundary(tester, boundary, '$out/$device.png');
      }
      expect(tester.takeException(), isNull, reason: '$device layout');
      final start = find.byKey(const ValueKey('home-start-learning'));
      await tester.ensureVisible(start);
      await tester.pump(const Duration(milliseconds: 400));
      final target = tester.getRect(start);
      // Global transforms can introduce sub-pixel floating point error.
      expect(target.height, greaterThanOrEqualTo(48 - .001));
      expect(target.width, greaterThanOrEqualTo(48 - .001));
      await tester.tap(start);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(LumoAkademieScreen), findsOneWidget,
          reason: 'Loslernen reaches the existing real learning route');
      expect(tester.takeException(), isNull, reason: '$device navigation');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
