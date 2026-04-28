class LumoCompanionAgent {
  const LumoCompanionAgent();

  String reactToEvent(String event, {Map<String, int> practice = const <String, int>{}}) {
    switch (event) {
      case 'app_opened':
        return _pick(_openings);
      case 'idle':
        return _pick(_idleIdeas);
      case 'mission_start':
        return _pick(_missionStarts);
      case 'mission_finished':
        return _pick(_missionFinished);
      case 'correct':
        return _pick(_correctRewards);
      case 'success_streak':
        return _pick(_successStreaks);
      case 'wrong_1':
        return _pick(_firstMistakes);
      case 'wrong_2':
        return _pick(_secondMistakes);
      case 'wrong_3':
        return _pick(_thirdMistakes);
      case 'test_start':
        return _pick(_testStarts);
      case 'test_finished':
        return _pick(_testFinished);
      case 'pause':
        return _pick(_pauseIdeas);
      default:
        return nextSuggestion(practice);
    }
  }

  String rewardLine({required int stars, required int xp, String? unit}) {
    final base = _pick(_rewardLines);
    final focus = unit == null || unit.isEmpty ? '' : ' Ich merke mir: $unit wird gerade besser.';
    return '$base Du hast jetzt $stars Sterne und $xp XP.$focus';
  }

  String nextSuggestion(Map<String, int> practice) {
    if (practice.isEmpty) return _pick(_freshSuggestions);
    final entries = practice.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final unit = entries.first.key;
    return _pick([
      'Ich habe etwas entdeckt: $unit braucht noch ein bisschen Fuchstraining. Wir machen es in kleinen Schritten.',
      'Gute Idee: Wir ueben $unit kurz und ruhig. Nicht lange, nur klug.',
      'Ich schlage $unit vor. Genau dort kann ich dir heute am besten helfen.',
      'Dein Kopf hat bei $unit schon viel gearbeitet. Wir machen daraus jetzt eine kleine Mission.',
    ]);
  }

  String explainTask({required String subject, required String unit, required String prompt, required String answer}) {
    if (subject == 'Mathematik') {
      if (unit.contains('Plus')) return _pick(_plusExplanations);
      if (unit.contains('Minus')) return _pick(_minusExplanations);
      if (unit.contains('Zahlenreihe')) return _pick(_sequenceExplanations);
      if (unit.contains('Geld')) return 'Stell dir Muenzen vor. Wir zaehlen langsam zusammen, wie viel es ist.';
      if (unit.contains('Uhr')) return 'Bei der Uhr schauen wir zuerst auf den grossen Zeiger, dann auf den kleinen.';
      return 'Lies die Aufgabe langsam. Suche zuerst die Zahlen, dann entscheide: kommt etwas dazu oder geht etwas weg?';
    }
    if (subject == 'Deutsch' || subject == 'Lesen') {
      if (unit.contains('Silben')) return _pick(_syllableExplanations);
      if (unit.contains('Reime')) return _pick(_rhymeExplanations);
      if (unit.contains('Anfang')) return _pick(_soundExplanations);
      return 'Lies langsam. Wenn ein Wort schwer ist, teile es in kleine Teile. Ich bleibe bei dir.';
    }
    if (subject == 'Englisch') return _pick(_englishExplanations);
    if (subject == 'Schreiben') return _pick(_writingExplanations);
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
    if (lower.contains('plus') || lower.contains('+')) return _pick(_plusExplanations);
    if (lower.contains('minus') || lower.contains('-')) return _pick(_minusExplanations);
    if (lower.contains('silbe')) return _pick(_syllableExplanations);
    if (lower.contains('reim')) return _pick(_rhymeExplanations);
    if (lower.contains('englisch')) return _pick(_englishExplanations);
    if (lower.contains('schreiben') || lower.contains('buchstabe')) return _pick(_writingExplanations);
    if (lower.contains('hilfe') || lower.contains('versteh')) return _pick(_helpResponses);
    if (lower.contains('pause') || lower.contains('muede') || lower.contains('müde')) return _pick(_pauseIdeas);
    if (lower.contains('was soll') || lower.contains('weiter')) return _pick(_freshSuggestions);
    if (lower.contains('gut gemacht') || lower.contains('geschafft')) return _pick(_correctRewards);
    return _pick(_generalChat);
  }

  String _pick(List<String> values) {
    if (values.isEmpty) return 'Ich bin bei dir. Wir machen einen kleinen Lernschritt.';
    final i = DateTime.now().microsecondsSinceEpoch.remainder(values.length);
    return values[i];
  }

  static const _openings = [
    'Hallo Lena! Ich bin da. Heute machen wir Lernen leicht und freundlich.',
    'Da bist du ja. Ich freue mich. Womit starten wir heute?',
    'Willkommen zur Lumo-Mission. Wir nehmen uns nur den naechsten kleinen Schritt vor.',
    'Hallo! Ich habe heute ein paar gute Lernideen fuer dich vorbereitet.',
  ];

  static const _idleIdeas = [
    'Ich habe eine Idee: eine kurze Mission mit drei kleinen Aufgaben.',
    'Wir koennen langsam starten. Eine leichte Aufgabe reicht fuer den Anfang.',
    'Such dir eine Karte aus. Ich bleibe rechts bei dir und helfe sofort.',
    'Dein Kopf muss nicht alles auf einmal koennen. Wir machen es Schritt fuer Schritt.',
  ];

  static const _missionStarts = [
    'Super. Ich bleibe bei dir und gebe dir immer nur den naechsten kleinen Schritt.',
    'Mission startet. Ruhig lesen, kurz nachdenken, dann antworten.',
    'Los gehts. Wir machen das wie ein kleines Abenteuer, nicht wie Stress.',
    'Ich begleite dich. Wenn etwas schwer wird, erklaere ich es anders.',
  ];

  static const _missionFinished = [
    'Mission geschafft. Ich speichere, was gut geklappt hat, und was wir noch leichter machen.',
    'Das war eine starke Lernrunde. Ich merke mir deine Fortschritte.',
    'Geschafft. Dein Lernweg wird jetzt ein kleines Stueck genauer.',
    'Prima. Wir haben heute wieder herausgefunden, was dir hilft.',
  ];

  static const _correctRewards = [
    'Sehr gut. Du hast sauber gedacht.',
    'Das war richtig. Ich habe gesehen, wie du es geloest hast.',
    'Klasse gemacht. Genau so wird Lernen staerker.',
    'Ja, das passt. Dein Kopf hat den richtigen Weg gefunden.',
    'Fuchsfreude! Das war ein guter Schritt.',
    'Stark geloest. Ich gebe dir gleich etwas Passendes danach.',
    'Richtig. Und nicht nur geraten, sondern gut gearbeitet.',
    'Super. Wir bauen darauf gleich weiter auf.',
  ];

  static const _rewardLines = [
    'Das war ein schoener Erfolg.',
    'Du hast dir die Belohnung verdient.',
    'Ich packe ein paar Sterne in deinen Lernrucksack.',
    'Deine Mission wird staerker.',
    'Das war ein echter Fortschrittsmoment.',
    'Ich sehe, dass du dranbleibst.',
  ];

  static const _successStreaks = [
    'Du bist gerade richtig gut im Fluss. Ich mache die naechste Aufgabe ein kleines bisschen spannender.',
    'Drei gute Schritte hintereinander. Wir duerfen jetzt vorsichtig etwas schwerer werden.',
    'Du wirst sicherer. Ich gebe dir eine Aufgabe mit einem kleinen Extra.',
    'Das laeuft gut. Wir bleiben konzentriert und freundlich.',
  ];

  static const _firstMistakes = [
    'Fast. Das ist kein Problem. Wir schauen noch einmal gemeinsam hin.',
    'Noch nicht ganz. Lies die Frage langsam, ich warte.',
    'Das war knapp. Versuch den ersten Schritt noch einmal.',
    'Fehler sind Hinweise. Ich helfe dir, den Hinweis zu lesen.',
  ];

  static const _secondMistakes = [
    'Du musst nicht schnell sein. Ich zeige dir einen ruhigeren Weg.',
    'Wir bremsen kurz. Erst verstehen, dann antworten.',
    'Okay, das Thema ist gerade knifflig. Ich mache es kleiner.',
    'Kein Druck. Wir nehmen nur den Anfang der Aufgabe.',
  ];

  static const _thirdMistakes = [
    'Nach drei Versuchen helfe ich dir ganz ruhig Schritt fuer Schritt.',
    'Jetzt uebernehme ich kurz den Erklaer-Teil. Danach bekommst du eine aehnliche leichtere Aufgabe.',
    'Das ist ein Lernsignal. Ich zeige dir den Weg und wir ueben danach sanfter.',
    'Alles gut. Schwierige Stellen sind genau da, wo Lumo helfen soll.',
  ];

  static const _testStarts = [
    'Arbeite wie im Heft. Ruhig lesen, dann erst antworten.',
    'Testmodus startet. Ich bleibe ruhig im Hintergrund und passe auf dich auf.',
    'Jetzt zaehlt Konzentration, nicht Geschwindigkeit.',
    'Wie in der Schule, nur freundlicher. Du schaffst den naechsten Schritt.',
  ];

  static const _testFinished = [
    'Ich habe deine Arbeit gespeichert und mache daraus einen Uebungsplan.',
    'Der Test ist fertig. Jetzt schauen wir freundlich, was schon klappt und was wir ueben.',
    'Geschafft. Ich werte nicht nur die Note, sondern auch deinen Lernweg aus.',
    'Fertig. Aus deinen Antworten baue ich die naechste passende Mission.',
  ];

  static const _pauseIdeas = [
    'Kurze Pause ist gut. Atme einmal ruhig ein und aus. Danach machen wir nur eine Mini-Aufgabe.',
    'Dein Kopf darf kurz ausruhen. Ich warte hier.',
    'Pause ist kein Aufgeben. Pause ist Akku laden.',
    'Trink einen Schluck Wasser. Danach nehmen wir die leichteste naechste Aufgabe.',
  ];

  static const _freshSuggestions = [
    'Starte mit einer gemischten Mission. Ich finde dann heraus, was gut passt.',
    'Ich wuerde mit einer kurzen Mathe- oder Lesemission anfangen.',
    'Nimm eine Karte, die freundlich aussieht. Ich mache daraus den passenden Weg.',
    'Wir koennen heute klein starten: drei Aufgaben, dann schauen wir weiter.',
  ];

  static const _plusExplanations = [
    'Plus bedeutet: Es kommt etwas dazu. Wir zaehlen beide Teile zusammen.',
    'Stell dir vor, du legst erst eine Menge hin und dann noch eine dazu. Danach zaehlst du alles.',
    'Bei Plus wird es mehr. Erst die erste Zahl, dann die zweite dazunehmen.',
    'Plus ist wie Sammeln. Zwei Gruppen werden zu einer Gruppe.',
  ];

  static const _minusExplanations = [
    'Minus bedeutet: Es geht etwas weg. Wir starten bei der ersten Zahl und gehen zurueck.',
    'Bei Minus wird es weniger. Stell dir vor, du nimmst einige Dinge weg.',
    'Starte bei der grossen Zahl. Dann gehst du langsam so viele Schritte zurueck.',
    'Minus ist wie Wegnehmen. Danach zaehlen wir, was noch da ist.',
  ];

  static const _sequenceExplanations = [
    'Schau auf den Sprung zwischen den Zahlen. Der Sprung bleibt gleich.',
    'Eine Zahlenreihe hat ein Muster. Finde den Abstand, dann findest du die naechste Zahl.',
    'Vergleiche immer zwei Nachbarn. Dann erkennst du die Regel.',
  ];

  static const _syllableExplanations = [
    'Silben findest du gut mit Klatschen. Ba-na-ne hat drei Klatscher.',
    'Sprich das Wort langsam. Jeder kleine Sprechteil ist eine Silbe.',
    'Wenn du klatschst, hoerst du, wie viele Teile ein Wort hat.',
  ];

  static const _rhymeExplanations = [
    'Reime hoeren am Ende gleich. Haus und Maus passen zusammen.',
    'Bei Reimen ist der Schlussklang wichtig. Hoer auf das Ende des Wortes.',
    'Sag beide Woerter laut. Wenn sie am Ende gleich klingen, reimen sie sich.',
  ];

  static const _soundExplanations = [
    'Sprich das Wort langsam. Der erste Klang ist der Anfangslaut.',
    'Der Anfangslaut ist das, was dein Mund zuerst macht.',
    'Hoer auf den allerersten Ton im Wort. Genau den suchen wir.',
  ];

  static const _englishExplanations = [
    'Englisch ueben wir mit kleinen Wortbildern. Ein Wort, ein Bild, eine Wiederholung.',
    'Mach aus dem englischen Wort ein Bild im Kopf. Dann merkt es sich leichter.',
    'Wir sagen das Wort langsam und verbinden es mit einer Sache, die du kennst.',
  ];

  static const _writingExplanations = [
    'Schreibe langsam. Es geht nicht um schnell, sondern um schoene ruhige Bewegungen.',
    'Fang oben an und fuehre den Finger ruhig. Ein schoener Buchstabe darf Zeit brauchen.',
    'Stell dir vor, dein Finger faehrt auf einer kleinen Strasse. Ruhig bleiben und der Linie folgen.',
  ];

  static const _helpResponses = [
    'Wir machen es Schritt fuer Schritt. Ich zeige dir zuerst den Anfang.',
    'Sag mir, was schwer ist: die Frage, die Rechnung oder das Wort?',
    'Ich erklaere es anders. Manchmal braucht ein Gedanke nur eine andere Tuer.',
    'Okay, ich mache die Aufgabe kleiner. Erst ein Teil, dann der naechste.',
  ];

  static const _generalChat = [
    'Ich bin bei dir. Lass uns eine kleine Lernmission starten.',
    'Das klingt nach einer Frage fuer Lumo. Willst du eine Erklaerung oder eine Aufgabe?',
    'Wir koennen reden, aber ich bleibe beim Lernen, Mutmachen und Helfen.',
    'Ich helfe dir gern. Waehle ein Fach oder frag mich zu einer Aufgabe.',
  ];
}
