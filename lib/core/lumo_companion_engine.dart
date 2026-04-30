import '../app/app_state.dart';
import '../domain/companion/lumo_companion_core.dart' as companion;
import '../domain/learning/lumo_learning_domain.dart' as learning;

class LumoCompanionEngine {
  const LumoCompanionEngine();

  static const _companionCore = companion.LumoCompanionEngine();

  LumoReply answer({
    required String input,
    required LumoSessionState state,
  }) {
    final q = input.trim().toLowerCase();
    final name = state.childName.trim().isEmpty ? 'du' : state.childName.trim();

    final coreTurn = _companionCore.handleText(
      input: companion.ChildInput(
        childId: _childId(state),
        type: companion.ChildInputType.text,
        text: input,
        subject: _learningSubject(state.subject),
        skillId: _skillFromState(state),
      ),
      context: companion.CompanionContext(
        memory: companion.ChildLearningMemory(
          childId: _childId(state),
          childName: name,
          grade: state.grade,
          weakSkills: _weakSkills(state),
          preferredHelpStyle: 'visuell',
          favoriteTheme: 'Fuchs und Wald',
        ),
        activeSubject: _learningSubject(state.subject),
        activeSkill: _skillFromState(state),
        consecutiveWrong: state.practiceErrors,
        helpLevel: state.practiceErrors >= 2 ? 2 : 0,
      ),
    );

    if (!coreTurn.safety.allowed) {
      return LumoReply(
        text: coreTurn.response.text,
        mood: LumoMood.comfort,
      );
    }

    if (q.isEmpty) {
      return LumoReply(
        text: coreTurn.response.text,
        mood: _moodFor(coreTurn),
      );
    }

    if (_containsAny(q, [
      'was soll ich lernen',
      'was soll ich üben',
      'empfehlung',
      'empfiehl',
      'was fällt mir schwer',
      'was ist schwer',
      'wo bin ich schlecht',
      'hilf mir',
    ])) {
      final recommendationText = state.learningRecommendationText;
      if (recommendationText == null || recommendationText.trim().isEmpty) {
        return LumoReply(
          text: '${coreTurn.response.text} Ich kenne deinen Lernweg noch nicht gut genug. Lass uns mit drei gemischten Aufgaben starten.',
          mood: LumoMood.think,
          suggestedSubject: 'Alle',
          suggestedUnit: 'Alle',
          suggestedSection: LumoSection.exercises,
        );
      }
      return LumoReply(
        text: '${coreTurn.response.text} $recommendationText',
        mood: LumoMood.think,
        suggestedSubject: state.learningRecommendationSubject ?? state.subject,
        suggestedUnit: state.learningRecommendationUnit ?? state.unit,
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['traurig', 'schaff', 'dumm', 'blöd', 'angst', 'kann nicht', 'zu schwer', 'verstehe nicht'])) {
      return LumoReply(
        text: coreTurn.response.text,
        mood: LumoMood.comfort,
        suggestedSubject: _suggestSubject(q) ?? state.subject,
        suggestedUnit: _suggestUnit(q) ?? state.unit,
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['plus', 'addieren', '+', 'zusammenzählen'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Bei Plus kommen zwei Mengen zusammen. Ich zeige dir das mit Punkten.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Plus bis 20',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['minus', 'subtrahieren', '-', 'wegnehmen'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Bei Minus ist zuerst eine Menge da, dann geht etwas weg. Ich zeige dir das mit Beeren.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Minus bis 20',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['mal', 'einmaleins', 'multiplikation', 'times'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Malrechnen heisst: gleiche Gruppen zaehlen. Wir ueben das langsam.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Einmaleins',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['geteilt', 'division', 'teilen'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Beim Teilen verteilst du gerecht. Ich mache daraus eine kleine Aufgabe.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Teilen',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['lesen', 'deutsch', 'text', 'wort', 'silbe'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Beim Lesen machen wir es in kleinen Silben. Erst langsam, dann schneller.',
        mood: LumoMood.think,
        suggestedSubject: 'Deutsch',
        suggestedUnit: 'Silben',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['rechtschreibung', 'schreiben', 'buchstabe', 'diktat'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Beim Schreiben schauen wir auf Startpunkt, Richtung und die ganze Form.',
        mood: LumoMood.think,
        suggestedSubject: 'Deutsch',
        suggestedUnit: 'Buchstaben schreiben',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['spielen', 'spiel', 'game', 'fuchs spiel'])) {
      return LumoReply(
        text: coreTurn.response.text,
        mood: LumoMood.celebrate,
        suggestedSubject: state.subject == 'Alle' ? 'Mathematik' : state.subject,
        suggestedUnit: state.unit,
        suggestedSection: LumoSection.missions,
      );
    }

    if (_containsAny(q, ['foto', 'kamera', 'scannen', 'aufgabe fotografieren'])) {
      return const LumoReply(
        text: 'Du kannst deine Aufgabe fotografieren. Dann schauen wir sie gemeinsam an und ich helfe dir Schritt für Schritt.',
        mood: LumoMood.point,
        suggestedSection: LumoSection.scanner,
      );
    }

    if (_containsAny(q, ['test', 'schularbeit', 'prüfung'])) {
      return LumoReply(
        text: '${coreTurn.response.text} Wir machen das ruhig wie in der Schule: genau lesen, dann antworten.',
        mood: LumoMood.think,
        suggestedSubject: 'Alle',
        suggestedUnit: 'Alle',
        suggestedSection: LumoSection.tests,
      );
    }

    if (_containsAny(q, ['belohnung', 'stern', 'xp', 'level'])) {
      return const LumoReply(
        text: 'Du bekommst Sterne und XP fuer Lernen, Dranbleiben und besser werden. Nicht nur fuer perfekte Antworten.',
        mood: LumoMood.celebrate,
        suggestedSection: LumoSection.rewards,
      );
    }

    return LumoReply(
      text: coreTurn.response.text,
      mood: _moodFor(coreTurn),
      suggestedSubject: state.subject,
      suggestedUnit: state.unit,
      suggestedSection: coreTurn.plan.shouldGenerateTask ? LumoSection.exercises : LumoSection.learn,
    );
  }

  String _childId(LumoSessionState state) {
    final safeName = state.childName.trim().isEmpty ? 'kind' : state.childName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'local_${safeName}_${state.grade}';
  }

  learning.LearningSubject _learningSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('deutsch') || s.contains('lesen') || s.contains('schreiben') || s.contains('rechtschreibung')) return learning.LearningSubject.deutsch;
    if (s.contains('sach')) return learning.LearningSubject.sachkunde;
    return learning.LearningSubject.mathematik;
  }

  learning.SkillId? _skillFromState(LumoSessionState state) {
    if (state.unit == 'Alle') return null;
    return learning.SkillId('${state.subject}.${state.unit}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'));
  }

  List<learning.SkillId> _weakSkills(LumoSessionState state) {
    final entries = state.weakSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).map((entry) => learning.SkillId(entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'))).toList(growable: false);
  }

  LumoMood _moodFor(companion.LumoTurnResult turn) {
    if (turn.emotion.emotion == companion.ChildEmotion.frustrated || turn.emotion.emotion == companion.ChildEmotion.unsure) return LumoMood.comfort;
    if (turn.emotion.emotion == companion.ChildEmotion.happy) return LumoMood.celebrate;
    if (turn.plan.visualAction == companion.VisualActionType.showMiniGame) return LumoMood.celebrate;
    if (turn.plan.tone == companion.LumoTone.tutoring) return LumoMood.think;
    if (turn.intent.intent == companion.CompanionIntent.greeting) return LumoMood.greet;
    return LumoMood.wave;
  }

  String? _suggestSubject(String q) {
    if (_containsAny(q, ['plus', 'minus', 'mathe', 'rechnen', 'zahl'])) return 'Mathematik';
    if (_containsAny(q, ['lesen', 'deutsch', 'wort', 'silbe', 'buchstabe'])) return 'Deutsch';
    if (_containsAny(q, ['tier', 'wetter', 'pflanze', 'sach'])) return 'Sachunterricht';
    return null;
  }

  String? _suggestUnit(String q) {
    if (_containsAny(q, ['plus'])) return 'Plus bis 20';
    if (_containsAny(q, ['minus', 'wegnehmen'])) return 'Minus bis 20';
    if (_containsAny(q, ['silbe'])) return 'Silben';
    if (_containsAny(q, ['buchstabe', 'schreiben'])) return 'Buchstaben schreiben';
    return null;
  }

  bool _containsAny(String value, List<String> words) => words.any(value.contains);
}

class LumoReply {
  const LumoReply({
    required this.text,
    required this.mood,
    this.suggestedSection,
    this.suggestedSubject,
    this.suggestedUnit,
  });

  final String text;
  final LumoMood mood;
  final LumoSection? suggestedSection;
  final String? suggestedSubject;
  final String? suggestedUnit;
}
