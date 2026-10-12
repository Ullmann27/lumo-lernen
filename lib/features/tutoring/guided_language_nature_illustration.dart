import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/tutoring/guided_lesson_catalog.dart';
import '../../domain/tutoring/tutoring_session_planner.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';

/// A demonstrated word may be segmented; a new question never displays its
/// syllable count or the name of the highlighted plant part.
class GuidedLanguageNatureIllustration extends StatelessWidget {
  const GuidedLanguageNatureIllustration(
      {super.key,
      required this.lesson,
      required this.step,
      required this.reduceMotion});
  final GuidedLesson lesson;
  final GuidedLessonStep step;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final example =
        step.type == TutoringStepType.showExample || !step.isQuestion;
    if (lesson.concept == GuidedLessonConcept.syllables) {
      return LumoLessonSurface(
          child: Column(children: [
        if (step.word.isEmpty)
          const Icon(Icons.hearing_rounded,
              color: LumoVisualTokens.gold, size: 48)
        else if (!example)
          Text(step.word,
              key: const ValueKey('guided-unsegmented-word'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w900))
        else
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < step.syllables.length; i++)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('guided-spoken-syllable-$i'),
                    tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                    duration: Duration(
                        milliseconds: reduceMotion ? 0 : 450 + i * 350),
                    builder: (context, value, child) => Transform.scale(
                        scale: .9 + .1 * value,
                        child: Opacity(opacity: .4 + .6 * value, child: child)),
                    child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFF124A88),
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: LumoVisualTokens.cyanBright)),
                        child: Text(step.syllables[i],
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w900))),
                  ),
              ]),
        const SizedBox(height: 12),
        const Text('Sprich langsam. Klatsche bei jedem Sprechstück.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontSize: 16,
                height: 1.4)),
      ]));
    }
    return LumoLessonSurface(
        child: Column(children: [
      Semantics(
          label: step.plantPart == null
              ? 'Eine Blütenpflanze mit Teilen über und unter der Erde.'
              : 'Eine Blütenpflanze. Hervorgehoben ist ${switch (step.plantPart!) {
                  GuidedPlantPart.root => 'der verzweigte Teil unter der Erde',
                  GuidedPlantPart.stem =>
                    'die senkrechte Verbindung zwischen den Pflanzenteilen',
                  GuidedPlantPart.leaf => 'die seitliche grüne Fläche',
                  GuidedPlantPart.flower => 'der bunte Teil oben',
                }}.',
          excludeSemantics: true,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
            duration: Duration(milliseconds: reduceMotion ? 0 : 700),
            builder: (context, value, _) => SizedBox(
                height: 230,
                width: 280,
                child: CustomPaint(
                    key: const ValueKey('guided-flowering-plant'),
                    painter: GuidedFlowerPainter(
                        target: step.plantPart,
                        variant: step.plantVariant,
                        highlight: .55 + .45 * value))),
          )),
      if (example && step.plantPart != null) ...[
        const SizedBox(height: 8),
        Text(step.plantPart!.label,
            key: const ValueKey('guided-demonstrated-part'),
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                color: LumoVisualTokens.gold,
                fontWeight: FontWeight.w900)),
      ],
    ]));
  }
}

/// Editable original vector diagram used by the actual lesson runtime.
class GuidedFlowerPainter extends CustomPainter {
  const GuidedFlowerPainter(
      {required this.target, required this.variant, required this.highlight});
  final GuidedPlantPart? target;
  final int variant;
  final double highlight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 230);
    final soil = Paint()..color = const Color(0xFF4A3440);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 170, 256, 55), const Radius.circular(12)),
        soil);
    Paint part(GuidedPlantPart part, Color color, {double width = 5}) => Paint()
      ..color = target == part
          ? Color.lerp(color, LumoVisualTokens.gold, highlight)!
          : color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final root = part(GuidedPlantPart.root, const Color(0xFFDCA889));
    for (final x in [105.0, 125.0, 145.0, 169.0]) {
      canvas.drawLine(const Offset(140, 171), Offset(x, 216), root);
    }
    canvas.drawLine(const Offset(140, 185), const Offset(93, 192), root);
    canvas.drawLine(const Offset(140, 191), const Offset(179, 203), root);
    final stem = part(GuidedPlantPart.stem, const Color(0xFF50BA79), width: 9);
    canvas.drawLine(const Offset(140, 174), const Offset(140, 55), stem);
    final leaf = part(GuidedPlantPart.leaf, const Color(0xFF43BA77));
    final left = Path()
      ..moveTo(140, 137)
      ..quadraticBezierTo(72, 142, 60, variant == 0 ? 97 : 85)
      ..quadraticBezierTo(123, 84, 140, 137)
      ..close();
    final right = Path()
      ..moveTo(140, 115)
      ..quadraticBezierTo(181, 69, 226, 91)
      ..quadraticBezierTo(203, 135, 140, 115)
      ..close();
    canvas.drawPath(left, leaf);
    canvas.drawPath(right, leaf);
    final petals = part(GuidedPlantPart.flower,
        variant == 0 ? const Color(0xFFFF83B5) : const Color(0xFFA999FF));
    final count = variant == 0 ? 6 : 8;
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count;
      canvas.drawCircle(
          Offset(140 + math.cos(angle) * 24, 46 + math.sin(angle) * 24),
          17,
          petals);
    }
    canvas.drawCircle(
        const Offset(140, 46), 16, Paint()..color = const Color(0xFFFFD96B));
    canvas.restore();
  }

  @override
  bool shouldRepaint(GuidedFlowerPainter old) =>
      old.target != target ||
      old.variant != variant ||
      old.highlight != highlight;
}
