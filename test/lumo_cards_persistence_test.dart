import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_bot_policy.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

LumoCardsGameController _controller({bool vsBot = false, int seed = 20}) =>
    LumoCardsGameController(
        player1Name: 'Du',
        player2Name: 'Lumo',
        vsBot: vsBot,
        enableVoice: false,
        seed: seed,
        difficulty: LumoCardsDifficulty.expert,
        style: LumoCardsStyle.collector);

LumoCardsSessionRepository _repository(String child,
        {int grade = 1, bool vsBot = false}) =>
    LumoCardsSessionRepository(studentId: child, grade: grade, vsBot: vsBot);
Future<LumoCardsRound?> _load(LumoCardsSessionRepository repo) =>
    repo.load(player1Name: 'Neuer Anzeigename', player2Name: 'Lumo');

class _RejectingStore extends InMemorySharedPreferencesStore {
  _RejectingStore() : super.withData({});
  bool reject = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (reject) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  test(
      'Complete real round survives every phase, deck order and pending question',
      () async {
    final phases = <GamePhase>{};
    for (var seed = 0; seed < 12; seed++) {
      final game = _controller(seed: seed);
      addTearDown(game.dispose);
      final repo = _repository('school-child-A');
      var turns = 0;
      while (turns++ < 800) {
        final original = game.snapshot();
        phases.add(original.state.phase);
        await repo.save(original);
        final restored = await _load(_repository('school-child-A'));
        expect(restored, isNotNull);
        expect(restored!.encode(repo.owner), original.encode(repo.owner));
        expect(restored.state.players[0].name, 'Neuer Anzeigename');
        if (restored.state.phase == GamePhase.learningQuestion) {
          final invalid = jsonDecode(jsonEncode(restored.encode(repo.owner)))
              as Map<String, dynamic>;
          (invalid['question'] as Map)['correct'] = 99;
          expect(
              LumoCardsRound.decode(jsonEncode(invalid),
                  owner: repo.owner,
                  grade: 1,
                  vsBot: false,
                  player1Name: 'Du',
                  player2Name: 'Lumo'),
              isNull);
        }
        game.restoreRound(restored);
        expect(game.turnClock.value, isTrue);
        game.turnClock.resume();
        final s = game.state;
        if (s.phase == GamePhase.gameOver) break;
        switch (s.phase) {
          case GamePhase.playing:
            final decision = LumoCardsBotPolicy.select(
                ownHand: s.currentPlayer.hand,
                grade: 1,
                topCard: s.topCard!,
                selectedColor: s.selectedColor,
                opponentCardCount: s.otherPlayer.hand.length,
                difficulty: LumoCardsDifficulty.expert,
                style: LumoCardsStyle.planner,
                rng: Random(turns));
            if (decision == null) {
              game.drawCard();
            } else {
              game.playCard(decision);
            }
          case GamePhase.chooseColor:
            game.selectColor(LumoCardColor.blue);
          case GamePhase.learningQuestion:
            game.answerLearningQuestion(
                s.pendingLearningQuestion!.correctIndex);
          case GamePhase.passDevice:
            game.confirmHandover();
          case GamePhase.gameOver:
            break;
        }
      }
      expect(game.state.phase, GamePhase.gameOver);
    }
    expect(
        phases,
        containsAll([
          GamePhase.playing,
          GamePhase.passDevice,
          GamePhase.chooseColor,
          GamePhase.learningQuestion,
          GamePhase.gameOver
        ]));
  });

  test(
      'Unknown schema, lost/duplicate cards and inconsistent phases fall back safely',
      () async {
    final game = _controller();
    addTearDown(game.dispose);
    final repo = _repository('child-A');
    final cases = <void Function(Map<String, dynamic>)>[
      (j) => j['version'] = 99,
      (j) => j['deckVersion'] = 2,
      (j) => j['owner'] = 'another-child',
      (j) => j['grade'] = 4,
      (j) => j['vsBot'] = true,
      (j) => j['id'] = 'invalid',
      (j) => (j['draw'] as List).removeLast(),
      (j) => (j['draw'] as List)[0] = (j['draw'] as List)[1],
      (j) => (j['draw'] as List)[0] = 'nonexistent',
      (j) => j['phase'] = 'unknown',
      (j) => j['phase'] = 'gameOver',
      (j) => j['phase'] = 'learningQuestion',
      (j) => j['phase'] = 'chooseColor',
      (j) => j['current'] = 2,
      (j) => j['direction'] = 0,
      (j) => j['rewardedLearningStars'] = 50,
      (j) => j['callRewardSettled'] = true,
      (j) => j['winner'] = 0,
    ];
    final prefs = await SharedPreferences.getInstance();
    for (final corrupt in cases) {
      final j = jsonDecode(jsonEncode(game.snapshot().encode(repo.owner)))
          as Map<String, dynamic>;
      corrupt(j);
      await prefs.setString(repo.storageKey, jsonEncode(j));
      expect(await _load(repo), isNull, reason: '$j');
    }
    await prefs.setString(repo.storageKey, '{broken');
    expect(await _load(repo), isNull);
    await prefs.setString(repo.storageKey, 'x' * 65537);
    expect(await _load(repo), isNull);
    await prefs.setInt(repo.storageKey, 17);
    expect(await _load(repo), isNull);
  });

