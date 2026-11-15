import 'dart:async';
import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/flame/lumo_jump_game.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

/// Exercise the production game's installed Flutter question callbacks. The
/// engine is paused to isolate these surfaces; this is not a physics tour or
/// device speech test. Answers are derived only from the displayed prompt.
String _visibleMathAnswer(String prompt) {
  final calculation =
      RegExp(r'^(\d+)\s*([+−-])\s*(\d+)\s*=\s*\?$').firstMatch(prompt);
  if (calculation != null) {
    final a = int.parse(calculation[1]!), b = int.parse(calculation[3]!);
    return '${calculation[2] == '+' ? a + b : a - b}';
  }
  final line = RegExp(r'^Welche Zahl fehlt\? (\d+), (\d+), _, (\d+)$')
      .firstMatch(prompt);
  if (line != null) return '${int.parse(line[2]!) + 1}';
  if (prompt.endsWith('– wo ist mehr?')) {
    final parts = prompt.split(' oder ');
    final left = '🍎'.allMatches(parts[0]).length;
    final right = '🍎'.allMatches(parts[1]).length;
    return left == right ? 'gleich' : (left > right ? 'links' : 'rechts');
  }
  throw StateError('Unsupported visible mathematical prompt: $prompt');
}

Future<void> _frames(WidgetTester tester, [int count = 10]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  late LumoAppState app;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              soundEnabled: false,
              calmMode: true)
          .toJson()),
    });
    bus.clearLearningScope();
    LumoVoice.instance.isEnabled = false;
    app = LumoAppState(walletRepository: RewardWalletRepository());
  });
  tearDown(() {
    app.dispose();
    LumoVoice.instance.isEnabled = true;
  });

  Future<LumoFlameJumpGame> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await app.ensureSettingsLoaded();
      await app.loadLearningProfile();
    });
    await tester.pumpWidget(MaterialApp(
        home: LumoJumpFlameScreen(
            appState: app, level: GameLevelCatalog.levels.first)));
    await _frames(tester);
    final game = tester
        .widget<GameWidget<LumoFlameJumpGame>>(
            find.byType(GameWidget<LumoFlameJumpGame>))
        .game!;
    await tester.runAsync(() => game.ready());
    game.pauseEngine();
    await _frames(tester);
    return game;
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pump();
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await _frames(tester);
  }

  Future<void> propose(WidgetTester tester, String answer) async {
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: answer),
        isTrue);
    await _frames(tester);
    final input = find.byKey(const ValueKey('game-answer-proposal'));
    expect(tester.widget<TextField>(input).controller!.text, answer);
    await tap(
        tester, find.widgetWithText(OutlinedButton, 'Diese Karte wählen'));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  }

  testWidgets('Flame question confirms a card before the existing answer check',
      (tester) async {
    final game = await open(tester);
    bool? solved;
    unawaited(game
        .onQuestionNeeded(
            'Mathematik',
            const LumoLearningTask(
                prompt: '8 + 5 = ?', choices: ['12', '13', '14'], answer: '13'))
        .then((value) => solved = value));
    await _frames(tester, 20);
    expect(find.text('8 + 5 = ?'), findsOneWidget);
    expect(bus.taskContext.value!.ownerSection, 'games');
    final original = bus.learningIdentity.value!;
    final entry = find.widgetWithText(OutlinedButton, 'Mit Lumo in 3D');
    expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));

    await propose(tester, '12');
    expect(solved, isNull);
    expect(find.text('Tippe auf die richtige Antwort.'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('jump-check-answer')));
    expect(solved, isNull);
    expect(find.text('Noch nicht ganz – versuch es nochmal!'), findsOneWidget);
    expect(bus.taskContext.value!.lastAnswer, '12');
    expect(bus.taskContext.value!.lastCorrect, isFalse);
    expect(bus.isCurrentLearningIdentity(original), isFalse);

    await propose(tester, '13');
    expect(solved, isNull);
    expect((app.state.stars, app.state.xp), (0, 0));
    await tap(tester, find.byKey(const ValueKey('jump-check-answer')));
    await _frames(tester, 20);
    expect(solved, isTrue);
    expect(find.text('8 + 5 = ?'), findsNothing);
    expect(bus.taskContext.value, isNull);
    expect((app.state.stars, app.state.xp), (0, 0),
        reason:
            'The surface returns its result; the existing game owns rewards.');
    await close(tester);
  });

  testWidgets('Flame chest keeps the original three-consecutive-answer rule',
      (tester) async {
    final game = await open(tester);
    bool? opened;
    unawaited(game.onChestChallenge().then((value) => opened = value));
    await _frames(tester, 20);
    expect(find.text('Serie: 0 / 3'), findsOneWidget);
    final first = bus.taskContext.value!;
    expect(find.text(first.prompt), findsOneWidget);
    final wrong = first.answerChoices
        .firstWhere((choice) => choice != _visibleMathAnswer(first.prompt));
    await propose(tester, wrong);
    expect(opened, isNull);
    expect(find.text('Serie: 0 / 3'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('jump-chest-check')));
    expect(find.text('Fast! Wir starten die 3er-Serie neu.'), findsOneWidget);
    expect(find.text('Serie: 0 / 3'), findsOneWidget);
    expect(bus.taskContext.value!.taskId, isNot(first.taskId));

    for (var streak = 0; streak < 3; streak++) {
      final task = bus.taskContext.value!;
      expect(find.text(task.prompt), findsOneWidget);
      await propose(tester, _visibleMathAnswer(task.prompt));
      expect(opened, isNull,
          reason: 'A confirmed candidate cannot increment the chest streak.');
      expect(find.text('Serie: $streak / 3'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('jump-chest-check')));
      if (streak < 2) {
        expect(opened, isNull);
        expect(find.text('Serie: ${streak + 1} / 3'), findsOneWidget);
        expect(bus.taskContext.value!.taskId, isNot(task.taskId));
      }
    }
    await _frames(tester, 20);
    expect(opened, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(bus.taskContext.value, isNull);
    expect((app.state.stars, app.state.xp), (0, 0));
    await close(tester);
  });
}
