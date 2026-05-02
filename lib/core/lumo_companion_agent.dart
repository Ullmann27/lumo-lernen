class LumoCompanionAgent {
  const LumoCompanionAgent();

  String reactToEvent(String event, {Map<String, int> practice = const <String, int>{}}) {
    switch (event) {
      case 'app_opened':
        return 'Hallo, ich bin Lumo. Heute reicht eine kleine Mission.';
      case 'idle':
        return 'Ich habe eine Idee: Wir machen eine 10-Minuten-Mission. Ich suche passende Aufgaben aus.';
      case 'mission_start':
        return 'Super. Ich bleibe bei dir und gebe dir immer nur den nächsten kleinen Schritt.';
      case 'mission_finished':
        return 'Mission geschafft. Ich speichere, was gut geklappt hat, und was wir noch leichter machen.';
      case 'correct':
        return 'Fuchsstark. Ich gebe dir gleich eine neue passende Aufgabe.';
      case 'success_streak':
        return 'Du bist gerade richtig gut im Fluss. Ich mache die nächste Aufgabe ein kleines bisschen spannender.';
      case 'wrong_1':
        return 'Fast. Das ist kein Problem. Wir schauen es gemeinsam an.';
      case 'wrong_2':
        return 'Du musst nicht schnell sein. Ich zeige dir einen ruhigeren Weg.';
      case 'wrong_3':
        return 'Nach drei Versuchen helfe ich dir ganz ruhig Schritt für Schritt.';
      case 'test_start':
        return 'Arbeite wie im Heft. Ruhig lesen, dann erst antworten.';
      case 'test_finished':
        return 'Ich habe deine Arbeit gespeichert und mache daraus einen Uebungsplan.';
      case 'pause':
        return 'Kurze Pause ist gut. Atme einmal ruhig ein und aus. Danach machen wir nur eine Mini-Aufgabe.';
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
    return 'Ich hätte eine gute Idee: Wir üben $unit in kleinen Schritten, ohne Druck.';
  }

  String explainTask({required String subject, required String unit, required String prompt, required String answer}) {
    if (subject == 'Mathematik') {
      if (unit.contains('Plus')) {
        return 'Bei Plus kommt etwas dazu. Lege zuerst die erste Zahl, dann die zweite dazu. Danach zaehlst du alles zusammen.';
      }
      if (unit.contains('Minus')) {
        return 'Bei Minus geht etwas weg. Starte bei der grossen Zahl und gehe langsam zurueck.';
      }
      if (unit.contains('Zahlenreihe')) {
        return 'Schau, wie gross der Sprung zwischen den Zahlen ist. Dieser Sprung bleibt gleich.';
      }
      return 'Lies die Aufgabe langsam. Suche zuerst die Zahlen, dann entscheide, ob etwas dazukommt oder weggeht.';
    }
    if (subject == 'Deutsch' || subject == 'Lesen') {
      if (unit.contains('Silben')) return 'Sprich das Wort langsam und klatsche jeden Wortteil mit.';
      if (unit.contains('Reime')) return 'Reimwoerter klingen am Ende fast gleich.';
      if (unit.contains('Anfang')) return 'Sprich das Wort langsam. Der erste Klang ist der Anfangslaut.';
      return 'Lies langsam. Wenn ein Wort schwer ist, teile es in kleine Teile.';
    }
    if (subject == 'Englisch') {
      return 'Hoere auf das Wort und verbinde es mit einem Bild im Kopf. So merkt man sich Englisch leichter.';
    }
    if (subject == 'Schreiben') {
      return 'Schreibe langsam. Es geht nicht um schnell, sondern um schöne ruhige Bewegungen.';
    }
    return 'Ich helfe dir mit einem kleinen Schritt. Wir machen die Aufgabe ruhig zusammen.';
  }

  String answerChild(String text) {
    final lower = text.toLowerCase();
    final privateWords = <String>['adresse', 'telefon', 'schule', 'passwort', 'wohn', 'tiktok', 'instagram', 'treffen', 'foto von mir'];
    final sadWords = <String>['angst', 'traurig', 'weh', 'verletzt', 'weinen', 'allein'];
    final adultWords = <String>['gewalt', 'sex', 'kaufen', 'politik', 'geld schicken'];

    if (privateWords.any(lower.contains)) {
      return 'Das musst du mir nicht sagen. Frag bitte Mama, Papa oder einen vertrauten Erwachsenen. Ich helfe dir gern beim Lernen.';
    }
    if (sadWords.any(lower.contains)) {
      return 'Das klingt schwer. Bitte sag es Mama, Papa oder einem vertrauten Erwachsenen. Ich bleibe hier und mache mit dir nur einen ruhigen Lernschritt.';
    }
    if (adultWords.any(lower.contains)) {
      return 'Darueber rede ich nicht. Aber beim Lernen, Mutmachen oder Ausruhen helfe ich dir gern.';
    }
    if (lower.contains('plus') || lower.contains('+')) {
      return 'Plus bedeutet: Es kommt etwas dazu. Wir zaehlen beide Teile zusammen.';
    }
    if (lower.contains('minus') || lower.contains('-')) {
      return 'Minus bedeutet: Es geht etwas weg. Wir starten bei der ersten Zahl und gehen zurueck.';
    }
    if (lower.contains('silbe')) {
      return 'Silben findest du gut mit Klatschen. Ba-na-ne hat drei Klatscher.';
    }
    if (lower.contains('reim')) {
      return 'Reime hören am Ende gleich. Haus und Maus passen zusammen.';
    }
    if (lower.contains('englisch')) {
      return 'Englisch üben wir mit kleinen Wortbildern. Ein Wort, ein Bild, eine Wiederholung.';
    }
    if (lower.contains('hilfe') || lower.contains('versteh')) {
      return 'Wir machen es Schritt für Schritt. Ich zeige dir zuerst den Anfang.';
    }
    if (lower.contains('pause') || lower.contains('muede')) {
      return 'Gute Idee. Eine kurze Pause kann dem Kopf helfen. Danach machen wir eine Mini-Aufgabe.';
    }
    return 'Ich bin bei dir. Lass uns eine kleine Lernmission starten.';
  }
}
