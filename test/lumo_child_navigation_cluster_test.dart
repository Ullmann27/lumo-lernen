import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/widgets/shell/left_navigation.dart';

void main() {
  testWidgets('every existing secondary route remains one tap from Explore', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    LumoSection? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Row(children: [
        LeftNavigation(appState: appState, width: 230, onSelect: (s) => selected = s),
        const Expanded(child: SizedBox.shrink()),
      ]),
    )));
    await tester.tap(find.byKey(const ValueKey('lumo-nav-explore')));
    await tester.pump();
    expect(find.text('Lernen & Üben'), findsOneWidget);
    expect(find.text('Meine Erfolge'), findsOneWidget);
    expect(find.text('Lumo & Eltern'), findsOneWidget);
    const sections = <LumoSection>[
      LumoSection.reading, LumoSection.exercises, LumoSection.schoolwork,
      LumoSection.scanner, LumoSection.missions, LumoSection.progress,
      LumoSection.agent, LumoSection.settings,
    ];
    for (final section in sections) {
      final tile = find.byKey(ValueKey('lumo-nav-${section.name}'));
      await tester.ensureVisible(tile);
      await tester.pump();
      expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
      await tester.tap(tile);
      await tester.pump();
      expect(selected, section);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact 90dp navigation keeps Discover reachable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(300, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Row(children: [
      LeftNavigation(appState: appState, width: 90, onSelect: (_) {}),
      const Expanded(child: SizedBox.shrink()),
    ]))));
    await tester.tap(find.byKey(const ValueKey('lumo-nav-explore')));
    await tester.pump();
    expect(find.byKey(const ValueKey('lumo-nav-reading'), skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
