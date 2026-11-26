import 'dart:convert';
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
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning_modules/tiere/tiere_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';

import '../helpers/lumo_capture.dart' show loadLumoCaptureFonts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              soundEnabled: false,
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

  for (final dimensions in [
    const Size(344, 882),
    const Size(412, 915),
    const Size(690, 829),
  ]) {
    testWidgets('vier Fächer sofort erreichbar bei ${dimensions.width} dp',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = dimensions;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.binding.setSurfaceSize(dimensions);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final date = DateTime(2026, 10, 23);
      await tester.pumpWidget(MaterialApp(
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
            id: 'learning-first-screen',
            name: 'Mia',
            age: 8,
            grade: 2,
            createdAt: date,
            lastActiveAt: date,
          ),
          initialSection: LumoSection.learn,
        ),
      ));
      await frames(tester);

      final scrollable = find.descendant(
        of: find.byType(LumoLearningHub),
        matching: find.byType(Scrollable),
      );
      final viewport = tester.getRect(scrollable);
      for (final subject in [
        'Mathematik',
        'Deutsch',
        'Englisch',
        'Sachunterricht',
      ]) {
        final card = find.byKey(ValueKey('learning-subject-$subject'));
        final bounds = tester.getRect(card);
        expect(bounds.top, greaterThanOrEqualTo(viewport.top), reason: subject);
        expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom), reason: subject);
        expect(card.hitTestable(), findsOneWidget, reason: subject);
      }
      await tester.tap(find.byKey(const ValueKey('learning-subject-Sachunterricht')));
      await frames(tester);
      expect(find.text('Themen · Sachunterricht'), findsOneWidget);
      expect(find.text('2. Klasse · aus deinem Profil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester);
    });
  }

  for (final openedTools in [false, true]) {
    testWidgets('Fold cover opens Tiere from the first view (Atelier: $openedTools)',
        (tester) async {
      const size = Size(344, 882);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final date = DateTime(2026, 10, 23);
      await tester.pumpWidget(MaterialApp(
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
            id: 'animals-first-screen',
            name: 'Mia',
            age: 7,
            grade: 1,
            createdAt: date,
            lastActiveAt: date,
          ),
          initialSection: LumoSection.learn,
        ),
      ));
      await frames(tester);
      final hub = find.byType(LumoLearningHub);
      if (openedTools) {
        final tools = find.byKey(const ValueKey('learning-advanced-entry'));
        await tester.ensureVisible(tools);
        await frames(tester);
        await tester.tap(tools);
        await frames(tester);
        expect(find.text('Dein Lernatelier'), findsOneWidget);
        await tester.drag(hub, const Offset(0, 1200));
        await frames(tester);
      }
      final subject = find.byKey(const ValueKey('learning-subject-Sachunterricht'));
      expect(subject.hitTestable(), findsOneWidget);
      await tester.tap(subject);
      await frames(tester);
      expect(find.text('Dein Lernatelier'), findsNothing);
      final animals = find.byKey(const ValueKey('learning-unit-Sachunterricht-Tiere'));
      final viewport = tester.getRect(find.descendant(
        of: hub, matching: find.byType(Scrollable),
      ));
      expect(animals.hitTestable(), findsOneWidget);
      expect(tester.getRect(animals).bottom, lessThanOrEqualTo(viewport.bottom));
      expect(tester.getSize(animals).height, greaterThanOrEqualTo(48));
      await tester.tap(animals);
      await frames(tester);
      expect(find.byType(TiereScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(animals.hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('learning-back-to-subjects')));
      await frames(tester);
      expect(subject.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester);
    });
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
    // The unit list builds lazily. With the workshop button lane reserved at
    // the bottom, this late unit must be scrolled to like a child would.
    await tester.scrollUntilVisible(unit, 180,
        scrollable: find.byType(Scrollable).first, maxScrolls: 40);
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
