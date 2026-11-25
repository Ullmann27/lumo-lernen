import 'lumo_tutor_contracts.dart';
import '../domain/learning/whole_arithmetic.dart';
import '../domain/learning/error_detective.dart';
import 'primary_school_word_data.dart';
import 'school_exercise_generator.dart';
import 'task_hint_service.dart';

/// Lokale Entscheidungslogik für Lumo Nachhilfe+.
///
/// V1 ist bewusst offline und risikolos:
/// - keine Proxy-Calls
/// - keine Änderung an der funktionierenden KI-Verbindung
/// - keine UI-Abhängigkeit
/// - keine Store-/Abo-Abhängigkeit
///
/// Diese Engine entscheidet nur, welche Hilfestufe pädagogisch sinnvoll ist
/// und welche lokale Visualisierung später gerendert werden kann.
class LumoTutorEngine {
  const LumoTutorEngine();

  LumoTutorHelpLevel decideHelpLevel({
    required int attemptCount,
    required bool hasRepeatedWeakness,
    required bool premiumEnabled,
  }) {
    if (!premiumEnabled) return LumoTutorHelpLevel.hintOnly;
    if (attemptCount >= 3 || hasRepeatedWeakness) {
      return LumoTutorHelpLevel.visualExplanation;
    }
    if (attemptCount == 2) return LumoTutorHelpLevel.guidedStep;
    return LumoTutorHelpLevel.hintOnly;
  }

  LumoTutorMode decideMode({
    required int attemptCount,
    required bool hasRepeatedWeakness,
    required bool isTestReview,
  }) {
    if (isTestReview) return LumoTutorMode.testReview;
    if (attemptCount >= 3 || hasRepeatedWeakness) {
      return LumoTutorMode.miniLesson;
    }
    if (attemptCount == 2) return LumoTutorMode.mistakeExplanation;
    return LumoTutorMode.practiceHint;
  }

  LumoTutorResponse buildLocalFallback(LumoTutorRequest request) {
    if (request.isTestLike) {
      return const LumoTutorResponse(
        speech:
            'Ich schaue mir nach dem Test an, was schon gut klappt und was wir noch üben.',
        shortHint: 'Auswertung nach dem Test',
        explanation:
            'Während Tests gibt Lumo keine Lösungshilfe. Danach wird gezielt geübt.',
        source: 'local_tutor_engine_v1',
      );
    }

    switch (request.subject) {
      case LumoTutorSubject.mathematik:
        return _mathFallback(request);
      case LumoTutorSubject.deutsch:
        return _germanFallback(request);
      case LumoTutorSubject.lesen:
        return _readingFallback(request);
      case LumoTutorSubject.sachunterricht:
        return _scienceFallback(request);
      case LumoTutorSubject.englisch:
        return _englishFallback(request);
      case LumoTutorSubject.logik:
        return _contextualFallback(request, 'Logik');
    }
  }

  LumoTutorVisualPlan suggestVisualPlan(LumoTutorRequest request) {
    if (request.isTestLike) return const LumoTutorVisualPlan.none();
    if (request.subject == LumoTutorSubject.mathematik) {
      final calculation = WholeArithmetic.parse(request.currentPrompt ?? '',
          expected: request.correctAnswer);
      if (calculation == null || !calculation.isAddOrSubtract ||
          calculation.result < 0) {
        return const LumoTutorVisualPlan.none();
      }
      final left = calculation.left;
      final right = calculation.right;
      if (left > 10 || right > 10) {
        return const LumoTutorVisualPlan(type: LumoTutorVisualType.numberLine);
      }
      if (calculation.operation == WholeOperation.subtraction) {
        return LumoTutorVisualPlan(
          type: LumoTutorVisualType.apples,
          left: left,
          remove: right,
        );
      }
      return LumoTutorVisualPlan(
        type: LumoTutorVisualType.tenFrame,
        left: left,
        right: right,
      );
    }

    if (request.subject == LumoTutorSubject.deutsch) {
      final unit = request.unit.toLowerCase();
      if (unit.contains('silb')) {
        // Displaying every syllable also reveals the count. A first hint must
        // leave that discovery to the child.
        if (request.shouldAvoidDirectSolution) {
          return const LumoTutorVisualPlan.none();
        }
        final word = RegExp(r'Silben\s+hat\s+([A-Za-zÄÖÜäöüß]+)', caseSensitive: false)
            .firstMatch(request.currentPrompt ?? '')?.group(1);
        if (word == null) return const LumoTutorVisualPlan.none();
        final parts = PrimarySchoolWordData.syllablesFor(word);
        if (parts == null || parts.isEmpty) {
          return const LumoTutorVisualPlan.none();
        }
        return LumoTutorVisualPlan(
          type: LumoTutorVisualType.syllableChips,
          word: word,
          parts: parts,
        );
      }
      if (unit.contains('satz')) {
        return const LumoTutorVisualPlan(
            type: LumoTutorVisualType.sentenceBuilder);
      }
      if (unit.contains('laut')) {
        final word = RegExp(r'Laut\s+(?:beginnt|endet)\s+([A-Za-zÄÖÜäöüß]+)', caseSensitive: false)
            .firstMatch(request.currentPrompt ?? '')?.group(1);
        if (word == null) return const LumoTutorVisualPlan.none();
        return LumoTutorVisualPlan(
          type: LumoTutorVisualType.soundHighlight,
          word: word,
          highlight: unit.contains('end') ? 'end' : 'start',
        );
      }
      return const LumoTutorVisualPlan(type: LumoTutorVisualType.wordCards);
    }

    return const LumoTutorVisualPlan.none();
  }

