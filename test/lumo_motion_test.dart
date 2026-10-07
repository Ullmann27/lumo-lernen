import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_motion.dart';

void main() {
  Widget host(Widget child, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(body: Center(child: child)),
        ),
      );

  double scaleOf(WidgetTester tester) {
    final transforms = tester.widgetList<Transform>(find.descendant(
        of: find.byType(LumoPressable), matching: find.byType(Transform)));
    // Kleinster Maßstab: der Button selbst kann eigene Transforms enthalten.
    return transforms.fold<double>(
        1, (m, t) => t.transform.storage[0] < m ? t.transform.storage[0] : m);
  }

  testWidgets('Druck federt sofort ein, Tap kommt unverzögert an',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(LumoPressable(
      child: ElevatedButton(onPressed: () => taps++, child: const Text('Los')),
    )));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Los')));
    await tester.pump();
    await tester.pump(LumoMotion.press);
    expect(scaleOf(tester), lessThan(.97));
    await gesture.up();
    await tester.pump();
    expect(taps, 1, reason: 'Aktion läuft nicht erst nach der Animation');
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
  });

  testWidgets('reduzierte Animationen: keine Federbewegung', (tester) async {
    await tester.pumpWidget(host(
      LumoPressable(
          child: ElevatedButton(onPressed: () {}, child: const Text('Los'))),
      reduced: true,
    ));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Los')));
    await tester.pump();
    await tester.pump(LumoMotion.press);
    expect(scaleOf(tester), 1);
    await gesture.up();
  });

  testWidgets('Werte laufen vom alten zum neuen echten Wert', (tester) async {
    Widget bar(double v) => host(LumoAnimatedValue(
          value: v,
          builder: (_, x) => Text(x.toStringAsFixed(2)),
        ));
    await tester.pumpWidget(bar(.2));
    expect(find.text('0.20'), findsOneWidget,
        reason: 'erster Aufbau zeigt sofort den echten Wert');
    await tester.pumpWidget(bar(.8));
    await tester.pump(LumoMotion.value ~/ 2);
    final mid = double.parse(tester.widget<Text>(find.byType(Text)).data!);
    expect(mid, greaterThan(.2));
    expect(mid, lessThan(.8));
    await tester.pumpAndSettle();
    expect(find.text('0.80'), findsOneWidget);
  });

  testWidgets('Karten erscheinen gestaffelt; reduziert sofort sichtbar',
      (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      LumoEntrance(index: 0, child: Text('A')),
      LumoEntrance(index: 3, child: Text('B')),
    ])));
    await tester.pump(const Duration(milliseconds: 60));
    final fades =
        tester.widgetList<FadeTransition>(find.byType(FadeTransition)).toList();
    expect(fades.first.opacity.value, greaterThan(fades.last.opacity.value));
    await tester.pumpAndSettle();
    expect(fades.last.opacity.value, 1);

    await tester.pumpWidget(
        host(const LumoEntrance(index: 5, child: Text('C')), reduced: true));
    await tester.pump();
    expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        1);
  });
}
