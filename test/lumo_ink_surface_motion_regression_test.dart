import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/writing/widgets/lumo_ink_surface.dart';

void main() {
  testWidgets('an outside contact already down cannot move a new stylus stroke',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    final palm = await tester.startGesture(const Offset(40, 420));
    final pen = await tester.startGesture(
      tester.getCenter(find.byKey(_inkKey)),
      kind: PointerDeviceKind.stylus,
    );
    await pen.moveBy(const Offset(15, 20));
    await palm.moveBy(const Offset(0, -60));
    await palm.moveBy(const Offset(0, -60));
    await tester.pump();
    final offsetWhileDrawing = state.scroll.offset;
    await pen.up();
    await palm.up();
    await tester.pumpAndSettle();

    expect(state.starts, 1);
    expect(state.ends, 1);
    expect(state.cancels, 0);
    expect(offsetWhileDrawing, 0);
    await tester.dragFrom(const Offset(40, 420), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(state.scroll.offset, greaterThan(0));
  });

  testWidgets('ink starts on the first contact while the page is coasting',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    // Travel beyond the scroll physics' minimum fling distance so this
    // exercises a real ballistic activity, not an already idle page.
    await tester.flingFrom(const Offset(40, 420), const Offset(0, -100), 800);
    final offsetAtRelease = state.scroll.offset;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.scroll.position.isScrollingNotifier.value, isTrue);
    expect(state.scroll.offset, greaterThan(offsetAtRelease),
        reason: 'The paper must actually be moving before the pen lands');
    final stoppedOffset = state.scroll.offset;
    final pen = await tester.startGesture(
      tester.getCenter(find.byKey(_inkKey)),
      kind: PointerDeviceKind.stylus,
    );
    await pen.moveBy(const Offset(0, 25));
    await tester.pump(const Duration(milliseconds: 16));
    await pen.moveBy(const Offset(0, 25));
    await pen.up();
    await tester.pump();
    debugPrint('[InkMotion] coasting offset=$stoppedOffset '
        'after=${state.scroll.offset} starts=${state.starts} ends=${state.ends}');

    expect(state.starts, 1,
        reason: 'The first pen contact must draw, not start another page drag');
    expect(state.ends, 1);
    expect(state.scroll.offset, stoppedOffset);
  });

  testWidgets('a pen takes over from an already moving outside contact',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    final palm = await tester.startGesture(const Offset(40, 420));
    await palm.moveBy(const Offset(0, -30));
    await palm.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(state.scroll.offset, greaterThan(0));
    final stoppedOffset = state.scroll.offset;
    final pen = await tester.startGesture(
      tester.getCenter(find.byKey(_inkKey)),
      kind: PointerDeviceKind.stylus,
    );
    await pen.moveBy(const Offset(15, 20));
    await palm.moveBy(const Offset(0, -40));
    await tester.pump();
    final offsetWhileDrawing = state.scroll.offset;
    await pen.up();
    await palm.up();
    await tester.pump();
    debugPrint('[InkMotion] existing drag offset=$stoppedOffset '
        'during=$offsetWhileDrawing starts=${state.starts} ends=${state.ends}');

    expect(state.starts, 1);
    expect(state.ends, 1);
    expect(offsetWhileDrawing, stoppedOffset);
  });

  testWidgets('another canvas cannot replace the active drawing owner',
      (tester) async {
    var firstStarts = 0;
    var firstEnds = 0;
    var firstCancels = 0;
    var secondStarts = 0;
    Widget ink(Key key, bool first) => SizedBox(
          width: 250,
          height: 250,
          child: LumoInkSurface(
            key: key,
            onStart: (_) => first ? firstStarts++ : secondStarts++,
            onUpdate: (_) {},
            onEnd: () {
              if (first) firstEnds++;
            },
            onCancel: () {
              if (first) firstCancels++;
            },
            child: const ColoredBox(color: Colors.white),
          ),
        );
    const secondKey = ValueKey('second-ink-canvas');
    await tester.pumpWidget(MaterialApp(
      home: Row(children: [ink(_inkKey, true), ink(secondKey, false)]),
    ));
    final pen = await tester.startGesture(
      tester.getCenter(find.byKey(_inkKey)),
      kind: PointerDeviceKind.stylus,
    );
    final palm =
        await tester.startGesture(tester.getCenter(find.byKey(secondKey)));
    await palm.moveBy(const Offset(0, 30));
    await pen.moveBy(const Offset(10, 20));
    await palm.up();
    await pen.up();
    await tester.pump();
    expect(firstStarts, 1);
    expect(firstEnds, 1);
    expect(firstCancels, 0);
    expect(secondStarts, 0);
    await tester.dragFrom(
        tester.getCenter(find.byKey(secondKey)), const Offset(15, 25));
    await tester.pump();
    expect(secondStarts, 1);
  });

  testWidgets('scroll hit testing follows the lifetime of all mounted canvases',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var showFirst = true;
    var showSecond = true;
    var secondStarts = 0;
    var passiveContacts = 0;
    late StateSetter rebuild;
    const secondKey = ValueKey('remaining-ink-slot');
    Widget ink({bool second = false}) => LumoInkSurface(
          onStart: (_) {
            if (second) secondStarts++;
          },
          onUpdate: (_) {},
          onEnd: () {},
          onCancel: () {},
          child: const ColoredBox(color: Colors.white),
        );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return SingleChildScrollView(
            controller: scroll,
            physics: const ClampingScrollPhysics(),
            child: Column(children: [
              const SizedBox(height: 60),
              SizedBox(
                  width: 250, height: 120, child: showFirst ? ink() : null),
              const SizedBox(height: 40),
              SizedBox(
                key: secondKey,
                width: 250,
                height: 120,
                child: showSecond
                    ? ink(second: true)
                    : Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) => passiveContacts++,
                      ),
              ),
              const SizedBox(height: 900),
            ]),
          );
        }),
      ),
    ));

    final palm = await tester.startGesture(const Offset(40, 420));
    rebuild(() => showFirst = false);
    await tester.pump();
    final pen = await tester.startGesture(
        tester.getCenter(find.byKey(secondKey)),
        kind: PointerDeviceKind.stylus);
    await pen.moveBy(const Offset(0, 20));
    await pen.up();
    await palm.up();
    await tester.pump();
    expect(secondStarts, 1,
        reason: 'Removing one canvas must not disable another mounted canvas');

    rebuild(() => showSecond = false);
    await tester.pump();
    final outside = await tester.startGesture(const Offset(40, 420));
    await tester.tapAt(tester.getCenter(find.byKey(secondKey)));
    expect(passiveContacts, 0,
        reason:
            'Without ink, scrolling must restore its normal hit-test policy');
    await outside.up();
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byKey(secondKey)));
    expect(passiveContacts, 1,
        reason: 'The ordinary child must remain hittable after scrolling ends');
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing an active writing page releases its pointer owner',
      (tester) async {
    final previous = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: previous));
    final oldPen =
        await tester.startGesture(tester.getCenter(find.byKey(_inkKey)));
    await oldPen.moveBy(const Offset(10, 20));
    await tester.pumpWidget(const SizedBox.shrink());

    final next = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: next));
    final pen =
        await tester.startGesture(tester.getCenter(find.byKey(_inkKey)));
    await oldPen.up();
    await pen.moveBy(const Offset(10, 20));
    await pen.up();
    await tester.pump();
    expect(next.currentState!.starts, 1);
    expect(next.currentState!.ends, 1);
    expect(next.currentState!.cancels, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a second contact outside the canvas cannot scroll an ink stroke',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    final pen =
        await tester.startGesture(tester.getCenter(find.byKey(_inkKey)));
    await pen.moveBy(const Offset(15, 20));
    final palm = await tester.startGesture(const Offset(40, 420));
    await palm.moveBy(const Offset(0, -60));
    await palm.moveBy(const Offset(0, -60));
    await tester.pump();
    final offsetWhileDrawing = state.scroll.offset;
    await pen.moveBy(const Offset(15, 20));
    await palm.up();
    await pen.up();
    await tester.pumpAndSettle();

    expect(offsetWhileDrawing, 0,
        reason: 'An outside palm must not move the paper under the active pen');
    expect(state.starts, 1);
    expect(state.ends, 1);
    expect(state.cancels, 0);
    expect(state.points, [
      const Offset(160, 120),
      const Offset(175, 140),
      const Offset(190, 160),
    ]);

    await tester.dragFrom(const Offset(40, 420), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(state.scroll.offset, greaterThan(0),
        reason: 'Normal page scrolling must resume after the pen is lifted');
  });

  testWidgets('a layout translation cancels ink before it joins stale points',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    final pen =
        await tester.startGesture(tester.getCenter(find.byKey(_inkKey)));
    await pen.moveBy(const Offset(15, 20));
    state.moveCanvas(70);
    await tester.pump();
    await pen.moveBy(const Offset(15, 20));
    await pen.up();
    await tester.pump();

    expect(state.cancels, 1,
        reason: 'Coordinates from two canvas positions must not form one line');
    expect(state.ends, 0);
    expect(state.points.length, 2);

    await tester.dragFrom(
        tester.getCenter(find.byKey(_inkKey)), const Offset(15, 20));
    await tester.pump();
    expect(state.starts, 2);
    expect(state.ends, 1);
    expect(state.cancels, 1);
  });

  testWidgets('a resize before pointer up cancels the incomplete stroke',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    final pen =
        await tester.startGesture(tester.getCenter(find.byKey(_inkKey)));
    await pen.moveBy(const Offset(15, 20));
    state.resizeCanvas(260);
    await tester.pump();
    await pen.up();
    await tester.pump();

    expect(state.cancels, 1);
    expect(state.ends, 0,
        reason: 'A changed writing scale must not save an unfinished stroke');
  });

  testWidgets('ordinary parent rebuilds preserve the same active ink pointer',
      (tester) async {
    final host = GlobalKey<_InkHostState>();
    await tester.pumpWidget(_InkHost(key: host));
    final state = host.currentState!;
    final pen =
        await tester.startGesture(tester.getCenter(find.byKey(_inkKey)));
    await pen.moveBy(const Offset(15, 20));
    state.rebuild();
    await tester.pump();
    await pen.moveBy(const Offset(15, 20));
    await pen.up();
    await tester.pump();

    expect(state.points.length, 3);
    expect(state.starts, 1);
    expect(state.ends, 1);
    expect(state.cancels, 0);
    expect(state.scroll.offset, 0);
  });
}

const _inkKey = ValueKey('motion-regression-ink');

class _InkHost extends StatefulWidget {
  const _InkHost({super.key});

  @override
  State<_InkHost> createState() => _InkHostState();
}

class _InkHostState extends State<_InkHost> {
  final scroll = ScrollController();
  final points = <Offset>[];
  var starts = 0;
  var ends = 0;
  var cancels = 0;
  double topSpace = 120;
  double canvasWidth = 320;

  void moveCanvas(double distance) => setState(() => topSpace += distance);
  void resizeCanvas(double width) => setState(() => canvasWidth = width);
  void rebuild() => setState(() {});

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scroll,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: topSpace),
              Center(
                child: SizedBox(
                  width: canvasWidth,
                  height: 240,
                  child: LumoInkSurface(
                    key: _inkKey,
                    onStart: (point) {
                      starts++;
                      points.add(point);
                    },
                    onUpdate: points.add,
                    onEnd: () => ends++,
                    onCancel: () => cancels++,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );
  }
}