  LumoTutorResponse _mathFallback(LumoTutorRequest request) {
    final fallback = _contextualFallback(request, 'Mathematik');
    // Actual task-bound wrong answer only, and only during requested help.
    if (request.mode != LumoTutorMode.mistakeExplanation ||
        request.attemptCount < 1 ||
        request.helpLevel == LumoTutorHelpLevel.hintOnly) {
      return fallback;
    }
    final calculation = WholeArithmetic.parse(request.currentPrompt ?? '',
        expected: request.correctAnswer);
    final given = WholeArithmetic.integerAnswer(request.childAnswer);
    if (calculation == null ||
        request.correctAnswer == null ||
        given == null ||
        given == calculation.result) {
      return fallback;
    }
    final detection = const ErrorDetective().analyze(
      subject: 'Mathematik',
      prompt: request.currentPrompt ?? '',
      correctAnswer: request.correctAnswer!,
      givenAnswer: request.childAnswer!,
    );
    if (!detection.isRecognised) return fallback;
    final text = detection.childFriendlyMessage;
    return LumoTutorResponse(
      speech: text,
      shortHint: text,
      explanation: text,
      visualPlan: fallback.visualPlan,
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _contextualFallback(
      LumoTutorRequest request, String subject) {
    final visual = suggestVisualPlan(request);
    final text = const TaskHintService().explain(
        LumoTask(
          id: 'local-tutor',
          grade: request.grade,
          subject: subject,
          unit: request.unit,
          prompt: request.currentPrompt ?? '',
          answer: request.correctAnswer ?? '',
          choices: const [],
          explanation: '',
        ),
        level: request.helpLevel.index + 1);
    return LumoTutorResponse(
      speech: text,
      shortHint: text,
      explanation: text,
      visualPlan: visual,
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _germanFallback(LumoTutorRequest request) =>
      _contextualFallback(request, 'Deutsch');

  LumoTutorResponse _readingFallback(LumoTutorRequest request) {
    // Picture/word tasks contain no passage to search. Their existing units
    // need decoding and meaning checks instead of an unrelated text instruction.
    final stage = request.helpLevel.index.clamp(0, 2).toInt();
    final String text;
    if (request.unit == 'Bild und Wort') {
      text = const [
        'Schau dir das Bild in Ruhe an. Lies jedes angebotene Wort langsam und vergleiche es mit dem Bild.',
        'Beschreibe, was du auf dem Bild siehst. Sprich dann jedes Wort in kleinen Teilen und setze die Teile wieder zusammen.',
        'Prüfe jedes Wort einzeln: Passt seine Bedeutung zum Bild? Achte auch auf die Buchstaben in der Mitte und am Ende.',
      ][stage];
    } else if (request.unit == 'Woerter lesen') {
      text = const [
        'Lies die Beschreibung langsam. Lies danach jedes angebotene Wort ganz und prüfe seine Bedeutung.',
        'Teile ein schwieriges Wort in kleine Sprechstücke. Setze sie wieder zusammen und vergleiche das Wort mit der Beschreibung.',
        'Ähnliche Wörter können etwas anderes bedeuten. Vergleiche Buchstabe für Buchstabe und prüfe jedes Wort an der Beschreibung.',
      ][stage];
    } else {
      return _contextualFallback(request, 'Lesen');
    }
    return LumoTutorResponse(
      speech: text,
      shortHint: text,
      explanation: text,
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _scienceFallback(LumoTutorRequest request) {
    return const LumoTutorResponse(
      speech:
          'Wir denken wie kleine Forscher. Was siehst du? Was passt zur Natur?',
      shortHint: 'Genau beobachten.',
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _englishFallback(LumoTutorRequest request) {
    return const LumoTutorResponse(
      speech:
          'Wir üben das englische Wort langsam und mit einem einfachen Beispiel.',
      shortHint: 'Langsam nachsprechen.',
      source: 'local_tutor_engine_v1',
    );
  }
}
