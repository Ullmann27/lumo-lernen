import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_bot_policy.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_table_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Mailbox implements CardsTableTransport {
  Map<String, Object?> state = {};
  Map<String, dynamic>? request;
  DateTime now = DateTime(2026, 11, 13);
  bool active = true;
  int pauseEpoch = 0;
  bool closed = false;
  @override
  Future<void> open(String token, Map<String, Object?> value) async {
    state = value;
  }

  @override
  Future<void> publish(String token, Map<String, Object?> value) async {
    state = value;
  }

  @override
  Future<Map<String, dynamic>> poll(String token) async => {
        'request': request,
        'lifecycle': {
          'active': active,
          'stamp': now.millisecondsSinceEpoch,
          'pauseEpoch': pauseEpoch
        },
      };
  @override
  Future<void> close(String token) async {
    closed = true;
  }

  void action(String kind, [Map<String, Object?> payload = const {}]) {
    request = {
      ...payload,
      'token': state['token'],
      'revision': state['revision'],
      'sequence': (state['ack'] as int) + 1,
      'action': kind
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });
  LumoCardsGameController game({int seed = 20}) {
    final value = LumoCardsGameController(
        player1Name: 'Du',
        player2Name: 'Lumo',
        seed: seed,
        vsBot: false,
        enableVoice: false);
    addTearDown(value.dispose);
    return value;
  }

  test('Public renderer view never contains hidden hands, deck order or answer',
      () {
    final controller = game();
    final view =
        cardsTableView(controller, token: 'a' * 32, revision: 1, ack: 0);
    final json = jsonEncode(view);
    for (final hidden in [
      ...controller.state.players[1].hand,
      ...controller.state.drawPile
    ]) {
      expect(json.contains('"${hidden.id}"'), isFalse);
    }
    expect(view.containsKey('drawPile'), isFalse);
    expect(json.contains('correctIndex'), isFalse);
    controller.drawCard();
    expect(controller.state.phase, GamePhase.passDevice);
    final hidden =
        cardsTableView(controller, token: 'a' * 32, revision: 2, ack: 0);
    expect(hidden['hand'], isEmpty);
  });

  test(
      'Native draw is saved then acknowledged once; duplicate cannot draw twice',
      () async {
    final controller = game();
    final mailbox = _Mailbox();
    final repo = LumoCardsSessionRepository(
        studentId: 'native-child', grade: 1, vsBot: false);
    final session = LumoCardsTableSession(
        controller: controller,
        transport: mailbox,
        canUseProfile: () => true,
        now: () => mailbox.now,
        persist: () => repo.save(controller.snapshot()));
    await session.open(automaticPolling: false);
    await session.pump();
    final before = controller.state.players[0].hand.length;
    mailbox.action('draw');
    await session.pump();
    expect(controller.state.players[0].hand.length, before + 1);
    expect(mailbox.state['ack'], 1);
    final saved = await repo.load(player1Name: 'Du', player2Name: 'Lumo');
    expect(saved!.state.players[0].hand.length, before + 1);
    await session.pump();
    expect(controller.state.players[0].hand.length, before + 1);
    await session.close();
    expect(mailbox.closed, isTrue);
  });

  test(
      'Stale revision, wrong nonce and foreign card IDs cannot change the round',
      () async {
    final controller = game();
    final mailbox = _Mailbox();
    final session = LumoCardsTableSession(
        controller: controller,
        transport: mailbox,
        canUseProfile: () => true,
        now: () => mailbox.now,
        persist: () async {});
    await session.open(automaticPolling: false);
    await session.pump();
    final original = controller.state;
    mailbox.action('draw');
    mailbox.request!['token'] = 'wrong';
    await session.pump();
    expect(controller.state, same(original));
    mailbox.action('draw');
    mailbox.request!['revision'] = -1;
    await session.pump();
    expect(controller.state, same(original));
    mailbox
        .action('play', {'cardId': controller.state.players[1].hand.first.id});
    await session.pump();
    expect(controller.state, same(original));
    // Even matching revision cannot operate on a state changed since publication.
    controller.drawCard();
    final changed = controller.state;
    mailbox.action('handover');
    await session.pump();
    expect(controller.state, same(changed));
    await session.close();
  });

  test(
      'Storage rejection holds acknowledgement and retries without reapplying action',
      () async {
    final controller = game();
    final mailbox = _Mailbox();
    var fail = false;
    final session = LumoCardsTableSession(
        controller: controller,
        transport: mailbox,
        canUseProfile: () => true,
        now: () => mailbox.now,
        persist: () async {
          if (fail) throw StateError('disk');
        });
    await session.open(automaticPolling: false);
    await session.pump();
    final before = controller.state.players[0].hand.length;
    fail = true;
    mailbox.action('draw');
    await session.pump();
    expect(controller.state.players[0].hand.length, before + 1);
    expect(mailbox.state['ack'], 0);
    expect(controller.turnClock.value, isTrue);
    fail = false;
    await session.pump();
    expect(mailbox.state['ack'], 1);
    expect(controller.state.players[0].hand.length, before + 1);
    await session.close();
  });

  test(
      'Native background, expired heartbeat and profile invalidation stop authority',
      () async {
    final controller = game();
    final mailbox = _Mailbox();
    var valid = true;
    var clock = mailbox.now;
    final session = LumoCardsTableSession(
        controller: controller,
        transport: mailbox,
        canUseProfile: () => valid,
        now: () => clock,
        persist: () async {});
    await session.open(automaticPolling: false);
    await session.pump();
    expect(controller.turnClock.value, isFalse);
    mailbox.active = false;
    await session.pump();
    expect(controller.turnClock.value, isTrue);
    mailbox.action('draw');
    final original = controller.state;
    await session.pump();
    expect(controller.state, same(original));
    mailbox.active = true;
    await session.pump();
    expect(controller.turnClock.value, isTrue);
    mailbox.action('resume');
    await session.pump();
    expect(controller.turnClock.value, isFalse);
    clock = clock.add(const Duration(seconds: 4));
    await session.pump();
    expect(controller.turnClock.value, isTrue);
    valid = false;
    await session.pump();
    expect(mailbox.closed, isTrue);
    expect(controller.state, same(original));
  });

  test(
      'Revoked parent daily-mission gate closes native authority without a move',
      () async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    addTearDown(app.dispose);
    final owner = await app.captureLearningProfile();
    await app.prepareLearningLease(owner);
    final controller = game();
    final mailbox = _Mailbox();
    final session = LumoCardsTableSession(
        controller: controller,
        transport: mailbox,
        canUseProfile: () =>
            app.isCurrentLearningLease(owner) && app.canPlayToday,
        now: () => mailbox.now,
        persist: () async {});
    await session.open(automaticPolling: false);
    await session.pump();
    mailbox.action('draw');
    final original = controller.state;
    app.updateSettings(const AppSettings(
        requireDailyMissionForGames: true,
        voiceEnabled: false,
        soundEnabled: false));
    expect(app.canPlayToday, isFalse);
    await session.pump();
    expect(mailbox.closed, isTrue);
    expect(controller.turnClock.value, isTrue);
    expect(controller.state, same(original));
  });

  test('Missed Android pause remains sticky after Dart is scheduled again',
      () async {
    final controller = game();
    final mailbox = _Mailbox();
    final session = LumoCardsTableSession(
        controller: controller,
        transport: mailbox,
        canUseProfile: () => true,
        now: () => mailbox.now,
        persist: () async {});
    await session.open(automaticPolling: false);
    await session.pump();
    expect(controller.turnClock.value, isFalse);
    // Android onPause then onResume occurred while Dart had no execution time.
    // The latest active heartbeat still carries the monotonic pause epoch.
    mailbox.pauseEpoch++;
    mailbox.action('draw');
    final before = controller.state;
    await session.pump();
    expect(controller.turnClock.value, isTrue);
    expect(controller.state, same(before));
    mailbox.action('resume');
    await session.pump();
    expect(controller.turnClock.value, isFalse);
    mailbox.action('draw');
    await session.pump();
    expect(controller.state.players[0].hand.length,
        before.players[0].hand.length + 1);
    await session.close();
  });

  test(
      'Twelve complete rounds through the native protocol preserve all 112 cards and every phase',
      () async {
    final phases = <GamePhase>{};
    for (var seed = 0; seed < 12; seed++) {
      final controller = game(seed: seed);
      final mailbox = _Mailbox();
      final repo = LumoCardsSessionRepository(
          studentId: 'full-$seed', grade: 1, vsBot: false);
      final session = LumoCardsTableSession(
          controller: controller,
          transport: mailbox,
          canUseProfile: () => true,
          now: () => mailbox.now,
          persist: () => repo.save(controller.snapshot()));
      await session.open(automaticPolling: false);
      await session.pump();
      var moves = 0;
      while (moves++ < 900) {
        final state = controller.state;
        phases.add(state.phase);
        final all = [
          ...state.drawPile,
          ...state.discardPile,
          for (final player in state.players) ...player.hand
        ];
        expect(all.length, 112);
        expect(all.map((c) => c.id).toSet().length, 112);
        if (state.phase == GamePhase.gameOver) break;
        switch (state.phase) {
          case GamePhase.playing:
            final choice = LumoCardsBotPolicy.select(
                ownHand: state.currentPlayer.hand,
                grade: 1,
                topCard: state.topCard!,
                selectedColor: state.selectedColor,
                opponentCardCount: state.otherPlayer.hand.length,
                difficulty: LumoCardsDifficulty.expert,
                style: LumoCardsStyle.planner,
                rng: Random(moves));
            mailbox.action(choice == null ? 'draw' : 'play',
                choice == null ? {} : {'cardId': choice.id});
          case GamePhase.chooseColor:
            mailbox.action('color', {'color': 'blue'});
          case GamePhase.learningQuestion:
            final visible = mailbox.state['question'] as Map;
            expect(visible.containsKey('correctIndex'), isFalse);
            mailbox.action('answer',
                {'index': state.pendingLearningQuestion!.correctIndex});
          case GamePhase.passDevice:
            expect(mailbox.state['hand'], isEmpty);
            mailbox.action('handover');
          case GamePhase.gameOver:
            break;
        }
        await session.pump();
        final restored =
            await repo.load(player1Name: 'Du', player2Name: 'Lumo');
        expect(restored!.encode(repo.owner),
            controller.snapshot().encode(repo.owner));
      }
      expect(controller.state.phase, GamePhase.gameOver,
          reason: 'seed $seed moves $moves');
      await session.close();
    }
    expect(phases, containsAll(GamePhase.values));
  });
}
