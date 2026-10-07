import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/core/game_progress_repository.dart';
import '../../lib/domain/games/game_level_catalog.dart';

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
          childId: child, levelId: first.id, starsEarned: first.maxStars),
      GameProgressRepository().recordResult(
          childId: child, levelId: first.id, starsEarned: 1),
    ]);
    expect((await repo.loadStars(child))[first.id], first.maxStars);
  });

  test('reset requested after result does not resurrect that result', () async {
    final saved = repo.recordResult(
        childId: child, levelId: first.id, starsEarned: 3);
    final reset = repo.reset(child);
    await saved;
    await reset;
    expect(await repo.loadStars(child), isEmpty);
  });

  test('new result after reset belongs to the new progress state', () async {
    await repo.saveStars(child, <int, int>{first.id: 3});
    final reset = repo.reset(child);
    final saved = repo.recordResult(
        childId: child, levelId: second.id, starsEarned: 2);
    await reset;
    await saved;
    expect(await repo.loadStars(child), <int, int>{second.id: 2});
  });

  test('read requested behind a result observes that result', () async {
    final saved = repo.recordResult(
        childId: child, levelId: first.id, starsEarned: 2);
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

  test('many requests retain every best score across repository instances',
      () async {
    final levels = GameLevelCatalog.playableLevels.take(6).toList();
    final requests = <Future<Map<int, int>>>[];
    for (var round = 3; round >= 1; round--) {
      for (final level in levels) {
        requests.add(GameProgressRepository().recordResult(
            childId: child, levelId: level.id, starsEarned: round));
      }
    }
    await Future.wait(requests);
    final restored = await repo.loadStars(child);
    for (final level in levels) {
      expect(restored[level.id], level.maxStars);
    }
  });

  test('invalid level request does not erase valid progress', () async {
    await repo.recordResult(
        childId: child, levelId: first.id, starsEarned: 2);
    final result = await repo.recordResult(
        childId: child, levelId: -999, starsEarned: 3);
    expect(result, <int, int>{first.id: 2});
    expect(await repo.loadStars(child), <int, int>{first.id: 2});
  });

  test('corrupt legacy JSON can be read without crashing or changing bytes',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'lumo.games.stars.$child';
    await prefs.setString(key, '{broken-json');
    expect(await repo.loadStars(child), isEmpty);
    expect(prefs.getString(key), '{broken-json');
  });
}
