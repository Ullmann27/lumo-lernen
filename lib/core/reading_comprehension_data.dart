/// Local, visible-text comprehension. Every question names its evidence;
/// no generated factual claim, hidden picture or provider request.
class ReadingCheck {
  const ReadingCheck(this.question, this.answer, this.wrong);
  final String question;
  final String answer;
  final List<String> wrong;
}

class ReadingPassage {
  const ReadingPassage(this.text, this.checks);
  final String text;
  final List<ReadingCheck> checks;
}

const readingPassages = <int, List<ReadingPassage>>{
  1: [
    ReadingPassage('Mia malt eine rote Blume.', [
      ReadingCheck('Was malt Mia?', 'eine Blume', ['ein Haus', 'einen Ball']),
      ReadingCheck('Welche Farbe hat die Blume?', 'rot', ['blau', 'gelb'])
    ]),
    ReadingPassage('Lumo liest im Garten ein Buch.', [
      ReadingCheck(
          'Was liest Lumo?', 'ein Buch', ['ein Schild', 'einen Brief']),
      ReadingCheck('Wo liest Lumo?', 'im Garten', ['im Bus', 'in der Küche'])
    ]),
    ReadingPassage('Ben trägt einen Ball in den Hof.', [
      ReadingCheck('Was trägt Ben?', 'einen Ball', ['einen Korb', 'ein Buch']),
      ReadingCheck(
          'Wohin trägt Ben den Ball?', 'in den Hof', ['in den Wald', 'ins Bad'])
    ]),
    ReadingPassage('Oma sitzt auf einer Bank. Neben ihr liegt ein Hut.', [
      ReadingCheck('Wo sitzt Oma?', 'auf einer Bank',
          ['auf dem Boden', 'auf einem Bett']),
      ReadingCheck(
          'Was liegt neben Oma?', 'ein Hut', ['ein Schuh', 'ein Apfel'])
    ]),
    ReadingPassage('Der Hund schläft unter dem Tisch.', [
      ReadingCheck(
          'Welches Tier schläft?', 'der Hund', ['die Katze', 'die Maus']),
      ReadingCheck('Wo schläft der Hund?', 'unter dem Tisch',
          ['auf dem Tisch', 'neben der Tür'])
    ]),
    ReadingPassage('Ali legt zwei Äpfel in den Korb.', [
      ReadingCheck('Was legt Ali in den Korb?', 'Äpfel', ['Birnen', 'Nüsse']),
      ReadingCheck('Wie viele Äpfel sind es?', 'zwei', ['drei', 'vier'])
    ]),
    ReadingPassage('Lea baut im Sand einen Turm.', [
      ReadingCheck('Was baut Lea?', 'einen Turm', ['ein Boot', 'eine Brücke']),
      ReadingCheck('Womit baut Lea?', 'mit Sand', ['mit Holz', 'mit Schnee'])
    ]),
    ReadingPassage('Die Katze trinkt Wasser aus einer Schale.', [
      ReadingCheck('Was trinkt die Katze?', 'Wasser', ['Saft', 'Tee']),
      ReadingCheck('Woraus trinkt die Katze?', 'aus einer Schale',
          ['aus einem Glas', 'aus einer Flasche'])
    ]),
    ReadingPassage('Im Baum sitzt ein Vogel. Er singt.', [
      ReadingCheck(
          'Wo sitzt der Vogel?', 'im Baum', ['im Gras', 'auf dem Tisch']),
      ReadingCheck(
          'Was macht der Vogel?', 'Er singt.', ['Er schläft.', 'Er schwimmt.'])
    ]),
    ReadingPassage('Lumo zieht seine blauen Schuhe an.', [
      ReadingCheck('Was zieht Lumo an?', 'Schuhe', ['einen Hut', 'Handschuhe']),
      ReadingCheck('Welche Farbe haben die Schuhe?', 'blau', ['rot', 'grün'])
    ]),
    ReadingPassage('Mia gießt die Blume mit einer Kanne.', [
      ReadingCheck('Was gießt Mia?', 'die Blume', ['den Ball', 'das Buch']),
      ReadingCheck('Womit gießt Mia?', 'mit einer Kanne',
          ['mit einem Besen', 'mit einem Stift'])
    ]),
    ReadingPassage('Ben fährt mit dem Rad zur Schule.', [
      ReadingCheck(
          'Womit fährt Ben?', 'mit dem Rad', ['mit dem Bus', 'mit dem Zug']),
      ReadingCheck('Wohin fährt Ben?', 'zur Schule', ['zum See', 'zum Markt'])
    ]),
  ],
  2: [
    ReadingPassage('Es regnet. Mia nimmt ihren Schirm und geht zur Bücherei.', [
      ReadingCheck('Warum nimmt Mia den Schirm?', 'Weil es regnet.',
          ['Weil die Sonne scheint.', 'Weil sie schlafen geht.']),
      ReadingCheck('Wohin geht Mia?', 'zur Bücherei',
          ['zum Schwimmbad', 'zum Spielplatz'])
    ]),
    ReadingPassage(
        'Lumo sucht den Ball. Erst schaut er unter das Bett. Dann findet er ihn hinter der Tür.',
        [
          ReadingCheck('Wo findet Lumo den Ball?', 'hinter der Tür',
              ['unter dem Bett', 'im Schrank']),
          ReadingCheck('Wo sucht Lumo zuerst?', 'unter dem Bett',
              ['hinter der Tür', 'auf dem Tisch'])
        ]),
    ReadingPassage(
        'Ben hat Hunger. Er wäscht einen Apfel und isst ihn in der Pause.', [
      ReadingCheck('Warum isst Ben?', 'Er hat Hunger.',
          ['Er ist müde.', 'Er sucht seinen Stift.']),
      ReadingCheck('Was macht Ben vor dem Essen?', 'Er wäscht den Apfel.',
          ['Er legt ihn ins Bett.', 'Er malt ihn an.'])
    ]),
    ReadingPassage(
        'Oma pflanzt eine Blume. Danach gießt sie die Erde. Am Abend stellt sie die Kanne zurück.',
        [
          ReadingCheck(
              'Was macht Oma nach dem Pflanzen?',
              'Sie gießt die Erde.',
              ['Sie liest ein Buch.', 'Sie schneidet die Blume ab.']),
          ReadingCheck('Wann stellt Oma die Kanne zurück?', 'am Abend',
              ['am Morgen', 'zu Mittag'])
        ]),
    ReadingPassage(
        'Ali packt ein Heft und einen Stift ein. Das Buch lässt er zu Hause, weil er es heute nicht braucht.',
        [
          ReadingCheck(
              'Was lässt Ali zu Hause?', 'das Buch', ['das Heft', 'den Stift']),
          ReadingCheck(
              'Warum bleibt das Buch zu Hause?',
              'Ali braucht es heute nicht.',
              ['Das Buch ist verschwunden.', 'Ali hat keine Tasche.'])
        ]),
    ReadingPassage(
        'Lea will draußen malen. Der Wind weht das Papier weg. Lea malt deshalb in der Küche weiter.',
        [
          ReadingCheck(
              'Warum wechselt Lea den Ort?',
              'Der Wind weht das Papier weg.',
              ['Die Farben sind leer.', 'Die Sonne ist zu hell.']),
          ReadingCheck(
              'Wo malt Lea weiter?', 'in der Küche', ['im Hof', 'im Wald'])
        ]),
    ReadingPassage(
        'Lumo und Mia backen. Mia wiegt das Mehl ab. Lumo rührt danach den Teig.',
        [
          ReadingCheck('Wer wiegt das Mehl ab?', 'Mia', ['Lumo', 'Ben']),
          ReadingCheck('Was macht Lumo nach dem Abwiegen?',
              'Er rührt den Teig.', ['Er kauft Mehl.', 'Er deckt das Bett zu.'])
        ]),
    ReadingPassage(
        'Der Bus hält. Ben lässt zuerst die Menschen aussteigen. Dann steigt er ein.',
        [
          ReadingCheck('Was macht Ben zuerst?', 'Er lässt Menschen aussteigen.',
              ['Er drängelt hinein.', 'Er steigt auf das Dach.']),
          ReadingCheck(
              'Wann steigt Ben ein?',
              'nach dem Aussteigen der anderen',
              ['bevor der Bus hält', 'während der Bus fährt'])
        ]),
    ReadingPassage(
        'Mia hat zwei Buntstifte. Ali hat keinen. Mia gibt Ali einen ihrer Stifte.',
        [
          ReadingCheck('Wer bekommt einen Stift?', 'Ali', ['Ben', 'Lumo']),
          ReadingCheck('Was tut Mia?', 'Sie teilt ihre Stifte.',
              ['Sie versteckt beide Stifte.', 'Sie wirft beide weg.'])
        ]),
    ReadingPassage(
        'Im Garten steht ein leerer Blumentopf. Lea füllt Erde hinein und setzt einen Samen ein.',
        [
          ReadingCheck(
              'Was füllt Lea zuerst in den Topf?', 'Erde', ['Steine', 'Saft']),
          ReadingCheck('Was setzt Lea in die Erde?', 'einen Samen',
              ['einen Stift', 'einen Ball'])
        ]),
    ReadingPassage(
        'Lumo leiht ein Buch aus. Er liest es am Wochenende. Am Montag bringt er es zurück.',
        [
          ReadingCheck('Wann liest Lumo das Buch?', 'am Wochenende',
              ['am Montag in der Bücherei', 'vor dem Ausleihen']),
          ReadingCheck(
              'Was macht Lumo am Montag?',
              'Er bringt das Buch zurück.',
              ['Er leiht zuerst das Buch aus.', 'Er verliert das Buch.'])
        ]),
    ReadingPassage(
        'Ben findet einen Handschuh im Hof. Er gibt ihn der Lehrerin, damit der Besitzer ihn wiederbekommt.',
        [
          ReadingCheck('Was findet Ben?', 'einen Handschuh',
              ['eine Mütze', 'eine Tasche']),
          ReadingCheck(
              'Warum gibt Ben ihn der Lehrerin?',
              'Der Besitzer soll ihn zurückbekommen.',
              ['Ben will ihn verstecken.', 'Die Lehrerin soll ihn wegwerfen.'])
        ]),
  ],
  3: [
    ReadingPassage(
        'Auf dem Ausflug vergisst Mia ihre Trinkflasche. Ben hat genug Wasser dabei und bietet ihr etwas an. Beide füllen Mias Becher.',
        [
          ReadingCheck('Wie hilft Ben?', 'Er teilt sein Wasser.',
              ['Er versteckt seine Flasche.', 'Er geht ohne Mia weiter.']),
          ReadingCheck('Was fehlte Mia?', 'ihre Trinkflasche',
              ['ihre Jause', 'ihre Schuhe'])
        ]),
    ReadingPassage(
        'Am Morgen ist der Schulweg glatt. Lumo nimmt kleine Schritte und hält sich am Geländer fest. So kommt er sicher zur Schule.',
        [
          ReadingCheck('Warum geht Lumo vorsichtig?', 'Der Weg ist glatt.',
              ['Er sucht einen Ball.', 'Er zählt die Fenster.']),
          ReadingCheck('Was hilft Lumo neben den kleinen Schritten?',
              'das Geländer', ['ein Buch', 'ein Regenschirm'])
        ]),
    ReadingPassage(
        'Die Erde im Blumentopf ist trocken. Die Blätter hängen herab. Lea gießt vorsichtig und beobachtet am nächsten Tag wieder aufrechte Blätter.',
        [
          ReadingCheck(
              'Was brauchte die Pflanze?', 'Wasser', ['Musik', 'Steine']),
          ReadingCheck(
              'Woran erkennt Lea die Veränderung?',
              'Die Blätter stehen wieder aufrecht.',
              ['Die Blätter fehlen.', 'Der Topf ist verschwunden.'])
        ]),
    ReadingPassage(
        'Im Bus sind alle Sitze besetzt. Eine Frau steigt mit einem verletzten Bein ein. Mia bietet ihr ihren Sitz an und hält sich im Stehen fest.',
        [
          ReadingCheck(
              'Warum bietet Mia den Sitz an?',
              'Die Frau hat ein verletztes Bein.',
              ['Mia will aussteigen.', 'Der Sitz ist kaputt.']),
          ReadingCheck(
              'Wie fährt Mia danach sicher mit?',
              'Sie hält sich fest.',
              ['Sie läuft im Bus herum.', 'Sie steht auf einem Sitz.'])
        ]),
    ReadingPassage(
        'Für ein Experiment stellt Ben zwei gleiche Becher an denselben Ort. Einer enthält mehr Wasser. Nach einer Woche vergleicht er die Wasserstände.',
        [
          ReadingCheck('Was ist am Anfang verschieden?', 'die Wassermenge',
              ['die Becherform', 'der Standort']),
          ReadingCheck('Was vergleicht Ben am Ende?', 'die Wasserstände',
              ['die Farben seiner Stifte', 'die Größe des Tisches'])
        ]),
    ReadingPassage(
        'Lumo liest eine Wegbeschreibung: zuerst bis zur Brücke, dort links, dann am Teich vorbei. Hinter dem Teich liegt der Spielplatz.',
        [
          ReadingCheck('Wo soll Lumo links abbiegen?', 'an der Brücke',
              ['am Spielplatz', 'vor seiner Haustür']),
          ReadingCheck('Was erreicht Lumo nach dem Teich?', 'den Spielplatz',
              ['die Schule', 'den Bahnhof'])
        ]),
    ReadingPassage(
        'Lea findet beim Radfahren eine kaputte Lampe. Sie sagt einem Erwachsenen Bescheid und fährt vorerst nur bei Tageslicht. Die Lampe wird repariert.',
        [
          ReadingCheck('Was lässt Lea reparieren?', 'die Lampe',
              ['den Sattel', 'die Klingel']),
          ReadingCheck(
              'Was macht Lea bis zur Reparatur?',
              'Sie fährt nur bei Tageslicht.',
              ['Sie fährt ohne Licht in der Nacht.', 'Sie versteckt das Rad.'])
        ]),
    ReadingPassage(
        'Die Klasse sammelt Papier getrennt. Stark verschmutzte Jausenservietten kommen in den Restmüll. Saubere Zeichnungen landen beim Altpapier.',
        [
          ReadingCheck(
              'Was kommt laut Text ins Altpapier?',
              'saubere Zeichnungen',
              ['stark verschmutzte Servietten', 'Bananenschalen']),
          ReadingCheck('Warum braucht die Klasse zwei Behälter?',
              'Sie trennt sauberes Papier von Restmüll.', [
            'Alle Abfälle sind gleich.',
            'Papier darf nie gesammelt werden.'
          ])
        ]),
    ReadingPassage(
        'Am Markt vergleicht Ali zwei Preise für gleich große Körbe Äpfel. Er kauft den günstigeren Korb. Den Kassenbon steckt er in die Tasche.',
        [
          ReadingCheck('Was vergleicht Ali?', 'die Preise',
              ['die Busfahrpläne', 'die Namen der Straßen']),
          ReadingCheck('Welchen Korb wählt Ali?', 'den günstigeren',
              ['immer den teureren', 'einen leeren Korb'])
        ]),
    ReadingPassage(
        'Ben möchte wissen, wie ein Regenwurm lebt. Er beobachtet ihn in feuchter Erde und liest in einem Tierbuch nach. Danach setzt er ihn vorsichtig zurück.',
        [
          ReadingCheck(
              'Wie sammelt Ben Informationen?',
              'Er beobachtet und liest nach.',
              ['Er rät nur.', 'Er fragt einen Spielwürfel.']),
          ReadingCheck(
              'Was macht Ben zuletzt?',
              'Er setzt den Regenwurm zurück.',
              ['Er legt ihn auf heißen Asphalt.', 'Er nimmt ihm die Erde weg.'])
        ]),
    ReadingPassage(
        'Für das Klassenfest übernimmt Mia die Einladung, Ali die Musik und Lumo die Spiele. Am Freitag prüfen sie gemeinsam, ob alles bereit ist.',
        [
          ReadingCheck(
              'Wer kümmert sich um die Musik?', 'Ali', ['Mia', 'Lumo']),
          ReadingCheck('Was tun alle am Freitag?',
              'Sie prüfen gemeinsam die Vorbereitung.', [
            'Sie verteilen erstmals die Aufgaben.',
            'Sie sagen das Fest ohne Prüfung ab.'
          ])
        ]),
    ReadingPassage(
        'Die Bücherei schließt heute früher. Lea sieht den Hinweis an der Tür. Sie holt ihr Buch gleich nach der Schule statt erst am Abend.',
        [
          ReadingCheck(
              'Warum ändert Lea ihren Plan?',
              'Die Bücherei schließt früher.',
              ['Ihr Buch ist nass.', 'Die Schule beginnt am Abend.']),
          ReadingCheck(
              'Wo findet Lea die Information?',
              'an der Tür der Bücherei',
              ['in ihrer Jausenbox', 'auf dem Fußballplatz'])
        ]),
  ],
  4: [
    ReadingPassage(
        'Die Klasse will draußen lesen. Als dunkle Wolken aufziehen, schlägt Mia die Bücherei vor. Dort können alle trocken weiterlesen, ohne die Lesestunde abzusagen.',
        [
          ReadingCheck('Warum ist Mias Vorschlag sinnvoll?',
              'Alle können geschützt weiterlesen.', [
            'In der Bücherei gibt es keine Bücher.',
            'Draußen ist Lesen immer verboten.'
          ]),
          ReadingCheck(
              'Was bleibt trotz des Ortswechsels erhalten?',
              'die gemeinsame Lesestunde',
              ['der Aufenthalt im Regen', 'das Fußballspiel'])
        ]),
    ReadingPassage(
        'Lumo findet zwei widersprüchliche Angaben über ein Tier. Er vergleicht beide mit einem aktuellen Sachbuch. Die dort beschriebene Beobachtung unterstützt nur eine der Angaben.',
        [
          ReadingCheck('Wie prüft Lumo den Widerspruch?',
              'Er verwendet eine weitere Quelle.', [
            'Er glaubt automatisch der ersten Angabe.',
            'Er würfelt die Lösung.'
          ]),
          ReadingCheck(
              'Was stärkt eine Angabe im Text?',
              'eine passende Beobachtung',
              ['ihre größere Schrift', 'ihr erster Platz'])
        ]),
    ReadingPassage(
        'Ben gießt täglich, obwohl die Erde noch nass ist. Die Wurzeln seiner Pflanze faulen. Er beschließt, künftig zuerst die Feuchtigkeit zu prüfen und nur bei Bedarf zu gießen.',
        [
          ReadingCheck('Was lernt Ben?', 'Wasser muss zum Bedarf passen.', [
            'Jede Pflanze braucht ständig mehr Wasser.',
            'Erde soll immer im Wasser schwimmen.'
          ]),
          ReadingCheck(
              'Welche Ursache nennt der Text für die faulenden Wurzeln?',
              'dauerhaft nasse Erde',
              ['zu wenig Licht am Mittag', 'ein größerer Blumentopf'])
        ]),
    ReadingPassage(
        'Für das Fest verteilt die Klasse die Aufgaben. Mia gestaltet Plakate, Ben bereitet Spiele vor und Lumo prüft den Zeitplan. Ein fehlendes Plakat wird vor dem Fest noch fertig.',
        [
          ReadingCheck('Was hilft bei der Vorbereitung?',
              'Die Aufgaben sind aufgeteilt.', [
            'Alle tun nur dieselbe Arbeit.',
            'Niemand spricht miteinander.'
          ]),
          ReadingCheck('Wer prüft den Zeitplan?', 'Lumo', ['Mia', 'Ben'])
        ]),
    ReadingPassage(
        'Eine Werbung verspricht: Diese Flasche ist die beste. Ali sucht nach Angaben zu Material, Größe und Haltbarkeit. Ohne solche Informationen kann er die Behauptung nicht prüfen.',
        [
          ReadingCheck('Was fehlt Ali für einen Vergleich?', 'prüfbare Angaben',
              ['eine größere Überschrift', 'eine weitere Werbefarbe']),
          ReadingCheck(
              'Welche Aussage ist im Text nur eine Werbebehauptung?',
              'Diese Flasche ist die beste.',
              ['Ali sucht Informationen.', 'Die Angaben fehlen.'])
        ]),
    ReadingPassage(
        'Zwei Gruppen untersuchen das Wachstum von Bohnen. Sie verwenden gleiche Töpfe, gleich viel Wasser und denselben Samen. Nur die Lichtmenge ist verschieden.',
        [
          ReadingCheck('Welche Bedingung wird verändert?', 'die Lichtmenge',
              ['die Topfgröße', 'die Wassermenge']),
          ReadingCheck('Warum halten die Gruppen anderes gleich?',
              'Um den Einfluss des Lichts zu vergleichen.', [
            'Weil Pflanzen kein Wasser brauchen.',
            'Damit alle Pflanzen sofort gleich wachsen.'
          ])
        ]),
    ReadingPassage(
        'Im Fahrplan steht Abfahrt 14:10 und Ankunft 14:35. Mia ist um 14:05 an der Haltestelle. Sie hat also noch fünf Minuten bis zur planmäßigen Abfahrt.',
        [
          ReadingCheck(
              'Wann soll der Bus ankommen?', '14:35', ['14:05', '14:10']),
          ReadingCheck(
              'Worauf beziehen sich die fünf Minuten?',
              'auf die Wartezeit bis zur Abfahrt',
              ['auf die ganze Fahrtdauer', 'auf die Zeit nach der Ankunft'])
        ]),
    ReadingPassage(
        'Die Gemeinde plant mehr Schatten am Spielplatz. Ein Vorschlag sieht Bäume vor, ein anderer ein Sonnensegel. Die Kinder vergleichen Wachstum, Platzbedarf und Pflege, bevor sie abstimmen.',
        [
          ReadingCheck('Was tun die Kinder vor der Abstimmung?',
              'Sie vergleichen mehrere Eigenschaften.', [
            'Sie wählen ohne Informationen.',
            'Sie bauen beide Vorschläge sofort.'
          ]),
          ReadingCheck('Welches Ziel haben beide Vorschläge?', 'mehr Schatten',
              ['mehr Autoverkehr', 'weniger Platz zum Spielen'])
        ]),
    ReadingPassage(
        'Ein Zeitungsbericht beschreibt Hochwasser nach starkem Regen. Eine Augenzeugin berichtet von einer überfluteten Straße. Diese Beobachtung sagt noch nichts darüber, wie jede Straße im Ort aussieht.',
        [
          ReadingCheck('Welche Aussage ist durch die Beobachtung belegt?',
              'Eine Straße war überflutet.', [
            'Alle Straßen waren überflutet.',
            'Im ganzen Land war Hochwasser.'
          ]),
          ReadingCheck(
              'Warum ist eine Verallgemeinerung auf alle Straßen unsicher?',
              'Es wurde nur eine Straße beschrieben.', [
            'Die Augenzeugin nennt Regen.',
            'Straßen können nicht nass werden.'
          ])
        ]),
    ReadingPassage(
        'Beim Lesewettbewerb zählt zuerst die Verständlichkeit, dann der Ausdruck. Geschwindigkeit allein entscheidet nicht. Ben liest etwas langsamer und macht sinnvolle Pausen.',
        [
          ReadingCheck('Was zählt zuerst?', 'die Verständlichkeit',
              ['die Geschwindigkeit', 'die Lautstärke der Musik']),
          ReadingCheck(
              'Wie unterstützt Ben verständliches Lesen?',
              'Er macht sinnvolle Pausen.',
              ['Er überspringt Satzzeichen.', 'Er liest immer schneller.'])
        ]),
    ReadingPassage(
        'Ein Museum zeigt ein altes Waschbrett und eine moderne Waschmaschine. Lea vergleicht die Arbeit von Hand mit dem elektrisch betriebenen Gerät. Beide dienen dem Reinigen von Wäsche.',
        [
          ReadingCheck(
              'Was haben beide Gegenstände gemeinsam?',
              'Sie helfen beim Reinigen von Wäsche.',
              ['Beide benötigen Strom.', 'Beide waschen völlig ohne Arbeit.']),
          ReadingCheck(
              'Welchen Unterschied nennt der Text?',
              'Handarbeit und elektrischer Betrieb',
              ['Sommer und Winter', 'Salzwasser und Süßwasser'])
        ]),
    ReadingPassage(
        'Die Klasse misst den Müll einer Woche und plant Mehrwegboxen. Eine Woche später misst sie erneut. Erst der Vergleich zeigt, ob die neue Maßnahme die Müllmenge verringert hat.',
        [
          ReadingCheck('Wie prüft die Klasse den Erfolg?',
              'Sie vergleicht zwei Messungen.', [
            'Sie betrachtet nur die Farbe der Boxen.',
            'Sie schätzt ohne Messung.'
          ]),
          ReadingCheck(
              'Welche Maßnahme wird untersucht?',
              'Mehrwegboxen verwenden',
              ['mehr Einwegverpackungen kaufen', 'den Müll nicht mehr sammeln'])
        ]),
  ],
};

