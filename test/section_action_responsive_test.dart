import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/sections/section_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Schoolwork cards fit Fold cover, scale and navigate correctly',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [280.0, 360.0, 967.0]) {
      await tester.binding.setSurfaceSize(Size(width, 780));
      final appState = LumoAppState();
      final selected = <LumoSection>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 780),
              textScaler: const TextScaler.linear(1.6),
            ),
            child: SectionContent(
              appState: appState,
              section: LumoSection.schoolwork,
              onSection: selected.add,
            ),
          ),
        ),
      ));
      await tester.pump();
      final actionButtons = find.byType(InkWell);
      expect(actionButtons, findsWidgets);
      for (final element in actionButtons.evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width + 0.1));
      }
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Englisch-Lerncheck'));
      await tester.pump();
      await tester.tap(find.text('Englisch-Lerncheck'));
      expect(selected.last, LumoSection.exercises);
      expect(appState.state.subject, 'Englisch');
      expect(appState.state.sessionKind, LumoSessionKind.test);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      appState.dispose();
    }
  });
}
