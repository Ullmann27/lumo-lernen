import '../learning/lumo_learning_domain.dart';

enum ChildInputType {
  speech,
  text,
  taskAnswer,
  writingAttempt,
  tap,
}

enum CompanionIntent {
  greeting,
  wantsHelp,
  needsClarification,
  doesNotUnderstand,
  asksForExplanation,
  asksForNextTask,
  celebrates,
  expressesFrustration,
  wantsToPlay,
  offTopic,
  unsafe,
}

enum ChildEmotion {
  neutral,
  curious,
  confident,
  happy,
  unsure,
  frustrated,
  tired,
}

enum LumoTone {
  calm,
  playful,
  encouraging,
  focused,
  tutoring,
}

enum SafetyRiskLevel {
  safe,
  redirect,
  parentNeeded,
}

enum VisualActionType {
  none,
  foxWave,
  foxThink,
  foxCelebrate,
  showDots,
  showNumberLine,
  showWritingTrace,
  showMiniGame,
  showCalmBreak,
}

class ChildInput {
  const ChildInput({
    required this.childId,
    required this.type,
    required this.text,
    this.subject,
    this.skillId,
    this.timestamp,
  });

  final String childId;
  final ChildInputType type;
  final String text;
  final LearningSubject? subject;
  final SkillId? skillId;
  final DateTime? timestamp;
}

class ChildLearningMemory {
  const ChildLearningMemory({
    required this.childId,
    required this.childName,
    required this.grade,
    this.strongSkills = const <SkillId>[],
    this.weakSkills = const <SkillId>[],
    this.preferredHelpStyle = 'visuell',
    this.preferredTone = LumoTone.encouraging,
    this.favoriteTheme = 'Fuchs und Wald',
    this.recentEmotions = const <ChildEmotion>[],
    this.recentIntents = const <CompanionIntent>[],
  });

  final String childId;
  final String childName;
  final int grade;
  final List<SkillId> strongSkills;
  final List<SkillId> weakSkills;
  final String preferredHelpStyle;
  final LumoTone preferredTone;
  final String favoriteTheme;
  final List<ChildEmotion> recentEmotions;
  final List<CompanionIntent> recentIntents;
}

class CompanionContext {
  const CompanionContext({
    required this.memory,
    this.activeSubject,
    this.activeSkill,
    this.lastTaskCorrect,
    this.consecutiveWrong = 0,
    this.helpLevel = 0,
  });

  final ChildLearningMemory memory;
  final LearningSubject? activeSubject;
  final SkillId? activeSkill;
  final bool? lastTaskCorrect;
  final int consecutiveWrong;
  final int helpLevel;
}

class IntentDetectionResult {
  const IntentDetectionResult({required this.intent, required this.confidence});
  final CompanionIntent intent;
  final double confidence;
}

class EmotionDetectionResult {
  const EmotionDetectionResult({required this.emotion, required this.confidence});
  final ChildEmotion emotion;
  final double confidence;
}

class SafetyDecision {
  const SafetyDecision({
    required this.allowed,
    required this.riskLevel,
    this.reason,
    this.redirectMessage,
  });

  final bool allowed;
  final SafetyRiskLevel riskLevel;
  final String? reason;
  final String? redirectMessage;
}

class TutorDialoguePlan {
  const TutorDialoguePlan({
    required this.intent,
    required this.emotion,
    required this.tone,
    required this.subject,
    required this.skillId,
    required this.helpLevel,
    required this.pedagogicGoal,
    required this.visualAction,
    this.shouldGenerateTask = false,
    this.shouldStartTutoring = false,
    this.maxWords = 34,
  });

  final CompanionIntent intent;
  final ChildEmotion emotion;
  final LumoTone tone;
  final LearningSubject? subject;
  final SkillId? skillId;
  final int helpLevel;
  final String pedagogicGoal;
  final VisualActionType visualAction;
  final bool shouldGenerateTask;
  final bool shouldStartTutoring;
  final int maxWords;
}

class LumoResponse {
  const LumoResponse({
    required this.text,
    required this.tone,
    required this.visualAction,
    this.followUpPrompt,
  });

  final String text;
  final LumoTone tone;
  final VisualActionType visualAction;
  final String? followUpPrompt;
}

class LumoTurnResult {
  const LumoTurnResult({
    required this.input,
    required this.intent,
    required this.emotion,
    required this.safety,
    required this.plan,
    required this.response,
  });

