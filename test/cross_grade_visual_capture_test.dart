import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_theme.dart';

import 'helpers/lumo_capture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';

// Actual offscreen Flutter renderings. The eight answers are explicitly
// synthetic QA fixtures, not a child profile or remotely earned points.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Capture the APK's real Nunito glyph outlines and Material icon font.
  // Without these, the default Flutter test font paints solid Ahem blocks.
  setUpAll(loadLumoCaptureFonts);

  testWidgets('captures real library/hologlass lesson on phone and Fold',
      (tester) async {
    const scope =
        'cross_grade_practice_v1:visuelleprobe:3:Mathematik:Plus bis 1000';
    SharedPreferences.setMockInitialValues({
      '$scope:answered': 8,
      '$scope:correct': 6,
    });
    final output = Directory('visual-evidence')..createSync(recursive: true);
    final configs = <(String, Size)>[
      ('phone_390x844', const Size(390, 844)),
      ('fold_cover_320x780', const Size(320, 780)),
      ('fold_open_840x760', const Size(840, 760)),
    ];

    for (final (name, size) in configs) {
      await tester.binding.setSurfaceSize(size);
      final captureKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          theme: LumoAppTheme.light(),
          home: const CrossGradePracticeScreen(
            profileName: 'VisuelleProbe',
            enrolledGrade: 2,
            lessonGrade: 3,
            subject: 'Mathematik',
            unit: 'Plus bis 1000',
          ),
        ),
      ));
      // Finish the real prefs load and 850 ms ribbon transition.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('75 %'), findsOneWidget);
      final boundary = captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      // The rasterizer runs asynchronously; a testWidgets fake-async await
      // on toImage() can deadlock indefinitely in headless GitHub CI.
      // Keep the true rendered pixels and their original PNG bytes.
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          expect(data, isNotNull);
          await File('${output.path}/cross_grade_$name.png')
              .writeAsBytes(data!.buffer.asUint8List(), flush: true);
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
