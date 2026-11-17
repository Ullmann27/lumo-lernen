import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_quantity_workbenches.dart';

Future<void> showBoard(WidgetTester tester, Widget board,
    {double width = 344, double scale = 1.4}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
    data: MediaQueryData(
        size: Size(width, 900), textScaler: TextScaler.linear(scale)),
    child: Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16), child: board)),
  )));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('subtraction changes only the chosen candy and supports undo',
      (tester) async {
    var removed = <int>{};
    await showBoard(
        tester,
        StatefulBuilder(
            builder: (context, setState) => LumoSubtractionWorkbench(
                start: 8,
                takeAway: 3,
                removed: removed,
                onChanged: (next) => setState(() => removed = next))));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    for (final index in [7, 2, 4]) {
      await tester.tap(find.byKey(ValueKey('minus-quantity-$index')));
      await tester.pumpAndSettle();
    }
    expect(removed, {7, 2, 4});
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(3));
    expect(find.text('Weggenommen: 3 · Auftrag: 3'), findsOneWidget);
    expect(find.textContaining('5 übrig'), findsNothing,
        reason: 'The child counts the result; the visual does not answer.');
    await tester.tap(find.byKey(const ValueKey('minus-quantity-2')));
    await tester.pumpAndSettle();
    expect(removed, {7, 4});
    for (var i = 0; i < 8; i++) {
      final size = tester.getSize(find.byKey(ValueKey('minus-quantity-$i')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    await tester
        .ensureVisible(find.byKey(const ValueKey('minus-workbench-reset')));
    await tester.tap(find.byKey(const ValueKey('minus-workbench-reset')));
    await tester.pumpAndSettle();
    expect(removed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'subtraction reports extra removal without declaring a wrong answer',
      (tester) async {
    await showBoard(
        tester,
        LumoSubtractionWorkbench(
            start: 8,
            takeAway: 2,
            removed: const {0, 1, 2, 100},
            onChanged: (_) {}));
    expect(find.text('Weggenommen: 3 · Auftrag: 2'), findsOneWidget);
    expect(find.textContaining('Du hast mehr weggenommen'), findsOneWidget);
    expect(find.textContaining('Falsch'), findsNothing);
  });

  testWidgets('10 × 10 contains exactly 100 actual stones in ten groups',
      (tester) async {
    var counted = <int>{};
    await showBoard(
        tester,
        StatefulBuilder(
            builder: (context, setState) => LumoEqualGroupsWorkbench(
                groups: 10,
                perGroup: 10,
                counted: counted,
                onChanged: (next) => setState(() => counted = next))));
    for (var group = 0; group < 10; group++) {
      expect(find.byKey(ValueKey('times-group-$group')), findsOneWidget);
      for (var stone = 0; stone < 10; stone++) {
        expect(find.byKey(ValueKey('times-group-$group-stone-$stone')),
            findsOneWidget);
      }
    }
    expect(find.text('100'), findsNothing,
        reason: 'The sum is not declared before the answer.');
    await tester.tap(find.byKey(const ValueKey('times-group-0')));
    await tester.pumpAndSettle();
    expect(counted, {0});
    expect(find.text('1 von 10 Gruppen markiert'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('times-group-0')));
    await tester.pumpAndSettle();
    expect(counted, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'group model fits small, cover and inner displays with readable targets',
      (tester) async {
    for (final width in [320.0, 344.0, 840.0]) {
      await showBoard(
          tester,
          LumoEqualGroupsWorkbench(
              groups: 7, perGroup: 8, counted: const {}, onChanged: (_) {}),
          width: width);
      for (var group = 0; group < 7; group++) {
        final rect = tester.getRect(find.byKey(ValueKey('times-group-$group')));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('disabled workbenches reject taps while persistence is pending',
      (tester) async {
    var changed = 0;
    await showBoard(
        tester,
        Column(children: [
          LumoSubtractionWorkbench(
              start: 3,
              takeAway: 1,
              removed: const {},
              enabled: false,
              onChanged: (_) => changed++),
          LumoEqualGroupsWorkbench(
              groups: 2,
              perGroup: 3,
              counted: const {},
              enabled: false,
              onChanged: (_) => changed++),
        ]));
    await tester.tap(find.byKey(const ValueKey('minus-quantity-0')));
    await tester.ensureVisible(find.byKey(const ValueKey('times-group-0')));
    await tester.tap(find.byKey(const ValueKey('times-group-0')));
    expect(changed, 0);
    expect(tester.takeException(), isNull);
  });
}
