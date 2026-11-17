import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/games/memory_board.dart';
import 'memory_round.dart';
import 'memory_rules.dart';

/// The existing published dealer, motif set, difficulty and reward formula.
class FlutterMemoryCatalog implements MemoryCatalog {
  const FlutterMemoryCatalog();

  @override
  List<String> deal(String difficulty, math.Random random, String pack) =>
      MemoryBoard.deal(MemoryDifficulty.values.byName(difficulty), random,
          pack: MemoryThemePack.values.byName(pack)).map((motif) => motif.name).toList();

  @override
  int cardCount(String difficulty) => MemoryDifficulty.values.byName(difficulty).cards;

  @override
  bool containsMotif(String motif) => MemoryMotif.values.any((value) => value.name == motif);

  @override
  int starsFor(String difficulty, {required bool won, required bool draw}) =>
      MemoryDifficulty.values.byName(difficulty).starsFor(won: won, draw: draw);
}

/// The private new round key is independent of the existing statistics key.
/// Never reads, migrates or overwrites the historical unowned lumo_memory_v2.
class PreferencesMemoryStore implements MemoryStore {
  PreferencesMemoryStore(this.preferences, String owner)
      : roundKey = 'lumo.memory.round.v1.' + owner,
        statsKey = 'lumo.memory.stats.v1.' + owner {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner)) {
      throw ArgumentError('Ungültige Memory-Profilkennung');
    }
  }

  final SharedPreferences preferences;
  final String roundKey;
  final String statsKey;

  @override
  Future<String?> readRound() async => preferences.getString(roundKey);

  @override
  Future<String?> readStats() async => preferences.getString(statsKey);

  @override
  Future<void> writeRound(String value) async {
    if (!await preferences.setString(roundKey, value)) {
      throw StateError('Memory-Runde wurde nicht gespeichert');
    }
  }

  @override
  Future<void> writeStats(String value) async {
    if (!await preferences.setString(statsKey, value)) {
      throw StateError('Memory-Bestwerte wurden nicht gespeichert');
    }
  }
}
