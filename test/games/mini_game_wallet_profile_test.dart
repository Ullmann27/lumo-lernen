import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';

const _initial = RewardWallet(stars: 7, xp: 40, totalEarnedStars: 19,
    streak: 3, lumoCardsWinStreak: 2);

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.withData({
    'flutter.lumo_reward_wallet_v1': jsonEncode(_initial.toJson()),
  });
  bool failNext = false;
  Completer<void>? entered, release;
  void hold() { entered = Completer<void>(); release = Completer<void>(); }
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.lumo_reward_wallet_v1') {
      if (entered != null && !entered!.isCompleted) {
        entered!.complete(); await release!.future;
      }
      if (failNext) { failNext = false; return false; }
    }
    return super.setValue(valueType, key, value);
  }
  Future<RewardWallet> disk() async => RewardWallet.fromJson(
      jsonDecode((await getAll())['flutter.lumo_reward_wallet_v1'] as String)
        as Map<String, dynamic>);
}

String _id(LearningProfileLease lease, int sequence) =>
    'mini:${sha256.convert(utf8.encode(lease.studentId))}:'
    '${sequence.toRadixString(16).padLeft(32, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Store store;
  late LumoAppState app;
  late LearningProfileLease lease;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.school.setActiveStudent('mini-child-a');
    lease = await app.captureLearningProfile();
  });
  tearDown(() {
    if (store.release != null && !store.release!.isCompleted) store.release!.complete();
    app.dispose();
  });

  Future<void> award({int level = 1, int stars = 3, int xp = 40, int sequence = 1,
    String? id, LearningProfileLease? owner}) => app.recordMiniGameResult(
      lease: owner ?? lease, resultId: id ?? _id(owner ?? lease, sequence),
      levelId: level, stars: stars, xp: xp);

  test('same result ID twice persists exactly once and leaves school results alone', () async {
    await award(); await award();
    final wallet = await store.disk();
    expect(wallet.stars, 10); expect(wallet.xp, 80);
    expect(wallet.gameResultIds, [_id(lease, 1)]);
    expect(wallet.totalEarnedStars, 22);
    expect(wallet.streak, 3); expect(wallet.lumoCardsWinStreak, 2);
    expect(app.learningSkills(), isEmpty);
  });

  test('every completed mini-game uses its existing exact reward amounts', () async {
    const amounts = <(int, int, int)>[
      (1, 1, 40), (1, 2, 40), (1, 3, 40), (7, 3, 40),
      (2, 5, 25), (25, 1, 0), (25, 1, 8), (25, 2, 16),
      (25, 3, 24), (25, 3, 32), (25, 4, 40), (25, 5, 48),
      (13, 1, 80), (13, 3, 80), (23, 2, 40), (35, 3, 40),
    ];
    var stars = 7, xp = 40, sequence = 10;
    for (final amount in amounts) {
      await award(level: amount.$1, stars: amount.$2, xp: amount.$3,
        sequence: sequence++);
      stars += amount.$2; xp += amount.$3;
      final wallet = await store.disk();
      expect(wallet.stars, stars); expect(wallet.xp, xp);
    }
    expect(app.learningSkills(), isEmpty);
  });

  test('unknown levels, QuizShow route and invented amounts are rejected', () async {
    for (final invalid in <(int, int, int)>[
      (50, 3, 40), (999, 3, 40), (1, 5, 40), (7, 3, 48),
      (2, 3, 25), (2, 5, 40), (25, 5, 40), (25, 3, 23),
      (13, 3, 40), (23, 3, 80), (35, -1, 40),
    ]) {
      await expectLater(award(level: invalid.$1, stars: invalid.$2, xp: invalid.$3), throwsStateError);
    }
    expect((await store.disk()).toJson(), _initial.toJson());
    expect(app.hasPendingRewards, isFalse);
  });

  test('foreign owner or different game identity cannot claim a mini-game reward', () async {
    final other = sha256.convert(utf8.encode('mini-child-b'));
    for (final invalid in ['mini:$other:${'a' * 32}',
      _id(lease, 1).replaceFirst('mini:', 'memory:'), 'mini:bad', '${_id(lease, 1)}:extra']) {
      await expectLater(award(id: invalid), throwsStateError);
    }
    expect((await store.disk()).toJson(), _initial.toJson());
  });

  test('false wallet acknowledgement retries the same ID without double pay', () async {
    store.failNext = true;
    await expectLater(award(), throwsStateError);
    expect((await store.disk()).toJson(), _initial.toJson());
    expect(app.hasPendingRewards, isTrue);
    await award();
    final saved = await store.disk();
    expect(saved.stars, 10); expect(saved.xp, 80);
    expect(saved.gameResultIds, [_id(lease, 1)]);
    expect(app.hasPendingRewards, isFalse);
    expect(app.rewardSaveError, isNull);
  });

  test('profile switch before request rejects the old lease without a write', () async {
    await app.school.setActiveStudent('mini-child-b');
    await expectLater(award(), throwsStateError);
    expect((await store.disk()).toJson(), _initial.toJson());
    expect(app.hasPendingRewards, isFalse);
  });

  test('profile is checked again after waiting behind an earlier reward', () async {
    store.hold();
    final older = app.recordLumoCardsBonus(resultId: 'existing-cards');
    await store.entered!.future;
    final rejected = expectLater(award(), throwsStateError);
    await app.school.setActiveStudent('mini-child-b');
    store.release!.complete();
    await older; await rejected;
    final saved = await store.disk();
    expect(saved.stars, 8); expect(saved.xp, 40);
    expect(saved.gameResultIds, ['existing-cards']);
  });

  test('switch during committed write keeps original receipt but denies stale UI success', () async {
    store.hold();
    final rejected = expectLater(award(), throwsStateError);
    await store.entered!.future;
    await app.school.setActiveStudent('mini-child-b');
    store.release!.complete();
    await rejected;
    final original = await store.disk();
    expect(original.stars, 10); expect(original.gameResultIds, [_id(lease, 1)]);
    await expectLater(award(), throwsStateError);
    await app.school.setActiveStudent('mini-child-a');
    final current = await app.captureLearningProfile();
    await award(owner: current);
    expect((await store.disk()).stars, 10);
    expect((await store.disk()).gameResultIds, [_id(current, 1)]);
  });
}
