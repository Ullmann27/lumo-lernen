import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_math_tasks.dart';
import 'package:lumo_lernen/features/games/mini_games/color_boxes_game.dart';
import 'package:lumo_lernen/features/games/mini_games/letter_fill_game.dart';
import 'package:lumo_lernen/features/games/mini_games/number_house_game.dart';
import 'package:lumo_lernen/features/games/mini_games/stars_path_game.dart';
import 'package:lumo_lernen/features/games/shared/lumo_board_game_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

Widget _game(String game, LumoAppState app) => switch (game) {
      'boxes' =>
        ColorBoxesGame(appState: app, level: GameLevelCatalog.byId(2)!),
      'letters' =>
        LetterFillGame(appState: app, level: GameLevelCatalog.byId(25)!),
      'house' =>
        NumberHouseGame(appState: app, level: GameLevelCatalog.byId(7)!),
      _ => StarsPathGame(appState: app, level: GameLevelCatalog.byId(42)!),
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(loadLumoCaptureFonts);

  testWidgets('Round progress speaks real counters and marks completed steps',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: LumoBoardRoundProgress(
                currentIndex: 2, total: 5, correct: 1))));
    expect(find.text('Aufgabe 3 / 5'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.bySemanticsLabel('Aufgabe 3 von 5, 1 richtig'), findsOneWidget);
    semantics.dispose();
  });

  for (final game in ['boxes', 'letters', 'house', 'stars']) {
    for (final size in const [Size(412, 915), Size(690, 829)]) {
      testWidgets('$game actual premium surface at $size', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState();
        app.updateSettings(const AppSettings(
            voiceEnabled: false,
            soundEnabled: false,
            autoReadEnabled: false,
            reduceAnimations: true));
        const boundary = ValueKey('board-premium-capture');
        await tester.pumpWidget(MaterialApp(
            theme: LumoAppTheme.light(),
            home: RepaintBoundary(key: boundary, child: _game(game, app))));
        await tester.pump();
        final progress = tester.widget<LumoBoardRoundProgress>(
            find.byType(LumoBoardRoundProgress));
        expect(progress.currentIndex, 0);
        expect(progress.correct, 0);
        for (final step in tester.widgetList<AnimatedContainer>(find.descendant(
            of: find.byType(LumoBoardRoundProgress),
            matching: find.byType(AnimatedContainer)))) {
          expect(step.duration, Duration.zero,
              reason: 'Reduced motion applies to the round track.');
        }
        if (game == 'house' || game == 'stars') {
          final prompt = tester.widget<Text>(find.textContaining(game == 'house'
              ? 'Welche Zahl fehlt'
              : GameMathTasks.starsPath(GameLevelCatalog.byId(42)!, 0).prompt));
          expect(_contrast(prompt.style!.color!, const Color(0xFFF0F7FC)),
              greaterThan(7),
              reason: 'Task ink must remain readable in the night app theme.');
          final option = find.byKey(const ValueKey('math-option-0'));
          await tester.ensureVisible(option);
          await tester.tap(option);
          await tester.pump();
          final surface = tester.widget<AnimatedContainer>(find
              .descendant(of: option, matching: find.byType(AnimatedContainer))
              .first);
          expect(surface.duration, Duration.zero);
          final color = (surface.decoration! as BoxDecoration).color!;
          final label = tester.widget<Text>(
              find.descendant(of: option, matching: find.byType(Text)).first);
          expect(_contrast(label.style!.color!, color), greaterThan(4.5));
        }
        final folder = Platform.environment['LUMO_BOARD_CAPTURES'];
        if (folder != null) {
          await captureLumoBoundary(tester, boundary,
              '$folder/$game-${size.width.toInt()}x${size.height.toInt()}.png',
              pixelRatio: 1.5);
        }
        await tester.tap(find.byTooltip('Pausieren / Zurück'));
        await tester.pump();
        expect(find.text('Spiel pausiert'), findsOneWidget);
        await tester.tap(find.text('Fortsetzen'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
    }
  }
}
