import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'game_level_model.dart';
import 'mini_game_learning_task.dart';

abstract interface class MiniGameRoundStore {
  Future<String?> read();
  Future<void> write(String snapshot);
}

typedef MiniGameLevelSave = Future<void> Function(int stars);
typedef MiniGameAward = Future<void> Function(
    String resultId, int stars, int xp);

class MiniGameResponse {
  MiniGameResponse(
      {this.attempts = const [],
      this.help = 0,
      this.selected,
      this.boxes = const [],
      this.order = const []});

  final List<String> attempts;
  final int help;
  final String? selected;
  final List<bool> boxes;
  final List<int> order;

  bool solved(MiniGameLearningTask task) =>
      attempts.isNotEmpty && task.accepts(attempts.last);
  bool independent(MiniGameLearningTask task) =>
      solved(task) && attempts.length == 1 && help == 0;

  MiniGameResponse copy(
          {List<String>? attempts,
          int? help,
          String? selected,
          bool clearSelection = false,
          List<bool>? boxes,
          List<int>? order}) =>
      MiniGameResponse(
        attempts: List.unmodifiable(attempts ?? this.attempts),
        help: help ?? this.help,
        selected: clearSelection ? null : selected ?? this.selected,
        boxes: List.unmodifiable(boxes ?? this.boxes),
        order: List.unmodifiable(order ?? this.order),
      );

  Map<String, Object?> toJson() => {
        'attempts': attempts,
        'help': help,
        'selected': selected,
        'boxes': boxes,
        'order': order,
      };

  static MiniGameResponse read(Object? raw, MiniGameLearningTask task) {
    if (raw is! Map<String, dynamic> ||
        raw['attempts'] is! List ||
        raw['help'] is! int ||
        (raw['help'] as int) < 0 ||
        (raw['help'] as int) > 3 ||
        raw['boxes'] is! List ||
        raw['order'] is! List ||
        (raw['selected'] != null && raw['selected'] is! String)) {
      throw const FormatException('Die gespeicherte Antwort ist ungültig.');
    }
    final attempts = raw['attempts'] as List;
    final boxes = raw['boxes'] as List;
    final order = raw['order'] as List;
    bool admissible(String value) {
      if (task.input == MiniGameInput.boxes) {
        final number = int.tryParse(value);
        return number != null && number >= 0 && number <= 10;
      }
      if (task.input == MiniGameInput.orderedWords) {
        final words = value.split(' ');
        return words.length == task.choices.length &&
            words.toSet().length == words.length &&
            words.every(task.choices.contains);
      }
      return task.choices.contains(value);
    }

    if (attempts.length > 200 ||
        attempts.any((a) => a is! String || !admissible(a)) ||
        attempts
            .take(max(0, attempts.length - 1))
            .any((a) => task.accepts(a as String)) ||
        boxes.any((b) => b is! bool) ||
        order.any((i) => i is! int || i < 0 || i >= task.choices.length) ||
        order.toSet().length != order.length ||
        (task.input == MiniGameInput.boxes
            ? boxes.length != 10
            : boxes.isNotEmpty) ||
        (task.input != MiniGameInput.orderedWords && order.isNotEmpty) ||
        (raw['selected'] != null && !admissible(raw['selected'] as String))) {
      throw const FormatException(
          'Die gespeicherten Lernhandlungen passen nicht zur Aufgabe.');
    }
    return MiniGameResponse(
        attempts: List<String>.from(attempts),
        help: raw['help'] as int,
        selected: raw['selected'] as String?,
        boxes: List<bool>.from(boxes),
        order: List<int>.from(order));
  }
}

class MiniGameRound {
  MiniGameRound(
      {required this.owner,
      required this.id,
      required this.seed,
      required this.level,
      required this.tasks,
      required this.responses,
      this.index = 0,
      this.finishRequested = false,
      this.rewarded = false,
      this.revision = 1});

  final String owner, id;
  final int seed, index, revision;
  final GameLevel level;
  final List<MiniGameLearningTask> tasks;
  final List<MiniGameResponse> responses;
  final bool finishRequested, rewarded;

