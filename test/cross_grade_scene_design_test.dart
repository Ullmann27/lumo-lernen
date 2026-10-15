import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning/cross_grade_writing_screen.dart';
import 'package:lumo_lernen/features/learning/widgets/cross_grade_visual_scene.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('practice shares official library, real Lumo and glass, '
      'but choices remain interactive at Fold cover width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CrossGradePracticeScreen(
          profileName: 'VisuelleProbe',
          enrolledGrade: 2,
          lessonGrade: 3,
          subject: 'Mathematik',
          unit: 'Plus bis 1000',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final scene = tester.widget<LumoSceneBackground>(
        find.byType(LumoSceneBackground));
    expect(scene.scene, LumoScene.library);
    expect(scene.dimmed, true);
    expect(find.byType(CrossGradeLumoHeader), findsOneWidget);
    expect(find.byType(LumoFoxPose), findsOneWidget);
    expect(find.byType(LumoGlassCard), findsAtLeastNWidgets(2));
    expect(find.byKey(const ValueKey('cross-grade-profile-info')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('cross-grade-question')),
        findsOneWidget);
    final firstChoice = find.byKey(const ValueKey('cross-grade-choice-0'));
    await tester.ensureVisible(firstChoice);
    await tester.tap(firstChoice);
    await tester.pump();
    expect(find.byKey(const ValueKey('cross-grade-feedback')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grade-four editor shares library / original fox '
      'and saves a real draft with animations disabled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: CrossGradeWritingScreen(
          profileName: 'VisuelleProbe',
          enrolledGrade: 2,
        ),
      ),
    ));
    await tester.pump();
    final scene = tester.widget<LumoSceneBackground>(
        find.byType(LumoSceneBackground));
    expect(scene.scene, LumoScene.library);
    expect(scene.dimmed, true);
    expect(find.byType(LumoFoxPose), findsOneWidget);
    expect(find.byType(CrossGradeGlassPanel), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('cross-grade-writing-input')),
      'Lumo liest seine Karte und findet den geheimen Hafen.',
    );
    final save = find.byKey(const ValueKey('cross-grade-writing-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.byKey(const ValueKey('cross-grade-writing-saved')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
