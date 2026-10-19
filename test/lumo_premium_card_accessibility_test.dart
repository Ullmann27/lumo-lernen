import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/premium/lumo_premium_card.dart';

void main() {
  testWidgets('interactive premium cards activate with keyboard and semantics',
      (tester) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: LumoPremiumCard(onTap: () => taps++, child: const Text('Lesen')),
    ))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
    expect(
        tester.getSemantics(find.text('Lesen')),
        matchesSemantics(
          label: 'Lesen',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          isFocused: true,
          hasFocusAction: true,
        ));
    semantics.dispose();
  });

  testWidgets('reduced motion keeps premium cards still during a press',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(
          body: LumoPremiumCard(onTap: () {}, child: const Text('Lesen'))),
    )));
    final before = tester.getRect(find.text('Lesen'));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Lesen')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getRect(find.text('Lesen')), before);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
