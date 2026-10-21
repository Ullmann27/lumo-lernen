import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/lumo_rechentricks_poster_screen.dart';

void main() {
  testWidgets('One mentor, one example, and one step at a time',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: LumoRechentricksPosterScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lumos Trick-Werkstatt'), findsOneWidget);
    expect(find.text('Wer hilft dir heute?'), findsOneWidget);
    expect(find.byKey(const ValueKey('tricks-task')), findsOneWidget);
    expect(find.byKey(const ValueKey('tricks-result')), findsNothing);
    expect(find.text('Emma sagt:'), findsNothing);
    expect(find.text('5 schlaue Wege zur Antwort'), findsNothing);
    expect(find.byKey(const ValueKey('tricks-lesson')), findsOneWidget);

    final firstStep = find.textContaining('Vertausche:');
    expect(firstStep, findsOneWidget);
    final next = find.byKey(const ValueKey('tricks-next'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.textContaining('Schritte weiterzaehlen'), findsOneWidget);
    expect(find.byKey(const ValueKey('tricks-result')), findsNothing);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tricks-result')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact screen reveals advanced tricks only on request',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: LumoRechentricksPosterScreen()),
    );
    await tester.pumpAndSettle();
    final advanced = find.byKey(const ValueKey('tricks-more-mentors'));
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(find.text('Leichte Tricks zeigen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
