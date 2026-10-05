// Wortschatz für Lumos Abenteuer-Aufgaben. Österreichische Volksschule,
// echte Rechtschreibung mit Umlauten und ß. Alles hier ist Lerninhalt:
// Bei Änderungen bitte Artikel, Mehrzahl und Silben mitprüfen.

/// Figuren aus Lumos Welt. Es werden nur Namen verwendet, keine Pronomen.
const adventureFriends = <String>[
  'Lumo', 'Pip', 'Ola', 'Ivo', 'Hoppel', 'Mila', 'Fips', 'Nala',
];

/// Wo die Geschichten spielen (Ort mit Präposition).
const adventurePlaces = <String>[
  'im Zauberwald', 'auf der Himmelsinsel', 'am Bauernhof', 'auf der Alm',
  'am Spielplatz', 'im Garten', 'am Donauufer', 'in der Schule',
  'am Badesee', 'im Kristallberg', 'auf der Kartstrecke', 'am Markt',
];

/// Zählbare Dinge: Einzahl, Mehrzahl.
const adventureObjects = <List<String>>[
  ['Apfel', 'Äpfel'], ['Nuss', 'Nüsse'], ['Stern', 'Sterne'],
  ['Murmel', 'Murmeln'], ['Muschel', 'Muscheln'],
  ['Kastanie', 'Kastanien'], ['Pilz', 'Pilze'], ['Blume', 'Blumen'],
  ['Feder', 'Federn'], ['Stein', 'Steine'], ['Erdbeere', 'Erdbeeren'],
  ['Karotte', 'Karotten'], ['Ballon', 'Ballons'], ['Kristall', 'Kristalle'],
  ['Keks', 'Kekse'], ['Tannenzapfen', 'Tannenzapfen'], ['Sticker', 'Sticker'],
  ['Kirsche', 'Kirschen'], ['Perle', 'Perlen'], ['Buntstift', 'Buntstifte'],
];

/// Behälter für Mal-Aufgaben: „in jede/jeden/jedes …“.
const adventureContainers = <List<String>>[
  // [Mehrzahl, Akkusativ mit „jede/jeden/jedes“]
  ['Körbe', 'jeden Korb'], ['Säckchen', 'jedes Säckchen'],
  ['Schachteln', 'jede Schachtel'], ['Gläser', 'jedes Glas'],
  ['Taschen', 'jede Tasche'], ['Kisten', 'jede Kiste'],
];

/// Marktstand: Ware, Preis in Cent je Klasse passend gewählt.
const adventureMarketGoods = <List<Object>>[
  // [Name mit Artikel für „kauft …“, Preis in Cent]
  ['eine Semmel', 50], ['ein Kipferl', 80], ['eine Breze', 120],
  ['einen Apfel', 60], ['eine Birne', 70], ['ein Glas Honig', 450],
  ['ein Stück Apfelstrudel', 280], ['eine Gurke', 90], ['ein Heft', 150],
  ['einen Bleistift', 90], ['einen Ball', 600], ['ein Malbuch', 400],
  ['eine Flasche Apfelsaft', 220], ['einen Becher Joghurt', 110],
];

/// Nomen mit Artikel, Mehrzahl und Silben (Bindestrich trennt Silben).
class AdventureNoun {
  const AdventureNoun(this.article, this.word, this.syllables, this.grade);
  final String article;
  final String word;
  final String syllables;
  final int grade;
  int get syllableCount => syllables.split('-').length;
}

