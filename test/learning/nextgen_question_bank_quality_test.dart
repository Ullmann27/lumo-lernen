import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/choice_question_quality.dart';
import 'package:lumo_lernen/core/lumo_asset_paths.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/domain/quiz/quiz_show.dart';
import 'package:lumo_lernen/features/games/lumo_cards/learning_question_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';

List<Map<String, dynamic>> _items(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

QuizQuestion _withIndex(QuizQuestion q, int index) => QuizQuestion(
    id: q.id,
    prompt: q.prompt,
    options: q.options,
    correctIndex: index,
    difficulty: q.difficulty,
    subject: q.subject,
    hint: q.hint,
    explanation: q.explanation);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 200 bundled cards are reviewed; every wrong index is rejected', () {
    var count = 0;
    for (final path in LumoAssetPaths.allQuestionBundles) {
      for (final item in _items(path)) {
        final question = LearningQuestionRepository.debugParseQuestion(item);
        expect(question, isNotNull, reason: '$path: ${item['prompt']}');
        expect(question!.correctIndex, item['correctIndex']);
        expect(question.options, item['options']);
        expect(LearningQuestionRepository.problems(question), isEmpty,
            reason: question.prompt);
        for (var wrong = 0; wrong < 4; wrong++) {
          if (wrong == question.correctIndex) continue;
          expect(
              LearningQuestionRepository.debugParseQuestion(
                  {...item, 'correctIndex': wrong}),
              isNull,
              reason: '${question.prompt}: wrong index $wrong must fail');
        }
        expect(() => question.options[0] = 'changed', throwsUnsupportedError);
        count++;
      }
    }
    expect(count, 200);
  });

  test('card parser blocks duplicate, missing and non-string options', () {
    const valid = {
      'prompt': 'Wie viel ist 1 + 1?',
      'options': ['1', '2', '3', '4'],
      'correctIndex': 1,
    };
    for (final broken in [
      {
        ...valid,
        'options': ['2', '2', '3', '4']
      },
      {
        ...valid,
        'options': ['1', '02', '2,0', '4']
      },
      {
        ...valid,
        'options': ['1', '2', '', '4']
      },
      {
        ...valid,
        'options': ['1', '2', null, '4']
      },
      {
        ...valid,
        'options': ['1', 2, '3', '4']
      },
      {
        ...valid,
        'options': ['1', '2', '3']
      },
      {...valid, 'correctIndex': -1},
      {...valid, 'correctIndex': 4},
      {...valid, 'prompt': ''},
      {...valid, 'prompt': 'A new unsupported fact?'},
    ]) {
      expect(LearningQuestionRepository.debugParseQuestion(broken), isNull,
          reason: '$broken');
    }
  });

  test('concurrent real bundle initialization waits for the same 200 items',
      () async {
    final repo = LearningQuestionRepository.instance..debugReset();
    addTearDown(repo.debugReset);
    final first = repo.init();
    final second = repo.init();
    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);
    expect(repo.isReady, isTrue);
    expect(repo.count, 200);
    for (var grade = 1; grade <= 2; grade++) {
      final gradePrompts = {
        for (final path in LumoAssetPaths.allQuestionBundles)
          if (path.contains('grade${grade}_'))
            for (final item in _items(path)) item['prompt'],
      };
      final correctPositions = <int>{};
      for (var seed = 0; seed < 256; seed++) {
        final question = repo.randomForGrade(grade, Random(seed));
        expect(gradePrompts, contains(question.prompt));
        expect(LearningQuestionRepository.problems(question), isEmpty);
        correctPositions.add(question.correctIndex);
      }
      expect(correctPositions, {0, 1, 2, 3});
    }
  });

  test('nine direct card math scopes and grade pickers keep verified answers',
      () {
    const units = {
      3: ['Einmaleins', 'Plus bis 100', 'Minus bis 100', 'Division einstellig'],
      4: [
        'Schriftliche Multiplikation',
        'Schriftliche Division',
        'Plus bis 10000',
        'Minus bis 10000',
        'Vergleichen'
      ],
    };
    var variants = 0;
    for (final entry in units.entries) {
      for (final unit in entry.value) {
        for (var seed = 0; seed < 128; seed++) {
          final task = MathTaskTemplates.generate(
              grade: entry.key, unit: unit, seed: seed);
          final question = LearningQuestion(
              prompt: task.prompt,
              options: task.choices,
              correctIndex: task.choices.indexOf(task.answer),
              hint: task.explanation);
          expect(LearningQuestionRepository.problems(question), isEmpty,
              reason: '${entry.key} / $unit / $seed: ${task.prompt}');
          variants++;
        }
      }
      for (var seed = 0; seed < 1024; seed++) {
        final question = LearningQuestionRepository.instance
            .randomForGrade(entry.key, Random(seed));
        expect(LearningQuestionRepository.problems(question), isEmpty,
            reason: 'grade ${entry.key}, seed $seed');
        expect(() => question.options[0] = 'changed', throwsUnsupportedError);
      }
    }
    expect(variants, 1152);
  });

  test(
      'all 108 quiz identities are checked across grades and subject priorities',
      () {
    final all = <String, QuizQuestion>{};
    var rounds = 0;
    for (var grade = 1; grade <= 4; grade++) {
      for (final subject in [null, 'Mathe', 'Deutsch', 'Sachunterricht']) {
        final seen = <String>{};
        for (var seed = 0; seed < 64; seed++) {
          final questions = const QuizQuestionBank().generateGameQuestions(
              grade: grade,
              seenIds: seen,
              preferSubject: subject,
              random: Random(seed));
          expect(questions, hasLength(20));
          expect(questions.map((q) => q.id).toSet(), hasLength(20));
          expect(questions.last.id, startsWith('final_g${grade}_'));
          expect(() => questions.removeLast(), throwsUnsupportedError);
          for (final question in questions) {
            expect(QuizQuestionBank.problems(question), isEmpty,
                reason: question.id);
            all[question.id] = question;
            seen.add(question.id);
          }
          rounds++;
        }
      }
    }
    expect(rounds, 1024);
    expect(all, hasLength(108));
    for (final question in all.values) {
      for (var wrong = 0; wrong < 4; wrong++) {
        if (wrong == question.correctIndex) continue;
        expect(
            QuizQuestionBank.problems(_withIndex(question, wrong)), isNotEmpty,
            reason: '${question.id}: wrong index $wrong must fail');
      }
    }
  });

  test('actual predicates reject multiple valid answers and unsafe fact edits',
      () {
    final cases = [
      ('Was ist größer als 15?', ['18', '19', '9', '5'], 0),
      ('Welche Zahl ist gerade?', ['8', '6', '5', '3'], 0),
      (
        'Welche Zahl ist größer als 20, kleiner als 30 und gerade?',
        ['22', '23', '26', '31'],
        2
      ),
      ('Wie viel ist 1 + 1?', ['2', '2,00', '3', '4'], 0),
      ('Wie viel ist 3 : 0?', ['0', '1', '3', '4'], 0),
      ('Wie viel ist 3 : 2?', ['1', '2', '3', '4'], 0),
      ('Welche Farbe hat eine Banane?', ['Rot', 'Blau', 'Gelb', 'Grün'], 2),
      (
        'In welchem Kontinent leben Löwen wild?',
        ['Europa', 'Afrika', 'Amerika', 'Asien'],
        1
      ),
      (
        'Was atmen wir ein?',
        ['Wasser', 'Stickstoff', 'Sauerstoff', 'Kohlendioxid'],
        2
      ),
      ('Welches Tier legt Eier?', ['Ente', 'Schaf', 'Huhn', 'Pferd'], 2),
      ('Was reimt sich auf Haus?', ['Maus', 'Klaus', 'Ball', 'Stern'], 0),
      (
        'Wie schreibt man "schtoa..."?',
        ['Schtohr', 'Stohr', 'Stoa', 'Stör'],
        3
      ),
      (
        'Welcher Fischname ist richtig geschrieben?',
        ['Schtohr', 'Stohr', 'Stoa', 'stör'],
        3
      ),
    ];
    for (final (prompt, options, index) in cases) {
      expect(
          ChoiceQuestionQuality.problems(
              prompt: prompt, options: options, correctIndex: index),
          isNotEmpty,
          reason: prompt);
    }
  });

  test('spelling tasks ask about letters and do not mislabel the Vogel sound',
      () {
    final questions = _items('assets/learning_questions/grade1_german.json');
    final vogel = questions.singleWhere(
        (item) => item['prompt'] == 'Mit welchem Buchstaben beginnt "Vogel"?');
    final parsed = LearningQuestionRepository.debugParseQuestion(vogel)!;
    expect(parsed.options[parsed.correctIndex], 'V');
    expect(parsed.hint, contains('geschriebenen Buchstaben'));
    expect(parsed.hint, isNot(contains('ersten Laut')));
  });
}
