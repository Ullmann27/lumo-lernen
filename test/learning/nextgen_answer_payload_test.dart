import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

const _adapter = LegacyLumoTaskAdapter();

LumoTask _source(
  String prompt,
  String answer,
  List<String> choices, {
  String visual = 'auto',
}) => LumoTask(
  id: 'nextgen-payload-${prompt.hashCode}',
  grade: 4,
  subject: 'Mathematik',
  unit: 'Zahlen und Größen',
  prompt: prompt,
  choices: choices,
  answer: answer,
  explanation: 'Prüfe den Zahlenwert und die zugehörige Einheit.',
  visual: visual,
);

TaskInstance _checked(LumoTask source) {
  expect(
    const TaskQualityGuard().problems(source),
    isEmpty,
    reason: source.prompt,
  );
  expect(
    _adapter.qualityCheckedTask(source),
    same(source),
    reason: 'The test must exercise this task, never a replacement.',
  );
  return _adapter.toTaskInstance(
    task: source,
    childId: 'synthetic-nextgen-child',
    difficulty: source.difficulty,
    now: DateTime(2026, 11, 15),
  );
}

void main() {
  test(
    'decimal, currency and time choices keep distinct scoring identities',
    () {
      for (final source in [
        _source('Welche Zahl ist zwölf Zehntel?', '1,2', ['1,2', '12', '2,1']),
        _source('Welche Karte nennt einen Euro?', '1 €', [
          '1 €',
          '1 Cent',
          '100 €',
        ]),
        _source(
          'Welche Uhrzeit ist gemeint: Stunde 1 und Minute 30?',
          '1:30 Uhr',
          ['1:30 Uhr', '130', '13:00 Uhr'],
          visual: 'clock',
        ),
        _source('Welche Karte nennt eine Länge?', '12 cm', [
          '12 cm',
          '12 kg',
          '12 Minuten',
        ]),
      ]) {
        final task = _checked(source);
        final answerKeys = task.options
            .map((option) => '${option.payload ?? option.label}')
            .toList();
        expect(
          answerKeys.toSet().length,
          source.choices.length,
          reason: source.prompt,
        );
        expect(
          answerKeys.where((key) => key == '${task.correctAnswer}').length,
          1,
          reason: source.prompt,
        );
        expect(task.parameters['legacyId'], source.id);
      }
    },
  );

  test('only whole integer answers become numeric counts', () {
    final task = _checked(
      _source('Welche Zahl ist fünf?', '5', ['5', '50', '15']),
    );
    expect(task.correctAnswer, 5);
    expect(task.options.map((option) => option.payload), [5, 50, 15]);

    final fraction = _checked(
      _source('1/4 + 2/4 = ?', '3/4', [
        '3/4',
        '1/23',
        '12/3',
      ], visual: 'fraction_add'),
    );
    expect(fraction.correctAnswer, '3/4');
    expect(fraction.options.map((option) => option.payload), [
      '3/4',
      '1/23',
      '12/3',
    ]);
    expect(NativeLearningActivity.fromTask(fraction)!.kind, 'fraction_parts');
  });

  test('decimal arithmetic exposes exact place values, never integer dots', () {
    final task = _checked(
      _source('0,1 + 0,2 = ?', '0,3', ['0,3', '3', '0,2'], visual: 'dots'),
    );
    expect(task.correctAnswer, '0,3');
    expect(task.visualPayload.type, VisualType.none);
    expect(task.visualPayload.data, {
      'operation': 'decimal_addition',
      'leftMinorUnits': 1,
      'rightMinorUnits': 2,
      'resultMinorUnits': 3,
      'decimalPlaces': 1,
      'leftText': '0,1',
      'rightText': '0,2',
      'resultText': '0,3',
    });
    expect(
      NativeLearningActivity.fromTask(task),
      isNull,
      reason: 'The bounded native scene currently accepts whole objects.',
    );

    final negative = _checked(
      _source('1,2 - 2,4 = ?', '-1,2', ['-1,2', '1,2', '12'], visual: 'line'),
    );
    expect(negative.visualPayload.type, VisualType.none);
    expect(negative.visualPayload.data['leftMinorUnits'], 12);
    expect(negative.visualPayload.data['rightMinorUnits'], 24);
    expect(negative.visualPayload.data['resultMinorUnits'], -12);
    expect(negative.visualPayload.data['operation'], 'decimal_subtraction');
  });

  test(
    'different decimal precision is scaled without floating point rounding',
    () {
      final task = _checked(
        _source('1,25 + 2,5 = ?', '3,75', [
          '3,75',
          '3,50',
          '375',
        ], visual: 'decimal'),
      );
      expect(task.visualPayload.data['decimalPlaces'], 2);
      expect(task.visualPayload.data['leftMinorUnits'], 125);
      expect(task.visualPayload.data['rightMinorUnits'], 250);
      expect(task.visualPayload.data['resultMinorUnits'], 375);
    },
  );

  test('all generated decimal variants preserve their exact arithmetic', () {
    for (var seed = 0; seed < 128; seed++) {
      final generated = MathTaskTemplates.generate(
        grade: 4,
        unit: 'Dezimalzahlen',
        seed: seed,
      );
      final task = _checked(
        _source(
          generated.prompt,
          generated.answer,
          generated.choices,
          visual: generated.visual,
        ),
      );
      final data = task.visualPayload.data;
      expect(data['operation'], 'decimal_addition', reason: generated.prompt);
      expect(data['leftMinorUnits'], isA<int>());
      expect(data['rightMinorUnits'], isA<int>());
      expect(
        data['resultMinorUnits'],
        (data['leftMinorUnits'] as int) + (data['rightMinorUnits'] as int),
      );
      expect(task.visualPayload.type, VisualType.none);
      expect(task.correctAnswer, generated.answer);
    }
  });

  test(
    'whole-object formula is complete and still reaches native 8 plus 5',
    () {
      final task = _checked(
        _source('8 + 5 = ?', '13', ['13', '12', '14'], visual: 'dots'),
      );
      expect(task.visualPayload.data, {
        'operation': 'addition',
        'left': 8,
        'right': 5,
      });
      expect(NativeLearningActivity.fromTask(task)!.toLaunchOptions(), {
        'kind': 'addition',
        'a': 8,
        'b': 5,
      });

      final text = _checked(
        _source(
          'Im Beispiel gilt 8 + 5 = 13. Welche Zahl wird genannt?',
          '13',
          ['13', '12', '14'],
        ),
      );
      expect(
        text.visualPayload.data,
        isEmpty,
        reason:
            'A formula inside unrelated text is not a verified object model.',
      );
    },
  );

  test('one decimal digit in an amount means tenths of a euro', () {
    for (final notation in ['1,5 €', '1.5 Euro', '1,50 EUR']) {
      final task = _checked(
        _source('Lege $notation auf den Tisch.', '150', [
          '150',
          '105',
          '15',
        ], visual: 'money_coins'),
      );
      expect(task.visualPayload.data['cents'], 150, reason: notation);
      expect(task.visualPayload.data['amount'], 150, reason: notation);
    }
    final unknown = _checked(
      _source('Was kostet 1.500 €?', '1500', [
        '1500',
        '500',
        '15',
      ], visual: 'money_coins'),
    );
    expect(
      unknown.visualPayload.data,
      isEmpty,
      reason: 'Do not silently parse a substring as 500 euros.',
    );
  });

  for (final source in [
    _source('Welche Zahl ist zwölf Zehntel?', '1,2', ['1,2', '12', '2,1']),
    _source('Welche Karte nennt einen Euro?', '1 €', [
      '1 €',
      '1 Cent',
      '100 €',
    ]),
    _source(
      'Welche Uhrzeit ist gemeint: Stunde 1 und Minute 30?',
      '1:30 Uhr',
      ['1:30 Uhr', '130', '13:00 Uhr'],
      visual: 'clock',
    ),
  ]) {
    testWidgets(
      'actual answer renderer rejects a colliding distractor: ${source.answer}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1300));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final answers = <AdaptiveTaskAnswer>[];
        final task = _checked(source);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdaptiveTaskRenderer(
                  task: task,
                  onAnswered: answers.add,
                ),
              ),
            ),
          ),
        );
        final distractor = find.byKey(
          ValueKey('math-crystal-${source.choices[1]}'),
        );
        await tester.ensureVisible(distractor);
        await tester.tap(distractor);
        await tester.pump();
        expect(answers, hasLength(1));
        expect(answers.single.correct, isFalse);
        expect(
          answers.single.answer,
          source.choices[1] == '12'
              ? 12
              : source.choices[1] == '130'
              ? 130
              : source.choices[1],
        );

        final correct = find.byKey(ValueKey('math-crystal-${source.answer}'));
        await tester.ensureVisible(correct);
        await tester.tap(correct);
        await tester.pump();
        expect(answers, hasLength(2));
        expect(answers.last.correct, isTrue);
        await tester.tap(correct);
        await tester.pump();
        expect(
          answers,
          hasLength(2),
          reason: 'Repeated taps may not submit the solved task again.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
