import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
    await fonts.load();
  });
  for (final target in [
    (const Size(360, 800), 1.0, 'phone'),
    (const Size(967, 805), 1.6, 'fold'),
    (const Size(640, 360), 1.6, 'landscape')
  ]) {
    testWidgets(
        'actual fourth-grade reading, wrong attempt and retry on ${target.$3}',
        (tester) async {
      await tester.binding.setSurfaceSize(target.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final legacy = ExerciseFactory(seed: 1937)
          .next(grade: 4, subject: 'Lesen', unit: 'Lesesinn');
      final task = const LegacyLumoTaskAdapter()
          .toTaskInstance(task: legacy, childId: 'synthetic', difficulty: 4);
      final answers = <bool>[];
      const captureKey = ValueKey('reading-capture');
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(
                  size: target.$1, textScaler: TextScaler.linear(target.$2)),
              child: Scaffold(
                  backgroundColor: const Color(0xFF07152F),
                  body: RepaintBoundary(
                      key: captureKey,
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: AdaptiveTaskRenderer(
                              task: task,
                              onAnswered: (a) => answers.add(a.correct))))))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reading-passage')), findsOneWidget);
      expect(find.byKey(const ValueKey('reading-question')), findsOneWidget);
      expect(tester.takeException(), isNull);
      final wrong = find.text(task.options
          .firstWhere((x) => '${x.payload}' != '${task.correctAnswer}')
          .label);
      await tester.ensureVisible(wrong);
      await tester.tap(wrong);
      await tester.pumpAndSettle();
      final correct = find.text(task.options
          .firstWhere((x) => '${x.payload}' == '${task.correctAnswer}')
          .label);
      await tester.ensureVisible(correct);
      await tester.tap(correct);
      await tester.pumpAndSettle();
      expect(answers, [false, true]);
      expect(tester.takeException(), isNull);
      final folder = Platform.environment['LUMO_READING_CAPTURES'];
      if (folder != null) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
              .toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$folder/reading-${target.$3}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