  test('School children, local child, grade and solo mode have separate slots',
      () async {
    final game = _controller();
    addTearDown(game.dispose);
    await _repository('school-A').save(game.snapshot());
    for (final repo in [
      _repository('school-B'),
      _repository('local-uuid'),
      _repository('school-A', grade: 2),
      _repository('school-A', vsBot: true)
    ]) {
      expect(await _load(repo), isNull);
    }
    final a = await _load(_repository('school-A'));
    expect(a!.id, game.roundId);
    final raw = (await SharedPreferences.getInstance())
        .getString(_repository('school-A').storageKey)!;
    expect(raw, isNot(contains('school-A')));
    expect(raw, isNot(contains('Neuer Anzeigename')));
  });

  test('Failed saves leave last durable deck intact and retry exactly once',
      () async {
    final store = _RejectingStore();
    SharedPreferencesStorePlatform.instance = store;
    final game = _controller();
    addTearDown(game.dispose);
    final repo = _repository('child');
    await repo.save(game.snapshot());
    final before = (await _load(repo))!.encode(repo.owner);
    game.drawCard();
    store.reject = true;
    await expectLater(repo.save(game.snapshot()), throwsStateError);
    expect((await _load(repo))!.encode(repo.owner), before);
    store.reject = false;
    await repo.save(game.snapshot());
    expect((await _load(repo))!.encode(repo.owner),
        game.snapshot().encode(repo.owner));
    game.restart();
    await repo.save(game.snapshot(), canWrite: () => false);
    expect((await _load(repo))!.id, isNot(game.roundId));
  });

  testWidgets(
      'Restored bot waits for explicit resume and keeps strategy and deck',
      (tester) async {
    final first = _controller(vsBot: true);
    first.drawCard();
    final saved = first.snapshot();
    first.dispose();
    final fresh = _controller(vsBot: true, seed: 999);
    addTearDown(fresh.dispose);
    fresh.restoreRound(saved);
    expect(fresh.snapshot().encode('test'), saved.encode('test'));
    expect(fresh.turnClock.value, isTrue);
    await tester.pump(const Duration(seconds: 10));
    expect(fresh.state, same(saved.state));
    fresh.turnClock.resume();
    await tester.pump(const Duration(seconds: 2));
    expect(fresh.state, isNot(same(saved.state)));
    fresh.restart();
    expect(fresh.roundId, isNot(saved.id));
  });

  test(
      'Completed round and learning/call bonuses never reward twice after restart',
      () async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.recordLumoCardsResult(won: true, resultId: 'cards-round-A');
    await app.recordLumoCardsBonus(resultId: 'cards-round-A:question-1');
    await app.recordLumoCardsBonus(resultId: 'cards-round-A:call');
    expect(app.state.stars, 5);
    expect(app.state.xp, 20);
    app.dispose();
    final restarted = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(restarted.dispose);
    await restarted.hydrateFromWallet();
    await restarted.recordLumoCardsResult(won: true, resultId: 'cards-round-A');
    await restarted.recordLumoCardsBonus(resultId: 'cards-round-A:question-1');
    await restarted.recordLumoCardsBonus(resultId: 'cards-round-A:call');
    expect(restarted.state.stars, 5);
    expect(restarted.state.xp, 20);
    expect(restarted.lumoCardsWinStreak, 1);
    await restarted.recordLumoCardsResult(won: true, resultId: 'cards-round-B');
    expect(restarted.state.stars, 9);
    expect(restarted.lumoCardsWinStreak, 2);
  });
  test('Failed idempotent Cards award retries without increasing streak twice',
      () async {
    final store = _RejectingStore();
    SharedPreferencesStorePlatform.instance = store;
    final wallet = RewardWalletRepository();
    await wallet.load();
    final app = LumoAppState(walletRepository: wallet);
    addTearDown(app.dispose);
    store.reject = true;
    await expectLater(
        app.recordLumoCardsResult(won: true, resultId: 'cards-retry'),
        throwsStateError);
    expect(app.lumoCardsWinStreak, 0);
    expect(wallet.snapshot.gameResultIds, isEmpty);
    store.reject = false;
    await app.retryRewards();
    expect(app.lumoCardsWinStreak, 1);
    expect(app.state.stars, 3);
    final restart = RewardWalletRepository();
    await restart.awardLumoCardsResult(won: true, resultId: 'cards-retry');
    expect(restart.snapshot.lumoCardsWinStreak, 1);
    expect(restart.snapshot.stars, 3);
    expect(restart.snapshot.xp, 20);
  });
}
