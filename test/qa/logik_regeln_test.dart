import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/widgets/inquiry_workbench.dart';

/// Logik „Regeln kombinieren“ (offener Punkt 11 des Prüfberichts): Mehrere
/// Zahlen erfüllen die drei Regeln, nur eine steht auf den Karten. Die Frage
/// heißt deshalb „Welche dieser Zahlen …“ statt „Welche Zahl …“.
void main() {
  test('die Frage bezieht sich auf die Karten, genau eine Karte passt', () {
    const guard = TaskQualityGuard();
    final rule = RegExp(r'größer als (\d+), kleiner als (\d+) und (.+)\?$');
    var severalFit = 0;
    for (var seed = 0; seed < 300; seed++) {
      final task = ExerciseFactory(seed: seed).nextExact(
          grade: 4, subject: 'Logik', unit: 'Regeln kombinieren');
      expect(task.prompt,
          startsWith('Welche dieser Zahlen erfüllt alle drei Regeln:'));
      expect(guard.problems(task), isEmpty, reason: task.prompt);
      final m = rule.firstMatch(task.prompt)!;
      final lower = int.parse(m[1]!), upper = int.parse(m[2]!);
      final fitting = [
        for (var v = lower + 1; v < upper; v++)
          if (combinedRuleProperty(m[3]!, v)) v,
      ];
      if (fitting.length > 1) severalFit++;
      final onCards = task.choices
          .where((c) => fitting.contains(int.tryParse(c)))
          .toList();
      expect(onCards, [task.answer], reason: task.prompt);
      // Die Werkbank „Regeln prüfen“ erkennt die neue Frage.
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
          task: task,
          childId: 'logik',
          difficulty: 4,
          now: DateTime.utc(2026, 11, 26));
      expect(InquiryWorkbench.kindFor(instance), 'rules');
    }
    // Ohne „dieser“ wäre die Frage in diesen Fällen mehrdeutig.
    expect(severalFit, greaterThan(250));
  });
}
