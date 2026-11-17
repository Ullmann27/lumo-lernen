import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/onboarding/lumo_onboarding_holo_screen.dart';
import 'package:lumo_lernen/main.dart';

import 'helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  late bool previousVoiceEnabled;

  setUp(() {
    previousVoiceEnabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        soundEnabled: false,
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
  });
  tearDown(() => LumoVoice.instance.isEnabled = previousVoiceEnabled);

  Future<void> frames(WidgetTester tester) async {
    // Animated characters never settle globally. Pump a bounded startup window.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> start(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    await tester.pumpWidget(const LumoApp());
    // The old skipped test only observed this transient splash.
    expect(find.text('Lumo Lernen'), findsOneWidget);
    await frames(tester);
    expect(find.text('lädt eure Welt...'), findsNothing);
  }

  Future<void> close(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }

  testWidgets('fresh Lumo startup reaches usable child profile setup',
      (tester) async {
    await start(tester);
    expect(find.byType(LumoOnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    await tester.tap(find.text("Los geht's!"));
    await frames(tester);
    final nameInput = find.byKey(const ValueKey('lumo-onboarding-name-input'));
    expect(nameInput, findsOneWidget);
    await tester.enterText(nameInput, 'Mia');
    await tester.pump();
    expect(tester.widget<TextField>(nameInput).controller!.text, 'Mia');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('lumo_active_profile'), isFalse,
        reason: 'An unfinished setup must not create a child profile.');
    await close(tester);
  });

  testWidgets('Lumo startup restores the existing child without rewriting it',
      (tester) async {
    final date = DateTime(2026, 11, 3);
    final profile = UserProfile(
      id: 'startup-child',
      name: 'Mia',
      age: 8,
      grade: 3,
      createdAt: date,
      lastActiveAt: date,
    );
    final savedProfile =
        jsonEncode({...profile.toJson(), 'futureField': 'preserve'});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumo_active_profile', savedProfile);
    await prefs.setBool('lumo_intro_seen', true);
    await start(tester);
    expect(find.byType(LumoOnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    final home = tester.widget<HomeContent>(find.byType(HomeContent));
    expect(home.appState.state.childName, 'Mia');
    expect(home.appState.state.grade, 3);
    expect(prefs.getString('lumo_active_profile'), savedProfile);
    await close(tester);
  });
}
