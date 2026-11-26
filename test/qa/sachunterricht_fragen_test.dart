import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

/// Sachunterricht und Diagramme (offener Punkt 1 des Prüfberichts,
/// Entscheidung Heinz vom 26.11.2026):
/// Rechnen mit Diagrammen gehört in die Mathematik (Lehrplan VS 2023:
/// „Säulen- und Balkendiagramme sowie Piktogramme interpretieren“ ab der
/// 2. Schulstufe im Fach Mathematik). Der Sachunterricht behält Diagramme
/// zu Wetter, Natur, Verkehr und Umwelt, wenn sie sachunterrichtliches
/// Verständnis prüfen.
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

/// Rechenfragen: Summe, Unterschied, Vielfaches aus Diagramm oder Uhr.
final _calculation = RegExp(
  r'[Ww]ie viele[^?]*zusammen\?|Unterschied|[Uu]m wie viel|[Ww]ie viel mehr|'
  r'[Ww]ie viele \S+ (mehr|weniger) als|mehr als (der|die|das) \S+\?|'
  r'wurden befragt|nicht zu Fuß\?|kamen am|Wann endet sie',
);

void main() {
  group('Diagramme: Rechnen in Mathematik, Deutung im Sachunterricht', () {
    test('kein Sachunterricht-Thema stellt eine Rechenaufgabe', () {
      for (var grade = 1; grade <= 4; grade++) {
        for (final unit in Curriculum.unitsForGrade('Sachunterricht', grade)) {
          for (final task in _bank(grade, unit)) {
            expect(task.prompt, isNot(matches(_calculation)),
                reason: '$grade/$unit: ${task.prompt}');
          }
        }
      }
    });

    test('Sachunterricht „Diagramme lesen“ prüft Wetter, Natur, Verkehr, Umwelt',
        () {
      final theme = RegExp(
          r'Frost|Regen|Niederschlag|Sonne|Sommer|Tageslicht|Gewitter|Grad|Wetter|Kresse|'
          r'Vögel|Müll|Wasser|Autos|Schulweg|Helm|Zebrastreifen');
      final tasks = _bank(4, 'Diagramme lesen');
      expect(tasks.length, greaterThanOrEqualTo(12));
      for (final task in tasks) {
        expect(task.grade, 4);
        expect('${task.prompt} ${task.answer}', matches(theme),
            reason: task.prompt);
        expect(task.prompt, matches(RegExp('iagramm|[Tt]abelle')),
            reason: task.prompt);
      }
    });

    test('die Rechenfragen stehen jetzt in Mathematik Kl. 4 „Diagramme lesen“',
        () {
      const moved = <String>[
        'Strichliste zeigt Lieblingstiere',
        'Besucher im Schwimmbad',
        'Wie viele Kinder kommen nicht zu Fuß?',
        'Lieblingsobst',
        'Ein 🟦 sind 5 Besucher.',
        'Ein 🟦 ist ein Regentag.',
        'Ein 🟦 ist ein Buch.',
        'eine Sonne für 2 Sonnentage',
        'Klasse 4a 12 kg Altpapier',
        'in der Früh 4 Grad, zu Mittag 11 Grad',
        'Ein Thermometer zeigt morgens 7 Grad und mittags 14 Grad',
        'Was zeigt ein Säulendiagramm?',
        'Wozu hat ein Diagramm eine Überschrift?',
      ];
      final math = <String>{};
      for (var seed = 0; seed < 600; seed++) {
        final task = ExerciseFactory(seed: seed).nextExact(
            grade: 4, subject: 'Mathematik', unit: 'Diagramme lesen');
        expect(task.subject, 'Mathematik');
        math.add(task.prompt);
      }
      for (final fragment in moved) {
        expect(math.any((p) => p.contains(fragment)), isTrue,
            reason: 'fehlt in Mathematik: $fragment');
      }
    });
  });
}
