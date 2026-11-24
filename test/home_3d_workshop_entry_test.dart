import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/home/home_content.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_hub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('3D workshop is directly reachable from the real home on Fold',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeContent(
          appState: app,
          onSection: (_) {},
          drawBackground: false,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    final workshop = find.byKey(const ValueKey('home-3d-workshop'));
    expect(workshop, findsOneWidget);
    expect(find.byKey(const ValueKey('home-learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-games')), findsOneWidget);
    await tester.ensureVisible(workshop);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(workshop).height, greaterThanOrEqualTo(48));
    expect(workshop.hitTestable(), findsOneWidget);
    expect(tester.widget<FilledButton>(workshop).onPressed, isNotNull,
        reason: 'The visible primary action must be wired to a real route');
    await tester.tap(workshop);
    // The first frame schedules Navigator.push; the next frame animates the
    // actual MaterialPageRoute into the visible widget tree.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(LearningLabHub), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
