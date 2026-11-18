import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Befund M11 der Fachprüfung Mathematik (17.11.2026): Formales Erweitern
/// von Brüchen geht über den Volksschulstoff hinaus. Die Aufgaben sind als
/// Knobelaufgabe gekennzeichnet; Prüfung, Tipp und Bild lesen sie weiter.
void main() {
  test('Brüche erweitern ist als Knobelaufgabe gekennzeichnet', () {
    const guard = TaskQualityGuard();
    const hints = TaskHintService();
    for (var seed = 0; seed < 60; seed++) {
      final task = ExerciseFactory(seed: seed)
          .nextExact(grade: 4, subject: 'Mathematik', unit: 'Brüche erweitern');
      expect(task.prompt, startsWith('Knobelaufgabe: Erweitere den Bruch '));
      expect(guard.problems(task), isEmpty, reason: task.prompt);
      // Der genaue Tipp nennt den Faktor, nicht nur einen allgemeinen Satz.
      expect(hints.explain(task, level: 2), contains('oben '),
          reason: task.prompt);
    }
  });
}
