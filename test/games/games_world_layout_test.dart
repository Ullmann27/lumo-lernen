import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/logic/logic_games_screen.dart';

/// Spielewelt nach Bild 06: nur echte Spiele, Android-Prüftexte bleiben.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Spielewelt erhält bestehende Spiele und zeigt World und Logikspiele',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(392, 2800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      final app = LumoAppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GamesContent(appState: app)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Lumo Kart'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('spielwelt-portal-kart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spielwelt-portal-quizShow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('games-lumo-meister-portal')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('games-1990-hero')), findsNothing);
      expect(find.text('Weitere Spielwelten entdecken'), findsNothing);
      expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);
      for (final title in [
        'Lumo World',
        'Logikspiele',
        'Memory',
        'Cards',
        'Puzzle',
        'Jump & Run',
        'Rhythm',
        'Schach',
        'Sternenpost',
        'Sternenjagd',
        'Lumo Kart',
      ]) {
        expect(find.text(title), findsWidgets, reason: title);
      }
      expect(find.byKey(const ValueKey('spielwelt-lumo')), findsOneWidget);
      expect(find.byKey(const ValueKey('spielwelt-adventure')), findsOneWidget);
      expect(find.byKey(const ValueKey('spielwelt-portal-treasure')), findsNothing);
      expect(find.byKey(const ValueKey('spielwelt-portal-build')), findsNothing);
      expect(find.byKey(const ValueKey('spielwelt-portal-village')), findsNothing);
      expect(find.text('Quizshow'), findsOneWidget);
      expect(find.text('Wer wird Lumo-Meister?'), findsNothing);
      expect(find.text('4 Gewinnt'), findsOneWidget);
      // The extra-mode sliver is below the expanded portal grid.
      await tester.scrollUntilVisible(
        find.text('Zusätzliche Spielmodi'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Zusätzliche Spielmodi'), findsOneWidget);
      expect(
        find.text('Wortjagd'),
        findsNothing,
        reason: 'kein Spiel anzeigen, das es nicht gibt',
      );

      expect(tester.takeException(), isNull);
      handle.dispose();
    },
  );

  testWidgets('Fold landscape uses the tile hub with every game portal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GamesContent(appState: app)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('spielwelt-narrow-hub')), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-reference-hub')), findsNothing);
    expect(find.text('Auf ins Abenteuer!'), findsOneWidget);
    for (final identity in const [
      'world',
      'logic',
      'memory',
      'cards',
      'puzzle',
      'jumpRun',
      'rhythm',
      'chess',
      'skypost',
      'stars',
      'kart',
      'connectFour',
      'quizShow',
    ]) {
      expect(
        find.byKey(ValueKey('spielwelt-portal-$identity')),
        findsOneWidget,
        reason: identity,
      );
    }
    // The card portal's native launch is covered by spielwelt_routing_test
    // and parent_games_polish_test (scene 'cards', exactly one launch).
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Fold7 open portrait and tablet keep existing and new game portals',
    (tester) async {
      for (final size in const [
        Size(690, 829),
        Size(768, 1024),
        Size(1024, 768),
      ]) {
        await tester.binding.setSurfaceSize(size);
        final app = LumoAppState();
        addTearDown(app.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GamesContent(appState: app)),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 700));
        expect(
          find.byKey(const ValueKey('spielwelt-narrow-hub')),
          findsOneWidget,
          reason: '$size',
        );
        expect(
          find.byKey(const ValueKey('spielwelt-reference-hub')),
          findsNothing,
          reason: '$size uses the image-tile menu, not the arch hub',
        );
        expect(
          find.text('Auf ins Abenteuer!'),
          findsOneWidget,
          reason: '$size',
        );
        for (final identity in const [
          'world',
          'logic',
          'memory',
          'cards',
          'puzzle',
          'jumpRun',
          'rhythm',
          'chess',
          'skypost',
          'stars',
          'kart',
          'connectFour',
          'quizShow',
        ]) {
          expect(
            find.byKey(ValueKey('spielwelt-portal-$identity')),
            findsOneWidget,
            reason: '$size $identity',
          );
        }
        await tester.pumpWidget(const SizedBox());
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  for (final scene in ['rhythm', 'world', 'stars']) {
    testWidgets('$scene portal opens its real native scene after cold start', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const bridge = MethodChannel('lumo_lernen/bridge');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, (call) async {
            calls.add(call);
            return {'destination': 'games'};
          });
      try {
        await tester.binding.setSurfaceSize(const Size(1000, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState();
        addTearDown(app.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GamesContent(appState: app)),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        final start = find.byKey(ValueKey('spielwelt-portal-$scene'));
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(calls.where((c) => c.method == 'launch3D'), hasLength(1));
        expect(
          (calls.firstWhere((c) => c.method == 'launch3D').arguments
              as Map)['scene'],
          scene,
        );
        expect(find.text('Rhythm Party kommt bald!'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(bridge, null);
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('Logikspiele portal opens the actual saved puzzle hub', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GamesContent(appState: app)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final start = find.byKey(const ValueKey('spielwelt-portal-logic'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    // _allowLaunch resolves asynchronously, then Navigator schedules a new
    // frame. Pump actual frames until the route is built, with a finite bound.
    for (
      var frame = 0;
      frame < 40 && find.text('Deine Schulstufe').evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(LogicGamesScreen), findsOneWidget);
    expect(find.text('Deine Schulstufe'), findsOneWidget);
    expect(find.text('Sudoku-Insel'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
