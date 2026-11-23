import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/logic/trail_puzzle.dart';
import 'package:lumo_lernen/features/games/logic/trail_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = TrailProgressStore();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(TrailProgressStore.flushPendingWrites);

  test('programs, selection and completions remain with their child', () async {
    final puzzle = TrailCatalog.puzzle(3, 4);
    final plan = TrailSolver.shortestPlan(puzzle)!;
    await store.savePlan(
        profileId: 'child/a', puzzle: puzzle, commands: plan, complete: true);
    final a = await store.load('child/a');
    final b = await store.load('child-b');
    expect(a.plans[puzzle.id], plan);
    expect(a.completed, {puzzle.id});
    expect(a.lastGrade, 3);
    expect(b.plans, isEmpty);
    expect(b.completed, isEmpty);
    await store.clear('child-b');
    expect((await store.load('child/a')).completed, {puzzle.id});
  });

  test('unfinished programs cannot claim a completed picnic', () async {
    final puzzle = TrailCatalog.puzzle(1, 1);
    expect(
        () => store.savePlan(
            profileId: 'child', puzzle: puzzle, commands: [], complete: true),
        throwsStateError);
    expect((await store.load('child')).completed, isEmpty);
  });

  test('queued writes merge different boards and copy mutable input', () async {
    final first = TrailCatalog.puzzle(1, 1);
    final second = TrailCatalog.puzzle(2, 2);
    final plan = <TrailDirection>[TrailDirection.up];
    final a = store.savePlan(profileId: 'child', puzzle: first, commands: plan);
    plan.add(TrailDirection.down);
    final b = store.savePlan(
        profileId: 'child', puzzle: second, commands: [TrailDirection.left]);
    await Future.wait([a, b]);
    final saved = await store.load('child');
    expect(saved.plans[first.id], [TrailDirection.up]);
    expect(saved.plans[second.id], [TrailDirection.left]);
  });

  test('corruption and another profile identifier never overwrite old bytes',
      () async {
    final prefs = await SharedPreferences.getInstance();
    const key = '${TrailProgress.preferencePrefix}child';
    final bytes = jsonEncode(TrailProgress(profileId: 'other').toJson());
    await prefs.setString(key, bytes);
    await expectLater(store.load('child'), throwsFormatException);
    await expectLater(
        store.savePlan(
            profileId: 'child',
            puzzle: TrailCatalog.puzzle(1, 1),
            commands: []),
        throwsFormatException);
    expect(prefs.getString(key), bytes);
  });
}
