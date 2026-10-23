// Unretouched Flutter-render evidence from the production AppShell.
// All routes use real taps and curriculum units. No lesson/progress mocks.
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
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';

import '../helpers/lumo_capture.dart';

const _boundary = ValueKey('navigation-evidence-boundary');
final _out = Platform.environment['LUMO_NAVIGATION_CAPTURES'];

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _reveal(WidgetTester tester, Finder target,
    {double delta = 160}) async {
  if (target.evaluate().isEmpty) {
    // Production topics use a lazy ListView. Build the target by scrolling
    // the real hub, then let ensureVisible position the existing element.
    final scrollable = find.descendant(
        of: find.byType(LumoLearningHub), matching: find.byType(Scrollable));
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(target, delta,
        scrollable: scrollable, maxScrolls: 40);
  }
  await tester.ensureVisible(target);
  await _frames(tester);
}

Future<void> _hubTop(WidgetTester tester) async {
  await tester.drag(find.byType(LumoLearningHub), const Offset(0, 1800));
  await _frames(tester);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await _frames(tester);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await _frames(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  await captureLumoBoundary(tester, _boundary, '$_out/$name.png');
  expect(tester.takeException(), isNull, reason: 'Flutter layout for $name');
}

Future<void> _shell(WidgetTester tester, Size size,
    {LumoSection? initialSection}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final date = DateTime(2026, 10, 23);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
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
          id: 'nextgen-evidence-fixture',
          name: 'Mia',
          age: 8,
          grade: 2,
          createdAt: date,
          lastActiveAt: date,
        ),
        initialSection: initialSection,
      ),
    ),
  ));
  await _frames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadLumoCaptureFonts();
    await loadLumoCaptureEmojiFont();
  });
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

  for (final (device, size) in [
    ('phone', const Size(360, 800)),
    ('fold', const Size(840, 560)),
  ]) {
    testWidgets('navigation render home grade tools games $device',
        (tester) async {
      await _shell(tester, size);
      await _capture(tester, 'home-$device');

      await _tap(tester, find.byKey(const ValueKey('home-start-learning')));
      await _capture(tester, 'learning-entry-$device');

      await _tap(tester, find.byKey(const ValueKey('grade-pill-4')));
      expect(find.text('4. Klasse · frei lernen'), findsOneWidget);
      expect(find.byKey(const ValueKey('academy-return-clear-overview')),
          findsNothing);
      await _hubTop(tester);
      await _capture(tester, 'modern-grade-4-$device');

      await _tap(tester, find.byKey(const ValueKey('learning-advanced-entry')));
      final tools = find.text('Dein Lernatelier');
      await tester.ensureVisible(tools);
      await _frames(tester);
      await _capture(tester, 'modern-tools-$device');

      await tester.binding.handlePopRoute();
      await _frames(tester);
      await _tap(tester, find.byKey(const ValueKey('home-games')));
      await _capture(tester, 'games-$device');
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
    }, skip: _out == null);

    for (final (slug, subject) in [
      ('math', 'Mathematik'),
      ('german', 'Deutsch'),
      ('english', 'Englisch'),
      ('science', 'Sachunterricht'),
    ]) {
      testWidgets('navigation render $slug topics task $device',
          (tester) async {
        await _shell(tester, size, initialSection: LumoSection.learn);
        await _tap(tester, find.byKey(ValueKey('learning-subject-$subject')));
        final unit =
            Curriculum.unitsForGrade(subject, 2, currentGradeOnly: true).first;
        final unitTarget = find.byKey(ValueKey('learning-unit-$subject-$unit'));
        await _hubTop(tester);
        await _capture(tester, '$slug-topics-$device');
        await _tap(tester, unitTarget);
        await _capture(tester, '$slug-task-$device');
        await tester.binding.handlePopRoute();
        await _frames(tester);
        final back = find.byKey(const ValueKey('learning-back-to-subjects'));
        await _reveal(tester, back, delta: -180);
        expect(find.text('Themen · $subject'), findsOneWidget,
            reason: 'Back retains the real task subject');
        expect(tester.takeException(), isNull, reason: 'Back from $subject');
        await tester.pumpWidget(const SizedBox.shrink());
        await _frames(tester);
      }, skip: _out == null);
    }
  }
}
