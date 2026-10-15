import 'package:flutter/material.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';

/// Base-ten regrouping and equal-area fractions inside the existing lesson.
/// Completed solutions are drawn only during a worked example.
class GuidedAdvancedMathIllustration extends StatelessWidget {
  const GuidedAdvancedMathIllustration(
      {super.key,
      required this.lesson,
      required this.step,
      required this.reduceMotion});
  final GuidedLesson lesson;
  final GuidedLessonStep step;
  final bool reduceMotion;
  static const text = TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w800,
      color: Colors.white,
      fontSize: 16,
      height: 1.4);
  @override
  Widget build(BuildContext context) {
    if (step.a == 0) {
      return LumoLessonSurface(
          child: Column(children: [
        Icon(
            lesson.concept == GuidedLessonConcept.bridgeHundred
                ? Icons.grid_on_rounded
                : Icons.pie_chart_outline_rounded,
            color: LumoVisualTokens.gold,
            size: 48),
        const SizedBox(height: 12),
        const Text('Anschauen. Gemeinsam üben. Selbst ausprobieren.',
            style: text, textAlign: TextAlign.center)
      ]));
    }
    return lesson.concept == GuidedLessonConcept.fractionParts
        ? _fractions()
        : _hundreds();
  }

  Widget _hundreds() {
    final foundation = step.answerKind == GuidedAnswerKind.tensValue;
    if (foundation) {
      return LumoLessonSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Jeder Streifen ist ein Zehner.', style: text),
        const SizedBox(height: 12),
        BaseTenBlocks(value: step.a * 10)
      ]));
    }
    final example = step.type == TutoringStepType.showExample;
    return LumoLessonSurface(
        child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: example ? 1 : 0),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 3000),
            builder: (context, time, _) {
              final phase = !example || time < .35
                  ? 0
                  : time < .75
                      ? 1
                      : 2;
              final moved = phase == 0
                  ? 0
                  : phase == 1
                      ? step.nextHundred - step.a
                      : step.b;
              final left = step.a + moved;
              final right = step.b - moved;
              final description = phase == 0
                  ? '${step.a} + ${step.b}'
                  : phase == 1
                      ? '${step.a} + $moved = $left. Von ${step.b} bleiben $right.'
                      : '${step.nextHundred} + ${step.a + step.b - step.nextHundred} = $left';
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(description,
                        key: const ValueKey('guided-hundred-calculation'),
                        style: text.copyWith(fontSize: 22)),
                    const SizedBox(height: 12),
                    const Text('Erste Zahl', style: text),
                    const SizedBox(height: 6),
                    BaseTenBlocks(
                        key: const ValueKey('hundred-first-quantity'),
                        value: left),
                    const SizedBox(height: 12),
                    const Text('Kommt dazu', style: text),
                    const SizedBox(height: 6),
                    BaseTenBlocks(
                        key: const ValueKey('hundred-second-quantity'),
                        value: right,
                        color: LumoVisualTokens.gold),
                    const SizedBox(height: 10),
                    Text(
                        example
                            ? 'Zehn Zehner werden zu einem Hunderter gebündelt. Kein Feld geht verloren.'
                            : 'Ein großes Feld enthält hundert kleine Felder. Ein Streifen enthält zehn.',
                        style: text)
                  ]);
            }));
  }

  Widget _fractions() {
    final example = step.type == TutoringStepType.showExample;
    return LumoLessonSurface(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Ein Ganzes in gleich großen Teilen', style: text),
      const SizedBox(height: 16),
      Semantics(
          label:
              'Ein Rechteck ist in ${step.b} gleich große Teile geteilt. Orange und Blau markieren Teile dieses einen Ganzen.',
          excludeSemantics: true,
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: example ? 0 : 1, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 1400),
              builder: (context, time, _) => SizedBox(
                  height: 84,
                  child: Row(
                      key: const ValueKey('guided-fraction-whole'),
                      children: [
                        for (var i = 0; i < step.b; i++)
                          Expanded(
                              child: DecoratedBox(
                                  key: ValueKey('fraction-part-$i'),
                                  decoration: BoxDecoration(
                                      color: i < step.a
                                          ? LumoVisualTokens.gold
                                              .withValues(alpha: .8)
                                          : i < step.a + step.fractionExtra
                                              ? LumoVisualTokens.cyan
                                                  .withValues(
                                                      alpha: .15 + .65 * time)
                                              : const Color(0xFF143655),
                                      border: Border.all(
                                          color: Colors.white, width: 1.2)),
                                  child: const SizedBox.expand()))
                      ])))),
      const SizedBox(height: 12),
      Text(
          example
              ? '${step.a}/${step.b} + ${step.fractionExtra}/${step.b} = ${step.a + step.fractionExtra}/${step.b}'
              : 'Zähle alle gleich großen Teile und die markierten Teile. Die Größe der Teile bleibt gleich.',
          style: text,
          key: const ValueKey('guided-fraction-description'))
    ]));
  }
}

/// One tile contains exactly 100 cells; one rod contains exactly ten.
/// Wrapping changes the arrangement without changing the represented value.
class BaseTenBlocks extends StatelessWidget {
  const BaseTenBlocks(
      {super.key, required this.value, this.color = LumoVisualTokens.cyan});
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < value ~/ 100; i++)
              SizedBox(
                  key: ValueKey('hundred-tile-$i'),
                  width: 70,
                  height: 70,
                  child: CustomPaint(painter: _CellGrid(10, 10, color))),
            for (var i = 0; i < value % 100 ~/ 10; i++)
              SizedBox(
                  key: ValueKey('ten-rod-$i'),
                  width: 14,
                  height: 70,
                  child: CustomPaint(painter: _CellGrid(1, 10, color))),
            for (var i = 0; i < value % 10; i++)
              SizedBox(
                  key: ValueKey('one-cell-$i'),
                  width: 10,
                  height: 10,
                  child: ColoredBox(color: color)),
            if (value == 0)
              const Text('Kein Rest',
                  style: GuidedAdvancedMathIllustration.text),
          ]);
}

class _CellGrid extends CustomPainter {
  const _CellGrid(this.columns, this.rows, this.color);
  final int columns;
  final int rows;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color.withValues(alpha: .75);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final width = size.width / columns;
    final height = size.height / rows;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final rect = Rect.fromLTWH(x * width, y * height, width, height);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, line);
      }
    }
  }

  @override
  bool shouldRepaint(_CellGrid old) =>
      old.columns != columns || old.rows != rows || old.color != color;
}
