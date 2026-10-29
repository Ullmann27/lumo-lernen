import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_place_value_workshop.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final duringQuestion in [false, true]) {
    testWidgets(
        'help during ${duringQuestion ? 'comprehension via alternative card' : 'construction via companion'} remains assisted',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
      addTearDown(() => LumoVoice.instance.isEnabled = true);
      await tester.binding.setSurfaceSize(const Size(880, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.runAsync(() async {
        await app.school.setActiveStudent('transfer-help');
        await app.loadLearningProfile();
      });
      app.updateSettings(const AppSettings(
          voiceEnabled: false,
          autoReadEnabled: false,
          soundEnabled: false,
          reduceAnimations: true));
      app.update(app.state
          .copyWith(grade: 2, subject: 'Mathematik', unit: 'Zehner und Einer'));
      await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: Scaffold(body: LearningContent(appState: app))));
      await tester.pump();
      Future<void> settleOwner() async {
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        }
      }

      for (var i = 0; i < 3; i++) {
        LumoCompanionRequests.instance.requestTaskHelp();
        await settleOwner();
      }
      final workshop = find.byType(LumoPlaceValueWorkshop);
      final widget = tester.widget<LumoPlaceValueWorkshop>(workshop);
      Future<void> tapKey(String key, {bool inWorkshop = true}) async {
        final finder = inWorkshop
            ? find.descendant(of: workshop, matching: find.byKey(ValueKey(key)))
            : find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
        await tester.pump();
      }

      for (var i = 0; i < widget.number ~/ 10; i++) {
        await tapKey('lumo-tens-block-$i');
      }
      await tapKey('lumo-place-value-build-next');
      final target = widget.lesson!.targetNumber;
      if (!duringQuestion) {
        LumoCompanionRequests.instance.requestTaskHelp();
        await settleOwner();
      }
      for (var i = 0; i < target ~/ 10; i++) {
        await tapKey('lumo-build-add-ten');
      }
      for (var i = 0; i < target % 10; i++) {
        await tapKey('lumo-build-add-one');
      }
      await tapKey('lumo-build-check');
      if (duringQuestion) {
        await tapKey('lumo-scene-not-understood', inWorkshop: false);
        await settleOwner();
      }
      expect(find.text('Schritt für Schritt'), findsOneWidget);
      // Exhaustion must not overwrite the last method that was actually shown.
      LumoCompanionRequests.instance.requestTaskHelp();
      await settleOwner();
      expect(
          find.byKey(const ValueKey('lumo-scene-other-task')), findsOneWidget);
      await tapKey('lumo-comprehension-${target % 10}');
      await settleOwner();
      expect(widget.lesson!.completion!.independent, isFalse);
      expect(app.learningJourney().values.single.transferCorrect, 0);
      expect(app.learningJourney().values.single.assistedCorrect, 1);
      final completed = app.learningProfile.sceneMemory.records.lastWhere((r) =>
          r.outcome == SceneOutcome.assistedTransfer ||
          r.outcome == SceneOutcome.independentTransfer);
      expect(completed.outcome, SceneOutcome.assistedTransfer);
      expect(completed.method, ExplanationMethod.guided);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
