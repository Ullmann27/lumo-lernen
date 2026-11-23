import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/domain/world/world_school_mission.dart';
import 'package:lumo_lernen/features/games/world/world_school_lesson_screen.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final device in const {
    'fold-cover': Size(344, 882),
    'fold-open': Size(690, 829),
  }.entries) {
    testWidgets('world school visible on ${device.key}', (tester) async {
      await tester.binding.setSurfaceSize(device.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      await app.school.setActiveStudent('school-capture');
      await app.loadLearningProfile();
      final owner = await app.captureLearningProfile();
      const boundary = ValueKey('world-school-capture');
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: RepaintBoundary(
          key: boundary,
          child: WorldSchoolLessonScreen(
            appState: app,
            owner: owner,
            request: WorldSchoolMissionRequest(
                requestId: 'school-capture-request', grade: 1),
          ),
        ),
      ));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 25));
      }
      expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
      expect(find.text('Die Schule braucht dich!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final out = Platform.environment['LUMO_SCHOOL_CAPTURES'];
      if (out != null && out.isNotEmpty) {
        await captureLumoBoundary(
            tester, boundary, '$out/world-school-${device.key}.png',
            pixelRatio: 1.5);
        expect(tester.takeException(), isNull);
      }
      final help = find.byKey(const ValueKey('world-school-help'));
      await tester.ensureVisible(help);
      expect(tester.getSize(help).height, greaterThanOrEqualTo(48));
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }
}
