import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('first mistake has a second chance and no saved attempt',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: CrossGradePracticeScreen(
      profileName: 'SecondChance', enrolledGrade: 2, lessonGrade: 3,
      subject: 'Mathematik', unit: 'Plus bis 1000',
    )));
    await tester.pump(const Duration(milliseconds: 400));
    final prompt = tester.widget<Text>(
      find.byKey(const ValueKey('cross-grade-question'))).data!;
    // Classic "a + b = ?" or the missing-number form "a + ? = c".
    final match =
        RegExp(r'(\d+)\s*\+\s*(\d+|\?)\s*=\s*(\d+|\?)').firstMatch(prompt);
    expect(match, isNotNull, reason: prompt);
    final answer = match!.group(2) == '?'
        ? int.parse(match.group(3)!) - int.parse(match.group(1)!)
        : int.parse(match.group(1)!) + int.parse(match.group(2)!);
    final choices = <String>[];
    for (var i = 0; i < 4; i++) {
      final button = tester.widget<OutlinedButton>(
        find.byKey(ValueKey('cross-grade-choice-$i')));
      choices.add((button.child! as Text).data!);
    }
    final wrong = choices.indexWhere((s) => s != '$answer');
    final correct = choices.indexOf('$answer');
    expect(wrong, greaterThanOrEqualTo(0));
    expect(correct, greaterThanOrEqualTo(0));
    await tester.tap(find.byKey(ValueKey('cross-grade-choice-$wrong')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('cross-grade-explanation')), findsNothing);
    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cross-grade-next')));
    expect(next.onPressed, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('cross_grade_practice_v1:secondchance:3:Mathematik:Plus bis 1000:answered'), isNull);
    await tester.tap(find.byKey(ValueKey('cross-grade-choice-$correct')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('cross-grade-explanation')), findsOneWidget);
    expect(prefs.getInt('cross_grade_practice_v1:secondchance:3:Mathematik:Plus bis 1000:answered'), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
