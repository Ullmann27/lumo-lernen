import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/parents/lumo_insight_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Lumo Insight keeps four evidence counters readable on phone and Fold',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final app = LumoAppState();
    addTearDown(app.dispose);

    for (final width in [320.0, 360.0, 800.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1000),
            textScaler: const TextScaler.linear(1.2),
          ),
          child: LumoInsightDashboard(appState: app),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 48));

      final first = tester.getTopLeft(find.text('Gesamt'));
      final second = tester.getTopLeft(find.text('Streak'));
      final third = tester.getTopLeft(find.text('Staerken'));
      final fourth = tester.getTopLeft(find.text('Übung'));

      expect((first.dy - second.dy).abs(), lessThan(3),
          reason: 'First pair shares one row at width $width');
      if (width < 640) {
        expect(third.dy, greaterThan(first.dy + 35),
            reason: 'Phone stats must form a legible second row');
        expect((third.dy - fourth.dy).abs(), lessThan(3));
      } else {
        expect((first.dy - third.dy).abs(), lessThan(3),
            reason: 'Fold stats must share one spacious row');
        expect((first.dy - fourth.dy).abs(), lessThan(3));
      }
      expect(find.byKey(const ValueKey('insight-stats-grid')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