  MiniGameLearningTask get task => tasks[index];
  MiniGameResponse get response => responses[index];
  String get resultId => 'mini:$owner:$id';
  bool get complete =>
      List.generate(tasks.length, (i) => responses[i].solved(tasks[i]))
          .every((solved) => solved);
  int get solvedCount =>
      List.generate(tasks.length, (i) => responses[i].solved(tasks[i]) ? 1 : 0)
          .fold(0, (a, b) => a + b);
  int get firstCorrectCount => List.generate(
      tasks.length,
      (i) => responses[i].attempts.length == 1 && responses[i].solved(tasks[i])
          ? 1
          : 0).fold(0, (a, b) => a + b);
  int get independentCount => List.generate(
          tasks.length, (i) => responses[i].independent(tasks[i]) ? 1 : 0)
      .fold(0, (a, b) => a + b);
  int get mistakeTasks => List.generate(
      tasks.length,
      (i) => responses[i].attempts.any((answer) => !tasks[i].accepts(answer))
          ? 1
          : 0).fold(0, (a, b) => a + b);
  int get mistakes => List.generate(
      tasks.length,
      (i) => responses[i]
          .attempts
          .where((answer) => !tasks[i].accepts(answer))
          .length).fold(0, (a, b) => a + b);

  // The established amounts are retained, including LetterFill's first-answer
  // formula even though an incorrect letter now gets a genuine retry.
  int get walletStars => switch (level.miniType) {
        GameMiniType.colorBoxes => solvedCount,
        GameMiniType.letterFill =>
          (firstCorrectCount * 5 / tasks.length).round().clamp(1, 5),
        GameMiniType.starsPath ||
        GameMiniType.numberHouse =>
          solvedCount == tasks.length && mistakeTasks == 0
              ? 3
              : solvedCount == tasks.length && mistakeTasks <= 2
                  ? 2
                  : solvedCount >= 3
                      ? 1
                      : 0,
        _ => min(
            level.maxStars,
            mistakes == 0
                ? 3
                : mistakes <= 2
                    ? 2
                    : 1),
      };
  int get levelStars => walletStars.clamp(0, level.maxStars);
  int get xp => level.miniType == GameMiniType.colorBoxes
      ? solvedCount * 5
      : level.miniType == GameMiniType.letterFill
          ? firstCorrectCount * 8
          : solvedCount * 8;

  static String newId() {
    final random = Random.secure();
    return List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static MiniGameRound fresh(
      {required String owner,
      required GameLevel level,
      int? seed,
      String? id}) {
    final actualSeed = seed ?? Random.secure().nextInt(1 << 30);
    final actualId = id ?? newId();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(actualId)) {
      throw ArgumentError('Ungültige Lernspiel-Runde.');
    }
    final tasks = MiniGameLearningDeck.build(level, actualSeed);
    return MiniGameRound(
        owner: owner,
        id: actualId,
        seed: actualSeed,
        level: level,
        tasks: tasks,
        responses: [
          for (final task in tasks)
            MiniGameResponse(boxes: List.unmodifiable(task.initialBoxes))
        ]);
  }

  MiniGameRound copy(
          {List<MiniGameResponse>? responses,
          int? index,
          bool? finishRequested,
          bool? rewarded}) =>
      MiniGameRound(
          owner: owner,
          id: id,
          seed: seed,
          level: level,
          tasks: tasks,
          responses: List.unmodifiable(responses ?? this.responses),
          index: index ?? this.index,
          revision: revision + 1,
          finishRequested: finishRequested ?? this.finishRequested,
          rewarded: rewarded ?? this.rewarded);

  Map<String, Object?> toJson() => {
        'schema': 1,
        'owner': owner,
        'id': id,
        'seed': seed,
        'levelId': level.id,
        'index': index,
        'revision': revision,
        'finishRequested': finishRequested,
        'rewarded': rewarded,
        'responses': [for (final response in responses) response.toJson()],
      };

