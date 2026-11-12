import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_routes.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

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
        cloudVoiceEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final (device, size) in [
    ('fold7-cover', const Size(344, 882)),
    ('fold7-open-portrait', const Size(690, 829)),
    ('fold7-open-landscape', const Size(840, 560)),
  ]) {
    testWidgets('Spielewelt in the actual app shell $device', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const boundary = ValueKey('spielwelt-shell-capture');
      final date = DateTime(2026, 11, 12);
      await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LumoAppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              padding: const EdgeInsets.only(top: 24, bottom: 16),
            ),
            child: child!,
          ),
          home: AppShell(
            profile: UserProfile(
              id: 'spielewelt-stage-fixture',
              name: 'Mia',
              age: 8,
              grade: 2,
              createdAt: date,
              lastActiveAt: date,
            ),
            initialSection: LumoSection.games,
          ),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.pump();
      expect(find.byType(LumoTopBar), findsNothing,
          reason: 'Games has one own title and reward balance');
      final dock = find.byKey(const ValueKey('lumo-help-dock'));
      expect(dock, findsOneWidget,
          reason: 'Voice and companion help remain reachable');
      for (final identity in SpielweltRoutes.identities) {
        expect(
            find.byKey(ValueKey('spielwelt-portal-$identity')), findsOneWidget);
      }
      final kart =
          tester.getRect(find.byKey(const ValueKey('spielwelt-portal-kart')));
      expect(kart.bottom, lessThanOrEqualTo(tester.getRect(dock).top),
          reason: 'Kart is usable immediately without scrolling');
      expect(tester.takeException(), isNull);
      final out = Platform.environment['LUMO_HUB_CAPTURES'];
      if (out != null && out.isNotEmpty) {
        await captureLumoBoundary(tester, boundary, '$out/shell-$device.png');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  }
}
