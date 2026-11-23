import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/world/world_school_mission.dart';
import 'package:lumo_lernen/features/games/world/world_school_lesson_screen.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _ticks(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}

class _DelayedPrepareState extends LumoAppState {
  final preparing = Completer<void>();
  final release = Completer<void>();
  bool holdNextPrepare = false;

  @override
  Future<void> prepareLearningLease(LearningProfileLease lease) async {
    if (holdNextPrepare) {
      holdNextPrepare = false;
      preparing.complete();
      await release.future;
    }
    await super.prepareLearningLease(lease);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(LumoAppState, WorldSchoolMissionRequest)> prepare() async {
    final app = LumoAppState();
    await app.school.setActiveStudent('child-a');
    await app.loadLearningProfile();
    final request = WorldSchoolMissionRequest(
      requestId: 'school-ui-0001',
      grade: 1,
    );
    return (app, request);
  }

  Future<void> open(
    WidgetTester tester,
    LumoAppState app,
    WorldSchoolMissionRequest request,
    ValueChanged<Map<String, Object>?> finished,
  ) async {
    final owner = await app.captureLearningProfile();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .push<Map<String, Object>>(
                          MaterialPageRoute(
                            builder: (_) => WorldSchoolLessonScreen(
                              appState: app,
                              request: request,
                              owner: owner,
                            ),
                          ),
                        );
                    finished(result);
                  },
                  child: const Text('Start school'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Start school'));
    await _ticks(tester);
    expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
  }

  Future<void> answer(WidgetTester tester, bool correct) async {
    final renderer = tester.widget<AdaptiveTaskRenderer>(
      find.byType(AdaptiveTaskRenderer),
    );
    final task = renderer.task;
    final option = task.options.firstWhere(
      (option) => ('${option.payload}' == '${task.correctAnswer}') == correct,
    );
    renderer.onAnswered!(
      AdaptiveTaskAnswer(task: task, answer: option.payload!, correct: correct),
    );
    await _ticks(tester);
  }

  testWidgets('wrong answers and back navigation return no success', (
    tester,
  ) async {
    final (app, request) = await prepare();
    Map<String, Object>? result;
    var returned = false;
    await open(tester, app, request, (value) {
      result = value;
      returned = true;
    });
    await answer(tester, false);
    expect(find.byKey(const ValueKey('world-school-next')), findsNothing);
    expect(returned, isFalse);
    await tester.tap(find.byKey(const ValueKey('world-school-back')));
    await _ticks(tester);
    expect(returned, isTrue);
    expect(result, isNull);
    final attempts = await app.attemptLog.load(studentId: 'child-a');
    expect(attempts, hasLength(1));
    expect(attempts.single.correct, isFalse);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('three assessed saved answers return matching world receipt', (
    tester,
  ) async {
    final (app, request) = await prepare();
    Map<String, Object>? result;
    await open(tester, app, request, (value) => result = value);
    for (var i = 0; i < 3; i++) {
      await answer(tester, true);
      expect(result, isNull);
      final next = find.byKey(const ValueKey('world-school-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await _ticks(tester);
    }
    expect(result?['requestId'], request.requestId);
    expect(result?['missionId'], 'school_numbers');
    expect(result?['completed'], isTrue);
    final attempts = await app.attemptLog.load(studentId: 'child-a');
    expect(attempts, hasLength(3));
    expect(attempts.every((attempt) => attempt.correct), isTrue);
    expect(attempts.map((attempt) => attempt.unit).toSet(), hasLength(3));
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('profile switch after an answer invalidates mission completion', (
    tester,
  ) async {
    final (app, request) = await prepare();
    Map<String, Object>? result;
    await open(tester, app, request, (value) => result = value);
    await answer(tester, true);
    await app.school.setActiveStudent('child-b');
    await app.loadLearningProfile();
    await _ticks(tester);
    expect(find.byType(AdaptiveTaskRenderer), findsNothing);
    expect(find.textContaining('nicht sicher fortgesetzt'), findsOneWidget);
    expect(result, isNull);
    expect(await app.attemptLog.load(studentId: 'child-b'), isEmpty);
    await tester.tap(find.byKey(const ValueKey('world-school-back')));
    await _ticks(tester);
    expect(result, isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('a World request cannot acquire the new child before screen load',
      (tester) async {
    final (app, request) = await prepare();
    final owner = await app.captureLearningProfile();
    await app.school.setActiveStudent('child-b');
    await app.loadLearningProfile();
    await tester.pumpWidget(MaterialApp(
      home: WorldSchoolLessonScreen(
          appState: app, request: request, owner: owner),
    ));
    await _ticks(tester);
    expect(find.byType(AdaptiveTaskRenderer), findsNothing);
    expect(find.textContaining('nicht sicher fortgesetzt'), findsOneWidget);
    expect(find.byKey(const ValueKey('world-school-next')), findsNothing);
    expect(await app.attemptLog.load(studentId: 'child-a'), isEmpty);
    expect(await app.attemptLog.load(studentId: 'child-b'), isEmpty);
    expect((await app.captureLearningProfile()).studentId, 'child-b');
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('profile change during delayed school load keeps its original owner',
      (tester) async {
    final app = _DelayedPrepareState();
    await app.school.setActiveStudent('child-a');
    await app.loadLearningProfile();
    final owner = await app.captureLearningProfile();
    final request = WorldSchoolMissionRequest(
        requestId: 'world-delayed-school-001', grade: 1);
    app.holdNextPrepare = true;
    addTearDown(() {
      if (!app.release.isCompleted) app.release.complete();
      app.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      home: WorldSchoolLessonScreen(
          appState: app, request: request, owner: owner),
    ));
    await _ticks(tester, 2);
    expect(app.preparing.isCompleted, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await app.school.setActiveStudent('child-b');
    await app.loadLearningProfile();
    await _ticks(tester, 2);
    app.release.complete();
    await _ticks(tester);
    expect(find.byType(AdaptiveTaskRenderer), findsNothing);
    expect(find.textContaining('nicht sicher fortgesetzt'), findsOneWidget);
    expect(find.byKey(const ValueKey('world-school-next')), findsNothing);
    expect(await app.attemptLog.load(studentId: 'child-a'), isEmpty);
    expect(await app.attemptLog.load(studentId: 'child-b'), isEmpty);
    expect((await app.captureLearningProfile()).studentId, 'child-b');
    await tester.pumpWidget(const SizedBox());
  });
}
