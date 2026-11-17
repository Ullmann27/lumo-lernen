import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';

/// Regression for "Memory bricht beim Einstieg in der neuen APK sofort ab".
///
/// Up to 2036 the Spielwelt entry opened Memory and immediately started the
/// separate Godot table Activity (`launch3D`, scene `memory`) on Android.
/// The child-facing entry must open the real Flutter board, stay playable on
/// a phone and never touch either native channel unless 3D is requested.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const bridge = MethodChannel('lumo_lernen/bridge');
  const table = MethodChannel('lumo_lernen/table_games');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Spielwelt Memory entry opens a playable board without native start',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final bridgeCalls = <MethodCall>[];
    final tableCalls = <MethodCall>[];
    messenger.setMockMethodCallHandler(bridge, (call) async {
      bridgeCalls.add(call);
      throw PlatformException(code: 'game_unavailable');
    });
    // An engine that is missing or fails on the device is simulated by the
    // private table channel refusing to open.
    messenger.setMockMethodCallHandler(table, (call) async {
      tableCalls.add(call);
      throw PlatformException(code: 'table_unavailable');
    });
    final app = LumoAppState();
    try {
      app.updateSettings(const AppSettings(
          voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
      await tester.binding.setSurfaceSize(const Size(412, 915));
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 700));

      final portal = find.byKey(const ValueKey('spielwelt-portal-memory'));
      await tester.scrollUntilVisible(portal, 280,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(portal);
      await tester.pump();
      for (var i = 0; i < 60 &&
          find.byKey(const ValueKey('memory-card-0')).hitTestable().evaluate().isEmpty; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(LumoMemoryScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('memory-card-0')).hitTestable(),
          findsOneWidget, reason: 'Board is playable right after entry');
      await tester.pump(const Duration(seconds: 2));
      expect(bridgeCalls.where((c) => c.method == 'launch3D'), isEmpty,
          reason: 'Entry must not start the separate Godot Activity');
      expect(tableCalls, isEmpty,
          reason: 'Entry must not open the native table session');

      // Opting into 3D on a device whose engine fails keeps the same round.
      await tester.tap(find.byKey(const ValueKey('memory-open-3d')));
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tableCalls.map((c) => c.method), contains('open'));
      expect(bridgeCalls.where((c) => c.method == 'launch3D'), isEmpty,
          reason: 'A refused table never launches the Activity');
      expect(find.byType(LumoMemoryScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('memory-card-0')).hitTestable(),
          findsOneWidget, reason: 'Failed 3D start falls back to the board');
      expect(find.byKey(const ValueKey('memory-native-opening')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      messenger.setMockMethodCallHandler(bridge, null);
      messenger.setMockMethodCallHandler(table, null);
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });
}
