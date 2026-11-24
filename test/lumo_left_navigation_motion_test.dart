import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/widgets/shell/left_navigation.dart';

Widget _host(LumoAppState appState, {bool systemReduced = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: systemReduced),
      child: Scaffold(
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => Row(
            children: [
              LeftNavigation(
                appState: appState,
                onSelect: appState.setSection,
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _pillDecoration(WidgetTester tester, LumoSection section) {
  final container = find
      .descendant(
        of: find.byKey(ValueKey('lumo-nav-${section.name}')),
        matching: find.byType(AnimatedContainer),
      )
      .first;
  return tester.widget<AnimatedContainer>(container).decoration!
      as BoxDecoration;
}

void main() {
  testWidgets(
      'normal navigation keeps its active glow and working destinations',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(_host(app));
    final initial = _pillDecoration(tester, LumoSection.home);
    await tester.pump(const Duration(milliseconds: 370));
    expect(_pillDecoration(tester, LumoSection.home), isNot(initial));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('lumo-nav-learn')));
    await tester.pump();
    expect(app.state.section, LumoSection.learn);
    expect(_pillDecoration(tester, LumoSection.learn).boxShadow, isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final mode in ['app', 'calm', 'system']) {
    testWidgets(
        '$mode reduced motion stops the sidebar glow without losing taps',
        (tester) async {
      final app = LumoAppState();
      addTearDown(app.dispose);
      app.updateSettings(AppSettings(
        reduceAnimations: mode == 'app',
        calmMode: mode == 'calm',
      ));
      await tester.pumpWidget(_host(app, systemReduced: mode == 'system'));
      await tester.pump();
      final initial = _pillDecoration(tester, LumoSection.home);
      await tester.pump(const Duration(milliseconds: 370));
      expect(_pillDecoration(tester, LumoSection.home), initial);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.tap(find.byKey(const ValueKey('lumo-nav-learn')));
      await tester.pump();
      await tester.pump();
      expect(app.state.section, LumoSection.learn);
      expect(_pillDecoration(tester, LumoSection.learn).boxShadow, isNotEmpty);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing motion settings stops and resumes the existing sidebar',
      (tester) async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(_host(app));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    app.updateSettings(app.state.settings.copyWith(reduceAnimations: true));
    await tester.pump();
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    final still = _pillDecoration(tester, LumoSection.home);
    await tester.pump(const Duration(seconds: 1));
    expect(_pillDecoration(tester, LumoSection.home), still);

    app.updateSettings(app.state.settings.copyWith(reduceAnimations: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 370));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(_pillDecoration(tester, LumoSection.home), isNot(still));
    await tester.pumpWidget(_host(app, systemReduced: true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
