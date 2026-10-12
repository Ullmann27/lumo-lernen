class ScienceQuestion {
  const ScienceQuestion(
      {required this.grade,
      required this.unit,
      required this.prompt,
      required this.answer,
      required this.choices,
      required this.explanation});
  const ScienceQuestion.item(int grade, String unit, String prompt,
      String answer, List<String> wrong, String explanation)
      : this(
            grade: grade,
            unit: unit,
            prompt: prompt,
            answer: answer,
            choices: wrong,
            explanation: explanation);
  final int grade;
  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
}

/// Bounded local content expansion: observe, compare, explain and act.
/// Grades describe app progression, not a claim of complete curriculum coverage.
const scienceExtensionQuestions = <ScienceQuestion>[
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Die Fußgängerampel ist rot. Was machst du?',
      'Ich warte am Gehsteig.',
      [
        'Ich laufe auf die Straße.',
        'Ich folge jedem Auto.',
        'Ich schließe die Augen.'
      ],
      'Rot heißt warten. Bleib am Gehsteig und achte auf den Verkehr.'),
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Warum tragen wir beim Radfahren einen Helm?',
      'Er schützt den Kopf.',
      [
        'Er macht das Rad schneller.',
        'Er ersetzt die Bremse.',
        'Er schützt nur die Schuhe.'
      ],
      'Ein passend sitzender Helm kann den Kopf bei einem Sturz schützen.'),
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Wo gehen Menschen normalerweise neben einer Straße?',
      'auf dem Gehsteig',
      ['in der Mitte der Fahrbahn', 'auf dem Autodach', 'auf den Bahngleisen'],
      'Der Gehsteig ist für Menschen zu Fuß vorgesehen.'),
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Was hilft anderen, dich im Dunkeln zu sehen?',
      'helle Kleidung mit Reflektoren',
      [
        'eine geschlossene Tasche',
        'dunkle Kleidung ohne Reflektoren',
        'geschlossene Augen'
      ],
      'Reflektoren werfen Licht zurück. Helle Kleidung und Reflektoren machen dich besser sichtbar.'),
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Der Bus fährt noch. Was machst du vor dem Aussteigen?',
      'Ich warte, bis er hält.',
      [
        'Ich springe heraus.',
        'Ich öffne ein Fenster.',
        'Ich laufe neben dem Bus.'
      ],
      'Steig erst aus, wenn der Bus vollständig hält und die Tür geöffnet ist.'),
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Warum schnallen wir uns im Auto an?',
      'Der Gurt hält uns bei starkem Bremsen.',
      [
        'Der Gurt lenkt das Auto.',
        'Der Gurt macht Musik.',
        'Der Gurt öffnet die Straße.'
      ],
      'Der Gurt und ein geeigneter Kindersitz helfen, dich beim Bremsen und bei einem Unfall zu schützen.'),
  ScienceQuestion.item(
      1,
      'Verkehr',
      'Du willst über die Straße gehen. Was prüfst du zuerst?',
      'ob Fahrzeuge kommen und anhalten',
      [
        'ob dein Stift schreibt',
        'ob die Wolken rund sind',
        'ob deine Jause süß ist'
      ],
      'Schau nach links, rechts und nochmals links. Geh nur hinüber, wenn du sicher überqueren kannst.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Ein Kind möchte mitspielen. Wie kannst du helfen?',
      'Ich erkläre ihm die Spielregeln.',
      [
        'Ich verstecke alle Spielsteine.',
        'Ich lache es aus.',
        'Ich schicke es immer weg.'
      ],
      'Regeln erklären und gemeinsam Platz machen hilft beim Mitspielen.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Zwei Kinder möchten denselben Stift. Was ist fair?',
      'Sie wechseln sich ab.',
      [
        'Eines nimmt alle Stifte.',
        'Sie zerbrechen den Stift.',
        'Sie verstecken die Tasche.'
      ],
      'Abwechseln oder gemeinsam eine Lösung vereinbaren hilft, einen Streit fair zu lösen.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Du hast jemanden versehentlich gestoßen. Was hilft?',
      'Ich entschuldige mich und frage, ob es ihm gut geht.',
      [
        'Ich laufe lachend weg.',
        'Ich stoße nochmals.',
        'Ich gebe jemand anderem die Schuld.'
      ],
      'Eine Entschuldigung und Nachfragen zeigen, dass dir das andere Kind wichtig ist.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Du findest eine fremde Jausenbox. Was machst du?',
      'Ich gebe sie einer Betreuungsperson.',
      ['Ich verstecke sie.', 'Ich werfe sie weg.', 'Ich esse sofort alles.'],
      'Eine Betreuungsperson kann helfen, die Jausenbox zurückzugeben.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Ein Kind sagt: Bitte hör auf. Wie reagierst du?',
      'Ich höre auf und nehme es ernst.',
      [
        'Ich mache absichtlich weiter.',
        'Ich lache es aus.',
        'Ich halte ihm die Ohren zu.'
      ],
      'Jeder Mensch darf Grenzen setzen. Nimm ein Nein ernst.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Eine Aufgabe ist für dich zu schwer. Was darfst du tun?',
      'um Hilfe bitten',
      [
        'so tun, als gäbe es sie nicht',
        'andere Kinder anschreien',
        'alles kaputtmachen'
      ],
      'Du darfst um Hilfe bitten. Gemeinsam kann man einen nächsten kleinen Schritt finden.'),
  ScienceQuestion.item(
      1,
      'Familie und Gemeinschaft',
      'Welche Regel hilft beim Gespräch in der Klasse?',
      'einander ausreden lassen',
      [
        'alle gleichzeitig schreien',
        'immer weglaufen',
        'niemanden zuhören lassen'
      ],
      'Wenn wir zuhören und andere ausreden lassen, können alle ihre Gedanken erklären.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Welcher Tag kommt direkt nach Montag?',
      'Dienstag',
      ['Sonntag', 'Freitag', 'Samstag'],
      'Die Reihenfolge beginnt Montag, Dienstag, Mittwoch.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Welcher Tag kommt direkt vor Sonntag?',
      'Samstag',
      ['Montag', 'Mittwoch', 'Donnerstag'],
      'Samstag liegt zwischen Freitag und Sonntag.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Wie viele Tage hat eine Woche?',
      '7',
      ['5', '10', '12'],
      'Eine Woche hat sieben Tage von Montag bis Sonntag.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Womit findest du das Datum eines Tages?',
      'mit einem Kalender',
      ['mit einer Waage', 'mit einem Thermometer', 'mit einem Kochlöffel'],
      'Ein Kalender zeigt Tage, Wochen und Monate.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Was kommt in einem normalen Tagesablauf vor dem Abend?',
      'der Nachmittag',
      ['die nächste Mitternacht', 'der nächste Morgen', 'die nächste Nacht'],
      'Nach Morgen und Mittag folgt der Nachmittag, dann der Abend.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Was bedeutet gestern?',
      'der Tag vor heute',
      ['der Tag nach morgen', 'die nächste Woche', 'das nächste Jahr'],
      'Gestern liegt einen Tag vor heute. Morgen liegt einen Tag danach.'),
  ScienceQuestion.item(
      1,
      'Zeit und Kalender',
      'Was bedeutet morgen?',
      'der Tag nach heute',
      ['der Tag vor gestern', 'die vergangene Woche', 'das vergangene Jahr'],
      'Heute ist der aktuelle Tag. Danach kommt morgen.'),
  ScienceQuestion.item(
      1,
      'Körper',
      'Womit hörst du einen Vogel singen?',
      'mit den Ohren',
      ['mit den Knien', 'mit den Zehen', 'mit den Haaren'],
      'Die Ohren nehmen Geräusche auf.'),
  ScienceQuestion.item(
      1,
      'Körper',
      'Womit riechst du an einer Blume?',
      'mit der Nase',
      ['mit den Ellbogen', 'mit den Füßen', 'mit den Haaren'],
      'Mit der Nase nehmen wir Gerüche wahr.'),
  ScienceQuestion.item(
      1,
      'Körper',
      'Warum waschen wir vor dem Essen die Hände?',
      'um Schmutz und viele Keime zu entfernen',
      [
        'damit die Hände wachsen',
        'damit die Jause verschwindet',
        'damit wir nichts hören'
      ],
      'Waschen mit Wasser und Seife entfernt Schmutz und viele Keime.'),
  ScienceQuestion.item(
      1,
      'Körper',
      'Was hilft dem Körper beim Ausruhen?',
      'genug Schlaf',
      [
        'immer wach bleiben',
        'den ganzen Tag schreien',
        'nie eine Pause machen'
      ],
      'Im Schlaf kann sich der Körper erholen.'),
  ScienceQuestion.item(
      1,
      'Körper',
      'Was solltest du bei Durst trinken?',
      'Wasser',
      ['Salzwasser aus dem Meer', 'Putzmittel', 'Klebstoff'],
      'Sauberes Trinkwasser stillt den Durst. Unbekannte Flüssigkeiten trinkst du nicht.'),
  ScienceQuestion.item(
      1,
      'Körper',
      'Womit fühlst du, ob etwas weich ist?',
      'mit der Haut',
      ['nur mit den Haaren', 'nur mit den Zähnen', 'nur mit den Augen'],
      'In der Haut sitzen Sinneszellen für Berührung.'),
  ScienceQuestion.item(
      1,
      'Tag und Nacht',
      'Was brauchen wir oft, um bei Dunkelheit zu lesen?',
      'eine Lampe',
      ['einen Besen', 'eine Waage', 'einen Ball'],
      'Licht macht Buchstaben sichtbar.'),
  ScienceQuestion.item(
      1,
      'Tag und Nacht',
      'Wann sehen wir am klaren Himmel meistens viele Sterne?',
      'in der Nacht',
      ['am hellen Mittag', 'nur beim Frühstück', 'nur im Sommer am Tag'],
      'Sterne leuchten auch am Tag, doch das Sonnenlicht überstrahlt sie.'),
  ScienceQuestion.item(
      1,
      'Tag und Nacht',
      'Was passiert beim Sonnenaufgang?',
      'Es wird allmählich hell.',
      [
        'Es wird plötzlich Winter.',
        'Alle Wolken verschwinden.',
        'Der Mond fällt herunter.'
      ],
      'Beim Sonnenaufgang beginnt der helle Teil des Tages.'),
  ScienceQuestion.item(
      1,
      'Tag und Nacht',
      'Was passiert beim Sonnenuntergang?',
      'Es wird allmählich dunkel.',
      [
        'Es wird sofort Sommer.',
        'Die Erde hört auf, sich zu drehen.',
        'Alle Sterne verschwinden für immer.'
      ],
      'Nach dem Sonnenuntergang nimmt das Tageslicht ab.'),
  ScienceQuestion.item(
      1,
      'Tag und Nacht',
      'Was folgt im täglichen Ablauf auf den Abend?',
      'die Nacht',
      [
        'der Mittag desselben Tages',
        'der Morgen desselben Tages',
        'der Nachmittag desselben Tages'
      ],
      'Die Reihenfolge ist Morgen, Mittag, Nachmittag, Abend und Nacht.'),
  ScienceQuestion.item(
      1,
      'Tag und Nacht',
      'Warum ist ein Schatten draußen am sonnigen Tag sichtbar?',
      'Ein Gegenstand hält Licht auf.',
      [
        'Der Boden leuchtet schwarz.',
        'Ein Schatten ist ein Tier.',
        'Licht geht durch jeden Gegenstand.'
      ],
      'Wo ein Gegenstand das Sonnenlicht aufhält, fällt weniger Licht auf den Boden.'),
  ScienceQuestion.item(
      1,
      'Pflanzen',
      'Ein Samen liegt in trockener Erde. Was braucht er zum Keimen unter anderem?',
      'Wasser',
      [
        'Klebstoff',
        'Salz auf den Samen',
        'eine geschlossene Schachtel ohne Luft'
      ],
      'Viele Samen brauchen Wasser, Luft und eine passende Temperatur zum Keimen.'),
  ScienceQuestion.item(
      1,
      'Pflanzen',
      'Welcher Teil hält viele Pflanzen im Boden fest?',
      'die Wurzel',
      ['die Blüte', 'der Samen an der Spitze', 'das Blatt'],
      'Wurzeln verankern die Pflanze und nehmen Wasser auf.'),
  ScienceQuestion.item(
      1,
      'Pflanzen',
      'Was kannst du tun, um eine Pflanze zu beobachten?',
      'regelmäßig schauen und Veränderungen zeichnen',
      [
        'alle Blätter abreißen',
        'den Topf verstecken',
        'die Pflanze nie ansehen'
      ],
      'Beobachtungen und Zeichnungen zeigen, wie eine Pflanze sich verändert.'),
  ScienceQuestion.item(
      1,
      'Pflanzen',
      'Welcher Baum trägt im Herbst oft Äpfel?',
      'der Apfelbaum',
      ['die Tanne', 'die Birke', 'die Buche'],
      'Äpfel sind die Früchte des Apfelbaums.'),
  ScienceQuestion.item(
      1,
      'Wetter',
      'Die Bäume bewegen sich stark. Was kann die Ursache sein?',
      'Wind',
      ['ein leises Buch', 'der Kalender', 'ein Radiergummi'],
      'Bewegte Luft heißt Wind. Sie kann Zweige und Blätter bewegen.'),
  ScienceQuestion.item(
      1,
      'Wetter',
      'Womit messen wir, wie warm die Luft ist?',
      'mit einem Thermometer',
      ['mit einem Lineal', 'mit einer Uhr', 'mit einer Waage'],
      'Ein Thermometer misst die Temperatur.'),
  ScienceQuestion.item(
      1,
      'Wetter',
      'Du hörst Donner im Freien. Was ist sinnvoll?',
      'mit einem Erwachsenen einen sicheren Innenraum aufsuchen',
      [
        'unter den höchsten einzelnen Baum stellen',
        'ins Wasser gehen',
        'auf einen Turm klettern'
      ],
      'Bei Gewitter suchen wir einen sicheren Innenraum. Einzelne hohe Bäume und Wasser sind gefährlich.'),
  ScienceQuestion.item(
      1,
      'Wetter',
      'Was hilft beim Regen trocken zu bleiben?',
      'eine Regenjacke',
      ['eine Badehose allein', 'ein Papierhut', 'offene Sandalen allein'],
      'Eine Regenjacke hält viele Regentropfen von der Kleidung ab.'),
  ScienceQuestion.item(
      1,
      'Jahreszeiten',
      'Welche Jahreszeit folgt auf den Frühling?',
      'Sommer',
      ['Winter', 'Herbst', 'Nacht'],
      'Die Jahreszeiten folgen Frühling, Sommer, Herbst und Winter.'),
  ScienceQuestion.item(
      1,
      'Jahreszeiten',
      'Welche Jahreszeit folgt auf den Herbst?',
      'Winter',
      ['Sommer', 'Frühling', 'Mittag'],
      'Nach dem Herbst beginnt der Winter.'),
  ScienceQuestion.item(
      1,
      'Tiere',
      'Welches Tier trägt ein Schneckenhaus?',
      'Schnecke',
      ['Hund', 'Amsel', 'Forelle'],
      'Viele Schnecken haben ein Haus auf dem Rücken, das sie schützt.'),
  ScienceQuestion.item(
      1,
      'Tiere',
      'Wie behandeln wir ein kleines Tier beim Beobachten?',
      'vorsichtig, ohne es zu verletzen',
      [
        'wir reißen ihm Beine aus',
        'wir legen es in die pralle Sonne',
        'wir treten darauf'
      ],
      'Lebewesen brauchen Schutz. Beobachte vorsichtig und lass das Tier in seinem Lebensraum.'),
  ScienceQuestion.item(2, 'Zeit und Kalender', 'Wie viele Monate hat ein Jahr?',
      '12', ['7', '24', '30'], 'Ein Kalenderjahr hat zwölf Monate.'),
  ScienceQuestion.item(
      2,
      'Zeit und Kalender',
      'Welcher Monat folgt auf April?',
      'Mai',
      ['März', 'Jänner', 'Dezember'],
      'Auf März folgt April, danach Mai.'),
  ScienceQuestion.item(
      2,
      'Zeit und Kalender',
      'Welcher Monat beginnt ein Kalenderjahr?',
      'Jänner',
      ['Juni', 'September', 'Dezember'],
      'In Österreich nennen wir den ersten Monat Jänner.'),
  ScienceQuestion.item(
      2,
      'Zeit und Kalender',
      'Was bedeutet übermorgen?',
      'der Tag nach morgen',
      ['der Tag vor gestern', 'der heutige Tag', 'die vergangene Woche'],
      'Von heute aus gehst du zwei Tage weiter: morgen und übermorgen.'),
  ScienceQuestion.item(
      2,
      'Verkehr',
      'Du fährst mit dem Rad und willst abbiegen. Was hilft anderen?',
      'ein deutliches Handzeichen',
      ['geschlossene Augen', 'die Klingel ausbauen', 'das Licht verdecken'],
      'Ein Handzeichen zeigt deine Absicht. Prüfe vorher den Verkehr und halte das Rad sicher.'),
  ScienceQuestion.item(
      2,
      'Verkehr',
      'Warum lässt du beim Radfahren Abstand?',
      'damit du rechtzeitig bremsen kannst',
      [
        'damit du nichts siehst',
        'damit du schneller auffährst',
        'damit dein Helm unnötig wird'
      ],
      'Mit Abstand hast du mehr Zeit zu reagieren und zu bremsen.'),
  ScienceQuestion.item(
      2,
      'Berufe',
      'Wer hilft, einen Brand zu löschen?',
      'die Feuerwehr',
      ['die Büchereimitarbeiterin', 'der Bäcker', 'die Gärtnerin'],
      'Die Feuerwehr löscht Brände und hilft bei vielen Notfällen.'),
  ScienceQuestion.item(
      2,
      'Berufe',
      'Wer repariert eine undichte Wasserleitung?',
      'ein Installateur',
      ['ein Busfahrer', 'eine Lehrerin', 'ein Briefträger'],
      'Installateurinnen und Installateure arbeiten unter anderem an Wasserleitungen.'),
  ScienceQuestion.item(
      2,
      'Körper',
      'Warum braucht der Körper Bewegung?',
      'Sie stärkt unter anderem Muskeln und Herz.',
      [
        'Sie ersetzt jeden Schlaf.',
        'Sie macht Wasser unnötig.',
        'Sie verhindert jeden Unfall.'
      ],
      'Bewegung trainiert Muskeln, Herz und Kreislauf. Ruhe und Trinken bleiben ebenfalls wichtig.'),
  ScienceQuestion.item(
      2,
      'Körper',
      'Was machst du bei einer Verletzung in der Schule?',
      'einer Betreuungsperson Bescheid sagen',
      [
        'sie immer verstecken',
        'Schmutz in die Wunde reiben',
        'unbekannte Medikamente nehmen'
      ],
      'Eine Betreuungsperson kann die Verletzung versorgen und weitere Hilfe holen.'),
  ScienceQuestion.item(
      2,
      'Familie und Gemeinschaft',
      'Eine Abstimmung soll fair sein. Welche Regel hilft?',
      'jede Person hat gleich viele Stimmen',
      [
        'nur das lauteste Kind stimmt ab',
        'die Stimmen werden versteckt',
        'ein Kind zählt nur seine eigenen Stimmen'
      ],
      'Gleiche Stimmrechte und nachvollziehbares Zählen helfen bei einer fairen Abstimmung.'),
  ScienceQuestion.item(
      2,
      'Familie und Gemeinschaft',
      'Was hilft beim gemeinsamen Arbeiten?',
      'Aufgaben besprechen und verteilen',
      [
        'alle Materialien verstecken',
        'niemanden zu Wort kommen lassen',
        'nur streiten'
      ],
      'Wenn Aufgaben und Absprachen klar sind, können alle beitragen.'),
  ScienceQuestion.item(
      2,
      'Wetter',
      'Wasser liegt bei Frost draußen. Was kann passieren?',
      'Es kann zu Eis gefrieren.',
      [
        'Es wird zu Sand.',
        'Es verliert sein Gewicht vollständig.',
        'Es wird zu Holz.'
      ],
      'Bei ausreichend niedriger Temperatur gefriert Wasser zu Eis.'),
  ScienceQuestion.item(
      2,
      'Pflanzen',
      'Warum lassen wir Blüten für Bienen stehen?',
      'Sie liefern oft Nahrung.',
      [
        'Bienen essen Beton.',
        'Blüten ersetzen jeden Lebensraum.',
        'Bienen brauchen nie Nahrung.'
      ],
      'Viele Blüten bieten Bienen Nektar und Pollen.'),
  ScienceQuestion.item(
      3,
      'Wasserkreislauf',
      'Was passiert beim Verdunsten von Wasser?',
      'Es geht als Wasserdampf in die Luft.',
      [
        'Es wird zu Stein.',
        'Es wird zu Salz.',
        'Es verschwindet ohne Stoffänderung aus der Welt.'
      ],
      'Beim Verdunsten wird flüssiges Wasser gasförmig. Es bleibt als Wasserdampf vorhanden.'),
  ScienceQuestion.item(
      3,
      'Wasserkreislauf',
      'Eine kalte Scheibe beschlägt. Was passiert dabei?',
      'Wasserdampf wird zu kleinen Tropfen.',
      ['Glas wird zu Wasser.', 'Luft wird zu Sand.', 'Wasser verbrennt.'],
      'An kalten Oberflächen kann Wasserdampf kondensieren und Tropfen bilden.'),
  ScienceQuestion.item(
      3,
      'Ernährung',
      'Was hilft dir beim Vergleichen verpackter Lebensmittel?',
      'Zutatenliste und Nährwertangaben lesen',
      [
        'nur die Verpackungsfarbe ansehen',
        'nur die größte Schrift lesen',
        'jede Werbung sofort glauben'
      ],
      'Die Angaben zeigen unter anderem Zutaten und Mengen bestimmter Nährstoffe.'),
  ScienceQuestion.item(
      3,
      'Ernährung',
      'Was ist eine abwechslungsreiche Ernährung?',
      'verschiedene passende Lebensmittel essen',
      [
        'immer nur Süßigkeiten essen',
        'nie Wasser trinken',
        'jeden Tag nur dasselbe essen'
      ],
      'Verschiedene Lebensmittel können unterschiedliche Nährstoffe liefern.'),
  ScienceQuestion.item(
      3,
      'Bundesländer Österreichs',
      'In welchem Bundesland liegt die Landeshauptstadt Graz?',
      'Steiermark',
      ['Tirol', 'Vorarlberg', 'Burgenland'],
      'Graz ist die Landeshauptstadt der Steiermark.'),
  ScienceQuestion.item(
      3,
      'Bundesländer Österreichs',
      'Wie viele Bundesländer hat Österreich?',
      '9',
      ['4', '7', '12'],
      'Österreich besteht aus neun Bundesländern.'),
  ScienceQuestion.item(
      3,
      'Verkehr',
      'Warum braucht ein fahrendes Auto einen Bremsweg?',
      'Es kann nicht sofort zum Stillstand kommen.',
      [
        'Jede Straße ist gleich lang.',
        'Autos brauchen keinen Abstand.',
        'Nur die Farbe bestimmt das Bremsen.'
      ],
      'Bis ein Auto steht, legt es einen Weg zurück. Geschwindigkeit und Straßenverhältnisse beeinflussen ihn.'),
  ScienceQuestion.item(
      3,
      'Pflanzen',
      'Warum sind Wurzeln für eine Pflanze wichtig?',
      'Sie nehmen Wasser auf und verankern die Pflanze.',
      [
        'Sie ersetzen jede Blüte.',
        'Sie machen Licht.',
        'Sie treiben das Fahrrad an.'
      ],
      'Viele Wurzeln nehmen Wasser und Mineralstoffe auf und geben Halt im Boden.'),
  ScienceQuestion.item(
      3,
      'Körper',
      'Welche Aufgabe hat das Herz?',
      'Blut durch den Körper pumpen',
      ['Nahrung kauen', 'Gerüche wahrnehmen', 'Licht erzeugen'],
      'Das Herz pumpt Blut. So werden unter anderem Sauerstoff und Nährstoffe transportiert.'),
  ScienceQuestion.item(
      3,
      'Zeit und Kalender',
      'Warum dauert ein Schaltjahr einen Tag länger?',
      'Der Februar hat dann 29 Tage.',
      [
        'Jeder Monat hat einen zusätzlichen Tag.',
        'Der Juli fehlt.',
        'Jede Woche hat acht Tage.'
      ],
      'Ein Schaltjahr hat 366 Tage. Der zusätzliche Tag ist der 29. Februar.'),
  ScienceQuestion.item(
      4,
      'Stromkreise',
      'Die Lampe im Batteriestromkreis ist aus. Ein Kabel ist unterbrochen. Was erklärt das?',
      'Der Stromkreis ist nicht geschlossen.',
      [
        'Die Batterie muss immer brennen.',
        'Die Lampe braucht kein Kabel.',
        'Strom fließt durch jede Lücke.'
      ],
      'In einem einfachen Stromkreis müssen die Verbindungen geschlossen sein, damit Strom fließt.'),
  ScienceQuestion.item(
      4,
      'Stromkreise',
      'Womit üben Kinder einen einfachen Stromkreis sicher unter Anleitung?',
      'mit einer geeigneten kleinen Batterie',
      [
        'mit einer Steckdose',
        'mit einer offenen Netzleitung',
        'mit einem beschädigten Ladekabel'
      ],
      'Für Schulversuche verwenden wir unter Anleitung sichere Kleinspannung. Steckdosen und Netzleitungen sind kein Experimentiermaterial.'),
  ScienceQuestion.item(
      4,
      'Stromkreise',
      'Warum sind elektrische Kabel außen oft mit Kunststoff umhüllt?',
      'Kunststoff isoliert den leitenden Draht.',
      [
        'Kunststoff erzeugt den ganzen Strom.',
        'Kunststoff ersetzt die Batterie.',
        'Kunststoff macht Kabel essbar.'
      ],
      'Die isolierende Hülle schützt vor Kontakt mit dem leitenden Metall.'),
  ScienceQuestion.item(
      4,
      'Stromkreise',
      'Der Schalter wird geöffnet. Was geschieht im einfachen Stromkreis?',
      'Die Lampe geht aus.',
      [
        'Die Lampe leuchtet immer heller.',
        'Das Kabel verschwindet.',
        'Die Batterie lädt sich dadurch sofort auf.'
      ],
      'Ein offener Schalter unterbricht den Stromkreis.'),
  ScienceQuestion.item(
      4,
      'Ökosysteme',
      'Eine Wiese wird seltener gemäht. Viele Blumen blühen. Wer findet dadurch mehr Nahrung?',
      'viele blütenbesuchende Insekten',
      ['nur Autos', 'nur Schreibtische', 'nur Computer'],
      'Blüten bieten vielen Insekten Pollen und Nektar.'),
  ScienceQuestion.item(
      4,
      'Ökosysteme',
      'Warum lassen wir im Wald auch Totholz liegen?',
      'Es ist Lebensraum für viele Organismen.',
      [
        'Es verhindert jeden Regen.',
        'Es macht alle Pflanzen unsterblich.',
        'Es ersetzt jeden lebenden Baum.'
      ],
      'Totholz bietet Pilzen und Tieren Nahrung und Lebensraum und wird nach und nach zersetzt.'),
  ScienceQuestion.item(
      4,
      'Ökosysteme',
      'Was geschieht, wenn ein Lebensraum stark verschmutzt wird?',
      'Lebewesen können geschädigt werden.',
      [
        'Alle Tiere bekommen mehr Platz.',
        'Alle Pflanzen brauchen dann weniger Wasser.',
        'Es hat nie Auswirkungen.'
      ],
      'Verschmutzung kann Nahrung, Wasser und Lebensbedingungen beeinträchtigen.'),
  ScienceQuestion.item(
      4,
      'Ökosysteme',
      'Welche Nahrungskette ist möglich?',
      'Gras → Hase → Fuchs',
      ['Fuchs → Stein → Gras', 'Hase → Sonne → Glas', 'Stein → Gras → Sonne'],
      'Ein Hase frisst Pflanzen. Ein Fuchs kann einen Hasen fressen.'),
  ScienceQuestion.item(
      4,
      'Geschichte',
      'Warum vergleichen wir mehrere Quellen zu einem Ereignis?',
      'Sie können verschiedene Sichtweisen zeigen.',
      [
        'Eine Quelle ist immer vollständig.',
        'Alte Bilder sind immer erfunden.',
        'Jede Quelle sagt immer dasselbe.'
      ],
      'Quellen können unterschiedliche Beobachtungen und Perspektiven enthalten. Vergleiche sie sorgfältig.'),
  ScienceQuestion.item(
      4,
      'Geschichte',
      'Was ist ein Beispiel für eine schriftliche historische Quelle?',
      'ein alter Brief',
      [
        'eine heutige Schätzung ohne Beleg',
        'ein neuer Spielwürfel',
        'ein leerer Bildschirm'
      ],
      'Ein Brief aus der betrachteten Zeit kann Auskunft über damaliges Leben geben.'),
  ScienceQuestion.item(
      4,
      'Geschichte',
      'Was zeigt eine Zeitleiste?',
      'Ereignisse in zeitlicher Reihenfolge',
      [
        'nur Höhen von Bergen',
        'nur Gewichte von Tieren',
        'nur Farben von Autos'
      ],
      'Eine Zeitleiste ordnet Ereignisse nach ihrer Zeit.'),
  ScienceQuestion.item(
      4,
      'Geografie Österreich',
      'Wozu dient die Legende einer Landkarte?',
      'Sie erklärt Zeichen und Farben.',
      [
        'Sie misst automatisch das Wetter.',
        'Sie erzählt nur erfundene Märchen.',
        'Sie ersetzt jede Beschriftung.'
      ],
      'Die Kartenlegende erklärt, wofür die verwendeten Symbole und Farben stehen.'),
  ScienceQuestion.item(
      4,
      'Geografie Österreich',
      'Welcher große Fluss fließt durch Linz und Wien?',
      'Donau',
      ['Nil', 'Amazonas', 'Themse'],
      'Die Donau fließt unter anderem durch Linz und Wien.'),
  ScienceQuestion.item(
      4,
      'Kontinente und Ozeane',
      'Auf welchem Kontinent liegt Österreich?',
      'Europa',
      ['Australien', 'Antarktika', 'Südamerika'],
      'Österreich liegt in Europa.'),
  ScienceQuestion.item(
      4,
      'Kontinente und Ozeane',
      'Warum schmeckt Meerwasser meist salzig?',
      'Es enthält gelöste Salze.',
      [
        'Es enthält immer Zucker.',
        'Jede Welle erzeugt Zucker.',
        'Salz ist ein Fisch.'
      ],
      'Im Meerwasser sind Salze gelöst. Deshalb ist es kein Trinkwasser.'),
];
