import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

void main() {
  for (final target in [
    (const Size(360, 800), 1.0, 'phone'),
    (const Size(967, 805), 1.6, 'fold'),
    (const Size(640, 360), 1.6, 'landscape'),
  ]) {
    testWidgets(
        'real oval task, matching pictures, wrong/right taps ${target.$3}',
        (tester) async {
      await tester.binding.setSurfaceSize(target.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final f = ExerciseFactory(seed: 1938);
      late LumoTask legacy;
      for (var i = 0; i < 100; i++) {
        legacy =
            f.next(grade: 1, subject: 'Mathematik', unit: 'Geometrie Formen');
        if (legacy.answer == 'Oval') break;
      }
      expect(legacy.answer, 'Oval');
      final task = const LegacyLumoTaskAdapter()
          .toTaskInstance(task: legacy, childId: 'synthetic', difficulty: 1);
      final answers = <bool>[];
      const boundary = ValueKey('actual-shapes-runtime');
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(
                  size: target.$1, textScaler: TextScaler.linear(target.$2)),
              child: Scaffold(
                  backgroundColor: const Color(0xFF07152F),
                  body: RepaintBoundary(
                      key: boundary,
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: AdaptiveTaskRenderer(
                              task: task,
                              onAnswered: (a) => answers.add(a.correct))))))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shape-help-Oval')), findsOneWidget);
      for (final shape in ['Kreis', 'Dreieck', 'Quadrat', 'Rechteck', 'Oval']) {
        expect(find.byKey(ValueKey('shape-help-$shape')),
            legacy.choices.contains(shape) ? findsOneWidget : findsNothing);
      }
      expect(tester.takeException(), isNull);
      final folder = Platform.environment['LUMO_SHAPE_CAPTURES'];
      if (folder != null) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
              .toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$folder/shapes-${target.$3}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final wrong =
          find.text(legacy.choices.firstWhere((x) => x != legacy.answer)).last;
      await tester.ensureVisible(wrong);
      await tester.tap(wrong);
      await tester.pumpAndSettle();
      final correct = find.text('Oval').last;
      await tester.ensureVisible(correct);
      await tester.tap(correct);
      await tester.pumpAndSettle();
      expect(answers, [false, true]);
      expect(tester.takeException(), isNull);
    });
  }
}
