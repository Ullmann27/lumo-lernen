import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/mini_games/number_house_game.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/photo_lesson/photo_lesson_practice_screen.dart';
import 'package:lumo_lernen/features/photo_lesson/photo_lesson_session.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import 'module_coach_confirmation_test.dart' show pause, resume;

const _settings = AppSettings(
    voiceEnabled: false,
    autoReadEnabled: false,
    microphoneEnabled: false,
    calmMode: true,
    reduceAnimations: true);
const _task = LumoTask(
    id: 'native-photo-eight-five',
    grade: 1,
    subject: 'Mathematik',
    unit: 'Plus bis 20',
    prompt: '8 + 5 = ?',
    choices: ['12', '13', '14'],
    answer: '13',
    explanation: 'Acht und zwei sind zehn. Drei bleiben übrig.',
    visual: 'ten_frame');
const _story = LumoStory(
    title: 'Lumos Äpfel',
    heroName: 'Lumo',
    location: 'Garten',
    theme: 'Teilen',
    gradeLevel: 1,
    newWords: [],
    pages: [
      LumoStoryPage(
          pageNum: 1,
          text: 'Lumo hat zwei und drei Äpfel.',
          imagePrompt: '',
          exercise: StoryExercise(
              type: StoryExerciseType.mathPlus,
              prompt: '2 + 3 = ?',
              correctAnswer: '5',
              options: ['4', '5', '6'])),
    ]);

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _frames(tester);
  await tester.tap(finder);
  await _frames(tester);
}

Finder _confirm(String kind) => switch (kind) {
      'cross' => find.byKey(const ValueKey('cross-grade-proposal-confirm')),
      'photo' => find.widgetWithText(OutlinedButton, 'Diese Antwort prüfen'),
      'story' => find.byKey(const ValueKey('story-confirm-answer-proposal')),
      _ => find.byKey(const ValueKey('mini-game-proposal-confirm')),
    };
Finder _proposal(String kind) => find.byKey(ValueKey(switch (kind) {
      'cross' => 'cross-grade-answer-proposal',
      'photo' => 'photo-answer-proposal',
      'story' => 'story-answer-proposal-text',
      _ => 'mini-game-answer-proposal',
    }));

Future<LumoAppState> _mount(WidgetTester tester, String kind) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  LumoCompanionRequests.instance.clearLearningScope();
  await tester.binding.setSurfaceSize(const Size(412, 1000));
  final app = LumoAppState();
  late Widget child;
  await tester.runAsync(() async {
    await app.ensureSettingsLoaded();
    await app.loadLearningProfile();
    await app.hydrateFromWallet();
    app.updateSettings(_settings);
    if (kind == 'photo') {
      final lease = await app.captureLearningProfile();
      final repository = PhotoLessonSessionRepository(
          studentId: lease.studentId,
          mayWrite: () => app.canUseLearningLease(lease));
      final session = PhotoLessonSession.start([_task]);
      await repository.save(session);
      child = PhotoLessonPracticeScreen(
          appState: app,
          lease: lease,
          repository: repository,
          session: session);
    } else if (kind == 'cross') {
      child = CrossGradePracticeScreen(
          profileName: app.state.childName,
          enrolledGrade: app.state.grade,
          lessonGrade: 1,
          subject: 'Mathematik',
          unit: 'Plus bis 10',
          appState: app);
    } else if (kind == 'story') {
      child = LumoStoryReaderScreen(story: _story, appState: app);
    } else {
      child = NumberHouseGame(appState: app, level: GameLevelCatalog.byId(7)!);
    }
  });
  await tester.pumpWidget(MaterialApp(home: child));
  await _frames(tester);
  expect(LumoCompanionRequests.instance.taskContext.value, isNotNull);
  addTearDown(() async {
    resume(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    app.dispose();
    await tester.binding.setSurfaceSize(null);
    LumoVoice.instance.isEnabled = true;
  });
  return app;
}

void main() {
  final bus = LumoCompanionRequests.instance;
  for (final kind in ['cross', 'photo', 'story', 'mini']) {
    testWidgets(
        '$kind: real native entry preserves exact task through pause and return',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const bridge = MethodChannel('lumo_lernen/bridge');
      final returned = Completer<Map<String, Object?>>();
      Map<dynamic, dynamic>? payload;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, (call) async {
        if (call.method == 'launch3D') {
          payload = (call.arguments as Map)['learning'] as Map;
          return returned.future;
        }
        return <String, Object?>{'destination': 'learn'};
      });
      addTearDown(() {
        if (!returned.isCompleted) returned.complete({'destination': 'learn'});
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(bridge, null);
        debugDefaultTargetPlatformOverride = null;
      });
      final app = await _mount(tester, kind);
      final taskId = bus.taskContext.value!.taskId;
      final native = find.widgetWithText(OutlinedButton, 'Mit Lumo in 3D');
      expect(tester.getSize(native).height, greaterThanOrEqualTo(48));
      await _tap(tester, native);
      expect(payload, isNotNull);
      expect(payload!.containsKey('correctAnswer'), isFalse);
      expect(payload!.containsKey('reward'), isFalse);
      expect(bus.taskContext.value!.helpLevel, greaterThanOrEqualTo(1));
      final identity = bus.learningIdentity.value!;
      expect(payload!['scope'], identity.toJson());
      pause(tester);
      await _frames(tester);
      expect(bus.learningIdentity.value!.matches(identity), isTrue);
      final choice = bus.taskContext.value!.answerChoices.first;
      expect(
          bus.requestLearningAction(LumoLearningAction.proposeAnswer,
              identity: identity, candidate: choice),
          isTrue);
      await _frames(tester);
      returned.complete({'destination': 'learn'});
      await _frames(tester);
      expect(bus.taskContext.value!.attempts, 0);
      resume(tester);
      await _frames(tester);
      expect(bus.taskContext.value!.taskId, taskId);
      expect(_proposal(kind), findsOneWidget);
      expect(bus.taskContext.value!.attempts, 0);
      expect(app.state.stars, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '$kind: stopped or replaced proposal cannot use an old confirm callback',
        (tester) async {
      final app = await _mount(tester, kind);
      final first = bus.learningIdentity.value!;
      final choices = bus.taskContext.value!.answerChoices;
      expect(
          bus.requestLearningAction(LumoLearningAction.proposeAnswer,
              identity: first, candidate: choices.first),
          isTrue);
      await _frames(tester);
      final old = tester.widget<ButtonStyleButton>(_confirm(kind)).onPressed!;
      bus.cancelLearningInteraction();
      await _frames(tester);
      expect(_proposal(kind), findsNothing);
      expect(
          bus.requestLearningAction(LumoLearningAction.proposeAnswer,
              identity: first, candidate: choices.last),
          isFalse);
      expect(
          bus.requestLearningAction(LumoLearningAction.proposeAnswer,
              identity: bus.learningIdentity.value!, candidate: choices.last),
          isTrue);
      await _frames(tester);
      old();
      await _frames(tester);
      expect(bus.taskContext.value!.attempts, 0);
      expect(app.state.stars, 0);
      pause(tester);
      await _frames(tester);
      expect(bus.taskContext.value, isNull);
      resume(tester);
      await _frames(tester);
      expect(_proposal(kind), findsNothing);
      expect(bus.taskContext.value!.attempts, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
