import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_math_tasks.dart';
import 'package:lumo_lernen/features/games/mini_games/stars_path_game.dart';
import 'package:lumo_lernen/features/games/mini_games/number_house_game.dart';
import 'package:lumo_lernen/features/games/mini_games/color_boxes_game.dart';
import 'package:lumo_lernen/features/games/mini_games/letter_fill_game.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final house in [false, true]) {
    testWidgets(
        '${house ? 'Rechenhaus' : 'Sternepfad'} all five tasks, answer feedback, saved completion',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.hydrateFromWallet();
      final level = GameLevelCatalog.byId(house ? 7 : 42)!;
      await tester.pumpWidget(MaterialApp(
          home: house
              ? NumberHouseGame(appState: app, level: level)
              : StarsPathGame(appState: app, level: level)));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        final choices = house
            ? GameMathTasks.numberHouse(level, i)
                .choices
                .map((c) => '$c')
                .toList()
            : GameMathTasks.starsPath(level, i).choices;
        final answer = house
            ? '${GameMathTasks.numberHouse(level, i).answer}'
            : GameMathTasks.starsPath(level, i).answer;
        final option =
            find.byKey(ValueKey('math-option-${choices.indexOf(answer)}'));
        await tester.ensureVisible(option);
        await tester.pump();
        await tester.tap(option);
        await tester.pump();
        await tester.tap(
            find.text(house ? 'Antwort bestätigen' : 'Antwort bestaetigen'));
        await tester.pump();
        await tester.tap(find.text(i == 4 ? 'Spiel beenden' : 'Weiter'));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsOneWidget);
      expect(app.state.stars, 3);
      await app.flushRewards();
      expect((await RewardWalletRepository().load()).stars, 3);
      expect(
          (await const GameProgressRepository()
              .loadStars('local_lena_1'))[level.id],
          3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }

  testWidgets('Color boxes complete all five targets and save level 2',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    await tester.pumpWidget(MaterialApp(
        home: ColorBoxesGame(appState: app, level: GameLevelCatalog.byId(2)!)));
    await tester.pump();
    for (var round = 0; round < 5; round++) {
      final target = int.parse(tester
          .widgetList<Text>(find.byType(Text))
          .singleWhere((t) => t.style?.fontSize == 56)
          .data!);
      final empty = <int>[];
      var filled = 0;
      for (var i = 0; i < 10; i++) {
        final tile =
            tester.widget<Semantics>(find.byKey(ValueKey('color-box-$i')));
        if (tile.properties.label!.endsWith('leer')) {
          empty.add(i);
        } else {
          filled++;
        }
      }
      for (final i in empty.take(target - filled)) {
        await tester.tap(find.byKey(ValueKey('color-box-$i')));
        await tester.pump();
      }
      await tester.tap(find.text('Pruefen'));
      await tester.pump();
      expect(find.text('🎉 Richtig!'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pump();
    }
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(app.state.stars, 5);
    await app.flushRewards();
    expect(
        (await const GameProgressRepository().loadStars('local_lena_1'))[2], 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('Letter gaps complete six different words and save level 25',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet();
    await tester.pumpWidget(MaterialApp(
        home:
            LetterFillGame(appState: app, level: GameLevelCatalog.byId(25)!)));
    await tester.pump();
    const answers = {
      '🐭': 'M',
      '🐕': 'H',
      '🐟': 'F',
      '☀️': 'S',
      '🚗': 'A',
      '🌳': 'B',
      '🍎': 'A',
      '📖': 'B',
      '🏠': 'A',
      '🐱': 'T',
      '🌸': 'U',
      '🐦': 'O',
      '🪑': 'S',
      '🏫': 'U',
      '🧒': 'E',
      '🎮': 'L',
      '🌧️': 'E',
      '⭐': 'E',
      '🥛': 'L',
      '🐎': 'E'
    };
    final seen = <String>{};
    for (var i = 0; i < 6; i++) {
      final emoji = tester
          .widgetList<Text>(find.byType(Text))
          .singleWhere((t) => t.style?.fontSize == 100)
          .data!;
      seen.add(emoji);
      await tester.tap(find.descendant(
          of: find.byType(GridView), matching: find.text(answers[emoji]!)));
      await tester.pump(const Duration(milliseconds: 1500));
    }
    expect(seen.length, 6);
    expect(find.text('Geschafft! 🦊'), findsOneWidget);
    expect(app.state.stars, 5);
    await app.flushRewards();
    expect((await const GameProgressRepository().loadStars('local_lena_1'))[25],
        3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