  final ChildInput input;
  final IntentDetectionResult intent;
  final EmotionDetectionResult emotion;
  final SafetyDecision safety;
  final TutorDialoguePlan plan;
  final LumoResponse response;
}

class LumoIntentDetector {
  const LumoIntentDetector();

  IntentDetectionResult detect(String text) {
    final t = _normalize(text);
    if (t.isEmpty) return const IntentDetectionResult(intent: CompanionIntent.offTopic, confidence: .30);
    if (_isIsolatedHelp(t)) {
      return const IntentDetectionResult(intent: CompanionIntent.needsClarification, confidence: .94);
    }
    if (_containsAny(t, const ['hallo', 'hi', 'servus', 'guten morgen'])) {
      return const IntentDetectionResult(intent: CompanionIntent.greeting, confidence: .86);
    }
    if (_containsAny(t, const ['ich verstehe', 'verstehe nicht', 'kann das nicht', 'zu schwer', 'hilfe'])) {
      return const IntentDetectionResult(intent: CompanionIntent.doesNotUnderstand, confidence: .92);
    }
    if (_containsAny(t, const ['erklaer', 'erklär', 'warum', 'wie geht', 'zeig mir'])) {
      return const IntentDetectionResult(intent: CompanionIntent.asksForExplanation, confidence: .88);
    }
    if (_containsAny(t, const ['spielen', 'spiel', 'game', 'fuchs spiel'])) {
      return const IntentDetectionResult(intent: CompanionIntent.wantsToPlay, confidence: .88);
    }
    if (_containsAny(t, const ['super', 'geschafft', 'richtig', 'cool', 'juhu'])) {
      return const IntentDetectionResult(intent: CompanionIntent.celebrates, confidence: .78);
    }
    if (_containsAny(t, const ['weiter', 'naechste', 'nächste', 'noch eine'])) {
      return const IntentDetectionResult(intent: CompanionIntent.asksForNextTask, confidence: .80);
    }
    return const IntentDetectionResult(intent: CompanionIntent.wantsHelp, confidence: .52);
  }

  String _normalize(String value) => value.trim().toLowerCase();
  bool _isIsolatedHelp(String value) => RegExp(r'^(bitte\s+)?(hilf(e)?|hilfe|help|brauch(e)?\s+hilfe|ich\s+brauch(e)?\s+hilfe)[.!?]*$').hasMatch(value);
  bool _containsAny(String value, List<String> needles) => needles.any(value.contains);
}

class LumoEmotionDetector {
  const LumoEmotionDetector();

  EmotionDetectionResult detect(String text, {int consecutiveWrong = 0}) {
    final t = text.trim().toLowerCase();
    if (consecutiveWrong >= 2) {
      return const EmotionDetectionResult(emotion: ChildEmotion.frustrated, confidence: .82);
    }
    if (_containsAny(t, const ['kann nicht', 'schwer', 'blöd', 'blöd', 'mag nicht', 'falsch'])) {
      return const EmotionDetectionResult(emotion: ChildEmotion.frustrated, confidence: .80);
    }
    if (_containsAny(t, const ['weiss nicht', 'weiß nicht', 'vielleicht', 'unsicher'])) {
      return const EmotionDetectionResult(emotion: ChildEmotion.unsure, confidence: .74);
    }
    if (_containsAny(t, const ['juhu', 'cool', 'super', 'geschafft'])) {
      return const EmotionDetectionResult(emotion: ChildEmotion.happy, confidence: .78);
    }
    if (_containsAny(t, const ['muede', 'müde', 'pause'])) {
      return const EmotionDetectionResult(emotion: ChildEmotion.tired, confidence: .75);
    }
    return const EmotionDetectionResult(emotion: ChildEmotion.neutral, confidence: .55);
  }

  bool _containsAny(String value, List<String> needles) => needles.any(value.contains);
}

class LumoSafetyGuard {
  const LumoSafetyGuard();

  SafetyDecision check(String text, CompanionIntent intent) {
    final t = text.trim().toLowerCase();
    if (_containsAny(t, const ['adresse', 'telefonnummer', 'passwort', 'wo wohnst', 'geheimnis'])) {
      return const SafetyDecision(
        allowed: false,
        riskLevel: SafetyRiskLevel.parentNeeded,
        reason: 'private_data',
        redirectMessage: 'Das ist etwas Privates. Bitte frag einen Erwachsenen. Wir koennen hier weiter lernen.',
      );
    }
    if (_containsAny(t, const ['angst', 'weh tun', 'wehgetan', 'verletzt', 'verletzen', 'allein zuhause', 'hilfe zuhause'])) {
      return const SafetyDecision(
        allowed: false,
        riskLevel: SafetyRiskLevel.parentNeeded,
        reason: 'wellbeing',
        redirectMessage: 'Das ist wichtig. Bitte sag es einem Erwachsenen, dem du vertraust. Ich bleibe ruhig bei dir.',
      );
    }
    return const SafetyDecision(allowed: true, riskLevel: SafetyRiskLevel.safe);
  }

