import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';

import '../helpers/lumo_capture.dart';

TaskInstance task({
  String id = 'checked-eight-plus-five',
  LearningSubject subject = LearningSubject.mathematik,
  VisualType visual = VisualType.dots,
  String prompt = '8 + 5 = ?',
  Object answer = 13,
  List<Object> choices = const [12, 13, 14],
  Map<String, Object?> data = const {
    'operation': 'addition',
    'left': 8,
    'right': 5,
  },
}) =>
    TaskInstance(
      taskInstanceId: id,
      templateId: 'checked-workspace-fixture',
      childId: 'local-fixture',
      seedHash: id,
      subject: subject,
      skillId: const SkillId('workspace-fixture'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const {},
      prompt: prompt,
      options: [
        for (final value in choices)
          AnswerOption(id: '$value', label: '$value', payload: value)
      ],
      correctAnswer: answer,
      visualPayload: VisualPayload(type: visual, data: data),
      helpPayload: const HelpPayload(
        shortHint: 'Schau dir die gegebenen Angaben genau an.',
        guidedSteps: [
          'Schau genau hin.',
          'Probiere mit den Dingen.',
          'Prüfe einen Schritt nach dem anderen.'
        ],
      ),
      generatedAt: DateTime(2026, 11, 15),
    );

TaskInstance banana() => task(
      id: 'checked-banana',
      subject: LearningSubject.deutsch,
      visual: VisualType.syllables,
      prompt: 'Wie viele Silben hat Banane?',
      answer: 3,
      choices: const [2, 3, 4],
      data: const {
        'word': 'Banane',
        'syllables': ['Ba', 'na', 'ne']
      },
    );

TaskInstance pattern() => task(
      id: 'checked-pattern',
      subject: LearningSubject.logik,
      visual: VisualType.sequence,
      prompt: 'Kreis – Dreieck – Kreis – Dreieck – Kreis. Welche Form folgt?',
      answer: 'Dreieck',
      choices: const ['Kreis', 'Dreieck', 'Quadrat'],
      data: const {
        'sequence': ['Kreis', 'Dreieck', 'Kreis', 'Dreieck', 'Kreis'],
        'period': 2
      },
    );

Future<void> showWorkspace(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(440, 1000),
  double textScale = 1,
  bool quiet = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(fontFamily: 'Nunito', brightness: Brightness.dark),
    home: MediaQuery(
      data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: quiet),
      child: Scaffold(
        backgroundColor: const Color(0xFF071B32),
        body: RepaintBoundary(
          key: const ValueKey('workspace-capture'),
          child: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);

  testWidgets('8 + 5 conserves thirteen distinct objects while completing ten',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(tester,
        InteractiveTaskWorkspace(task: task(), onInteraction: events.add));
    expect(events.last.visibleState['inFrame'], 8);
    expect(events.last.visibleState['inSupply'], 5);
    expect((events.last.visibleState['objects'] as List).length, 13);
    await tap(tester, 'quantity-add');
    expect(events.last.visibleState['inFrame'], 9);
    expect(events.last.visibleState['freePlaces'], 1);
    await tap(tester, 'quantity-add');
    final state = events.last.visibleState;
    expect(state['inFrame'], 10);
    expect(state['inSupply'], 3);
    expect(state['freePlaces'], 0);
    final objects = state['objects'] as List;
    expect(objects.length, 13);
    expect(objects.map((o) => (o as Map)['id']).toSet().length, 13);
    expect(
        objects.where((o) => (o as Map)['location'] == 'ten-frame').length, 10);
    expect(events.last.explanation, contains('10 + 3'));
    expect(events.last.explanation, isNot(contains('= 13')));
    await tap(tester, 'workspace-reset');
    expect(events.last.visibleState['inFrame'], 8);
    expect(events.last.visibleState['inSupply'], 5);
  });

  testWidgets('subtraction refuses extra fast removals and keeps total fixed',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
          task: task(
              id: 'take-five',
              prompt: '12 − 5 = ?',
              answer: 7,
              data: const {'operation': 'subtraction', 'left': 12, 'right': 5}),
          onInteraction: events.add,
        ));
    // These callbacks intentionally run before a rebuild, like queued taps.
    final callbacks = [
      for (var i = 0; i < 8; i++)
        tester
            .widget<InkWell>(find.descendant(
                of: find.byKey(ValueKey('remaining-counter-$i')),
                matching: find.byType(InkWell)))
            .onTap!
    ];
    for (final callback in callbacks) {
      callback();
    }
    await tester.pumpAndSettle();
    expect(events.last.visibleState['remaining'], 7);
    expect(events.last.visibleState['stillToRemove'], 0);
    expect((events.last.visibleState['removed'] as List).length, 5);
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('removed-counter-')),
        findsNWidgets(5));
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('remaining-counter-')),
        findsNWidgets(7));
    await tap(tester, 'removed-counter-0');
    expect(events.last.visibleState['remaining'], 8);
  });

  testWidgets('group actions cannot create or lose counters during rapid taps',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
          task: task(
              id: 'one-divided-one',
              prompt: '1 : 1 = ?',
              answer: 1,
              visual: VisualType.divisionGroups,
              data: const {'operation': 'division', 'left': 1, 'right': 1}),
          onInteraction: events.add,
        ));
    final add = tester
        .widget<OutlinedButton>(find.byKey(const ValueKey('group-0-add')))
        .onPressed!;
    add();
    add();
    add();
    await tester.pumpAndSettle();
    expect(events.last.visibleState['allocations'], [1]);
    expect(events.last.visibleState['supply'], 0);
    final remove = tester
        .widget<InkWell>(find.descendant(
            of: find.byKey(const ValueKey('group-0-counter-0')),
            matching: find.byType(InkWell)))
        .onTap!;
    remove();
    remove();
    remove();
    await tester.pumpAndSettle();
    expect(events.last.visibleState['allocations'], [0]);
    expect(events.last.visibleState['supply'], 1);
  });

  testWidgets(
      'Banane uses verified units and host highlight, never an audio timer',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(tester,
        InteractiveTaskWorkspace(task: banana(), onInteraction: events.add));
    expect(find.text('Banane'), findsOneWidget);
    expect(find.byKey(const ValueKey('syllable-0')), findsNothing);
    await tap(tester, 'workspace-reveal-syllables');
    expect(events.last.isHelp, isTrue);
    expect(find.text('Ba'), findsOneWidget);
    expect(find.text('na'), findsOneWidget);
    expect(find.text('ne'), findsOneWidget);
    await tap(tester, 'syllable-1');
    expect(events.last.objectId, 'syllable-1');
    expect(events.last.visibleState['activeSyllable'], 1);
    await tester.pump(const Duration(seconds: 3));
    expect(events.last.visibleState['activeSyllable'], 1);
    await tap(tester, 'workspace-arrange-syllables');
    for (final id in [1, 2, 0]) {
      await tap(tester, 'token-bank-$id');
    }
    expect(events.last.visibleState['arranged'], [1, 2, 0]);
    expect(find.text('Ba'), findsNWidgets(2));
  });

  testWidgets('pattern uses shapes, highlights repetition and does not answer',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(tester,
        InteractiveTaskWorkspace(task: pattern(), onInteraction: events.add));
    expect(find.byKey(const ValueKey('interactive-workspace-pattern')),
        findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('pattern-$i')), findsOneWidget);
    }
    expect(find.text('Dreieck'), findsNothing,
        reason: 'The answer is not printed by the exploration surface.');
    await tap(tester, 'workspace-show-pattern-group');
    expect(events.last.isHelp, isTrue);
    expect(events.last.visibleState['groupVisible'], isTrue);
    expect(find.byKey(const ValueKey('pattern-group-hint')), findsOneWidget);
    expect(events.last.explanation, isNot(contains('kommt Dreieck')));
  });

  testWidgets('unverified arithmetic never becomes a false quantity model',
      (tester) async {
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(answer: 15),
            fallback: const Text('Vorliegende Aufgabe')));
    expect(find.byKey(const ValueKey('interactive-workspace-evidence')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('quantity-add')), findsNothing);
    await tap(tester, 'workspace-inspect-evidence');
    await tap(tester, 'evidence-0');
    expect(find.text('Vorliegende Aufgabe'), findsOneWidget);
  });

  testWidgets('changing tasks resets all exploration state without scoring',
      (tester) async {
    var current = task();
    late StateSetter update;
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(tester, StatefulBuilder(builder: (context, setState) {
      update = setState;
      return InteractiveTaskWorkspace(task: current, onInteraction: events.add);
    }));
    await tap(tester, 'quantity-add');
    update(() => current = banana());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quantity-add')), findsNothing);
    expect(find.byKey(const ValueKey('syllable-0')), findsNothing);
    expect(events.last.taskId, 'checked-banana');
    expect(events.last.action, 'workspaceReady');
  });

  testWidgets('normal renderer records assistance and locks duplicate answers',
      (tester) async {
    final answers = <AdaptiveTaskAnswer>[];
    await showWorkspace(
        tester,
        AdaptiveTaskRenderer(
            task: banana(), onAnswered: answers.add, reduceMotion: true));
    await tap(tester, 'workspace-reveal-syllables');
    final answer = find.text('3');
    await tester.ensureVisible(answer);
    await tester.pump();
    await tester.tap(answer);
    await tester.pumpAndSettle();
    expect(answers.length, 1);
    expect(answers.single.correct, isTrue);
    expect(answers.single.hintUsed, isTrue);
    await tester.tap(answer);
    await tester.pumpAndSettle();
    expect(answers.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fraction parts stay distinct through rapid taps and reset',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(
                id: 'quarter-plus-two-quarters',
                visual: VisualType.fractionPizza,
                prompt: '1/4 + 2/4 = ?',
                answer: '3/4',
                choices: const [
                  '1/4',
                  '2/4',
                  '3/4'
                ],
                data: const {
                  'operation': 'fraction_addition',
                  'numerator': 1,
                  'denominator': 4,
                  'extra': 2
                }),
            onInteraction: events.add),
        size: const Size(320, 800));
    expect(events.last.visibleState['denominator'], 4);
    expect(events.last.visibleState['selectedParts'], [0]);
    final callbacks = [
      for (final index in [1, 2])
        tester
            .widget<InkWell>(find.descendant(
                of: find.byKey(ValueKey('fraction-piece-$index')),
                matching: find.byType(InkWell)))
            .onTap!
    ];
    for (final callback in callbacks) {
      callback();
    }
    await tester.pumpAndSettle();
    expect(events.last.visibleState['selectedParts'], [0, 1, 2]);
    expect(events.last.explanation, contains('3 sind gerade markiert'));
    expect(find.byKey(const ValueKey('fraction-piece-4')), findsNothing);
    expect(tester.takeException(), isNull);
    await tap(tester, 'workspace-reset');
    expect(events.last.visibleState['selectedParts'], [0]);
    for (final event in events) {
      expect(event.visibleState['objectIds'], contains(event.objectId));
    }
  });

  testWidgets('incorrect fraction payload cannot display a false model',
      (tester) async {
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(
                visual: VisualType.fractionPizza,
                prompt: '1/4 + 2/4 = ?',
                answer: '4/4',
                data: const {
              'operation': 'fraction_addition',
              'numerator': 1,
              'denominator': 4,
              'extra': 2
            })));
    expect(find.byKey(const ValueKey('interactive-workspace-evidence')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('fraction-disc')), findsNothing);
  });

  testWidgets('decimal columns preserve tenths without creating whole objects',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(
                id: 'exact-tenths',
                visual: VisualType.none,
                prompt: '0,1 + 0,2 = ?',
                answer: '0,3',
                choices: const [
                  '0,3',
                  '0,4',
                  '0,5'
                ],
                data: const {
                  'operation': 'decimal_addition',
                  'decimalPlaces': 1,
                  'leftMinorUnits': 1,
                  'rightMinorUnits': 2,
                  'resultMinorUnits': 3
                }),
            onInteraction: events.add),
        size: const Size(320, 800),
        textScale: 1.4);
    expect(events.last.visibleState['kind'], 'decimal');
    expect(events.last.visibleState['decimalPlaces'], 1);
    expect(events.last.visibleState['leftMinorUnits'], 1);
    expect(events.last.visibleState['rightMinorUnits'], 2);
    expect(events.last.visibleState.containsKey('left'), isFalse);
    expect(events.last.visibleState.containsKey('objects'), isFalse);
    expect(find.byKey(const ValueKey('quantity-add')), findsNothing);
    expect(find.text('0,3'), findsNothing);
    await tap(tester, 'decimal-place-1');
    expect(events.last.explanation, contains('Zehntel'));
    expect(events.last.visibleState['focusedPlace'], 1);
    expect(events.last.isHelp, isFalse);
    expect(events.last.visibleState['objectIds'], contains('decimal-place-1'));
  });

  testWidgets('decimal answer and unit scale must agree before display',
      (tester) async {
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(
                visual: VisualType.none,
                prompt: '0,1 + 0,2 = ?',
                answer: '3',
                data: const {
              'operation': 'decimal_addition',
              'decimalPlaces': 1,
              'leftMinorUnits': 1,
              'rightMinorUnits': 2,
              'resultMinorUnits': 3
            })));
    expect(find.byKey(const ValueKey('interactive-workspace-evidence')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('decimal-place-0')), findsNothing);
  });

  testWidgets('plant part inspection focuses the actual part and records help',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(
                id: 'plant-water',
                subject: LearningSubject.sachkunde,
                visual: VisualType.none,
                prompt: 'Welcher Pflanzenteil nimmt Wasser auf?',
                answer: 'Wurzel',
                choices: const ['Wurzel', 'Blatt', 'Blüte'],
                data: const {'sceneKind': 'plant_parts', 'plantPart': 'root'}),
            onInteraction: events.add),
        size: const Size(320, 800),
        textScale: 1.4);
    expect(events.last.visibleState['focusedPart'], isNull);
    await tap(tester, 'plant-root');
    expect(events.last.visibleState['focusedPart'], 'root');
    expect(events.last.explanation, contains('nehmen Wasser'));
    expect(events.last.isHelp, isTrue);
    expect(
        events.last.visibleState['objectIds'],
        containsAll(
            ['plant-root', 'plant-stem', 'plant-leaf', 'plant-flower']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('decreasing number pattern reveals its step but not its answer',
      (tester) async {
    final events = <TaskWorkspaceInteraction>[];
    await showWorkspace(
        tester,
        InteractiveTaskWorkspace(
            task: task(
                id: 'count-back-two',
                subject: LearningSubject.logik,
                visual: VisualType.sequence,
                prompt: '10, 8, 6, 4, ?',
                answer: 2,
                data: const {
                  'sequence': [10, 8, 6, 4],
                  'step': -2
                }),
            onInteraction: events.add),
        size: const Size(320, 800));
    expect(events.last.visibleState['kind'], 'numberPattern');
    expect(find.text('2'), findsNothing);
    await tap(tester, 'workspace-show-number-step');
    expect(find.text('Immer − 2'), findsOneWidget);
    expect(events.last.visibleState['stepVisible'], isTrue);
    expect(events.last.isHelp, isTrue);
    expect(events.last.explanation, contains('Zahlenschritt'));
    expect(
        events.last.visibleState['objectIds'], contains(events.last.objectId));
  });

  testWidgets('host speed and replay update the same current workspace',
      (tester) async {
    var slow = false;
    var replay = 0;
    late StateSetter update;
    final events = <TaskWorkspaceInteraction>[];
    final current = task();
    await showWorkspace(tester, StatefulBuilder(builder: (context, setState) {
      update = setState;
      return InteractiveTaskWorkspace(
          task: current,
          slow: slow,
          replaySerial: replay,
          onInteraction: events.add);
    }));
    await tap(tester, 'quantity-add');
    update(() => slow = true);
    await tester.pumpAndSettle();
    expect(find.text('Normales Tempo'), findsOneWidget);
    await tap(tester, 'workspace-change-representation');
    expect(events.last.visibleState['slow'], isTrue);
    expect(events.last.visibleState['representation'], 'numberLine');
    expect(events.last.visibleState['objectIds'], isNot(contains('initial-0')));
    expect(events.last.visibleState['objectIds'], contains('number-line'));
    update(() => replay++);
    await tester.pumpAndSettle();
    expect(events.last.visibleState['representation'], 'counters');
    expect(events.last.visibleState['moved'], 0);
    expect(events.last.visibleState['slow'], isTrue);
    for (final event in events) {
      expect(event.visibleState['objectIds'], contains(event.objectId));
    }
  });

  testWidgets('syllable selection follows actual host segment changes',
      (tester) async {
    String? active = 'syllable-0';
    late StateSetter update;
    final current = banana();
    await showWorkspace(tester, StatefulBuilder(builder: (context, setState) {
      update = setState;
      return InteractiveTaskWorkspace(
          task: current, helpLevel: 2, activeObjectId: active);
    }));
    expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('syllable-0')))
            .properties
            .selected,
        isTrue);
    update(() => active = 'syllable-2');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('syllable-2')))
            .properties
            .selected,
        isTrue);
    expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('syllable-0')))
            .properties
            .selected,
        isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('syllable-2')))
            .properties
            .selected,
        isTrue);
  });

  for (final config in [
    ('phone-320', const Size(320, 800), 1.0),
    ('fold-cover', const Size(344, 882), 1.4),
    ('fold-open', const Size(840, 900), 1.0),
  ]) {
    for (final entry in [
      ('quantity', task()),
      ('syllables', banana()),
      ('pattern', pattern())
    ]) {
      testWidgets('real ${entry.$1} view fits ${config.$1}', (tester) async {
        await showWorkspace(
            tester, AdaptiveTaskRenderer(task: entry.$2, reduceMotion: true),
            size: config.$2, textScale: config.$3);
        final key = switch (entry.$1) {
          'quantity' => 'quantity-add',
          'syllables' => 'workspace-reveal-syllables',
          _ => 'workspace-show-pattern-group',
        };
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        await tap(tester, key);
        if (entry.$1 == 'quantity') await tap(tester, key);
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['LUMO_WORKSPACE_CAPTURES'];
        if (directory != null) {
          // Capture the actual interactive Flutter view after actual actions.
          // This intentionally makes no claim of a physical-device capture.
          final workspace = find.byType(InteractiveTaskWorkspace);
          await tester.ensureVisible(workspace);
          await tester.pumpAndSettle();
          await captureLumoBoundary(tester, const ValueKey('workspace-capture'),
              '$directory/${config.$1}-${entry.$1}.png');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
