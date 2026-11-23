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
    'phone': Size(390, 800),
    'phone-narrow': Size(344, 800),
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
        builder: (context, child) => RepaintBoundary(
          key: boundary,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: child!,
          ),
        ),
        home: TrailPuzzleScreen(
          appState: app,
          initialGrade: device.key == 'phone' ? 1 : 4,
          initialLevel: 1,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pfotenpfad'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final phone = device.key.startsWith('phone');
      if (phone) {
        final board = tester.getRect(find.byKey(const ValueKey('trail-board')));
        expect(board.top, greaterThanOrEqualTo(80));
        expect(board.width, greaterThanOrEqualTo(190));
        for (final direction in const ['up', 'right', 'down', 'left']) {
          final button = find.byKey(ValueKey('trail-add-$direction'));
          final rect = tester.getRect(button);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.top, greaterThanOrEqualTo(board.bottom));
          expect(rect.bottom, lessThanOrEqualTo(device.value.height - 24));
          expect(button.hitTestable(), findsOneWidget);
        }
      }
      final output = Platform.environment['LUMO_TRAIL_CAPTURES'];
      if (output != null && output.isNotEmpty) {
        await captureLumoBoundary(
          tester,
          boundary,
          '$output/trail-${device.key}-board.png',
          pixelRatio: 1.5,
        );
        if (phone) {
          // These presses must work without scrolling the board away.
          for (final direction in const ['right', 'right', 'up']) {
            await tester.tap(find.byKey(ValueKey('trail-add-$direction')));
            await tester.pumpAndSettle();
          }
        } else {
          await tester.ensureVisible(find.byKey(const ValueKey('trail-run')));
        }
        await tester.pumpAndSettle();
        await captureLumoBoundary(
          tester,
          boundary,
          '$output/trail-${device.key}-program.png',
          pixelRatio: 1.5,
        );
        if (device.key == 'phone-narrow') {
          await tester.tap(find.byKey(const ValueKey('trail-choose')));
          await tester.pumpAndSettle();
          await captureLumoBoundary(
            tester, boundary, '$output/trail-phone-narrow-chooser.png',
            pixelRatio: 1.5,
          );
          await tester.tap(find.text('Beim aktuellen Pfad bleiben'));
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }
}
