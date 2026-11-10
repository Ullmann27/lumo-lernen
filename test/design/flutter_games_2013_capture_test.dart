// Raster captures of the real Flutter game screens for LUMO 2013.
// Writes into LUMO_FLUTTER_GAMES_CAPTURE when set; otherwise skipped.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_jump_celebration.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_result_dialog.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

final String? _directory = Platform.environment['LUMO_FLUTTER_GAMES_CAPTURE'];
const _boundary = ValueKey('lumo-2013-games-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  for (final entry in const [
    ('phone', Size(412, 915)),
    ('fold', Size(690, 829)),
  ]) {
    final name = entry.$1;
    final size = entry.$2;

    testWidgets('Memory overview $name', (tester) async {
      await _open(
        tester,
        size,
        LumoMemoryScreen(
          appState: _app(),
          seed: 4,
          difficulty: MemoryDifficulty.schwer,
        ),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/memory_overview_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await _close(tester);
    }, skip: _directory == null);

    testWidgets('Cards overview $name', (tester) async {
      await _open(
        tester,
        size,
        LumoCardsScreen(
          appState: _app(),
          seed: 10,
          skipIntro: true,
        ),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/cards_overview_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await _close(tester);
    }, skip: _directory == null);

    testWidgets('Connect Four overview $name', (tester) async {
      await _open(
        tester,
        size,
        LumoConnectFourScreen(appState: _app(), seed: 1),
      );
      await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
      await tester.pump();
      for (final column in [3, 2, 3, 2, 4, 5]) {
        await tester.tap(find.byKey(ValueKey('connect-column-$column')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
      }
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/connect_overview_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await _close(tester);
    }, skip: _directory == null);

    testWidgets('Quizshow overview $name', (tester) async {
      await _open(
        tester,
        size,
        QuizShowContent(appState: _app(), previewQuestionSeed: 2013),
      );
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/quiz_overview_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await _close(tester);
    }, skip: _directory == null);

    testWidgets('Memory combo $name', (tester) async {
      await _open(
        tester,
        size,
        LumoMemoryScreen(
          appState: _app(),
          seed: 4,
          difficulty: MemoryDifficulty.leicht,
        ),
      );
      final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
      final firstPartner = deck.indexOf(deck[0], 1);
      final second = List<int>.generate(deck.length, (i) => i)
          .firstWhere((i) => deck[i] != deck[0]);
      final secondPartner = deck.indexOf(deck[second], second + 1);
      await tester.tap(find.byKey(const ValueKey('memory-card-0')));
      await tester.tap(find.byKey(ValueKey('memory-card-$firstPartner')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(ValueKey('memory-card-$second')));
      await tester.tap(find.byKey(ValueKey('memory-card-$secondPartner')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 600));
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/memory_combo_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await _close(tester);
    }, skip: _directory == null);

    testWidgets('Connect Four win-glow $name', (tester) async {
      await _open(
        tester,
        size,
        LumoConnectFourScreen(appState: _app(), seed: 1),
      );
      await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
      await tester.pump();
      for (final column in [0, 6, 1, 6, 2, 6, 3]) {
        await tester.tap(find.byKey(ValueKey('connect-column-$column')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();
      }
      // captureLumoBoundary itself pumps 480ms, so stay inside the
      // last-cell dwell (starts ~660ms, dialog ~1140ms).
      await tester.pump(const Duration(milliseconds: 400));
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/connect_winglow_$name.png',
        pixelRatio: 1.5,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await _close(tester);
    }, skip: _directory == null);

    testWidgets('Cards Lumo-Sprung $name', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LumoAppTheme.light(),
        home: const RepaintBoundary(
          key: _boundary,
          child: Scaffold(
            backgroundColor: Color(0xFF12355C),
            body: Center(child: LumoJumpCelebration()),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/cards_jump_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, skip: _directory == null);

    testWidgets('Cards round summary $name', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: _boundary,
          child: Scaffold(
            body: Stack(
              children: [
                LumoResultDialog(
                  winnerName: 'Du',
                  kindWon: true,
                  reward: 5,
                  streak: 2,
                  onRestart: () {},
                  onExit: () {},
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();
      await captureLumoBoundary(
        tester,
        _boundary,
        '$_directory/cards_summary_$name.png',
        pixelRatio: 1.5,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, skip: _directory == null);
  }
}

LumoAppState _app() {
  final app = LumoAppState();
  app.updateSettings(const AppSettings(
    voiceEnabled: false,
    soundEnabled: false,
    reduceAnimations: true,
  ));
  return app;
}

Future<void> _open(WidgetTester tester, Size size, Widget home) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (home is LumoMemoryScreen) {
    addTearDown(home.appState.dispose);
  } else if (home is LumoCardsScreen) {
    addTearDown(home.appState.dispose);
  } else if (home is LumoConnectFourScreen) {
    addTearDown(home.appState.dispose);
  } else if (home is QuizShowContent) {
    addTearDown(home.appState.dispose);
  }
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LumoAppTheme.light(),
    home: RepaintBoundary(key: _boundary, child: home),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}
