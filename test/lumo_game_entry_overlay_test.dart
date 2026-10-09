import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/lumo3d/lumo_game_entry_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled 3D game uses its own existing artwork and honest title', () {
    const expected = <String, (String, String)>{
      'kart': ('Lumo Kart', 'assets/lumo_design/gameplay/kart_sonnenhafen_preview.webp'),
      'build': ('Lumo Bauwelt', 'assets/lumo_design/gameplay/build.png'),
      'puzzle': ('Lumo Puzzle-Atelier', 'assets/lumo_design/gameplay/puzzle.png'),
      'rhythm': ('Lumo Rhythm Party', 'assets/lumo_design/gameplay/rhythm.png'),
      'treasure': ('Lumo Schatzsuche', 'assets/lumo_design/gameplay/treasure.png'),
      'jump': ('Lumo Abenteuer', 'assets/lumo_design/bg/bg_games.png'),
    };
    for (final entry in expected.entries) {
      expect(LumoGameEntryArt.titleFor(entry.key), entry.value.$1);
      expect(LumoGameEntryArt.imageFor(entry.key), entry.value.$2);
      expect(LumoGameEntryArt.categoryFor(entry.key), isNotEmpty);
    }
    expect(LumoGameEntryArt.titleFor('unknown'), 'Lumo Spielewelt');
  });

  for (final size in [
    const Size(320, 720), // Narrow Fold cover
    const Size(360, 800), // Standard phone
    const Size(840, 720), // Inner Fold
    const Size(1280, 800), // Tablet landscape
    const Size(640, 320), // Short Android landscape
  ]) {
    testWidgets('branded launch artwork and progress fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(
        home: LumoGameEntryOverlay(
          scene: 'kart',
          phase: LumoGameEntryPhase.preparing,
          reduceMotion: true,
        ),
      ));
      await tester.pump();
      expect(find.text('Lumo Kart'), findsOneWidget);
      expect(find.byKey(const ValueKey('game-entry-loading')), findsOneWidget);
      expect(find.text('Dein Spiel wird vorbereitet'), findsOneWidget);
      final art = tester.widget<Image>(find.byKey(const ValueKey('game-entry-art')));
      expect((art.image as AssetImage).assetName,
          LumoGameEntryArt.imageFor('kart'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('covering the old page hides animation and lets navigation settle',
      (tester) async {
    late BuildContext launchContext;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) {
        launchContext = context;
        return const Text('Spielewelt');
      })),
    ));
    final handle = LumoGameEntryHandle.show(
      launchContext, scene: 'kart', reduceMotion: false,
    );
    expect(handle, isNotNull);
    await tester.pump();
    expect(find.byType(LumoGameEntryOverlay), findsOneWidget);

    // Route change happens while wallet/save completion is still pending.
    // The progress animation must no longer keep the new page spinning.
    Navigator.of(launchContext).push<void>(MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Andere Seite')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Andere Seite'), findsOneWidget);
    expect(find.byType(LumoGameEntryOverlay), findsNothing);
    handle!.close();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay stays until explicitly closed; phase is not fake percent',
      (tester) async {
    late BuildContext launchContext;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) {
        launchContext = context;
        return const Text('Lumo Lernen bleibt offen');
      })),
    ));
    final handle = LumoGameEntryHandle.show(
      launchContext, scene: 'puzzle', reduceMotion: true,
    );
    expect(handle, isNotNull);
    await tester.pump();
    expect(find.text('Lumo Puzzle-Atelier'), findsOneWidget);
    expect(find.text('Deine Sterne werden gespeichert'), findsOneWidget);
    handle!.setPhase(LumoGameEntryPhase.opening);
    await tester.pump();
    expect(find.text('Die Spielwelt wird geöffnet'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('game-entry-loading')),
    );
    expect(bar.value, isNull, reason: 'Do not invent load percentages');
    handle.close();
    handle.close(); // A second dispose must not throw.
    await tester.pump();
    expect(find.text('Lumo Puzzle-Atelier'), findsNothing);
    expect(find.text('Lumo Lernen bleibt offen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
