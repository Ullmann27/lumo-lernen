import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'memory_rules.dart';

abstract interface class MemoryStore {
  Future<String?> readRound();
  Future<void> writeRound(String value);
  Future<String?> readStats();
  Future<void> writeStats(String value);
}

typedef MemoryAward = Future<void> Function(
  String resultId, String difficulty, int kindPairs, int lumoPairs,
);

class MemoryRound {
  MemoryRound({
    required this.owner,
    required this.id,
    required this.revision,
    required this.rules,
    this.paused = false,
    this.rewarded = false,
  });
  final String owner;
  final String id;
  final int revision;
  final MemoryRules rules;
  final bool paused;
  final bool rewarded;

  String get resultId => 'memory:$owner:$id';

  static String newId() {
    final random = math.Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  factory MemoryRound.read(String text, MemoryCatalog catalog, String owner) {
    final value = jsonDecode(text);
    if (value is! Map<String, dynamic> || value['schema'] != 1 ||
        value['game'] != 'memory' || value['owner'] != owner ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        value['id'] is! String || !RegExp(r'^[a-f0-9]{32}$').hasMatch(value['id'] as String) ||
        value['revision'] is! int || (value['revision'] as int) < 1 ||
        (value['revision'] as int) >= 1000000000 ||
        value['paused'] is! bool || value['rewarded'] is! bool ||
        value['rules'] is! Map<String, dynamic>) {
      throw const FormatException('Der gespeicherte Memory-Spielstand ist ungültig');
    }
    final rules = MemoryRules.restore(catalog, value['rules'] as Map<String, dynamic>);
    if (value['rewarded'] == true && !rules.complete) {
      throw const FormatException('Unfertige Memory-Runde hat eine Belohnung');
    }
    return MemoryRound(
      owner: owner, id: value['id'] as String, revision: value['revision'] as int,
      rules: rules, paused: value['paused'] as bool, rewarded: value['rewarded'] as bool,
    );
  }

  MemoryRound copy(MemoryCatalog catalog, {bool? paused, bool? rewarded}) => MemoryRound(
    owner: owner, id: id, revision: revision + 1,
    rules: MemoryRules.restore(catalog, Map<String, dynamic>.from(rules.toJson())),
    paused: paused ?? this.paused, rewarded: rewarded ?? this.rewarded,
  );

  Map<String, Object?> toJson() => {
    'schema': 1, 'game': 'memory', 'owner': owner, 'id': id,
    'revision': revision, 'paused': paused, 'rewarded': rewarded,
    'rules': rules.toJson(),
  };
}

/// One profile-owned writer. Every accepted turn is persisted before exposure.
/// The owner queue also orders a disposed screen's pending write before a new
/// controller reads the same child's round. It never changes another key.
class MemoryRoundController {
  MemoryRoundController._({
    required this.owner,
    required this.catalog,
    required this.store,
    required this.award,
    required bool Function() canUseProfile,
  }) : _profile = canUseProfile;

  static final Map<String, Future<void>> _ownerWrites = {};
  final String owner;
  final MemoryCatalog catalog;
  final MemoryStore store;
  final MemoryAward award;
  final bool Function() _profile;
  late MemoryRound _round;
  Map<String, dynamic> _stats = {};
  Map<String, int> _best = {};
  bool _statsWritable = true;
  bool _closed = false;
  bool _uncertain = false;
  bool restored = false;

  MemoryRound get round => _round;
  MemoryRules get state => _round.rules;
  Map<String, int> get best => Map.unmodifiable(_best);
  bool get statsWritable => _statsWritable;
  bool canUseProfile() => !_closed && _profile();

  void _guard() {
    if (!canUseProfile()) throw StateError('Das Kinderprofil hat gewechselt');
  }

