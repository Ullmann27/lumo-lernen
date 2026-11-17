import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_cup.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_cup_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_showcase_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_draw_pile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/lumo_capture.dart';

Future<LumoAppState> _app() async {
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  await app.hydrateFromWallet();
  app.updateSettings(const AppSettings(
      voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
  return app;
}

Future<void> _openCup(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('cards-cup-capture'),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LumoAppTheme.light(),
          home: LumoCardsCupScreen(appState: app))));
  await tester.pump();
  await tester.pump();
}

// A legal final-card position containing exactly the original 112 cards.
Future<String> _nearFinish(LumoCardsSessionRepository repo, int leg) async {
  final rival = LumoCardsCup.opponents[leg];
  final game = LumoCardsGameController(
      player1Name: 'Du',
      player2Name: 'Lumo',
      seed: 19 + leg,
      enableVoice: false,
      difficulty: rival.difficulty,
      style: rival.style);
  final initial = game.snapshot();
  final all = [
    ...initial.state.players.expand((p) => p.hand),
    ...initial.state.drawPile,
    ...initial.state.discardPile
  ];
  final top = all.firstWhere((c) => c.type == LumoCardType.number);
  final last = all.firstWhere((c) =>
      c.type == LumoCardType.number && c.color == top.color && c.id != top.id);
  final rest = all.where((c) => c.id != top.id && c.id != last.id).toList();
  await repo.save(LumoCardsRound(
      id: initial.id,
      state: initial.state.copyWith(
          players: [
            initial.state.players[0].copyWith(hand: [last]),
            initial.state.players[1].copyWith(hand: rest.take(7).toList())
          ],
          drawPile: rest.skip(7).toList(),
          discardPile: [top],
          selectedColor: top.color),
      grade: initial.grade,
      vsBot: true,
      difficulty: rival.difficulty,
      style: rival.style));
  game.dispose();
  return last.id;
}

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
      'Cup completes three real final-card inputs, reopens progress and awards once',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var app = await _app();
    final owner = (await app.captureLearningProfile()).studentId;
    final repo = LumoCardsCupRepository(studentId: owner, grade: 1);
    final classic =
        LumoCardsSessionRepository(studentId: owner, grade: 1, vsBot: true);
    final classicGame = LumoCardsGameController(
        player1Name: 'Du', player2Name: 'Lumo', seed: 77, enableVoice: false);
    await classic.save(classicGame.snapshot());
    classicGame.dispose();
    final prefs = await SharedPreferences.getInstance();
    final classicBefore = prefs.getString(classic.storageKey);
    await _openCup(tester, app);
    final cup = await repo.load(canWrite: () => true);
    for (var leg = 0; leg < 3; leg++) {
      final session = LumoCardsSessionRepository(
          studentId: owner, grade: 1, vsBot: true, slot: 'cup-${cup.id}-$leg');
      final last = await _nearFinish(session, leg);
      await tester.ensureVisible(find.text('Runde ${leg + 1} spielen'));
      await tester.tap(find.text('Runde ${leg + 1} spielen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LumoCardsScreen), findsOneWidget);
      expect(find.byTooltip('Lumos Spielstärke'), findsNothing);
      expect(find.text('Spiel pausiert'), findsOneWidget);
      await tester.tap(find.text('Fortsetzen'));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('hand-$last')));
      await tester.pump();
      await app.flushRewards();
      await tester.pump(const Duration(milliseconds: 400));
      final saved = await session.load(player1Name: 'Du', player2Name: 'Lumo');
      expect(saved!.state.phase, GamePhase.gameOver);
      expect(saved.difficulty, LumoCardsCup.opponents[leg].difficulty);
      expect(saved.style, LumoCardsCup.opponents[leg].style);
      expect((await repo.load(canWrite: () => true)).results.length, leg + 1);
      await tester.tap(find.text('Zum Pokal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LumoCardsScreen), findsNothing);
      // New app lifecycle reloads durable cup, no UI-only progression.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app.dispose();
      app = await _app();
      await _openCup(tester, app);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Goldpokal'), findsOneWidget);
    final capture = Platform.environment['LUMO_CARDS_CUP_CAPTURE'];
    if (capture != null) {
      await captureLumoBoundary(
          tester, const ValueKey('cards-cup-capture'), capture,
          pixelRatio: 1.5);
    }
    expect(app.state.stars, 12);
    expect(app.state.xp, 20 + 25 + 30);
    expect(app.lumoCardsWinStreak, 3);
    expect(prefs.getString(classic.storageKey), classicBefore);
    expect((await repo.load(canWrite: () => true)).id, cup.id);
    await tester.ensureVisible(find.text('Neuer Sternenpokal'));
    await tester.tap(find.text('Neuer Sternenpokal'));
    await tester.pump();
    expect(find.text('Runde 1 spielen'), findsOneWidget);
    expect(app.state.stars, 12);
    expect((await repo.load(canWrite: () => true)).id, isNot(cup.id));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
  });

  testWidgets('Incomplete cup round resumes exact draw and hand after return',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await _app();
    addTearDown(app.dispose);
    await _openCup(tester, app);
    await tester.tap(find.text('Runde 1 spielen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Ziehen'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final owner = (await app.captureLearningProfile()).studentId;
    final cup = await LumoCardsCupRepository(studentId: owner, grade: 1)
        .load(canWrite: () => true);
    final repo = LumoCardsSessionRepository(
        studentId: owner, grade: 1, vsBot: true, slot: 'cup-${cup.id}-0');
    final saved = await repo.load(player1Name: 'Du', player2Name: 'Lumo');
    expect(saved!.state.players[0].hand.length, 8);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _openCup(tester, app);
    await tester.tap(find.text('Runde 1 spielen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(
        (await repo.load(player1Name: 'Du', player2Name: 'Lumo'))!
            .encode(repo.owner),
        saved.encode(repo.owner));
    expect(tester.widget<LumoDrawPile>(find.byType(LumoDrawPile)).cardsLeft,
        saved.state.drawPile.length);
    expect(cup.results, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Current profile change hides old Cards hand and cup progression',
      (tester) async {
    final app = await _app();
    addTearDown(app.dispose);
    await tester.pumpWidget(
        MaterialApp(home: LumoCardsScreen(appState: app, skipIntro: true)));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LumoDrawPile), findsOneWidget);
    final old = await app.captureLearningProfile();
    await app.school.setActiveStudent('other-child');
    await tester.pump();
    expect(app.canUseLearningLease(old), isTrue,
        reason: 'Old queued persistence remains safe');
    expect(app.isCurrentLearningLease(old), isFalse);
    expect(find.byType(LumoDrawPile), findsNothing);
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _openCup(tester, app);
    await app.school.setActiveStudent('third-child');
    await tester.pump();
    expect(find.text('Runde 1 spielen'), findsNothing);
    expect(find.textContaining('Das Kinderprofil hat gewechselt.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final size in [
    const Size(360, 640),
    const Size(640, 360),
    const Size(840, 400)
  ]) {
    testWidgets('Every Cards mode remains reachable with 48dp target at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var selected = '';
      await tester.pumpWidget(MaterialApp(
          home: LumoCardsShowcaseScreen(
              onSolo: () => selected = 'solo',
              onLocal: () => selected = 'local',
              onCup: () => selected = 'cup')));
      await tester.pump();
      for (final mode in ['solo', 'local', 'cup']) {
        final target = find.byKey(ValueKey('cards-hub-$mode'));
        final rect = tester.getRect(target);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect((Offset.zero & size).contains(rect.topLeft), isTrue);
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        await tester.tap(target);
        expect(selected, mode);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
