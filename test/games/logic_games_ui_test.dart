import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/logic/logic_games.dart';
import 'package:lumo_lernen/domain/logic/logic_learning_profile.dart';
import 'package:lumo_lernen/features/games/logic/logic_games_screen.dart';
import 'package:lumo_lernen/features/games/logic/logic_progress_store.dart';
import 'package:lumo_lernen/features/games/logic/logic_puzzle_screen.dart';
import 'package:lumo_lernen/features/games/logic/logic_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

const _boundary = ValueKey('logic-ui-capture');
const _profile = 'logic-ui-child';
const _store = LogicProgressStore();

Future<void> _ticks(WidgetTester tester, [int count = 12]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _ticks(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  final output = Platform.environment['LUMO_LOGIC_CAPTURES'];
  if (output != null && output.isNotEmpty) {
    await captureLumoBoundary(tester, _boundary, '$output/$name.png',
        pixelRatio: 1.5);
  }
}

LumoAppState _app() => LumoAppState()
  ..updateSettings(const AppSettings(
    voiceEnabled: false,
    soundEnabled: false,
    reduceAnimations: true,
    calmMode: true,
  ));

Widget _wrapped(Widget child, {double textScale = 1}) => MaterialApp(
      theme: LumoAppTheme.light(),
      builder: (context, child) => RepaintBoundary(
        key: _boundary,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
      home: child,
    );

Future<void> _enterCell(
    WidgetTester tester, LogicPuzzle puzzle, int index, String value) async {
  final wordCell = find.byKey(ValueKey('logic-word-cell-$index'));
  await _tap(
      tester,
      wordCell.evaluate().isNotEmpty
          ? wordCell
          : find.byKey(ValueKey('logic-cell-$index')));
  for (final symbol in value.split('')) {
    final input = find.byKey(ValueKey('logic-input-$symbol'));
    expect(tester.getSize(input).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(input).height, greaterThanOrEqualTo(48));
    await _tap(tester, input);
  }
  if (puzzle.kind == LogicGameKind.maths) {
    await _tap(tester, find.byKey(const ValueKey('logic-check')));
  }
}

class _FailOnceStore extends LogicProgressStore {
  _FailOnceStore();
  bool fail = true;
  @override
  Future<LogicProgress> saveSession(
      String profileId, LogicPuzzleSession session) {
    if (fail) {
      fail = false;
      return Future.error(StateError('simulated persistence failure'));
    }
    return super.saveSession(profileId, session);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('logic hub prepares a fresh learning profile without hanging',
      (tester) async {
    final app = _app();
    await tester.pumpWidget(_wrapped(LogicGamesScreen(appState: app)));
    await _ticks(tester, 30);
    for (final kind in LogicGameKind.values) {
      expect(find.byKey(ValueKey('logic-game-${kind.name}')), findsOneWidget);
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  for (final kind in LogicGameKind.values) {
    testWidgets(
        '${kind.name}: wrong, hint, resume, real completion unlocks next level',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(344, 882));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = _app();
      await app.school.setActiveStudent(_profile);
      await app.loadLearningProfile();
      await tester.pumpWidget(_wrapped(LogicGamesScreen(appState: app)));
      await _ticks(tester);
      await _tap(tester, find.byKey(ValueKey('logic-game-${kind.name}')));
      final locked = tester
          .widget<LogicAction>(find.byKey(const ValueKey('logic-level-2')));
      expect(locked.onPressed, isNull);
      await _tap(tester, find.byKey(const ValueKey('logic-level-1')));
      expect(find.byType(LogicPuzzleScreen), findsOneWidget);
      final puzzle = LogicCatalog.puzzle(kind, 1, 1);
      final first = puzzle.editableCells.first;
      await _capture(tester, '${kind.name}-initial');
      if (kind == LogicGameKind.words) {
        final clue = puzzle.clues.last;
        await _tap(tester, find.byKey(ValueKey('logic-word-clue-${clue.id}')));
        expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('logic-active-clue')))
                .data,
            clue.text);
        for (final index in clue.cells) {
          final size =
              tester.getSize(find.byKey(ValueKey('logic-word-cell-$index')));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        await _capture(tester, 'words-entry');
      }
      final wrong = kind == LogicGameKind.words
          ? (first.answer == 'X' ? 'Y' : 'X')
          : (first.answer == '1' ? '2' : '1');
      await _enterCell(tester, puzzle, first.index, wrong);
      var progress = await _store.load(_profile);
      expect(progress.drafts[puzzle.id]!.errors, 1);
      expect(progress.isCompleted(puzzle.id), isFalse);
      await _tap(tester, find.widgetWithText(LogicAction, 'Lumo hilft'));
      expect(find.text('Lumo denkt mit dir'), findsOneWidget);
      await _tap(tester, find.widgetWithText(LogicAction, 'Ich probiere es'));
      await _enterCell(tester, puzzle, first.index, first.answer);
      progress = await _store.load(_profile);
      final attemptId = progress.drafts[puzzle.id]!.attemptId;
      expect(progress.drafts[puzzle.id]!.hints, 1);
      expect(progress.drafts[puzzle.id]!.answers[first.index], first.answer);
      expect(
          find.descendant(
              of: find.byKey(ValueKey('logic-cell-${first.index}')),
              matching: find.byIcon(Icons.check_rounded)),
          findsOneWidget);
      await _tap(tester, find.byTooltip('Zu den Levels'));
      await _tap(tester, find.byKey(const ValueKey('logic-level-1')));
      progress = await _store.load(_profile);
      expect(progress.drafts[puzzle.id]!.attemptId, attemptId);
      expect(progress.drafts[puzzle.id]!.answers[first.index], first.answer);
      for (final cell in puzzle.editableCells.skip(1)) {
        await _enterCell(tester, puzzle, cell.index, cell.answer);
      }
      expect(find.text('Abenteuer geschafft!'), findsOneWidget);
      progress = await _store.load(_profile);
      expect(progress.isCompleted(puzzle.id), isTrue);
      expect(progress.isUnlocked(kind, 1, 2), isTrue);
      expect(progress.results[puzzle.id]!.hints, 1);
      expect(progress.results[puzzle.id]!.errors, 1);
      await _capture(tester, '${kind.name}-success');
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byKey(const ValueKey('logic-finished')));
      final unlocked = tester
          .widget<LogicAction>(find.byKey(const ValueKey('logic-level-2')));
      expect(unlocked.onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }

  for (final device in const {
    'fold-cover': Size(344, 882),
    'fold-open': Size(690, 829),
    'landscape': Size(840, 560),
  }.entries) {
    testWidgets('${device.key}: large text keeps every game operable at 48dp',
        (tester) async {
      await tester.binding.setSurfaceSize(device.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = _app();
      await app.school.setActiveStudent(_profile);
      await app.loadLearningProfile();
      await tester.pumpWidget(
          _wrapped(LogicGamesScreen(appState: app), textScale: 1.5));
      await _ticks(tester);
      final hero = tester.getRect(find.byKey(const ValueKey('logic-hero')));
      for (final key in const ['logic-hero-title', 'logic-hero-subtitle']) {
        final text = tester.getRect(find.byKey(ValueKey(key)));
        expect(text.top, greaterThanOrEqualTo(hero.top));
        expect(text.bottom, lessThanOrEqualTo(hero.bottom));
      }
      await _capture(tester, 'hub-${device.key}-large');
      final wordsCard = find.ancestor(
          of: find.byKey(const ValueKey('logic-game-words')),
          matching: find.byType(LogicGlass));
      await tester.ensureVisible(wordsCard);
      await _ticks(tester);
      await _capture(tester, 'hub-words-${device.key}-large');
      expect(tester.takeException(), isNull);
      final owner = await app.captureLearningProfile();
      for (final kind in LogicGameKind.values) {
        final puzzle = LogicCatalog.puzzle(kind, 4, 12);
        final session = await _store.begin(
            profileId: _profile,
            puzzle: puzzle,
            sessionId: 'qa-large-${device.key}');
        await tester.pumpWidget(_wrapped(
            LogicPuzzleScreen(
              appState: app,
              owner: owner,
              puzzle: puzzle,
              session: session,
            ),
            textScale: 1.5));
        await _ticks(tester);
        for (final cell in puzzle.editableCells) {
          final size =
              tester.getSize(find.byKey(ValueKey('logic-cell-${cell.index}')));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        for (final value in puzzle.inputChoices) {
          final size =
              tester.getSize(find.byKey(ValueKey('logic-input-$value')));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        if (kind == LogicGameKind.sudoku) {
          // The 6×6 board fits a narrow fold cover while retaining 48 dp cells.
          final left =
              tester.getRect(find.byKey(const ValueKey('logic-cell-0')));
          final right = tester.getRect(
              find.byKey(ValueKey('logic-cell-${puzzle.columns - 1}')));
          expect(left.left, greaterThanOrEqualTo(16));
          expect(right.right, lessThanOrEqualTo(device.value.width - 16));
        }
        await _capture(tester, '${kind.name}-${device.key}-large');
        if (kind == LogicGameKind.words) {
          await _tap(tester,
              find.byKey(ValueKey('logic-word-clue-${puzzle.clues.last.id}')));
          await _capture(tester, 'words-entry-${device.key}-large');
        }
        await _tap(tester, find.widgetWithText(LogicAction, 'Lumo hilft'));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.widgetWithText(LogicAction, 'Ich probiere es'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
      app.dispose();
    });
  }

  testWidgets(
      'profile switch disables inputs without moving another child progress',
      (tester) async {
    final app = _app();
    await app.school.setActiveStudent(_profile);
    await app.loadLearningProfile();
    final owner = await app.captureLearningProfile();
    final puzzle = LogicCatalog.puzzle(LogicGameKind.sudoku, 1, 1);
    final session = await _store.begin(
        profileId: _profile, puzzle: puzzle, sessionId: 'owner-test');
    await tester.pumpWidget(_wrapped(LogicPuzzleScreen(
      appState: app,
      owner: owner,
      puzzle: puzzle,
      session: session,
    )));
    await _ticks(tester);
    await app.school.setActiveStudent('other-child');
    await app.loadLearningProfile();
    await _ticks(tester);
    final key = tester
        .widget<FilledButton>(find.byKey(const ValueKey('logic-input-1')));
    expect(key.onPressed, isNull);
    expect((await _store.load('other-child')).drafts, isEmpty);
    expect((await _store.load(_profile)).drafts[puzzle.id]!.answers, isEmpty);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets(
      'a failed save locks input and retry preserves the accepted answer',
      (tester) async {
    final app = _app();
    await app.school.setActiveStudent(_profile);
    await app.loadLearningProfile();
    final owner = await app.captureLearningProfile();
    final puzzle = LogicCatalog.puzzle(LogicGameKind.sudoku, 1, 1);
    final session = await _store.begin(
        profileId: _profile, puzzle: puzzle, sessionId: 'failure-test');
    final store = _FailOnceStore();
    await tester.pumpWidget(_wrapped(LogicPuzzleScreen(
      appState: app,
      owner: owner,
      puzzle: puzzle,
      session: session,
      store: store,
    )));
    await _ticks(tester);
    final cell = puzzle.editableCells.first;
    await _enterCell(tester, puzzle, cell.index, cell.answer);
    expect(find.textContaining('noch nicht gespeichert'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('logic-input-1')))
            .onPressed,
        isNull);
    await _tap(
        tester, find.widgetWithText(LogicAction, 'Speichern wiederholen'));
    expect((await _store.load(_profile)).drafts[puzzle.id]!.answers[cell.index],
        cell.answer);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('logic-input-1')))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
