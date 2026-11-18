// L1 "Ehrlich üben": the real LearningContent flow.
//
// Independent means first try without help; a mistake gets feedback that
// fits it, then a worked solution; mistakes come back as similar tasks;
// rewards and summaries say what really happened.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_mistake_help_card.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/widgets/design/lumo_answer_crystal.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _quiet = AppSettings(
  aiProxyEnabled: false,
  voiceEnabled: false,
  autoReadEnabled: false,
  soundEnabled: false,
  reduceAnimations: true,
);

/// Records what would be spoken. Proves when audio starts, not how it sounds.
class _Voice extends Fake implements LumoVoice {
  final spoken = <String>[];
  int revision = 0;
  int stops = 0;

  /// While true a playback stays "speaking" until [finish] is called.
  bool hold = false;
  final _playing = <Completer<void>>[];

  void finish() {
    for (final playback in _playing) {
      if (!playback.isCompleted) playback.complete();
    }
    _playing.clear();
  }

  @override
  final status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  @override
  final lastError = ValueNotifier<String?>(null);
  @override
  int get requestRevision => revision;
  @override
  bool get isEnabled => true;
  @override
  Future<bool> localSpeechAvailable() async => true;
  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm, double speedFactor = 1}) {
    revision++;
    spoken.add(text);
    if (!hold) return Future<void>.value();
    final playback = Completer<void>();
    _playing.add(playback);
    return playback.future;
  }

  @override
  Future<void> stop() async {
    revision++;
    stops++;
  }
}

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Answers are saved in the background through a serialized storage queue.
/// Waits until everything the lesson recorded so far is written; ending a
/// test earlier would leave that queue blocked for the next test.
Future<void> _drain(WidgetTester tester, LumoAppState app) async {
  var done = false;
  unawaited(Future.wait<void>([
    app.flushLearningProgress(),
    app.flushTutorEvidence(),
  ]).then<void>((_) {}, onError: (Object _) {}).whenComplete(() => done = true));
  for (var round = 0; round < 600 && !done; round++) {
    await _settle(tester, 1);
  }
  expect(done, isTrue, reason: 'learning storage did not finish');
  await _settle(tester, 4);
}

/// Lets the short pause before automatic reading pass.
Future<void> _afterReadingPause(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await _settle(tester);
}

Future<LumoAppState> _open(
  WidgetTester tester, {
  int grade = 1,
  String subject = 'Mathematik',
  String unit = 'Plus bis 10',
  LumoSessionKind kind = LumoSessionKind.quickPractice,
  AppSettings settings = _quiet,
  LumoVoice? voice,
  int stars = 0,
  Size size = const Size(1000, 1400),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late LumoAppState app;
  await tester.runAsync(() async {
    final wallet = RewardWalletRepository();
    app = LumoAppState(walletRepository: wallet);
    await app.ensureSettingsLoaded();
    await app.loadLearningProfile();
    if (stars > 0) {
      await wallet.addStars(stars);
      await app.hydrateFromWallet();
    }
    app.updateSettings(settings);
    app.update(app.state.copyWith(
      childName: 'Mira',
      grade: grade,
      subject: subject,
      unit: unit,
      sessionKind: kind,
      testLevel: 0,
    ));
  });
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LearningContent(appState: app, voice: voice))));
  await _settle(tester);
  addTearDown(() async {
    await _drain(tester, app);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester, 4);
    app.dispose();
    LumoCompanionRequests.instance.clearLearningScope();
  });
  return app;
}

AdaptiveTaskRenderer _renderer(WidgetTester tester) =>
    tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));

String _value(AnswerOption option) => '${option.payload ?? option.label}';

List<AnswerOption> _wrongOptions(TaskInstance task) => task.options
    .where((option) => _value(option) != '${task.correctAnswer}')
    .toList();

AnswerOption _rightOption(TaskInstance task) => task.options
    .firstWhere((option) => _value(option) == '${task.correctAnswer}');

