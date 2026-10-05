import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/writing/writing_engine.dart';

/// Schreibcoach: Lumos eigene Vorzeige-Striche gelten als richtig, auch etwas
/// verwackelt, schräg oder schmaler; ein anderer Buchstabe meist nicht.
List<WritingStroke> _drawn(
  LetterTemplate template, {
  int dropLast = 0,
  math.Random? wobble,
  double slant = 0,
  double width = 1,
}) {
  double jitter() => wobble == null ? 0 : (wobble.nextDouble() - 0.5) * 25;
  final strokes = [
    for (final stroke in template.demoStrokes)
      WritingStroke([
        for (final p in stroke)
          Offset((p.dx + slant * (50 - p.dy)) * 3 * width + jitter(), p.dy * 3 + jitter()),
      ]),
  ];
  return strokes.sublist(0, strokes.length - dropLast);
}

bool _accepted(LetterTemplate template, List<WritingStroke> strokes) =>
    WritingFeedbackEngine.generate(template: template, userStrokes: strokes).matched;

void main() {
  const all = LetterTemplates.all;

  test('Ä, Ö, Ü und ß haben Vorlagen', () {
    for (final letter in ['Ä', 'Ö', 'Ü', 'ß']) {
      expect(all[letter], isNotNull, reason: letter);
    }
  });

  test('alle Vorzeige-Striche werden als richtig erkannt', () {
    final rejected = [
      for (final e in all.entries)
        if (!_accepted(e.value, _drawn(e.value))) e.key,
    ];
    expect(rejected, isEmpty);
  });

  test('verwackelt, schräg oder schmaler geschrieben gilt meist noch', () {
    final wobble = math.Random(3);
    var tries = 0;
    var rejected = 0;
    for (final template in all.values) {
      for (var r = 0; r < 6; r++) {
        tries++;
        final strokes = _drawn(template, wobble: wobble, slant: (r - 3) * 0.08, width: 0.8 + r * 0.08);
        if (!_accepted(template, strokes)) rejected++;
      }
    }
    expect(rejected / tries, lessThan(0.03), reason: '$rejected von $tries abgelehnt');
  });

  test('ein anderer Buchstabe wird meist nicht angenommen', () {
    var pairs = 0;
    var accepted = 0;
    for (final wanted in all.entries) {
      for (final written in all.entries) {
        if (written.key.toLowerCase() == wanted.key.toLowerCase()) continue;
        pairs++;
        if (_accepted(wanted.value, _drawn(written.value))) accepted++;
      }
    }
    expect(accepted / pairs, lessThan(0.15), reason: '$accepted von $pairs angenommen');
  });

  test('O statt L und Ä ohne Punkte reichen nicht', () {
    expect(_accepted(all['L']!, _drawn(all['O']!)), isFalse);
    expect(_accepted(all['Ä']!, _drawn(all['Ä']!, dropLast: 2)), isFalse);
  });
}
