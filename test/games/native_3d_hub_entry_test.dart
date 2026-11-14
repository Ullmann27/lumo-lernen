import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('real native 3D games hub is visibly enterable from Flutter',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const bridge = MethodChannel('lumo_lernen/bridge');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      calls.add(call);
      return {'destination': 'games'};
    });
    try {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      const key = ValueKey('spielwelt-native-3d-hub');
      final entry = find.byKey(key);
      expect(entry, findsOneWidget,
          reason: 'The existing Godot game_hub must not remain unreachable');
      await tester.ensureVisible(entry);
      await tester.pump();
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      await tester.tap(entry);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final launches = calls.where((call) => call.method == 'launch3D').toList();
      expect(launches.length, 1);
      final request = launches.single.arguments as Map;
      expect(request['scene'], 'games',
          reason: 'Never silently replace the real 3D hub with Kart');
      expect(request['grade'], inInclusiveRange(1, 4));
      expect(request['childKey'], isNotNull);
      expect(tester.takeException(), isNull);
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });
}
