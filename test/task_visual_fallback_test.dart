import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

/// Das Mengenbild erscheint nur, wenn es wirklich zur Rechnung passt.
void main() {
  Future<void> show(WidgetTester tester, String prompt, String answer) async {
    final task = LumoTask(
      id: 't',
      grade: 1,
      subject: 'Mathematik',
      unit: 'Test',
      prompt: prompt,
      choices: [answer, '1', '2', '3'],
      answer: answer,
      explanation: 'Weil es so ist.',
    );
    final instance = const LegacyLumoTaskAdapter()
        .toTaskInstance(task: task, childId: 'k', difficulty: 1);
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: AdaptiveTaskRenderer(task: instance)))));
    await tester.pump();
  }

  testWidgets('einfache Plus-Geschichte zeigt das Mengenbild', (tester) async {
    await show(tester, 'Mia hat 3 Äpfel und findet 4 dazu. Wie viele sind es?', '7');
    expect(find.text('Mengenbild'), findsOneWidget);
  });

  testWidgets('Zahlenmauer und große Zahlen zeigen kein falsches Mengenbild',
      (tester) async {
    await show(tester,
        'Unten liegen 3, 5 und 3. Welche Zahl steht ganz oben?', '16');
    expect(find.text('Mengenbild'), findsNothing);
    await show(tester, 'Lumo hat 694 Sterne und schenkt 666 her. Wie viele bleiben?', '28');
    expect(find.text('Mengenbild'), findsNothing);
    expect(find.text('Wegnehmen-Bild'), findsNothing);
    await show(tester, 'Es gibt 4 Körbe mit je 5 Äpfeln. Wie viele Äpfel sind es?', '20');
    expect(find.text('Mengenbild'), findsNothing,
        reason: '4 + 5 ist nicht 20: Mal-Aufgaben bekommen kein Plus-Bild');
  });
}
