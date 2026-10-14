import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/theme/lumo_visual_tokens.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'portrait More reveals every missing Fold destination and scrolls to parents',
    (tester) async {
      for (final width in [360.0, 280.0]) {
        final selected = <LumoSection>[];
        await tester.binding.setSurfaceSize(Size(width, 640));
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            backgroundColor: LumoVisualTokens.night,
            bottomNavigationBar: LumoBottomNavigation(
              active: LumoSection.home,
              onSelect: selected.add,
            ),
          ),
        ));
        await tester.pump();
        final more = find.byKey(const ValueKey('lumo-nav-more'));
        expect(more, findsOneWidget);
        final button = tester.getRect(more);
        expect(button.right, lessThanOrEqualTo(width));
        expect(button.bottom, lessThanOrEqualTo(640));
        expect(button.width, greaterThanOrEqualTo(48));

        await tester.tap(more);
        // The first pump starts the modal route's entrance transition.
        // Advancing 450ms in that same first pump leaves the sheet offscreen.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Mehr mit Lumo'), findsOneWidget);
        expect(find.byKey(const ValueKey('lumo-nav-extra-scroll')),
            findsOneWidget);

        final parents = find.byKey(const ValueKey('lumo-nav-extra-settings'));
        await tester.scrollUntilVisible(
          parents,
          125,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('lumo-nav-extra-scroll')),
            matching: find.byType(Scrollable),
          ).first,
        );
        await tester.ensureVisible(parents);
        await tester.pump(const Duration(milliseconds: 200));
        expect(parents, findsOneWidget);
        expect(tester.getRect(parents).bottom,
          lessThanOrEqualTo(640),
          reason: 'Parent destination must be tappable on the cover screen');
        await tester.tap(parents);
        // Trigger route removal before advancing the reverse transition.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(selected, [LumoSection.settings]);
        expect(find.text('Mehr mit Lumo'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('five primary tabs stay accessible on a narrow 280dp cover',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selected = <LumoSection>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: LumoBottomNavigation(
          active: LumoSection.home,
          onSelect: selected.add,
        ),
      ),
    ));
    await tester.pump();

    final profile = find.byKey(const ValueKey('lumo-nav-profil'));
    await tester.ensureVisible(profile);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(profile).right, lessThanOrEqualTo(280));
    await tester.tap(profile);
    expect(selected.last, LumoSection.profile);
    expect(find.byKey(const ValueKey('lumo-nav-more')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
