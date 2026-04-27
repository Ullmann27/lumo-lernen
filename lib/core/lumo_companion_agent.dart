class LumoCompanionAgent {
  const LumoCompanionAgent();

  String reactToEvent(String event, {Map<String, int> practice = const <String, int>{}}) {
    switch (event) {
      case 'app_opened':
        return 'Hallo, ich bin Lumo. Heute reicht eine kleine Mission.';
      case 'idle':
        return 'Ich habe eine Idee: Wir machen nur eine kurze Aufgabe und schauen dann weiter.';
      case 'correct':
        return 'Fuchsstark. Ich gebe dir gleich eine neue passende Aufgabe.';
      case 'wrong_1':
        return 'Fast. Das ist kein Problem. Wir schauen es gemeinsam an.';
      case 'wrong_2':
        return 'Du musst nicht schnell sein. Ich zeige dir einen ruhigeren Weg.';
      case 'wrong_3':
        return 'Nach drei Versuchen helfe ich dir ganz ruhig Schritt fuer Schritt.';
      case 'test_start':
        return 'Arbeite wie im Heft. Ruhig lesen, dann erst antworten.';
      case 'test_finished':
        return 'Ich habe deine Arbeit gespeichert und mache daraus einen Uebungsplan.';
      default:
        return nextSuggestion(practice);
    }
  }

  String nextSuggestion(Map<String, int> practice) {
    if (practice.isEmpty) {
      return 'Starte mit einer gemischten Mission. Ich finde dann heraus, was gut passt.';
    }
    final entries = practice.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final unit = entries.first.key;
    return 'Ich schlage vor: Wir ueben $unit mit kleinen Schritten.';
  }

  String answerChild(String text) {
    final lower = text.toLowerCase();
    final privateWords = <String>['adresse', 'telefon', 'schule', 'passwort', 'wohn', 'tiktok', 'instagram', 'treffen'];
    final sadWords = <String>['angst', 'traurig', 'weh', 'verletzt', 'weinen'];
    final adultWords = <String>['gewalt', 'sex', 'kaufen', 'politik'];

    if (privateWords.any(lower.contains)) {
      return 'Das musst du mir nicht sagen. Frag bitte Mama, Papa oder einen vertrauten Erwachsenen. Ich helfe dir gern beim Lernen.';
    }
    if (sadWords.any(lower.contains)) {
      return 'Das klingt schwer. Bitte sag es Mama, Papa oder einem vertrauten Erwachsenen. Ich bleibe hier und mache mit dir nur einen ruhigen Schritt.';
    }
    if (adultWords.any(lower.contains)) {
      return 'Darueber rede ich nicht. Aber beim Lernen, Mutmachen oder Ausruhen helfe ich dir gern.';
    }
    if (lower.contains('hilfe') || lower.contains('versteh')) {
      return 'Wir machen es Schritt fuer Schritt. Ich zeige dir den Anfang.';
    }
    if (lower.contains('pause')) {
      return 'Gute Idee. Eine kurze Pause kann dem Kopf helfen. Danach machen wir eine Mini-Aufgabe.';
    }
    return 'Ich bin bei dir. Lass uns eine kleine Lernmission starten.';
  }
}
