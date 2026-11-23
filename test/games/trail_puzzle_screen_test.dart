import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/logic/trail_puzzle.dart';
import 'package:lumo_lernen/features/games/logic/trail_progress_store.dart';
import 'package:lumo_lernen/features/games/logic/trail_puzzle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
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
      {int grade = 1, int level = 1, double textScale = 1}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale), disableAnimations: true),
        child: child!,
      ),
      home: TrailPuzzleScreen(
          appState: app, initialGrade: grade, initialLevel: level),
    ));
    await tester.pumpAndSettle();
  }

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
        matching: find.text('${route.length} ${route.last.arrow}'));
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
