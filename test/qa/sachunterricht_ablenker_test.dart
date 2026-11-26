import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

/// Sachunterricht-Fragenbanken (offener Punkt 6 des Prüfberichts): Die
/// richtige Karte darf nicht an ihrer Länge zu erkennen sein. Früher war die
/// Lösung bei Ökosystemen in 69 %, Verkehr Kl. 3 in 73 %, Familie und
/// Gemeinschaft Kl. 3 in 78 %, Stromkreisen in 60 % der Fragen die einzige
/// längste Karte (gesamt 35 %). Bei vier Karten wären es zufällig etwa 25 %.
List<LumoTask> _bank(int grade, String unit) {
  final factory = ExerciseFactory(seed: 11 + grade);
  final seen = <String>{};
  final tasks = <LumoTask>[];
  for (var i = 0; i < 400; i++) {
    final task =
        factory.nextExact(grade: grade, subject: 'Sachunterricht', unit: unit);
    if (seen.add('${task.prompt}|${task.answer}')) tasks.add(task);
  }
  return tasks;
}

bool _uniqueLongest(LumoTask task) {
  final lengths = task.choices.map((c) => c.length).toList();
  final max = lengths.reduce((a, b) => a > b ? a : b);
  return task.answer.length == max && lengths.where((l) => l == max).length == 1;
}

void main() {
  test('die richtige Karte ist nicht einfach die längste', () {
    var total = 0, longest = 0;
    final skewed = <String>[];
    for (var grade = 1; grade <= 4; grade++) {
      for (final unit in Curriculum.unitsForGrade('Sachunterricht', grade,
          currentGradeOnly: true)) {
        final tasks = _bank(grade, unit);
        final hits = tasks.where(_uniqueLongest).length;
        total += tasks.length;
        longest += hits;
        // Je Fragenbank höchstens 40 %.
        if (tasks.length >= 8 && hits / tasks.length > .4) {
          skewed.add('$grade/$unit: $hits von ${tasks.length}');
        }
      }
    }
    // ignore: avoid_print
    print('Sachunterricht: $longest von $total Lösungen einzige längste Karte');
    expect(skewed, isEmpty, reason: skewed.join('\n'));
    expect(longest / total, lessThan(.3));
  });
}
