import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_answer_crystal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

Future<void> _frames(WidgetTester tester, [int count = 24]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);

  testWidgets('Akademie Minus route renders four deep, visible crystal answers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = LumoAppState();
      addTearDown(app.dispose);
      final previousVoice = LumoVoice.instance.isEnabled;
      LumoVoice.instance.isEnabled = false;
      addTearDown(() => LumoVoice.instance.isEnabled = previousVoice);
      await tester.runAsync(() async {
        await app.hydrateFromWallet();
        await app.loadLearningProfile();
      });
      app.state.settings = app.state.settings.copyWith(
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
      );
      const boundaryKey = ValueKey('minus-crystal-route-capture');
      await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LumoAppTheme.light(),
          home: LumoAkademieScreen(appState: app),
        ),
      ));
      await _frames(tester);
      await tester.tap(find.byKey(const ValueKey('grade-pill-1')));
      await tester.pump();
      final math = find.byKey(const ValueKey('learning-subject-Mathematik'));
      await tester.ensureVisible(math);
      await tester.tap(math);
      await _frames(tester);
      final topic =
          find.byKey(const ValueKey('learning-unit-Mathematik-Minus bis 10'));
      await tester.scrollUntilVisible(topic, 180,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(topic);
      await tester.pumpAndSettle();
      await tester.tap(topic);
      await _frames(tester);
      expect(find.byType(MinusBis10Screen), findsOneWidget);
      final crystals = find.byType(LumoAnswerCrystal);
      expect(crystals, findsNWidgets(4));
      expect(
          tester
              .widgetList<LumoAnswerCrystal>(crystals)
              .every((c) => c.state == LumoCrystalState.neutral),
          isTrue);
      final output = Platform.environment['LUMO_CRYSTAL_CAPTURE_DIR'];
      // Long subtraction visualisations can add a second row of sweets.
      // Use the real scroll path so all four complete pedestals are visible.
      await tester.ensureVisible(crystals.last);
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        final rect = tester.getRect(crystals.at(i));
        expect(rect.height, greaterThanOrEqualTo(100),
            reason:
                'The crystal body and pedestal must not collapse into a bar');
        expect(rect.width, greaterThanOrEqualTo(48));
        final button = find.descendant(
            of: crystals.at(i), matching: find.byType(OutlinedButton));
        expect(button.hitTestable(), findsOneWidget);
        final node = tester.getSemantics(button);
        expect(node.label,
            contains(tester.widget<LumoAnswerCrystal>(crystals.at(i)).label));
      }
      // Inspect actual composite pixels, including Material/Button descendants.
      // A theme background covering the painter also fails this check.
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
      final rect = tester.getRect(crystals.first);
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          if (output != null) {
            final png =
                (await image.toByteData(format: ui.ImageByteFormat.png))!;
            final file = File('$output/minus-phone.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png.buffer.asUint8List());
          }
          final pixels =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          var brightFacetPixels = 0;
          var samples = 0;
          for (var y = (rect.top + rect.height * .2).round();
              y < rect.top + rect.height * .56;
              y++) {
            for (var x = (rect.left + rect.width * .08).round();
                x < rect.left + rect.width * .24;
                x++) {
              final offset = (y * image.width + x) * 4;
              if (pixels.getUint8(offset + 1) > 105 &&
                  pixels.getUint8(offset + 2) > 150) {
                brightFacetPixels++;
              }
              samples++;
            }
          }
          expect(brightFacetPixels / samples, greaterThan(.15),
              reason: 'Side facets must be visibly lit, not dark flat blue');
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _frames(tester, 2);
    } finally {
      semantics.dispose();
    }
  });
}
