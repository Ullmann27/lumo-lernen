import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_widgets.dart';

void main() {
  testWidgets('shared widget barrel exports modern widgets', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const LumoModernCard(child: Text('Card')),
              LumoPrimaryCta(label: 'Start', onPressed: () => tapped = true),
              const LumoStatPill(value: '24', label: 'Sterne'),
              const LumoMissionCard(
                title: 'Mission',
                description: 'Drei Aufgaben lösen',
                progress: .5,
                progressLabel: '1 / 2',
              ),
              LumoSubjectCard(
                title: 'Deutsch',
                description: 'Wörter üben',
                progress: .4,
                progressLabel: '8 / 20',
                accentColor: Colors.orange,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Card'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Mission'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
