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

  test('Dorfwirtschaft and building are native parts of the one Lumo World', () {
    final world = SpielweltRoutes.byIdentity('world');
    expect(world.isNative, isTrue);
    expect(world.target, 'world');
    expect(world.identity, 'world');
    expect(world.title, 'Lumo World');
    expect(world.targetDescription, contains('Dorfwirtschaft'));
    expect(world.targetDescription, contains('Baumodus'));
    expect(world.targetDescription, contains('Schatzinsel'));
    expect(SpielweltRoutes.identities, isNot(contains('village')));
    expect(SpielweltRoutes.identities, isNot(contains('build')));
    expect(SpielweltRoutes.identities, isNot(contains('treasure')));
    expect(SpielweltRoutes.all.map((r) => r.identity).toSet().length,
        SpielweltRoutes.all.length);
  });

  testWidgets(
      'Lumo World launches one native scene that owns exploration and village building',
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
      final tile = find.byKey(const ValueKey('spielwelt-portal-world'));
      expect(tile, findsOneWidget);
      expect(find.byKey(const ValueKey('spielwelt-portal-village')), findsNothing);
      expect(find.byKey(const ValueKey('spielwelt-portal-build')), findsNothing);
      expect(find.byKey(const ValueKey('spielwelt-portal-treasure')), findsNothing);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 700));
      final launched = calls.where((c) => c.method == 'launch3D').toList();
      expect(launched, hasLength(1));
      final options = launched.single.arguments as Map;
      expect(options['scene'], 'world');
      expect(options['childKey'], isNotNull);
      expect(options['grade'], inInclusiveRange(1, 4));
      expect(options.containsKey('livingVillage'), isFalse);
      expect(options.containsKey('settlementMode'), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
