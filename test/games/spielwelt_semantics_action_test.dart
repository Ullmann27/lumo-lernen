import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/domain/games/game_world.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_hub.dart';

SpielweltPortal _portal(
  GameId id,
  VoidCallback onOpen, {
  bool unlocked = true,
  GameAvailability availability = GameAvailability.playable,
}) {
  final original = GameCatalog.byId(id);
  return SpielweltPortal(
    game: GameDefinition(
      id: original.id,
      title: original.title,
      tagline: original.tagline,
      availability: availability,
      rule: original.rule,
    ),
    state: GameUnlockState(unlocked: unlocked),
    onOpen: onOpen,
  );
}

Widget _hub(SpielweltPortal portal) => MaterialApp(
      home: Scaffold(
        body: SpielweltHub(
          portals: [portal],
          reduceMotion: true,
          onAdventure: () {},
          onHome: () {},
          onLearn: () {},
          onTests: () {},
          onParents: () {},
          onProgress: () {},
          onSettings: () {},
        ),
      ),
    );

Finder _tile(SpielweltPortal portal) =>
    find.byKey(ValueKey('spielwelt-portal-${portal.identity}'));

String _label(SpielweltPortal portal) {
  final status = !portal.playable
      ? 'Kommt bald'
      : portal.state.unlocked
          ? 'Spielen'
          : 'Noch gesperrt';
  return '${portal.semanticTitle ?? portal.title}. ${portal.tagline} $status';
}

SemanticsNode _node(WidgetTester tester, SpielweltPortal portal) =>
    tester.getSemantics(find.bySemanticsLabel(_label(portal)));

void _accessibilityTap(SemanticsNode node) {
  // Dispatch through the actual semantics owner, as an accessibility action
  // would. Calling the Dart callback directly would miss this regression.
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

Future<void> _prepare(WidgetTester tester) async {
  // testWidgets already enables and owns semantics for the complete test.
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets(
      'all ten game portals dispatch each accessibility and touch tap once',
      (tester) async {
    await _prepare(tester);
    var opened = 0;
    final portals = [
      for (final game in GameCatalog.games) _portal(game.id, () => opened++),
      SpielweltPortal.connectFour(onOpen: () => opened++),
      SpielweltPortal.quizShow(onOpen: () => opened++),
    ];
    expect(portals, hasLength(10));

    for (final portal in portals) {
      await tester.pumpWidget(_hub(portal));
      await tester.pump();
      final node = _node(tester, portal);
      final data = node.getSemanticsData();
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue,
          reason: portal.identity);
      expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue,
          reason: portal.identity);
      expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue,
          reason: portal.identity);
      expect(data.hasAction(SemanticsAction.tap), isTrue,
          reason: portal.identity);

      final before = opened;
      _accessibilityTap(node);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opened, before + 1,
          reason: '${portal.identity}: one actual semantics action');
      await tester.tap(_tile(portal));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opened, before + 2,
          reason: '${portal.identity}: existing InkWell still fires once');
      expect(tester.takeException(), isNull, reason: portal.identity);
    }
    expect(opened, 20);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final availability in GameAvailability.values) {
    testWidgets(
        'unavailable ${availability.name} has no accessible launch action',
        (tester) async {
      await _prepare(tester);
      var callbacks = 0;
      final portal = _portal(
        GameId.puzzle,
        () => callbacks++,
        unlocked: availability == GameAvailability.comingSoon,
        availability: availability,
      );
      await tester.pumpWidget(_hub(portal));
      await tester.pump();
      final node = _node(tester, portal);
      final data = node.getSemanticsData();
      expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      _accessibilityTap(node);
      await tester.pump();
      expect(callbacks, 0,
          reason:
              'Even an explicitly dispatched unsupported action cannot open it');

      // The existing physical tap still reaches the domain's locked/coming-soon
      // explanation. The semantics change must not replace that InkWell path.
      await tester.tap(_tile(portal));
      await tester.pump();
      expect(callbacks, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('rebuilding a tile removes and restores the accessible action',
      (tester) async {
    await _prepare(tester);
    var opened = 0;
    for (final unlocked in [true, false, true]) {
      final portal =
          _portal(GameId.jumpRun, () => opened++, unlocked: unlocked);
      await tester.pumpWidget(_hub(portal));
      await tester.pump();
      final node = _node(tester, portal);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), unlocked);
      final before = opened;
      _accessibilityTap(node);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opened, before + (unlocked ? 1 : 0));
    }
    expect(opened, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
