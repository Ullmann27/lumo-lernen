import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/lumo_rechentricks_poster_screen.dart';

import 'helpers/lumo_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);

  for (final (name, size) in [
    ('phone', const Size(393, 852)),
    ('fold-cover', const Size(320, 740)),
  ]) {
    testWidgets('Lumo Trick-Werkstatt original Flutter render $name',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const key = ValueKey('rechentricks-capture-boundary');
      await tester.pumpWidget(
        const MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: LumoRechentricksPosterScreen(),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 140));
      }
      final captureDirectory = Platform.environment['LUMO_TRICKS_CAPTURES'];
      if (captureDirectory != null) {
        await captureLumoBoundary(tester, key,
            '$captureDirectory/rechentricks-$name.png');
      }
      expect(find.byKey(const ValueKey('tricks-lesson')), findsOneWidget);
      expect(find.byKey(const ValueKey('tricks-result')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
