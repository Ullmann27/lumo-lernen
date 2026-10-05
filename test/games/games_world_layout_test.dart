import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

/// Spielewelt nach Bild 06: nur echte Spiele, Android-Prüftexte bleiben.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Spielewelt zeigt die vier Spiele und Lumo Kart', (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    final app = LumoAppState();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);
    for (final title in [
      'Memory mit Lumo',
      'Lumo Cards',
      'Vier gewinnt',
      'Würfel-Wettlauf',
      'Lumo Kart',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Wortjagd'), findsNothing,
        reason: 'kein Spiel anzeigen, das es nicht gibt');
    expect(find.bySemanticsLabel(RegExp('Losfahren')), findsOneWidget,
        reason: 'Android-Prüfung tippt auf „Losfahren“');
    expect(find.byKey(const ValueKey('launch-lumo-kart')), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
