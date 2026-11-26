import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

/// Ablenker dürfen die Lösung nicht durch ihre Form verraten. Bei Auswahl
/// aus drei oder vier Karten wäre die Lösung zufällig in etwa 25-33 % der
/// Aufgaben die einzige längste Karte. Früher: Wortfamilien 91 %, Kommas in
/// Aufzählungen 88 % (nur die Lösung hatte zwei Kommas).
///
/// Geprüft werden die Rubriken, deren Ablenker der Generator zusammenstellt.
/// Die festen Sachunterricht-Fragenbanken (Ökosysteme 70 %, Stromkreise 62 %,
/// Verkehr 61 %, Ernährung 58 %) sind im Prüfbericht als offener Punkt
/// dokumentiert; dort müsste jede Frage einzeln überarbeitet werden.
void main() {
  const checked = <(String, int, String)>[
    ('Deutsch', 2, 'Wortfamilien'),
    ('Deutsch', 4, 'Kommas in Aufzählungen'),
  ];
  for (final (subject, grade, unit) in checked) {
    test('$grade/$subject/$unit: die Lösung ist nicht einfach die längste Karte',
        () {
      var total = 0, longest = 0;
      for (var seed = 0; seed < 600; seed++) {
        final task = ExerciseFactory(seed: seed * 7919 + grade)
            .nextExact(grade: grade, subject: subject, unit: unit);
        final lengths = task.choices.map((c) => c.length).toList();
        final max = lengths.reduce((a, b) => a > b ? a : b);
        total++;
        if (task.answer.length == max &&
            lengths.where((l) => l == max).length == 1) {
          longest++;
        }
      }
      // ignore: avoid_print
      print('$grade/$unit: $longest von $total einzige längste Karte');
      expect(longest / total, lessThan(.5),
          reason: '$longest von $total: Lösung ist die einzige längste Karte');
    });
  }
}
