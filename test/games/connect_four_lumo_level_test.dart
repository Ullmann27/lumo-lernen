import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/connect_four/connect_four_engine.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

ConnectFourEngine _play(List<int> columns) {
  final game = ConnectFourEngine();
  for (final column in columns) {
    expect(game.drop(column), isNotNull);
  }
  return game;
}

void main() {
  test('default Lumo level stays mittel and still blocks at column 3', () {
    final game = _play([0, 6, 1, 6, 2]);
    expect(game.turn, ConnectPiece.lumo);
    expect(game.chooseLumoColumn(Random(1)), 3);
    expect(game.chooseLumoColumn(Random(1), level: ConnectLumoLevel.mittel), 3);
    expect(game.chooseLumoColumn(Random(1), level: ConnectLumoLevel.schlau), 3);
  });

  test('every level takes an immediate win instead of only blocking', () {
    final game = _play([0, 6, 1, 6, 2, 6, 4]);
    expect(game.turn, ConnectPiece.lumo);
    for (final level in ConnectLumoLevel.values) {
      expect(
        game.chooseLumoColumn(Random(1), level: level),
        6,
        reason: level.name,
      );
    }
    expect(game.chooseLumoColumn(Random(1)), 6);
    expect(game.moves, 7);
  });

  test('schlau avoids setting up an immediate child win', () {
    final game = _play([0, 1, 0, 2, 1, 5, 2]);
    expect(game.turn, ConnectPiece.lumo);
    expect(game.phase, ConnectPhase.playing);
    expect(
      game.chooseLumoColumn(Random(0), level: ConnectLumoLevel.schlau),
      isNot(3),
    );
  });

  test('choices are deterministic for a seed and leicht can skip a block', () {
    final game = _play([0, 6, 1, 6, 2]);
    for (final level in ConnectLumoLevel.values) {
      final first = game.chooseLumoColumn(Random(42), level: level);
      final second = game.chooseLumoColumn(Random(42), level: level);
      expect(first, second, reason: level.name);
    }
    final leichtPicks = {
      for (var seed = 0; seed < 40; seed++)
        game.chooseLumoColumn(Random(seed), level: ConnectLumoLevel.leicht),
    };
    expect(leichtPicks, contains(3));
    expect(leichtPicks.length, greaterThan(1));
  });

  testWidgets('difficulty chips show against Lumo and hide in two-player',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
      home: LumoConnectFourScreen(appState: app, seed: 1),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('connect-level-leicht')), findsOneWidget);
    expect(find.byKey(const ValueKey('connect-level-mittel')), findsOneWidget);
    expect(find.byKey(const ValueKey('connect-level-schlau')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('connect-level-schlau')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
    await tester.pump();
    expect(find.byKey(const ValueKey('connect-level-schlau')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
