import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_discard_pile.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_draw_pile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/lumo_capture.dart';

Future<LumoAppState> _app({String? child}) async {
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  if (child != null) await app.school.setActiveStudent(child);
  await app.hydrateFromWallet();
  app.updateSettings(const AppSettings(
      voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
  return app;
}

Future<LumoCardsSessionRepository> _repo(LumoAppState app) async =>
    LumoCardsSessionRepository(
        studentId: (await app.captureLearningProfile()).studentId,
        grade: app.state.grade,
        vsBot: true);
Future<LumoCardsRound> _load(LumoCardsSessionRepository repo) async =>
    (await repo.load(player1Name: 'Du', player2Name: 'Lumo'))!;
Future<void> _open(WidgetTester tester, LumoAppState app,
    {int seed = 10}) async {
  await tester.pumpWidget(MaterialApp(
      home: LumoCardsScreen(appState: app, seed: seed, skipIntro: true)));
  await tester.pump();
  await tester.pump();
  expect(find.byType(LumoDrawPile), findsOneWidget);
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  app.dispose();
}

List<Object> _board(WidgetTester tester) => [
      tester.widget<LumoDiscardPile>(find.byType(LumoDiscardPile)).topCard.id,
      tester.widget<LumoDrawPile>(find.byType(LumoDrawPile)).cardsLeft,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets(
      'Real draw, background pause, new AppState and exact bot-turn continuation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final first = await _app();
    await _open(tester, first);
    final repo = await _repo(first);
    final initial = await _load(repo);
    await tester.tap(find.text('Ziehen'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final saved = await _load(repo);
    expect(saved.state.currentPlayerIndex, 1);
    expect(saved.state.players[0].hand.length,
        initial.state.players[0].hand.length + 1);
    expect(saved.state.drawPile.length, initial.state.drawPile.length - 1);
    final board = _board(tester);
    await _close(tester, first);
    final second = await _app();
    await _open(tester, second, seed: 999);
    expect(_board(tester), board);
    expect(find.text('Spiel pausiert'), findsOneWidget);
    final reloaded = await _load(await _repo(second));
    expect(reloaded.encode(repo.owner), saved.encode(repo.owner));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));
    expect(_board(tester), board);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump(const Duration(seconds: 2));
    expect((await _load(repo)).encode(repo.owner),
        isNot(saved.encode(repo.owner)));
    expect(tester.takeException(), isNull);
    await _close(tester, second);
  });

  testWidgets(
      'School profile switch never exposes or overwrites the other child round',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final a = await _app(child: 'school-A');
    await _open(tester, a);
    await tester.tap(find.text('Ziehen'));
    await tester.pump();
    final repoA = await _repo(a);
    final savedA = await _load(repoA);
    await _close(tester, a);
    final b = await _app(child: 'school-B');
    await _open(tester, b, seed: 90);
    final repoB = await _repo(b);
    final savedB = await _load(repoB);
    expect(savedB.id, isNot(savedA.id));
    expect(savedB.state.players[0].hand.length, 7);
    expect(find.text('Spiel pausiert'), findsNothing);
    expect(repoA.storageKey, isNot(repoB.storageKey));
    await _close(tester, b);
    final againA = await _app(child: 'school-A');
    await _open(tester, againA, seed: 555);
    expect(
        (await _load(repoA)).encode(repoA.owner), savedA.encode(repoA.owner));
    expect(
        (await _load(repoB)).encode(repoB.owner), savedB.encode(repoB.owner));
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, againA);
  });

  testWidgets(
      'Winning final card persists and reopening result cannot award twice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await _app();
    final repo = await _repo(app);
    final game = LumoCardsGameController(
        player1Name: 'Du', player2Name: 'Lumo', seed: 10, enableVoice: false);
    final original = game.snapshot();
    final all = [
      ...original.state.players.expand((p) => p.hand),
      ...original.state.drawPile,
      ...original.state.discardPile
    ];
    final top = all.firstWhere((c) => c.type == LumoCardType.number);
    final last = all.firstWhere((c) =>
        c.type == LumoCardType.number &&
        c.color == top.color &&
        c.id != top.id);
    final rest = all.where((c) => c.id != top.id && c.id != last.id).toList();
    final nearFinish = LumoCardsRound(
        id: original.id,
        state: original.state.copyWith(
            players: [
              original.state.players[0].copyWith(hand: [last]),
              original.state.players[1].copyWith(hand: rest.take(7).toList())
            ],
            drawPile: rest.skip(7).toList(),
            discardPile: [top],
            selectedColor: top.color),
        grade: original.grade,
        vsBot: original.vsBot,
        difficulty: original.difficulty,
        style: original.style);
    await repo.save(nearFinish);
    game.dispose();
    await _open(tester, app);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('hand-${last.id}')));
    await tester.pump();
    await app.flushRewards();
    expect((await _load(repo)).state.phase, GamePhase.gameOver);
    expect(app.state.stars, 3);
    expect(app.state.xp, 20);
    expect(app.lumoCardsWinStreak, 1);
    await _close(tester, app);
    final restarted = await _app();
    await _open(tester, restarted);
    await restarted.flushRewards();
    expect(restarted.state.stars, 3);
    expect(restarted.state.xp, 20);
    expect(restarted.lumoCardsWinStreak, 1);
    expect((await _load(repo)).id, original.id);
    expect(tester.takeException(), isNull);
    await _close(tester, restarted);
  });
}
