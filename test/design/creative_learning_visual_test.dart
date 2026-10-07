import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_lesson_tasks.dart';
import 'package:lumo_lernen/domain/games/game_world.dart';
import 'package:lumo_lernen/features/games/mini_games/lesson_trail_game.dart';
import 'package:lumo_lernen/features/games/widgets/lumo_creative_game_shelf.dart';

const boundary = ValueKey('creative-learning-capture');
Future<void> capture(WidgetTester tester, String name) async {
  final out = Platform.environment['LUMO_POLISH_CAPTURES'];
  if (out == null) return;
  await tester.pump();
  final render = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$out/$name.png');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    final font = FontLoader('Nunito')..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
    await font.load();
  });
  for (final id in [13, 23, 32, 47]) {
    testWidgets('Level $id renders, accepts its task and pauses safely', (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(); addTearDown(app.dispose);
      final level = GameLevelCatalog.byId(id)!;
      await tester.pumpWidget(MaterialApp(theme: LumoAppTheme.light(),
        home: RepaintBoundary(key: boundary, child: LessonTrailGame(appState: app, level: level))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await capture(tester, 'learning_level_$id');
      final task = GameLessonTasks.task(level, 0);
      if (!task.orderWords) {
        await tester.ensureVisible(find.byKey(ValueKey('lesson-answer-${task.answer}')));
        await tester.tap(find.byKey(ValueKey('lesson-answer-${task.answer}')));
        await tester.pump();
        expect(find.text(task.explanation), findsOneWidget);
      } else {
        for (final word in task.answer.split(' ')) {
          await tester.ensureVisible(find.widgetWithText(FilledButton, word));
          await tester.tap(find.widgetWithText(FilledButton, word)); await tester.pump();
        }
        await tester.tap(find.text('Satz prüfen')); await tester.pump();
        expect(find.text(task.explanation), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Pause')); await tester.pump();
      expect(find.text('Fortsetzen'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Creative shelf uses real game previews and opens all four games', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final opened = <GameId>[];
    await tester.pumpWidget(MaterialApp(theme: LumoAppTheme.light(), home: Scaffold(
      body: RepaintBoundary(key: boundary, child: SingleChildScrollView(child: LumoCreativeGameShelf(
        busy: false, unlocked: (_) => true, onOpen: opened.add))))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await capture(tester, 'creative_worlds_app');
    for (final game in LumoCreativeGameShelf.games) {
      final button = find.byKey(ValueKey('launch-creative-${game.$4}'));
      await tester.ensureVisible(button); await tester.tap(button); await tester.pump();
    }
    expect(opened, [GameId.build, GameId.puzzle, GameId.treasure, GameId.rhythm]);
    await tester.pumpWidget(const SizedBox());
  });
}
