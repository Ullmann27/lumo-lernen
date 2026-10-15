import 'dart:convert';

import 'package:flutter/services.dart';

/// Read-only opponent identity. Never changes rewards, rules or profile data.
class LumoOpponent {
  LumoOpponent._(Map<String, dynamic> row)
      : id = row['id'] as String,
        name = row['name'] as String,
        color = row['color'] as String,
        games = List<String>.unmodifiable(
          (row['games'] as List<dynamic>).cast<String>(),
        ),
        portraitAsset = row['flutterPortrait'] as String,
        godotModel = row['godotModel'] as String,
        runtimeReady = row['runtimeReady'] == true;

  final String id;
  final String name;
  final String color;
  final List<String> games;
  final String portraitAsset;
  final String godotModel;
  final bool runtimeReady;
}

/// Flutter reads the same canonical JSON as Godot. It does not call a server.
class LumoOpponentRoster {
  LumoOpponentRoster._(this.opponents);

  final List<LumoOpponent> opponents;

  static const assetPath = 'assets/rivals/roster.json';

  static Future<LumoOpponentRoster> load({AssetBundle? bundle}) async =>
      parse(await (bundle ?? rootBundle).loadString(assetPath));

  static LumoOpponentRoster parse(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Invalid Lumo opponent roster schema.');
    }
    final rows = decoded['opponents'];
    if (rows is! List<dynamic> || rows.isEmpty) {
      throw const FormatException('Missing Lumo opponent identities.');
    }
    final ids = <String>{};
    final opponents = <LumoOpponent>[];
    for (final value in rows) {
      if (value is! Map<String, dynamic> ||
          value['id'] is! String ||
          (value['id'] as String).isEmpty ||
          value['name'] is! String ||
          value['color'] is! String ||
          value['games'] is! List<dynamic> ||
          (value['games'] as List<dynamic>).any((game) => game is! String) ||
          value['flutterPortrait'] is! String ||
          value['godotModel'] is! String) {
        throw const FormatException('Invalid Lumo opponent identity.');
      }
      final id = value['id'] as String;
      if (!(value['flutterPortrait'] as String)
              .startsWith('assets/rivals/portraits/') ||
          !(value['godotModel'] as String)
              .startsWith('res://assets/characters/rivals/') ||
          (value['flutterPortrait'] as String).contains('..') ||
          (value['godotModel'] as String).contains('..')) {
        throw const FormatException('Invalid local Lumo opponent asset path.');
      }
      if (!ids.add(id)) {
        throw FormatException('Duplicate Lumo opponent identity: $id');
      }
      opponents.add(LumoOpponent._(value));
    }
    return LumoOpponentRoster._(List<LumoOpponent>.unmodifiable(opponents));
  }

  List<LumoOpponent> forGame(String game) => List<LumoOpponent>.unmodifiable(
        opponents.where((opponent) => opponent.games.contains(game)),
      );

  List<LumoOpponent> rotation(String game, {int roundIndex = 0}) {
    final entries = forGame(game);
    if (entries.isEmpty) return const [];
    final offset = roundIndex % entries.length;
    return List<LumoOpponent>.unmodifiable([
      ...entries.skip(offset),
      ...entries.take(offset),
    ]);
  }

  /// A declared future asset must not become a broken visible placeholder.
  List<LumoOpponent> readyForGame(String game) =>
      List<LumoOpponent>.unmodifiable(
        forGame(game).where((opponent) => opponent.runtimeReady),
      );
}
