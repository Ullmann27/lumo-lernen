import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/home/home_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              reduceAnimations: true)
          .toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets(
      'Android back returns from a task through its own topics and subjects',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime(2026, 10, 23);
    await tester.pumpWidget(MaterialApp(
        home: AppShell(
            profile: UserProfile(
                id: 'back-test',
                name: 'Mia',
                age: 9,
                grade: 4,
                createdAt: date,
                lastActiveAt: date),
            initialSection: LumoSection.learn)));
    await frames(tester);
    await tester.tap(find.byKey(const ValueKey('learning-subject-Mathematik')));
    await frames(tester);
    final unit = find.byKey(
        const ValueKey('learning-unit-Mathematik-Zahlenraum bis 1 Million'));
    await tester.ensureVisible(unit);
    await frames(tester);
    expect(unit.hitTestable(), findsOneWidget);
    await tester.tap(unit);
    await frames(tester);
    expect(find.byType(LearningContent), findsOneWidget);
    await tester.binding.handlePopRoute();
    await frames(tester);
    expect(find.text('Themen · Mathematik'), findsOneWidget,
        reason: 'Back must retain the chosen subject instead of jumping home.');
    expect(find.text('4. Klasse · aus deinem Profil'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await frames(tester);
    expect(
        find.byKey(const ValueKey('learning-subject-Deutsch')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await frames(tester);
    expect(find.byType(HomeContent), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
