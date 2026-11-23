import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/backup/local_backup.dart';
import 'package:lumo_lernen/domain/logic/trail_puzzle.dart';
import 'package:lumo_lernen/features/games/logic/trail_progress_store.dart';

class _ControlledTrailStorage extends InMemorySharedPreferencesStore {
  _ControlledTrailStorage() : super.withData({});

  bool hold = false;
  bool reject = false;
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.startsWith('flutter.${TrailProgress.preferencePrefix}')) {
      if (hold && !entered.isCompleted) {
        entered.complete();
        await release.future;
      }
      if (reject) return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = TrailProgressStore();
  final puzzle = TrailCatalog.puzzle(1, 1);

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    await TrailProgressStore.flushPendingWrites();
    SharedPreferences.setMockInitialValues({});
  });

  test('resetting one profile preserves the other child trail program',
      () async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    final solution = TrailSolver.shortestPlan(puzzle)!;
    await store.savePlan(
      profileId: 'child-a',
      puzzle: puzzle,
      commands: solution,
      complete: true,
    );
    await store.savePlan(
      profileId: 'child-b',
      puzzle: puzzle,
      commands: [TrailDirection.right],
    );
    await app.school.setActiveStudent('child-a');
    await app.loadLearningProfile();
    await app.resetLearningProfile();

    final a = await store.load('child-a');
    final b = await store.load('child-b');
    expect(a.plans, isEmpty);
    expect(a.completed, isEmpty);
    expect(b.plans[puzzle.id], [TrailDirection.right]);
    expect((await app.captureLearningProfile()).studentId, 'child-a');
  });

  test('backup waits for an accepted trail write before reading its snapshot',
      () async {
    final disk = _ControlledTrailStorage();
    SharedPreferencesStorePlatform.instance = disk;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(() {
      if (!disk.release.isCompleted) disk.release.complete();
      app.dispose();
    });
    await store.load('child-a');
    disk.hold = true;
    final pendingWrite = store.savePlan(
      profileId: 'child-a',
      puzzle: puzzle,
      commands: [TrailDirection.right, TrailDirection.up],
    );
    await disk.entered.future.timeout(const Duration(seconds: 5));
    var read = false;
    final backup = app.withBackupStoragePaused(() async {
      read = true;
      expect(app.resetting, isTrue);
      final prefs = await SharedPreferences.getInstance();
      final saved = TrailProgress.fromJson(jsonDecode(
          prefs.getString('${TrailProgress.preferencePrefix}child-a')!));
      expect(saved.plans[puzzle.id],
          [TrailDirection.right, TrailDirection.up]);
    });
    await Future<void>.delayed(Duration.zero);
    expect(read, isFalse);
    disk.release.complete();
    await Future.wait([pendingWrite, backup]);
    expect(read, isTrue);
  });

  test('full reset drains an accepted write so its trail cannot reappear',
      () async {
    final disk = _ControlledTrailStorage();
    SharedPreferencesStorePlatform.instance = disk;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(() {
      if (!disk.release.isCompleted) disk.release.complete();
      app.dispose();
    });
    await store.load('child-a');
    disk.hold = true;
    final pendingWrite = store.savePlan(
      profileId: 'child-a',
      puzzle: puzzle,
      commands: [TrailDirection.right],
    );
    await disk.entered.future.timeout(const Duration(seconds: 5));
    final reset = app.resetAllProfile();
    await Future<void>.delayed(Duration.zero);
    disk.release.complete();
    await Future.wait([pendingWrite, reset]);
    final persisted = await disk.getAll();
    expect(
      persisted.keys.any((key) => key.contains(TrailProgress.preferencePrefix)),
      isFalse,
    );
    expect((await store.load('child-a')).plans, isEmpty);
  });

  test('backup validation binds a trail record to its exact encoded child key',
      () {
    final progress = TrailProgress(profileId: 'child/a').withPlan(
      puzzle,
      [TrailDirection.right],
    );
    final encoded = jsonEncode(progress.toJson());
    final correctKey = TrailProgress.preferencePrefix +
        Uri.encodeComponent(progress.profileId);
    expect(
      () => LocalBackupPolicy.validateLearningData({correctKey: encoded}),
      returnsNormally,
    );
    expect(
      () => LocalBackupPolicy.validateLearningData({
        '${TrailProgress.preferencePrefix}child-b': encoded,
      }),
      throwsFormatException,
    );
    expect(
      () => LocalBackupPolicy.validateLearningData({
        '${TrailProgress.preferencePrefix}child/a': encoded,
      }),
      throwsFormatException,
    );
  });

  test('a failed write reloads the cache before retrying the saved program',
      () async {
    final disk = _ControlledTrailStorage();
    SharedPreferencesStorePlatform.instance = disk;
    await store.savePlan(
      profileId: 'child-a',
      puzzle: puzzle,
      commands: [TrailDirection.right],
    );
    disk.reject = true;
    await expectLater(
      store.savePlan(
        profileId: 'child-a',
        puzzle: puzzle,
        commands: [TrailDirection.right, TrailDirection.up],
      ),
      throwsStateError,
    );
    expect((await store.load('child-a')).plans[puzzle.id],
        [TrailDirection.right]);
    disk.reject = false;
    await store.savePlan(
      profileId: 'child-a',
      puzzle: puzzle,
      commands: [TrailDirection.right, TrailDirection.up],
    );
    expect((await store.load('child-a')).plans[puzzle.id],
        [TrailDirection.right, TrailDirection.up]);
  });
}
