import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

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

    expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);
    for (final title in [
      'Memory',
      'Cards',
      'Puzzle',
      'Jump & Run',
      'Rhythm Party',
      'Schatzsuche',
      'Bauwelt',
      'Vier gewinnt',
      'Würfel-Wettlauf',
      'Lumo Kart',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.byKey(const ValueKey('spielwelt-lumo')), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-adventure')), findsOneWidget);
    expect(find.text('Wortjagd'), findsNothing,
        reason: 'kein Spiel anzeigen, das es nicht gibt');
    expect(find.bySemanticsLabel(RegExp('Losfahren')), findsOneWidget,
        reason: 'Android-Prüfung tippt auf „Losfahren“');
    expect(find.byKey(const ValueKey('launch-lumo-kart')), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('Rhythm Party ist noch nicht spielbar: Lumo tanzt im Hinweis',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('spielwelt-portal-rhythm')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Rhythm Party kommt bald!'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('tanzt mit Kopfhörern')),
        findsWidgets,
        reason: 'beim Rhythmusspiel zeigt der Hinweis den tanzenden Kopfhörer-Lumo');
    expect(tester.takeException(), isNull);
  });
}