  bool _containsAny(String value, List<String> needles) => needles.any(value.contains);
}

class TutorDialoguePlanner {
  const TutorDialoguePlanner();

  TutorDialoguePlan plan({
    required CompanionContext context,
    required IntentDetectionResult intent,
    required EmotionDetectionResult emotion,
  }) {
    final helpLevel = _helpLevel(context, emotion.emotion, intent.intent);
    final subject = context.activeSubject ?? LearningSubject.mathematik;
    final skill = context.activeSkill ?? (context.memory.weakSkills.isEmpty ? null : context.memory.weakSkills.first);

    if (intent.intent == CompanionIntent.needsClarification) {
      return TutorDialoguePlan(
        intent: intent.intent,
        emotion: emotion.emotion,
        tone: LumoTone.calm,
        subject: subject,
        skillId: skill,
        helpLevel: 0,
        pedagogicGoal: 'sicher klären, ob Lernhilfe oder Wohlbefinden gemeint ist',
        visualAction: VisualActionType.foxThink,
        shouldGenerateTask: false,
        shouldStartTutoring: false,
        maxWords: 22,
      );
    }

    if (intent.intent == CompanionIntent.wantsToPlay) {
      return TutorDialoguePlan(
        intent: intent.intent,
        emotion: emotion.emotion,
        tone: LumoTone.playful,
        subject: subject,
        skillId: skill,
        helpLevel: helpLevel,
        pedagogicGoal: 'spielerische Wiederholung ohne Leistungsdruck',
        visualAction: VisualActionType.showMiniGame,
        shouldGenerateTask: true,
        maxWords: 28,
      );
    }

    if (intent.intent == CompanionIntent.doesNotUnderstand || emotion.emotion == ChildEmotion.frustrated) {
      return TutorDialoguePlan(
        intent: intent.intent,
        emotion: emotion.emotion,
        tone: LumoTone.tutoring,
        subject: subject,
        skillId: skill,
        helpLevel: helpLevel,
        pedagogicGoal: 'kleiner erklaeren, Schwierigkeit senken, visuell zeigen',
        visualAction: _visualFor(subject, skill),
        shouldGenerateTask: true,
        shouldStartTutoring: true,
        maxWords: 32,
      );
    }

    return TutorDialoguePlan(
      intent: intent.intent,
      emotion: emotion.emotion,
      tone: context.memory.preferredTone,
      subject: subject,
      skillId: skill,
      helpLevel: helpLevel,
      pedagogicGoal: 'kurz antworten und nächsten sinnvollen Lernschritt anbieten',
      visualAction: VisualActionType.foxThink,
      shouldGenerateTask: intent.intent == CompanionIntent.asksForNextTask,
      maxWords: 34,
    );
  }

  int _helpLevel(CompanionContext context, ChildEmotion emotion, CompanionIntent intent) {
    var level = context.helpLevel;
    if (context.consecutiveWrong >= 2) level += 2;
    if (emotion == ChildEmotion.frustrated || emotion == ChildEmotion.unsure) level += 1;
    if (intent == CompanionIntent.doesNotUnderstand) level += 1;
    return level.clamp(0, 4).toInt();
  }

  VisualActionType _visualFor(LearningSubject subject, SkillId? skillId) {
    if (subject == LearningSubject.deutsch) return VisualActionType.showWritingTrace;
    if (subject == LearningSubject.sachkunde) return VisualActionType.foxThink;
    final value = skillId?.value ?? '';
    if (value.contains('subtraction') || value.contains('addition')) return VisualActionType.showDots;
    return VisualActionType.showNumberLine;
  }
}

class LumoResponseGenerator {
  const LumoResponseGenerator();

