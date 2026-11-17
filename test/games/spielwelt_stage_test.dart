import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_routes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Spielewelt displays the real reward balance after an update',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.binding.setSurfaceSize(const Size(690, 829));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    app.update(app.state.copyWith(stars: 317));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedBuilder(
          animation: app,
          builder: (context, _) => GamesContent(appState: app),
        ),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)));
    await tester.pump(const Duration(milliseconds: 800));
    final balance = find.byKey(const ValueKey('spielwelt-stars'));
    expect(tester.widget<Text>(balance).data, '317');
    app.update(app.state.copyWith(stars: 322));
    await tester.pump();
    expect(tester.widget<Text>(balance).data, '322');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Fold resizing and large text retain ten usable game targets',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(344, 882), Size(690, 829), Size(320, 620)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(body: GamesContent(appState: app)),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.pump(const Duration(milliseconds: 800));
      for (final identity in SpielweltRoutes.identities) {
        final target = find.byKey(ValueKey('spielwelt-portal-$identity'));
        expect(target, findsOneWidget, reason: '$size: $identity retained');
        final rect = tester.getRect(target);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull, reason: '$size at 180% text');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
