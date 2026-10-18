import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/mini_games/color_boxes_game.dart';
import 'package:lumo_lernen/features/games/mini_games/letter_fill_game.dart';
import 'package:lumo_lernen/features/games/mini_games/number_house_game.dart';
import 'package:lumo_lernen/features/games/mini_games/stars_path_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dice_race_runtime_test.dart' show boundary, capture;
import '../helpers/lumo_capture.dart' show loadLumoCaptureFonts;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(loadLumoCaptureFonts);
  for (final size in const [Size(360, 640), Size(967, 805), Size(926, 362)]) {
    for (final game in ['boxes', 'letters', 'house', 'stars']) {
      testWidgets('$game on $size with large text remains playable',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState();
        app.updateSettings(
            const AppSettings(voiceEnabled: false, soundEnabled: false));
        final screen = switch (game) {
          'boxes' =>
            ColorBoxesGame(appState: app, level: GameLevelCatalog.byId(2)!),
          'letters' =>
            LetterFillGame(appState: app, level: GameLevelCatalog.byId(25)!),
          'house' =>
            NumberHouseGame(appState: app, level: GameLevelCatalog.byId(7)!),
          _ => StarsPathGame(appState: app, level: GameLevelCatalog.byId(42)!),
        };
        await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(
                    size: size, textScaler: TextScaler.linear(1.6)),
                child: RepaintBoundary(key: boundary, child: screen))));
        await tester.pump(const Duration(milliseconds: 400));
        await capture(
            tester, '$game-${size.width.toInt()}x${size.height.toInt()}');
        expect(tester.takeException(), isNull);
        final control = game == 'boxes'
            ? find.byKey(const ValueKey('color-box-9'))
            : game == 'letters'
                ? find
                    .byWidgetPredicate((widget) =>
                        widget is GestureDetector &&
                        widget.key is ValueKey<String> &&
                        (widget.key! as ValueKey<String>)
                            .value
                            .startsWith('letter-choice-'))
                    .last
                : find.byKey(const ValueKey('math-option-2'));
        await tester.ensureVisible(control);
        await tester.pump();
        expect(control.hitTestable(), findsOneWidget);
        await capture(tester,
            '$game-answers-${size.width.toInt()}x${size.height.toInt()}');
        await tester.tap(control);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
    }
  }
}
