import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/cosmos/lumo_cosmos_screen.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/magic_hub/lumo_magic_hub_screen.dart';
import 'package:lumo_lernen/features/story/lumo_quest_hub_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> showHome(WidgetTester tester, LumoAppState app) async {
    await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: HomeContent(
            appState: app,
            onSection: (_) {},
            drawBackground: false,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openDiscovery(WidgetTester tester, Key target) async {
    final discover = find.text('Mehr mit Lumo entdecken');
    await tester.scrollUntilVisible(discover, 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 140);
    await tester.ensureVisible(discover);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(discover);
    // Flutter establishes ExpansionTile's ticker epoch on the first frame.
    // Without this frame the last discovery actions can be drawn but clipped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    final entry = find.byKey(target);
    final action = find.descendant(
        of: entry, matching: find.byType(InkWell)).first;
    final homeList =
        find.byKey(const PageStorageKey<String>('lumo-home-scroll'));
    expect(homeList, findsOneWidget);
    // Scroll the actual outer home viewport. Nested scrollables can make
    // scrollUntilVisible/ensureVisible leave the InkWell below the screen.
    for (var i = 0; i < 60 && action.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(homeList, const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(action.hitTestable(), findsOneWidget,
        reason: 'Discovery action must be physically touchable in the viewport');
    expect(tester.widget<InkWell>(action).onTap, isNotNull);
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
  }

  testWidgets('Mirror studio opens directly from compact discovery',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: 3));

    await showHome(tester, app);
    expect(find.byKey(const ValueKey('home-learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-games')), findsOneWidget);
    await openDiscovery(tester, const ValueKey('home-discover-mirror'));
    expect(find.byType(LumoMirrorShowcaseScreen), findsOneWidget);
    expect(find.text('Lumo Mirror'), findsWidgets);
    expect(app.state.grade, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Cosmos opens from Fold discovery without changing school grade',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(840, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    app.update(app.state.copyWith(grade: 4));

    await showHome(tester, app);
    await openDiscovery(tester, const ValueKey('home-discover-cosmos'));
    expect(find.byType(LumoCosmosScreen), findsOneWidget);
    expect(app.state.grade, 4);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Magic hub keeps all premium worlds on a readable 1992 scene',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);

    await showHome(tester, app);
    await openDiscovery(tester, const ValueKey('home-discover-magic-hub'));
    expect(find.byType(LumoMagicHubScreen), findsOneWidget);
    expect(find.byType(LumoSceneBackground), findsOneWidget);
    expect(find.text('Lumo Magic'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('all five premium discovery routes keep 48dp touch targets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);

    await showHome(tester, app);
    final discover = find.text('Mehr mit Lumo entdecken');
    await tester.scrollUntilVisible(discover, 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 140);
    await tester.ensureVisible(discover);
    await tester.tap(discover);
    // Flutter establishes ExpansionTile's ticker epoch on the first frame.
    // Without this frame the last discovery actions can be drawn but clipped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    for (final name in const [
      'home-discover-live',
      'home-discover-mirror',
      'home-discover-cosmos',
      'home-discover-quest',
      'home-discover-magic-hub',
    ]) {
      final entry = find.byKey(ValueKey(name));
      expect(entry, findsOneWidget, reason: name);
      await tester.ensureVisible(entry);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48),
          reason: '$name has to be comfortable for children to touch');
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('premium Magic hub opens the real Quest screen on Fold cover',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);

    await showHome(tester, app);
    await openDiscovery(tester, const ValueKey('home-discover-magic-hub'));
    final quest = find.byKey(const ValueKey('magic-quest-route'));
    final questTap = find.descendant(
        of: quest, matching: find.byType(InkWell)).first;
    final questList = find.descendant(
        of: find.byType(LumoMagicHubScreen),
        matching: find.byType(ListView)).first;
    for (var i = 0; i < 30 && questTap.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(questList, const Offset(0, -140));
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(questTap.hitTestable(), findsOneWidget);
    expect(tester.widget<InkWell>(questTap).onTap, isNotNull);
    await tester.tap(questTap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(LumoQuestHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
