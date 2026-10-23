import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/learning/curriculum_activities_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Nine real 3D learning islands fit phone and unfolded Fold',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[320, 1024]) {
      await tester.binding.setSurfaceSize(Size(width, 1400));
      final state = LumoAppState();
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: HomeContent(appState: state, onSection: (_) {}),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 150));
      final chooser = find.text('Alle Fächer direkt öffnen');
      await tester.scrollUntilVisible(
        chooser, -300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(chooser);
      await tester.tap(chooser);
      // Start ExpansionTile's ticker before advancing its animation.
      // Otherwise its final card can be painted yet still clipped.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      // ExpansionTile builds all nine real islands. Verify the complete
      // catalogue before scrolling; forcing a fixed -360px delta on a
      // tall 320dp column can recycle its containing sliver.
      for (final key in const [
        'home-island-mathe',
        'home-island-deutsch',
        'home-island-lesen',
        'home-island-schreiben',
        'home-island-englisch',
        'home-island-sachkunde',
        'home-island-musik',
        'home-island-kunst',
        'home-island-technik',
        'home-logic-shortcut',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget,
            reason: 'Missing genuine subject route $key at width $width');
      }
      // The last island must also become genuinely tappable on a narrow Fold.
      // Center its actual InkWell rather than aligning it against a viewport
      // boundary hidden by a tall animated expansion panel.
      final island = find.byKey(const ValueKey('home-island-technik'));
      await Scrollable.ensureVisible(
        tester.element(island),
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      await tester.pump();
      if (island.hitTestable().evaluate().isEmpty) {
        final stillMounted = island.evaluate().isNotEmpty;
        debugPrint('Lumo Fold island: width=$width, '
            'stillMounted=$stillMounted, '
            'scrollable=${tester.getRect(find.byType(Scrollable).first)}');
        if (stillMounted) {
          debugPrint('Lumo Fold target geometry: ${tester.getRect(island)}');
        }
      }
      expect(island.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'No overflow or missing island at width $width');
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    }
  });

  testWidgets('Music island opens genuine grade-aware practical exercises',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(840, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeContent(appState: state, onSection: (_) {}),
      ),
    ));
    await tester.pump();
    final chooser = find.text('Alle Fächer direkt öffnen');
    await tester.scrollUntilVisible(
      chooser, -300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(chooser);
    await tester.tap(chooser);
    // Use the same real opening frames for the music touch-route test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final music = find.byKey(const ValueKey('home-island-musik'));
    await tester.scrollUntilVisible(
      music, -260, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(music);
    await tester.pump(const Duration(milliseconds: 500));
    expect(music.hitTestable(), findsOneWidget);
    await tester.tap(music);
    // MaterialPageRoute builds through its first transition frame. Check the
    // real destination after navigation, not during the initial push frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CurriculumActivitiesScreen), findsOneWidget);
    expect(find.text('Musik'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
