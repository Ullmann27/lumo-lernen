enum LumoLearningDomain {
  german,
  math,
  science,
}

enum LumoLearningAction {
  hearSound,
  readSyllable,
  clapSyllables,
  buildWord,
  writeWord,
  buildSentence,
  understandSentence,
  countSet,
  recognizeNumberImage,
  completeToTen,
  decomposeNumber,
  chooseStrategy,
  solveStory,
  observe,
  sort,
  readFact,
  checkStatement,
  answerResearchQuestion,
}

class LumoDidacticTaskStyle {
  const LumoDidacticTaskStyle({
    required this.domain,
    required this.action,
    required this.visualType,
    required this.explanationCue,
    required this.difficultyStep,
  });

  final LumoLearningDomain domain;
  final LumoLearningAction action;
  final String visualType;
  final String explanationCue;
  final int difficultyStep;

  bool get isGerman => domain == LumoLearningDomain.german;
  bool get isMath => domain == LumoLearningDomain.math;
  bool get isScience => domain == LumoLearningDomain.science;

  LumoDidacticTaskStyle copyWith({
    LumoLearningDomain? domain,
    LumoLearningAction? action,
    String? visualType,
    String? explanationCue,
    int? difficultyStep,
  }) {
    return LumoDidacticTaskStyle(
      domain: domain ?? this.domain,
      action: action ?? this.action,
      visualType: visualType ?? this.visualType,
      explanationCue: explanationCue ?? this.explanationCue,
      difficultyStep: difficultyStep ?? this.difficultyStep,
    );
  }
}

class LumoDidacticTaskStyles {
  const LumoDidacticTaskStyles._();

  static const List<LumoDidacticTaskStyle> germanProgression = <LumoDidacticTaskStyle>[
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.german,
      action: LumoLearningAction.hearSound,
      visualType: 'sound_card',
      explanationCue: 'Sprich das Wort langsam und hoere genau hin.',
      difficultyStep: 1,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.german,
      action: LumoLearningAction.readSyllable,
      visualType: 'syllable_tiles',
      explanationCue: 'Lies jede Silbe einzeln und verbinde sie dann.',
      difficultyStep: 2,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.german,
      action: LumoLearningAction.clapSyllables,
      visualType: 'syllable_colors',
      explanationCue: 'Klatsche fuer jede Silbe einmal.',
      difficultyStep: 2,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.german,
      action: LumoLearningAction.buildWord,
      visualType: 'word_build',
      explanationCue: 'Setze die Silben zu einem Wort zusammen.',
      difficultyStep: 3,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.german,
      action: LumoLearningAction.writeWord,
      visualType: 'writing_line',
      explanationCue: 'Schreibe langsam Silbe fuer Silbe.',
      difficultyStep: 3,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.german,
      action: LumoLearningAction.understandSentence,
      visualType: 'sentence_strip',
      explanationCue: 'Lies den Satz und suche das Tunwort.',
      difficultyStep: 4,
    ),
  ];

  static const List<LumoDidacticTaskStyle> mathProgression = <LumoDidacticTaskStyle>[
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.math,
      action: LumoLearningAction.countSet,
      visualType: 'dot_field',
      explanationCue: 'Zaehle die Menge ruhig von links nach rechts.',
      difficultyStep: 1,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.math,
      action: LumoLearningAction.recognizeNumberImage,
      visualType: 'ten_frame',
      explanationCue: 'Schau auf das Zahlbild, bevor du rechnest.',
      difficultyStep: 1,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.math,
      action: LumoLearningAction.completeToTen,
      visualType: 'ten_frame',
      explanationCue: 'Ergaenze zuerst bis zehn.',
      difficultyStep: 2,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.math,
      action: LumoLearningAction.decomposeNumber,
      visualType: 'number_house',
      explanationCue: 'Zerlege die Zahl in zwei passende Teile.',
      difficultyStep: 2,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.math,
      action: LumoLearningAction.chooseStrategy,
      visualType: 'strategy_card',
      explanationCue: 'Waehle eine Rechenstrategie, die dir hilft.',
      difficultyStep: 3,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.math,
      action: LumoLearningAction.solveStory,
      visualType: 'story_card',
      explanationCue: 'Lies die Rechengeschichte und markiere die Zahlen.',
      difficultyStep: 4,
    ),
  ];

  static const List<LumoDidacticTaskStyle> scienceProgression = <LumoDidacticTaskStyle>[
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.science,
      action: LumoLearningAction.observe,
      visualType: 'observe_card',
      explanationCue: 'Schau genau hin und beschreibe, was du siehst.',
      difficultyStep: 1,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.science,
      action: LumoLearningAction.sort,
      visualType: 'sort_card',
      explanationCue: 'Ordne zusammen, was zusammen gehoert.',
      difficultyStep: 2,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.science,
      action: LumoLearningAction.readFact,
      visualType: 'fact_card',
      explanationCue: 'Lies den kurzen Sachtext und suche die wichtige Info.',
      difficultyStep: 3,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.science,
      action: LumoLearningAction.checkStatement,
      visualType: 'fact_check_card',
      explanationCue: 'Pruefe, ob die Aussage zum Sachtext passt.',
      difficultyStep: 3,
    ),
    LumoDidacticTaskStyle(
      domain: LumoLearningDomain.science,
      action: LumoLearningAction.answerResearchQuestion,
      visualType: 'research_card',
      explanationCue: 'Denke wie ein Forscher: Was ist die beste Antwort?',
      difficultyStep: 4,
    ),
  ];

  static List<LumoDidacticTaskStyle> forDomain(LumoLearningDomain domain) {
    switch (domain) {
      case LumoLearningDomain.german:
        return germanProgression;
      case LumoLearningDomain.math:
        return mathProgression;
      case LumoLearningDomain.science:
        return scienceProgression;
    }
  }

  static LumoDidacticTaskStyle styleFor({
    required LumoLearningDomain domain,
    required LumoLearningAction action,
  }) {
    final styles = forDomain(domain);
    return styles.firstWhere(
      (style) => style.action == action,
      orElse: () => styles.first,
    );
  }
}
