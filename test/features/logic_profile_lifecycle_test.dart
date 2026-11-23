import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/logic/logic_games.dart';
import 'package:lumo_lernen/domain/logic/logic_learning_profile.dart';
import 'package:lumo_lernen/features/games/logic/logic_progress_store.dart';

class _ControlledLogicStorage extends InMemorySharedPreferencesStore {
  _ControlledLogicStorage() : super.withData({});
  bool hold = false;
  bool reject = false;
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.startsWith('flutter.${LogicProgress.preferencePrefix}')) {
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
  const store = LogicProgressStore();
  final puzzle = LogicCatalog.puzzle(LogicGameKind.sudoku, 1, 1);

  Future<LogicPuzzleSession> start(String child) => store.begin(
        profileId: child,
        puzzle: puzzle,
        sessionId: 'visit',
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() async {
    await LogicProgressStore.flushPendingWrites();
    SharedPreferences.setMockInitialValues({});
  });

  test('resetting one learning profile preserves the other child puzzle',
      () async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(app.dispose);
    await start('child-a');
    final b = (await start('child-b')).copyWith(hints: 1);
    await store.saveSession('child-b', b);
    await app.school.setActiveStudent('child-a');
    await app.loadLearningProfile();
    await app.resetLearningProfile();
    expect((await store.load('child-a')).drafts, isEmpty);
    expect((await store.load('child-b')).drafts[puzzle.id]!.hints, 1);
    expect((await app.captureLearningProfile()).studentId, 'child-a');
  });

  test('backup waits for accepted logic writes before reading the snapshot',
      () async {
    final disk = _ControlledLogicStorage();
    SharedPreferencesStorePlatform.instance = disk;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(() {
      if (!disk.release.isCompleted) disk.release.complete();
      app.dispose();
    });
    final session = (await start('child-a')).copyWith(hints: 2);
    disk.hold = true;
    final pendingWrite = store.saveSession('child-a', session);
    await disk.entered.future;
    var read = false;
    final backup = app.withBackupStoragePaused(() async {
      read = true;
      expect(app.resetting, isTrue);
      final prefs = await SharedPreferences.getInstance();
      final saved = LogicProgress.fromJson(jsonDecode(
          prefs.getString('${LogicProgress.preferencePrefix}child-a')!));
      expect(saved.drafts[puzzle.id]!.hints, 2);
    });
    await Future<void>.delayed(Duration.zero);
    expect(read, isFalse);
    disk.release.complete();
    await Future.wait([pendingWrite, backup]);
    expect(read, isTrue);
  });

  test('full reset drains logic writes so they cannot reappear afterwards',
      () async {
    final disk = _ControlledLogicStorage();
    SharedPreferencesStorePlatform.instance = disk;
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(() {
      if (!disk.release.isCompleted) disk.release.complete();
      app.dispose();
    });
    final session = (await start('child-a')).copyWith(hints: 1);
    disk.hold = true;
    final pendingWrite = store.saveSession('child-a', session);
    await disk.entered.future;
    final reset = app.resetAllProfile();
    await Future<void>.delayed(Duration.zero);
    disk.release.complete();
    await Future.wait([pendingWrite, reset]);
    final saved = await disk.getAll();
    expect(
        saved.keys.any((key) => key.contains(LogicProgress.preferencePrefix)),
        isFalse);
  });

  test('failed writes reload the plugin cache before retrying a puzzle',
      () async {
    final disk = _ControlledLogicStorage();
    SharedPreferencesStorePlatform.instance = disk;
    final session = await start('child-a');
    disk.reject = true;
    final hinted = session.copyWith(hints: 1);
    await expectLater(store.saveSession('child-a', hinted), throwsStateError);
    expect((await store.load('child-a')).drafts[puzzle.id]!.hints, 0);
    disk.reject = false;
    await store.saveSession('child-a', hinted);
    expect((await store.load('child-a')).drafts[puzzle.id]!.hints, 1);
  });
}