const readingSequences = <List<String>>[
  ['Mia zieht Schuhe an.', 'Mia geht zur Schule.', 'Mia sitzt in der Klasse.'],
  [
    'Lumo holt ein Buch.',
    'Lumo liest das Buch.',
    'Lumo stellt das Buch zurück.'
  ],
  ['Oma wäscht den Apfel.', 'Oma schneidet den Apfel.', 'Oma isst ein Stück.'],
  [
    'Wir füllen Erde in einen Topf.',
    'Wir säen einen Samen.',
    'Eine Pflanze wächst.'
  ],
  [
    'Ben zieht seinen Helm an.',
    'Ben fährt mit dem Rad.',
    'Ben stellt das Rad ab.'
  ],
  ['Lea holt Papier.', 'Lea malt ein Bild.', 'Lea hängt das Bild auf.'],
  ['Ali deckt den Tisch.', 'Ali isst seine Jause.', 'Ali räumt den Tisch ab.'],
  [
    'Wir füllen einen Becher mit Wasser.',
    'Wir stellen ihn ins Gefrierfach.',
    'Das Wasser gefriert.'
  ],
  [
    'Lumo schreibt einen Brief.',
    'Lumo steckt ihn in ein Kuvert.',
    'Lumo wirft ihn in den Postkasten.'
  ],
  [
    'Mia packt ihre Tasche.',
    'Mia fährt zum Schwimmbad.',
    'Mia schwimmt im Becken.'
  ],
  [
    'Ben findet einen Riss im Reifen.',
    'Ein Erwachsener repariert den Reifen.',
    'Ben fährt wieder sicher.'
  ],
  [
    'Die Klasse sammelt Blätter.',
    'Die Klasse sortiert die Blätter.',
    'Die Klasse gestaltet ein Plakat.'
  ],
];
