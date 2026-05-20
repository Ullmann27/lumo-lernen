// ════════════════════════════════════════════════════════════════════════
//                  SCHREIBCOACH - FEEDBACK ENGINE
// ════════════════════════════════════════════════════════════════════════
//
// Wandelt ein Analyse-Ergebnis in eine freundliche Lumo-Botschaft um.
// Niemals beschaemen. Immer mit Hoffnung.

import 'dart:math' as math;

import '../models/coach_writing_models.dart';

class WritingFeedbackEngine {
  WritingFeedbackEngine({math.Random? rng}) : _rng = rng ?? math.Random();

  final math.Random _rng;

  CoachWritingFeedback feedbackFor(CoachLetterAnalysisResult result) {
    final letter = result.expectedLetter;
    if (result.isCorrect) {
      return CoachWritingFeedback(
        message: _pick(_correctPool),
        allowRetry: false,
        showDemo: false,
        lumoEmotion: CoachLumoEmotion.cheer,
        isCorrect: true,
        messageKey: 'correct',
      );
    }
    // Priorisierte Issue-Behandlung: Reihenfolge bestimmt welche
    // Botschaft gewinnt.
    final issues = result.issues;
    if (issues.contains(CoachLetterIssue.missingCrossbar)) {
      return CoachWritingFeedback(
        message: _crossbarMessage(letter),
        allowRetry: true,
        showDemo: result.showDemo,
        lumoEmotion: CoachLumoEmotion.point,
        messageKey: 'missingCrossbar',
      );
    }
    if (issues.contains(CoachLetterIssue.notClosed)) {
      return CoachWritingFeedback(
        message: _notClosedMessage(letter),
        allowRetry: true,
        showDemo: result.showDemo,
        lumoEmotion: CoachLumoEmotion.point,
        messageKey: 'notClosed',
      );
    }
    if (issues.contains(CoachLetterIssue.missingStroke)) {
      return CoachWritingFeedback(
        message: _missingStrokeMessage(letter),
        allowRetry: true,
        showDemo: result.showDemo,
        lumoEmotion: CoachLumoEmotion.point,
        messageKey: 'missingStroke',
      );
    }
    if (issues.contains(CoachLetterIssue.tooSmall)) {
      return CoachWritingFeedback(
        message: 'Schreib den Buchstaben ein bisschen groesser auf die Linie.',
        allowRetry: true,
        showDemo: false,
        lumoEmotion: CoachLumoEmotion.comfort,
        messageKey: 'tooSmall',
      );
    }
    if (issues.contains(CoachLetterIssue.tooLarge)) {
      return CoachWritingFeedback(
        message: 'Probier es etwas kleiner, dann passt es genau auf die Linie.',
        allowRetry: true,
        showDemo: false,
        lumoEmotion: CoachLumoEmotion.comfort,
        messageKey: 'tooLarge',
      );
    }
    if (issues.contains(CoachLetterIssue.offLine)) {
      return CoachWritingFeedback(
        message: 'Bleib mit dem Buchstaben schoen auf der Linie.',
        allowRetry: true,
        showDemo: false,
        lumoEmotion: CoachLumoEmotion.comfort,
        messageKey: 'offLine',
      );
    }
    if (issues.contains(CoachLetterIssue.mirrored)) {
      return CoachWritingFeedback(
        message: 'Fast! Probier den Buchstaben gespiegelt - so wie ich.',
        allowRetry: true,
        showDemo: result.showDemo,
        lumoEmotion: CoachLumoEmotion.think,
        messageKey: 'mirrored',
      );
    }
    if (issues.contains(CoachLetterIssue.wrongLetter)) {
      return CoachWritingFeedback(
        message:
            'Hier brauchen wir ein $letter. Ich zeige dir, wie das geht.',
        allowRetry: true,
        showDemo: true,
        lumoEmotion: CoachLumoEmotion.point,
        messageKey: 'wrongLetter',
      );
    }
    // Default: unclear
    return CoachWritingFeedback(
      message: _pick(_unclearPool),
      allowRetry: true,
      showDemo: result.showDemo,
      lumoEmotion: CoachLumoEmotion.think,
      messageKey: 'unclear',
    );
  }

  String _crossbarMessage(String letter) {
    if (letter == 'H') {
      return 'Fast! Beim H fehlt noch die Bruecke in der Mitte.';
    }
    if (letter == 'A') {
      return 'Fast! Beim A fehlt noch der Querstrich.';
    }
    return 'Fast! Da fehlt noch ein kleiner Querstrich.';
  }

  String _notClosedMessage(String letter) {
    if (letter == 'O') {
      return 'Das O ist fast rund. Mach den Kreis noch zu.';
    }
    return 'Fast! Schliess die Form noch ein bisschen.';
  }

  String _missingStrokeMessage(String letter) {
    if (letter == 'L') {
      return 'Fast! Beim L brauchen wir noch den Fuss unten.';
    }
    if (letter == 'H') {
      return 'Fast! Beim H brauchen wir zwei Striche und eine Bruecke.';
    }
    return 'Fast! Es fehlt noch ein Strich.';
  }

  String _pick(List<String> pool) {
    if (pool.isEmpty) return 'Schau noch mal.';
    return pool[_rng.nextInt(pool.length)];
  }

  static const List<String> _correctPool = <String>[
    'Super! Das sieht gut aus.',
    'Klasse! Genau so.',
    'Wow, das ist toll geschrieben!',
    'Sehr schoen! Weiter so.',
  ];

  static const List<String> _unclearPool = <String>[
    'Fast! Probier es noch einmal.',
    'Schau noch mal genau hin, dann klappt es.',
    'Wir versuchen das gemeinsam.',
    'Probier es noch einmal, ich helfe dir.',
  ];
}
