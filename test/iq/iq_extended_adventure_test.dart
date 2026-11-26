import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:lumo_lernen/features/tests/iq_test_screen.dart';

import 'iq_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIqFonts);
  setUp(() async => resetIqEnvironment());

  test('Long adventure includes six domains and 36 real adaptive puzzles', () {
    final session = IqTestSession(grade: 3, seed: 1987, itemsPerArea: 6);
    expect(session.totalItems, 36);
    expect(session.atAreaStart, isTrue);
    for (var i = 0; i < 36; i++) {
      expect(session.area, IqArea.values[i ~/ 6]);
      expect(session.itemInArea, i % 6 + 1);
      final puzzle = session.current;
      final response = switch (puzzle) {
        IqChoicePuzzle p => [p.answer],
        IqMemoryPuzzle p => p.sequence,
      };
      expect(session.answer(response, durationMs: 4000), isTrue);
      if (i < 35) expect(session.atAreaStart, (i + 1) % 6 == 0);
    }
    expect(session.finished, isTrue);
    expect(session.records, hasLength(36));
    expect(session.answered, hasLength(36));
    final result = session.result(
      id: 'extended-1987',
      studentId: 'local-test',
      finishedAt: DateTime(2026, 10, 19),
      durationMs: 144000,
    );
    expect(result.version, endsWith('-explorer36'));
    expect(IqTestSession(grade: 3, seed: 1987).result(
      id: 'short', studentId: 'local-test',
      finishedAt: DateTime(2026, 10, 19), durationMs: 0,
    ).version, IqTestSession.version);
    expect(result.items, hasLength(36));
    expect(result.items.map((item) => item.puzzleId).toSet(), hasLength(36));
  });

  testWidgets('Explorer button creates 36 tasks, normal start keeps 24',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = iqTestApp();
    addTearDown(state.dispose);
    await tester.pumpWidget(iqScreenApp(state, textScale: 1.6));
    await tester.pump(const Duration(milliseconds: 400));
    for (final key in ['iq-start-button', 'iq-extended-button']) {
      final button = find.byKey(ValueKey(key));
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    }
    expect(find.text('24 Rätsel starten'), findsOneWidget);
    expect(find.text('36 Rätsel entdecken'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('iq-extended-button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bereich 1 von 6'), findsWidgets);
    expect(find.textContaining('36'), findsWidgets,
        reason: 'The real extended test should expose 36 in progress.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('short landscape fits the actual title and both rounds',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(882, 344));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = iqTestApp();
    addTearDown(state.dispose);
    await tester.pumpWidget(iqScreenApp(state));
    await settleIq(tester);
    final title = tester.getRect(find.text('Lumo Knobel-Test'));
    final short = find.byKey(const ValueKey('iq-start-button'));
    final extended = find.byKey(const ValueKey('iq-extended-button'));
    expect(title.bottom, lessThan(tester.getRect(short).top));
    expect(short.hitTestable(), findsOneWidget);
    expect(extended.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
