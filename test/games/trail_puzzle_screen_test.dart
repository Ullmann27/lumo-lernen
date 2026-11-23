import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/logic/trail_puzzle.dart';
import 'package:lumo_lernen/features/games/logic/trail_progress_store.dart';
import 'package:lumo_lernen/features/games/logic/trail_puzzle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _expectVisiblePlanner(WidgetTester tester, Size viewport,
    {double minimumBoard = 190}) {
  final board = tester.getRect(find.byKey(const ValueKey('trail-board')));
  expect(board.width, greaterThanOrEqualTo(minimumBoard));
  expect(board.height, closeTo(board.width, .1));
  expect(board.left, greaterThanOrEqualTo(0));
  expect(board.right, lessThanOrEqualTo(viewport.width));
  expect(board.top, greaterThanOrEqualTo(80));
  for (final key in [
    for (final direction in TrailDirection.values)
      'trail-add-${direction.name}',
    'trail-run',
    'trail-choose',
    'trail-guide',
    'trail-undo',
    'trail-hint',
  ]) {
    final rect = tester.getRect(find.byKey(ValueKey(key)));
    expect(rect.width, greaterThanOrEqualTo(48), reason: key);
    expect(rect.height, greaterThanOrEqualTo(48), reason: key);
    expect(rect.left, greaterThanOrEqualTo(0), reason: key);
    expect(rect.right, lessThanOrEqualTo(viewport.width), reason: key);
    expect(rect.top, greaterThanOrEqualTo(24), reason: key);
    expect(rect.bottom, lessThanOrEqualTo(viewport.height - 24), reason: key);
    if (key.startsWith('trail-add-')) {
      expect(board.bottom, lessThanOrEqualTo(rect.top), reason: key);
    }
  }
  expect(tester.takeException(), isNull);
}

class _ControlledTrailStore extends TrailProgressStore {
  Completer<void>? pending;
  bool failCompletion = false;

