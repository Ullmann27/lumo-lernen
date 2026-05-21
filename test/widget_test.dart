import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/main.dart';

void main() {
  testWidgets('Lumo app boots', (tester) async {
    await tester.pumpWidget(const LumoApp());
    // Pump genug damit async init durch ist (Profile-Load, etc).
    await tester.pump(const Duration(milliseconds: 100));
    // Bei frischer Installation zeigt sich der Onboarding-Screen.
    // 'Lumo Lernen' Titel ist in MaterialApp + Onboarding-Step.
    expect(find.text('Lumo Lernen'), findsWidgets);
  });
}
