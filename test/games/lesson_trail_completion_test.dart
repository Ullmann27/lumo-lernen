import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_lesson_tasks.dart';
import 'package:lumo_lernen/features/games/mini_games/lesson_trail_game.dart';

class _WalletFailureStore extends InMemorySharedPreferencesStore {
  _WalletFailureStore() : super.withData({
    'flutter.lumo_reward_wallet_v1': jsonEncode(const RewardWallet().toJson()),
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
  Future<Map<String, dynamic>> persisted() async => jsonDecode(
    (await getAll())['flutter.lumo_reward_wallet_v1'] as String) as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A full lesson retries a failed combined reward exactly once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _WalletFailureStore();
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    final app = LumoAppState(walletRepository: wallet);
    addTearDown(app.dispose);
    const voice = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(voice, (_) async => 1);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(voice, null));
    await tester.binding.setSurfaceSize(const Size(840, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final level = GameLevelCatalog.byId(10)!;
    await tester.pumpWidget(MaterialApp(home: LessonTrailGame(appState: app, level: level)));
    for (var i = 0; i < 5; i++) {
      expect(find.text('${i + 1} / 5'), findsOneWidget);
      final answer = find.byKey(ValueKey('lesson-answer-${GameLessonTasks.task(level, i).answer}'));
      await tester.ensureVisible(answer);
      await tester.pump();
      await tester.tap(answer);
      await tester.pump();
      expect(find.text(GameLessonTasks.task(level, i).explanation), findsOneWidget);
      final next = find.text(i == 4 ? 'Ergebnis speichern' : 'Weiter auf dem Weg');
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('noch nicht vollständig gespeichert'), findsOneWidget);
    expect(find.textContaining('Geschafft!'), findsNothing);
    expect((await store.persisted())['stars'], 0);
    expect((await store.persisted())['xp'], 0);
    expect(app.hasPendingRewards, isTrue);
    expect((await const GameProgressRepository().loadStars('local_lena_1'))[10], 3);
    await tester.ensureVisible(find.text('Ergebnis speichern'));
    await tester.pump();
    await tester.tap(find.text('Ergebnis speichern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Geschafft! 3 Sterne'), findsOneWidget);
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
  });
}
