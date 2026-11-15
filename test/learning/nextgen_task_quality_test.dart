import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/checked_task_patterns.dart';
import 'package:lumo_lernen/core/safe_fallback_pool.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';

LumoTask task(
  String prompt,
  String answer,
  List<String> choices, {
  String subject = 'Mathematik',
  String unit = 'Üben',
  String visual = 'auto',
}) => LumoTask(
  id: 'preserve-this-task-id',
  grade: 4,
  subject: subject,
  unit: unit,
  prompt: prompt,
  answer: answer,
  choices: choices,
  visual: visual,
  explanation: 'Prüfe die sichtbare Aufgabe Schritt für Schritt.',
  missionTag: 'preserve-this-mission',
);

void main() {
  const guard = TaskQualityGuard();
  const adapter = LegacyLumoTaskAdapter();

  TaskInstance instance(LumoTask value) => adapter.toTaskInstance(
    task: value,
    childId: 'local-neutral-quality-check',
    difficulty: value.difficulty,
  );

  test(
    'every grade and selectable cumulative topic reaches a checked variant',
    () {
      var count = 0;
      for (var grade = 1; grade <= 4; grade++) {
        for (final subject in Curriculum.exerciseSubjectsForGrade(grade)) {
          for (final unit in Curriculum.unitsForGrade(subject, grade)) {
            for (final seed in [
              0,
              1,
              2,
              3,
              5,
              8,
              13,
              21,
              34,
              55,
              89,
              144,
              233,
              377,
              610,
              987,
            ]) {
              final value = ExerciseFactory(
                seed: seed,
              ).nextExact(grade: grade, subject: subject, unit: unit);
              final scope = '$grade/$subject/$unit/seed=$seed';
              expect(value.grade, grade, reason: scope);
              expect(value.subject, subject, reason: scope);
              expect(value.unit, unit, reason: scope);
              expect(guard.problems(value), isEmpty, reason: scope);
              expect(
                identical(adapter.qualityCheckedTask(value), value),
                isTrue,
                reason: 'Valid task identity must be retained: $scope',
              );
              count++;
            }
          }
        }
      }
      expect(count, greaterThanOrEqualTo(7152));
    },
  );

  test('the required five-shape sequence has the proved next element', () {
    const prompt =
        'Das Muster wiederholt sich immer gleich: '
        'Kreis – Dreieck – Kreis – Dreieck – Kreis – ? Welche Form folgt?';
    final pattern = CheckedShapePattern.fromPrompt(prompt)!;
    expect(pattern.period, 2);
    expect(pattern.group, ['Kreis', 'Dreieck']);
    expect(pattern.next, 'Dreieck');
    final value = task(
      prompt,
      'Dreieck',
      ['Kreis', 'Dreieck', 'Quadrat'],
      subject: 'Logik',
      unit: 'Muster',
      visual: 'pattern',
    );
    expect(guard.problems(value), isEmpty);
    final rendered = instance(value);
    expect(rendered.visualPayload.type, VisualType.sequence);
    expect(rendered.visualPayload.data['sequence'], pattern.sequence);
    expect(rendered.visualPayload.data['period'], 2);
    expect(rendered.visualPayload.data['group'], pattern.group);
    expect(
      guard.problems(
        task(
          prompt,
          'Kreis',
          ['Kreis', 'Dreieck'],
          subject: 'Logik',
          unit: 'Muster',
        ),
      ),
      contains('shape_pattern_wrong_answer'),
    );
  });

  test('non-repeating and insufficient sequences are never guessed', () {
    for (final sequence in [
      'Kreis – Dreieck – Stern – Kreis',
      'Kreis – Dreieck – Kreis',
      'Kreis – Dreieck – Kreis – Quadrat',
    ]) {
      final value = task(
        'Das Muster wiederholt sich immer gleich: '
            '$sequence – ? Welche Form folgt?',
        'Dreieck',
        ['Dreieck', 'Kreis'],
        subject: 'Logik',
        unit: 'Muster',
      );
      expect(guard.problems(value), contains('shape_pattern_rule_unproved'));
    }
  });

  test('number patterns check every gap and combination rules every card', () {
    const beginning = 'Gehe jedes Mal gleich viele Schritte weiter: ';
    const end = ' – ? Welche Zahl folgt?';
    expect(
      guard.problems(
        task(
          '${beginning}2 – 4 – 6 – 8$end',
          '10',
          ['10', '12'],
          subject: 'Logik',
          unit: 'Zahlenmuster',
        ),
      ),
      isEmpty,
    );
    expect(
      guard.problems(
        task(
          '${beginning}2 – 4 – 7 – 8$end',
          '10',
          ['10', '12'],
          subject: 'Logik',
          unit: 'Zahlenmuster',
        ),
      ),
      contains('number_pattern_rule_unproved'),
    );
    expect(
      guard.problems(
        task(
          '${beginning}2 – 4 – 6 – 8$end',
          '12',
          ['10', '12'],
          subject: 'Logik',
          unit: 'Zahlenmuster',
        ),
      ),
      contains('number_pattern_wrong_answer'),
    );
    final ambiguous = task(
      'Welche Zahl erfüllt alle drei Regeln: größer als 10, kleiner als 18 und gerade?',
      '14',
      ['12', '14', '18'],
      subject: 'Logik',
      unit: 'Regeln kombinieren',
    );
    expect(
      guard.problems(ambiguous),
      contains('combined_rule_not_exactly_one_choice'),
    );
  });

  test('wrong derived math answers fail independent arithmetic checks', () {
    final cases = <(String, int)>[
      ('Was ist die Hälfte von 18?', 9),
      ('Was ist das Doppelte von 7?', 14),
      ('Wie viele Zehner hat 42?', 4),
      ('Wie viele Einer hat 42?', 2),
      ('Wie viele Zentimeter sind 3 Meter und 20 Zentimeter?', 320),
      ('Wie viele Gramm sind 2 kg und 300 g?', 2300),
      ('Wie viele Milliliter sind 4 Liter und 100 Milliliter?', 4100),
      ('Wie viele Minuten sind 2 Stunden und 15 Minuten?', 135),
      (
        'Ein Rechteck ist 4 cm lang und 5 cm breit. Wie groß ist der Umfang?',
        18,
      ),
      (
        'Ein Rechteck ist 4 cm lang und 5 cm breit. Wie groß ist der Flächeninhalt?',
        20,
      ),
      (
        'Drei Kinder sammeln Sterne: 3, 7 und 8. Wie viele Sterne im Mittelwert?',
        6,
      ),
      ('Diagramm: Montag 3 Kinder, Dienstag 5 Kinder. Wie viele zusammen?', 8),
      ('Wie oft 4 ist 20?', 5),
      ('Welche Zahl fehlt? 4, 5, _, 7', 6),
    ];
    for (final example in cases) {
      final choices = ['${example.$2}', '${example.$2 + 1}'];
      expect(
        guard.problems(task(example.$1, choices.first, choices)),
        isEmpty,
        reason: example.$1,
      );
      expect(
        guard.problems(task(example.$1, choices.last, choices)),
        contains('numeric_answer_wrong_result'),
        reason: example.$1,
      );
    }
  });

  test(
    'comparisons, clocks and money are checked against the visible question',
    () {
      final comparison = instance(task('Welches Zeichen passt? 19 ? 91', '<',
          ['>', '<', '='], visual: 'compare'));
      expect(comparison.visualPayload.data, {'left': 19, 'right': 91});
      for (final example in [
        task('Welches Zeichen passt? 19 ? 91', '>', ['>', '<', '=']),
        task('Ist 12 gerade oder ungerade?', 'ungerade', [
          'gerade',
          'ungerade',
        ]),
        task('🍎🍎🍎 oder 🍎🍎 – wo ist mehr?', 'rechts', [
          'links',
          'rechts',
          'gleich',
        ]),
        task(
          'Welche Uhrzeit ist gemeint: Stunde 2 und Minute 15?',
          '2:45 Uhr',
          ['2:15 Uhr', '2:45 Uhr'],
        ),
        task('Was kostet mehr: 3 € oder 5 €?', '3 €', ['3 €', '5 €']),
        task('Wie viele 2-€-Münzen ergeben 8 €?', '3 Münzen', [
          '3 Münzen',
          '4 Münzen',
        ]),
        task('Welche Zahl fehlt? 1, 2, _, 8', '3', ['3', '4']),
      ]) {
        expect(guard.problems(example), isNotEmpty, reason: example.prompt);
      }
    },
  );

  test(
    'expanding a fraction checks the requested factor, not just its value',
    () {
      const prompt = 'Erweitere den Bruch 1/2 mit 3. Wie heißt der neue Bruch?';
      expect(guard.problems(task(prompt, '3/6', ['3/6', '2/6'])), isEmpty);
      expect(
        guard.problems(task(prompt, '2/4', ['2/4', '2/6'])),
        contains('fraction_expansion_wrong_representation'),
      );
    },
  );

  test('fallback keeps the selected logic lesson and all task identity', () {
    final broken = task(
      'Das Muster wiederholt sich immer gleich: Kreis – Dreieck – Kreis – Dreieck – ? Welche Form folgt?',
      'Stern',
      ['Stern', 'Kreis', 'Dreieck'],
      subject: 'Logik',
      unit: 'Muster',
    );
    final repaired = adapter.qualityCheckedTask(broken);
    expect(repaired.id, broken.id);
    expect(repaired.missionTag, broken.missionTag);
    expect(repaired.grade, broken.grade);
    expect(repaired.subject, 'Logik');
    expect(repaired.unit, 'Muster');
    expect(guard.problems(repaired), isEmpty);
    const pool = SafeFallbackPool();
    for (final unit in [
      'Muster',
      'Zahlenmuster',
      'Reihenfolge',
      'Schlussfolgern',
      'Regeln kombinieren',
    ]) {
      final fallback = pool.pick(
        subject: 'Logik',
        grade: 4,
        counter: 0,
        unit: unit,
        difficulty: 1,
      );
      expect(fallback.subject, 'Logik');
      expect(fallback.unit, unit);
      expect(guard.problems(fallback), isEmpty);
    }
  });

  test('decimal, clock, measurement and fraction cards remain distinct', () {
    for (final choices in [
      ['1,5', '15'],
      ['1:30 Uhr', '13:00 Uhr'],
      ['2 cm', '2 m'],
      ['1/23', '12/3'],
    ]) {
      final rendered = instance(
        task('Wähle die passende Antwort.', choices.first, choices),
      );
      expect(
        rendered.options.map((option) => '${option.payload}').toSet(),
        hasLength(2),
      );
      expect('${rendered.correctAnswer}', choices.first);
    }
  });

  test('equivalent card labels use exactly the same scoring payload', () {
    for (final example in [
      task('Wähle die passende Zahl.', '0.5', ['0,50', '0,6']),
      task('Wähle das passende Wort.', 'Katze', [
        'katze',
        'Hund',
      ], subject: 'Deutsch'),
    ]) {
      final rendered = instance(example);
      expect(rendered.correctAnswer, rendered.options.first.payload);
      expect(rendered.options.first.label, example.choices.first);
    }
    expect(
      guard.problems(
        task('Welche Uhrzeit?', '3:00 Uhr', [
          '3:00 Uhr',
          '03:00 Uhr',
          '4:00 Uhr',
        ]),
      ),
      contains('duplicate_choices'),
    );
  });

  test(
    'fractional expressions never become unrelated integer counter groups',
    () {
      for (final value in [
        task('1,5 + 2,5 = ?', '4', ['4', '5'], visual: 'dots'),
        task('1/4 + 2/4 = ?', '3/4', ['3/4', '1/4'], visual: 'dots'),
      ]) {
        final data = instance(value).visualPayload.data;
        expect(data['operation'], isNot('addition'));
        expect(data.containsKey('left'), isFalse);
      }
      final subtraction = instance(
        task('13 − 5 = ?', '8', ['8', '9'], visual: 'line'),
      );
      expect(subtraction.visualPayload.data, {
        'operation': 'subtraction',
        'left': 13,
        'right': 5,
        'start': 13,
        'takeAway': 5,
      });
    },
  );

  test(
    'the visible quantities and syllables are taken from the actual problem',
    () {
      final quantity = instance(
        task('🍎🍎🍎 oder 🍎🍎 – wo ist mehr?', 'links', [
          'links',
          'rechts',
          'gleich',
        ], visual: 'quantity'),
      );
      expect(quantity.visualPayload.type, VisualType.quantityCompare);
      expect(quantity.visualPayload.data, {'left': 3, 'right': 2});
      final syllables = instance(
        task(
          'Wie viele Silben hat Banane?',
          '3',
          ['3', '2', '4'],
          subject: 'Deutsch',
          unit: 'Silben',
          visual: 'syllable_clap',
        ),
      );
      expect(syllables.visualPayload.data['word'], 'Banane');
      expect(syllables.visualPayload.data['syllables'], ['Ba', 'na', 'ne']);
      final money = instance(
        task('Wie viel sind 1,5 Euro?', '1,50 €', [
          '1,50 €',
          '1,05 €',
        ], visual: 'money'),
      );
      expect(money.visualPayload.data['cents'], 150);
    },
  );

  test('first help does not reuse a complete worked solution', () {
    final rendered = instance(
      const LumoTask(
        id: 'sum',
        grade: 1,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        prompt: '8 + 5 = ?',
        choices: ['13', '12', '14'],
        answer: '13',
        explanation: '8 + 2 = 10. 10 + 3 = 13.',
        visual: 'dots',
      ),
    );
    expect(rendered.helpPayload.shortHint, isNot(contains('13')));
    expect(rendered.helpPayload.guidedSteps, hasLength(3));
    expect(rendered.helpPayload.guidedSteps[2], contains('8 bis 10 fehlen 2'));
  });

  test('plant focus is supplied only for the curated question-answer pair', () {
    final root = instance(
      task(
        'Welcher Pflanzenteil nimmt Wasser auf?',
        'Wurzel',
        ['Wurzel', 'Blüte', 'Ast'],
        subject: 'Sachunterricht',
        unit: 'Pflanzen',
      ),
    );
    expect(root.visualPayload.data, {
      'sceneKind': 'plant_parts',
      'plantPart': 'root',
    });
    final unrelated = instance(
      task(
        'Welche Pflanze steht auf dem Bild?',
        'Baum',
        ['Baum', 'Blume'],
        subject: 'Sachunterricht',
        unit: 'Pflanzen',
      ),
    );
    expect(unrelated.visualPayload.data.containsKey('sceneKind'), isFalse);
  });
}
