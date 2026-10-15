import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';
import '../../widgets/design/lumo_quantity_art.dart';
import 'guided_language_nature_illustration.dart';
import 'guided_advanced_math_illustration.dart';

/// Actual countable original assets. Moving apples remain single widgets:
/// no duplicated "animation" objects that could falsify a quantity.
class GuidedMathIllustration extends StatelessWidget {
  static const _sourceColumns = 3;
  const GuidedMathIllustration({
    super.key,
    required this.lesson,
    required this.step,
    required this.reduceMotion,
  });

  final GuidedLesson lesson;
  final GuidedLessonStep step;
  final bool reduceMotion;

  static const _text = TextStyle(
      color: LumoVisualTokens.white,
      fontFamily: 'Nunito',
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w800);

  @override
  Widget build(BuildContext context) {
    if (lesson.concept == GuidedLessonConcept.bridgeHundred ||
        lesson.concept == GuidedLessonConcept.fractionParts) {
      return GuidedAdvancedMathIllustration(
          lesson: lesson, step: step, reduceMotion: reduceMotion);
    }
    if (lesson.subject != 'Mathematik') {
      return GuidedLanguageNatureIllustration(
          lesson: lesson, step: step, reduceMotion: reduceMotion);
    }
    if (step.a == 0) {
      return LumoLessonSurface(
        child: Column(children: [
          Icon(
              switch (lesson.concept) {
                GuidedLessonConcept.bridgeTen => Icons.grid_view_rounded,
                GuidedLessonConcept.equalGroups => Icons.workspaces_rounded,
                GuidedLessonConcept.subtractTen => Icons.remove_circle_outline,
                GuidedLessonConcept.syllables => Icons.hearing_rounded,
                GuidedLessonConcept.plantParts => Icons.local_florist_rounded,
                GuidedLessonConcept.bridgeHundred => Icons.grid_on_rounded,
                GuidedLessonConcept.fractionParts =>
                  Icons.pie_chart_outline_rounded,
              },
              color: LumoVisualTokens.gold,
              size: 48),
          const SizedBox(height: 12),
          const Text('Anschauen. Gemeinsam üben. Selbst ausprobieren.',
              style: _text, textAlign: TextAlign.center),
        ]),
      );
    }
    if (step.b == 0) {
      return LumoLessonSurface(
        child: Semantics(
          label: '${step.a} Äpfel',
          excludeSemantics: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < step.a; i++)
                LumoQuantityArt.apple(
                    key: ValueKey('guided-count-apple-$i'), size: 36),
            ],
          ),
        ),
      );
    }
    return switch (lesson.concept) {
      GuidedLessonConcept.equalGroups => _groups(),
      GuidedLessonConcept.bridgeTen => _tenFrame(context),
      GuidedLessonConcept.subtractTen => _subtraction(),
      _ =>
        throw StateError('Non-mathematical lesson routed to math illustration'),
    };
  }

  Widget _subtraction() => LumoLessonSurface(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(builder: (context, constraints) {
          final cell = math.min(
              54.0, (constraints.maxWidth - 20) / (5 + _sourceColumns));
          final trayX = cell * 5 + 12;
          final height = math.max((step.a / 5).ceil() * cell,
                  (step.b / _sourceColumns).ceil() * cell) +
              6;
          final example = step.type == TutoringStepType.showExample;
          // An independent question retains the full starting quantity:
          // the completed animation must never reveal its answer.
          final removal = example
              ? step.b
              : step.answerKind == GuidedAnswerKind.subtractRemainder
                  ? step.a % 10
                  : 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${step.a} − ${step.b}',
                  style: _text.copyWith(fontSize: 26),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: trayX, child: const Text('Da', style: _text)),
                const Expanded(child: Text('Weg', style: _text)),
              ]),
              const SizedBox(height: 8),
              Semantics(
                label: '${step.a} Äpfel am Anfang. '
                    '${step.b} sollen weggenommen werden.',
                excludeSemantics: true,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: removal > 0 ? 1 : 0),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1600),
                  builder: (context, fraction, _) => SizedBox(
                    height: height,
                    child: Stack(children: [
                      for (var i = 0; i < 10; i++)
                        Positioned(
                          left: (i % 5) * cell,
                          top: (i ~/ 5) * cell,
                          width: cell - 3,
                          height: cell - 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF103966),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: LumoVisualTokens.cyan
                                      .withValues(alpha: .55)),
                            ),
                          ),
                        ),
                      for (var i = 0; i < step.a; i++)
                        _subtractionApple(i, cell, trayX, removal, fraction),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                  example
                      ? '${step.a} − ${step.a % 10} = 10. '
                          '10 − ${step.b - step.a % 10} = ${step.a - step.b}.'
                      : removal > 0
                          ? 'Bis zehn sind wir schon zurück. '
                              'Welcher Teil fehlt noch?'
                          : 'Erst bis zehn zurück, dann den Rest wegnehmen.',
                  style: _text),
            ],
          );
        }),
      );

  Widget _subtractionApple(
      int index, double cell, double trayX, int removal, double fraction) {
    final order = step.a - 1 - index;
    final initial = Offset((index % 5) * cell, (index ~/ 5) * cell);
    final destination = Offset(trayX + (order % _sourceColumns) * cell,
        (order ~/ _sourceColumns) * cell);
    // Show the first subtraction to ten before moving the remaining apples.
    final firstPart = order < step.a % 10;
    final progress = order >= removal
        ? 0.0
        : firstPart
            ? (fraction / .45).clamp(0.0, 1.0)
            : ((fraction - .55) / .45).clamp(0.0, 1.0);
    final position = Offset.lerp(
        initial, destination, Curves.easeInOutCubic.transform(progress))!;
    return Positioned(
      key: ValueKey('guided-subtract-apple-$index'),
      left: position.dx,
      top: position.dy,
      width: cell - 3,
      height: cell - 3,
      child: LumoQuantityArt.apple(size: cell - 3),
    );
  }

  Widget _groups() => LumoLessonSurface(
        child: LayoutBuilder(builder: (context, constraints) {
          final columns = math.max(
              1, math.min(step.a, (constraints.maxWidth / 116).floor()));
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Column(children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var group = 0; group < step.a; group++)
                  SizedBox(
                    width: width,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: const Color(0xFF123D70),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  LumoVisualTokens.cyan.withValues(alpha: .7))),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(children: [
                          Text('Gruppe ${group + 1}', style: _text),
                          const SizedBox(height: 10),
                          Semantics(
                            label: '${step.b} Äpfel in Gruppe ${group + 1}',
                            excludeSemantics: true,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 3,
                              runSpacing: 3,
                              children: [
                                for (var item = 0; item < step.b; item++)
                                  LumoQuantityArt.apple(
                                      key: ValueKey(
                                          'guided-group-apple-$group-$item'),
                                      size: 30),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
            if (step.type == TutoringStepType.showExample) ...[
              const SizedBox(height: 12),
              Text(
                  '${List.filled(step.a, "${step.b}").join(" + ")} = '
                  '${step.a * step.b}',
                  style: _text.copyWith(fontSize: 20),
                  textAlign: TextAlign.center),
              Text('${step.a} × ${step.b} = ${step.a * step.b}',
                  style: _text.copyWith(fontSize: 20),
                  textAlign: TextAlign.center),
            ],
          ]);
        }),
      );

  Widget _tenFrame(BuildContext context) => LumoLessonSurface(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(builder: (context, constraints) {
          final cell = math.min(
              54.0, (constraints.maxWidth - 20) / (5 + _sourceColumns));
          final sourceX = cell * 5 + 12;
          final height = math.max(cell * 2,
                  ((step.b + _sourceColumns - 1) ~/ _sourceColumns) * cell) +
              6;
          // The remainder question starts from the same completed ten-frame
          // as its explanation. Keep all a + b apples; only their positions
          // change, so the child can actually count the remaining group.
          final animate = step.type == TutoringStepType.showExample ||
              step.answerKind == GuidedAnswerKind.remainder;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${step.a} + ${step.b}',
                  style: _text.copyWith(fontSize: 26),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Semantics(
                label: '${step.a} Äpfel und ${step.b} weitere Äpfel',
                excludeSemantics: true,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: animate ? 1 : 0),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1600),
                  curve: Curves.easeInOutCubic,
                  builder: (context, fraction, _) => SizedBox(
                    height: height,
                    child: Stack(children: [
                      for (var i = 0; i < 10; i++)
                        Positioned(
                          left: (i % 5) * cell,
                          top: (i ~/ 5) * cell,
                          width: cell - 3,
                          height: cell - 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF103966),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: LumoVisualTokens.cyan
                                      .withValues(alpha: .55)),
                            ),
                          ),
                        ),
                      for (var i = 0; i < step.a + step.b; i++)
                        _apple(i, cell, sourceX, fraction),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                  step.type == TutoringStepType.showExample
                      ? '${step.a} + ${10 - step.a} = 10. '
                          '10 + ${step.a + step.b - 10} = ${step.a + step.b}.'
                      : step.answerKind == GuidedAnswerKind.remainder
                          ? 'Der Zehner ist voll. Zähle die Äpfel daneben.'
                          : 'Erst den Zehner füllen, dann weiterzählen.',
                  style: _text),
            ],
          );
        }),
      );

  Widget _apple(int index, double cell, double sourceX, double fraction) {
    final gap = 10 - step.a;
    final next = index - step.a;
    final initial = index < step.a
        ? Offset((index % 5) * cell, (index ~/ 5) * cell)
        : Offset(sourceX + (next % _sourceColumns) * cell,
            (next ~/ _sourceColumns) * cell);
    final destination = index < 10
        ? Offset((index % 5) * cell, (index ~/ 5) * cell)
        : Offset(sourceX + ((next - gap) % _sourceColumns) * cell,
            ((next - gap) ~/ _sourceColumns) * cell);
    final position = Offset.lerp(initial, destination, fraction)!;
    return Positioned(
      key: ValueKey('guided-bridge-apple-$index'),
      left: position.dx,
      top: position.dy,
      width: cell - 3,
      height: cell - 3,
      child: LumoQuantityArt.apple(size: cell - 3),
    );
  }
}
