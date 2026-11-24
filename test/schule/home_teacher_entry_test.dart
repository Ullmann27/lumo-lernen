import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/teacher_demo/demo_pin_dialog.dart';

void main() {
  testWidgets('PIN-Dialog der Lehrkräfte-Demo öffnet sich', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));
    final result = DemoPinDialog.show(ctx);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DemoPinDialog), findsOneWidget);
    Navigator.of(ctx).pop(false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(await result, isFalse);
  });
}
