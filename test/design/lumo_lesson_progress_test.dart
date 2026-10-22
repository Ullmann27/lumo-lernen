import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_lesson_progress.dart';
import 'package:lumo_lernen/widgets/design/lumo_motion.dart';

Widget _host(double value, {bool quiet = false, bool visible = true}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: quiet),
        child: TickerMode(
          enabled: visible,
          child: Center(
            child: SizedBox(
              width: 280,
              child: LumoLessonProgress(value: value, totalTasks: 30),
            ),
          ),
        ),
      ),
    );

double _visibleValue(WidgetTester tester) {
  final tween = tester.widget<TweenAnimationBuilder<double>>(
    find.byType(TweenAnimationBuilder<double>),
  );
  // Read the animation's actual rendered value through its paint delegate.
  // Its constructor is private but its value is an ordinary public field.
  expect(tween.duration, isNotNull);
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(LumoLessonProgress),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter as dynamic).value as double;
}

void main() {
  setUp(() => LumoMotion.appReduced = false);
  tearDown(() => LumoMotion.appReduced = false);

  testWidgets('starts at real progress and animates only a changed value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_host(.2));
    expect(_visibleValue(tester), .2);
    expect(find.bySemanticsLabel('Lernfortschritt'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LumoLessonProgress)).value,
      '20 Prozent',
    );
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(_host(.6));
    await tester.pump(const Duration(milliseconds: 250));
    expect(_visibleValue(tester), greaterThan(.2));
    expect(_visibleValue(tester), lessThan(.6));
    await tester.pumpAndSettle();
    expect(_visibleValue(tester), .6);
    expect(tester.binding.transientCallbackCount, 0);
    semantics.dispose();
  });

  testWidgets(
    'reduced animation snaps to live data, including mid-transition',
    (tester) async {
      await tester.pumpWidget(_host(.1));
      await tester.pumpWidget(_host(.8));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_host(.8, quiet: true));
      await tester.pump();
      expect(_visibleValue(tester), .8);
      expect(tester.binding.transientCallbackCount, 0);

      LumoMotion.appReduced = true;
      await tester.pumpWidget(_host(.4));
      await tester.pump();
      expect(_visibleValue(tester), .4);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('hidden routes mute ticking and disposal leaves no work', (
    tester,
  ) async {
    await tester.pumpWidget(_host(.1));
    await tester.pumpWidget(_host(.9));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(.9, visible: false));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(_host(.9));
    await tester.pumpAndSettle();
    expect(_visibleValue(tester), .9);
    await tester.pumpWidget(_host(.2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
