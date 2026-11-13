import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _channel = MethodChannel('lumo_lernen/bridge');

class _LaunchState extends LumoAppState {
  int generation = 0;
  @override
  int get profileGeneration => generation;
  @override
  Future<void> flushRewards() async {}
  @override
  Future<void> ensureSettingsLoaded() async {}
  @override
  bool get canPlayToday => false;
}

Future<BuildContext> _mount(WidgetTester tester) async {
  late BuildContext launchContext;
  await tester
      .pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) {
    launchContext = context;
    return const Text('Aktuelle Lernaufgabe');
  }))));
  return launchContext;
}

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final math = NativeLearningActivity.fromLesson(
      GuidedLessonCatalog.bridgeTen, GuidedLessonCatalog.bridgeTen.steps[2])!;

  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'learning-test-salt'});
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return <String, Object?>{'destination': 'learn'};
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('descriptor derives actual quantities, syllables and plant part', () {
    expect(math.toLaunchOptions(), {'kind': 'bridge_ten', 'a': 8, 'b': 5});
    expect(
        NativeLearningActivity.fromLesson(GuidedLessonCatalog.syllables,
                GuidedLessonCatalog.syllables.steps[2])!
            .toLaunchOptions(),
        {
          'kind': 'syllables',
          'word': 'Banane',
          'syllables': ['Ba', 'na', 'ne'],
        });
    expect(
        NativeLearningActivity.fromLesson(GuidedLessonCatalog.plantParts,
                GuidedLessonCatalog.plantParts.steps[1])!
            .toLaunchOptions()['kind'],
        'plant_parts');
    expect(
        NativeLearningActivity.fromLesson(GuidedLessonCatalog.bridgeTen,
            GuidedLessonCatalog.bridgeTen.steps.first),
        isNull);
    for (final lesson in GuidedLessonCatalog.all) {
      expect(
          lesson.steps.any((step) =>
              NativeLearningActivity.fromLesson(lesson, step) != null),
          isTrue,
          reason: 'Each reviewed concept has an actual native representation.');
      for (final step in lesson.steps) {
        final descriptor = NativeLearningActivity.fromLesson(lesson, step);
        if (descriptor == null ||
            lesson.concept == GuidedLessonConcept.syllables ||
            lesson.concept == GuidedLessonConcept.plantParts) {
          continue;
        }
        expect(descriptor.toLaunchOptions()['a'], step.a);
        expect(descriptor.toLaunchOptions()['b'], step.b);
      }
    }
    expect(
        NativeLearningActivity.fromLesson(
            GuidedLessonCatalog.fractionParts,
            const GuidedLessonStep(
                type: TutoringStepType.independentTask,
                title: 'Invalid',
                instruction: '',
                a: 7,
                b: 4)),
        isNull);
  });

  test('adaptive task descriptors use checked original operands and word', () {
    const adapter = LegacyLumoTaskAdapter();
    TaskInstance task(String prompt, String answer, String visual,
            {String subject = 'Mathematik'}) =>
        adapter.toTaskInstance(
            task: LumoTask(
                id: 'native-actual',
                grade: 1,
                subject: subject,
                unit: subject == 'Deutsch' ? 'Silben' : 'Rechnen bis 20',
                prompt: prompt,
                choices: answer == '3' ? ['3', '2', '4'] : [answer, '3', '7'],
                answer: answer,
                explanation: 'Wir probieren es aus.',
                visual: visual),
            childId: 'synthetic',
            difficulty: 1);
    expect(
        NativeLearningActivity.fromTask(
                task('Wie viel ist 7 + 5?', '12', 'counters'))!
            .toLaunchOptions(),
        {'kind': 'addition', 'a': 7, 'b': 5});
    expect(
        NativeLearningActivity.fromTask(
                task('Wie viel ist 14 - 6?', '8', 'counters'))!
            .toLaunchOptions(),
        {'kind': 'subtract_ten', 'a': 14, 'b': 6});
    expect(
        NativeLearningActivity.fromTask(task(
                'Wie viele Silben hat Banane?', '3', 'syllables',
                subject: 'Deutsch'))!
            .toLaunchOptions(),
        {
          'kind': 'syllables',
          'word': 'Banane',
          'syllables': ['Ba', 'na', 'ne']
        });
    expect(
        NativeLearningActivity.fromTask(
            task('Wie viel ist 27 + 15?', '42', 'counters')),
        isNull);
  });

  testWidgets('native voice preserves license, mute and selected identity',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final state = _LaunchState();
      addTearDown(state.dispose);
      final context = await _mount(tester);
      for (final scenario in [
        (true, false, LumoVoiceIdentity.freeOffline, false),
        (false, true, LumoVoiceIdentity.freeOffline, false),
        (true, true, LumoVoiceIdentity.sulafatOriginal, false),
        (true, true, LumoVoiceIdentity.freeOffline, true),
      ]) {
        state.state.settings = AppSettings(
            voiceEnabled: scenario.$1,
            localVoiceLicenseAccepted: scenario.$2,
            autoReadEnabled: true,
            calmMode: true,
            voiceRate: 0.35);
        await LumoVoice.instance.configure(identity: scenario.$3);
        final opened = launchLumo3D(context,
            scene: 'learning', appState: state, learning: math);
        await _frames(tester);
        expect(await opened, isTrue);
        final options = calls.last.arguments as Map;
        expect(options['learningVoiceEnabled'], scenario.$4);
        expect(options['learningAutoRead'], isFalse,
            reason:
                'Calm mode forbids automatic narration, not explicit replay.');
        expect(options['learningVoiceRate'], 1.0);
      }
      await LumoVoice.instance
          .configure(identity: LumoVoiceIdentity.freeOffline);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('3D explanation stays available while games are mission locked',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final state = _LaunchState();
      addTearDown(state.dispose);
      state.state.settings =
          const AppSettings(requireDailyMissionForGames: true);
      final context = await _mount(tester);
      final returned = launchLumo3D(context,
          scene: 'learning', appState: state, learning: math);
      await _frames(tester);
      expect(await returned, isTrue);
      expect(calls, hasLength(1));
      final options = calls.single.arguments as Map;
      expect(options['scene'], 'learning');
      expect(options['learning'], math.toLaunchOptions());
      expect(options['childKey'], matches(r'^p_[a-f0-9]{32}$'));
      expect(state.state.stars, 0);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('learning scene cannot bypass gates without reviewed descriptor',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final context = await _mount(tester);
      expect(await launchLumo3D(context, scene: 'learning'), isFalse);
      expect(
          await launchLumo3D(context, scene: 'kart', learning: math), isFalse);
      expect(calls, isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('native return from another profile is rejected', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final state = _LaunchState();
      addTearDown(state.dispose);
      final native = Completer<Map<String, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) {
        calls.add(call);
        return native.future;
      });
      final context = await _mount(tester);
      final launched = launchLumo3D(context,
          scene: 'learning', appState: state, learning: math);
      await _frames(tester);
      expect(calls, hasLength(1));
      state.generation++;
      native.complete({'destination': 'learn'});
      await _frames(tester);
      expect(await launched, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
      'real guided task opens matching 3D and retains assisted evidence',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1000));
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        app!.update(app!.state.copyWith(grade: 1, section: LumoSection.learn));
        await app!.school.setActiveStudent('native-lesson-child');
        await app!.hydrateFromWallet();
        await app!.loadLearningProfile();
        app!.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            reduceAnimations: true,
            requireDailyMissionForGames: true));
      });
      final step = GuidedLessonCatalog.bridgeTen.steps
          .firstWhere((step) => step.type == TutoringStepType.independentTask);
      final lesson = GuidedLesson(
          id: 'native-test-existing-math',
          title: 'Über den Zehner',
          description: 'Aktuelle Aufgabe',
          grade: 1,
          schoolUnit: 'Plus bis 20',
          concept: GuidedLessonConcept.bridgeTen,
          steps: [step]);
      await tester.pumpWidget(MaterialApp(
          home: GuidedLessonScreen(
              appState: app!, lesson: lesson, discovery: false)));
      await _frames(tester, 40);
      final action = find.byKey(const ValueKey('guided-open-3d'));
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await _frames(tester, 40);
      expect(calls.where((call) => call.method == 'launch3D'), hasLength(1));
      final launch = calls.firstWhere((call) => call.method == 'launch3D');
      expect((launch.arguments as Map)['learning'],
          {'kind': 'bridge_ten', 'a': step.a, 'b': step.b});
      expect(LumoCompanionRequests.instance.taskContext.value!.helpLevel, 1);
      expect(find.byKey(const ValueKey('guided-step-title')), findsOneWidget);
      expect(app!.state.stars, 0,
          reason: 'Manipulating an explanation creates no answer or reward.');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
    }
  });

  for (final kind in [
    LumoSessionKind.quickPractice,
    LumoSessionKind.schoolwork
  ]) {
    testWidgets('actual adaptive $kind preserves task and assessment boundary',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      LumoAppState? app;
      try {
        await tester.binding.setSurfaceSize(const Size(690, 1000));
        await tester.runAsync(() async {
          app = LumoAppState(walletRepository: RewardWalletRepository());
          app!.update(app!.state.copyWith(
              grade: 1,
              subject: 'Mathematik',
              unit: 'Plus bis 10',
              sessionKind: kind,
              section: LumoSection.learn));
          await app!.school.setActiveStudent('native-adaptive-child');
          await app!.hydrateFromWallet();
          await app!.loadLearningProfile();
          app!.updateSettings(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              reduceAnimations: true));
        });
        await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: LearningContent(appState: app!))));
        await _frames(tester, 40);
        final task = tester
            .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
            .task;
        final descriptor = NativeLearningActivity.fromTask(task);
        expect(descriptor, isNotNull);
        final action = find.byKey(const ValueKey('adaptive-open-3d'));
        if (kind == LumoSessionKind.schoolwork) {
          expect(action, findsNothing,
              reason: 'A graded schoolwork session cannot reveal the answer.');
          expect(calls, isEmpty);
        } else {
          expect(action, findsOneWidget);
          await tester.ensureVisible(action);
          await tester.tap(action);
          await _frames(tester, 40);
          expect(calls, hasLength(1));
          expect((calls.single.arguments as Map)['learning'],
              descriptor!.toLaunchOptions());
          expect(
              tester
                  .widget<AdaptiveTaskRenderer>(
                      find.byType(AdaptiveTaskRenderer))
                  .task
                  .taskInstanceId,
              task.taskInstanceId,
              reason: 'Return never replaces the current task.');
          expect(
              LumoCompanionRequests.instance.taskContext.value!.helpLevel, 1);
          expect(app!.state.stars, 0);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        app?.dispose();
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