  @override
  Future<TrailProgress> savePlan({
    required String profileId,
    required TrailPuzzle puzzle,
    required List<TrailDirection> commands,
    bool complete = false,
  }) async {
    final gate = pending;
    if (gate != null) await gate.future;
    if (complete && failCompletion) {
      failCompletion = false;
      throw StateError('Simulated completion write failure');
    }
    return super.savePlan(
      profileId: profileId,
      puzzle: puzzle,
      commands: commands,
      complete: complete,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(TrailProgressStore.flushPendingWrites);

  Future<LumoAppState> prepare() async {
    final app = LumoAppState();
    await app.school.setActiveStudent('child-a');
    await app.loadLearningProfile();
    app.state.settings = app.state.settings
        .copyWith(soundEnabled: false, reduceAnimations: true);
    return app;
  }

  Future<void> open(WidgetTester tester, LumoAppState app,
      {int grade = 1,
      int level = 1,
      double textScale = 1,
      EdgeInsets safePadding = EdgeInsets.zero,
      TrailProgressStore store = const TrailProgressStore()}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
            padding: safePadding,
            viewPadding: safePadding),
        child: child!,
      ),
      home: TrailPuzzleScreen(
          appState: app, initialGrade: grade, initialLevel: level, store: store),
    ));
    await tester.pumpAndSettle();
  }

  for (final width in [344.0, 390.0]) {
    for (final grade in [1, 4]) {
      testWidgets(
          '${width.toInt()}x800 grade $grade keeps the whole board and arrows visible while planning',
          (tester) async {
        final viewport = Size(width, 800);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = await prepare();
        const padding = EdgeInsets.only(top: 24, bottom: 24);
        await open(tester, app, grade: grade, level: 6, safePadding: padding);
        _expectVisiblePlanner(tester, viewport);
        for (final direction in TrailDirection.values) {
          final button = find.byKey(ValueKey('trail-add-${direction.name}'));
          expect(button.hitTestable(), findsOneWidget);
          // No ensureVisible: the child must plan without moving the board.
          await tester.tap(button);
          await tester.pumpAndSettle();
          _expectVisiblePlanner(tester, viewport);
        }
        await tester.pumpWidget(const SizedBox());
        final puzzle = TrailCatalog.puzzle(grade, 6);
        await const TrailProgressStore().savePlan(
          profileId: 'child-a',
          puzzle: puzzle,
          commands: List.filled(TrailCatalog.maxCommands, TrailDirection.right),
        );
        await open(tester, app, grade: grade, level: 6, safePadding: padding);
        _expectVisiblePlanner(tester, viewport);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('trail-program')),
            matching: find.byWidgetPredicate((widget) =>
                widget is Semantics &&
                widget.properties.label == 'Schritt 64: Rechts'),
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
    }
  }

  testWidgets('compact chooser and complete help remain reachable',
      (tester) async {
    const viewport = Size(344, 800);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await prepare();
    await open(tester, app,
        safePadding: const EdgeInsets.only(top: 24, bottom: 24));
    await _tap(tester, 'trail-choose');
    await _tap(tester, 'trail-grade-4');
    await _tap(tester, 'trail-level-6');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Pfad 6 · Klasse 4 · Wählen'), findsOneWidget);
    _expectVisiblePlanner(tester, viewport);
    await _tap(tester, 'trail-hint');
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
        find.descendant(
            of: sheet,
            matching: find.textContaining('Jeder Lauf beginnt wieder an der Startpfote.')),
        findsOneWidget);
    expect(
        find.descendant(of: sheet, matching: find.textContaining('in Reihe')),
        findsOneWidget);
    await _tap(tester, 'trail-guide-close');
    _expectVisiblePlanner(tester, viewport);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('profile changes invalidate an open compact chooser',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await prepare();
    await open(tester, app);
    await _tap(tester, 'trail-choose');
    await _tap(tester, 'trail-grade-4');
    await app.school.setActiveStudent('child-b');
    await app.loadLearningProfile();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trail-level-6')), findsNothing);
    expect(find.textContaining('Das Lernprofil wurde gewechselt'), findsWidgets);
    const store = TrailProgressStore();
    expect((await store.load('child-a')).plans, isEmpty);
    expect((await store.load('child-b')).plans, isEmpty);
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trail-run')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('saving, failed completion and retry keep the compact plan usable',
      (tester) async {
    const viewport = Size(344, 800);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await prepare();
    final puzzle = TrailCatalog.puzzle(4, 6);
    final route = TrailSolver.shortestPlan(puzzle)!;
    await const TrailProgressStore().savePlan(
      profileId: 'child-a', puzzle: puzzle, commands: route,
    );
    final store = _ControlledTrailStore()..failCompletion = true;
    await open(tester, app, grade: 4, level: 6, store: store,
        safePadding: const EdgeInsets.only(top: 24, bottom: 24));
    final boardBefore = tester.getRect(find.byKey(const ValueKey('trail-board')));
    final gate = Completer<void>();
    store.pending = gate;
    await tester.tap(find.byKey(const ValueKey('trail-add-right')));
    await tester.pump();
    expect(tester.getRect(find.byKey(const ValueKey('trail-board'))), boardBefore,
        reason: 'A pending save must not resize the board after each arrow.');
    _expectVisiblePlanner(tester, viewport);
    gate.complete();
    store.pending = null;
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trail-run')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Picknick erreicht!'), findsOneWidget);
    expect(find.textContaining('noch nicht gespeichert'), findsOneWidget);
    _expectVisiblePlanner(tester, viewport, minimumBoard: 100);
    final next = find.descendant(
        of: find.byKey(const ValueKey('trail-next')),
        matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    final retry = find.widgetWithText(FilledButton, 'Speichern erneut versuchen');
    final retryRect = tester.getRect(retry);
    expect(retryRect.height, greaterThanOrEqualTo(48));
    expect(retryRect.bottom, lessThanOrEqualTo(viewport.height - 24));
    expect(retry.hitTestable(), findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.textContaining('noch nicht gespeichert'), findsNothing);
    expect((await store.load('child-a')).completed, contains(puzzle.id));
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    _expectVisiblePlanner(tester, viewport);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets(
      'phone: actual arrow taps finish a route and reopen its saved plan',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await prepare();
    await open(tester, app);
    final puzzle = TrailCatalog.puzzle(1, 1);
    final route = TrailSolver.shortestPlan(puzzle)!;
    for (final command in route) {
      await _tap(tester, 'trail-add-${command.name}');
    }
    await _tap(tester, 'trail-run');
    expect(find.textContaining('Picknick erreicht!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    const store = TrailProgressStore();
    expect((await store.load('child-a')).completed, {puzzle.id});
    expect((await store.load('child-b')).completed, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await open(tester, app);
    expect((await store.load('child-a')).plans[puzzle.id], route);
    final program = find.descendant(
        of: find.byKey(const ValueKey('trail-program')),
        matching: find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Schritt ${route.length}: ${route.last.label}'));
    expect(program, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('a boundary error keeps the program editable without completion',
      (tester) async {
    final app = await prepare();
    await open(tester, app);
    final puzzle = TrailCatalog.puzzle(1, 1);
    final invalid = TrailDirection.values.firstWhere(
        (direction) => puzzle.neighbor(puzzle.start, direction) == null);
    await _tap(tester, 'trail-add-${invalid.name}');
    await _tap(tester, 'trail-run');
    expect(find.textContaining('führt über den Rand'), findsOneWidget);
    expect(
        (await const TrailProgressStore().load('child-a')).completed, isEmpty);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('fold layout and large text keep arrow actions at least 48 dp',
      (tester) async {
    final app = await prepare();
    for (final size in [const Size(344, 882), const Size(1000, 750)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const SizedBox());
      await open(tester, app, grade: 4, level: 6, textScale: 1.4);
      for (final direction in TrailDirection.values) {
        final finder = find.byKey(ValueKey('trail-add-${direction.name}'));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        final actual = tester.getSize(finder);
        expect(actual.width, greaterThanOrEqualTo(48));
        expect(actual.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull, reason: '$size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('a profile switch blocks stale controls and preserves both saves',
      (tester) async {
    final app = await prepare();
    await open(tester, app);
    await _tap(tester, 'trail-add-right');
    await app.school.setActiveStudent('child-b');
    await app.loadLearningProfile();
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Das Lernprofil wurde gewechselt'), findsOneWidget);
    expect(find.byKey(const ValueKey('trail-run')), findsNothing);
    const store = TrailProgressStore();
    expect((await store.load('child-a')).plans, isNotEmpty);
    expect((await store.load('child-b')).plans, isEmpty);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
