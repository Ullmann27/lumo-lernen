import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/fox/lumo_character.dart';
import 'package:lumo_lernen/widgets/fox/stage/lumo_actor_stage.dart';
import 'package:lumo_lernen/widgets/fox/stage/lumo_stage_layout.dart';

import 'placeholder_actors.dart';

/// Eine schlichte Aufgabenseite: Rechnung, Bild, Antworten – wie die echte.
class _Lesson extends StatelessWidget {
  const _Lesson({
    required this.stage,
    required this.actors,
    required this.onAnswer,
    this.reduceMotion = false,
    this.character,
  });

  final LumoStageController stage;
  final LumoActorLibrary actors;
  final ValueChanged<int> onAnswer;
  final bool reduceMotion;
  final LumoCharacterController? character;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF071A3A),
          body: Stack(children: [
            LumoStageScope(
              targets: stage.targets,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 150, child: Placeholder()),
                    LumoStageTarget(
                      id: 'learning-task',
                      child: Container(
                        height: 120,
                        color: const Color(0xFF12366A),
                        alignment: Alignment.center,
                        child: const Text('7 + 5 = ?',
                            style:
                                TextStyle(fontSize: 38, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const LumoStageTarget(
                      id: 'task-workspace',
                      kind: LumoStageRegionKind.obstacle,
                      child: SizedBox(
                          height: 160,
                          child: ColoredBox(color: Color(0xFF0C356A))),
                    ),
                    const SizedBox(height: 16),
                    LumoStageTarget(
                      id: 'answers',
                      kind: LumoStageRegionKind.answers,
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final n in [10, 11, 12, 13])
                          SizedBox(
                            width: 150,
                            height: 64,
                            child: FilledButton(
                              key: ValueKey('answer-$n'),
                              onPressed: () => onAnswer(n),
                              child: Text('$n'),
                            ),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: LumoActorStage(
                key: const ValueKey('stage'),
                controller: stage,
                library: actors,
                character: character,
                reduceMotion: reduceMotion,
                greet: false,
              ),
            ),
          ]),
        ),
      );
}

LumoActorStageState _state(WidgetTester tester) =>
    tester.state<LumoActorStageState>(find.byKey(const ValueKey('stage')));

Rect _global(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// Alle geschützten Rechtecke (Aufgabe, Bild, Antworten) in Bühnenkoordinaten.
List<Rect> _protected(WidgetTester tester, LumoStageController stage) {
  final box =
      tester.renderObject<RenderBox>(find.byKey(const ValueKey('stage')));
  return stage.targets.protectedRects(box);
}

Future<void> _pumpFor(WidgetTester tester, Duration total,
    {Duration step = const Duration(milliseconds: 16)}) async {
  var left = total;
  while (left > Duration.zero) {
    await tester.pump(step);
    left -= step;
  }
}

void _expectFree(Rect? rect, List<Rect> protectedRects, String what) {
  expect(rect, isNotNull, reason: '$what fehlt');
  for (final other in protectedRects) {
    expect(rect!.deflate(1).overlaps(other), isFalse,
        reason: '$what $rect verdeckt $other');
  }
}

void main() {
  late LumoActorLibrary actors;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    actors = await loadPlaceholderActors();
  });

  test('Vertrag: Pflichtbewegungen, Schrittweite und Fußpunkt', () {
    expect(actors.field, const Size(192, 192));
    expect(actors.anchor, const Offset(96, 174));
    expect(actors.clips.keys, containsAll(LumoActorLibrary.required));
    final run = actors.clipFor(LumoActorMotion.run);
    expect(run.stridePx, 120);
    expect(run.loop, isTrue);
    final point = actors.clipFor(LumoActorMotion.point);
    expect(point.loop, isFalse);
    // Nicht-Schleifen halten das letzte Feld.
    expect(point.frameAt(const Duration(seconds: 5)), point.frames - 1);
    expect(run.frameAt(run.duration), 0);
  });

  test('ausgelieferter Satz: echter Lumo mit idle, run und point', () async {
    final shipped = await loadShippedActors();
    expect(shipped.field, const Size(384, 384));
    expect(shipped.clips.keys, containsAll(LumoActorLibrary.required));
    expect(shipped.clipFor(LumoActorMotion.run).stridePx, greaterThan(0));
    expect(shipped.clipFor(LumoActorMotion.point).loop, isFalse);
    expect(shipped.shadow, isNotNull);
    for (final clip in shipped.clips.values) {
      final rows = (clip.frames / clip.columns).ceil();
      expect(clip.image.width, clip.columns * 384);
      expect(clip.image.height, rows * 384);
    }
  });

  test('Vertrag: fehlender Laufstreifen schaltet die Bühne aus', () {
    expect(
        () => LumoActorLibrary.parse({
              'version': 1,
              'frame': [192, 192],
              'anchor': [96, 174],
              'clips': {
                'idle': {'file': 'a', 'frames': 1, 'columns': 1, 'fps': 12},
              },
            }, {}),
        throwsFormatException);
  });

  group('Geometrie verdeckt nie Aufgabe oder Antworten', () {
    for (final size in const [
      Size(360, 800),
      Size(412, 915),
      Size(690, 829), // Fold offen
    ]) {
      test('${size.width.toInt()}×${size.height.toInt()}', () {
        final layout = LumoStageLayout(
            stage: size, figureHeight: size.width < 600 ? 104 : 120);
        final task = Rect.fromLTWH(14, 200, size.width - 28, 120);
        final workspace = Rect.fromLTWH(14, 332, size.width - 28, 160);
        final answers = Rect.fromLTWH(14, 508, size.width - 28, 140);
        final placement = layout.placeNear(task, [workspace, answers]);
        expect(placement, isNotNull);
        final actor = layout.actorRect(placement!.foot);
        _expectFree(actor, [task, workspace, answers], 'Lumo');
        expect(actor.top, greaterThanOrEqualTo(0));
        final bubble = layout.placeBubble(
            const Size(240, 90), placement.foot, [workspace, answers],
            target: task);
        _expectFree(bubble, [task, workspace, answers, actor], 'Blase');
        // Am Standardplatz frei, wenn die Antworten weggescrollt sind.
        final home = layout.freeHome([task, workspace]);
        expect(home, isNotNull);
        _expectFree(layout.actorRect(home!), [task, workspace], 'Platz');
      });
    }
  });

  for (final size in const [Size(360, 800), Size(412, 915), Size(690, 829)]) {
    testWidgets(
        'läuft hin, zeigt mit Blase und läuft zurück '
        '(${size.width.toInt()}×${size.height.toInt()})', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final stage = LumoStageController();
      addTearDown(stage.dispose);
      await tester
          .pumpWidget(_Lesson(stage: stage, actors: actors, onAnswer: (_) {}));
      await tester.pump(const Duration(milliseconds: 50));
      final state = _state(tester);
      expect(state.phase, LumoStagePhase.home);
      final home = state.foot!;
      final stageRect = _global(tester, find.byKey(const ValueKey('stage')));
      expect(home.dy, closeTo(stageRect.height - 8, 1));
      _expectFree(state.actorRect, _protected(tester, stage), 'Lumo am Platz');

      stage.helpAt(
          'learning-task', 'Schau auf die 7. Wie viele fehlen bis 10?');
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFor(tester, const Duration(milliseconds: 200));
      expect(state.phase, LumoStagePhase.toTarget);
      expect(state.motion, LumoActorMotion.run);

      await _pumpFor(tester, const Duration(seconds: 3));
      expect(state.phase, LumoStagePhase.atTarget);
      expect(state.motion, LumoActorMotion.point);
      final protectedRects = _protected(tester, stage);
      _expectFree(state.actorRect, protectedRects, 'Lumo am Ziel');
      expect(find.byKey(const ValueKey('lumo-stage-bubble')), findsOneWidget);
      expect(state.bubbleText, contains('Wie viele fehlen'));
      _expectFree(
          state.bubbleRect, [...protectedRects, state.actorRect!], 'Blase');
      // Lumo schaut zur Aufgabe.
      final task = protectedRects.first;
      expect(state.facingRight, task.center.dx >= state.foot!.dx);

      // Ohne Ton bleibt der Text zum Lesen stehen, dann geht Lumo heim.
      await _pumpFor(tester, const Duration(seconds: 5));
      expect(state.phase, isNot(LumoStagePhase.atTarget));
      await _pumpFor(tester, const Duration(seconds: 3));
      expect(state.phase, LumoStagePhase.home);
      expect((state.foot! - home).distance, lessThan(1));
      expect(find.byKey(const ValueKey('lumo-stage-bubble')), findsNothing);
    });
  }

  testWidgets('Tipp auf eine Antwort bricht den Weg ab, die Antwort zählt',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stage = LumoStageController();
    addTearDown(stage.dispose);
    final answers = <int>[];
    await tester.pumpWidget(
        _Lesson(stage: stage, actors: actors, onAnswer: answers.add));
    await tester.pump(const Duration(milliseconds: 50));
    stage.helpAt('learning-task', 'Zähle weiter.');
    await _pumpFor(tester, const Duration(milliseconds: 300));
    final state = _state(tester);
    expect(state.phase, LumoStagePhase.toTarget);
    await tester.tap(find.byKey(const ValueKey('answer-12')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(answers, [12]);
    expect(state.phase, LumoStagePhase.toHome);
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(state.phase, LumoStagePhase.home);
  });

  testWidgets('Animationen reduzieren: kein Rennen, Lumo blendet am Ziel ein',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stage = LumoStageController();
    addTearDown(stage.dispose);
    await tester.pumpWidget(_Lesson(
        stage: stage, actors: actors, onAnswer: (_) {}, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 50));
    final state = _state(tester);
    stage.helpAt('learning-task', 'Zähle weiter.');
    var ran = false;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (state.motion == LumoActorMotion.run) ran = true;
    }
    expect(ran, isFalse);
    expect(state.phase, LumoStagePhase.atTarget);
    _expectFree(state.actorRect, _protected(tester, stage), 'Lumo');
    stage.goHome();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.phase, LumoStagePhase.home);
  });

  testWidgets('Reaktionen am Platz: richtig jubelt, falsch tröstet',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stage = LumoStageController();
    final character = LumoCharacterController();
    addTearDown(stage.dispose);
    addTearDown(character.dispose);
    await tester.pumpWidget(_Lesson(
        stage: stage, actors: actors, onAnswer: (_) {}, character: character));
    await tester.pump(const Duration(milliseconds: 50));
    final state = _state(tester);
    character.cheer();
    await tester.pump(const Duration(milliseconds: 120));
    expect(state.motion, LumoActorMotion.cheer);
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(state.motion, LumoActorMotion.idle);
    character.comfort();
    await tester.pump(const Duration(milliseconds: 120));
    expect(state.motion, LumoActorMotion.comfort);
    character.think();
    await tester.pump(const Duration(milliseconds: 120));
    expect(state.motion, LumoActorMotion.think);
  });

  testWidgets('unsichtbare Bühne läuft nicht weiter (TickerMode aus)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stage = LumoStageController();
    addTearDown(stage.dispose);
    await tester.pumpWidget(TickerMode(
        enabled: false,
        child: _Lesson(stage: stage, actors: actors, onAnswer: (_) {})));
    await tester.pump(const Duration(milliseconds: 50));
    stage.helpAt('learning-task', 'Zähle weiter.');
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(_state(tester).phase, LumoStagePhase.home);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