  static MiniGameRound read(String text,
      {required String owner, required GameLevel level}) {
    final raw = jsonDecode(text);
    if (raw is! Map<String, dynamic> ||
        raw['schema'] != 1 ||
        raw['owner'] != owner ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        raw['levelId'] != level.id ||
        raw['id'] is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(raw['id'] as String) ||
        raw['seed'] is! int ||
        (raw['seed'] as int) < 0 ||
        (raw['seed'] as int) >= 1 << 30 ||
        raw['index'] is! int ||
        (raw['index'] as int) < 0 ||
        raw['revision'] is! int ||
        (raw['revision'] as int) < 1 ||
        (raw['revision'] as int) >= 1000000000 ||
        raw['finishRequested'] is! bool ||
        raw['rewarded'] is! bool ||
        raw['responses'] is! List) {
      throw const FormatException(
          'Die angefangene Lernspiel-Runde ist ungültig.');
    }
    final tasks = MiniGameLearningDeck.build(level, raw['seed'] as int);
    final stored = raw['responses'] as List;
    if (stored.length != tasks.length || raw['index'] as int >= tasks.length) {
      throw const FormatException(
          'Die Lernspiel-Runde hat eine unpassende Länge.');
    }
    final round = MiniGameRound(
        owner: owner,
        id: raw['id'] as String,
        seed: raw['seed'] as int,
        level: level,
        tasks: tasks,
        index: raw['index'] as int,
        revision: raw['revision'] as int,
        finishRequested: raw['finishRequested'] as bool,
        rewarded: raw['rewarded'] as bool,
        responses: List.generate(
            tasks.length, (i) => MiniGameResponse.read(stored[i], tasks[i])));
    for (var i = 0; i < tasks.length; i++) {
      if (i < round.index && !round.responses[i].solved(tasks[i]) ||
          i > round.index &&
              (round.responses[i].attempts.isNotEmpty ||
                  round.responses[i].help != 0)) {
        throw const FormatException('Die Antwortreihenfolge ist ungültig.');
      }
    }
    if ((round.finishRequested && !round.complete) ||
        (round.rewarded && !round.finishRequested)) {
      throw const FormatException(
          'Eine unvollständige Runde hat keinen Abschluss.');
    }
    return round;
  }
}

/// Captures an owner and journals each accepted input before acknowledging it.
/// A failed write retains the exact same snapshot for retry. Completion uses
/// the wallet's existing result-ID ledger and is safe after process death.
class MiniGameRoundController {
  MiniGameRoundController._(
      {required this.owner,
      required this.level,
      required this.store,
      required this.saveLevel,
      required this.award,
      required bool Function() canUseProfile})
      : _profile = canUseProfile;

  static final Map<String, Future<void>> _owners = {};
  final String owner;
  final GameLevel level;
  final MiniGameRoundStore store;
  final MiniGameLevelSave saveLevel;
  final MiniGameAward award;
  final bool Function() _profile;
  late MiniGameRound _round;
  MiniGameRound? _pending;
  bool _closed = false, _busy = false;
  bool restored = false;

  MiniGameRound get round => _pending ?? _round;
  bool get hasPending => _pending != null;
  bool get busy => _busy;
  bool get canUseProfile => !_closed && _profile();
  bool get canWork =>
      canUseProfile &&
      !_busy &&
      !hasPending &&
      !round.finishRequested &&
      !round.response.solved(round.task);

  void _guard() {
    if (!canUseProfile) throw StateError('Das Kinderprofil hat gewechselt.');
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final key = '$owner:${level.id}';
    final previous = _owners[key] ?? Future<void>.value();
    final next = previous.then((_) => action());
    final done = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _owners[key] = done;
    unawaited(done.then((_) {
      if (identical(_owners[key], done)) _owners.remove(key);
    }));
    return next;
  }

