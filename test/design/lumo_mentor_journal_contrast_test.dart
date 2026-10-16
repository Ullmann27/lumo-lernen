import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/math/lumo_rechentricks.dart';
import 'package:lumo_lernen/features/learning/widgets/rechentricks_mentor_card.dart';
import 'package:lumo_lernen/features/journal/lumo_journal_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mentor calculation stays legible on dark hologlass', (tester) async {
    const tricks = LumoRechentricks();
    final exercise = tricks.explain(
      prompt: '2 + 7 = ?', correctAnswer: '9', grade: 1,
    );
    expect(exercise, isNotNull);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: RechentricksMentorCard(explanation: exercise!),
      )),
    ));
    final task = tester.widget<Text>(find.text('Aufgabe: 2 + 7 = ?'));
    expect(task.style?.color, Colors.white);
    final card = tester.widget<Container>(
      find.descendant(
        of: find.byType(RechentricksMentorCard),
        matching: find.byType(Container),
      ).first,
    );
    expect((card.decoration as BoxDecoration).gradient, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final size in <String, Size>{
    'fold-cover': const Size(320, 780),
    'phone': const Size(390, 840),
    'fold-open': const Size(860, 770),
    'large-text': const Size(320, 780),
  }.entries) {
    testWidgets('journal paper is readable on ${size.key}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(size.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(size.key == 'large-text' ? 1.6 : 1),
          ),
          child: child!,
        ),
        home: LumoJournalScreen(appState: state),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      expect(tester.widget<TextField>(fields.at(0)).style?.color,
          const Color(0xFF102943));
      expect(tester.widget<TextField>(fields.at(1)).style?.color,
          const Color(0xFF27415F));
      await tester.enterText(fields.at(1), 'Heute entdeckt Lumo einen Stern.');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
