import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
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
    expect(
        NativeLearningActivity.fromLesson(GuidedLessonCatalog.fractionParts,
            GuidedLessonCatalog.fractionParts.steps[2]),
        isNull,
        reason: 'Unsupported illustrations do not route to unrelated scenes.');
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
}
