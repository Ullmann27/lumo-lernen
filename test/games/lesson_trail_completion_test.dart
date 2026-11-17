import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/mini_games/lesson_trail_game.dart';
import '../helpers/mini_game_learning.dart';

class _WalletFailureStore extends InMemorySharedPreferencesStore {
  _WalletFailureStore()
      : super.withData({
          'flutter.lumo_reward_wallet_v1':
              jsonEncode(const RewardWallet().toJson()),
        });
  final snapshots = <Map<String, dynamic>>[];
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.lumo_reward_wallet_v1') {
      snapshots.add(jsonDecode(value as String) as Map<String, dynamic>);
      if (snapshots.length == 1) return false;
    }
    return super.setValue(type, key, value);
  }

  Future<Map<String, dynamic>> persisted() async =>
      jsonDecode((await getAll())['flutter.lumo_reward_wallet_v1'] as String)
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A full lesson retries a failed combined reward exactly once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _WalletFailureStore();
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    final app = LumoAppState(walletRepository: wallet);
    addTearDown(app.dispose);
    await tester.binding.setSurfaceSize(const Size(840, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final level = GameLevelCatalog.byId(10)!;
    await tester.pumpWidget(
        MaterialApp(home: LessonTrailGame(appState: app, level: level)));
    await settleMiniGame(tester);
    for (var i = 0; i < 5; i++) {
      expect(find.text('Aufgabe ${i + 1} / 5'), findsOneWidget);
      final round = await savedMiniGameRound(level);
      expect(round.index, i);
      await selectMiniGameAnswer(tester, round);
      await tapMiniGameKey(tester, 'mini-game-check');
      expect((await savedMiniGameRound(level)).response.solved(round.task),
          isTrue);
      expect(find.text(round.task.explanation), findsOneWidget);
      expect(app.state.stars, 0);
      await tapMiniGameKey(tester, 'mini-game-check');
    }
    expect(find.byKey(const ValueKey('mini-game-save-error')), findsOneWidget);
    expect(find.text('Geschafft!'), findsNothing);
    final pending = await savedMiniGameRound(level);
    expect(pending.finishRequested, isTrue);
    expect(pending.rewarded, isFalse);
    expect((await store.persisted())['stars'], 0);
    expect((await store.persisted())['xp'], 0);
    expect(app.hasPendingRewards, isTrue);
    expect((await const GameProgressRepository().loadStars('local_lena_1'))[10],
        3);
    expect(store.snapshots, hasLength(1));
    await tapMiniGameKey(tester, 'mini-game-save-retry');
    expect(find.text('Geschafft!'), findsOneWidget);
    expect((await savedMiniGameRound(level)).rewarded, isTrue);
    final saved = await store.persisted();
    expect(saved['stars'], 3);
    expect(saved['xp'], 40);
    expect(app.hasPendingRewards, isFalse);
    expect(store.snapshots, hasLength(2));
    for (final snapshot in store.snapshots) {
      expect(snapshot['stars'], 3);
      expect(snapshot['xp'], 40);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await settleMiniGame(tester);
  });
}