LumoAnswerCrystal _crystal(WidgetTester tester, AnswerOption option) => tester
    .widgetList<LumoAnswerCrystal>(find.byType(LumoAnswerCrystal))
    .singleWhere((crystal) => crystal.label == option.label);

/// Taps a real answer crystal, as a child would.
Future<void> _tap(WidgetTester tester, AnswerOption option) async {
  final target = find
      .descendant(
          of: find.byType(AdaptiveTaskRenderer),
          matching: find.text(option.label))
      .last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Answers through the renderer's own callback (for answers that need an
/// exact value, and for fast-forwarding through a session).
Future<void> _answer(WidgetTester tester, Object answer,
    {required bool correct}) async {
  final renderer = _renderer(tester);
  renderer.onAnswered!(AdaptiveTaskAnswer(
      task: renderer.task, answer: answer, correct: correct));
  await tester.pump();
}

Future<void> _solve(WidgetTester tester) async {
  await _answer(tester, _renderer(tester).task.correctAnswer, correct: true);
  await _next(tester);
}

Future<void> _next(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pump(const Duration(milliseconds: 400));
  await _settle(tester, 2);
}

Future<void> _failThenSolveTogether(WidgetTester tester) async {
  final task = _renderer(tester).task;
  await _tap(tester, _wrongOptions(task).first);
  await _tap(tester, _rightOption(_renderer(tester).task));
  await _next(tester);
}

Future<SkillRecord> _stored(
    WidgetTester tester, LumoAppState app, String subject, String unit) async {
  await _drain(tester, app);
  return app.learningSkills()[SkillRecord.makeId(subject, unit)]!;
}

String _header(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('lesson-progress-label')))
    .data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LumoVoiceClips.ensureFreeLoaded);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  group('1 · independent means first try without help', () {
    testWidgets('right on the first try is solved alone', (tester) async {
      final app = await _open(tester);
      final task = _renderer(tester).task;
      await _tap(tester, _rightOption(task));

      expect(find.text('Allein gelöst'), findsOneWidget);
      expect(find.text('Gemeinsam gelöst'), findsNothing);
      expect(find.text('+6 Sterne'), findsOneWidget);
      expect(_crystal(tester, _rightOption(task)).state,
          LumoCrystalState.correct);
      expect(find.byKey(const ValueKey('lesson-hint-button')), findsNothing);
      expect(app.state.stars, 6);
      // No ability claim after a single answer.
      expect(find.textContaining('Können'), findsNothing);
      expect(find.textContaining('%'), findsNothing);

      final record = await _stored(tester, app, 'Mathematik', 'Plus bis 10');
      expect(record.assessed.correct, 1);
      expect(record.hintCount, 0);
      expect(record.independentDays, hasLength(1));
    });

    testWidgets('right after one wrong pick is solved together, not alone',
        (tester) async {
      final app = await _open(tester);
      final task = _renderer(tester).task;
      await _tap(tester, _wrongOptions(task).first);
      expect(app.state.stars, 0, reason: 'a mistake costs nothing');
      await _tap(tester, _rightOption(task));

      expect(find.text('Gemeinsam gelöst'), findsWidgets);
      expect(find.text('Allein gelöst'), findsNothing);
      expect(find.text('+2 Sterne'), findsOneWidget);
      expect(app.state.stars, 2, reason: 'together earns 2, alone 6');

      final record = await _stored(tester, app, 'Mathematik', 'Plus bis 10');
      expect(record.correct, 1);
      expect(record.wrong, 1);
      expect(record.assessed.correct, 0,
          reason: 'a win by elimination is not independent evidence');
      expect(record.assessed.wrong, 1,
          reason: 'the first try was an independent mistake');
      expect(record.independentDays, isEmpty);

      await _drain(tester, app);
      final journey = app.learningJourney().values.single;
      expect(journey.independentCorrect, 0);
      expect(journey.assistedCorrect, 1);
      expect(journey.needsPractice, isTrue,
          reason: 'the topic stays due in the spaced review');
    });

    testWidgets('an opened tip also makes the answer solved together',
        (tester) async {
      final app = await _open(tester);
      final task = _renderer(tester).task;
      final hint = find.byKey(const ValueKey('lesson-hint-button'));
      await tester.ensureVisible(hint);
      await tester.tap(hint);
      await tester.pump();
      await _tap(tester, _rightOption(task));

      expect(find.text('Gemeinsam gelöst'), findsWidgets);
      expect(app.state.stars, 2);
      final record = await _stored(tester, app, 'Mathematik', 'Plus bis 10');
      expect(record.assessed.correct, 0);
    });
  });

  group('2 · help that fits the mistake', () {
    testWidgets('a recognised mistake is explained; a tip is offered',
        (tester) async {
      await _open(tester);
      final task = _renderer(tester).task;
      final correct = int.parse('${task.correctAnswer}');
      // One off: use the real crystal if the task offers it.
      final offByOne = _wrongOptions(task).where((option) =>
          ((int.tryParse(_value(option)) ?? 99) - correct).abs() == 1);
      if (offByOne.isNotEmpty) {
        await _tap(tester, offByOne.first);
      } else {
        await _answer(tester, correct + 1, correct: false);
      }

      expect(find.byType(LumoMistakeFeedbackCard), findsOneWidget);
      expect(find.text('Das ist passiert'), findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('mistake-feedback-message')))
              .data,
          'Du warst nur um 1 daneben. Zähl noch einmal genau nach.');
      expect(find.text('Du hast noch einen Versuch.'), findsOneWidget);
      // The same task is still open and the solution is not shown.
      expect(_renderer(tester).task.taskInstanceId, task.taskInstanceId);
      expect(find.byType(LumoWorkedSolutionCard), findsNothing);
      expect(find.textContaining('Richtige Antwort'), findsNothing);

      // Hint level 1 is offered visibly and opens inside the card.
      final tip = find.byKey(const ValueKey('mistake-feedback-hint-button'));
      expect(tip, findsOneWidget);
      expect(tester.getSize(tip).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(tip);
      await tester.tap(tip);
      await tester.pump();
      expect(find.byKey(const ValueKey('mistake-feedback-hint')), findsOneWidget);
    });

    testWidgets('an unrecognised mistake gets a neutral sentence, no lottery',
        (tester) async {
      await _open(tester);
      final task = _renderer(tester).task;
      final correct = int.parse('${task.correctAnswer}');
      await _answer(tester, correct + 7, correct: false);

      expect(find.text('Schau noch einmal genau'), findsOneWidget);
      final message = tester
          .widget<Text>(find.byKey(const ValueKey('mistake-feedback-message')))
          .data!;
      expect(
          message,
          'Das passt noch nicht. Lies die Aufgabe noch einmal in Ruhe und '
          'schau genau, was gefragt ist.');
      expect(find.textContaining('Fast'), findsNothing);
      expect(find.textContaining('verwechselt'), findsNothing,
          reason: 'not every wrong plus answer is a sign mix-up');
    });

    testWidgets('the sign tip appears only for the opposite operation',
        (tester) async {
      await _open(tester);
      final task = _renderer(tester).task;
      final numbers = RegExp(r'\d+')
          .allMatches(task.prompt)
          .map((m) => int.parse(m.group(0)!))
          .toList();
      expect(task.prompt, contains('+'));
      final difference = numbers[0] - numbers[1];
      final correct = int.parse('${task.correctAnswer}');
      // 3 + 1 = 4 and 3 − 1 = 2 differ by two; only then it is a mix-up.
      if ((correct - difference).abs() > 1) {
        await _answer(tester, difference, correct: false);
        expect(
            tester
                .widget<Text>(
                    find.byKey(const ValueKey('mistake-feedback-message')))
                .data,
            contains('Plus und Minus verwechselt'));
      }
    });

    testWidgets(
        'the second wrong answer shows the worked path, never skips and '
        'leaves no blind tap', (tester) async {
      final app = await _open(tester);
      final task = _renderer(tester).task;
      final wrong = _wrongOptions(task);
      expect(wrong.length, greaterThanOrEqualTo(3));
      await _tap(tester, wrong[0]);
      await _tap(tester, wrong[1]);

      expect(find.byType(LumoWorkedSolutionCard), findsOneWidget);
      expect(find.byType(LumoMistakeFeedbackCard), findsNothing);
      expect(find.text('Wir lösen es gemeinsam – Schritt für Schritt'),
          findsOneWidget);
      final card = tester
          .widget<LumoWorkedSolutionCard>(find.byType(LumoWorkedSolutionCard));
      expect(card.steps.length, inInclusiveRange(2, 3));
      expect(card.steps.every((step) => step.length <= 200), isTrue,
          reason: 'short steps a young child can read');
      expect(card.steps.last, contains('${task.correctAnswer}'),
          reason: 'the last step states the solution');
      // Nothing else competes with the explained answer.
      expect(find.byKey(const ValueKey('lesson-hint-button')), findsNothing);
      expect(find.text('Tippe jetzt die richtige Antwort an.'), findsOneWidget);

      // Every answer can be tapped again: no "last one left".
      final renderer = _renderer(tester);
      expect(renderer.guided, isTrue);
      expect(renderer.task.taskInstanceId, task.taskInstanceId);
      final crystals = tester
          .widgetList<LumoAnswerCrystal>(find.byType(LumoAnswerCrystal))
          .toList();
      expect(crystals.length, task.options.length);
      expect(crystals.every((crystal) => crystal.onPressed != null), isTrue);
      expect(
          crystals.every((c) => c.state == LumoCrystalState.neutral), isTrue);

      // Waiting does not skip the task.
      await tester.pump(const Duration(seconds: 20));
      expect(_renderer(tester).task.taskInstanceId, task.taskInstanceId);

      // A further wrong tap only points back to the explained answer.
      await _tap(tester, wrong[2]);
      expect(_renderer(tester).task.taskInstanceId, task.taskInstanceId);
      expect(find.textContaining('Schau auf Schritt'), findsOneWidget);

      await _tap(tester, _rightOption(task));
      expect(find.text('Gemeinsam gelöst'), findsWidgets);
      expect(_crystal(tester, _rightOption(task)).state,
          LumoCrystalState.correct,
          reason: 'the tapped solution is marked as right');
      expect(find.byType(LumoWorkedSolutionCard), findsNothing);
      expect(app.state.stars, 2);
      final record = await _stored(tester, app, 'Mathematik', 'Plus bis 10');
      expect(record.correct, 1);
      expect(record.wrong, 2,
          reason: 'the tap inside the worked solution is not counted again');
      expect(record.assessed.correct, 0);
      expect(record.assessed.wrong, 1);
    });
  });

  group('3 · mistakes come back as a similar task', () {
    testWidgets('the twin returns two tasks later, past the no-repeat guard',
        (tester) async {
      final app = await _open(tester, grade: 2, unit: 'Alle');
      final source = _renderer(tester).task;
      final sourceUnit = source.parameters['unit'];
      await _failThenSolveTogether(tester);
      expect(find.textContaining('Eine ähnliche'), findsNothing);

      // Task 2: something else, no announcement.
      expect(find.byType(LumoTwinTaskBanner), findsNothing);
      await _solve(tester);

      // Task 3: the similar task, announced kindly.
      expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
      expect(find.text('Noch eine ähnliche – jetzt schaffst du sie allein!'),
          findsOneWidget);
      final twin = _renderer(tester).task;
      expect(twin.parameters['unit'], sourceUnit,
          reason: 'same unit although it was practised two tasks ago');
      expect(twin.subject, source.subject);
      expect(
          twin.prompt != source.prompt ||
              '${twin.correctAnswer}' != '${source.correctAnswer}',
          isTrue,
          reason: 'a new task, not the same one again');

      // Solved on the first try: specific praise and independent evidence.
      await _tap(tester, _rightOption(twin));
      expect(find.text('Jetzt allein geschafft!'), findsOneWidget);
      expect(find.textContaining('ganz allein geschafft'), findsOneWidget);
      expect(find.text('Allein gelöst'), findsOneWidget);
      expect(app.state.stars, 2 + 6 + 6);
      final record =
          await _stored(tester, app, 'Mathematik', '$sourceUnit');
      expect(record.assessed.correct, greaterThanOrEqualTo(1));
    });

    testWidgets('a twin that fails again is solved together, not queued again',
        (tester) async {
      final app = await _open(tester); // grade 1: six tasks
      await _failThenSolveTogether(tester); // 1
      await _solve(tester); // 2
      expect(find.byType(LumoTwinTaskBanner), findsOneWidget); // 3 = twin
      final twin = _renderer(tester).task;
      final wrong = _wrongOptions(twin);
      await _tap(tester, wrong[0]);
      await _tap(tester, wrong[1]);
      expect(find.byType(LumoWorkedSolutionCard), findsOneWidget);
      await _tap(tester, _rightOption(twin));
      expect(find.text('Gemeinsam gelöst'), findsWidgets);
      await _next(tester);

      for (var question = 4; question <= 6; question++) {
        expect(_header(tester), 'Aufgabe $question / 6',
            reason: 'no extension for a twin');
        expect(find.byType(LumoTwinTaskBanner), findsNothing,
            reason: 'task $question must not be a third meeting');
        await _solve(tester);
      }
      expect(find.text('Einheit beendet'), findsOneWidget);

      // It stays due in the spaced review of the following days.
      await _drain(tester, app);
      final journey = app.learningJourney().values.single;
      expect(journey.needsPractice, isFalse,
          reason: 'the last three tasks were solved alone again');
      expect(journey.assistedCorrect, 2);
    });

    testWidgets('the session grows by at most two tasks for waiting twins',
        (tester) async {
      await _open(tester); // grade 1: six tasks
      for (var question = 1; question <= 5; question++) {
        expect(_header(tester), 'Aufgabe $question / 6');
        await _solve(tester);
      }
      // Mistake on the last planned task: its twin is due at task 8.
      await _failThenSolveTogether(tester);
      expect(_header(tester), 'Aufgabe 7 / 8');
      expect(find.byType(LumoTwinTaskBanner), findsNothing);
      // Another mistake in the extension must not extend it further.
      await _failThenSolveTogether(tester);
      expect(_header(tester), 'Aufgabe 8 / 8');
      expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
      await _solve(tester);

      expect(find.text('Einheit beendet'), findsOneWidget);
      expect(find.text('Du hast 8 Aufgaben bearbeitet.'), findsOneWidget);
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('session-alone'))).data,
          '6 Aufgaben allein gelöst');
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('session-together')))
              .data,
          '2 Aufgaben gemeinsam gelöst');
      expect(find.byKey(const ValueKey('session-twin-wins')), findsOneWidget);
      expect(find.textContaining('Super gemacht'), findsNothing);
    });
  });

  group('5 · tests and schoolwork', () {
    for (final kind in [LumoSessionKind.test, LumoSessionKind.schoolwork]) {
      testWidgets('$kind: one try, no star loss, and the reason why',
          (tester) async {
        final app = await _open(tester, kind: kind, stars: 5);
        expect(app.state.stars, 5);
        final task = _renderer(tester).task;
        await _tap(tester, _wrongOptions(task).first);

        expect(app.state.stars, 5, reason: 'no stars are taken away');
        expect(find.textContaining('-2'), findsNothing);
        expect(find.text('Kein Stern geht verloren'), findsOneWidget);
        // One try only: no second attempt, no twin, no feedback card.
        expect(find.byType(LumoMistakeFeedbackCard), findsNothing);
        expect(_renderer(tester).task.taskInstanceId, task.taskInstanceId);
        // The card explains why, instead of only stating the answer.
        expect(find.text('Richtige Antwort: ${_rightOption(task).label}'),
            findsOneWidget);
        expect(find.byKey(const ValueKey('solution-why-box')), findsOneWidget);
        final why = tester
            .widgetList<Text>(find.descendant(
                of: find.byKey(const ValueKey('solution-why-box')),
                matching: find.byType(Text)))
            .map((text) => text.data ?? '')
            .toList();
        expect(why.length, greaterThanOrEqualTo(3),
            reason: 'a heading and at least two steps');
        expect(why.last, contains('${task.correctAnswer}'),
            reason: 'the last step states the solution');
        expect(find.textContaining('Fast'), findsNothing);
      });
    }
  });

  group('7 · length, rounds and reading aloud', () {
    for (final (grade, length) in [(1, 6), (2, 8), (3, 10), (4, 10)]) {
      testWidgets('quick practice in grade $grade has $length tasks',
          (tester) async {
        await _open(tester, grade: grade, unit: 'Alle');
        expect(_header(tester), 'Aufgabe 1 / $length');
        expect(find.byKey(const ValueKey('lesson-round-label')), findsNothing);
        for (var question = 1; question <= length; question++) {
          expect(_header(tester), 'Aufgabe $question / $length');
          await _solve(tester);
        }
        expect(find.text('Einheit beendet'), findsOneWidget);
      });
    }

    testWidgets('schoolwork runs in rounds of ten and resumes at the round',
        (tester) async {
      final app = await _open(tester,
          grade: 2, unit: 'Alle', kind: LumoSessionKind.schoolwork);
      expect(find.text('Runde 1 von 3'), findsOneWidget);
      // The familiar header pattern stays: "Aufgabe N / M".
      expect(_header(tester), 'Aufgabe 1 / 30');
      for (var question = 1; question <= 10; question++) {
        expect(_header(tester), 'Aufgabe $question / 30');
        await _solve(tester);
      }

      // A clear, positive stopping point.
      expect(find.byKey(const ValueKey('round-break')), findsOneWidget);
      expect(find.text('Runde 1 von 3 geschafft!'), findsOneWidget);
      expect(find.byType(AdaptiveTaskRenderer), findsNothing);
      final stop = find.byKey(const ValueKey('round-stop'));
      expect(tester.getSize(stop).height, greaterThanOrEqualTo(48));
      await tester.tap(stop);
      await _settle(tester);
      expect(app.state.section, LumoSection.home);

      // Next time the session opens at round 2.
      app.update(app.state.copyWith(section: LumoSection.exercises));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: LearningContent(
                  key: const ValueKey('second visit'), appState: app))));
      await _settle(tester);
      expect(find.text('Runde 2 von 3'), findsOneWidget);
      expect(_header(tester), 'Aufgabe 11 / 30');
      expect(find.byKey(const ValueKey('round-resume-notice')), findsOneWidget);

      // Continuing through the break leads on within the same visit.
      for (var question = 1; question <= 10; question++) {
        await _solve(tester);
      }
      expect(find.text('Runde 2 von 3 geschafft!'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('round-continue')));
      await _settle(tester);
      expect(find.text('Runde 3 von 3'), findsOneWidget);
      expect(_header(tester), 'Aufgabe 21 / 30');
      for (var question = 1; question <= 10; question++) {
        await _solve(tester);
      }
      expect(find.text('Einheit beendet'), findsOneWidget);

      // A finished session starts at round 1 again.
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: LearningContent(
                  key: const ValueKey('third visit'), appState: app))));
      await _settle(tester);
      expect(find.text('Runde 1 von 3'), findsOneWidget);
    });

    const speaking = AppSettings(
      aiProxyEnabled: false,
      voiceEnabled: true,
      autoReadEnabled: true,
      localVoiceLicenseAccepted: true,
      soundEnabled: false,
      reduceAnimations: true,
    );

    testWidgets('grade 1 hears each new task when the voice is on',
        (tester) async {
      final voice = _Voice();
      await _open(tester, settings: speaking, voice: voice);
      await _afterReadingPause(tester);
      final first = _renderer(tester).task.prompt;
      expect(voice.spoken.first, startsWith('Hallo!'));
      expect(voice.spoken, contains(first));

      voice.spoken.clear();
      await _answer(tester, _renderer(tester).task.correctAnswer,
          correct: true);
      // Step through time as a device does: the praise, the next task
      // appears, then the short pause before reading.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await _afterReadingPause(tester);
      final second = _renderer(tester).task.prompt;
      expect(second, isNot(first));
      expect(voice.spoken.last, second,
          reason: 'the new task is read without asking');
    });

    testWidgets('the stop control ends an automatic reading', (tester) async {
      final voice = _Voice()..hold = true;
      await _open(tester, settings: speaking, voice: voice);
      await _afterReadingPause(tester);
      // The task is being read (after the greeting).
      final prompt = _renderer(tester).task.prompt;
      expect(voice.spoken.last, prompt);
      final spoken = voice.spoken.length;
      final stops = voice.stops;
      final stop = find.text('Stopp');
      await tester.ensureVisible(stop);
      await tester.tap(stop);
      await _settle(tester, 2);
      expect(voice.stops, greaterThan(stops),
          reason: 'the running reading is stopped');
      // After "Stopp" nothing starts by itself any more.
      voice.finish();
      await tester.pump(const Duration(seconds: 3));
      await _settle(tester);
      expect(voice.spoken, hasLength(spoken));
    });

    testWidgets('nothing is read when the voice is off', (tester) async {
      final voice = _Voice();
      await _open(tester,
          settings: speaking.copyWith(voiceEnabled: false), voice: voice);
      await _afterReadingPause(tester);
      await _solve(tester);
      await _afterReadingPause(tester);
      expect(voice.spoken, isEmpty,
          reason: 'no greeting, no task, no praise: the voice is off');
    });

    testWidgets('nothing is read automatically when auto-read is off',
        (tester) async {
      final voice = _Voice();
      await _open(tester,
          settings: speaking.copyWith(autoReadEnabled: false), voice: voice);
      await _afterReadingPause(tester);
      expect(voice.spoken, isEmpty);
      final prompt = _renderer(tester).task.prompt;
      // The read-aloud button still works on request.
      await tester.tap(find.byTooltip('Aufgabe vorlesen'));
      await _settle(tester);
      expect(voice.spoken, [prompt]);
    });

    testWidgets('from grade 3 on tasks are not read automatically',
        (tester) async {
      final voice = _Voice();
      await _open(tester,
          grade: 3, unit: 'Alle', settings: speaking, voice: voice);
      await _afterReadingPause(tester);
      final prompt = _renderer(tester).task.prompt;
      expect(voice.spoken, isNot(contains(prompt)));
    });
  });

  group('fits a small phone with large text', () {
    testWidgets('feedback and worked path at 320 wide, text scale 1.3',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      late LumoAppState app;
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        await app.loadLearningProfile();
        app.updateSettings(_quiet);
        app.update(app.state.copyWith(
            grade: 1, subject: 'Mathematik', unit: 'Plus bis 10'));
      });
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(body: LearningContent(appState: app)),
      ));
      await _settle(tester);
      final task = _renderer(tester).task;
      final wrong = _wrongOptions(task);
      await _tap(tester, wrong[0]);
      expect(find.byType(LumoMistakeFeedbackCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, wrong[1]);
      expect(find.byType(LumoWorkedSolutionCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, _rightOption(task));
      expect(find.text('Gemeinsam gelöst'), findsWidgets);
      expect(tester.takeException(), isNull);
      await _drain(tester, app);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester, 4);
    });
  });
}
