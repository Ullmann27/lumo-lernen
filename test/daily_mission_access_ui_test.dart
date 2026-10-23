import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });
  tearDown(() {
    LumoVoice.instance.isEnabled = true;
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lumo_lernen/bridge'), null);
  });

  testWidgets(
      'parent mission rule shows the actual stations before game portals',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.runAsync(app.ensureSettingsLoaded);
    app.updateSettings(const AppSettings(requireDailyMissionForGames: true));
    await tester.runAsync(app.loadDailyMission);
    LumoSection? destination;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GamesContent(
                appState: app, onSection: (value) => destination = value))));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const ValueKey('mission-station-Mathematik')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('mission-station-Deutsch')), findsOneWidget);
    expect(find.byKey(const ValueKey('mission-game-access')), findsNothing);
    final station = find.byKey(const ValueKey('mission-station-Mathematik'));
    await tester.ensureVisible(station);
    await tester.pump();
    await tester.tap(station);
    expect(destination, LumoSection.exercises);
    expect(app.state.subject, 'Mathematik');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('locked mission prevents a direct Flutter native game launch',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var launches = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('lumo_lernen/bridge'),
            (call) async {
      if (call.method == 'launch3D') launches++;
      return <String, Object?>{'destination': 'games'};
    });
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.runAsync(app.ensureSettingsLoaded);
    app.updateSettings(const AppSettings(requireDailyMissionForGames: true));
    late BuildContext launchContext;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      launchContext = context;
      return const SizedBox();
    }))));
    final launched =
        await tester.runAsync(() => launchLumo3D(launchContext, appState: app));
    expect(launches, 0,
        reason: 'A direct launcher must enforce the same parental rule.');
    expect(launched, isFalse);
    debugDefaultTargetPlatformOverride = null;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
