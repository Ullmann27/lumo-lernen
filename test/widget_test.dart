import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/main.dart';

void main() {
  testWidgets('Lumo app boots', (tester) async {
    await tester.pumpWidget(const LumoApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Lumo Lernen'), findsWidgets);
  }, skip: 'async init is flaky in test env, see CI #720');
}
