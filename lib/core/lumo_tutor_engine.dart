import 'lumo_tutor_contracts.dart';
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
    if (request.subject == LumoTutorSubject.mathematik) {
      final prompt = request.currentPrompt ?? '';
      final calculation =
          RegExp(r'(\d+)\s*([+−\-])\s*(\d+)\s*=').firstMatch(prompt);
      if (calculation != null) {
        final left = int.parse(calculation.group(1)!);
        final right = int.parse(calculation.group(3)!);
        if (left > 10 || right > 10) {
          return const LumoTutorVisualPlan(
              type: LumoTutorVisualType.numberLine);
        }
        if (calculation.group(2) != '+') {
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
      return const LumoTutorVisualPlan.none();
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
        return const LumoTutorVisualPlan(
            type: LumoTutorVisualType.sentenceBuilder);
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
    return _contextualFallback(request, 'Mathematik');
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
      shortHint: request.helpLevel == LumoTutorHelpLevel.hintOnly
          ? 'Schau auf die Wortart.'
          : null,
      explanation: speech,
      visualPlan: visual,
      source: 'local_tutor_engine_v1',
    );
  }

  LumoTutorResponse _readingFallback(LumoTutorRequest request) {
    return const LumoTutorResponse(
      speech:
          'Lies langsam. Wenn ein Wort schwer ist, teilen wir es in kleine Teile.',
      shortHint: 'Langsam lesen.',
      explanation:
          'Lumo kann schwierige Wörter in Silben teilen und danach noch einmal üben lassen.',
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
