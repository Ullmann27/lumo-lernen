import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/logic/logic_games_screen.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_routes.dart';
import 'package:lumo_lernen/features/games/star_trail/star_trail_screen.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

Future<void> _pumpHub(WidgetTester tester, LumoAppState app) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: GamesContent(appState: app)),
    ),
  );
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('routing table exposes one unified World and unique covers', () {
    expect(SpielweltRoutes.all.map((r) => r.identity), SpielweltRoutes.identities);
    expect(SpielweltRoutes.all, hasLength(13));
    expect(SpielweltRoutes.byIdentity('world').target, 'world');
    expect(SpielweltRoutes.identities, isNot(contains('treasure')));
    expect(SpielweltRoutes.identities, isNot(contains('build')));
    expect(SpielweltRoutes.identities, isNot(contains('village')));
    expect(SpielweltRoutes.byIdentity('world').targetDescription,
        allOf(contains('Schatzinsel'), contains('Dorfwirtschaft'), contains('Baumodus')));
    expect(SpielweltRoutes.byIdentity('chess').target, 'chess');
    expect(SpielweltRoutes.byIdentity('skypost').target, 'skypost');
    expect(SpielweltRoutes.byIdentity('stars').target, 'stars');
    final covers = [
      for (final route in SpielweltRoutes.all)
        if (route.coverAsset.isNotEmpty) route.coverAsset
    ];
    expect(covers.toSet(), hasLength(covers.length));
    expect(covers.any((cover) => cover.contains('cards/game_kart')), isFalse);
    // The card portal opens the 3D card table with its three own games.
    expect(SpielweltRoutes.byIdentity('cards').isNative, isTrue);
    expect(SpielweltRoutes.byIdentity('cards').target, 'cards');
    expect(SpielweltRoutes.byIdentity('cards').targetDescription,
        allOf(contains('Sternenstich'), contains('Lumo-Quartett')));
    // Jump & Run is the long 3D run, not the short cloud-island course.
    expect(SpielweltRoutes.byIdentity('jumpRun').target, 'run');
    expect(SpielweltRoutes.byIdentity('quizShow').title, 'Quizshow');
    expect(SpielweltRoutes.byIdentity('quizShow').semanticTitle, 'Wer wird Lumo-Meister?');
    expect(SpielweltRoutes.byIdentity('rhythm').title, 'Rhythm');
    expect(SpielweltRoutes.byIdentity('rhythm').semanticTitle, 'Rhythm Party');
    expect(SpielweltRoutes.coverFor('connectFour'), contains('cover_connect'));
    expect(SpielweltRoutes.coverFor('quizShow'), contains('cover_quiz'));
  });

  test('every viewport uses the image-tile hub with extra columns when wide', () {
    expect(SpielweltLayout.useReferenceHub(412, 915), isFalse);
    expect(SpielweltLayout.useReferenceHub(690, 829), isFalse);
    expect(SpielweltLayout.useReferenceHub(840, 560), isFalse);
    expect(SpielweltLayout.useReferenceHub(768, 1024), isFalse);
    expect(SpielweltLayout.useReferenceHub(1024, 768), isFalse);
    expect(SpielweltLayout.tileColumns(412), 2);
    expect(SpielweltLayout.tileColumns(690), 3);
    expect(SpielweltLayout.tileColumns(768), 3);
    expect(SpielweltLayout.tileColumns(840), 4);
    expect(SpielweltLayout.tileColumns(1024), 4);
  });

  testWidgets('chess refreshes the daily mission before a stale portal starts',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const bridge = MethodChannel('lumo_lernen/bridge');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      calls.add(call);
      return {'destination': 'games'};
    });
    final app = LumoAppState();
    try {
      await _pumpHub(tester, app);
      final portal = find.byKey(const ValueKey('spielwelt-portal-chess'));
      await tester.scrollUntilVisible(portal, 280,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(app.canPlayToday, isTrue);

      // The rendered portal predates the parent's setting change. Starting
      // chess must refresh the same mission gate as the other guarded games.
      app.update(app.state.copyWith(
          settings: app.state.settings
              .copyWith(requireDailyMissionForGames: true)));
      expect(app.canPlayToday, isFalse);
      expect(portal, findsOneWidget);
      await tester.tap(portal);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 800));

      expect(app.dailyMission, isNotNull);
      expect(app.canPlayToday, isFalse);
      expect(calls.where((call) => call.method == 'launch3D'), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      app.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  for (final scene in ['build', 'treasure', 'settlement']) {
    testWidgets('original $scene campaign launches directly with profile grade',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const bridge = MethodChannel('lumo_lernen/bridge');
      final calls = <MethodCall>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(bridge, (call) async {
        calls.add(call);
        return {'destination': 'games'};
      });
      final app = LumoAppState();
      try {
        SharedPreferences.setMockInitialValues({
          'lumo_kart_launch_v1': '{"grade":1,"subject":"Deutsch"}',
        });
        app.update(app.state.copyWith(grade: 3, subject: 'Mathematik'));
        await _pumpHub(tester, app);
        final original = find.byKey(const PageStorageKey('games-original-3d'));
        await tester.scrollUntilVisible(original, 260,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Originale 3D-Abenteuer'));
        await tester.pump(const Duration(milliseconds: 350));
        final tile = find.byKey(ValueKey('spielwelt-original-$scene'));
        // A built ListTile can still be clipped by the surrounding sliver.
        // Center it and lay out the actual viewport before sending a pointer.
        await tester.scrollUntilVisible(tile, 180,
            scrollable: find.byType(Scrollable).first);
        await tester.pump();
        await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
        await tester.pump();
        expect(tile.hitTestable(), findsOneWidget, reason: scene);
        await tester.tap(tile.hitTestable());
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(milliseconds: 800));
        final launches = calls.where((call) => call.method == 'launch3D');
        expect(launches, hasLength(1));
        final payload = launches.single.arguments as Map;
        expect(payload['scene'], scene);
        expect(payload['grade'], 3);
        expect(payload['subject'], 'Mathematik');
        expect(payload['childKey'], isNotNull);
        if (scene == 'settlement') {
          expect(payload['livingVillage'], isTrue);
          expect(payload['settlementMode'], 'settlement');
        } else {
          expect(payload.containsKey('livingVillage'), isFalse);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
        messenger.setMockMethodCallHandler(bridge, null);
        debugDefaultTargetPlatformOverride = null;
        await tester.binding.setSurfaceSize(null);
      }
    });
  }

  testWidgets('every visible portal opens its own target scene', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const bridge = MethodChannel('lumo_lernen/bridge');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      calls.add(call);
      return {'destination': 'games'};
    });
    try {
    for (final route in SpielweltRoutes.all) {
      calls.clear();
      final app = LumoAppState();
      addTearDown(app.dispose);
      await _pumpHub(tester, app);

      final portal = find.byKey(ValueKey('spielwelt-portal-${route.identity}'));
      expect(portal, findsOneWidget, reason: route.identity);
      expect(find.text(route.title), findsWidgets, reason: route.title);

      await tester.scrollUntilVisible(
        portal,
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(portal);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      if (route.isNative) {
        final launched = calls.where((call) => call.method == 'launch3D');
        expect(launched, hasLength(1), reason: route.identity);
        expect((launched.first.arguments as Map)['scene'], route.target,
            reason: '${route.identity} must open scene ${route.target}');
      } else {
        final found = switch (route.target) {
          'LogicGamesScreen' => find.byType(LogicGamesScreen),
          'LumoMemoryScreen' => find.byType(LumoMemoryScreen),
          'LumoConnectFourScreen' => find.byType(LumoConnectFourScreen),
          'QuizShowContent' => find.byType(QuizShowContent),
          _ => throw StateError('Unhandled Flutter Spielwelt target: ${route.target}'),
        };
        expect(found, findsOneWidget,
            reason: '${route.identity} → ${route.target}');
        expect(find.byType(LumoStarTrailScreen), findsNothing,
            reason: '${route.identity} must never open Sternenpfad');
      }
      await tester.pumpWidget(const SizedBox());
    }
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });
}
