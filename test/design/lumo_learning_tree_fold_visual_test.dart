import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_learning_tree_card.dart';

const captureKey = ValueKey('learning-visual-capture');

Future<void> captureVisual(WidgetTester tester, String name) async {
  final folder = Platform.environment['LUMO_LEARNING_CAPTURES'];
  if (folder == null) return;
  final target =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
  await tester.runAsync(() async {
    final image = await target.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(folder + '/' + name + '.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

SkillRecord skill(String unit, {
  int correct = 0, int wrong = 0, int streak = 0, int misses = 0,
}) => SkillRecord(
  skillId: SkillRecord.makeId('Mathematik', unit),
  subject: 'Mathematik', unit: unit,
  correct: correct, wrong: wrong, currentStreak: streak,
  currentMisses: misses,
);

TaskInstance exampleTask() => TaskInstance(
  taskInstanceId: 'fold-visual-task',
  templateId: 'fold-visual',
  childId: 'visual-child',
  seedHash: 'fold-test',
  subject: LearningSubject.mathematik,
  skillId: const SkillId('math.plus20'),
  taskType: TaskType.multipleChoice,
  difficulty: 1,
  parameters: const {},
  prompt: '7 + 5 = ?',
  options: const [
    AnswerOption(id: '10', label: '10', payload: '10'),
    AnswerOption(id: '11', label: '11', payload: '11'),
    AnswerOption(id: '12', label: '12', payload: '12'),
    AnswerOption(id: '13', label: '13', payload: '13'),
  ],
  correctAnswer: '12',
  visualPayload: const VisualPayload(type: VisualType.none),
  helpPayload: const HelpPayload(shortHint: 'Zähle fünf zu sieben dazu.'),
  generatedAt: DateTime(2026, 10, 9),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Tests laden dieselbe Nunito-Schrift + Icons wie die echte App.
    // Sonst zeigt der Screenshot nur rechteckige Platzhalter.
    final nunito = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
    await nunito.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test('Lernbaum trennt Aktivität und sichere Beherrschung', () {
    final r = {
      'a': skill('Plus bis 20', correct: 5, streak: 5),
      'b': skill('Minus bis 20', correct: 2, wrong: 8),
      'c': skill('Einmaleins', wrong: 3, misses: 3),
    };
    final p = LumoTreeProgress(r);
    expect(p.practiced, 3);
    expect(p.mastered, 1);
    expect(p.needsPractice, 2);
    expect(p.attempts, 18);
    expect(LumoTreeProgress.status(r['a']!), 'Sicher geübt');
    expect(LumoTreeProgress.status(r['b']!), 'Noch üben');
    expect(LumoTreeProgress.status(r['c']!), 'Noch üben');
    // Zehn richtig allein dürfen nicht als "gemeistert" gelten.
    expect(LumoTreeProgress.isMastered(skill('Nur richtig', correct: 10)),
        isFalse);
    expect(LumoTreeProgress(<String, SkillRecord>{}).mastered, 0);
  });

  for (final target in [
    (Size(360, 1100), 'phone'),
    (Size(740, 1000), 'fold_content'),
    (Size(1000, 900), 'tablet'),
  ]) {
    testWidgets('Lernbaum ohne Überlauf auf ' + target.$2, (tester) async {
      await tester.binding.setSurfaceSize(target.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final skills = {
        'a': skill('Plus bis 20', correct: 5, streak: 5),
        'b': skill('Minus bis 20', correct: 1, wrong: 3, misses: 3),
        'c': skill('Uhrzeit lesen', correct: 2),
      };
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF031930),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: RepaintBoundary(
              key: captureKey,
              child: LumoLearningTreeCard(
                skills: skills, compact: false, onOpenWorld: () {},
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Mein Lernbaum'), findsOneWidget);
      expect(find.byKey(const ValueKey('lumo-tree-mastered')), findsOneWidget);
      expect(find.text('Plus bis 20'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureVisual(tester, 'learning_tree_' + target.$2);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Aufgaben haben echtes Handy-/Fold-Layout ' + target.$2,
        (tester) async {
      await tester.binding.setSurfaceSize(target.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final answers = <AdaptiveTaskAnswer>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF031930),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: RepaintBoundary(
              key: captureKey,
              child: AdaptiveTaskRenderer(
                task: exampleTask(), onAnswered: answers.add,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('7 + 5 = ?'), findsOneWidget);
      expect(find.byKey(const ValueKey('lesson-hint-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureVisual(tester, 'math_task_' + target.$2);
      await tester.ensureVisible(find.byKey(const ValueKey('lesson-hint-button')));
      await tester.tap(find.byKey(const ValueKey('lesson-hint-button')));
      await tester.pump();
      expect(find.textContaining('Tipp von Lumo'), findsWidgets);
      await tester.ensureVisible(find.text('12').last);
      await tester.tap(find.text('12').last);
      await tester.pump();
      expect(answers, hasLength(1));
      expect(answers.single.correct, isTrue);
      expect(answers.single.hintUsed, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
