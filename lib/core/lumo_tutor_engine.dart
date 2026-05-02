import 'lumo_tutor_contracts.dart';

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
        speech: 'Ich schaue mir nach dem Test an, was schon gut klappt und was wir noch üben.',
        shortHint: 'Auswertung nach dem Test',
        explanation: 'Während Tests gibt Lumo keine Lösungshilfe. Danach wird gezielt geübt.',
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
    }
  }

  LumoTutorVisualPlan suggestVisualPlan(LumoTutorRequest request) {
    if (request.subject == LumoTutorSubject.mathematik) {
      final expression = '${request.currentPrompt ?? ''} ${request.correctAnswer ?? ''}';
      final numbers = RegExp(r'\d+')
          .allMatches(expression)
          .map((match) => int.tryParse(match.group(0) ?? ''))
          .whereType<int>()
          .toList();
      final prompt = request.currentPrompt ?? '';
      if (numbers.length >= 2 && numbers.take(2).every((number) => number >= 0 && number <= 10)) {
        if (prompt.contains('-')) {
          return LumoTutorVisualPlan(
            type: LumoTutorVisualType.apples,
            left: numbers[0],
            remove: numbers[1],
            result: numbers.length >= 3 ? numbers[2] : null,
          );
        }
        return LumoTutorVisualPlan(
          type: LumoTutorVisualType.tenFrame,
          left: numbers[0],
          right: numbers[1],
          result: numbers.length >= 3 ? numbers[2] : null,
        );
      }
      return const LumoTutorVisualPlan(type: LumoTutorVisualType.numberLine);
    }

    if (request.subject == LumoTutorSubject.deutsch) {
      final unit = request.unit.toLowerCase();
      if (unit.contains('silb')) {
        return LumoTutorVisualPlan(
          type: LumoTutorVisualType.syllableChips,
          word: request.correctAnswer,
        );
      }
      if (unit.contains('satz')) {
        return const LumoTutorVisualPlan(type: LumoTutorVisualType.sentenceBuilder);
      }
      if (unit.contains('laut')) {
        return LumoTutorVisualPlan(
          type: LumoTutorVisualType.soundHighlight,
          word: request.correctAnswer,
          highlight: unit.contains('end') ? 'end' : 'start',
        );
      }
      return const LumoTutorVisualPlan(type: LumoTutorVisualType.wordCards);
    }

    return const LumoTutorVisualPlan.none();
  }

  LumoTutorResponse _mathFallback(LumoTutorRequest request) {
    final visual = suggestVisualPlan(request);
    if (request.helpLevel == LumoTutorHelpLevel.hintOnly) {
      return LumoTutorResponse(
        speech: 'Schau zuerst auf die Mengen. Wird es mehr oder weniger?',
        shortHint: 'Mehr oder weniger?',
        visualPlan: visual,
        source: 'local_tutor_engine_v1',
      );
    }
    if (request.helpLevel == LumoTutorHelpLevel.guidedStep) {
      return LumoTutorResponse(
        speech: 'Wir machen es Schritt für Schritt. Suche zuerst die erste Zahl und dann die zweite Zahl.',
        shortHint: 'Erst die Zahlen finden.',
        explanation: 'Bei Plus kommt etwas dazu. Bei Minus geht etwas weg.',
        visualPlan: visual,
        source: 'local_tutor_engine_v1',
      );
    }
    return LumoTutorResponse(
      speech: 'Ich zeige es dir mit einem Bild. Dann probieren wir gleich eine ähnliche Aufgabe.',
      shortHint: 'Bild anschauen.',
      explanation: 'Lumo Nachhilfe+ erklärt schwierige Rechnungen mit Mengen, Zehnerfeld oder Zahlenstrahl.',
      visualPlan: visual,
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _germanFallback(LumoTutorRequest request) {
    final visual = suggestVisualPlan(request);
    final unit = request.unit.toLowerCase();
    final speech = unit.contains('nomen') || unit.contains('namenswort')
        ? 'Ein Namenswort ist etwas, das einen Namen hat. Oft passt der, die oder das davor.'
        : unit.contains('verb') || unit.contains('tunwort')
            ? 'Ein Tunwort sagt, was jemand macht. Zum Beispiel laufen, malen oder lesen.'
            : unit.contains('silb')
                ? 'Wir klatschen das Wort langsam in Silben.'
                : 'Wir schauen das Wort ganz genau an.';
    return LumoTutorResponse(
      speech: speech,
      shortHint: request.helpLevel == LumoTutorHelpLevel.hintOnly ? 'Schau auf die Wortart.' : null,
      explanation: speech,
      visualPlan: visual,
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _readingFallback(LumoTutorRequest request) {
    return const LumoTutorResponse(
      speech: 'Lies langsam. Wenn ein Wort schwer ist, teilen wir es in kleine Teile.',
      shortHint: 'Langsam lesen.',
      explanation: 'Lumo kann schwierige Wörter in Silben teilen und danach noch einmal üben lassen.',
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _scienceFallback(LumoTutorRequest request) {
    return const LumoTutorResponse(
      speech: 'Wir denken wie kleine Forscher. Was siehst du? Was passt zur Natur?',
      shortHint: 'Genau beobachten.',
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _englishFallback(LumoTutorRequest request) {
    return const LumoTutorResponse(
      speech: 'Wir üben das englische Wort langsam und mit einem einfachen Beispiel.',
      shortHint: 'Langsam nachsprechen.',
      source: 'local_tutor_engine_v1',
    );
  }
}