  LumoResponse generate({required TutorDialoguePlan plan, required ChildLearningMemory memory}) {
    final name = memory.childName.isEmpty ? 'du' : memory.childName;
    final variant = DateTime.now().millisecond % 4;

    if (plan.intent == CompanionIntent.needsClarification) {
      return const LumoResponse(
        text: 'Wobei brauchst du Hilfe? Geht es um eine Aufgabe oder fühlst du dich nicht gut?',
        tone: LumoTone.calm,
        visualAction: VisualActionType.foxThink,
      );
    }

    if (plan.intent == CompanionIntent.greeting) {
      final lines = <String>[
        'Hallo $name! Ich bin da. Wollen wir kurz und stark lernen?',
        'Hi $name! Heute machen wir es Schritt fuer Schritt.',
        'Schoen, dass du da bist. Ich bleibe bei dir und helfe dir.',
        'Hallo! Dein Lernfuchs ist bereit. Wir starten leicht.',
      ];
      return LumoResponse(text: lines[variant], tone: LumoTone.encouraging, visualAction: VisualActionType.foxWave);
    }

    if (plan.shouldStartTutoring) {
      final lines = <String>[
        'Okay, wir machen es kleiner. Ich zeige es dir mit einem Bild, dann probieren wir eins zusammen.',
        'Kein Stress. Ich sehe, hier brauchst du einen Zwischenschritt. Wir gehen langsam.',
        'Gut, dass du es sagst. Dann erklaere ich anders: erst schauen, dann zaehlen, dann antworten.',
        'Wir nehmen eine leichtere Aufgabe. Du musst nicht raten, ich fuehre dich.',
      ];
      return LumoResponse(text: lines[variant], tone: LumoTone.tutoring, visualAction: plan.visualAction, followUpPrompt: 'Bereit für eine Mini-Aufgabe?');
    }

    if (plan.intent == CompanionIntent.wantsToPlay) {
      final lines = <String>[
        'Ja! Wir spielen, aber schlau: Lumo sammelt nur die richtigen Antworten.',
        'Gute Idee. Ich mache daraus ein Lernspiel mit Fuchs-Punkten.',
        'Spielzeit! Aber jedes Feld hilft deinem Gehirn ein Stueck weiter.',
        'Wir nehmen ein kurzes Fuchs-Spiel. Schnell, bunt und mit Lernen drin.',
      ];
      return LumoResponse(text: lines[variant], tone: LumoTone.playful, visualAction: VisualActionType.showMiniGame);
    }

    final lines = <String>[
      'Ich höre dich. Wir machen den nächsten Schritt ganz ruhig.',
      'Okay. Ich passe die Aufgabe an dich an.',
      'Verstanden. Ich schaue, was dir jetzt am besten hilft.',
      'Gut gesagt. Dann wähle ich eine passende Aufgabe für dich.',
    ];
    return LumoResponse(text: lines[variant], tone: plan.tone, visualAction: plan.visualAction);
  }
}

class LumoCompanionEngine {
  const LumoCompanionEngine({
    this.intentDetector = const LumoIntentDetector(),
    this.emotionDetector = const LumoEmotionDetector(),
    this.safetyGuard = const LumoSafetyGuard(),
    this.dialoguePlanner = const TutorDialoguePlanner(),
    this.responseGenerator = const LumoResponseGenerator(),
  });

  final LumoIntentDetector intentDetector;
  final LumoEmotionDetector emotionDetector;
  final LumoSafetyGuard safetyGuard;
  final TutorDialoguePlanner dialoguePlanner;
  final LumoResponseGenerator responseGenerator;

  LumoTurnResult handleText({
    required ChildInput input,
    required CompanionContext context,
  }) {
    final intent = intentDetector.detect(input.text);
    final emotion = emotionDetector.detect(input.text, consecutiveWrong: context.consecutiveWrong);
    final safety = safetyGuard.check(input.text, intent.intent);

    final plan = safety.allowed
        ? dialoguePlanner.plan(context: context, intent: intent, emotion: emotion)
        : TutorDialoguePlan(
            intent: CompanionIntent.unsafe,
            emotion: emotion.emotion,
            tone: LumoTone.calm,
            subject: context.activeSubject,
            skillId: context.activeSkill,
            helpLevel: 0,
            pedagogicGoal: 'sicher umleiten',
            visualAction: VisualActionType.showCalmBreak,
            maxWords: 24,
          );

    final response = safety.allowed
        ? responseGenerator.generate(plan: plan, memory: context.memory)
        : LumoResponse(
            text: safety.redirectMessage ?? 'Bitte frag einen Erwachsenen. Wir koennen weiter lernen.',
            tone: LumoTone.calm,
            visualAction: VisualActionType.showCalmBreak,
          );

    return LumoTurnResult(
      input: input,
      intent: intent,
      emotion: emotion,
      safety: safety,
      plan: plan,
      response: response,
    );
  }
}
