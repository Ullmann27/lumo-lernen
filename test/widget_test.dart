import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/main.dart';

void main() {
  testWidgets('Lumo app boots', (tester) async {
    await tester.pumpWidget(const LumoApp());
    expect(find.text('Lumo Lernen'), findsOneWidget);
    expect(find.text('Zur Lernwelt'), findsOneWidget);
  });
}
