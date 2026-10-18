import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';
import '../helpers/lumo_capture.dart';

void main() {
  setUpAll(loadLumoCaptureFonts);
  testWidgets(
      'Fold cover keeps full navigation labels and reachable destinations with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selected = <LumoSection>[];
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
                body: Align(
                    alignment: Alignment.bottomCenter,
                    child: LumoBottomNavigation(
                        active: LumoSection.learn, onSelect: selected.add))))));
    for (final label in ['Start', 'Lernen', 'Spielen', 'Tests', 'Profil']) {
      final text = tester.widget<Text>(find.text(label));
      final painter = TextPainter(
          text: TextSpan(text: label, style: text.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(1.6))
        ..layout();
      final cell = tester
          .getSize(find.byKey(ValueKey('lumo-nav-${label.toLowerCase()}')));
      expect(cell.width, greaterThanOrEqualTo(painter.width + 8),
          reason: label);
      painter.dispose();
    }
    await tester.tap(find.byKey(const ValueKey('lumo-nav-lernen')));
    final rail = find.byKey(const ValueKey('lumo-nav-primary-scroll'));
    await tester.drag(rail, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lumo-nav-profil')));
    expect(selected, [LumoSection.learn, LumoSection.profile]);
    expect(tester.getRect(find.byKey(const ValueKey('lumo-nav-more'))).right,
        lessThanOrEqualTo(344));
    expect(tester.takeException(), isNull);
  });
}
