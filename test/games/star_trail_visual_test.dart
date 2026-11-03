import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/star_trail/star_trail_screen.dart';
import 'package:lumo_lernen/features/games/star_trail/star_trail_rules.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';

// The island board deliberately precedes the cards in a lazily built ListView.
// Exercise the actual scroll interaction instead of expecting offscreen widgets
// to be eagerly constructed in the Flutter test environment.
Future<void> revealStarTrail(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    240,
    scrollable: find.descendant(
      of: find.byType(LumoStarTrailScreen),
      matching: find.byType(Scrollable),
    ).first,
    maxScrolls: 16,
  );
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.text(label), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in <(String, Size)>[
    ('phone 360x800', const Size(360, 800)),
    ('Fold inner 690x829', const Size(690, 829)),
    ('tablet 1024x768', const Size(1024, 768)),
  ]) {
    testWidgets('Sternenpfad original Lumo and play on ' + entry.$1,
        (tester) async {
      await tester.binding.setSurfaceSize(entry.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: LumoStarTrailScreen()));
      await tester.pump(const Duration(milliseconds: 550));
      expect(find.byType(LumoCharacter), findsOneWidget);
      expect(find.text('Gemeinsam über die Wolken!'), findsOneWidget);
      await revealStarTrail(tester, 'WÄHLE DEINE NÄCHSTE KARTE');
      await revealStarTrail(tester, 'Sternlaterne');
      expect(tester.takeException(), isNull);
      final lantern = find.text('Sternlaterne');
      await tester.ensureVisible(lantern);
      await tester.pump();
      await tester.tap(lantern);
      await tester.pump(const Duration(milliseconds: 400));
      // Return to the visible progress counter after playing the card.
      await tester.drag(find.byType(ListView), const Offset(0, 1400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('1/12'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Completed route credits five child stars exactly once per visit',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = LumoAppState();
    addTearDown(app.dispose);
    final starsBefore = app.state.stars;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: LumoStarTrailScreen(appState: app),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < StarTrailState.goalDistance; i++) {
      await revealStarTrail(tester, 'Sternlaterne');
      final lantern = find.text('Sternlaterne');
      await tester.ensureVisible(lantern);
      await tester.pump();
      await tester.tap(lantern);
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(app.state.stars, starsBefore + 5);
    await revealStarTrail(tester, 'Noch eine Sternenreise');
    final restart = find.text('Noch eine Sternenreise');
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    await tester.pump(const Duration(milliseconds: 300));
    // Restart does not reset the per-screen award guard.
    for (var i = 0; i < StarTrailState.goalDistance; i++) {
      await revealStarTrail(tester, 'Sternlaterne');
      final lantern = find.text('Sternlaterne');
      await tester.ensureVisible(lantern);
      await tester.tap(lantern);
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(app.state.stars, starsBefore + 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });


}
