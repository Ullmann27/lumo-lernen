import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/cosmos/lumo_cosmos_screen.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/magic_hub/lumo_magic_hub_screen.dart';
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
    await tester.scrollUntilVisible(discover, -250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 140);
    await tester.ensureVisible(discover);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(discover);
    await tester.pump(const Duration(milliseconds: 650));

    final entry = find.byKey(target);
    await tester.scrollUntilVisible(entry, -220,
        scrollable: find.byType(Scrollable).first, maxScrolls: 140);
    await tester.ensureVisible(entry);
    await tester.pump(const Duration(milliseconds: 200));
    expect(entry.hitTestable(), findsOneWidget);
    await tester.tap(entry);
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
    expect(find.text('Lumo Magic ✨'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
