import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/games/logic/trail_puzzle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final device in const {
    'phone': Size(393, 852),
    'fold': Size(1000, 750),
  }.entries) {
    testWidgets('Pfotenpfad visible on ${device.key}', (tester) async {
      await tester.binding.setSurfaceSize(device.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      await app.school.setActiveStudent('trail-capture');
      await app.loadLearningProfile();
      app.state.settings = app.state.settings.copyWith(
          soundEnabled: false, reduceAnimations: true);
      const boundary = ValueKey('trail-capture');
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: boundary,
          child: TrailPuzzleScreen(
            appState: app,
            initialGrade: device.key == 'phone' ? 1 : 4,
            initialLevel: 1,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pfotenpfad'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final output = Platform.environment['LUMO_TRAIL_CAPTURES'];
      if (output != null && output.isNotEmpty) {
        await captureLumoBoundary(
          tester,
          boundary,
          '$output/trail-${device.key}-board.png',
          pixelRatio: 1.5,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('trail-run')));
        await tester.pumpAndSettle();
        await captureLumoBoundary(
          tester,
          boundary,
          '$output/trail-${device.key}-program.png',
          pixelRatio: 1.5,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }
}
