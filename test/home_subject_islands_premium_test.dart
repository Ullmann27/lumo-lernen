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
      final island = find.byKey(const ValueKey('home-island-technik'));
      await tester.scrollUntilVisible(
        island, 360, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(island, findsOneWidget);
      expect(find.byKey(const ValueKey('home-island-mathe')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-island-musik')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-island-kunst')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-logic-shortcut')), findsOneWidget);
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
    final music = find.byKey(const ValueKey('home-island-musik'));
    await tester.scrollUntilVisible(
      music, 360, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(music);
    await tester.pump();
    expect(find.byType(CurriculumActivitiesScreen), findsOneWidget);
    expect(find.text('Musik'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
