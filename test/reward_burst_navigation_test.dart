import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/premium/lumo_reward_burst.dart';

void main() {
  testWidgets('dismissed reward cannot pop a subsequently opened page',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: const Scaffold(body: Text('Home')),
    ));
    showLumoRewardBurst(tester.element(find.text('Home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    key.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 300));
    key.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('New page'))));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('New page'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
