import 'dart:convert';
import 'math_task_templates.dart';

void main() {
  var changed = 0;
  for (final item in <(int, String)>[
    (2, 'Geld'),
    (3, 'Geometrie Formen'),
    (4, 'Geometrie Formen'),
  ]) {
    final task = MathTaskTemplates.generate(
        grade: item.$1, unit: item.$2, seed: 1);
    final preserved = task.unit == item.$2;
    if (!preserved) changed++;
    print(jsonEncode({
      'grade': item.$1, 'requested_unit': item.$2, 'seed': 1,
      'actual_unit': task.unit, 'selection_preserved': preserved,
      'scope': 'actual unmodified pure Dart templates; no Flutter or UI run',
    }));
  }
  print('Counterexamples with changed explicit unit: $changed / 3');
}
