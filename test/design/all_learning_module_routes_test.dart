import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/curriculum/academy_topic_units.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/features/learning/nextgen/module_task_scope.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning_lab_runtime_test.dart' show frames, tap;

Future<void> confirmCandidate(WidgetTester tester, String prefix) async {
  final button = find.byKey(ValueKey('$prefix-confirm-candidate'));
  await tester.ensureVisible(button);
  await tester.pump();
  expect(button.hitTestable(), findsOneWidget);
  expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
  await tester.tap(button);
  await frames(tester);
}

void main() {
  final cases = <(String, int, String, String?)>[
    for (final grade in LumoCurriculum.grades)
      for (final subject in grade.subjects)
        for (final topic in subject.topics)
          if (LearningModuleRegistry.hasModule(topic.id) &&
              topic.id != 'd1_woerter')
            (
              topic.id,
              grade.grade,
              subject.name,
              AcademyTopicUnits.exerciseUnit(
                  topicId: topic.id,
                  title: topic.title,
                  subject: subject.name,
                  grade: grade.grade),
            ),
    ('s1_farben', 1, 'Sachunterricht', null),
  ];
  const scopedEntries = {
    'm1_minus10',
    'm1_zahlen10',
    'm1_formen',
    'm2_uhr',
    'm2_geld',
    'm2_zahlen100',
    'm2_einmaleins',
    'm3_einmaleins_voll',
    'm4_bruch',
    'd2_artikel',
    'd2_mehrzahl',
    'd3_wortarten',
    'd3_zeitformen',
    's1_tiere',
    's1_farben',
    's2_jahreszeiten',
    's2_wetter',
    's2_verkehr',
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);

  test('route cases include every registered non-writing module entry', () {
    final expected = {...LearningModuleRegistry.registeredTopicIds}
      ..remove('d1_woerter');
    expect(cases.map((entry) => entry.$1).toSet(), expected);
    expect(cases, hasLength(19),
        reason:
            'Two multiplication entries share one of the 18 module screens.');
  });

  for (final entry in cases) {
    testWidgets('${entry.$1} opens its real module through academy navigation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      late LumoAppState app;
      await tester.runAsync(() async {
        app = LumoAppState();
        await app.school.setActiveStudent('route-${entry.$1}');
        await app.hydrateFromWallet();
        await app.loadLearningProfile();
        app.update(
            app.state.copyWith(grade: entry.$2, section: LumoSection.learn));
        app.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            reduceAnimations: true,
            calmMode: true));
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await frames(tester);
        app.dispose();
      });
      final expected = LearningModuleRegistry.builderFor(entry.$1, app)!;
      final before = (
        app.state.grade,
        app.state.stars,
        app.state.xp,
        app.learningDailyDone()
      );
      await tester
          .pumpWidget(MaterialApp(home: LumoAkademieScreen(appState: app)));
      await frames(tester);
      if (entry.$1 == 's1_farben' || entry.$1 == 'd2_artikel') {
        await tap(tester, 'learning-advanced-entry');
        await tap(tester, 'academy-tool-${entry.$1}');
      } else {
        expect(entry.$4, isNotNull);
        await tap(tester, 'learning-subject-${entry.$3}');
        await tap(tester, 'learning-unit-${entry.$3}-${entry.$4}');
      }
      expect(find.byType(expected.runtimeType), findsOneWidget,
          reason:
              'The real route must reach the specialist module for ${entry.$1}.');
      if (scopedEntries.contains(entry.$1)) {
        expect(find.byType(ModuleTaskScope), findsOneWidget);
        final bus = LumoCompanionRequests.instance;
        expect(bus.taskContext.value!.objectIds,
            contains(ModuleTaskScope.taskObjectId));
        expect(
            bus.requestLearningAction(LumoLearningAction.hint,
                identity: bus.learningIdentity.value!),
            isTrue);
        await frames(tester);
        expect(find.byKey(const ValueKey('module-help-text')), findsOneWidget);
        expect(bus.taskContext.value!.helpLevel, 1);
        for (final action in [
          LumoLearningAction.repeat,
          LumoLearningAction.slower
        ]) {
          expect(
              bus.requestLearningAction(action,
                  identity: bus.learningIdentity.value!),
              isTrue);
          await frames(tester);
          expect(bus.taskContext.value!.helpLevel, 1);
        }
        expect(
            bus.requestLearningAction(LumoLearningAction.hint,
                identity: bus.learningIdentity.value!),
            isTrue);
        await frames(tester);
        expect(bus.taskContext.value!.helpLevel, 2);
        final captured = bus.learningIdentity.value!;
        expect(
            bus.requestLearningAction(LumoLearningAction.stop,
                identity: captured),
            isTrue);
        await frames(tester);
        expect(
            bus.requestLearningAction(LumoLearningAction.hint,
                identity: captured),
            isFalse);
        expect(bus.taskContext.value!.helpLevel, 2);
      }
      expect((
        app.state.grade,
        app.state.stars,
        app.state.xp,
        app.learningDailyDone()
      ), before);
      final bus = LumoCompanionRequests.instance;
      final prefix = scopedEntries.contains(entry.$1) ? 'module' : 'plus10';
      final native = find.byKey(ValueKey('$prefix-open-3d'));
      expect(native, findsOneWidget);
      await tester.ensureVisible(native);
      await tester.pump();
      expect(native.hitTestable(), findsOneWidget);
      expect(tester.getSize(native).height, greaterThanOrEqualTo(48));
      final task = bus.taskContext.value!;
      expect(task.answerChoices, isNotEmpty);
      expect(task.allowedActions, contains(LumoLearningAction.proposeAnswer));
      final oldId = bus.learningIdentity.value!;
      expect(
          bus.requestLearningAction(LumoLearningAction.proposeAnswer,
              identity: oldId, candidate: 'noch nicht eindeutig'),
          isTrue);
      await frames(tester);
      final field = find.byKey(ValueKey('$prefix-answer-candidate'));
      expect(field, findsOneWidget);
      expect(bus.taskContext.value!.attempts, 0);
      expect((
        app.state.grade,
        app.state.stars,
        app.state.xp,
        app.learningDailyDone()
      ), before);
      await confirmCandidate(tester, prefix);
      expect(bus.taskContext.value!.attempts, 0,
          reason: 'A value outside the offered choices must stay ungraded.');
      await tester.enterText(field, task.answerChoices.first);
      await tester.pump();
      final confirm = tester
          .widget<FilledButton>(
              find.byKey(ValueKey('$prefix-confirm-candidate')))
          .onPressed!;
      await confirmCandidate(tester, prefix);
      expect(bus.taskContext.value!.lastAnswer, task.answerChoices.first);
      expect(bus.taskContext.value!.lastCorrect, isNotNull,
          reason: 'Only the module itself evaluates the confirmed choice.');
      expect(bus.taskContext.value!.attempts, 1);
      confirm();
      await tester.pump();
      expect(bus.taskContext.value!.attempts, 1,
          reason: 'The captured confirmation cannot submit twice.');
      expect(tester.takeException(), isNull);
    });
  }
}
