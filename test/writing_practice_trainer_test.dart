import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/writing/expanded_writing_template_repository.dart';
import 'package:lumo_lernen/domain/writing/letter_practice_rules.dart';
import 'package:lumo_lernen/domain/writing/writing_domain.dart';
import 'package:lumo_lernen/domain/writing/writing_path_geometry.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/renderers/writing_task_renderer.dart';
import 'package:lumo_lernen/features/writing/widgets/lumo_letter_practice_board.dart';

TaskInstance writingTask(String target, {String? id}) => TaskInstance(
      taskInstanceId: id ?? 'practice-$target',
      templateId: 'writing-practice',
      childId: 'child-local',
      seedHash: '1953',
      subject: LearningSubject.deutsch,
      skillId: const SkillId('de.letter_writing'),
      taskType: TaskType.writingCanvas,
      difficulty: 1,
      parameters: <String, Object?>{'symbol': target},
      prompt: 'Schreibe: $target',
      correctAnswer: target,
      options: const [],
      visualPayload: VisualPayload(
          type: VisualType.writingPath,
          data: <String, Object?>{'symbol': target}),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 10, 16),
    );

Stroke stroke(List<List<double>> points) => Stroke(
      id: 'test',
      points: [
        for (final p in points) StrokePoint(x: p[0], y: p[1], timestampMs: 0),
      ],
    );

ButtonStyleButton button(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key)));

Future<void> drawAcross(WidgetTester tester, {double fraction = .5}) async {
  final surface = find.byKey(const ValueKey('lumo-learning-ink-surface'));
  final rect = tester.getRect(surface);
  final gesture = await tester.startGesture(
      rect.topLeft + Offset(rect.width * .25, rect.height * .2));
  const steps = 12;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(rect.topLeft +
        Offset(rect.width * (.25 + fraction * i / steps),
            rect.height * (.2 + .6 * i / steps)));
  }
  await gesture.up();
  await tester.pump();
}