  static Future<MemoryRoundController> open({
    required String owner,
    required MemoryCatalog catalog,
    required MemoryStore store,
    required MemoryAward award,
    required bool Function() canUseProfile,
    String? difficulty,
    String? pack,
    int? seed,
    bool configureUnplayed = false,
  }) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        (difficulty != null && !memoryDifficulties.contains(difficulty)) ||
        (pack != null && !memoryPacks.contains(pack))) {
      throw ArgumentError('Ungültige Memory-Zuordnung');
    }
    final controller = MemoryRoundController._(
      owner: owner, catalog: catalog, store: store, award: award,
      canUseProfile: canUseProfile,
    );
    await controller._serial(() async {
      controller._guard();
      await controller._loadStats();
      final raw = await store.readRound();
      controller._guard();
      if (raw != null) {
        // Corrupt/private foreign rounds are never replaced with defaults.
        controller._round = MemoryRound.read(raw, catalog, owner);
        controller.restored = true;
        final rules = controller._round.rules;
        final unplayed = rules.phase == 'select' && rules.turn == 'kind' &&
            rules.kindMoves == 0 && rules.kindPairs == 0 && rules.lumoPairs == 0 &&
            rules.known.isEmpty && rules.faceUp.every((v) => !v) &&
            rules.matched.every((v) => !v);
        if (configureUnplayed && !controller._round.paused && unplayed &&
            (difficulty != null || pack != null || seed != null)) {
          // Explicit entry settings may configure a board before its first
          // touch. They never replace a begun, paused or unsettled round.
          final previous = controller._round;
          final next = MemoryRound(
            owner: owner, id: MemoryRound.newId(), revision: previous.revision + 1,
            rules: MemoryRules.start(catalog,
                seed == null ? MemoryRandom.restore(rules.random.toJson()) : MemoryRandom(seed),
                difficulty ?? rules.difficulty, pack ?? 'alle'),
          );
          await controller._commit(next);
          controller.restored = false;
        } else if (rules.complete && controller._round.rewarded) {
          // The existing screen starts another game after a settled finish.
          // Never discard a finish whose wallet/round receipt is unresolved.
          // Retain the child's pack, difficulty, bests and random stream.
          final previous = controller._round;
          final next = MemoryRound(
            owner: owner, id: MemoryRound.newId(), revision: previous.revision + 1,
            rules: MemoryRules.start(catalog,
                MemoryRandom.restore(previous.rules.random.toJson()),
                previous.rules.difficulty, previous.rules.pack),
          );
          await controller._commit(next);
          controller.restored = false;
        } else if (!controller._round.paused && !unplayed) {
          await controller._commit(controller._round.copy(catalog, paused: true));
        }
      } else {
        final savedDifficulty = controller._stats['difficulty'];
        final selected = difficulty ??
            (savedDifficulty is String && memoryDifficulties.contains(savedDifficulty)
                ? savedDifficulty : 'schwer');
        final random = MemoryRandom(seed ?? math.Random.secure().nextInt(0x80000000));
        final initial = MemoryRound(
          owner: owner, id: MemoryRound.newId(), revision: 1,
          rules: MemoryRules.start(catalog, random, selected, pack ?? 'alle'),
        );
        await controller._writeInitial(initial);
      }
    });
    return controller;
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final previous = _ownerWrites[owner] ?? Future<void>.value();
    final operation = previous.then<T>((_) => action());
    // A failed operation remains visible to its caller, but does not poison
    // the owner's later explicit retry or a new screen's read.
    late final Future<void> tail;
    void release() {
      // Only the last completed tail can leave the map. A newer queued write
      // must still wait for its actual predecessor, even after screen dispose.
      if (identical(_ownerWrites[owner], tail)) _ownerWrites.remove(owner);
    }
    tail = operation.then<void>((_) => release(),
        onError: (Object _, StackTrace __) => release());
    _ownerWrites[owner] = tail;
    return operation;
  }

  Future<void> _loadStats() async {
    try {
      final raw = await store.readStats();
      _guard();
      if (raw == null) return;
      final document = jsonDecode(raw);
      if (document is! Map<String, dynamic>) throw const FormatException('Memory-Bestwerte');
      final savedBest = document['best'] ?? <String, dynamic>{};
      if (savedBest is! Map) throw const FormatException('Memory-Bestwerte');
      final values = <String, int>{};
      for (final entry in savedBest.entries) {
        if (entry.key is! String || !memoryDifficulties.contains(entry.key) ||
            entry.value is! int || (entry.value as int) < 1) {
          throw const FormatException('Ungültiger Memory-Bestwert');
        }
        values[entry.key as String] = entry.value as int;
      }
      _stats = Map<String, dynamic>.from(document);
      _best = values;
    } catch (_) {
      _guard();
      // Existing unreadable statistics remain byte-for-byte untouched.
      _statsWritable = false;
    }
  }

  Future<void> _writeInitial(MemoryRound next) async {
    _guard();
    if (await store.readRound() != null) {
      throw StateError('Eine Memory-Runde wurde inzwischen gespeichert');
    }
    _guard();
    final text = jsonEncode(next.toJson());
    try {
      await store.writeRound(text);
    } catch (_) {
      _guard();
      if (await store.readRound() != text) rethrow;
    }
    _guard();
    _round = next;
  }

  Future<void> _checkDisk() async {
    _guard();
    final raw = await store.readRound();
    _guard();
    if (raw == null) throw StateError('Memory-Spielstand fehlt');
    final disk = MemoryRound.read(raw, catalog, owner);
    if (_uncertain) {
      if (disk.id != _round.id || disk.revision < _round.revision) {
        throw StateError('Memory-Spielstand wurde anderweitig ersetzt');
      }
      _round = disk;
      _uncertain = false;
    } else if (jsonEncode(disk.toJson()) != jsonEncode(_round.toJson())) {
      throw StateError('Eine neuere Memory-Runde hat Vorrang');
    }
  }

  Future<void> _commit(MemoryRound next) async {
    _guard();
    if (next.owner != owner || next.revision >= 1000000000) {
      throw StateError('Memory-Speichergrenze erreicht');
    }
    await _checkDisk();
    _guard();
    final text = jsonEncode(next.toJson());
    try {
      await store.writeRound(text);
    } catch (_) {
      _uncertain = true;
      _guard();
      final observed = await store.readRound();
      _guard();
      if (observed != text) rethrow;
      _uncertain = false;
    }
    _guard();
    _round = next;
  }

  Future<bool> flip(int index) => _serial(() async {
    await _checkDisk();
    if (_round.paused) return false;
    final next = _round.copy(catalog);
    if (!next.rules.flip(index)) return false;
    await _commit(next);
    return true;
  });

  Future<bool> advance(int elapsedMs) => _serial(() async {
    await _checkDisk();
    if (_round.paused) return false;
    final next = _round.copy(catalog);
    if (!next.rules.elapse(elapsedMs)) return false;
    await _commit(next);
    await _settleReward();
    return true;
  });

  Future<void> setPaused(bool paused, {int elapsedMs = 0}) => _serial(() async {
    await _checkDisk();
    if (elapsedMs < 0 || elapsedMs > 60000) throw ArgumentError.value(elapsedMs);
    final next = _round.copy(catalog, paused: paused);
    final advanced = !_round.paused && next.rules.elapse(elapsedMs);
    if (advanced || _round.paused != paused) await _commit(next);
    if (!paused) await _settleReward();
  });

  Future<void> settleReward() => _serial(() async {
    await _checkDisk();
    await _settleReward();
  });

  Future<void> _settleReward() async {
    _guard();
    if (!_round.rules.complete || _round.rewarded) return;
    final current = _round;
    // A crash after the wallet write but before this round receipt retries the
    // same owner+round ID through the existing idempotent AppState wallet.
    await award(current.resultId, current.rules.difficulty,
        current.rules.kindPairs, current.rules.lumoPairs);
    _guard();
    if (!identical(current, _round)) throw StateError('Memory-Runde hat gewechselt');
    final nextBest = Map<String, int>.from(_best);
    if (current.rules.kindPairs > current.rules.lumoPairs) {
      final old = nextBest[current.rules.difficulty];
      if (old == null || current.rules.kindMoves < old) {
        nextBest[current.rules.difficulty] = current.rules.kindMoves;
      }
    }
    await _saveStats(current.rules.difficulty, nextBest);
    _guard();
    await _commit(current.copy(catalog, rewarded: true));
  }

  Future<void> _saveStats(String difficulty, Map<String, int> best) async {
    if (!_statsWritable) return;
    _guard();
    final next = <String, dynamic>{..._stats, 'difficulty': difficulty, 'best': best};
    final encoded = jsonEncode(next);
    try {
      await store.writeStats(encoded);
    } catch (_) {
      _guard();
      if (await store.readStats() != encoded) rethrow;
    }
    _guard();
    _stats = next;
    _best = Map<String, int>.from(best);
  }

  Future<void> restart({String? difficulty, String? pack}) => _serial(() async {
    await _checkDisk();
    if ((difficulty != null && !memoryDifficulties.contains(difficulty)) ||
        (pack != null && !memoryPacks.contains(pack))) {
      throw ArgumentError('Unbekannte Memory-Einstellung');
    }
    await _settleReward();
    _guard();
    final random = MemoryRandom.restore(_round.rules.random.toJson());
    final next = MemoryRound(
      owner: owner, id: MemoryRound.newId(), revision: _round.revision + 1,
      rules: MemoryRules.start(catalog, random,
          difficulty ?? state.difficulty, pack ?? state.pack),
    );
    await _commit(next);
    await _saveStats(next.rules.difficulty, _best);
  });

  Future<void> flush() => _serial(() async {
    await _checkDisk();
    await _settleReward();
  });

  void dispose() {
    _closed = true;
  }
}
