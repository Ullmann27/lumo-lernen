import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/domain/rewards/reward_shop.dart';
import 'package:lumo_lernen/widgets/profile_screen.dart';

import '../helpers/lumo_capture.dart';

/// Aufnahmen des Profils im echten App-Rahmen zum Vergleich mit Heinz'
/// Zielbild `docs/design_targets/2026-11-17/profil_handy.jpg`.
///
/// Schreibt nur, wenn `LUMO_PROFILE_CAPTURES` auf einen Ordner zeigt.
/// Die Werte stammen aus echtem, vorab gespeichertem Spielstand.
const _student = 'local-profil-capture';

String _day(int daysAgo) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day - daysAgo);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

SkillRecord _skill(String subject, String unit, int correct) => SkillRecord(
      skillId: '${subject.toLowerCase()}::${unit.toLowerCase()}',
      subject: subject,
      unit: unit,
      correct: correct,
    );

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
      LegacyLearningDataRepository.localIdKey: _student,
      LearningDataNamespace.keyFor('lumo_progress_daily', _student):
          jsonEncode({
        // Sieben Lerntage in Folge einschließlich heute.
        for (var i = 0; i < 7; i++) _day(i): 2,
      }),
      LearningDataNamespace.keyFor('lumo_progress_skills', _student):
          jsonEncode({
        for (final skill in [
          _skill('Mathematik', 'Plus bis 10', 2),
          _skill('Logik', 'Muster', 1),
        ])
          skill.skillId: skill.toJson(),
      }),
      'lumo.reward_shop.local_mia_2': jsonEncode(RewardShopState(
        redeemed: [
          RedeemedReward(
            itemId: 'sticker_aussuchen',
            title: 'Sticker aussuchen',
            redeemedAt: DateTime(2026, 11, 10),
            cost: 30,
            currency: RewardCurrency.stars,
          ),
          RedeemedReward(
            itemId: 'gute_nacht_geschichte',
            title: 'Gute-Nacht-Geschichte extra',
            redeemedAt: DateTime(2026, 11, 14),
            cost: 60,
            currency: RewardCurrency.stars,
          ),
        ],
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    final wallet = RewardWalletRepository.instance;
    await wallet.reset();
    await wallet.applyRewardDelta(starsDelta: 6, xpDelta: 80);
    await wallet.awardGameResult(resultId: 'capture-1', stars: 3, xp: 20);
    await wallet.awardGameResult(resultId: 'capture-2', stars: 3, xp: 20);
  });

  for (final (device, size, scale) in [
    ('phone-390x844', const Size(390, 844), 1.0),
    ('fold-open-840x760', const Size(840, 760), 1.0),
    ('fold-zu-320x640', const Size(320, 640), 1.0),
    ('phone-390x844-schrift-1-3', const Size(390, 844), 1.3),
  ]) {
    testWidgets('Profil im App-Rahmen $device', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const boundary = ValueKey('profile-target-capture');
      final date = DateTime(2026, 11, 17);
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
              id: 'profil-capture',
              name: 'Mia',
              age: 8,
              grade: 2,
              createdAt: date,
              lastActiveAt: date,
            ),
            initialSection: LumoSection.profile,
          ),
        ),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(ProfileScreen), findsOneWidget);
      final out = Platform.environment['LUMO_PROFILE_CAPTURES'];
      if (out != null) {
        await captureLumoBoundary(tester, boundary, '$out/$device.png');
      }
      expect(tester.takeException(), isNull, reason: '$device layout');
      // Zweite Aufnahme: bis zum Ende gescrollt (Regal und Aktionskarten).
      await tester.drag(find.byType(ProfileScreen), const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('profile-report')), findsOneWidget);
      if (out != null) {
        await captureLumoBoundary(tester, boundary, '$out/$device-unten.png');
      }
      expect(tester.takeException(), isNull, reason: '$device unten');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
