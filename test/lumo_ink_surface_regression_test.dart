import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/writing/widgets/lumo_ink_surface.dart';

void main() {
  testWidgets('vertical letter stroke does not scroll its learning page',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final points = <Offset>[];
    var ended = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 420,
          child: SingleChildScrollView(
            controller: scroll,
            child: Column(children: [
              const SizedBox(height: 90),
              SizedBox(
                height: 210,
                child: LumoInkSurface(
                  key: const ValueKey('ink'),
                  onStart: points.add,
                  onUpdate: points.add,
                  onEnd: () => ended++,
                  onCancel: () {},
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
              const SizedBox(height: 620),
            ]),
          ),
        ),
      ),
    ));

    final start = tester.getCenter(find.byKey(const ValueKey('ink')));
    await tester.dragFrom(start, const Offset(0, -100));
    await tester.pump();
    expect(scroll.offset, 0,
        reason: 'The page must not jump while writing vertical letters');
    expect(points.length, greaterThan(1));
    expect(ended, 1);

    // Swiping OUTSIDE the ink canvas still scrolls the lesson normally.
    await tester.dragFrom(const Offset(50, 60), const Offset(0, -70));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
  });

  testWidgets('a second finger never creates a second ink stroke',
      (tester) async {
    final points = <Offset>[];
    var starts = 0;
    var ends = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: LumoInkSurface(
            onStart: (p) { starts++; points.add(p); },
            onUpdate: points.add,
            onEnd: () => ends++,
            onCancel: () {},
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    ));

    final first = await tester.startGesture(const Offset(350, 300));
    final second = await tester.startGesture(const Offset(360, 310));
    await first.moveBy(const Offset(0, 30));
    await second.moveBy(const Offset(0, 70));
    await second.up();
    await first.up();
    await tester.pump();

    expect(starts, 1);
    expect(ends, 1);
    expect(points.length, 2);
  });
}