const adventureNouns = <AdventureNoun>[
  AdventureNoun('der', 'Hund', 'Hund', 1),
  AdventureNoun('die', 'Katze', 'Kat-ze', 1),
  AdventureNoun('das', 'Pferd', 'Pferd', 1),
  AdventureNoun('der', 'Apfel', 'Ap-fel', 1),
  AdventureNoun('die', 'Banane', 'Ba-na-ne', 1),
  AdventureNoun('das', 'Haus', 'Haus', 1),
  AdventureNoun('die', 'Sonne', 'Son-ne', 1),
  AdventureNoun('der', 'Mond', 'Mond', 1),
  AdventureNoun('das', 'Auto', 'Au-to', 1),
  AdventureNoun('die', 'Blume', 'Blu-me', 1),
  AdventureNoun('der', 'Baum', 'Baum', 1),
  AdventureNoun('das', 'Buch', 'Buch', 1),
  AdventureNoun('die', 'Maus', 'Maus', 1),
  AdventureNoun('der', 'Fuchs', 'Fuchs', 1),
  AdventureNoun('das', 'Schaf', 'Schaf', 1),
  AdventureNoun('die', 'Tomate', 'To-ma-te', 1),
  AdventureNoun('der', 'Ball', 'Ball', 1),
  AdventureNoun('das', 'Kind', 'Kind', 1),
  AdventureNoun('die', 'Ente', 'En-te', 1),
  AdventureNoun('der', 'Igel', 'I-gel', 1),
  AdventureNoun('die', 'Schokolade', 'Scho-ko-la-de', 2),
  AdventureNoun('der', 'Schmetterling', 'Schmet-ter-ling', 2),
  AdventureNoun('das', 'Fahrrad', 'Fahr-rad', 2),
  AdventureNoun('die', 'Giraffe', 'Gi-raf-fe', 2),
  AdventureNoun('der', 'Kindergarten', 'Kin-der-gar-ten', 2),
  AdventureNoun('das', 'Krokodil', 'Kro-ko-dil', 2),
  AdventureNoun('die', 'Melone', 'Me-lo-ne', 2),
  AdventureNoun('der', 'Papagei', 'Pa-pa-gei', 2),
  AdventureNoun('das', 'Telefon', 'Te-le-fon', 2),
  AdventureNoun('die', 'Ananas', 'A-na-nas', 2),
  AdventureNoun('der', 'Elefant', 'E-le-fant', 2),
  AdventureNoun('das', 'Eichhörnchen', 'Eich-hörn-chen', 2),
  AdventureNoun('die', 'Kartoffel', 'Kar-tof-fel', 2),
  AdventureNoun('der', 'Regenbogen', 'Re-gen-bo-gen', 2),
  AdventureNoun('das', 'Klavier', 'Kla-vier', 2),
  AdventureNoun('die', 'Lokomotive', 'Lo-ko-mo-ti-ve', 3),
  AdventureNoun('der', 'Hubschrauber', 'Hub-schrau-ber', 3),
  AdventureNoun('das', 'Abenteuer', 'A-ben-teu-er', 3),
  AdventureNoun('die', 'Bibliothek', 'Bi-bli-o-thek', 3),
  AdventureNoun('der', 'Kalender', 'Ka-len-der', 3),
  AdventureNoun('das', 'Gewitter', 'Ge-wit-ter', 3),
  AdventureNoun('die', 'Mannschaft', 'Mann-schaft', 3),
  AdventureNoun('der', 'Bürgermeister', 'Bür-ger-meis-ter', 4),
  AdventureNoun('das', 'Thermometer', 'Ther-mo-me-ter', 4),
  AdventureNoun('die', 'Geschwindigkeit', 'Ge-schwin-dig-keit', 4),
];

/// Wortdetektiv: richtiges Wort und typische Kinderfehler.
class AdventureSpelling {
  const AdventureSpelling(this.correct, this.wrong, this.grade, this.tip);
  final String correct;
  final List<String> wrong;
  final int grade;
  final String tip;
}

