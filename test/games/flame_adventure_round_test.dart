// Actual Flutter/Flame input and physics check; never an Android-device claim.
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/flame/lumo_jump_game.dart';

Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

Future<LumoFlameJumpGame> _menuAndCollect(
    WidgetTester tester, LumoAppState app) async {
  await tester.binding.setSurfaceSize(const Size(800, 900));
  await app.hydrateFromWallet();
  await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
  await tester.pump();
  await tester.pump();
  final card = find.text('Lumos Jump Adventure · 2D');
  // Die Spielewelt baut Karten unterhalb der Spielkarten erst beim Scrollen.
  await tester.scrollUntilVisible(card, 300,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(card);
  await tester.pump();
  await tester.tap(card);
  await _frames(tester);
  expect(find.byType(LumoJumpFlameScreen), findsOneWidget);
  final game = tester
      .widget<GameWidget<LumoFlameJumpGame>>(
          find.byType(GameWidget<LumoFlameJumpGame>))
      .game!;
  await tester.runAsync(() => game.ready());
  await tester.pump();
  final joystick = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_VirtualJoystick');
  final stick = await tester.startGesture(
      tester.getRect(joystick).topLeft + const Offset(164, 100),
      pointer: 1);
  for (var frame = 0; frame < 240 && game.totalEarnedStars == 0; frame++) {
    await _frames(tester, 1);
  }
  await stick.up();
  await tester.pump();
  expect(game.totalEarnedStars, greaterThan(0),
      reason:
          'Only real joystick movement and collision physics may earn this reward');
  return game;
}

Future<void> _dispose(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf'
    }.entries) {
      final file = File('$fonts/${entry.value}');
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(
          Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });

  testWidgets('Full adventure actual joystick and 60 Hz collision physics',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    final game = await _menuAndCollect(tester, app);
    final joystick = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_VirtualJoystick');
    final origin = tester.getRect(joystick).topLeft + const Offset(100, 100);
    TestGesture? stick;
    var direction = 1.0;
    var questions = 0;
    var jumps = 0;
    var falls = 0;
    var previousX = game.fox.position.x;
    String answerFromPrompt(String prompt) {
      final math =
          RegExp(r'^(\d+)\s*([+−-])\s*(\d+)\s*=\s*\?$').firstMatch(prompt);
      if (math != null) {
        final a = int.parse(math[1]!), b = int.parse(math[3]!);
        return '${math[2] == '+' ? a + b : a - b}';
      }
      final line = RegExp(r'^Welche Zahl fehlt\? (\d+), (\d+), _, (\d+)$')
          .firstMatch(prompt);
      if (line != null) return '${int.parse(line[2]!) + 1}';
      if (prompt.endsWith('– wo ist mehr?')) {
        final parts = prompt.split(' oder ');
        final left = '🍎'.allMatches(parts[0]).length,
            right = '🍎'.allMatches(parts[1]).length;
        return left == right
            ? 'gleich'
            : left > right
                ? 'links'
                : 'rechts';
      }
      final first =
          RegExp(r'^Mit welchem Laut beginnt (.+)\?$').firstMatch(prompt);
      final sound = RegExp(r'^Welche Buchstaben passen zum Laut „([^“]+)“\?$')
          .firstMatch(prompt);
      if (sound != null) {
        final value = sound[1]!;
        if (value.startsWith('sch')) return 'Sch';
        if (value.startsWith('ch')) return 'Ch';
        return value[0].toUpperCase();
      }
      if (first != null) {
        final word = first[1]!;
        if (word.startsWith('Sch') || word.startsWith('St')) return 'Sch';
        if (word.startsWith('Au')) return 'Au';
        if (word.startsWith('V')) return 'F';
        return word[0].toUpperCase();
      }
      final last =
          RegExp(r'^Mit welchem Laut endet (.+)\?$').firstMatch(prompt);
      if (last != null) {
        final word = last[1]!;
        if (word.toLowerCase().endsWith('sch')) return 'Sch';
        if (word.toLowerCase().endsWith('ch')) return 'Ch';
        if (word.endsWith('ß')) return 'S';
        final letter =
            (word.endsWith('h') ? word[word.length - 2] : word[word.length - 1])
                .toUpperCase();
        return {'D': 'T', 'B': 'P', 'G': 'K'}[letter] ?? letter;
      }
      const images = {
        '🍎': 'Apfel',
        '🏠': 'Haus',
        '🐕': 'Hund',
        '🐶': 'Hund',
        '🐈': 'Katze',
        '🐱': 'Katze',
        '🌳': 'Baum',
        '☀️': 'Sonne',
        '🌸': 'Blume',
        '🌼': 'Blume',
        '🚗': 'Auto',
        '🐟': 'Fisch',
        '📚': 'Buch',
        '📖': 'Buch',
        '🐭': 'Maus',
        '🐷': 'Schwein',
        '🐰': 'Hase',
        '🥕': 'Karotte',
        '🦊': 'Fuchs',
        '🐻': 'Bär',
        '🐸': 'Frosch',
        '🌙': 'Mond',
        '⭐': 'Stern',
        '🚲': 'Rad',
        '🚂': 'Zug',
        '⚽': 'Ball',
        '🍌': 'Banane',
        '🐦': 'Vogel',
        '🐴': 'Pferd',
        '🐮': 'Kuh',
        '🐔': 'Huhn',
        '🥚': 'Ei',
        '🍞': 'Brot',
        '🚪': 'Tür',
        '🛏️': 'Bett',
        '👃': 'Nase',
        '✋': 'Hand',
        '👂': 'Ohr'
      };
      const additionalImages = {
        '🐝': 'Biene',
        '🍐': 'Birne',
        '🚌': 'Bus',
        '📘': 'Buch'
      };
      for (final entry in {...images, ...additionalImages}.entries) {
        if (prompt.contains('Bild: ${entry.key}')) return entry.value;
      }
      const syllables = {
        'Apfel': 2,
        'Banane': 3,
        'Sonne': 2,
        'Haus': 1,
        'Hund': 1,
        'Katze': 2,
        'Maus': 1,
        'Hase': 2,
        'Nase': 2,
        'Rose': 2,
        'Ball': 1,
        'Baum': 1,
        'Auto': 2,
        'Blume': 2,
        'Schule': 2,
        'Tomate': 3,
        'Elefant': 3,
        'Rakete': 3,
        'Ameise': 3,
        'Schokolade': 4,
        'Krokodil': 3,
        'Giraffe': 3,
        'Pinguin': 3
      };
      final syl = RegExp(r'^Wie viele Silben hat (.+)\?$').firstMatch(prompt);
      if (syl != null && syllables.containsKey(syl[1])) {
        return '${syllables[syl[1]]}';
      }
      if (syl != null) {
        return '${RegExp(r'au|ei|eu|äu|ie|aa|ee|oo|[aeiouäöü]', caseSensitive: false).allMatches(syl[1]!).length}';
      }
      throw StateError('Unsupported visible prompt: $prompt');
    }

    for (var frame = 0;
        frame < 7000 && find.text('Level geschafft!').evaluate().isEmpty;
        frame++) {
      if (game.interactionLock) {
        await stick?.up();
        stick = null;
        await _frames(tester, 30);
        final question = find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_QuestionSheet');
        final chest = find.byType(AlertDialog);
        final panel = question.evaluate().isNotEmpty ? question : chest;
        final texts = tester
            .widgetList<Text>(
                find.descendant(of: panel, matching: find.byType(Text)))
            .map((t) => t.data ?? '')
            .toList();
        final prompt = texts.firstWhere(
            (text) => text.contains('?') || text.endsWith('wo ist mehr?'));
        final answer = answerFromPrompt(prompt);
        debugPrint('VISIBLE QUESTION $prompt -> $answer (choices: $texts)');
        final choice = find.descendant(of: panel, matching: find.text(answer));
        expect(choice, findsOneWidget);
        await tester.tap(choice);
        await tester.pump();
        await tester.tap(find.text('Antwort prüfen'));
        await _frames(tester, 30);
        questions++;
        if (game.solvedN.value == game.totalQN.value) direction = 1;
        if (questions > 15) {
          fail(
              'Too many unanswered visible questions; no artificial completion');
        }
        continue;
      }
      if (game.solvedN.value < game.totalQN.value) {
        final unresolved = game.questionBlocks.where((b) => !b.cleared).toList()
          ..sort((a, b) =>
              (a.position.x - game.fox.position.x).abs().compareTo(
                    (b.position.x - game.fox.position.x).abs(),
                  ));
        if (unresolved.isNotEmpty) {
          final targetX = unresolved.first.position.x;
          if ((targetX - game.fox.position.x).abs() > 70) {
            direction = targetX > game.fox.position.x ? 1 : -1;
          }
        }
      } else {
        direction = 1;
      }
      stick ??= await tester.startGesture(origin + Offset(64 * direction, 0),
          pointer: 1);
      await stick.moveTo(origin + Offset(64 * direction, 0));
      final rect = game.fox.worldRect;
      final grounds = game.platforms
          .where((p) =>
              (rect.bottom - p.position.y).abs() < 5 &&
              rect.right > p.position.x + 6 &&
              rect.left < p.position.x + p.size.x - 6)
          .toList();
      if (game.fox.onGround && grounds.isNotEmpty) {
        final end = grounds
            .map((p) => p.position.x + p.size.x)
            .reduce((a, b) => a > b ? a : b);
        final start =
            grounds.map((p) => p.position.x).reduce((a, b) => a < b ? a : b);
        final edge = direction > 0 ? end - rect.right : rect.left - start;
        double distanceTo(dynamic o) => direction > 0
            ? o.position.x - rect.right
            : rect.left - o.position.x - o.size.x;
        final ahead = game.obstacles
                .any((o) => distanceTo(o) >= -5 && distanceTo(o) < 40) ||
            game.crates.any(
                (o) => o.active && distanceTo(o) >= -5 && distanceTo(o) < 40);
        if (edge < 35 || ahead) {
          await tester.tap(find.text('▲'));
          jumps++;
        }
      }
      // The game's own fall recovery may move to a platform either ahead
      // or behind the fox. No test code changes the player's position.
      if ((game.fox.position.x - previousX).abs() > 100) falls++;
      previousX = game.fox.position.x;
      if (frame % 120 == 0) {
        debugPrint(
            'RUN frame=$frame x=${game.fox.position.x} y=${game.fox.position.y} vx=${game.fox.vx} vy=${game.fox.vy} ground=${game.fox.onGround} questions=${game.solvedN.value}/${game.totalQN.value} stars=${game.totalEarnedStars} jumps=$jumps falls=$falls');
      }
      await _frames(tester, 1);
    }
    await stick?.up();
    expect(find.text('Level geschafft!'), findsOneWidget);
    expect(game.solvedN.value, game.totalQN.value);
    expect(game.chest.chestState, isNot(ChestState.closed));
    final earned = game.totalEarnedStars;
    await tester.tap(find.text('Weiter'));
    await _frames(tester);
    expect(find.byType(LumoJumpFlameScreen), findsNothing);
    final stored = await RewardWalletRepository().load();
    expect(stored.stars, earned);
    expect(stored.xp, earned * 2);
    final name = app.state.childName.trim().isEmpty
        ? 'kind'
        : app.state.childName
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final progress = await const GameProgressRepository()
        .loadStars('local_${name}_${app.state.grade}');
    expect(progress[game.level.id], 3);
    debugPrint(
        'COMPLETE actual physics stars=$earned questions=$questions jumps=$jumps falls=$falls time=${game.totalTime}');
    final reloaded = LumoAppState(walletRepository: RewardWalletRepository());
    await reloaded.hydrateFromWallet();
    expect(reloaded.state.stars, earned);
    expect(reloaded.state.xp, earned * 2);
    reloaded.dispose();
    final replay = find.text('Lumos Jump Adventure · 2D');
    await tester.ensureVisible(replay);
    await tester.pump();
    await tester.tap(replay);
    await _frames(tester);
    final restarted = tester
        .widget<GameWidget<LumoFlameJumpGame>>(
            find.byType(GameWidget<LumoFlameJumpGame>))
        .game!;
    await tester.runAsync(() => restarted.ready());
    await tester.pump();
    expect(identical(restarted, game), isFalse);
    expect(restarted.totalEarnedStars, 0);
    expect(restarted.questionBlocks.every((b) => !b.cleared), isTrue);
    final replayStick = await tester.startGesture(
        tester.getRect(joystick).topLeft + const Offset(164, 100),
        pointer: 1);
    await _frames(tester, 8);
    await replayStick.up();
    await tester.pump();
    expect(restarted.fox.position.x, greaterThan(70));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final pausedPosition = restarted.fox.position.clone();
    expect(restarted.paused, isTrue);
    await _frames(tester, 60);
    expect(restarted.fox.position, pausedPosition);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester, 5);
    expect(restarted.paused, isFalse);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    await tester.tap(find.text('Verlassen'));
    await _frames(tester);
    expect(find.byType(LumoJumpFlameScreen), findsNothing);
    expect((await RewardWalletRepository().load()).stars, earned);
    await _dispose(tester, app);
  });
}
