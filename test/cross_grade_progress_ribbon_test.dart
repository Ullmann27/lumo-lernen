import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/learning/widgets/cross_grade_visual_scene.dart';

void main() {
  testWidgets('real progress responds to values on narrow Fold cover',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(12),
            child: CrossGradeProgressRibbon(answered: 8, correct: 6),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('75 %'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('cross-grade-progress-bar')),
    ).value, closeTo(.75, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero attempts never invent XP or cause a divide by zero',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CrossGradeProgressRibbon(answered: 0, correct: 0)),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0 %'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
