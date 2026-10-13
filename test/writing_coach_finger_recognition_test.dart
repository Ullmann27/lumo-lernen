import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/writing/writing_engine.dart';

WritingStroke stroke(List<Offset> points) => WritingStroke(points);

void main() {
  test('finger-written H in one continuous stroke is recognized', () {
    final template = LetterTemplates.all['H']!;
    final fingerH = <WritingStroke>[
      stroke(const [
        Offset(20, 10),
        Offset(20, 90),
        Offset(20, 50),
        Offset(80, 50),
        Offset(80, 10),
        Offset(80, 90),
      ]),
    ];

    final strict = LetterShapeAnalyzer.analyze(
      userStrokes: fingerH,
      template: template,
    );
    expect(strict.matched, isFalse,
        reason: 'Die Schulschrift-Vorlage erwartet mehrere Striche.');

    final feedback = WritingFeedbackEngine.generate(
      template: template,
      userStrokes: fingerH,
    );
    expect(feedback.matched, isTrue);
    expect(feedback.showDemo, isFalse);
  });

  test('one straight stroke cannot pass as an H', () {
    final template = LetterTemplates.all['H']!;
    for (final line in <List<Offset>>[
      const [Offset(20, 50), Offset(80, 50)],
      const [Offset(50, 10), Offset(50, 90)],
    ]) {
      final feedback = WritingFeedbackEngine.generate(
        template: template,
        userStrokes: [stroke(line)],
      );
      expect(feedback.matched, isFalse, reason: 'A straight line is not H');
    }
  });

  test('wobbly finger C and S remain acceptable handwriting', () {
    final samples = <String, List<Offset>>{
      'C': const [
        Offset(78, 24),
        Offset(52, 10),
        Offset(24, 22),
        Offset(12, 48),
        Offset(18, 75),
        Offset(45, 94),
        Offset(78, 80),
      ],
      'S': const [
        Offset(80, 18),
        Offset(58, 8),
        Offset(30, 16),
        Offset(20, 34),
        Offset(42, 48),
        Offset(68, 55),
        Offset(76, 72),
        Offset(60, 91),
        Offset(28, 82),
      ],
    };

    for (final entry in samples.entries) {
      final feedback = WritingFeedbackEngine.generate(
        template: LetterTemplates.all[entry.key]!,
        userStrokes: [stroke(entry.value)],
      );
      expect(feedback.matched, isTrue, reason: entry.key);
    }
  });

  test('a closed O is not accepted as C just because both are curved', () {
    final feedback = WritingFeedbackEngine.generate(
      template: LetterTemplates.all['C']!,
      userStrokes: [
        stroke(LetterTemplates.all['O']!.demoStrokes.single),
      ],
    );
    expect(feedback.matched, isFalse);
  });
}
