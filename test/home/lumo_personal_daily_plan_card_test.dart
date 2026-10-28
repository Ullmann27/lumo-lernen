import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_personal_daily_tutor_planner.dart';
import 'package:lumo_lernen/features/home/widgets/lumo_personal_daily_plan_card.dart';

void main() {
  testWidgets('narrow Fold card exposes full subjects and actionable 48dp targets',
      (tester) async {
    final steps = [
      const LumoDailyTutorStep(
        kind: LumoDailyTutorStepKind.revise,
        subject: 'Mathematik',
        unit: 'Zehner und Einer',
        durationMinutes: 5,
      ),
      const LumoDailyTutorStep(
        kind: LumoDailyTutorStepKind.confidence,
        subject: 'Lesen',
        unit: 'Silben',
        durationMinutes: 3,
      ),
    ];
    LumoDailyTutorStep? chosen;
    await tester.binding.setSurfaceSize(const Size(280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: LumoPersonalDailyPlanCard(
              steps: steps,
              onStart: (step) => chosen = step,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Heute mit Lumo'), findsOneWidget);
    expect(find.text('Mathematik · Zehner und Einer'), findsOneWidget);
    final start = find.byKey(const ValueKey('lumo-daily-plan-start-0'));
    expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
    await tester.tap(start);
    await tester.pump();
    expect(chosen?.unit, 'Zehner und Einer');
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty profile never renders a fictional plan', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoPersonalDailyPlanCard(
          steps: const [],
          onStart: (_) {},
        ),
      ),
    ));
    expect(find.text('Heute mit Lumo'), findsNothing);
    expect(find.byKey(const ValueKey('lumo-personal-daily-plan')),
        findsNothing);
  });
}
