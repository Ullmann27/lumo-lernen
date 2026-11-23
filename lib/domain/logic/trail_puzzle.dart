import 'dart:collection';

/// Absolute board directions: one command always moves exactly one cell.
enum TrailDirection { up, right, down, left }

extension TrailDirectionText on TrailDirection {
  String get label => switch (this) {
        TrailDirection.up => 'Oben',
        TrailDirection.right => 'Rechts',
        TrailDirection.down => 'Unten',
        TrailDirection.left => 'Links',
      };

  String get arrow => switch (this) {
        TrailDirection.up => '↑',
        TrailDirection.right => '→',
        TrailDirection.down => '↓',
        TrailDirection.left => '←',
      };

  int get rowDelta => switch (this) {
        TrailDirection.up => -1,
        TrailDirection.down => 1,
        _ => 0,
      };
  int get columnDelta => switch (this) {
        TrailDirection.left => -1,
        TrailDirection.right => 1,
        _ => 0,
      };
}

/// A small, offline route-planning board. Station order is visible to the child.
/// Any legal route collecting every station in order is accepted, including
/// detours and revisits. There is no timer, intelligence score or shortest-path
/// requirement.
class TrailPuzzle {
  TrailPuzzle({
    required this.id,
    required this.grade,
    required this.level,
    required this.rows,
    required this.columns,
    required this.start,
    required this.goal,
    required Iterable<int> stations,
    Iterable<int> blocked = const [],
  })  : stations = List<int>.unmodifiable(stations),
        blocked = Set<int>.unmodifiable(blocked) {
    if (rows < 2 || columns < 2 || grade < 1 || grade > 4 || level < 1) {
      throw ArgumentError('Invalid route board dimensions or school grade.');
    }
    if (!contains(start) || !contains(goal) || start == goal) {
      throw ArgumentError('Start and goal must be different board cells.');
    }
    if (this.stations.isEmpty ||
        this.stations.toSet().length != this.stations.length ||
        this.stations.any((i) => !contains(i) || i == start || i == goal) ||
        this.blocked.any((i) => !contains(i)) ||
        this.blocked.contains(start) ||
        this.blocked.contains(goal) ||
        this.stations.any(this.blocked.contains)) {
      throw ArgumentError(
          'Stations and obstacles must be valid distinct cells.');
    }
  }

  final String id;
  final int grade;
  final int level;
  final int rows;
  final int columns;
  final int start;
  final int goal;
  final List<int> stations;
  final Set<int> blocked;

  String get title => 'Pfad $level · Klasse $grade';
  String get instruction => stations.length == 1
      ? 'Besuche Stern 1 und bringe die Pfote dann zum Picknick.'
      : 'Besuche die Sterne der Reihe nach: '
          '${List.generate(stations.length, (i) => i + 1).join(', ')}. '
          'Gehe dann zum Picknick.';

  bool contains(int cell) => cell >= 0 && cell < rows * columns;

  int? neighbor(int cell, TrailDirection direction) {
    if (!contains(cell)) return null;
    final row = cell ~/ columns + direction.rowDelta;
    final column = cell % columns + direction.columnDelta;
    if (row < 0 || row >= rows || column < 0 || column >= columns) return null;
    return row * columns + column;
  }
}

enum TrailStepStatus { moved, obstacle, edge, finished }

class TrailStep {
  const TrailStep(this.state, this.status, {this.collectedStation = false});
  final TrailState state;
  final TrailStepStatus status;
  final bool collectedStation;
  bool get accepted =>
      status == TrailStepStatus.moved || status == TrailStepStatus.finished;
}

/// Immutable execution state. Failed commands never move through a rock or
/// wrap from the end of one row to the start of the next.
class TrailState {
  TrailState._(this.puzzle, this.position, this.nextStation, this.moves,
      Iterable<int> visited)
      : visited = List<int>.unmodifiable(visited);

  factory TrailState.initial(TrailPuzzle puzzle) =>
      TrailState._(puzzle, puzzle.start, 0, 0, [puzzle.start]);

  final TrailPuzzle puzzle;
  final int position;
  final int nextStation;
  final int moves;
  final List<int> visited;

  bool get isComplete =>
      position == puzzle.goal && nextStation == puzzle.stations.length;

  TrailStep step(TrailDirection direction) {
    if (isComplete) return TrailStep(this, TrailStepStatus.finished);
    final destination = puzzle.neighbor(position, direction);
    if (destination == null) return TrailStep(this, TrailStepStatus.edge);
    if (puzzle.blocked.contains(destination)) {
      return TrailStep(this, TrailStepStatus.obstacle);
    }
    final collected = nextStation < puzzle.stations.length &&
        destination == puzzle.stations[nextStation];
    final next = TrailState._(
      puzzle,
      destination,
      nextStation + (collected ? 1 : 0),
      moves + 1,
      [...visited, destination],
    );
    return TrailStep(
      next,
      next.isComplete ? TrailStepStatus.finished : TrailStepStatus.moved,
      collectedStation: collected,
    );
  }
}