/// LearningContent keeps Lumo alive with endless idle animations, so the
/// full path pumps a bounded time instead of waiting for a settled tree.
Future<void> settleRoute(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LetterPracticeRules', () {
    test('a stray tap is not a real attempt, a visible stroke is', () {
      expect(LetterPracticeRules.isRealAttempt(const []), isFalse);
      expect(
          LetterPracticeRules.isRealAttempt([
            stroke([
              [50, 50],
              [50.4, 50.3],
            ])
          ]),
          isFalse);
      expect(
          LetterPracticeRules.isRealAttempt([
            stroke([
              [20, 20],
              [40, 50],
              [55, 70],
            ])
          ]),
          isTrue);
    });

    test('words need a little more ink than one letter', () {
      final short = [
        stroke([
          [10, 50],
          [40, 50],
        ])
      ];
      expect(LetterPracticeRules.isRealAttempt(short), isTrue);
      expect(LetterPracticeRules.isRealAttempt(short, word: true), isFalse);
    });

    test('tips never contain a percentage or a grade', () {
      const low = WritingEvaluation(
        overallScore: .04,
        startPointScore: .1,
        directionScore: .1,
        coverageScore: .1,
        pathDistanceScore: .1,
        strokeOrderScore: .1,
        mirrored: false,
        incomplete: true,
        hints: [],
      );
      final tip = LetterPracticeRules.gentleTip(low)!;
      expect(tip, isNot(contains('%')));
      expect(tip.toLowerCase(), isNot(contains('falsch')));
      for (var i = 0; i < 8; i++) {
        expect(LetterPracticeRules.praise(i), isNot(contains('%')));
      }
    });
  });

  group('lowercase school print', () {
    const repository = ExpandedWritingTemplateRepository();

    test('every lowercase letter and umlaut has its own bounded trace', () {
      for (final symbol in [
        ...ExpandedWritingTemplateRepository.lowercaseLetters,
        ...ExpandedWritingTemplateRepository.uppercaseUmlauts,
      ]) {
        final model = repository.findOrFallback(symbol);
        expect(model.strokes, isNotEmpty, reason: symbol);
        for (final line in model.strokes) {
          final points = WritingPathGeometry.sample(line.pathData);
          expect(points, isNotEmpty, reason: symbol);
          for (final p in points) {
            expect(p.x, inInclusiveRange(0, 100), reason: symbol);
            expect(p.y, inInclusiveRange(0, 100), reason: symbol);
          }
        }
      }
      // A lowercase letter is never the capital's template.
      expect(
          repository.findOrFallback('a').strokes.map((s) => s.pathData),
          isNot(repository.findOrFallback('A').strokes.map((s) => s.pathData)));
    });

    test('lowercase bodies sit on the base line of the four school lines', () {
      expect(ExpandedWritingTemplateRepository.lineatureFor('a'),
          WritingLineature.fourLines);
      expect(ExpandedWritingTemplateRepository.lineatureFor('A'),
          WritingLineature.capitals);
      for (final symbol in ['a', 'c', 'e', 'm', 'n', 'o', 'u', 'x', 'z']) {
        final ys = [
          for (final line in repository.findOrFallback(symbol).strokes)
            ...WritingPathGeometry.sample(line.pathData).map((p) => p.y),
        ];
        final top = ys.reduce((a, b) => a < b ? a : b);
        final bottom = ys.reduce((a, b) => a > b ? a : b);
        expect(top, closeTo(38, 1.5), reason: '$symbol x-height');
        expect(bottom, closeTo(70, 1.5), reason: '$symbol base line');
      }
      for (final symbol in ['g', 'j', 'p', 'q', 'y']) {
        final ys = [
          for (final line in repository.findOrFallback(symbol).strokes)
            ...WritingPathGeometry.sample(line.pathData).map((p) => p.y),
        ];
        expect(ys.reduce((a, b) => a > b ? a : b), greaterThan(86),
            reason: '$symbol descender');
      }
    });
  });

  group('trainer page', () {
    for (final size in const [
      Size(320, 740), // Fold cover
      Size(412, 915), // phone
      Size(690, 829), // Fold open
      Size(915, 412), // landscape
    ]) {
      testWidgets('letter trainer fits ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        LetterPracticeResult? result;
        await tester.pumpWidget(MaterialApp(
          home: LumoLetterPracticePage(
            template: const ExpandedWritingTemplateRepository().findOrFallback('a'),
            progressLabel: 'Buchstabe 1 von 8',
            onDone: (value) => result = value,
          ),
        ));
        await tester.pump();
        final surface = find.byKey(const ValueKey('lumo-learning-ink-surface'));
        final canvas = tester.getSize(surface);
        expect(canvas.width, closeTo(canvas.height, 1.5));
        expect(canvas.shortestSide, greaterThanOrEqualTo(150));
        expect(find.byKey(const ValueKey('writing-target-badge')), findsOneWidget);
        expect(button(tester, 'writing-modal-finish').onPressed, isNull);
        expect(button(tester, 'writing-modal-skip').onPressed, isNotNull);
        expect(find.textContaining('%'), findsNothing);
        await drawAcross(tester);
        expect(button(tester, 'writing-modal-finish').onPressed, isNotNull);
        expect(find.byKey(const ValueKey('writing-praise')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('writing-modal-finish')));
        await tester.pump();
        expect(result?.practiced, isTrue);
        expect(result?.strokes, isNotEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a tiny tap does not unlock Weiter; Nochmals üben clears',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: LumoLetterPracticePage(
          template: const ExpandedWritingTemplateRepository().findOrFallback('L'),
          onDone: (_) {},
        ),
      ));
      final surface = find.byKey(const ValueKey('lumo-learning-ink-surface'));
      await tester.tapAt(tester.getCenter(surface));
      await tester.pump();
      expect(button(tester, 'writing-modal-finish').onPressed, isNull);
      expect(find.byKey(const ValueKey('writing-praise')), findsNothing);
      await drawAcross(tester);
      expect(button(tester, 'writing-modal-finish').onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('writing-modal-again')));
      await tester.pumpAndSettle();
      expect(button(tester, 'writing-modal-finish').onPressed, isNull);
      expect(find.byKey(const ValueKey('writing-praise')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Zeigen animates the guide without blocking input',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: LumoLetterPracticePage(
          template: const ExpandedWritingTemplateRepository().findOrFallback('B'),
          onDone: (_) {},
        ),
      ));
      await tester.tap(find.byKey(const ValueKey('writing-modal-demo')));
      await tester.pump(const Duration(milliseconds: 600));
      await drawAcross(tester);
      expect(button(tester, 'writing-modal-finish').onPressed, isNotNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('lesson task', () {
    testWidgets('a wrong typed spelling can be corrected and checked again',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final results = <WritingTaskResult>[];
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: SingleChildScrollView(
          child: WritingTaskRenderer(
            task: writingTask('Mama'),
            onSubmitted: results.add,
          ),
        ),
      )));
      final input = find.byKey(const ValueKey('writing-keyboard-answer'));
      await tester.ensureVisible(input);
      await tester.enterText(input, 'Mamma');
      await tester.pump();
      final check = find.byKey(const ValueKey('writing-keyboard-check'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
      await tester.enterText(input, 'Mama');
      await tester.pump();
      await tester.tap(check);
      await tester.pump();
      expect(results.map((r) => r.typedAnswer), ['Mamma', 'Mama']);
      expect(results.every((r) => r.graded), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the start button sits fully visible on the Fold cover',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: WritingTaskRenderer(task: writingTask('W'), onSubmitted: (_) {}),
          ),
        ),
      )));
      final start = tester.getRect(find.byKey(const ValueKey('writing-start')));
      expect(start.left, greaterThanOrEqualTo(0));
      expect(start.right, lessThanOrEqualTo(320));
      expect(start.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  });

  group('full learning path', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
    });
    tearDown(() => LumoVoice.instance.isEnabled = true);

    testWidgets(
        'letter appears, the finger writes, the attempt is accepted and the '
        'next task starts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final wallet = RewardWalletRepository();
      final state = LumoAppState(walletRepository: wallet);
      await tester.pump();
      state.update(state.state.copyWith(
        subject: 'Deutsch',
        unit: 'Schreiben üben',
        sessionKind: LumoSessionKind.quickPractice,
      ));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LearningContent(appState: state)),
      ));
      await tester.pump();

      TaskInstance current() => tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      final first = current();
      expect(first.taskType, TaskType.writingCanvas);
      expect(find.textContaining('Aufgabe 1 /'), findsOneWidget);
      final xpBefore = state.state.xp;

      // 1. The letter is shown large before writing.
      expect(find.text('${first.parameters['symbol']}'), findsWidgets);
      final start = find.byKey(const ValueKey('writing-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await settleRoute(tester);

      // 2. The finger draws in the trainer.
      expect(find.byType(LumoLetterPracticePage), findsOneWidget);
      await drawAcross(tester);

      // 3. The attempt is accepted with praise, never with a percentage.
      expect(find.byKey(const ValueKey('writing-praise')), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('writing-modal-finish')));
      await settleRoute(tester);

      // 4. The next task starts; practice is no invented XP.
      expect(find.byType(LumoLetterPracticePage), findsNothing);
      expect(current().taskInstanceId, isNot(first.taskInstanceId));
      expect(find.textContaining('Aufgabe 2 /'), findsOneWidget);
      expect(state.state.xp, xpBefore);

      // "Andere Aufgabe" swaps the task without counting progress.
      final second = current();
      final skip = find.byKey(const ValueKey('writing-parent-skip'));
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      await settleRoute(tester);
      expect(current().taskInstanceId, isNot(second.taskInstanceId));
      expect(find.textContaining('Aufgabe 2 /'), findsOneWidget);
      expect(state.state.xp, xpBefore);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
  });
}
