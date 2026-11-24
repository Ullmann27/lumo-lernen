import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';

import 'connect_four_engine.dart';

/// A legal move history is the save. The existing engine alone reconstructs
/// cells, turns, wins and draws; neither Android nor Godot supplies a result.
class ConnectFourRound {
  ConnectFourRound({
    required this.owner,
    required this.id,
    required this.seed,
    required this.revision,
    required this.twoPlayers,
    required this.level,
    required List<int> columns,
    this.rewarded = false,
  }) : columns = List.unmodifiable(columns);

  final String owner;
  final String id;
  final int seed;
  final int revision;
  final bool twoPlayers;
  final ConnectLumoLevel level;
  final List<int> columns;
  final bool rewarded;

  static String ownerKey(String studentId) {
    if (studentId.trim().isEmpty || studentId.length > 512) {
      throw StateError('Ungültige Kinderidentität');
    }
    return sha256.convert(utf8.encode(studentId)).toString();
  }

  static String newId() {
    final random = Random.secure();
    return List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  ConnectFourEngine replay() {
    final engine = ConnectFourEngine();
    if (columns.length > 42) throw const FormatException('Too many moves');
    for (final column in columns) {
      if (engine.drop(column) == null) {
        throw const FormatException('Illegal Connect Four history');
      }
    }
    if (rewarded && engine.phase == ConnectPhase.playing) {
      throw const FormatException('Unfinished result cannot be rewarded');
    }
    return engine;
  }

  Map<String, Object?> toJson() => {
        'schema': 1,
        'owner': owner,
        'id': id,
        'seed': seed,
        'revision': revision,
        'twoPlayers': twoPlayers,
        'level': level.name,
        'columns': columns,
        'rewarded': rewarded,
      };

  factory ConnectFourRound.decode(String source, String expectedOwner) {
    if (source.length > 16384) throw const FormatException('Save too large');
    final raw = jsonDecode(source);
    const keys = {
      'schema',
      'owner',
      'id',
      'seed',
      'revision',
      'twoPlayers',
      'level',
      'columns',
      'rewarded',
    };
    if (raw is! Map<String, dynamic> ||
        raw.keys.toSet().difference(keys).isNotEmpty ||
        raw.length != keys.length ||
        raw['schema'] is! int ||
        raw['schema'] != 1 ||
        raw['owner'] != expectedOwner ||
        raw['id'] is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(raw['id'] as String) ||
        raw['seed'] is! int ||
        (raw['seed'] as int) < 0 ||
        (raw['seed'] as int) > 0x7fffffff ||
        raw['revision'] is! int ||
        (raw['revision'] as int) < 1 ||
        (raw['revision'] as int) > 1000000000 ||
        raw['twoPlayers'] is! bool ||
        raw['rewarded'] is! bool ||
        raw['columns'] is! List ||
        (raw['columns'] as List).any((v) => v is! int || v < 0 || v > 6) ||
        !ConnectLumoLevel.values.any((v) => v.name == raw['level'])) {
      throw const FormatException('Invalid Connect Four save');
    }
    final value = ConnectFourRound(
      owner: expectedOwner,
      id: raw['id'] as String,
      seed: raw['seed'] as int,
      revision: raw['revision'] as int,
      twoPlayers: raw['twoPlayers'] as bool,
      level: ConnectLumoLevel.values.firstWhere((v) => v.name == raw['level']),
      columns: List<int>.from(raw['columns'] as List),
      rewarded: raw['rewarded'] as bool,
    );
    value.replay();
    return value;
  }

  ConnectFourRound copy(
          {List<int>? columns, ConnectLumoLevel? level, bool? rewarded}) =>
      ConnectFourRound(
        owner: owner,
        id: id,
        seed: seed,
        revision: revision + 1,
        twoPlayers: twoPlayers,
        level: level ?? this.level,
        columns: columns ?? this.columns,
        rewarded: rewarded ?? this.rewarded,
      );
}

abstract interface class ConnectFourStore {
  Future<ConnectFourRound?> load(String owner, bool Function() current);
  Future<void> save(ConnectFourRound next, ConnectFourRound? previous,
      bool Function() current);
}

/// New namespace only. No legacy/profile/wallet key is migrated or removed.
class ConnectFourRoundRepository implements ConnectFourStore {
  static String key(String owner) => 'lumo.connect_four.round.v1.$owner';

  @override
  Future<ConnectFourRound?> load(String owner, bool Function() current) =>
      LearningStorage.run((prefs) async {
        if (!current()) throw StateError('Kinderprofil hat gewechselt');
        final raw = prefs.getString(key(owner));
        return raw == null ? null : ConnectFourRound.decode(raw, owner);
      });

  @override
  Future<void> save(ConnectFourRound next, ConnectFourRound? previous,
          bool Function() current) =>
      LearningStorage.run((prefs) async {
        if (!current()) throw StateError('Kinderprofil hat gewechselt');
        final raw = prefs.getString(key(next.owner));
        if ((previous == null && raw != null) ||
            (previous != null && raw != jsonEncode(previous.toJson()))) {
          throw StateError('Eine neuere Runde ist bereits gespeichert');
        }
        next.replay();
        if (!current()) throw StateError('Kinderprofil hat gewechselt');
        await LearningStorage.write(
            prefs, key(next.owner), jsonEncode(next.toJson()));
        // An in-flight write is still bound to its captured old owner key.
        // It must never install old state into a newly selected child's UI.
        if (!current()) throw StateError('Kinderprofil hat gewechselt');
      });
}

typedef ConnectFourAward = Future<void> Function(String id, int stars, int xp);

/// One shared Dart round for Flutter and the native presentation. Every move
/// is saved before its engine is installed or its native action acknowledged.
class ConnectFourRoundController extends ChangeNotifier {
  ConnectFourRoundController._(
      this._round, this.store, this.canUseProfile, this.award)
      : _engine = _round.replay();

