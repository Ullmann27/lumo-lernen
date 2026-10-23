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
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
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
    final academy =
        tester.widget<LumoAkademieScreen>(find.byType(LumoAkademieScreen));
    expect(academy.navigation!.subject, 'Mathematik');
    final back = find.byKey(const ValueKey('learning-back-to-subjects'));
    await tester.scrollUntilVisible(back, -200,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await frames(tester);
    expect(find.text('Themen · Mathematik'), findsOneWidget,
        reason: 'Back must retain the chosen subject instead of jumping home.');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('learning-profile-grade')), -200,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await frames(tester);
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  });
  testWidgets('a Home mission replaces an earlier browsing return path',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime(2026, 10, 23);
    await tester.pumpWidget(MaterialApp(
        home: AppShell(
            profile: UserProfile(
                id: 'mission-back',
                name: 'Mia',
                age: 8,
                grade: 2,
                createdAt: date,
                lastActiveAt: date),
            initialSection: LumoSection.learn)));
    await frames(tester);
    await tester.tap(find.byKey(const ValueKey('grade-pill-4')));
    await frames(tester);
    await tester.tap(find.byKey(const ValueKey('learning-subject-Englisch')));
    await frames(tester);
    await tester.tap(find.text('Start').last);
    await frames(tester);
    final home = tester.widget<HomeContent>(find.byType(HomeContent));
    await tester.runAsync(home.appState.loadDailyMission);
    await frames(tester);
    expect(home.appState.dailyMissionError, isNull);
    expect(home.appState.dailyMission, isNotNull);
    final mission = find.byKey(const ValueKey('mission-station-Mathematik'));
    await tester.scrollUntilVisible(mission, 240,
        scrollable: find
            .descendant(
                of: find.byType(HomeContent), matching: find.byType(Scrollable))
            .first,
        maxScrolls: 35);
    await frames(tester);
    await tester.tap(mission);
    await frames(tester);
    expect(find.byType(LearningContent), findsOneWidget);
    await tester.binding.handlePopRoute();
    await frames(tester);
    final academy =
        tester.widget<LumoAkademieScreen>(find.byType(LumoAkademieScreen));
    expect(academy.navigation!.subject, 'Mathematik');
    expect(academy.navigation!.gradeFor(2), 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  });
}
