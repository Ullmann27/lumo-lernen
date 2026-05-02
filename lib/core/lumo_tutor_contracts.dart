/// Domain-Verträge für Lumo Nachhilfe+.
///
/// Diese Datei ist bewusst isoliert: keine Proxy-Calls, keine UI, keine
/// Subscription-Zahlungslogik. Sie definiert nur die stabile Sprache, mit der
/// die App künftig Nachhilfe-Anfragen, Hinweise, Erklärungen und sichere
/// Visualisierungen beschreiben kann.
///
/// Wichtige Produktregel:
/// Lumo Nachhilfe+ ist kein offener Chat. Die KI wird nur über kontrollierte
/// Tutor-Modi, Kindersicherheitsfilter und lokal gerenderte Visual-Pläne
/// eingesetzt.

enum LumoTutorMode {
  practiceHint,
  mistakeExplanation,
  miniLesson,
  weaknessPlan,
  testReview,
  voiceTutor,
}

enum LumoTutorSubject {
  mathematik,
  deutsch,
  lesen,
  sachunterricht,
  englisch,
}

enum LumoTutorHelpLevel {
  /// Kleiner Denkanstoß, keine Lösung.
  hintOnly,

  /// Ein geführter Zwischenschritt.
  guidedStep,

  /// Bildliche Erklärung mit lokal gerendertem Visual.
  visualExplanation,

  /// Vollständige kurze Erklärung mit passender Folgeaufgabe.
  fullMiniLesson,
}

enum LumoTutorVisualType {
  none,
  quantityDots,
  apples,
  tenFrame,
  numberLine,
  wordCards,
  syllableChips,
  soundHighlight,
  sentenceBuilder,
}

class LumoTutorRequest {
  const LumoTutorRequest({
    required this.mode,
    required this.subject,
    required this.grade,
    required this.unit,
    required this.helpLevel,
    this.childFirstName,
    this.currentPrompt,
    this.childAnswer,
    this.correctAnswer,
    this.attemptCount = 1,
    this.weaknessTags = const <String>[],
    this.sessionSummary,
  });

  final LumoTutorMode mode;
  final LumoTutorSubject subject;
  final int grade;
  final String unit;
  final LumoTutorHelpLevel helpLevel;

  /// Nur Vorname, niemals Nachname oder private Daten.
  final String? childFirstName;

  final String? currentPrompt;
  final String? childAnswer;
  final String? correctAnswer;
  final int attemptCount;
  final List<String> weaknessTags;
  final String? sessionSummary;

  bool get isTestLike => mode == LumoTutorMode.testReview;

  bool get shouldAvoidDirectSolution =>
      mode == LumoTutorMode.practiceHint || helpLevel == LumoTutorHelpLevel.hintOnly;
}

class LumoTutorResponse {
  const LumoTutorResponse({
    required this.speech,
    this.shortHint,
    this.explanation,
    this.nextPrompt,
    this.visualPlan = const LumoTutorVisualPlan.none(),
    this.safetyBlocked = false,
    this.source = 'local_contract',
  });

  /// Kurzer kindgerechter Text, der auch vorgelesen werden darf.
  final String speech;

  /// Sehr kurzer Hinweis für normale Übungen.
  final String? shortHint;

  /// Erklärung für Nachhilfe+ oder nach Abschluss von Tests.
  final String? explanation;

  /// Optionale Folgeaufgabe, wenn eine Mini-Lektion abgeschlossen ist.
  final String? nextPrompt;

  /// Sicherer Visual-Plan. Die App rendert diesen lokal; keine KI-Bilder in V1.
  final LumoTutorVisualPlan visualPlan;

  final bool safetyBlocked;
  final String source;
}

class LumoTutorVisualPlan {
  const LumoTutorVisualPlan({
    required this.type,
    this.left,
    this.right,
    this.remove,
    this.result,
    this.word,
    this.parts = const <String>[],
    this.highlight,
    this.object = 'apple',
  });

  const LumoTutorVisualPlan.none()
      : type = LumoTutorVisualType.none,
        left = null,
        right = null,
        remove = null,
        result = null,
        word = null,
        parts = const <String>[],
        highlight = null,
        object = 'apple';

  final LumoTutorVisualType type;
  final int? left;
  final int? right;
  final int? remove;
  final int? result;
  final String? word;
  final List<String> parts;
  final String? highlight;
  final String object;

  bool get hasMathQuantities => left != null || right != null || remove != null || result != null;
  bool get hasWordData => word != null || parts.isNotEmpty || highlight != null;
}

class LumoTutorEntitlement {
  const LumoTutorEntitlement({
    required this.nachhilfePlusEnabled,
    required this.voiceTutorEnabled,
    required this.dailyIntensiveHelpLimit,
    required this.dailyShortHintLimit,
  });

  const LumoTutorEntitlement.free()
      : nachhilfePlusEnabled = false,
        voiceTutorEnabled = false,
        dailyIntensiveHelpLimit = 0,
        dailyShortHintLimit = 3;

  const LumoTutorEntitlement.testPremium()
      : nachhilfePlusEnabled = true,
        voiceTutorEnabled = true,
        dailyIntensiveHelpLimit = 10,
        dailyShortHintLimit = 20;

  final bool nachhilfePlusEnabled;
  final bool voiceTutorEnabled;
  final int dailyIntensiveHelpLimit;
  final int dailyShortHintLimit;

  bool allows(LumoTutorMode mode) {
    if (mode == LumoTutorMode.practiceHint) return dailyShortHintLimit > 0;
    if (mode == LumoTutorMode.voiceTutor) return nachhilfePlusEnabled && voiceTutorEnabled;
    return nachhilfePlusEnabled && dailyIntensiveHelpLimit > 0;
  }
}
