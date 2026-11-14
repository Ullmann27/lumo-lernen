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
class PreferencesMemoryStore
    implements MemoryStore, MemoryReadbackConfirmation {
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

  // Reload refreshes Dart's cache from the platform snapshot. Android's native
  // SharedPreferences cache can itself contain a failed commit's value, so this
  // read is not a storage acknowledgement and has no write side effect.
  Future<String?> _readPlatform(String key) async {
    try {
      await preferences.reload();
    } catch (error) {
      throw MemoryStorageUnconfirmed(
          'Memory-Speicher konnte nicht gelesen werden', cause: error);
    }
    return preferences.getString(key);
  }

  @override
  Future<String?> readRound() => _readPlatform(roundKey);

  @override
  Future<String?> readStats() => _readPlatform(statsKey);

  Future<void> _writeConfirmed(String key, String value, String message) async {
    final bool confirmed;
    try {
      confirmed = await preferences.setString(key, value);
    } catch (error) {
      throw MemoryStorageUnconfirmed(message, cause: error);
    }
    if (!confirmed) throw MemoryStorageRejected(message);
  }

  @override
  Future<void> writeRound(String value) => _writeConfirmed(
      roundKey, value, 'Memory-Runde wurde nicht bestätigt');

  @override
  Future<void> writeStats(String value) => _writeConfirmed(
      statsKey, value, 'Memory-Bestwerte wurden nicht bestätigt');

  // The controller validates the exact snapshot and checks its profile lease
  // immediately before and after this bounded, same-value write. Only a true
  // platform reply succeeds; read equality never replaces that reply.
  @override
  Future<void> confirmRoundReadback(String value) => writeRound(value);

  @override
  Future<void> confirmStatsReadback(String value) => writeStats(value);
}
