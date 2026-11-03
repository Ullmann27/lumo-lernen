import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/main.dart';

import 'helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  final date = DateTime(2026, 11, 3);
  final profile = UserProfile(
    id: 'deep-link-child',
    name: 'Mia',
    age: 8,
    grade: 3,
    createdAt: date,
    lastActiveAt: date,
  );
  late String savedProfile;

  setUp(() async {
    savedProfile = jsonEncode({...profile.toJson(), 'futureField': 'preserve'});
    SharedPreferences.setMockInitialValues({
      'lumo_active_profile': savedProfile,
      'lumo_intro_seen': true,
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        soundEnabled: false,
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
        requireDailyMissionForGames: false,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
    await RewardWalletRepository.instance.addStars(27);
    await RewardWalletRepository.instance.addXp(140);
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('cold and repeated warm links preserve one child and wallet',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(840, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        'lumolernen://open?section=learn';
    addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    await tester.pumpWidget(const LumoApp());
    await frames(tester);
    expect(find.byType(LumoAkademieScreen), findsOneWidget);

    expect(await tester.binding.handlePushRoute(
        'lumolernen://open?section=games'), isTrue);
    await frames(tester);
    final games = tester.widget<GamesContent>(find.byType(GamesContent));
    final state = games.appState;
    expect(state.state.childName, 'Mia');
    expect(state.state.grade, 3);
    expect(state.state.stars, 27);
    expect(state.state.xp, 140);

    Navigator.of(tester.element(find.byType(GamesContent))).push(
      MaterialPageRoute<void>(builder: (_) =>
          const Scaffold(body: Center(child: Text('Detail route')))),
    );
    await frames(tester);
    expect(find.text('Detail route'), findsOneWidget);
    expect(await tester.binding.handlePushRoute(
        'lumolernen://open?section=games'), isTrue);
    await frames(tester);
    expect(find.text('Detail route'), findsNothing);
    expect(tester.widget<GamesContent>(find.byType(GamesContent)).appState,
        same(state));

    expect(await tester.binding.handlePushRoute(
        'lumolernen://open?section=unknown'), isTrue);
    await frames(tester);
    expect(find.byType(GamesContent), findsOneWidget);
    expect(await tester.binding.handlePushRoute(
        'lumolernen://open?section=home'), isTrue);
    await frames(tester);
    expect(find.byType(HomeContent), findsOneWidget);

    // Two platform events before the next frame: the newest request wins.
    await tester.binding.handlePushRoute('lumolernen://open?section=games');
    await tester.binding.handlePushRoute('lumolernen://open?section=learn');
    await frames(tester);
    expect(find.byType(LumoAkademieScreen), findsOneWidget);
    await tester.runAsync(state.flushRewards);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_active_profile'), savedProfile);
    expect(state.state.stars, 27);
    expect(state.state.xp, 140);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
