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
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:lumo_lernen/widgets/fox/stage/lumo_actor_stage.dart';

import '../helpers/lumo_capture.dart';
import 'placeholder_actors.dart';

/// Bilder nur, wenn ein Zielordner gesetzt ist (z. B. für die Sichtprüfung).
final _captureDir = Platform.environment['LUMO_STAGE_CAPTURE_DIR'];

Future<LumoAppState> _mount(WidgetTester tester, Size size,
    {bool reduceAnimations = false}) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  final bus = LumoCompanionRequests.instance;
  bus.clearLearningScope();
  await tester.binding.setSurfaceSize(size);
  final app = LumoAppState();
  await app.school.setActiveStudent('stage-child');
  await app.loadLearningProfile();
  app.updateSettings(AppSettings(
      voiceEnabled: false,
      autoReadEnabled: false,
      reduceAnimations: reduceAnimations));
  app.update(app.state.copyWith(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      grade: 1,
      sessionKind: LumoSessionKind.quickPractice));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF071A3A),
      body: RepaintBoundary(
        key: const ValueKey('capture'),
        child: AnimatedBuilder(
          animation: app,
          builder: (_, __) => LearningContent(appState: app, taskSeed: 7),
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

LumoActorStageState _stage(WidgetTester tester) => tester
    .state<LumoActorStageState>(find.byKey(const ValueKey('lumo-actor-stage')));

List<Rect> _visibleTaskRects(WidgetTester tester) {
  final stageBox = tester
      .renderObject<RenderBox>(find.byKey(const ValueKey('lumo-actor-stage')));
  Rect? local(Finder finder) {
    if (finder.evaluate().isEmpty) return null;
    final box = tester.renderObject<RenderBox>(finder.first);
    final rect = box.localToGlobal(Offset.zero, ancestor: stageBox) & box.size;
    return rect.overlaps(Offset.zero & stageBox.size) ? rect : null;
  }

  final renderer =
      tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
  final stage = _stage(tester);
  return [
    for (final option in renderer.task.options)
      if (local(find.byKey(ValueKey('math-crystal-${option.label}')))
          case final r?)
        r,
    // Die Rechnung selbst (Aufgabenkarte) aus dem echten Baum.
    if (stage.widget.controller.targets.rectOf('learning-task', stageBox)
        case final r?)
      r,
  ];
}

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  for (var t = Duration.zero;
      t < total;
      t += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

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

void main() {
  late LumoActorLibrary actors;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    actors = await loadPlaceholderActors();
  });

  setUp(() => LumoActorLibrary.shared.value = actors);
  tearDown(LumoActorLibrary.debugReset);

  for (final entry in const {
    'phone-360': Size(360, 800),
    'phone-412': Size(412, 915),
    'fold-open': Size(690, 829),
  }.entries) {
    testWidgets('„Hilf mir“: Lumo läuft zur Aufgabe und zurück (${entry.key})',
        (tester) async {
      if (_captureDir != null) {
        await tester.runAsync(loadLumoCaptureFonts);
      }
      await _mount(tester, entry.value);
      expect(find.byKey(const ValueKey('lumo-actor-stage')), findsOneWidget);
      await _pumpFor(tester, const Duration(milliseconds: 1600));
      final stage = _stage(tester);
      expect(stage.phase, LumoStagePhase.home);
      await _capture(tester, '${entry.key}-1-platz');

      final help = find.widgetWithText(OutlinedButton, 'Hilf mir');
      await tester.ensureVisible(help);
      await tester.pump();
      await tester.tap(help);
      await tester.pump();
      await _pumpFor(tester, const Duration(milliseconds: 420));
      expect(stage.phase, LumoStagePhase.toTarget);
      await _capture(tester, '${entry.key}-2-unterwegs');

      await _pumpFor(tester, const Duration(milliseconds: 4500));
      expect(stage.phase, LumoStagePhase.atTarget);
      expect(stage.motion, LumoActorMotion.point);
      final protectedRects = _visibleTaskRects(tester);
      expect(protectedRects, isNotEmpty);
      for (final rect in protectedRects) {
        expect(stage.actorRect!.deflate(1).overlaps(rect), isFalse,
            reason: 'Lumo ${stage.actorRect} verdeckt $rect');
        if (stage.bubbleRect != null) {
          expect(stage.bubbleRect!.deflate(1).overlaps(rect), isFalse,
              reason: 'Blase ${stage.bubbleRect} verdeckt $rect');
        }
      }
      expect(stage.bubbleText, isNotNull);
      await _capture(tester, '${entry.key}-3-am-ziel');

      await _pumpFor(tester, const Duration(seconds: 14));
      expect(stage.phase, LumoStagePhase.home);
    });
  }

  testWidgets('Antwort antippen bricht Lumos Weg ab und wird gewertet',
      (tester) async {
    await _mount(tester, const Size(412, 915));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    final help = find.widgetWithText(OutlinedButton, 'Hilf mir');
    await tester.ensureVisible(help);
    await tester.pump();
    await tester.tap(help);
    await _pumpFor(tester, const Duration(milliseconds: 500));
    final stage = _stage(tester);
    expect(stage.phase, LumoStagePhase.toTarget);
    final renderer =
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
    final option = find
        .byKey(ValueKey('math-crystal-${renderer.task.options.first.label}'));
    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(stage.phase, isNot(LumoStagePhase.toTarget));
    expect(LumoCompanionRequests.instance.taskContext.value!.attempts, 1);
  });

  testWidgets('ohne Bildsatz bleibt die Bühne aus', (tester) async {
    LumoActorLibrary.debugReset();
    await _mount(tester, const Size(412, 915));
    expect(find.byKey(const ValueKey('lumo-actor-stage')), findsNothing);
  });
}