const adventureSpellings = <AdventureSpelling>[
  AdventureSpelling('Hund', ['Hunt', 'Hunnd', 'Huhnd'], 1, 'Verlängere: die Hunde – darum mit d.'),
  AdventureSpelling('Vogel', ['Fogel', 'Vogl', 'Vohgel'], 1, 'Vogel schreibt man mit V wie Vater.'),
  AdventureSpelling('Baum', ['Baun', 'Bowm', 'Baumm'], 1, 'Hör genau: Baum endet mit m.'),
  AdventureSpelling('Mama', ['Mamma', 'Mahma', 'Mamah'], 1, 'Mama: zweimal ma.'),
  AdventureSpelling('Sonne', ['Sone', 'Sohne', 'Sonnä'], 1, 'Nach kurzem o kommt nn.'),
  AdventureSpelling('Maus', ['Mauss', 'Mauß', 'Maos'], 1, 'Maus endet mit einem s.'),
  AdventureSpelling('Ball', ['Bal', 'Bahl', 'Baal'], 1, 'Nach kurzem a kommt ll.'),
  AdventureSpelling('Fisch', ['Fish', 'Visch', 'Fiesch'], 1, 'Fisch: F am Anfang, sch am Ende.'),
  AdventureSpelling('Zahn', ['Zan', 'Tsahn', 'Zaan'], 2, 'Das lange a bekommt ein Dehnungs-h.'),
  AdventureSpelling('Fahrrad', ['Farrad', 'Fahrad', 'Fahrrat'], 2, 'fahren + Rad = Fahrrad, mit h und rr.'),
  AdventureSpelling('fliegen', ['fligen', 'fliehgen', 'flihgen'], 2, 'Das lange i schreibt man meistens ie.'),
  AdventureSpelling('Bett', ['Bet', 'Bed', 'Beet'], 2, 'Nach kurzem e kommt tt.'),
  AdventureSpelling('Schule', ['Schuhle', 'Schulle', 'Shule'], 2, 'Schule mit Sch und einem l.'),
  AdventureSpelling('Kind', ['Kint', 'Kinnd', 'Kiend'], 2, 'Verlängere: die Kinder – darum d.'),
  AdventureSpelling('Wald', ['Walt', 'Wahld', 'Vald'], 2, 'Verlängere: die Wälder – darum d.'),
  AdventureSpelling('Straße', ['Strasse', 'Strase', 'Straaße'], 3, 'Nach langem a schreibt man ß.'),
  AdventureSpelling('Fußball', ['Fussball', 'Fußbal', 'Fusball'], 3, 'Fuß mit ß, Ball mit ll.'),
  AdventureSpelling('nämlich', ['nähmlich', 'nemlich', 'nämmlich'], 3, 'nämlich hat kein h – merk es dir!'),
  AdventureSpelling('Fenster', ['Fenstr', 'Fennster', 'Venster'], 3, 'Fenster: F am Anfang, ein n.'),
  AdventureSpelling('Bäcker', ['Becker', 'Bäker', 'Bäckker'], 3, 'backen – Bäcker: a wird zu ä, dazu ck.'),
  AdventureSpelling('Wiese', ['Wise', 'Wihse', 'Wieße'], 3, 'Langes i: ie, dann ein s.'),
  AdventureSpelling('Maschine', ['Maschiene', 'Maschihne', 'Machine'], 4, 'Maschine ist ein Fremdwort: nur i.'),
  AdventureSpelling('Rhythmus', ['Rythmus', 'Rhytmus', 'Rüthmus'], 4, 'Rhythmus: Rh am Anfang, dann y und th.'),
  AdventureSpelling('ziemlich', ['zimlich', 'ziehmlich', 'zihmlich'], 4, 'ziemlich mit ie und ohne h.'),
  AdventureSpelling('Theater', ['Teater', 'Theahter', 'Thehater'], 4, 'Theater mit Th, wie Thema.'),
  AdventureSpelling('Mannschaft', ['Manschaft', 'Mannshaft', 'Mannschaaft'], 4, 'Mann mit nn, dann -schaft.'),
  AdventureSpelling('Erdbeere', ['Erdbere', 'Ertbeere', 'Erdbehre'], 3, 'Erde + Beere: d und ee.'),
  AdventureSpelling('Geburtstag', ['Geburtstak', 'Gebuhrtstag', 'Geburstag'], 4, 'Geburt + s + Tag.'),
];

/// Zusammengesetzte Nomen: erstes Wort, Grundwort mit Artikel, Ergebnis.
/// Der Artikel des Ergebnisses kommt immer vom Grundwort.
const adventureCompounds = <List<String>>[
  ['Schnee', 'der Mann', 'der Schneemann'],
  ['Haus', 'die Tür', 'die Haustür'],
  ['Sonne', 'die Blume', 'die Sonnenblume'],
  ['Apfel', 'der Baum', 'der Apfelbaum'],
  ['Schule', 'die Tasche', 'die Schultasche'],
  ['Hand', 'der Schuh', 'der Handschuh'],
  ['Regen', 'der Bogen', 'der Regenbogen'],
  ['Kinder', 'das Zimmer', 'das Kinderzimmer'],
  ['Fuß', 'der Ball', 'der Fußball'],
  ['Zahn', 'die Bürste', 'die Zahnbürste'],
  ['Feuer', 'die Wehr', 'die Feuerwehr'],
  ['Spiel', 'der Platz', 'der Spielplatz'],
  ['Erde', 'die Beere', 'die Erdbeere'],
  ['Geburt', 'der Tag', 'der Geburtstag'],
  ['Wald', 'das Tier', 'das Waldtier'],
  ['Stern', 'das Bild', 'das Sternbild'],
  ['Blume', 'der Topf', 'der Blumentopf'],
  ['baden', 'die Hose', 'die Badehose'],
];

