import '../app/app_state.dart';

class LumoCompanionEngine {
  const LumoCompanionEngine();

  LumoReply answer({
    required String input,
    required LumoSessionState state,
  }) {
    final q = input.trim().toLowerCase();
    final name = state.childName.trim().isEmpty ? 'du' : state.childName.trim();

    if (q.isEmpty) {
      return LumoReply(
        text: 'Ich höre dir zu. Frag mich etwas zu Mathe, Deutsch, Englisch oder deiner Aufgabe.',
        mood: LumoMood.greet,
      );
    }

    if (_containsAny(q, ['traurig', 'schaff', 'dumm', 'blöd', 'angst', 'kann nicht', 'zu schwer'])) {
      return LumoReply(
        text: 'Ganz ruhig, $name. Du bist nicht schlecht. Wir machen es langsam und Schritt für Schritt. Ich bleibe bei dir.',
        mood: LumoMood.comfort,
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['plus', 'addieren', '+', 'zusammenzählen'])) {
      return LumoReply(
        text: 'Bei Plus zählst du zwei Mengen zusammen. Beispiel: 3 plus 2. Erst hast du 3, dann kommen 2 dazu. Zusammen sind es 5.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Plus bis 20',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['minus', 'subtrahieren', '-', 'wegnehmen'])) {
      return LumoReply(
        text: 'Bei Minus nimmst du etwas weg. Beispiel: 7 minus 2. Von 7 nimmst du 2 weg. Es bleiben 5 übrig.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Minus bis 20',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['mal', 'einmaleins', 'multiplikation', 'times'])) {
      return LumoReply(
        text: 'Malrechnen ist wie mehrere gleiche Gruppen zählen. 3 mal 4 bedeutet: drei Gruppen mit je vier Dingen. Das sind 12.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Einmaleins',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['geteilt', 'division', 'teilen'])) {
      return LumoReply(
        text: 'Beim Teilen verteilst du gerecht. Wenn 8 Kekse auf 4 Kinder verteilt werden, bekommt jedes Kind 2 Kekse.',
        mood: LumoMood.think,
        suggestedSubject: 'Mathematik',
        suggestedUnit: 'Teilen',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['lesen', 'deutsch', 'text', 'wort', 'silbe'])) {
      return LumoReply(
        text: 'Beim Lesen hilft es, Wörter in Silben zu teilen. Lies langsam. Erst die erste Silbe, dann die nächste. So wird ein schweres Wort leichter.',
        mood: LumoMood.think,
        suggestedSubject: 'Lesen',
        suggestedUnit: 'Silben',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['rechtschreibung', 'schreiben', 'buchstabe', 'diktat'])) {
      return LumoReply(
        text: 'Beim Schreiben hörst du das Wort langsam ab. Sprich es leise in Silben. Dann prüfst du: Groß oder klein? Lang oder kurz?',
        mood: LumoMood.think,
        suggestedSubject: 'Rechtschreibung',
        suggestedUnit: 'Wörter üben',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['englisch', 'english', 'farbe', 'tier', 'hello'])) {
      return LumoReply(
        text: 'Englisch lernen wir mit kleinen Wörtern. Zum Beispiel: hello heißt hallo. Red heißt rot. Dog heißt Hund.',
        mood: LumoMood.greet,
        suggestedSubject: 'Englisch',
        suggestedUnit: 'Wörter',
        suggestedSection: LumoSection.exercises,
      );
    }

    if (_containsAny(q, ['foto', 'kamera', 'scannen', 'aufgabe fotografieren'])) {
      return LumoReply(
        text: 'Du kannst deine Aufgabe fotografieren. Dann schauen wir sie gemeinsam an und ich helfe dir Schritt für Schritt.',
        mood: LumoMood.point,
        suggestedSection: LumoSection.scanner,
      );
    }

    if (_containsAny(q, ['test', 'schularbeit', 'prüfung'])) {
      return LumoReply(
        text: 'Für einen Test üben wir ruhig. Lies zuerst genau. Dann löse einfache Aufgaben. Danach schauen wir, was noch schwer ist.',
        mood: LumoMood.think,
        suggestedSubject: 'Alle',
        suggestedUnit: 'Alle',
        suggestedSection: LumoSection.tests,
      );
    }

    if (_containsAny(q, ['belohnung', 'stern', 'xp', 'level'])) {
      return LumoReply(
        text: 'Du bekommst Sterne und XP, wenn du übst. Wichtig ist nicht perfekt sein. Wichtig ist: Du versuchst es weiter.',
        mood: LumoMood.celebrate,
        suggestedSection: LumoSection.rewards,
      );
    }

    return LumoReply(
      text: 'Gute Frage, $name. Ich erkläre es dir einfach: Wir suchen zuerst das Fach, dann machen wir eine kleine Aufgabe dazu. So lernst du Schritt für Schritt.',
      mood: LumoMood.greet,
      suggestedSubject: state.subject,
      suggestedUnit: state.unit,
      suggestedSection: LumoSection.learn,
    );
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