  final ConnectFourStore store;
  final bool Function() canUseProfile;
  final ConnectFourAward award;
  ConnectFourRound _round;
  ConnectFourEngine _engine;
  ConnectFourRound get round => _round;
  ConnectFourEngine get engine => _engine;
  String get announcement {
    final side = _engine.turn == ConnectPiece.child
        ? 'Cyan'
        : (_round.twoPlayers ? 'Gold' : 'Lumo');
    if (_engine.phase == ConnectPhase.draw) {
      return 'Deine gespeicherte Runde endet unentschieden.';
    }
    if (_engine.phase == ConnectPhase.won) {
      return 'Deine gespeicherte Runde ist beendet. $side hat gewonnen.';
    }
    final mode = _round.twoPlayers
        ? 'Ihr spielt zu zweit: Cyan und Gold.'
        : 'Du spielst mit Cyan, Lumo mit Gold.';
    final turn = _engine.turn == ConnectPiece.child
        ? (_round.twoPlayers ? 'Cyan ist dran.' : 'Du bist dran.')
        : (_round.twoPlayers ? 'Gold ist dran.' : 'Lumo ist dran.');
    return 'Vier gewinnt! $mode $turn';
  }

  bool _closed = false;
  Future<void> _tail = Future.value();

  static Future<ConnectFourRoundController> open({
    required String studentId,
    required bool Function() canUseProfile,
    required ConnectFourAward award,
    ConnectFourStore? store,
    int? seed,
  }) async {
    if (seed != null && (seed < 0 || seed > 0x7fffffff)) {
      throw ArgumentError.value(seed, 'seed');
    }
    final storage = store ?? ConnectFourRoundRepository();
    final owner = ConnectFourRound.ownerKey(studentId);
    if (!canUseProfile()) throw StateError('Kinderprofil hat gewechselt');
    var round = await storage.load(owner, canUseProfile);
    if (!canUseProfile()) throw StateError('Kinderprofil hat gewechselt');
    if (round == null) {
      round = ConnectFourRound(
          owner: owner,
          id: ConnectFourRound.newId(),
          seed: seed ?? Random.secure().nextInt(0x7fffffff),
          revision: 1,
          twoPlayers: false,
          level: ConnectLumoLevel.mittel,
          columns: const []);
      await storage.save(round, null, canUseProfile);
    }
    if (!canUseProfile()) throw StateError('Kinderprofil hat gewechselt');
    final controller =
        ConnectFourRoundController._(round, storage, canUseProfile, award);
    await controller.settleReward();
    return controller;
  }

  void _guard() {
    if (_closed || !canUseProfile())
      throw StateError('Kinderprofil hat gewechselt');
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) {
      _guard();
      return action();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _commit(ConnectFourRound next) async {
    _guard();
    await store.save(next, _round, () => !_closed && canUseProfile());
    _guard();
    _round = next;
    _engine = next.replay();
    notifyListeners();
  }

  Future<ConnectPosition?> play(int column, {bool bot = false}) =>
      _serial(() async {
        if (_engine.phase != ConnectPhase.playing ||
            (bot && (_round.twoPlayers || _engine.turn != ConnectPiece.lumo)) ||
            (!bot &&
                !_round.twoPlayers &&
                _engine.turn != ConnectPiece.child)) {
          return null;
        }
        final trial = _round.replay();
        final position = trial.drop(column);
        if (position == null) return null;
        await _commit(_round.copy(columns: [..._round.columns, column]));
        await _settleReward();
        return position;
      });

  Future<ConnectPosition?> playBot() => _serial(() async {
        if (_round.twoPlayers ||
            _engine.phase != ConnectPhase.playing ||
            _engine.turn != ConnectPiece.lumo) return null;
        // Same production policy, deterministic for a restored public board.
        final column = _engine.chooseLumoColumn(
            Random(_round.seed ^ (_engine.moves * 7919)),
            level: _round.level);
        _guard();
        if (column == null) return null;
        final position = _round.replay().drop(column);
        if (position == null) throw StateError('Ungültiger Botzug');
        await _commit(_round.copy(columns: [..._round.columns, column]));
        await _settleReward();
        return position;
      });

  Future<void> setLevel(ConnectLumoLevel level) => _serial(() async {
        if (_round.level != level) await _commit(_round.copy(level: level));
      });

  Future<void> restart({bool? twoPlayers}) => _serial(() async {
        await _settleReward();
        await _commit(ConnectFourRound(
            owner: _round.owner,
            id: ConnectFourRound.newId(),
            seed: Random.secure().nextInt(0x7fffffff),
            revision: _round.revision + 1,
            twoPlayers: twoPlayers ?? _round.twoPlayers,
            level: _round.level,
            columns: const []));
      });

  ({int stars, int xp}) get reward {
    final drawn = _engine.phase == ConnectPhase.draw;
    final childWon = !drawn && _engine.turn == ConnectPiece.child;
    final stars = drawn
        ? 3
        : childWon || _round.twoPlayers
            ? 5
            : 2;
    return (stars: stars, xp: drawn ? 20 : stars * 8);
  }

  Future<void> settleReward() => _serial(_settleReward);
  Future<void> _settleReward() async {
    if (_engine.phase == ConnectPhase.playing || _round.rewarded) return;
    _guard();
    final amount = reward;
    // Round history is durable first. If process death happens after wallet
    // commit, the existing wallet de-duplicates this exact owner/round ID.
    await award('c4:${_round.owner}:${_round.id}', amount.stars, amount.xp);
    _guard();
    await _commit(_round.copy(rewarded: true));
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
