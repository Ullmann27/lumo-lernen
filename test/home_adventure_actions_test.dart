import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/home/home_content.dart';

import 'helpers/lumo_capture.dart';

void main() {
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scale in [1.0, 2.0]) {
    testWidgets('illustrated secondary actions navigate directly at $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      final routes = <LumoSection>[];
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true,
              textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: HomeContent(appState: app, onSection: routes.add)),
        ),
      ));
      await tester.pump();
      for (final (key, route) in [
        ('home-secondary-tests', LumoSection.tests),
        ('home-secondary-rewards', LumoSection.rewards),
        ('home-kart-banner', LumoSection.games),
      ]) {
        final target = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(target, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(target);
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.getSize(target).shortestSide, greaterThanOrEqualTo(48));
        await tester.tap(target);
        expect(routes.last, route);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