/// Tiere für Satz-Bausteine im Werfall (Artikel, Nomen).
const adventureSentenceAnimals = <List<String>>[
  ['der', 'Hund'], ['die', 'Katze'], ['das', 'Pferd'], ['der', 'Fuchs'],
  ['die', 'Eule'], ['das', 'Schaf'], ['der', 'Igel'], ['die', 'Maus'],
  ['das', 'Eichhörnchen'], ['der', 'Hase'], ['die', 'Ente'], ['das', 'Pony'],
];

const adventureAdjectives = <String>[
  'kleine', 'flinke', 'mutige', 'müde', 'fröhliche', 'freche', 'neugierige',
  'große', 'leise', 'lustige',
];

const adventureVerbs = <String>[
  'läuft', 'springt', 'schläft', 'tanzt', 'spielt', 'rennt', 'klettert',
  'versteckt sich', 'gähnt', 'lacht',
];

const adventureVerbPlaces = <String>[
  'im Garten', 'auf der Wiese', 'unter dem Baum', 'im Stall',
  'hinter dem Haus', 'neben dem Bach', 'auf dem Hügel', 'im Wald',
];

/// Gegenteil-Paare (Wiewörter).
const adventureOpposites = <List<String>>[
  ['groß', 'klein'], ['schnell', 'langsam'], ['laut', 'leise'],
  ['hell', 'dunkel'], ['warm', 'kalt'], ['alt', 'jung'], ['voll', 'leer'],
  ['nass', 'trocken'], ['schwer', 'leicht'], ['dick', 'dünn'],
  ['müde', 'munter'], ['lang', 'kurz'], ['früh', 'spät'], ['hart', 'weich'],
  ['fröhlich', 'traurig'], ['mutig', 'ängstlich'],
];

