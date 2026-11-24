import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Alle pack keeps the historical shuffle for seed 4', () {
    final historical = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
    final explicit = MemoryBoard.deal(
      MemoryDifficulty.leicht,
      Random(4),
      pack: MemoryThemePack.alle,
    );
    expect(explicit, historical);
    expect(
      MemoryBoard.deal(MemoryDifficulty.profi, Random(9)),
      MemoryBoard.deal(
        MemoryDifficulty.profi,
        Random(9),
        pack: MemoryThemePack.alle,
      ),
    );
  });

  test('Themed packs prefer their motifs and still deal unique pairs', () {
    for (final pack in [
      MemoryThemePack.tiere,
      MemoryThemePack.weltall,
      MemoryThemePack.garten,
    ]) {
      final leicht = MemoryBoard.deal(
        MemoryDifficulty.leicht,
        Random(3),
        pack: pack,
      );
      expect(leicht, hasLength(8));
      final leichtUnique = leicht.toSet();
      expect(leichtUnique, hasLength(4));
      expect(leichtUnique.every(pack.motifs.contains), isTrue);

      final mittel = MemoryBoard.deal(
        MemoryDifficulty.mittel,
        Random(2),
        pack: pack,
      );
      expect(mittel, hasLength(12));
      final mittelUnique = mittel.toSet();
      expect(mittelUnique, hasLength(6));
      expect(
        mittelUnique.where(pack.motifs.contains).length,
        pack.motifs.length,
      );
      for (final motif in mittelUnique) {
        expect(mittel.where((card) => card == motif).length, 2);
      }
    }
  });

  testWidgets('Pack chips are tappable and combo banner appears on a streak',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.updateSettings(const AppSettings(
      voiceEnabled: false,
      soundEnabled: false,
      reduceAnimations: true,
    ));
    await tester.pumpWidget(MaterialApp(
      home: LumoMemoryScreen(
        appState: app,
        seed: 4,
        difficulty: MemoryDifficulty.leicht,
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('memory-pack-alle')), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-pack-tiere')), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-pack-weltall')), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-pack-garten')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('memory-pack-tiere')));
    await tester.pump();
    expect(find.byKey(const ValueKey('memory-card-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-combo-banner')), findsNothing);

    await tester.pumpWidget(MaterialApp(
      home: LumoMemoryScreen(
        key: UniqueKey(),
        appState: app,
        seed: 4,
        difficulty: MemoryDifficulty.leicht,
      ),
    ));
    await tester.pump();

    final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
    final firstPartner = deck.indexOf(deck[0], 1);
    final second = List<int>.generate(deck.length, (i) => i)
        .firstWhere((i) => deck[i] != deck[0]);
    final secondPartner = deck.indexOf(deck[second], second + 1);

    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(ValueKey('memory-card-$firstPartner')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('memory-combo-banner')), findsNothing);

    await tester.tap(find.byKey(ValueKey('memory-card-$second')));
    await tester.tap(find.byKey(ValueKey('memory-card-$secondPartner')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('memory-combo-banner')), findsOneWidget);
    expect(find.text('Combo x2!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