/// Execution stops at the first blocked step or at the completed picnic.
/// [consumed] tells the UI which prefix was actually executed.
class TrailExecution {
  TrailExecution._(this.state, this.consumed, this.failure);
  factory TrailExecution.run(
      TrailPuzzle puzzle, Iterable<TrailDirection> commands) {
    var state = TrailState.initial(puzzle);
    var consumed = 0;
    for (final command in commands) {
      final result = state.step(command);
      if (!result.accepted) {
        return TrailExecution._(state, consumed, result.status);
      }
      consumed++;
      state = result.state;
      if (state.isComplete) break;
    }
    return TrailExecution._(state, consumed, null);
  }

  final TrailState state;
  final int consumed;
  final TrailStepStatus? failure;
  bool get completed => failure == null && state.isComplete;
}

/// Breadth-first search over position AND collected-station state. Used to
/// verify authored boards and to provide a reproducible reference route.
class TrailSolver {
  static List<TrailDirection>? shortestPlan(TrailPuzzle puzzle,
      {TrailState? from}) {
    final initial = from ?? TrailState.initial(puzzle);
    if (!identical(initial.puzzle, puzzle)) {
      throw ArgumentError('The execution state belongs to another board.');
    }
    if (initial.isComplete) return const [];
    final queue = Queue<(int, int)>()
      ..add((initial.position, initial.nextStation));
    final visited = <(int, int)>{queue.first};
    final previous = <(int, int), ((int, int), TrailDirection)>{};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final direction in TrailDirection.values) {
        final destination = puzzle.neighbor(current.$1, direction);
        if (destination == null || puzzle.blocked.contains(destination)) {
          continue;
        }
        final station = current.$2 < puzzle.stations.length &&
                destination == puzzle.stations[current.$2]
            ? current.$2 + 1
            : current.$2;
        final next = (destination, station);
        if (!visited.add(next)) continue;
        previous[next] = (current, direction);
        if (destination == puzzle.goal && station == puzzle.stations.length) {
          final route = <TrailDirection>[];
          var cursor = next;
          while (previous.containsKey(cursor)) {
            final step = previous[cursor]!;
            route.add(step.$2);
            cursor = step.$1;
          }
          return List<TrailDirection>.unmodifiable(route.reversed);
        }
        queue.add(next);
      }
    }
    return null;
  }
}

class TrailCatalog {
  static const contentVersion = 'trail-2026-11-v1';
  static const levelsPerGrade = 6;
  static const maxCommands = 64;
  static final _cache = <String, TrailPuzzle>{};

  static List<TrailPuzzle> levels(int grade) => List.unmodifiable([
        for (var level = 1; level <= levelsPerGrade; level++)
          puzzle(grade, level),
      ]);

  static TrailPuzzle puzzle(int grade, int level) {
    if (grade < 1 || grade > 4) throw RangeError.range(grade, 1, 4, 'grade');
    if (level < 1 || level > levelsPerGrade) {
      throw RangeError.range(level, 1, levelsPerGrade, 'level');
    }
    final id = 'trail-g$grade-l$level-v1';
    return _cache.putIfAbsent(id, () => _build(id, grade, level));
  }

  static TrailPuzzle? fromId(String id) {
    final match = RegExp(r'^trail-g([1-4])-l([1-6])-v1$').firstMatch(id);
    return match == null
        ? null
        : puzzle(int.parse(match[1]!), int.parse(match[2]!));
  }

