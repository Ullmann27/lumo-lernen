import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_tutoring_hour.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:lumo_lernen/widgets/fox/stage/lumo_actor_stage.dart';

import '../helpers/lumo_capture.dart';
import 'placeholder_actors.dart';

Future<LumoAppState> _mount(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  final bus = LumoCompanionRequests.instance;
  bus.clearLearningScope();
  await tester.binding.setSurfaceSize(const Size(412, 915));
  final app = LumoAppState();
  await app.school.setActiveStudent('tutoring-child');
  await app.loadLearningProfile();
  await app.ensureSettingsLoaded();
  app.updateSettings(const AppSettings(
      voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
  app.update(app.state.copyWith(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      grade: 1,
      sessionKind: LumoSessionKind.tutoring));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF071A3A),
      body: RepaintBoundary(
        key: const ValueKey('capture'),
        child: AnimatedBuilder(
          animation: app,
          builder: (_, __) => LearningContent(appState: app, taskSeed: 11),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
    bus.clearLearningScope();
    await tester.binding.setSurfaceSize(null);
  });
  return app;
}

final _captureDir = Platform.environment['LUMO_STAGE_CAPTURE_DIR'];

Future<void> _capture(WidgetTester tester, String name) async {
  final dir = _captureDir;
  if (dir == null) return;
  final render = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')));
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

String _phaseText(WidgetTester tester) => tester
    .widget<LumoTutoringPhaseBar>(find.byType(LumoTutoringPhaseBar))
    .phase
    .label;

Future<void> _answerCorrectly(WidgetTester tester) async {
  final renderer =
      tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
  final correct = renderer.task.options.firstWhere((option) =>
      '${option.payload ?? option.label}' == '${renderer.task.correctAnswer}');
  final crystal = find.byKey(ValueKey('math-crystal-${correct.label}'));
  await tester.ensureVisible(crystal);
  await tester.pump();
  await tester.tap(crystal);
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('Ablauf: Aufwärmen, Erklären, Gemeinsam, Allein, Rückblick', () {
    LumoTutoringPhase at(int q, {bool explained = true}) =>
        LumoTutoringHourPlan.phaseFor(q, explained: explained);
    expect(at(1, explained: false), LumoTutoringPhase.warmUp);
    expect(at(2, explained: false), LumoTutoringPhase.warmUp);
    expect(at(3, explained: false), LumoTutoringPhase.explain);
    expect(at(3), LumoTutoringPhase.together);
    expect(at(5), LumoTutoringPhase.together);
    expect(at(6), LumoTutoringPhase.alone);
    expect(LumoTutoringHourPlan.phaseFor(8, explained: true, finished: true),
        LumoTutoringPhase.review);
  });

  test('Rückblick nur aus echten Ergebnissen', () {
    final review = LumoTutoringReview.from(
        unit: 'Plus bis 10',
        alone: 3,
        together: 2,
        twinWins: 0,
        mistakes: {'Zehnerübergang': 2, 'Zählfehler': 1});
    expect(review.canNow.first, contains('3 Aufgaben ganz allein'));
    expect(review.tomorrow, contains('Zehnerübergang'));
    final none = LumoTutoringReview.from(
        unit: 'Plus bis 10', alone: 0, together: 0, twinWins: 0, mistakes: {});
    expect(none.canNow.single, contains('Anfang'));
  });

  testWidgets('Nachhilfestunde führt durch Aufwärmen, Erklären und Üben',
      (tester) async {
    if (_captureDir != null) await tester.runAsync(loadLumoCaptureFonts);
    final actors = await tester.runAsync(loadShippedActors);
    LumoActorLibrary.shared.value = actors;
    addTearDown(LumoActorLibrary.debugReset);
    await _mount(tester);
    expect(_phaseText(tester), 'Aufwärmen');
    await _answerCorrectly(tester);
    expect(_phaseText(tester), 'Aufwärmen');
    await _answerCorrectly(tester);
    expect(_phaseText(tester), 'Erklären');
    expect(find.byKey(const ValueKey('tutoring-explain')), findsOneWidget);
    // Während der Erklärung ist keine Aufgabe offen.
    expect(find.byType(AdaptiveTaskRenderer), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('tutoring-phase')));
    await tester.pump();
    await _capture(tester, 'nachhilfe-1-erklaeren');
    final go = find.byKey(const ValueKey('tutoring-continue'));
    await tester.ensureVisible(go);
    await tester.pump();
    await tester.tap(go);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_phaseText(tester), 'Gemeinsam üben');
    expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
    // Lumo begleitet die gemeinsame Aufgabe mit ihrem Lernziel.
    await tester.pump(const Duration(milliseconds: 800));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final stage = tester.state<LumoActorStageState>(
        find.byKey(const ValueKey('lumo-actor-stage')));
    // Lumo geht zur sichtbaren Aufgabe, ohne die Seite zu verschieben.
    expect(stage.widget.controller.request!.text, startsWith('Gemeinsam:'));
    expect(stage.widget.controller.request!.reveal, isFalse);
    expect(stage.phase, LumoStagePhase.atTarget);
    if (stage.bubbleText != null) {
      expect(stage.bubbleText, startsWith('Gemeinsam:'));
    }
    for (var i = 0; i < 3; i++) {
      await _answerCorrectly(tester);
      // ignore: avoid_print
      print(
          'DEBUG ${_phaseText(tester)} ${find.textContaining('Aufgabe ').evaluate().map((e) => (e.widget as Text).data).toList()} ${LumoCompanionRequests.instance.taskContext.value?.attempts}');
    }
    expect(_phaseText(tester), 'Allein üben');
    for (var i = 0; i < 3; i++) {
      await _answerCorrectly(tester);
    }
    expect(find.byKey(const ValueKey('tutoring-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('tutoring-tomorrow')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('tutoring-review')));
    await tester.pump();
    await _capture(tester, 'nachhilfe-2-rueckblick');
  });
}
