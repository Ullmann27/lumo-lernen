import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _backs() => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('memory-back-'));

Future<void> _open(WidgetTester tester, LumoAppState app,
    {MemoryDifficulty? difficulty, Size size = const Size(392, 850)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
      home: LumoMemoryScreen(
          key: UniqueKey(), appState: app, seed: 4, difficulty: difficulty)));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Tippen dreht die Karte um (3D-Flip) und zeigt das Motiv',
      (tester) async {
    final app = LumoAppState();
    await _open(tester, app, difficulty: MemoryDifficulty.mittel);
    expect(_backs(), findsNWidgets(12));
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_backs(), findsNWidgets(12), reason: 'Flip noch in der ersten Hälfte');
    await tester.pump(const Duration(milliseconds: 500));
    expect(_backs(), findsNWidgets(11));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Stufenwahl startet ein neues Brett in der richtigen Größe',
      (tester) async {
    final app = LumoAppState();
    await _open(tester, app, difficulty: MemoryDifficulty.schwer);
    expect(_backs(), findsNWidgets(16));
    for (final d in MemoryDifficulty.values) {
      await tester.tap(find.byKey(ValueKey('memory-diff-${d.name}')));
      await tester.pump();
      expect(_backs(), findsNWidgets(d.cards), reason: d.label);
    }
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_memory_v2'), contains('profi'));
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Zuletzt gespielte Stufe wird wiederhergestellt', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'lumo_memory_v2': '{"difficulty":"leicht","best":{"leicht":5}}'});
    final app = LumoAppState();
    await _open(tester, app);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_backs(), findsNWidgets(8));
    expect(find.text('Dein Rekord: 5 Züge'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Kein Überlauf auf Handy, Fold, Querformat und kleinem Display',
      (tester) async {
    final app = LumoAppState();
    for (final size in const [
      Size(360, 640),
      Size(392, 850),
      Size(673, 841),
      Size(850, 392),
      Size(1280, 800),
    ]) {
      for (final d in MemoryDifficulty.values) {
        await _open(tester, app, difficulty: d, size: size);
        expect(tester.takeException(), isNull, reason: '$size ${d.label}');
        expect(find.byKey(ValueKey('memory-card-${d.cards - 1}')).hitTestable(),
            findsOneWidget,
            reason: 'letzte Karte erreichbar bei $size ${d.label}');
      }
    }
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Paar gefunden: bleibt offen, Zähler steigt, Kind nochmal dran',
      (tester) async {
    final app = LumoAppState();
    await _open(tester, app, difficulty: MemoryDifficulty.leicht);
    final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
    final partner = deck.indexOf(deck[0], 1);
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(ValueKey('memory-card-$partner')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_backs(), findsNWidgets(6));
    expect(find.text('Du bist dran! Tipp 2 Karten.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
