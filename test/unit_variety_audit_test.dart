import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

/// Inhalts-Audit (24.11.2026): Jede Rubrik jeder Klasse liefert nur Aufgaben
/// ihrer eigenen Einheit, ihres Fachs und ihrer Klasse, und genug
/// verschiedene Aufgaben, damit Kinder nicht dieselbe Frage wiederholt sehen.
const int _draws = 60;
const int _minDistinct = 15;

/// Begründete Ausnahmen: Diese Rubriken hängen an einer festen Zahl
/// geprüfter Vorlagen (Spurvorlagen bzw. native 3D-Objekte). Mehr Vielfalt
/// gibt es nur mit neuen Vorlagen, nicht mit neuen Texten. Die Zahl ist die
/// Untergrenze, damit es nicht noch weniger wird.
const Map<String, int> _templateBound = <String, int>{
  // Je eine geprüfte Nachzeichen-Vorlage pro Form (Quadrat, Kreis, Dreieck
  // bzw. zusätzlich Rechteck, Stern) in math_task_templates.dart.
  'Mathematik Kl.1 Formen Nachzeichnen': 3,
  'Mathematik Kl.2 Formen Nachzeichnen': 5,
  // Nur Buchstaben mit geprüfter Ein-Strich-Schwungvorlage (S C O U / s c o u e).
  'Schreiben Kl.1 Schwunguebung': 4,
  'Schreiben Kl.2 Schwunguebung': 5,
  // Jedes Wort braucht ein natives 3D-Objekt (NativeEnglishVocabulary,
  // tool/check_native_english_activity.dart verlangt das für Kl. 1–2).
  'Englisch Kl.1 Schulsachen': 10,
};

void main() {
  test('jede Rubrik: richtige Einheit und mindestens $_minDistinct verschiedene Aufgaben', () {
    final low = <String>[];
    final wrong = <String>[];
    final report = <Map<String, Object?>>[];
    for (final subject in Curriculum.subjects.keys) {
      for (var grade = 1; grade <= 4; grade++) {
        for (final unit in Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true)) {
          final factory = ExerciseFactory(seed: 4242 + grade);
          final prompts = <String>{};
          for (var n = 0; n < _draws; n++) {
            final t = factory.nextExact(grade: grade, subject: subject, unit: unit, currentGradeOnly: true);
            if (t.unit != unit || t.subject != subject || t.grade != grade) {
              wrong.add('$subject $grade $unit -> ${t.subject} ${t.grade} ${t.unit}');
            }
            expect(t.choices.isEmpty || t.choices.contains(t.answer), isTrue,
                reason: '$subject $grade $unit: ${t.prompt}');
            prompts.add('${t.prompt}|${t.answer}');
          }
          report.add({'subject': subject, 'grade': grade, 'unit': unit, 'distinct': prompts.length});
          final key = '$subject Kl.$grade $unit';
          if (prompts.length < (_templateBound[key] ?? _minDistinct)) low.add('$subject Kl.$grade $unit: ${prompts.length}');
        }
      }
    }
    final out = Platform.environment['LUMO_VARIETY_REPORT'];
    if (out != null) File(out).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(report));
    expect(wrong, isEmpty, reason: wrong.take(20).join('\n'));
    expect(low, isEmpty, reason: '${low.length} Rubriken unter $_minDistinct:\n${low.join('\n')}');
  });
}