  static Future<MiniGameRoundController> open(
      {required String owner,
      required GameLevel level,
      required MiniGameRoundStore store,
      required MiniGameLevelSave saveLevel,
      required MiniGameAward award,
      required bool Function() canUseProfile,
      int? seed,
      String? id}) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner)) {
      throw ArgumentError('Ungültiger Besitzer der Lernspiel-Runde.');
    }
    final controller = MiniGameRoundController._(
        owner: owner,
        level: level,
        store: store,
        saveLevel: saveLevel,
        award: award,
        canUseProfile: canUseProfile);
    await controller._serial(() async {
      controller._guard();
      final text = await store.read();
      controller._guard();
      if (text != null) {
        controller._round =
            MiniGameRound.read(text, owner: owner, level: level);
        controller.restored = true;
      } else {
        final round =
            MiniGameRound.fresh(owner: owner, level: level, seed: seed, id: id);
        await store.write(jsonEncode(round.toJson()));
        controller._round = round;
      }
    });
    return controller;
  }

  Future<bool> _change(MiniGameRound? Function(MiniGameRound) update) async {
    if (_busy || hasPending || !canUseProfile) return false;
    _busy = true;
    try {
      return await _serial(() async {
        _guard();
        final next = update(_round);
        if (next == null) return false;
        await _commit(next);
        return true;
      });
    } finally {
      _busy = false;
    }
  }

  Future<void> _commit(MiniGameRound next) async {
    _guard();
    _pending = next;
    await store.write(jsonEncode(next.toJson()));
    _round = next;
    _pending = null;
  }

  MiniGameRound _response(MiniGameRound round, MiniGameResponse response) {
    final responses = [...round.responses];
    responses[round.index] = response;
    return round.copy(responses: responses);
  }

  Future<bool> select(String answer) => _change((round) {
        if (round.finishRequested ||
            round.response.solved(round.task) ||
            !round.task.choices.contains(answer) ||
            round.task.input == MiniGameInput.orderedWords) return null;
        return _response(round, round.response.copy(selected: answer));
      });

  Future<bool> toggleBox(int index) => _change((round) {
        if (round.finishRequested ||
            round.response.solved(round.task) ||
            round.task.input != MiniGameInput.boxes ||
            index < 0 ||
            index >= 10) return null;
        final boxes = [...round.response.boxes];
        boxes[index] = !boxes[index];
        return _response(round, round.response.copy(boxes: boxes));
      });

  Future<bool> orderWord(int index) => _change((round) {
        if (round.finishRequested ||
            round.response.solved(round.task) ||
            round.task.input != MiniGameInput.orderedWords ||
            index < 0 ||
            index >= round.task.choices.length ||
            round.response.order.contains(index)) return null;
        return _response(round,
            round.response.copy(order: [...round.response.order, index]));
      });

  Future<bool> clearOrder() => _change((round) {
        if (round.finishRequested ||
            round.response.solved(round.task) ||
            round.task.input != MiniGameInput.orderedWords) return null;
        return _response(round, round.response.copy(order: []));
      });

  Future<bool> help(int level) => _change((round) {
        if (round.finishRequested ||
            round.response.solved(round.task) ||
            level <= round.response.help ||
            level < 1 ||
            level > 3) return null;
        return _response(round, round.response.copy(help: level));
      });

  Future<bool> answer([String? confirmedChoice]) => _change((round) {
        if (round.finishRequested || round.response.solved(round.task))
          return null;
        final response = round.response;
        final task = round.task;
        final answer = switch (task.input) {
          MiniGameInput.boxes => '${response.boxes.where((box) => box).length}',
          MiniGameInput.orderedWords =>
            response.order.length == task.choices.length
                ? response.order.map((i) => task.choices[i]).join(' ')
                : null,
          _ => confirmedChoice ?? response.selected,
        };
        if (answer == null ||
            (task.input != MiniGameInput.boxes &&
                task.input != MiniGameInput.orderedWords &&
                !task.choices.contains(answer)) ||
            (response.attempts.isNotEmpty && response.attempts.last == answer))
          return null;
        if (response.attempts.length >= 200) {
          throw StateError('Starte diese Runde bitte neu, um weiterzuüben.');
        }
        return _response(
            round,
            response.copy(
                attempts: [...response.attempts, answer],
                selected: task.input == MiniGameInput.boxes ? null : answer));
      });

  Future<bool> next() => _change((round) {
        if (round.finishRequested || !round.response.solved(round.task))
          return null;
        return round.index + 1 < round.tasks.length
            ? round.copy(index: round.index + 1)
            : round.copy(finishRequested: true);
      });

  Future<bool> restart({int? seed, String? id}) => _change((round) {
        if (round.finishRequested && !round.rewarded) return null;
        return MiniGameRound.fresh(
            owner: owner, level: level, seed: seed, id: id);
      });

  Future<void> retry() async {
    if (_busy || !canUseProfile) return;
    _busy = true;
    try {
      await _serial(() async {
        _guard();
        if (_pending != null) await _commit(_pending!);
      });
    } finally {
      _busy = false;
    }
    await settleResult();
  }

  Future<void> settleResult() async {
    if (_busy || hasPending || !canUseProfile) return;
    _busy = true;
    try {
      await _serial(() async {
        _guard();
        final round = _round;
        if (!round.finishRequested || round.rewarded || !round.complete) return;
        await saveLevel(round.levelStars);
        _guard();
        await award(round.resultId, round.walletStars, round.xp);
        _guard();
        await _commit(round.copy(rewarded: true));
      });
    } finally {
      _busy = false;
    }
  }

  void close() {
    _closed = true;
  }
}
