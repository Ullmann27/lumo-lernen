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
    ReadingPassage('Lea baut aus Sand einen Turm.', [
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
        'Lea bemerkt beim Radfahren, dass ihre Lampe kaputt ist. Sie sagt einem Erwachsenen Bescheid und fährt vorerst nur bei Tageslicht. Die Lampe wird repariert.',
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
        'Am Markt vergleicht Ali zwei Preise für gleich große Körbe Äpfel. Er kauft den günstigeren Korb. Die Rechnung steckt er in die Tasche.',
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
        'Lumo liest in zwei Büchern etwas Verschiedenes über Igel. Darum schaut er in ein neues Tierlexikon. Dort steht, was Forscher beobachtet haben. Nur eines der beiden Bücher hat recht.',
        [
          ReadingCheck(
              'Wie findet Lumo heraus, welches Buch recht hat?',
              'Er schaut in einem dritten Buch nach.',
              ['Er glaubt einfach dem ersten Buch.', 'Er würfelt die Lösung.']),
          ReadingCheck(
              'Was steht im Tierlexikon?',
              'was Forscher beobachtet haben',
              ['welches Buch dicker ist', 'was Lumo sich wünscht'])
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
        'Eine Werbung sagt: Diese Trinkflasche ist die beste. Ali will wissen, woraus sie gemacht ist, wie viel hineinpasst und wie lange sie hält. Das steht aber nirgends. So kann Ali nicht prüfen, ob die Werbung stimmt.',
        [
          ReadingCheck(
              'Was möchte Ali über die Flasche wissen?',
              'woraus sie ist und wie lange sie hält',
              ['welche Farbe die Werbung hat', 'wie die Verkäuferin heißt']),
          ReadingCheck(
              'Welcher Satz ist nur Werbung?',
              'Diese Trinkflasche ist die beste.',
              ['Ali will mehr wissen.', 'Das steht nirgends.'])
        ]),
    ReadingPassage(
        'Zwei Gruppen untersuchen das Wachstum von Bohnen. Sie verwenden gleiche Töpfe, gleich viel Wasser und die gleichen Samen. Nur die Lichtmenge ist verschieden.',
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
        'Nach starkem Regen schreibt die Zeitung über ein Hochwasser. Eine Frau erzählt: „In meiner Straße stand das Wasser.“ Wie es in den anderen Straßen aussah, hat sie nicht gesehen.',
        [
          ReadingCheck(
              'Was wissen wir sicher?', 'Eine Straße stand unter Wasser.', [
            'Alle Straßen standen unter Wasser.',
            'Im ganzen Land war Hochwasser.'
          ]),
          ReadingCheck('Warum wissen wir nichts über die anderen Straßen?',
              'Die Frau hat nur ihre Straße gesehen.', [
            'Die Frau erzählt vom Regen.',
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

/// „Lesesinn“: Die Antwort steht nicht wörtlich im Text, das Kind muss aus
/// dem Gelesenen schließen (Fachprüfung 2026-11, D-M12).
const readingInferences = <int, List<ReadingPassage>>{
  1: [
    ReadingPassage('Ben gähnt. Seine Augen fallen zu.', [
      ReadingCheck('Wie fühlt sich Ben?', 'müde', ['wütend', 'lustig']),
      ReadingCheck('Was sollte Ben jetzt tun?', 'schlafen gehen',
          ['Fußball spielen', 'laut singen']),
    ]),
    ReadingPassage('Lea zieht die Haube und die Handschuhe an.', [
      ReadingCheck('Wie ist es draußen?', 'kalt', ['heiß', 'sonnig und warm']),
      ReadingCheck(
          'Was will Lea wohl tun?', 'hinausgehen', ['schlafen gehen', 'baden']),
    ]),
    ReadingPassage(
        'Lumo hat ein Geschenk. Auf dem Tisch steht eine Torte mit Kerzen.', [
      ReadingCheck(
          'Was feiert Lumo?', 'seinen Geburtstag', ['Ostern', 'den Muttertag']),
      ReadingCheck('Was macht Lumo wohl gleich?', 'die Kerzen ausblasen',
          ['in die Schule gehen', 'schlafen gehen']),
    ]),
    ReadingPassage('Der Hund bellt. Es läutet an der Tür.', [
      ReadingCheck('Was ist wohl los?', 'Jemand kommt zu Besuch.',
          ['Der Hund schläft.', 'Alle sind weggefahren.']),
      ReadingCheck('Warum bellt der Hund?', 'Er hört die Klingel.',
          ['Er schläft tief.', 'Er frisst gerade.']),
    ]),
    ReadingPassage('Ali isst schnell seine Jause. Dann holt er den Ball.', [
      ReadingCheck('Was will Ali jetzt tun?', 'spielen', ['schlafen', 'lesen']),
      ReadingCheck('Wann holt Ali den Ball?', 'nach der Jause',
          ['vor der Jause', 'in der Nacht']),
    ]),
    ReadingPassage('Oma hat nasse Schuhe und einen nassen Mantel.', [
      ReadingCheck('Wie war das Wetter draußen?', 'Es hat geregnet.',
          ['Es war heiß.', 'Es war trocken.']),
      ReadingCheck('Was hätte Oma gebraucht?', 'einen Regenschirm',
          ['eine Sonnenbrille', 'einen Schlitten']),
    ]),
    ReadingPassage('Mia weint. Ihr Eis liegt auf dem Boden.', [
      ReadingCheck('Wie fühlt sich Mia?', 'traurig', ['fröhlich', 'stolz']),
      ReadingCheck('Was ist passiert?', 'Das Eis ist hinuntergefallen.',
          ['Mia hat das Eis aufgegessen.', 'Mia hat ein neues Eis bekommen.']),
    ]),
    ReadingPassage(
        'Lumo trägt seine Schultasche. Er hat eine Jause und Hefte dabei.', [
      ReadingCheck(
          'Wohin geht Lumo?', 'in die Schule', ['ins Freibad', 'ins Bett']),
      ReadingCheck('Wann ist das wohl?', 'am Morgen',
          ['in der Nacht', 'am späten Abend']),
    ]),
    ReadingPassage('Der Teller ist leer. Ben reibt sich den Bauch und lacht.', [
      ReadingCheck(
          'Wie hat Ben das Essen gefunden?', 'gut', ['grauslich', 'zu scharf']),
      ReadingCheck('Ist Ben noch hungrig?', 'Nein, er ist satt.',
          ['Ja, sehr hungrig.', 'Er hat nichts gegessen.']),
    ]),
    ReadingPassage('Die Katze sitzt vor der leeren Schüssel und miaut.', [
      ReadingCheck('Was will die Katze?', 'Futter', ['einen Ball', 'schlafen']),
      ReadingCheck('Wie fühlt sich die Katze?', 'hungrig', ['satt', 'müde']),
    ]),
    ReadingPassage('Papa holt den Schlitten und die dicke Jacke.', [
      ReadingCheck('Wie ist es draußen?', 'Es liegt Schnee.',
          ['Es ist heiß.', 'Es ist Sommer.']),
      ReadingCheck(
          'Was will Papa machen?', 'rodeln', ['schwimmen', 'Rad fahren']),
    ]),
    ReadingPassage('Lea hat Farbe an den Händen. Neben ihr liegt ein Pinsel.', [
      ReadingCheck('Was hat Lea gemacht?', 'gemalt', ['gekocht', 'geschlafen']),
      ReadingCheck('Was braucht Lea jetzt?', 'Wasser und Seife',
          ['einen Ball', 'eine Haube']),
    ]),
  ],
  2: [
    ReadingPassage(
        'Es ist heiß. Die Kinder haben Ferien und gehen ins Freibad.', [
      ReadingCheck('Welche Jahreszeit ist es?', 'Sommer', ['Winter', 'Herbst']),
      ReadingCheck('Was nehmen die Kinder wohl mit?', 'eine Badehose',
          ['einen Schlitten', 'eine Haube']),
    ]),
    ReadingPassage(
        'Mia kommt aus der Schule. Sie riecht Palatschinken und läuft schnell in die Küche.',
        [
          ReadingCheck('Warum läuft Mia in die Küche?', 'Sie hat Hunger.',
              ['Sie ist müde.', 'Sie sucht ihre Schultasche.']),
          ReadingCheck('Woran merkt Mia, dass es Essen gibt?', 'am Geruch',
              ['an einem Brief', 'am Fernseher']),
        ]),
    ReadingPassage(
        'Ben sucht unter dem Bett und im Kasten. Endlich findet er seinen Schlüssel.',
        [
          ReadingCheck(
              'Wie fühlt sich Ben am Ende?', 'froh', ['traurig', 'wütend']),
          ReadingCheck('Wie hat sich Ben vorher gefühlt?', 'Er war besorgt.',
              ['Er war fröhlich.', 'Er war satt.']),
        ]),
    ReadingPassage(
        'Die Blätter sind gelb und braun. Sie fallen von den Bäumen.', [
      ReadingCheck(
          'Welche Jahreszeit ist es?', 'Herbst', ['Frühling', 'Sommer']),
      ReadingCheck('Was braucht man bald im Garten?', 'einen Rechen',
          ['eine Badehose', 'einen Sonnenschirm']),
    ]),
    ReadingPassage(
        'Lea hält sich die Ohren zu. Draußen fährt ein Feuerwehrauto mit Sirene vorbei.',
        [
          ReadingCheck('Warum hält Lea sich die Ohren zu?',
              'Die Sirene ist laut.', ['Sie hört Musik.', 'Sie hat Hunger.']),
          ReadingCheck('Wohin fährt das Feuerwehrauto wohl?',
              'zu einem Einsatz', ['in die Waschanlage', 'zum Einkaufen']),
        ]),
    ReadingPassage('Lumo gießt die Blumen jeden Tag. Jetzt blühen sie bunt.', [
      ReadingCheck('Warum blühen die Blumen so schön?', 'Lumo pflegt sie gut.',
          ['Lumo hat sie vergessen.', 'Es war immer dunkel.']),
      ReadingCheck('Was gibt Lumo den Blumen?', 'Wasser', ['Saft', 'Sand']),
    ]),
    ReadingPassage(
        'Die Kinder ziehen Gummistiefel an. Sie springen in jede Lacke.', [
      ReadingCheck('Wie war das Wetter vorher?', 'Es hat geregnet.', [
        'Es war lange heiß und trocken.',
        'Die Sonne hat die ganze Woche geschienen.'
      ]),
      ReadingCheck(
          'Wie fühlen sich die Kinder?', 'fröhlich', ['traurig', 'ängstlich']),
    ]),
    ReadingPassage(
        'Ali legt ein Buch, einen Teddy und seine Zahnbürste in den Rucksack. Heute schläft er bei Oma.',
        [
          ReadingCheck('Wie lange bleibt Ali bei Oma?', 'bis morgen',
              ['nur fünf Minuten', 'ein ganzes Jahr']),
          ReadingCheck(
              'Warum nimmt Ali die Zahnbürste mit?',
              'Er putzt bei Oma die Zähne.',
              ['Er will damit malen.', 'Er braucht sie zum Lesen.']),
        ]),
    ReadingPassage(
        'Lumo schaut aus dem Fenster. Die Straßenlampen leuchten, und am Himmel sind Sterne.',
        [
          ReadingCheck(
              'Wann ist das?', 'in der Nacht', ['am Mittag', 'am Vormittag']),
          ReadingCheck('Was macht Lumo wohl bald?', 'schlafen gehen',
              ['in die Schule gehen', 'frühstücken']),
        ]),
    ReadingPassage('Emma hat einen Gips am Arm. Sie kann heute nicht turnen.', [
      ReadingCheck('Was ist mit Emmas Arm?', 'Er ist verletzt.',
          ['Er ist schmutzig.', 'Er ist ganz gesund.']),
      ReadingCheck('Was kann Emma in der Turnstunde tun?', 'zuschauen',
          ['am Reck turnen', 'einen Handstand machen']),
    ]),
    ReadingPassage(
        'Am Tisch sitzen viele Gäste. Auf der Torte steht „90“. Uroma lacht.', [
      ReadingCheck('Was wird gefeiert?', 'Uromas Geburtstag',
          ['Lumos erster Schultag', 'Weihnachten']),
      ReadingCheck('Wie alt wird Uroma?', '90 Jahre', ['9 Jahre', '19 Jahre']),
    ]),
    ReadingPassage(
        'Ben und Mama stehen an der Kreuzung. Die Fußgängerampel ist rot.', [
      ReadingCheck('Was müssen die beiden jetzt tun?', 'warten',
          ['schnell laufen', 'über die Straße rennen']),
      ReadingCheck('Wann dürfen sie gehen?', 'wenn die Ampel grün ist',
          ['sofort', 'wenn ein Auto kommt']),
    ]),
  ],
  3: [
    ReadingPassage(
        'Ali steht an der Haltestelle und schaut auf die Uhr. Er tritt von einem Fuß auf den anderen. Der Bus kommt nicht.',
        [
          ReadingCheck(
              'Wie fühlt sich Ali?', 'ungeduldig', ['fröhlich', 'stolz']),
          ReadingCheck('Worauf wartet Ali?', 'auf den Bus',
              ['auf den Postler', 'auf das Mittagessen']),
        ]),
    ReadingPassage(
        'Mia hat ein Pflaster am Knie. Ihr Rad steht mit einem verbogenen Lenker im Hof.',
        [
          ReadingCheck(
              'Was ist Mia wohl passiert?',
              'Sie ist mit dem Rad gestürzt.',
              ['Sie hat ein Rad gewonnen.', 'Sie hat ein Bild gemalt.']),
          ReadingCheck(
              'Was muss mit dem Rad geschehen?',
              'Es muss repariert werden.',
              ['Es muss gewaschen werden.', 'Es braucht eine Klingel.']),
        ]),
    ReadingPassage(
        'Der Himmel wird dunkelgrau. Der Wind wird stärker. Lumo holt schnell die Wäsche herein.',
        [
          ReadingCheck(
              'Was erwartet Lumo?', 'Regen', ['Sonnenschein', 'große Hitze']),
          ReadingCheck(
              'Warum holt Lumo die Wäsche herein?',
              'Sie soll nicht nass werden.',
              ['Sie ist schmutzig.', 'Er will sie verschenken.']),
        ]),
    ReadingPassage(
        'Ben hat eine Woche nicht Flöte geübt. Beim Vorspielen macht er viele Fehler.',
        [
          ReadingCheck('Warum macht Ben Fehler?', 'Er hat zu wenig geübt.',
              ['Er hat zu viel geübt.', 'Er spielt schon sehr lange Flöte.']),
          ReadingCheck(
              'Was sollte Ben beim nächsten Mal tun?',
              'jeden Tag ein bisschen üben',
              ['gar nicht mehr üben', 'die Flöte verstecken']),
        ]),
    ReadingPassage(
        'Oma stellt einen Kübel auf den Dachboden. Bei jedem Regen tropft Wasser hinein.',
        [
          ReadingCheck('Was ist mit dem Dach los?', 'Es hat ein Loch.',
              ['Es ist ganz neu.', 'Es ist aus Glas.']),
          ReadingCheck('Wozu dient der Kübel?', 'Er fängt die Tropfen auf.',
              ['Er ist ein Blumentopf.', 'Darin liegt Spielzeug.']),
        ]),
    ReadingPassage(
        'Im Klassenzimmer ist es ganz still. Alle Kinder schreiben. Die Lehrerin geht leise durch die Reihen.',
        [
          ReadingCheck(
              'Was machen die Kinder wohl gerade?',
              'Sie schreiben einen Test.',
              ['Sie haben Turnen.', 'Sie haben große Pause.']),
          ReadingCheck(
              'Warum geht die Lehrerin leise?',
              'Sie will die Kinder nicht stören.',
              ['Sie will die Kinder aufwecken.', 'Sie spielt Fangen.']),
        ]),
    ReadingPassage(
        'Felix steht vor dem Klettergerüst. Seine Hände zittern. Er schaut nach oben und atmet tief durch.',
        [
          ReadingCheck('Wie fühlt sich Felix?', 'Er hat ein bisschen Angst.',
              ['Er ist sehr müde.', 'Er ist wütend.']),
          ReadingCheck('Was hat Felix wohl vor?', 'Er will hinaufklettern.',
              ['Er will nach Hause gehen.', 'Er will schlafen.']),
        ]),
    ReadingPassage(
        'Am Abend gehen viele Kinder mit leuchtenden Laternen durch den Park. Sie singen „Ich geh mit meiner Laterne“.',
        [
          ReadingCheck('Welches Fest feiern sie wohl?', 'das Martinsfest',
              ['Ostern', 'Fasching']),
          ReadingCheck('Warum brauchen sie Laternen?', 'Es ist schon dunkel.',
              ['Es ist heiß.', 'Es regnet stark.']),
        ]),
    ReadingPassage(
        'Der Hase im Hof versteckt sich unter einem Busch. Über ihm kreist ein großer Vogel.',
        [
          ReadingCheck(
              'Warum versteckt sich der Hase?',
              'Er hat Angst vor dem Vogel.',
              ['Er will mit dem Vogel spielen.', 'Ihm ist zu heiß.']),
          ReadingCheck('Was für ein Vogel ist das wohl?', 'ein Greifvogel',
              ['ein Huhn', 'ein Spatz']),
        ]),
    ReadingPassage(
        'Lukas schaut in sein Sparschwein. Es ist fast voll. Bald hat er genug Geld für ein neues Buch.',
        [
          ReadingCheck('Was hat Lukas gemacht?', 'Er hat lange gespart.',
              ['Er hat alles ausgegeben.', 'Er hat das Sparschwein verloren.']),
          ReadingCheck('Was will Lukas bald tun?', 'ein Buch kaufen',
              ['ins Kino gehen', 'ein Fahrrad kaufen']),
        ]),
    ReadingPassage(
        'In der Früh ist die Windschutzscheibe weiß. Papa kratzt sie frei.', [
      ReadingCheck('Wie kalt war es in der Nacht?', 'unter 0 Grad',
          ['sehr heiß', 'genau 20 Grad']),
      ReadingCheck('Was ist auf der Scheibe?', 'Eis', ['Regenwasser', 'Staub']),
    ]),
    ReadingPassage(
        'Nina hört ein leises Piepsen im Gebüsch. Unter einem Blatt sitzt ein kleiner Vogel ohne Federn.',
        [
          ReadingCheck('Was hat Nina gefunden?', 'einen jungen Vogel',
              ['einen alten Vogel', 'eine Maus']),
          ReadingCheck('Was sollte Nina tun?', 'einen Erwachsenen holen', [
            'den Vogel mit nach Hause nehmen',
            'den Vogel in den Teich setzen'
          ]),
        ]),
  ],
  4: [
    ReadingPassage(
        'Lena packt Sonnencreme, Badetuch und Taucherbrille ein. Sie freut sich schon auf das Wasser.',
        [
          ReadingCheck('Wohin fährt Lena wohl?', 'an einen See',
              ['in die Bücherei', 'auf eine Skipiste']),
          ReadingCheck('Wie ist das Wetter wohl?', 'sonnig und warm',
              ['kalt und verschneit', 'stürmisch und eisig']),
        ]),
    ReadingPassage(
        'Jonas hat die Hausübung vergessen. Als die Lehrerin fragt, schaut er auf den Boden.',
        [
          ReadingCheck('Wie fühlt sich Jonas?', 'Er schämt sich.',
              ['Er ist stolz.', 'Er ist begeistert.']),
          ReadingCheck('Was sollte Jonas tun?', 'es ehrlich sagen',
              ['die Hausübung verstecken', 'einfach weglaufen']),
        ]),
    ReadingPassage(
        'Im frischen Schnee sind kleine Spuren. Sie führen direkt zum Futterhaus.',
        [
          ReadingCheck(
              'Was zeigen die Spuren?',
              'Ein Tier war beim Futterhaus.',
              ['Der Schnee ist schon geschmolzen.', 'Niemand war dort.']),
          ReadingCheck('Warum kommt das Tier wohl zum Futterhaus?',
              'Es sucht Futter.', ['Es will sich sonnen.', 'Es will baden.']),
        ]),
    ReadingPassage(
        'Die Klasse sammelt Geld für das Tierheim. Am Ende ist die Dose so schwer, dass Emma sie mit beiden Händen trägt.',
        [
          ReadingCheck(
              'Was kann man daraus schließen?',
              'Es wurde viel gesammelt.',
              ['Die Dose ist leer.', 'Niemand hat etwas gegeben.']),
          ReadingCheck('Wem hilft das Geld?', 'den Tieren im Tierheim',
              ['der Lehrerin', 'einem Fußballverein']),
        ]),
    ReadingPassage(
        'Paul öffnet den Kühlschrank. Milch, Butter und Käse fehlen. Daneben liegt ein Einkaufszettel.',
        [
          ReadingCheck('Was muss die Familie bald tun?', 'einkaufen gehen',
              ['den Kühlschrank verkaufen', 'auf Urlaub fahren']),
          ReadingCheck(
              'Wozu ist der Einkaufszettel da?',
              'Darauf steht, was fehlt.',
              ['Darauf steht ein Witz.', 'Er ist ein Geburtstagsbrief.']),
        ]),
    ReadingPassage(
        'Am Morgen sind die Grashalme voller kleiner Tropfen. In der Nacht hat es nicht geregnet, und niemand hat gegossen.',
        [
          ReadingCheck('Woher kommen die Tropfen?', 'vom Tau',
              ['vom Regen in der Nacht', 'von der Gießkanne']),
          ReadingCheck('Wann sieht man Tau oft?', 'am frühen Morgen',
              ['zu Mittag', 'am Nachmittag']),
        ]),
    ReadingPassage(
        'Die Klasse 4b hat das Fußballturnier gewonnen. Alle jubeln, nur Tim sitzt still auf der Bank. Er war krank und durfte nicht mitspielen.',
        [
          ReadingCheck('Wie fühlt sich Tim wohl?', 'ein bisschen enttäuscht',
              ['sehr stolz auf sein Tor', 'wütend auf die Lehrerin']),
          ReadingCheck(
              'Was kann Tim beim nächsten Turnier tun?',
              'wieder mitspielen, wenn er gesund ist',
              ['nie mehr Fußball spielen', 'die anderen auslachen']),
        ]),
    ReadingPassage(
        'Opa sucht seine Brille überall. Lisa lacht und zeigt auf seinen Kopf.',
        [
          ReadingCheck('Wo ist die Brille?', 'auf Opas Kopf',
              ['in der Küche', 'unter dem Sofa']),
          ReadingCheck(
              'Warum lacht Lisa?',
              'Opa sucht etwas, das er schon trägt.',
              ['Opa erzählt einen Witz.', 'Lisa hat Geburtstag.']),
        ]),
    ReadingPassage(
        'Im Wald steht ein Baumstumpf mit vielen Ringen. Jonas zählt mehr als hundert.',
        [
          ReadingCheck('Was erfährt Jonas über den Baum?', 'Er war sehr alt.',
              ['Er war erst ein Jahr alt.', 'Er ist gestern gewachsen.']),
          ReadingCheck('Wofür steht ein Ring?', 'für ein Jahr',
              ['für einen Tag', 'für einen Monat']),
        ]),
    ReadingPassage(
        'Mara übt jeden Tag Kopfrechnen. Bei der Wiederholung hat sie alles richtig.',
        [
          ReadingCheck(
              'Warum hat Mara alles richtig?',
              'Sie hat regelmäßig geübt.',
              ['Sie hat nie geübt.', 'Sie hat die Wiederholung verpasst.']),
          ReadingCheck('Wie fühlt sich Mara wohl?', 'stolz',
              ['enttäuscht', 'verärgert']),
        ]),
    ReadingPassage(
        'Am Bahnsteig schauen alle auf die Anzeigetafel. Dort steht: „Zug 15 Minuten später“. Einige Leute seufzen.',
        [
          ReadingCheck('Was ist los?', 'Der Zug hat Verspätung.',
              ['Der Zug ist schon abgefahren.', 'Der Zug kommt zu früh.']),
          ReadingCheck('Warum seufzen die Leute?', 'Sie müssen länger warten.',
              ['Sie haben etwas gewonnen.', 'Sie sind schon angekommen.']),
        ]),
    ReadingPassage(
        'Lisa hat ihre Pflanze eine Woche lang in den dunklen Kasten gestellt. Jetzt sind die Blätter gelb und schlapp.',
        [
          ReadingCheck(
              'Warum sind die Blätter gelb?', 'Die Pflanze hatte kein Licht.', [
            'Die Pflanze hatte zu viel Sonne.',
            'Die Pflanze ist ganz neu.'
          ]),
          ReadingCheck(
              'Was sollte Lisa jetzt tun?',
              'die Pflanze ans Fenster stellen',
              ['die Pflanze in den Keller stellen', 'die Blätter bemalen']),
        ]),
  ],
};
