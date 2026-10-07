import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const child = 'ordering_child';
  const repo = GameProgressRepository();
  final first = GameLevelCatalog.playableLevels.first;
  final second = GameLevelCatalog.playableLevels.skip(1).first;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('two concurrent level results both survive reload', () async {
    await Future.wait(<Future<Map<int, int>>>[
      repo.recordResult(childId: child, levelId: first.id, starsEarned: 2),
      repo.recordResult(childId: child, levelId: second.id, starsEarned: 3),
    ]);
    final loaded = await const GameProgressRepository().loadStars(child);
    expect(loaded[first.id], 2);
    expect(loaded[second.id], 3);
  });

  test('concurrent lower score cannot downgrade a better result', () async {
    await Future.wait(<Future<Map<int, int>>>[
      GameProgressRepository().recordResult(
        childId: child,
        levelId: first.id,
        starsEarned: first.maxStars,
      ),
      GameProgressRepository().recordResult(
        childId: child,
        levelId: first.id,
        starsEarned: 1,
      ),
    ]);
    expect((await repo.loadStars(child))[first.id], first.maxStars);
  });

  test('reset requested after result does not resurrect that result', () async {
    final saved = repo.recordResult(
      childId: child,
      levelId: first.id,
      starsEarned: 3,
    );
    final reset = repo.reset(child);
    await saved;
    await reset;
    expect(await repo.loadStars(child), isEmpty);
  });

  test('new result after reset belongs to the new progress state', () async {
    await repo.saveStars(child, <int, int>{first.id: 3});
    final reset = repo.reset(child);
    final saved = repo.recordResult(
      childId: child,
      levelId: second.id,
      starsEarned: 2,
    );
    await reset;
    await saved;
    expect(await repo.loadStars(child), <int, int>{second.id: 2});
  });

  test('read requested behind a result observes that result', () async {
    final saved = repo.recordResult(
      childId: child,
      levelId: first.id,
      starsEarned: 2,
    );
    final loaded = repo.loadStars(child);
    await saved;
    expect((await loaded)[first.id], 2);
  });

  test('saveStars snapshots input before an asynchronous gap', () async {
    final input = <int, int>{first.id: 1};
    final saved = repo.saveStars(child, input);
    input[first.id] = 3;
    await saved;
    expect((await repo.loadStars(child))[first.id], 1);
  });

  test('different children remain isolated', () async {
    await Future.wait(<Future<Map<int, int>>>[
      repo.recordResult(childId: child, levelId: first.id, starsEarned: 3),
      repo.recordResult(childId: 'other', levelId: second.id, starsEarned: 1),
    ]);
    expect(await repo.loadStars(child), <int, int>{first.id: 3});
    expect(await repo.loadStars('other'), <int, int>{second.id: 1});
  });

  test(
    'many requests retain every best score across repository instances',
    () async {
      final levels = GameLevelCatalog.playableLevels.take(6).toList();
      final requests = <Future<Map<int, int>>>[];
      for (var round = 3; round >= 1; round--) {
        for (final level in levels) {
          requests.add(
            GameProgressRepository().recordResult(
              childId: child,
              levelId: level.id,
              starsEarned: round,
            ),
          );
        }
      }
      await Future.wait(requests);
      final restored = await repo.loadStars(child);
      for (final level in levels) {
        expect(restored[level.id], level.maxStars);
      }
    },
  );

  test('invalid level request does not erase valid progress', () async {
    await repo.recordResult(childId: child, levelId: first.id, starsEarned: 2);
    final result = await repo.recordResult(
      childId: child,
      levelId: -999,
      starsEarned: 3,
    );
    expect(result, <int, int>{first.id: 2});
    expect(await repo.loadStars(child), <int, int>{first.id: 2});
  });

  test('upgrade retains earned and next legacy levels around new lessons', () async {
    SharedPreferences.setMockInitialValues({
      'lumo.games.stars.$child': '{"9":3,"11":2,"25":3}',
    });
    final stars = await repo.loadStars(child);
    final open = await repo.loadUnlocked(child);
    final runtime = repo.buildRuntime(stars, preservedUnlocked: open);
    bool locked(int id) => runtime.singleWhere((r) => r.level.id == id).locked;
    expect(locked(11), false);
    expect(locked(12), false);
    expect(locked(26), false);
    expect(locked(37), false);
    expect(locked(27), true);
    expect(await repo.loadStars(child), {9: 3, 11: 2, 25: 3});
    expect(await repo.loadUnlocked('other'), isEmpty);
  });

  test('new profiles follow all 50 lessons without the legacy shortcut', () async {
    await repo.recordResult(childId: child, levelId: 9, starsEarned: 3);
    final open = await repo.loadUnlocked(child);
    expect(open, isEmpty);
    final runtime = repo.buildRuntime(await repo.loadStars(child),
        preservedUnlocked: open);
    expect(runtime.singleWhere((r) => r.level.id == 10).locked, false);
    expect(runtime.singleWhere((r) => r.level.id == 11).locked, true);
  });

  test('reset removes migrated unlocks and migration runs only once', () async {
    SharedPreferences.setMockInitialValues({
      'lumo.games.stars.$child': '{"25":3}',
    });
    expect(await repo.loadUnlocked(child), contains(37));
    await repo.recordResult(childId: child, levelId: 9, starsEarned: 3);
    expect(await repo.loadUnlocked(child), isNot(contains(11)));
    await repo.reset(child);
    expect(await repo.loadStars(child), isEmpty);
    expect(await repo.loadUnlocked(child), isEmpty);
  });

  test(
    'corrupt legacy JSON can be read without crashing or changing bytes',
    () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'lumo.games.stars.$child';
      await prefs.setString(key, '{broken-json');
      expect(await repo.loadStars(child), isEmpty);
      expect(prefs.getString(key), '{broken-json');
    },
  );
}
