import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/shared/lumo_opponent_roster.dart';

void main() {
  String source() => File('assets/rivals/roster.json').readAsStringSync();

  test('the canonical five references are shared by competitive games', () {
    final roster = LumoOpponentRoster.parse(source());
    expect(roster.opponents.map((entry) => entry.id),
        ['lion', 'owl', 'rabbit', 'squirrel', 'turtle']);
    for (final game in ['kart', 'lumo_cards', 'connect_four']) {
      expect(roster.forGame(game).length, 5);
    }
    expect(roster.forGame('writing_coach'), isEmpty);
    expect(roster.opponents[2].name, 'Nova');
  });

  test('rotation is deterministic and has no duplicates', () {
    final roster = LumoOpponentRoster.parse(source());
    for (var round = -5; round < 15; round++) {
      final order = roster.rotation('kart', roundIndex: round);
      expect(order.map((entry) => entry.id).toSet().length, 5);
      expect(
          order.first.id, roster.opponents[round % roster.opponents.length].id);
    }
    expect(roster.rotation('unknown'), isEmpty);
  });

  test('unapproved assets are never marked available for a game', () {
    final data = jsonDecode(source()) as Map<String, dynamic>;
    for (final row in data['opponents'] as List<dynamic>) {
      (row as Map<String, dynamic>)['runtimeReady'] = false;
    }
    final roster = LumoOpponentRoster.parse(jsonEncode(data));
    expect(roster.readyForGame('kart'), isEmpty);
    expect(roster.forGame('kart').length, 5);
  });

  test('schema, missing identities and duplicated identifiers are rejected',
      () {
    expect(() => LumoOpponentRoster.parse('{}'), throwsFormatException);
    final data = jsonDecode(source()) as Map<String, dynamic>;
    final rows = data['opponents'] as List<dynamic>;
    rows.add(rows.first);
    expect(() => LumoOpponentRoster.parse(jsonEncode(data)),
        throwsFormatException);
    data['opponents'] = [];
    expect(() => LumoOpponentRoster.parse(jsonEncode(data)),
        throwsFormatException);
  });
}
