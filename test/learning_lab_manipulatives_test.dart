import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';

Future<void> _pumpBoard(
  WidgetTester tester,
  Widget child, {
  double width = 440,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 1000),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  ));
}

void main() {
  testWidgets('quantity moves real counters and parent reset restores the bank',
      (tester) async {
    var moved = 0;
    late StateSetter rebuild;
    await _pumpBoard(tester, StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return QuantityBridgeBoard(
        start: 7,
        addend: 5,
        moved: moved,
        onChanged: (value) => setState(() => moved = value),
      );
    }));

    expect(find.byKey(const ValueKey('quantity-bank-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('quantity-placed-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('quantity-bank-0')));
    await tester.pumpAndSettle();
    expect(moved, 1);
    expect(find.byKey(const ValueKey('quantity-placed-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('quantity-bank-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('quantity-add')));
    await tester.pumpAndSettle();
    expect(moved, 2);
    await tester.tap(find.byKey(const ValueKey('quantity-remove')));
    await tester.pumpAndSettle();
    expect(moved, 1);

    rebuild(() => moved = 0);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quantity-placed-0')), findsNothing);
    expect(find.byKey(const ValueKey('quantity-bank-0')), findsOneWidget);
    expect(find.textContaining('Bis 10 fehlen'), findsNothing);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('quantity clamps moves and reveals a gap only when requested',
      (tester) async {
    final changes = <int>[];
    await _pumpBoard(
      tester,
      QuantityBridgeBoard(
        start: 8,
        addend: 4,
        moved: 99,
        reveal: true,
        onChanged: changes.add,
      ),
    );
    expect(find.byKey(const ValueKey('quantity-bank-0')), findsNothing);
    expect(find.text('Bis 10 fehlen 2.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quantity-add')));
    await tester.pump();
    expect(changes, isEmpty);
    await tester.tap(find.byKey(const ValueKey('quantity-remove')));
    expect(changes, [3]);
    expect(find.byKey(const ValueKey('quantity-placed-3')), findsOneWidget);
  });

  testWidgets('fraction toggles individual equal pieces and resets from parent',
      (tester) async {
    var selected = <int>{};
    late StateSetter rebuild;
    await _pumpBoard(tester, StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return FractionBuildBoard(
        denominator: 4,
        selected: selected,
        onChanged: (value) => setState(() => selected = value),
      );
    }));
    await tester.tap(find.byKey(const ValueKey('fraction-piece-2')));
    await tester.pumpAndSettle();
    expect(selected, {2});
    await tester.tap(find.byKey(const ValueKey('fraction-piece-0')));
    await tester.pumpAndSettle();
    expect(selected, {0, 2});
    await tester.tap(find.byKey(const ValueKey('fraction-piece-2')));
    await tester.pumpAndSettle();
    expect(selected, {0});
    rebuild(() => selected = {1, 3});
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const ValueKey('fraction-piece-1'))),
      matchesSemantics(
        label: 'Teil 2 von 4',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('fraction visual pieces also toggle by position', (tester) async {
    var selected = <int>{};
    await _pumpBoard(tester, StatefulBuilder(builder: (context, setState) {
      return FractionBuildBoard(
        denominator: 4,
        selected: selected,
        onChanged: (value) => setState(() => selected = value),
      );
    }));
    final circle = tester.getRect(find.byKey(const ValueKey('fraction-disc')));
    await tester.tapAt(
        circle.center + Offset(circle.width * .23, -circle.height * .23));
    await tester.pumpAndSettle();
    expect(selected, {0});
  });

  testWidgets('token workbench preserves order, duplicates, undo, and reset',
      (tester) async {
    var selected = <int>[];
    late StateSetter rebuild;
    await _pumpBoard(tester, StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return LearningTokenWorkbench(
        tokens: const ['du', 'und', 'du'],
        selected: selected,
        onChanged: (value) => setState(() => selected = value),
      );
    }));
    await tester.tap(find.byKey(const ValueKey('token-bank-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('token-bank-0')));
    await tester.pumpAndSettle();
    expect(selected, [2, 0]);
    final first = tester.getTopLeft(find.byKey(const ValueKey('token-work-2')));
    final second =
        tester.getTopLeft(find.byKey(const ValueKey('token-work-0')));
    expect(first.dx, lessThan(second.dx));
    await tester.tap(find.byKey(const ValueKey('token-work-2')));
    await tester.pumpAndSettle();
    expect(selected, [0]);
    expect(find.byKey(const ValueKey('token-bank-2')), findsOneWidget);
    rebuild(() => selected = []);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('token-work-0')), findsNothing);
    expect(find.byKey(const ValueKey('token-bank-0')), findsOneWidget);
  });

  testWidgets('all actions have 48dp targets and keyboard activation',
      (tester) async {
    var moved = 0;
    await _pumpBoard(tester, StatefulBuilder(builder: (context, setState) {
      return QuantityBridgeBoard(
        start: 9,
        addend: 2,
        moved: moved,
        onChanged: (value) => setState(() => moved = value),
      );
    }));
    for (final key in ['quantity-add', 'quantity-remove', 'quantity-bank-0']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(moved, 1);
  });

  testWidgets('disabled boards keep answers unchanged', (tester) async {
    var callbacks = 0;
    await _pumpBoard(
        tester,
        Column(children: [
          QuantityBridgeBoard(
            start: 7,
            addend: 3,
            moved: 0,
            enabled: false,
            onChanged: (_) => callbacks++,
          ),
          FractionBuildBoard(
            denominator: 3,
            selected: const {},
            enabled: false,
            onChanged: (_) => callbacks++,
          ),
          LearningTokenWorkbench(
            tokens: const ['Ich', 'lerne'],
            selected: const [],
            enabled: false,
            onChanged: (_) => callbacks++,
          ),
        ]));
    await tester.tap(find.byKey(const ValueKey('quantity-bank-0')));
    await tester.tap(find.byKey(const ValueKey('fraction-piece-0')));
    await tester.ensureVisible(find.byKey(const ValueKey('token-bank-0')));
    await tester.tap(find.byKey(const ValueKey('token-bank-0')));
    expect(callbacks, 0);
  });

  testWidgets('fraction disc labels grow with system text size',
      (tester) async {
    Widget board() => FractionBuildBoard(
          denominator: 8,
          selected: const {},
          onChanged: (_) {},
        );
    Finder numeral() => find.descendant(
          of: find.byKey(const ValueKey('fraction-disc')),
          matching: find.text('1'),
        );
    await _pumpBoard(tester, board());
    final regular = tester.getSize(numeral()).height;
    await _pumpBoard(tester, board(), width: 280, textScale: 2);
    expect(tester.getSize(numeral()).height, greaterThan(regular * 1.8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every quantity button disables motion with the system setting',
      (tester) async {
    await _pumpBoard(
      tester,
      QuantityBridgeBoard(
        start: 7,
        addend: 5,
        moved: 2,
        onChanged: (_) {},
      ),
      disableAnimations: true,
    );
    for (final element in find.byType(TextButton).evaluate()) {
      final button = element.widget as TextButton;
      expect(button.style?.animationDuration, Duration.zero);
    }
  });

  testWidgets('all boards fit 280dp and large text with system reduced motion',
      (tester) async {
    final boards = <Widget>[
      QuantityBridgeBoard(
        start: 8,
        addend: 7,
        moved: 6,
        reveal: true,
        onChanged: (_) {},
      ),
      FractionBuildBoard(
        denominator: 8,
        selected: const {0, 2, 3, 6},
        onChanged: (_) {},
      ),
      LearningTokenWorkbench(
        tokens: const ['Schmetterlingsflügel', 'because', 'du', 'du'],
        selected: const [1, 2],
        onChanged: (_) {},
      ),
    ];
    for (final board in boards) {
      await _pumpBoard(tester, board,
          width: 280, textScale: 2, disableAnimations: true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
      for (final button in find.byType(TextButton).evaluate()) {
        final size = tester.getSize(find.byWidget(button.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    }
  });
}
