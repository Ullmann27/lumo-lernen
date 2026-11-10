import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_showcase_screen.dart';

/// Spielewelt nach Bild 06: nur echte Spiele, Android-Prüftexte bleiben.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Spielewelt zeigt die vier Spiele und Lumo Kart', (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    final app = LumoAppState();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Lumo Kart'), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-portal-kart')), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-portal-quizShow')), findsOneWidget);
    expect(find.byKey(const ValueKey('games-lumo-meister-portal')), findsNothing);
    expect(find.byKey(const ValueKey('games-1990-hero')), findsNothing);
    expect(find.text('Weitere Spielwelten entdecken'), findsNothing);
    expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);
    for (final title in [
      'Memory',
      'Cards',
      'Puzzle',
      'Jump & Run',
      'Rhythm',
      'Schatzsuche',
      'Bauwelt',
      'Lumo Kart',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    expect(find.byKey(const ValueKey('spielwelt-lumo')), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-adventure')), findsOneWidget);
    expect(find.text('Quizshow'), findsOneWidget);
    expect(find.text('Wer wird Lumo-Meister?'), findsNothing);
    expect(find.text('4 Gewinnt'), findsOneWidget);
    expect(find.text('Zusätzliche Spielmodi'), findsOneWidget);
    expect(find.text('Wortjagd'), findsNothing,
        reason: 'kein Spiel anzeigen, das es nicht gibt');

    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('Fold landscape uses the tile hub and Cards opens Cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('spielwelt-narrow-hub')), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-reference-hub')), findsNothing);
    expect(find.text('Auf ins Abenteuer!'), findsOneWidget);
    for (final identity in const [
      'memory',
      'cards',
      'puzzle',
      'jumpRun',
      'rhythm',
      'treasure',
      'build',
      'kart',
      'connectFour',
      'quizShow',
    ]) {
      expect(find.byKey(ValueKey('spielwelt-portal-$identity')), findsOneWidget,
          reason: identity);
    }
    final cards = find.byKey(const ValueKey('spielwelt-portal-cards'));
    await tester.ensureVisible(cards);
    await tester.tap(cards);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(LumoCardsShowcaseScreen), findsOneWidget,
        reason: 'Main Cards portal must never open Sternenpfad');
    expect(find.text('LUMO CARDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });


  testWidgets('Fold7 open portrait and tablet keep the tile hub with all ten games', (tester) async {
    for (final size in const [Size(690, 829), Size(768, 1024), Size(1024, 768)]) {
      await tester.binding.setSurfaceSize(size);
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('spielwelt-narrow-hub')), findsOneWidget,
          reason: '$size');
      expect(find.byKey(const ValueKey('spielwelt-reference-hub')), findsNothing,
          reason: '$size uses the image-tile menu, not the arch hub');
      expect(find.text('Auf ins Abenteuer!'), findsOneWidget, reason: '$size');
      for (final identity in const [
        'memory', 'cards', 'puzzle', 'jumpRun', 'rhythm',
        'treasure', 'build', 'kart', 'connectFour', 'quizShow',
      ]) {
        expect(find.byKey(ValueKey('spielwelt-portal-$identity')), findsOneWidget,
            reason: '$size $identity');
      }
      await tester.pumpWidget(const SizedBox());
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Rhythm Party opens the real native rhythm scene', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const bridge = MethodChannel('lumo_lernen/bridge');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      calls.add(call); return {'destination': 'games'};
    });
    try {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(); addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 600));
      final start = find.byKey(const ValueKey('spielwelt-portal-rhythm'));
      await tester.ensureVisible(start); await tester.tap(start);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(calls.where((c) => c.method == 'launch3D'), hasLength(1));
      expect((calls.firstWhere((c) => c.method == 'launch3D').arguments as Map)['scene'], 'rhythm');
      expect(find.text('Rhythm Party kommt bald!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
