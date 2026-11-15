import 'dart:convert';
import 'dart:io';

import '../lib/core/school_exercise_generator.dart';
import '../lib/domain/learning/lumo_learning_domain.dart';
import '../lib/domain/tutoring/native_english_vocabulary.dart';
import '../lib/domain/tutoring/native_learning_activity.dart';
import '../lib/features/learning/adapters/legacy_lumo_task_adapter.dart';

int checks = 0;
int cases = 0;

const schoolWords = <String, String>{
  'book': 'Buch',
  'pen': 'Kugelschreiber',
  'bag': 'Tasche',
  'ruler': 'Lineal',
  'rubber': 'Radiergummi',
  'school bag': 'Schultasche',
  'desk': 'Schreibtisch',
  'chair': 'Sessel',
  'pencil case': 'Federpennal',
  'paper': 'Papier',
};

void check(bool condition, String label) {
  checks++;
  if (!condition) throw StateError(label);
}

void scenario(String label, void Function() run) {
  run();
  cases++;
  stdout.writeln('PASS $label');
}

TaskInstance typed({
  String prompt = 'Was bedeutet „book“?',
  Object answer = 'Buch',
  LearningSubject subject = LearningSubject.englisch,
  TaskType type = TaskType.multipleChoice,
  String seed = 'bounded-seed',
  List<AnswerOption>? options,
  VisualPayload visual = const VisualPayload(type: VisualType.none),
}) => TaskInstance(
  taskInstanceId: 'current-task',
  templateId: 'current-template',
  childId: 'synthetic-child-a',
  seedHash: seed,
  subject: subject,
  skillId: const SkillId('current-english'),
  taskType: type,
  difficulty: 1,
  parameters: const {'unit': 'Schulsachen'},
  prompt: prompt,
  options:
      options ??
      const [
        AnswerOption(id: 'Buch', label: 'Buch', payload: 'Buch'),
        AnswerOption(id: 'Stift', label: 'Stift', payload: 'Stift'),
        AnswerOption(id: 'Lineal', label: 'Lineal', payload: 'Lineal'),
      ],
  correctAnswer: answer,
  visualPayload: visual,
  helpPayload: const HelpPayload(level: 1, shortHint: 'Bestehende Hilfe'),
  generatedAt: DateTime.utc(2026, 11, 14),
);

