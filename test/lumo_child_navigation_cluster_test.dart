import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/widgets/shell/left_navigation.dart';

void main() {
  const sections = <LumoSection>[
    LumoSection.home,
    LumoSection.learn,
    LumoSection.games,
    LumoSection.tests,
    LumoSection.rewards,
    LumoSection.profile,
    LumoSection.reading,
    LumoSection.exercises,
    LumoSection.schoolwork,
    LumoSection.scanner,
    LumoSection.missions,
    LumoSection.progress,
    LumoSection.agent,
    LumoSection.settings,
  ];

  for (final layout in <(String, Size, double)>[
    ('full rail', const Size(430, 1120), 230),
    ('compact 90dp rail', const Size(300, 700), 90),
  ]) {
    testWidgets(
        '${layout.$1} opens all 14 destinations by scrolling without Discover',
        (tester) async {
      await tester.binding.setSurfaceSize(layout.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final appState = LumoAppState();
      addTearDown(appState.dispose);
      LumoSection? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Row(children: [
            LeftNavigation(
              appState: appState,
              width: layout.$3,
              onSelect: (section) => selected = section,
            ),
            const Expanded(child: SizedBox.shrink()),
          ]),
        ),
      ));
      expect(find.byKey(const ValueKey('lumo-nav-explore')), findsNothing);
      await tester.pump();
      if (layout.$3 >= 110) {
        expect(find.text('Lernen & Üben'), findsOneWidget);
        expect(find.text('Meine Erfolge'), findsOneWidget);
        expect(find.text('Lumo & Eltern'), findsOneWidget);
      }
      for (final section in sections) {
        final tile = find.byKey(ValueKey('lumo-nav-${section.name}'));
        await tester.ensureVisible(tile);
        await tester.pump();
        expect(tile.hitTestable(), findsOneWidget, reason: section.name);
        final size = tester.getSize(tile);
        expect(size.width, greaterThanOrEqualTo(48), reason: section.name);
        expect(size.height, greaterThanOrEqualTo(48), reason: section.name);
        selected = null;
        await tester.tap(tile);
        await tester.pump();
        expect(selected, section);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
