import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../support/lumo_intelligence_capture.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_learning_scene_card.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_place_value_workshop.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Real production workshop SFX are enabled by the active app settings.
    // Pure Flutter tests have no native audioplayers transport; stub exactly
    // the two platform channel endpoints, without mocking the tutor itself.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), (call) async {
      if (call.method == 'init' ||
          call.method == 'setGlobalAudioContext') return null;
      throw MissingPluginException('Unexpected global audio call: ${call.method}');
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global/events'),
        (call) async {
      if (call.method == 'listen' || call.method == 'cancel') return null;
      throw MissingPluginException('Unexpected audio events call: ${call.method}');
    });
    await loadIntelligenceCaptureFonts();
  });
  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'), null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global/events'), null);
  });
  testWidgets(
      'failed first scene, actual alternative and fresh independent transfer survive restart',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = true);
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('live-scene-a');
      await app.loadLearningProfile();
    });
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
    app.update(app.state
        .copyWith(grade: 2, subject: 'Mathematik', unit: 'Zehner und Einer'));
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(RepaintBoundary(
        key: intelligenceBoundary,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: LumoAppTheme.light(),
            home: Scaffold(body: LearningContent(appState: app)))));
    await tester.pump();
    LumoCompanionRequests.instance.requestTaskHelp();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(find.byType(LumoLearningSceneCard), findsOneWidget);
    final button = find.byKey(const ValueKey('lumo-scene-not-understood'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(find.byKey(const ValueKey('lumo-scene-pictorial')), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('lumo-scene-pictorial')));
    await tester.pump();
    await captureIntelligence(tester, 'actual-alternative-pictorial-phone');
    expect(
        app.learningProfile.sceneMemory.records.any((r) =>
            r.outcome == SceneOutcome.notUnderstood &&
            r.method == ExplanationMethod.verbal),
        isTrue);
    expect(app.learningJourney().values.any((r) => r.transferCorrect > 0),
        isFalse);
    final quiet = find.byKey(const ValueKey('lumo-scene-think'));
    await tester.ensureVisible(quiet);
    await tester.pump();
    await tester.tap(quiet);
    await tester.pump();
    expect(find.byKey(const ValueKey('lumo-scene-pictorial')), findsNothing);
    LumoCompanionRequests.instance.requestTaskHelp();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(
        find.byKey(const ValueKey('lumo-scene-interactive')), findsOneWidget);

    // Continue the same real lesson all the way through a new task. Refusal
    // alone was not competence; the separate construction and question are.
    final workshop = find.byType(LumoPlaceValueWorkshop);
    final lessonWidget = tester.widget<LumoPlaceValueWorkshop>(workshop);
    Future<void> tapWorkshop(String key) async {
      final finder =
          find.descendant(of: workshop, matching: find.byKey(ValueKey(key)));
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
    }

    for (var i = 0; i < lessonWidget.number ~/ 10; i++) {
      await tapWorkshop('lumo-tens-block-$i');
    }
    await tapWorkshop('lumo-place-value-build-next');
    final target = lessonWidget.lesson!.targetNumber;
    expect(target, isNot(lessonWidget.number));
    for (var i = 0; i < target ~/ 10; i++) {
      await tapWorkshop('lumo-build-add-ten');
    }
    for (var i = 0; i < target % 10; i++) {
      await tapWorkshop('lumo-build-add-one');
    }
    await tapWorkshop('lumo-build-check');
    await tapWorkshop('lumo-comprehension-${target % 10}');
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(lessonWidget.lesson!.completion!.independent, isTrue);
    final restarted = LearningProfileEngine(
        repository: ProgressRepository(studentId: 'live-scene-a'));
    await tester.runAsync(() async {
      await restarted.loadSceneMemory();
      await restarted.loadJourney();
    });
    expect(
        restarted.sceneMemory.records.any((r) =>
            r.outcome == SceneOutcome.notUnderstood &&
            r.method == ExplanationMethod.verbal),
        isTrue);
    final receipt = restarted.sceneMemory.records.last;
    expect(receipt.outcome, SceneOutcome.independentTransfer);
    expect(receipt.method, ExplanationMethod.interactive);
    expect(receipt.transferProblemId, 'place-value:$target');
    expect(restarted.journey.records.values.single.transferCorrect, 1);
    expect(restarted.journey.records.values.single.attempts, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