void main(List<String> args) {
  final realExamples = <String, Map<String, Object?>>{};
  final schoolExamples = <int, Map<String, Map<String, Object?>>>{1: {}, 2: {}};
  scenario(
    'actual generator and unchanged checked adapter reach all fourteen words',
    () {
      final factory = ExerciseFactory(seed: 741);
      for (final family in [
        (1, 'Schulsachen'),
        (2, 'Schulsachen'),
        (2, 'Spielzeug'),
        (3, 'Wetter'),
        (3, 'Essen'),
      ]) {
        for (var index = 0; index < 160; index++) {
          final original = factory.next(
            grade: family.$1,
            subject: 'Englisch',
            unit: family.$2,
          );
          final task = const LegacyLumoTaskAdapter().toTaskInstance(
            task: original,
            childId: 'synthetic-child-a',
            difficulty: 1,
            now: DateTime.utc(2026, 11, 14),
          );
          final before = [
            task.prompt,
            task.correctAnswer,
            task.childId,
            task.taskInstanceId,
            task.helpPayload.level,
            ...task.options.map((option) => option.payload),
          ];
          final descriptor = NativeLearningActivity.fromTask(task);
          check(
            jsonEncode(before) ==
                jsonEncode([
                  task.prompt,
                  task.correctAnswer,
                  task.childId,
                  task.taskInstanceId,
                  task.helpPayload.level,
                  ...task.options.map((option) => option.payload),
                ]),
            'task/child/options/help unchanged',
          );
          final isFirstSchoolUnit =
              original.unit == 'Schulsachen' && original.grade <= 2;
          if (isFirstSchoolUnit) {
            check(descriptor != null, 'Every actual grade-one/two school object is supported');
          }
          if (descriptor == null) continue;
          final payload = descriptor.toLaunchOptions();
          final word = payload['word'] as String;
          check(
            task.prompt == original.prompt &&
                task.correctAnswer == original.answer,
            'actual checked task retained for supported word',
          );
          check(
            payload['meaning'] == task.correctAnswer,
            'actual answer bound',
          );
          check(
            NativeEnglishVocabulary.meanings[word]!.contains(
              payload['meaning'],
            ),
            'reviewed translation',
          );
          final objects = payload['objects'] as List<String>;
          check(
            objects.length == 3 &&
                objects.toSet().length == 3 &&
                objects.contains(word),
            'three distinct actual objects',
          );
          realExamples.putIfAbsent(
            word,
            () => {
              'prompt': task.prompt,
              'answer': task.correctAnswer,
              'options': task.options.map((option) => option.payload).toList(),
              'grade': original.grade,
              'unit': original.unit,
              'activity': payload,
            },
          );
          if (isFirstSchoolUnit) {
            check(schoolWords[word] == payload['meaning'],
                'Exact original school translation, including pen/Kugelschreiber');
            schoolExamples[original.grade]!.putIfAbsent(
              word,
              () => {
                'prompt': task.prompt,
                'answer': task.correctAnswer,
                'options': task.options.map((option) => option.payload).toList(),
                'grade': original.grade,
                'unit': original.unit,
                'activity': payload,
              },
            );
          }
        }
      }
      check(
        realExamples.length == 14,
        'all fourteen intended local vocabulary entries reached: ${realExamples.keys}',
      );
    },
  );
  scenario('both first school grades retain all ten real school objects', () {
    for (final grade in [1, 2]) {
      final observed = schoolExamples[grade]!;
      check(observed.length == schoolWords.length &&
          observed.keys.toSet().containsAll(schoolWords.keys),
          'Actual grade $grade school collection has every intended word');
    }
  });
  scenario('multiword objects require the exact prompt and actual answer', () {
    for (final word in ['school bag', 'pencil case']) {
      final answer = schoolWords[word]!;
      final options = [
        AnswerOption(id: 'actual', label: answer, payload: answer),
        const AnswerOption(id: 'book', label: 'Buch', payload: 'Buch'),
        const AnswerOption(id: 'ball', label: 'Ball', payload: 'Ball'),
      ];
      for (final prompt in ['Was bedeutet „$word“?', 'Was heißt $word auf Deutsch?']) {
        final descriptor = NativeLearningActivity.fromTask(
          typed(prompt: prompt, answer: answer, options: options),
        );
        check(descriptor?.toLaunchOptions()['word'] == word &&
            descriptor?.toLaunchOptions()['meaning'] == answer,
            'Actual supported multiword object remains exact');
      }
      for (final prompt in [
        'Was bedeutet „${word.replaceAll(' ', '  ')}“?',
        'Was bedeutet „${word.replaceAll(' ', '-')}“?',
        'Was bedeutet „$word“? Zusatz',
      ]) {
        check(NativeLearningActivity.fromTask(
          typed(prompt: prompt, answer: answer, options: options),
        ) == null, 'Modified multiword prompt rejected');
      }
    }
    for (final prompt in [
      'Was bedeutet „homework“?',
      'Was bedeutet „lesson“?',
      'Was bedeutet „Please open your book.“?',
    ]) {
      check(NativeLearningActivity.fromTask(typed(prompt: prompt)) == null,
          'Abstract/phrase school content is not replaced by a guessed object');
    }
  });
  scenario('fallback prompt remains bound to its actual German answer', () {
    final result = NativeLearningActivity.fromTask(
      typed(prompt: 'Was heißt book auf Deutsch?'),
    );
    check(
      result?.toLaunchOptions()['meaning'] == 'Buch',
      'real fallback prompt accepted',
    );
  });
  scenario('unknown words, text injection and wrong meanings fail closed', () {
    for (final task in [
      typed(prompt: 'Was bedeutet „cat“?', answer: 'Katze'),
      typed(prompt: 'Lies book. Was ist rot?'),
      typed(prompt: 'Was bedeutet „book“? Zusatz'),
      typed(prompt: 'Was bedeutet „Book“?'),
      typed(answer: 'Auto'),
      typed(answer: 7),
      typed(subject: LearningSubject.deutsch),
      typed(type: TaskType.writingCanvas),
    ]) {
      check(
        NativeLearningActivity.fromTask(task) == null,
        'unsupported task rejected',
      );
    }
  });
  scenario(
    'missing, duplicate or misleading visible answer choices fail closed',
    () {
      for (final options in <List<AnswerOption>>[
        [],
        const [AnswerOption(id: 'one', label: 'Buch', payload: 'Buch')],
        const [
          AnswerOption(id: 'one', label: 'Auto', payload: 'Auto'),
          AnswerOption(id: 'two', label: 'Ball', payload: 'Ball'),
        ],
        const [
          AnswerOption(id: 'one', label: 'Buch', payload: 'Buch'),
          AnswerOption(id: 'two', label: 'Buch', payload: 'Buch'),
        ],
        const [
          AnswerOption(id: 'one', label: 'Auto', payload: 'Buch'),
          AnswerOption(id: 'two', label: 'Ball', payload: 'Ball'),
        ],
        const [
          AnswerOption(id: 'one', label: 'Buch', payload: 'Buch'),
          AnswerOption(id: 'two', label: '2', payload: 2),
        ],
      ]) {
        check(
          NativeLearningActivity.fromTask(typed(options: options)) == null,
          'invalid choices rejected',
        );
      }
    },
  );
  scenario(
    'stable task chooses stable positions without always revealing the first slot',
    () {
      final positions = <int>{};
      for (var seed = 0; seed < 30; seed++) {
        final task = typed(seed: '$seed');
        final a = NativeLearningActivity.fromTask(task)!.toLaunchOptions();
        final b = NativeLearningActivity.fromTask(task)!.toLaunchOptions();
        check(jsonEncode(a) == jsonEncode(b), 'same task same descriptors');
        positions.add((a['objects'] as List<String>).indexOf('book'));
      }
      check(positions.length == 3, 'correct object visits all three slots');
    },
  );
  scenario('launch maps cannot mutate retained task descriptor', () {
    final descriptor = NativeLearningActivity.fromTask(typed())!;
    final payload = descriptor.toLaunchOptions();
    payload['word'] = 'sun';
    check(
      descriptor.toLaunchOptions()['word'] == 'book',
      'top-level payload copy',
    );
    var immutable = false;
    try {
      (payload['objects'] as List<String>).clear();
    } on UnsupportedError {
      immutable = true;
    }
    check(immutable, 'nested object order immutable');
  });
  scenario('existing arithmetic descriptors retain the same operands', () {
    final descriptor = NativeLearningActivity.fromTask(
      typed(
        subject: LearningSubject.mathematik,
        answer: 4,
        visual: const VisualPayload(
          type: VisualType.divisionGroups,
          data: {'operation': 'division', 'left': 12, 'right': 3},
        ),
      ),
    );
    check(
      jsonEncode(descriptor!.toLaunchOptions()) ==
          jsonEncode({'kind': 'equal_sharing', 'a': 12, 'b': 3}),
      'sharing unchanged',
    );
  });
  scenario('existing German syllable descriptor remains exact', () {
    final descriptor = NativeLearningActivity.fromTask(
      typed(
        subject: LearningSubject.deutsch,
        answer: 2,
        visual: const VisualPayload(
          type: VisualType.syllables,
          data: {
            'word': 'Lumo',
            'syllables': <String>['Lu', 'mo'],
          },
        ),
      ),
    );
    check(
      descriptor!.toLaunchOptions()['word'] == 'Lumo',
      'German word unchanged',
    );
    check(descriptor.kind == 'syllables', 'German route unchanged');
  });
  final report = {
    'kind':
        'actual Dart production contracts; synthetic child; no Android or reward claim',
    'cases': cases,
    'checks': checks,
    'failures': 0,
    'examples': realExamples,
    'school_examples': {
      for (final entry in schoolExamples.entries) '${entry.key}': entry.value,
    },
  };
  if (args.length == 2 && args[0] == '--out') {
    File(args[1]).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
  }
  stdout.writeln('NATIVE_ENGLISH_DART_PASS cases=$cases checks=$checks');
}
