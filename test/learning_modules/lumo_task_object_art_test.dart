import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/design/lumo_task_object_art.dart';

GermanTaskTemplate template(String id) =>
    GermanTaskTemplates.templates.singleWhere((item) => item.id == id);

TaskInstance wordImageTask({
  String prompt = 'Welches Wort passt zum Bild: 🐶?',
  String answer = 'Hund',
}) {
  return TaskInstance(
    taskInstanceId: 'g1-word-image',
    templateId: 'g1_word_image',
    childId: 'test',
    seedHash: '0',
    subject: LearningSubject.deutsch,
    skillId: const SkillId('g1_word_image'),
    taskType: TaskType.imageWord,
    difficulty: 1,
    parameters: const {'unit': 'Wort-Bild-Zuordnung', 'grade': 1},
    prompt: prompt,
    options: [
      AnswerOption(id: 'a', label: answer, payload: answer),
      const AnswerOption(id: 'b', label: 'Katze', payload: 'Katze'),
      const AnswerOption(id: 'c', label: 'Maus', payload: 'Maus'),
      const AnswerOption(id: 'd', label: 'Haus', payload: 'Haus'),
    ],
    correctAnswer: answer,
    visualPayload: const VisualPayload(type: VisualType.none),
    helpPayload: const HelpPayload(),
    generatedAt: DateTime(2026, 11, 10),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every first-grade word-image answer has matching local art', () async {
    const expected = <String, String>{
      'Hund': '🐶',
      'Katze': '🐱',
      'Maus': '🐭',
      'Hase': '🐰',
      'Fuchs': '🦊',
      'Kuh': '🐮',
      'Schwein': '🐷',
      'Biene': '🐝',
      'Apfel': '🍎',
      'Banane': '🍌',
      'Birne': '🍐',
      'Karotte': '🥕',
      'Baum': '🌳',
      'Auto': '🚗',
      'Bus': '🚌',
      'Buch': '📘',
      'Ball': '⚽',
      'Sonne': '☀️',
      'Mond': '🌙',
      'Haus': '🏠',
    };
    for (final entry in expected.entries) {
      final asset = LumoTaskObjectArt.resolvedAsset(
        name: entry.key,
        emoji: entry.value,
      );
      expect(asset, isNotNull, reason: entry.key);
      await rootBundle.load(asset!);
    }
    for (var seed = 0; seed < 80; seed++) {
      final task = template('g1_word_image').concretize(seed);
      expect(expected.containsKey(task.answer), isTrue);
      expect(task.prompt, contains(expected[task.answer]!));
      final cue = LumoTaskObjectArt.matchWordImage(
        prompt: task.prompt,
        answer: task.answer,
      );
      expect(cue, isNotNull);
      expect(cue!.name, task.answer);
      expect(LumoTaskObjectArt.assetForName(cue.name), isNotNull);
    }
  });

  test('word-image display prompt hides the emoji but keeps the data prompt', () {
    const prompt = 'Welches Wort passt zum Bild: 🐶?';
    final cue = LumoTaskObjectArt.matchWordImage(
      prompt: prompt,
      answer: 'Hund',
    );
    expect(cue?.displayPrompt, 'Welches Wort passt zum Bild?');
    expect(cue?.name, 'Hund');
    expect(cue?.emoji, '🐶');
    expect(prompt, contains('🐶'));
  });

  testWidgets('word-image renderer shows the matching 3D picture for Hund',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveTaskRenderer(task: wordImageTask()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Welches Wort passt zum Bild?'), findsOneWidget);
    expect(find.text('Welches Wort passt zum Bild: 🐶?'), findsNothing);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, isNotEmpty);
    final asset = images
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toList();
    expect(asset, contains('assets/lumo_design/task_objects/hund.webp'));
    expect(find.text('Hund'), findsWidgets);
  });
}
