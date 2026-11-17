import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/cognitive_profile_generator.dart';
import 'package:lumo_lernen/core/cognitive_profile_repository.dart';
import 'package:lumo_lernen/core/iq/iq_test_repository.dart';
import 'package:lumo_lernen/core/iq/iq_test_session.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';
import 'package:lumo_lernen/domain/iq/iq_puzzle.dart';
import 'package:lumo_lernen/features/tests/cognitive_profile_screen.dart';
import 'package:lumo_lernen/features/tests/cognitive_profile_visual_prompt.dart';
import 'package:lumo_lernen/features/tests/iq/iq_boards.dart';
import 'package:lumo_lernen/features/tests/iq/iq_memory.dart';
import 'package:lumo_lernen/features/tests/iq/iq_puzzle_view.dart';
import 'package:lumo_lernen/features/tests/iq/iq_widgets.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import 'iq_test_support.dart';

class _RetryCognitiveRepository extends CognitiveProfileRepository {
  int calls = 0;
  final ids = <String>[];
  @override
  Future<void> save(CognitiveProfileResult result) async {
    calls++;
    ids.add(result.id);
    if (calls == 1) throw StateError('simulated failed storage');
    await super.save(result);
  }
}

class _RetryIqRepository extends IqTestRepository {
  int calls = 0;
  final ids = <String>[];
  @override
  Future<void> save(IqTestResult result) async {
    calls++;
    ids.add(result.id);
    if (calls == 1) throw StateError('simulated failed storage');
    await super.save(result);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIqFonts);
  setUp(() async => resetIqEnvironment());