/// „Wer bin ich?“: Antwort, drei Hinweise, Klasse ab, Gruppe (für
/// passende falsche Antworten aus derselben Gruppe).
const adventureRiddles = <List<String>>[
  ['der Igel', 'Ich habe viele Stacheln.', 'Im Winter halte ich Winterschlaf.', 'Ich fresse gerne Käfer und Schnecken.', '1', 'Tier'],
  ['das Eichhörnchen', 'Ich habe einen buschigen Schwanz.', 'Ich klettere flink auf Bäume.', 'Im Herbst verstecke ich Nüsse.', '1', 'Tier'],
  ['die Kuh', 'Ich lebe am Bauernhof.', 'Ich fresse Gras und Heu.', 'Aus meiner Milch macht man Käse.', '1', 'Tier'],
  ['die Biene', 'Ich habe sechs Beine und Flügel.', 'Ich fliege von Blüte zu Blüte.', 'Ich mache Honig.', '1', 'Tier'],
  ['der Frosch', 'Ich kann weit springen.', 'Ich lebe am Teich.', 'Als Baby war ich eine Kaulquappe.', '1', 'Tier'],
  ['die Eule', 'Ich bin ein Vogel.', 'Ich bin in der Nacht wach.', 'Ich kann meinen Kopf weit drehen.', '1', 'Tier'],
  ['der Fisch', 'Ich lebe im Wasser.', 'Ich atme mit Kiemen.', 'Ich habe Flossen und Schuppen.', '1', 'Tier'],
  ['die Schnecke', 'Ich trage mein Haus auf dem Rücken.', 'Ich bin sehr langsam.', 'Ich hinterlasse eine Schleimspur.', '1', 'Tier'],
  ['der Maulwurf', 'Ich grabe Gänge unter der Erde.', 'Ich sehe sehr schlecht.', 'Man sieht meine Erdhügel im Garten.', '2', 'Tier'],
  ['der Specht', 'Ich bin ein Vogel.', 'Ich klopfe Löcher in Baumstämme.', 'Ich suche Insekten unter der Rinde.', '2', 'Tier'],
  ['die Fledermaus', 'Ich kann fliegen, bin aber kein Vogel.', 'Ich schlafe kopfüber.', 'Ich orientiere mich mit Ultraschall.', '3', 'Tier'],
  ['der Biber', 'Ich habe große Nagezähne.', 'Ich fälle Bäume.', 'Ich baue Dämme im Fluss.', '2', 'Tier'],
  ['die Gämse', 'Ich lebe hoch in den Bergen.', 'Ich klettere sicher über Felsen.', 'Ich habe kleine, gebogene Hörner.', '3', 'Tier'],
  ['der Löwenzahn', 'Ich bin eine gelbe Blume.', 'Später werde ich eine Pusteblume.', 'Meine Samen fliegen mit dem Wind.', '2', 'Natur'],
  ['die Kastanie', 'Ich wachse auf einem großen Baum.', 'Meine Hülle ist stachelig.', 'Im Herbst falle ich glänzend braun herunter.', '2', 'Natur'],
  ['das Herz', 'Ich bin ein Muskel in deiner Brust.', 'Ich pumpe Blut durch deinen Körper.', 'Wenn du läufst, schlage ich schneller.', '3', 'Körper'],
  ['die Lunge', 'Ich bin in deiner Brust.', 'Mit mir atmest du.', 'Ich hole Sauerstoff aus der Luft.', '3', 'Körper'],
  ['die Feuerwehrfrau', 'Ich trage einen Helm.', 'Ich lösche Brände.', 'Ich fahre mit Blaulicht und Sirene.', '1', 'Beruf'],
  ['der Bäcker', 'Ich stehe sehr früh auf.', 'Ich arbeite mit Mehl und einem Ofen.', 'Ich backe Brot und Semmeln.', '1', 'Beruf'],
  ['die Ärztin', 'Ich arbeite oft im Krankenhaus.', 'Ich untersuche kranke Menschen.', 'Ich höre mit dem Stethoskop dein Herz ab.', '2', 'Beruf'],
  ['der Regenbogen', 'Ich habe viele Farben.', 'Ich erscheine, wenn Sonne und Regen zusammenkommen.', 'Ich bin am Himmel wie ein Bogen.', '1', 'Natur'],
  ['der Schnee', 'Ich bin weiß und kalt.', 'Ich falle im Winter vom Himmel.', 'Aus mir kann man einen Mann bauen.', '1', 'Natur'],
  ['die Raupe', 'Ich krabble auf Blättern.', 'Ich fresse sehr viel.', 'Später werde ich ein Schmetterling.', '2', 'Tier'],
  ['der Kompass', 'Ich habe eine Nadel.', 'Meine Nadel zeigt nach Norden.', 'Mit mir findest du die Himmelsrichtung.', '3', 'Ding'],
  ['das Thermometer', 'Ich messe etwas.', 'Ich zeige an, wie warm oder kalt es ist.', 'Man liest bei mir Grad Celsius ab.', '3', 'Ding'],
  ['der Polizist', 'Ich trage eine Uniform.', 'Ich regle manchmal den Verkehr.', 'Ich helfe, wenn etwas gestohlen wurde.', '1', 'Beruf'],
  ['die Lehrerin', 'Ich arbeite in der Schule.', 'Ich erkläre Rechnen und Lesen.', 'Ich korrigiere eure Hefte.', '1', 'Beruf'],
  ['der Tischler', 'Ich arbeite mit Holz.', 'Ich benutze Säge und Hobel.', 'Ich baue Tische und Kästen.', '2', 'Beruf'],
  ['die Gärtnerin', 'Ich arbeite draußen mit Pflanzen.', 'Ich säe, gieße und schneide.', 'In meinem Glashaus wachsen Blumen.', '2', 'Beruf'],
  ['der Magen', 'Ich bin in deinem Bauch.', 'Ich sehe aus wie ein Sack.', 'Ich verdaue dein Essen.', '3', 'Körper'],
  ['das Auge', 'Ich bin zweimal in deinem Gesicht.', 'Ich habe eine bunte Iris.', 'Mit mir kannst du sehen.', '1', 'Körper'],
  ['das Ohr', 'Ich bin links und rechts am Kopf.', 'Ich fange Geräusche ein.', 'Mit mir kannst du hören.', '1', 'Körper'],
  ['die Lupe', 'Ich habe ein rundes Glas.', 'Ich mache kleine Dinge groß.', 'Forscherinnen und Forscher lieben mich.', '2', 'Ding'],
  ['die Waage', 'Ich messe etwas.', 'Ich zeige an, wie schwer etwas ist.', 'Bei mir liest man Kilogramm ab.', '2', 'Ding'],
  ['das Lineal', 'Ich bin lang und gerade.', 'Ich habe Striche und Zahlen.', 'Mit mir misst du Zentimeter.', '1', 'Ding'],
  ['die Wolke', 'Ich schwebe am Himmel.', 'Ich bestehe aus winzigen Wassertröpfchen.', 'Aus mir kann Regen fallen.', '1', 'Natur'],
];