  static TrailPuzzle _build(String id, int grade, int level) {
    final size = grade + 3;
    final mid = size ~/ 2;
    final start = (size - 1) * size;
    final goal = size - 1;
    final choices = <List<int>>[
      [(size - 1) * size + size - 1, mid * size, mid * size + mid],
      [mid * size + mid, (size - 1) * size + size - 1, 0],
      [(size - 2) * size + size - 1, mid * size + 1, 1],
      [mid * size, (size - 1) * size + size - 1, mid],
      [size + mid, (size - 1) * size + size - 1, mid * size],
      [(size - 1) * size + mid, 0, mid * size + size - 1],
    ];
    final count = grade == 1 ? 1 : (grade == 4 ? 3 : 2);
    final stations = choices[level - 1].take(count).toList();
    final reserved = <int>{start};
    var position = start;
    for (final target in [...stations, goal]) {
      // Reserve a complete walk before adding rocks; level layouts can never
      // isolate a required station. The solver may discover a different route.
      void vertical() {
        while (position ~/ size != target ~/ size) {
          position += position ~/ size < target ~/ size ? size : -size;
          reserved.add(position);
        }
      }

      void horizontal() {
        while (position % size != target % size) {
          position += position % size < target % size ? 1 : -1;
          reserved.add(position);
        }
      }

      if ((target + level).isEven) {
        vertical();
        horizontal();
      } else {
        horizontal();
        vertical();
      }
    }
    final rocks = <int>{};
    for (var cell = 0; cell < size * size; cell++) {
      if (reserved.contains(cell)) continue;
      final pattern = (cell * 17 + level * 11 + grade * 7) % 7;
      if (pattern < 3) rocks.add(cell);
    }
    // Rotations and reflections change spatial planning, not the rule.
    int transform(int cell) {
      var row = cell ~/ size;
      var column = cell % size;
      if (level > 4) column = size - 1 - column;
      for (var turn = 0; turn < (level - 1) % 4; turn++) {
        final nextRow = column;
        column = size - 1 - row;
        row = nextRow;
      }
      return row * size + column;
    }

    return TrailPuzzle(
      id: id,
      grade: grade,
      level: level,
      rows: size,
      columns: size,
      start: transform(start),
      goal: transform(goal),
      stations: stations.map(transform),
      blocked: rocks.map(transform),
    );
  }
}

/// Saved gameplay only. Completion marks never feed the cognitive reports.
class TrailProgress {
  TrailProgress({
    required this.profileId,
    this.lastGrade = 1,
    this.lastLevel = 1,
    Map<String, List<TrailDirection>> plans = const {},
    Iterable<String> completed = const [],
  })  : plans = Map.unmodifiable({
          for (final entry in plans.entries)
            entry.key: List<TrailDirection>.unmodifiable(entry.value),
        }),
        completed = Set<String>.unmodifiable(completed);

  static const preferencePrefix = 'lumo_trail_progress_v1_';
  final String profileId;
  final int lastGrade;
  final int lastLevel;
  final Map<String, List<TrailDirection>> plans;
  final Set<String> completed;

  TrailProgress withPlan(TrailPuzzle puzzle, List<TrailDirection> commands,
          {bool complete = false}) =>
      TrailProgress(
        profileId: profileId,
        lastGrade: puzzle.grade,
        lastLevel: puzzle.level,
        plans: {...plans, puzzle.id: commands},
        completed: {...completed, if (complete) puzzle.id},
      );

  Map<String, Object> toJson() => {
        'version': 1,
        'contentVersion': TrailCatalog.contentVersion,
        'profileId': profileId,
        'lastGrade': lastGrade,
        'lastLevel': lastLevel,
        'plans': {
          for (final entry in plans.entries)
            entry.key: entry.value.map((command) => command.name).toList(),
        },
        'completed': completed.toList()..sort(),
      };

  factory TrailProgress.fromJson(Object? source) {
    if (source is! Map ||
        source['version'] != 1 ||
        source['contentVersion'] != TrailCatalog.contentVersion ||
        source['profileId'] is! String ||
        (source['profileId'] as String).trim().isEmpty ||
        source['lastGrade'] is! int ||
        source['lastLevel'] is! int ||
        source['plans'] is! Map ||
        source['completed'] is! List) {
      throw const FormatException('Invalid trail progress');
    }
    final grade = source['lastGrade'] as int;
    final level = source['lastLevel'] as int;
    if (grade < 1 || grade > 4 || level < 1 || level > 6) {
      throw const FormatException('Invalid trail selection');
    }
    final plans = <String, List<TrailDirection>>{};
    for (final entry in (source['plans'] as Map).entries) {
      if (entry.key is! String ||
          TrailCatalog.fromId(entry.key as String) == null ||
          entry.value is! List ||
          (entry.value as List).length > TrailCatalog.maxCommands) {
        throw const FormatException('Invalid trail program');
      }
      final commands = <TrailDirection>[];
      for (final value in entry.value as List) {
        final matching = TrailDirection.values.where((d) => d.name == value);
        if (matching.isEmpty) {
          throw const FormatException('Invalid trail direction');
        }
        commands.add(matching.single);
      }
      plans[entry.key as String] = commands;
    }
    final completed = <String>{};
    for (final id in source['completed'] as List) {
      if (id is! String ||
          TrailCatalog.fromId(id) == null ||
          !completed.add(id)) {
        throw const FormatException('Invalid completed trail');
      }
    }
    return TrailProgress(
      profileId: source['profileId'] as String,
      lastGrade: grade,
      lastLevel: level,
      plans: plans,
      completed: completed,
    );
  }
}
