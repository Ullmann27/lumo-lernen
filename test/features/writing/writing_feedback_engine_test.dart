// Tests fuer WritingFeedbackEngine.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/writing/logic/writing_feedback_engine.dart';
import 'package:lumo_lernen/features/writing/models/coach_writing_models.dart';

CoachLetterAnalysisResult _result({
  required String letter,
  bool isCorrect = false,
  List<CoachLetterIssue> issues = const [],
  String key = 'unclear',
  bool showDemo = false,
}) {
  return CoachLetterAnalysisResult(
    expectedLetter: letter,
    recognizedLetter: isCorrect ? letter : '?',
    isCorrect: isCorrect,
    confidence: isCorrect ? 0.9 : 0.4,
    shapeScore: isCorrect ? 0.9 : 0.4,
    lineScore: 1.0,
    sizeScore: 1.0,
    issues: issues,
    showDemo: showDemo,
    messageKey: key,
  );
}

void main() {
  group('WritingFeedbackEngine', () {
    test('Korrektes Ergebnis -> cheer-Emotion, kein Retry', () {
      final engine = WritingFeedbackEngine(rng: math.Random(1));
      final fb = engine.feedbackFor(_result(letter: 'I', isCorrect: true));
      expect(fb.isCorrect, isTrue);
      expect(fb.lumoEmotion, CoachLumoEmotion.cheer);
      expect(fb.allowRetry, isFalse);
      expect(fb.showDemo, isFalse);
      expect(fb.message.isNotEmpty, isTrue);
    });

    test('missingCrossbar bei H -> Hinweis auf die Bruecke', () {
      final engine = WritingFeedbackEngine(rng: math.Random(1));
      final fb = engine.feedbackFor(_result(
        letter: 'H',
        issues: const [CoachLetterIssue.missingCrossbar],
        key: 'missingCrossbar',
      ));
      expect(fb.isCorrect, isFalse);
      expect(fb.message.toLowerCase(), contains('bruecke'));
      expect(fb.allowRetry, isTrue);
      expect(fb.messageKey, 'missingCrossbar');
    });

    test('notClosed bei O -> Hinweis Kreis schliessen', () {
      final engine = WritingFeedbackEngine(rng: math.Random(1));
      final fb = engine.feedbackFor(_result(
        letter: 'O',
        issues: const [CoachLetterIssue.notClosed],
        key: 'notClosed',
      ));
      expect(fb.message.toLowerCase(), contains('rund'));
      expect(fb.messageKey, 'notClosed');
    });

    test('Feedback enthaelt nie verbotene Woerter', () {
      final engine = WritingFeedbackEngine(rng: math.Random(1));
      const verbotenWords = ['falsch', 'schlecht', 'kannst das nicht'];
      // Mehrere Versuche, alle Pools abdecken.
      for (var i = 0; i < 30; i++) {
        final fb = engine.feedbackFor(_result(
          letter: 'I',
          isCorrect: i.isEven,
          issues: i.isEven
              ? const []
              : const [CoachLetterIssue.unclear],
        ));
        final lower = fb.message.toLowerCase();
        for (final w in verbotenWords) {
          expect(lower.contains(w), isFalse,
              reason:
                  'Feedback enthaelt verbotenes Wort "$w": ${fb.message}');
        }
      }
    });
  });
}
