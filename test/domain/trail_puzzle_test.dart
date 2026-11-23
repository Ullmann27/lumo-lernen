import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/logic/trail_puzzle.dart';

void main() {
  test(
      'all 24 distinct boards have a legal full route within the program limit',
      () {
    final ids = <String>{};
    final signatures = <String>{};
    for (var grade = 1; grade <= 4; grade++) {
      final levels = TrailCatalog.levels(grade);
      expect(levels, hasLength(6));
      for (final puzzle in levels) {
        expect(ids.add(puzzle.id), isTrue);
        final rocks = puzzle.blocked.toList()..sort();
        expect(
          signatures.add('${puzzle.rows}/${puzzle.start}/${puzzle.goal}/'
              '${puzzle.stations}/$rocks'),
          isTrue,
          reason: puzzle.id,
        );
        expect(puzzle.rows, grade + 3);
        expect(puzzle.blocked, isNotEmpty, reason: puzzle.id);
        expect(puzzle.stations.length, grade == 1 ? 1 : (grade == 4 ? 3 : 2));
        final plan = TrailSolver.shortestPlan(puzzle);
        expect(plan, isNotNull, reason: puzzle.id);
        expect(plan, isNotEmpty);
        expect(plan!.length, lessThanOrEqualTo(TrailCatalog.maxCommands));
        final replay = TrailExecution.run(puzzle, plan);
        expect(replay.completed, isTrue, reason: puzzle.id);
        expect(replay.consumed, plan.length);
        expect(replay.state.nextStation, puzzle.stations.length);
        expect(replay.state.visited.every((c) => !puzzle.blocked.contains(c)),
            isTrue);
        expect(TrailExecution.run(puzzle, plan.take(plan.length - 1)).completed,
            isFalse);
        expect(identical(puzzle, TrailCatalog.fromId(puzzle.id)), isTrue);
      }
    }
    expect(ids, hasLength(24));
  });

  test('board edges never wrap, rocks never consume a successful move', () {
    final puzzle = TrailPuzzle(
      id: 'test',
      grade: 1,
      level: 1,
      rows: 3,
      columns: 3,
      start: 2,
      goal: 8,
      stations: [6],
      blocked: [5],
    );
    final state = TrailState.initial(puzzle);
    final edge = state.step(TrailDirection.right);
    expect(edge.status, TrailStepStatus.edge);
    expect(identical(edge.state, state), isTrue);
    final rock = state.step(TrailDirection.down);
    expect(rock.status, TrailStepStatus.obstacle);
    expect(rock.state.moves, 0);
    expect(rock.state.position, 2);
    expect(puzzle.neighbor(0, TrailDirection.left), isNull);
    expect(puzzle.neighbor(6, TrailDirection.down), isNull);
    expect(puzzle.neighbor(-1, TrailDirection.up), isNull);
  });

  test('stations must be visited in order, but revisits and detours are legal',
      () {
    final puzzle = TrailPuzzle(
      id: 'test',
      grade: 2,
      level: 1,
      rows: 2,
      columns: 3,
      start: 0,
      goal: 2,
      stations: [4, 1],
    );
    final tooSoon = TrailExecution.run(
        puzzle, [TrailDirection.right, TrailDirection.right]);
    expect(tooSoon.completed, isFalse);
    expect(tooSoon.state.nextStation, 0);
    final route = [
      TrailDirection.right, // Station 2 is not yet collected.
      TrailDirection.down, // Station 1.
      TrailDirection.left, TrailDirection.up, // A legal detour.
      TrailDirection.right, // Now station 2.
      TrailDirection.right,
    ];
    final replay = TrailExecution.run(puzzle, route);
    expect(replay.completed, isTrue);
    expect(replay.state.moves, route.length);
    expect(replay.state.nextStation, 2);
    expect(TrailSolver.shortestPlan(puzzle)!.length, lessThan(route.length));
    expect(TrailSolver.shortestPlan(puzzle, from: replay.state), isEmpty);
  });

  test('solver returns null for unreachable stations, not a false success', () {
    final puzzle = TrailPuzzle(
      id: 'test',
      grade: 1,
      level: 1,
      rows: 3,
      columns: 3,
      start: 0,
      goal: 2,
      stations: [8],
      blocked: [3, 4, 5],
    );
    expect(TrailSolver.shortestPlan(puzzle), isNull);
    expect(TrailExecution.run(puzzle, []).completed, isFalse);
  });

  test('invalid boards and catalog references are rejected', () {
    expect(() => TrailCatalog.puzzle(0, 1), throwsRangeError);
    expect(() => TrailCatalog.puzzle(4, 7), throwsRangeError);
    expect(TrailCatalog.fromId('trail-g1-l7-v1'), isNull);
    expect(TrailCatalog.fromId('trail-g1-l1-v2'), isNull);
    expect(
        () => TrailPuzzle(
            id: 'x',
            grade: 1,
            level: 1,
            rows: 3,
            columns: 3,
            start: 0,
            goal: 8,
            stations: [4],
            blocked: [4]),
        throwsArgumentError);
    expect(() => TrailCatalog.puzzle(1, 1).blocked.clear(),
        throwsUnsupportedError);
  });

  test('saved programs round trip, remain immutable and preserve completion',
      () {
    final puzzle = TrailCatalog.puzzle(2, 3);
    final commands = TrailSolver.shortestPlan(puzzle)!;
    final initial = TrailProgress(profileId: 'child/a');
    final completed = initial.withPlan(puzzle, commands, complete: true);
    final edited = completed.withPlan(puzzle, []);
    final copy =
        TrailProgress.fromJson(jsonDecode(jsonEncode(edited.toJson())));
    expect(copy.profileId, 'child/a');
    expect(copy.lastGrade, 2);
    expect(copy.lastLevel, 3);
    expect(copy.completed, {puzzle.id});
    expect(copy.plans[puzzle.id], isEmpty);
    expect(() => copy.plans.clear(), throwsUnsupportedError);
    expect(initial.completed, isEmpty);
  });

  test('corrupt programs are rejected without inventing an empty save', () {
    final initial = TrailProgress(profileId: 'child').toJson();
    expect(() => TrailProgress.fromJson({...initial, 'version': 2}),
        throwsFormatException);
    expect(() => TrailProgress.fromJson({...initial, 'lastGrade': 9}),
        throwsFormatException);
    expect(
        () => TrailProgress.fromJson({
              ...initial,
              'plans': {
                'trail-g1-l1-v1': ['teleport'],
              }
            }),
        throwsFormatException);
    expect(
        () => TrailProgress.fromJson({
              ...initial,
              'plans': {
                'trail-g1-l1-v1': List.filled(65, 'up'),
              }
            }),
        throwsFormatException);
    expect(
        () => TrailProgress.fromJson({
              ...initial,
              'completed': ['fake']
            }),
        throwsFormatException);
  });
}