  testWidgets('all 50 cognitive answers survive failed save and retry once',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(690, 829));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = iqTestApp();
    addTearDown(app.dispose);
    final repository = _RetryCognitiveRepository();
    final questions = CognitiveProfileGenerator.forGrade(2);
    await tester.pumpWidget(MaterialApp(
        home: CognitiveProfileScreen(appState: app, repository: repository)));
    await tester.tap(find.byKey(const ValueKey('cognitive-start-button')));
    await tester.pump();
    for (final question in questions) {
      if (question.stimulusVisibleMs > 0) {
        final context = LumoCompanionRequests.instance.taskContext.value;
        expect(context?.prompt, 'Merke dir die Folge.');
        expect(context?.localHelp, isNot(contains(question.stimulus!)));
        await tester
            .pump(Duration(milliseconds: question.stimulusVisibleMs + 1));
      }
      final choice = find.byKey(ValueKey(
          'cognitive-choice-${question.id}-${question.correctAnswer}'));
      await tester.scrollUntilVisible(choice.hitTestable(), 160,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(choice.hitTestable(), findsOneWidget, reason: question.id);
      await tester.tap(choice);
      await tester.pump();
      final next = tester
          .widget<IqPrimaryButton>(find.byKey(const ValueKey('cognitive-next')))
          .onPressed!;
      next();
      next(); // Reusing the outgoing button must not answer the new question.
      await tester.pump();
    }
    await settleIq(tester);
    expect(repository.calls, 1);
    expect(find.byKey(const ValueKey('cognitive-save-error')), findsOneWidget);
    expect(find.text('50 von 50 gelöst'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cognitive-next')));
    await settleIq(tester);
    expect(repository.calls, 2);
    expect(repository.ids.toSet(), hasLength(1));
    expect(find.text('50 von 50 gelöst'), findsOneWidget);
    final saved =
        await tester.runAsync(() => repository.loadAll(iqTestStudentId));
    expect(saved, hasLength(1));
    expect(saved!.single.totalCorrect, 50);
    expect(LumoCompanionRequests.instance.taskContext.value, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'IQ ignores outgoing submit callbacks and retires changed profiles',
      (tester) async {
    final app = iqTestApp();
    addTearDown(app.dispose);
    final session = IqTestSession(grade: 2, seed: 61);
    await tester.pumpWidget(iqScreenApp(app, session: session));
    await startIqTest(tester);
    await leaveAreaIntro(tester);
    final old = tester.widget<IqPuzzleView>(find.byType(IqPuzzleView));
    final first = session.current as IqChoicePuzzle;
    old.onSubmit([first.answer], 20);
    old.onSubmit([first.answer], 20);
    await tester.pump();
    expect(session.index, 1);
    expect(session.records, hasLength(1));
    final next = tester.widget<IqPuzzleView>(find.byType(IqPuzzleView));
    app.update(app.state.copyWith(childName: 'Another child'));
    await tester.pump();
    next.onSubmit([(session.current as IqChoicePuzzle).answer], 30);
    await tester.pump();
    expect(session.index, 1);
    expect(
        find.textContaining('Kinderprofil wurde gewechselt'), findsOneWidget);
    expect(LumoCompanionRequests.instance.taskContext.value, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      '36-item IQ finish retries the same result without duplicate rewards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(690, 829));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = iqTestApp();
    addTearDown(app.dispose);
    final repository = _RetryIqRepository();
    final session = IqTestSession(grade: 2, seed: 93, itemsPerArea: 6);
    while (session.index < 35) {
      final puzzle = session.current;
      session.answer(
          switch (puzzle) {
            IqChoicePuzzle p => [p.answer],
            IqMemoryPuzzle p => p.sequence,
          },
          durationMs: 100);
    }
    await tester
        .pumpWidget(iqScreenApp(app, session: session, repository: repository));
    await startIqTest(tester);
    await answerCurrent(tester, session, correct: true);
    await settleIq(tester);
    expect(repository.calls, 1);
    expect(app.state.stars, 0);
    final retry = find.byKey(const ValueKey('iq-save-retry'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await settleIq(tester);
    expect(repository.calls, 2);
    expect(repository.ids.toSet(), hasLength(1));
    final history =
        await tester.runAsync(() => repository.loadAll(iqTestStudentId));
    expect(history, hasLength(1));
    expect(history!.single.total, 36);
    expect(history.single.solved, 36);
    expect(app.state.stars, 9);
    expect(find.byKey(const ValueKey('iq-save-retry')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('exam LUMO repeats only the assignment and exposes no answer',
      (tester) async {
    final app = iqTestApp();
    addTearDown(app.dispose);
    final session = IqTestSession(grade: 2, seed: 62);
    await tester.pumpWidget(iqScreenApp(app, session: session));
    await startIqTest(tester);
    await leaveAreaIntro(tester);
    final requests = LumoCompanionRequests.instance;
    final context = requests.taskContext.value!;
    final identity = requests.learningIdentity.value!;
    expect(context.isExam, isTrue);
    expect(context.answerChoices, isEmpty);
    expect(context.lastCorrect, isNull);
    expect(context.explanation, isNull);
    expect(context.localHelp, isNot(contains(session.current.explanation)));
    expect(context.allowedActions, {
      LumoLearningAction.repeat,
      LumoLearningAction.slower,
      LumoLearningAction.stop
    });
    expect(
        requests.requestLearningAction(LumoLearningAction.hint,
            identity: identity),
        isFalse);
    expect(
        requests.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: '1'),
        isFalse);
    expect(
        requests.requestLearningAction(LumoLearningAction.repeat,
            identity: identity),
        isTrue);
    await tester.pump();
    expect(find.byKey(const ValueKey('exam-instruction')), findsOneWidget);
    expect(
        requests.requestLearningAction(LumoLearningAction.slower,
            identity: identity),
        isTrue);
    await tester.pump();
    await tester.tap(find.text('Auftrag'));
    await tester.pump();
    final instruction = tester
        .widget<Text>(find.byKey(const ValueKey('exam-instruction')))
        .data!;
    expect(instruction, contains(session.current.question));
    expect(instruction, isNot(contains(session.current.explanation)));
    expect(session.index, 0);
    await tester.tap(find.text('Stopp'));
    await tester.pump();
    expect(find.byKey(const ValueKey('exam-instruction')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('left-turn cognitive cue shows the actual direction',
      (tester) async {
    final question = CognitiveProfileGenerator.forGrade(3)
        .firstWhere((q) => q.prompt.contains('nach links'));
    await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: CognitiveProfileVisualPrompt(question: question))));
    expect(find.byIcon(Icons.rotate_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right_rounded), findsNothing);
    expect(find.text(question.correctAnswer), findsNothing);
  });

  testWidgets(
      'cognitive memory pauses its remaining exposure in the background',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(690, 829));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    var now = DateTime(2026, 11, 15, 12);
    final app = iqTestApp();
    addTearDown(app.dispose);
    final questions = CognitiveProfileGenerator.forGrade(2);
    await tester.pumpWidget(MaterialApp(
        home: CognitiveProfileScreen(appState: app, now: () => now)));
    await tester.tap(find.byKey(const ValueKey('cognitive-start-button')));
    await tester.pump();
    for (final q in questions.take(4)) {
      final choice =
          find.byKey(ValueKey('cognitive-choice-${q.id}-${q.correctAnswer}'));
      await tester.scrollUntilVisible(choice.hitTestable(), 160,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(choice);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('cognitive-next')));
      await tester.pump();
    }
    final memory = questions[4];
    expect(find.text(memory.stimulus!), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(
        find.byKey(const ValueKey('cognitive-memory-paused')), findsOneWidget);
    expect(find.text(memory.stimulus!), findsNothing);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(memory.stimulus!), findsOneWidget);
    final rest = Duration(milliseconds: memory.stimulusVisibleMs - 1001);
    now = now.add(rest);
    await tester.pump(rest);
    expect(find.text(memory.stimulus!), findsOneWidget);
    now = now.add(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text(memory.stimulus!), findsNothing);
    expect(find.text(memory.prompt), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'IQ memory resumes the current flash without replaying earlier fields',
      (tester) async {
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    var now = DateTime(2026, 11, 15, 12);
    var input = false;
    const puzzle = IqMemoryPuzzle(
        id: 'pause-memory',
        level: 1,
        question: 'Merke die Reihenfolge.',
        explanation: 'Zwei Felder.',
        gridSize: 3,
        sequence: [0, 4],
        showMs: 1000,
        gapMs: 200);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 300,
                height: 300,
                child: IqMemoryPlay(
                    puzzle: puzzle,
                    now: () => now,
                    leadIn: const Duration(milliseconds: 1),
                    onInputStart: () => input = true,
                    onChanged: (_) {},
                    layout: (_, parts) => parts.grid)))));
    now = now.add(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    bool lit(int cell) => tester
        .widget<IqMemoryTile>(find.descendant(
            of: find.byKey(ValueKey('iq-memory-tile-$cell')),
            matching: find.byType(IqMemoryTile)))
        .lit;
    expect(lit(0), isTrue);
    now = now.add(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(const ValueKey('iq-memory-paused')), findsOneWidget);
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(input, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(lit(0), isTrue);
    now = now.add(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(lit(0), isFalse);
    now = now.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(lit(4), isTrue);
    now = now.add(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(input, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'a cramped memory grid retains 48 dp targets and ignores double taps',
      (tester) async {
    final puzzle = IqMemoryPuzzle(
        id: 'memory',
        level: 8,
        question: 'Reihe merken',
        explanation: 'Die Folge hatte sieben Felder.',
        gridSize: 4,
        sequence: const [0, 1, 2, 3, 4, 5, 6],
        showMs: 1,
        gapMs: 1);
    List<int> selected = const [];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 180,
                height: 180,
                child: IqMemoryPlay(
                    puzzle: puzzle,
                    leadIn: Duration.zero,
                    onChanged: (value) => selected = value,
                    layout: (context, parts) => parts.grid)))));
    await tester.pump(const Duration(milliseconds: 30));
    final tile = find.byKey(const ValueKey('iq-memory-tile-0'));
    expect(tester.getSize(tile).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.tap(tile);
    await tester.pump();
    expect(selected, [0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
