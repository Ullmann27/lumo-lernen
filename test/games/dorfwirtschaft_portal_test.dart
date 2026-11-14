import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_routes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Village economy has its own real native scene and unique identity', () {
    final village = SpielweltRoutes.byIdentity('village');
    expect(village.isNative, isTrue);
    expect(village.target, 'settlement');
    expect(village.identity, 'village');
    expect(village.title, 'Dorfwirtschaft');
    expect(village.coverAsset, isNot(SpielweltRoutes.byIdentity('build').coverAsset));
    expect(SpielweltRoutes.identities, contains('village'));
    expect(SpielweltRoutes.all.map((r) => r.identity).toSet().length,
        SpielweltRoutes.all.length);
  });

  testWidgets('Dorfwirtschaft tile launches true village, not Kart or the classic settlement',
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
      await tester.binding.setSurfaceSize(const Size(392, 2800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))),
      );
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 700));
      final tile = find.byKey(const ValueKey('spielwelt-portal-village'));
      expect(tile, findsOneWidget);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 700));
      final launched = calls.where((c) => c.method == 'launch3D').toList();
      expect(launched, hasLength(1));
      final options = launched.single.arguments as Map;
      expect(options['scene'], 'settlement');
      expect(options['livingVillage'], true);
      expect(options['settlementMode'], 'settlement');
      expect(options['childKey'], isNotNull);
      expect(options['grade'], inInclusiveRange(1, 4));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