/// Österreich: Bundesland, Landeshauptstadt.
const austriaStates = <List<String>>[
  ['Wien', 'Wien'], ['Niederösterreich', 'St. Pölten'],
  ['Oberösterreich', 'Linz'], ['Salzburg', 'Salzburg'],
  ['Tirol', 'Innsbruck'], ['Vorarlberg', 'Bregenz'],
  ['Kärnten', 'Klagenfurt'], ['Steiermark', 'Graz'],
  ['Burgenland', 'Eisenstadt'],
];

/// Österreich-Wissen: Frage, Antwort, Ablenker, Erklärung.
const austriaFacts = <List<String>>[
  ['Wie heißt der höchste Berg Österreichs?', 'Großglockner', 'Schneeberg|Dachstein|Ötscher', 'Der Großglockner ist 3798 Meter hoch.'],
  ['Durch welche Landeshauptstädte fließt die Donau?', 'Linz und Wien', 'Graz und Bregenz|Innsbruck und Graz|Klagenfurt und Eisenstadt', 'Die Donau fließt unter anderem durch Linz und Wien.'],
  ['Welche Farben hat die österreichische Fahne?', 'Rot-Weiß-Rot', 'Schwarz-Rot-Gold|Blau-Weiß|Grün-Weiß-Rot', 'Die Fahne Österreichs ist rot-weiß-rot.'],
  ['Wie viele Bundesländer hat Österreich?', '9', '7|8|10', 'Österreich hat neun Bundesländer.'],
  ['In welchem Bundesland liegt der Neusiedler See?', 'Burgenland', 'Tirol|Kärnten|Vorarlberg', 'Der Neusiedler See liegt im Burgenland.'],
  ['An welchem großen See liegt Bregenz?', 'Bodensee', 'Wörthersee|Attersee|Neusiedler See', 'Bregenz in Vorarlberg liegt am Bodensee.'],
  ['Wie heißt die Hauptstadt von Österreich?', 'Wien', 'Graz|Linz|Salzburg', 'Wien ist Bundeshauptstadt und zugleich ein Bundesland.'],
  ['In welcher Stadt wurde Mozart geboren?', 'Salzburg', 'Wien|Graz|Linz', 'Wolfgang Amadeus Mozart kam 1756 in Salzburg zur Welt.'],
];

/// Kategorien für „Was passt nicht?“: Name im Satz, Mitglieder.
const adventureCategories = <List<String>>[
  ['Obst', 'Apfel|Birne|Kirsche|Banane|Pflaume|Marille'],
  ['Gemüse', 'Karotte|Gurke|Paprika|Zwiebel|Erbse|Kohlrabi'],
  ['Tiere im Wald', 'Fuchs|Reh|Dachs|Specht|Wildschwein|Eichhörnchen'],
  ['Fahrzeuge', 'Auto|Bus|Zug|Fahrrad|Traktor|Roller'],
  ['Musikinstrumente', 'Gitarre|Flöte|Trommel|Geige|Klavier|Harfe'],
  ['Kleidungsstücke', 'Hose|Jacke|Mütze|Socke|Pullover|Schal'],
  ['Möbelstücke', 'Tisch|Sessel|Kasten|Bett|Regal|Sofa'],
  ['Farben', 'Rot|Blau|Gelb|Grün|Lila|Rosa'],
  ['Wetter', 'Regen|Schnee|Nebel|Hagel|Gewitter|Wind'],
  ['Schulsachen', 'Heft|Lineal|Radiergummi|Füllfeder|Spitzer|Bleistift'],
];

const adventureMonths = <String>[
  'Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August',
  'September', 'Oktober', 'November', 'Dezember',
];

const adventureWeekdays = <String>[
  'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag',
  'Sonntag',
];

/// Wörter für den Geheimcode (nur A–Z, keine Umlaute).
const adventureCodeWords = <String>[
  'HUND', 'BALL', 'STERN', 'APFEL', 'FUCHS', 'KART', 'MOND', 'BAUM',
  'SONNE', 'WALD', 'INSEL', 'EULE', 'HASE', 'BUCH', 'KUCHEN', 'ROBOTER',
  'BLUME', 'SCHATZ', 'ZEBRA', 'KATZE',
];
