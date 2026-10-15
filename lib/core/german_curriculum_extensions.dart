part of 'german_task_templates.dart';

// Additional authored problems; original banks remain in their original order.
// Automatic validation checks choices and variety, not a human curriculum approval.

const List<_FamilyItem> _familiesExtension = <_FamilyItem>[
  _FamilyItem("bau", "bauen, Bauwerk, Baustelle", <String>[
    "Baum, Bauer, Bär",
    "lesen, Leser, Lesebuch",
    "Wasser, Wolke, Wind"
  ]),
  _FamilyItem("sing", "singen, Sänger, Gesang", <String>[
    "Sonne, Sand, Sommer",
    "malen, Maler, Gemälde",
    "gehen, Weg, Schuh"
  ]),
  _FamilyItem("lern", "lernen, Lerngruppe, Lernspiel", <String>[
    "Lärm, Lampe, Leiter",
    "fahren, Fahrrad, Fahrer",
    "Apfel, Birne, Obst"
  ]),
  _FamilyItem("schreib", "schreiben, Schreiber, Schreibheft", <String>[
    "Schrank, Schere, Schaf",
    "lesen, Buch, leise",
    "spielen, Ball, Tor"
  ]),
  _FamilyItem("koch", "kochen, Koch, Kochbuch", <String>[
    "Korb, Kopf, Komet",
    "essen, Teller, Suppe",
    "Schule, Tafel, Kreide"
  ]),
  _FamilyItem("back", "backen, Bäcker, Backofen", <String>[
    "Bach, Ball, Band",
    "kochen, Suppe, Teller",
    "Wolke, Regen, Wind"
  ]),
  _FamilyItem("turn", "turnen, Turner, Turnsaal",
      <String>["Turm, Tür, Tuch", "fahren, Bus, Straße", "malen, Maler, Bild"]),
  _FamilyItem("schwimm", "schwimmen, Schwimmer, Schwimmbad", <String>[
    "Schwamm, Schwan, Schwein",
    "lesen, Buch, Heft",
    "gehen, Schuh, Weg"
  ]),
  _FamilyItem("lauf", "laufen, Läufer, Laufbahn", <String>[
    "Laub, Laus, Laune",
    "singen, Lied, Ton",
    "essen, Teller, Suppe"
  ]),
  _FamilyItem("spring", "springen, Springer, Sprung", <String>[
    "sprechen, Sprache, Spruch",
    "gehen, Weg, Schuh",
    "Apfel, Birne, Obst"
  ]),
  _FamilyItem("trink", "trinken, Trinkglas, Getränk", <String>[
    "tragen, Träger, Tragetasche",
    "essen, Teller, Suppe",
    "Sonne, Sand, Sommer"
  ]),
  _FamilyItem("wohn", "wohnen, Wohnung, Wohnhaus", <String>[
    "Wolke, Woche, Wolle",
    "fahren, Bus, Straße",
    "lesen, Buch, Heft"
  ]),
  _FamilyItem("freund", "Freund, Freundin, freundlich", <String>[
    "fremd, Frost, frisch",
    "Kind, Schule, Heft",
    "malen, Maler, Bild"
  ]),
  _FamilyItem("blüh", "blühen, Blüte, verblühen", <String>[
    "blau, Blei, Blitz",
    "Baum, Busch, Gras",
    "kochen, Suppe, Teller"
  ]),
  _FamilyItem("zähl", "zählen, Zähler, abzählen",
      <String>["Zeit, Zelt, Zange", "singen, Lied, Ton", "lesen, Buch, Heft"]),
  _FamilyItem("kauf", "kaufen, Käufer, Einkauf", <String>[
    "Kuh, Kuchen, Kamm",
    "fahren, Bus, Straße",
    "Wasser, Wolke, Wind"
  ]),
];

const List<_PluralItem> _pluralsExtension = <_PluralItem>[
  _PluralItem(
      "der Ball", "die Bälle", <String>["die Balle", "die Balls", "der Bälle"]),
  _PluralItem("der Stuhl", "die Stühle",
      <String>["die Stuhle", "die Stuhls", "der Stühle"]),
  _PluralItem("der Tisch", "die Tische",
      <String>["die Tischen", "die Tisch", "der Tische"]),
  _PluralItem("die Blume", "die Blumen",
      <String>["die Blume", "die Blumes", "der Blumen"]),
  _PluralItem("die Tasche", "die Taschen",
      <String>["die Tasche", "die Tasches", "der Taschen"]),
  _PluralItem("das Haus", "die Häuser",
      <String>["die Hauser", "die Hauses", "das Häuser"]),
  _PluralItem("das Glas", "die Gläser",
      <String>["die Glase", "die Glass", "das Gläser"]),
  _PluralItem("das Ei", "die Eier", <String>["die Eie", "die Eis", "das Eier"]),
  _PluralItem(
      "der Fuß", "die Füße", <String>["die Fuße", "die Fußs", "der Füße"]),
  _PluralItem(
      "der Zahn", "die Zähne", <String>["die Zahne", "die Zahns", "der Zähne"]),
  _PluralItem(
      "die Hand", "die Hände", <String>["die Hande", "die Hands", "der Hände"]),
  _PluralItem(
      "die Maus", "die Mäuse", <String>["die Mause", "die Mauss", "der Mäuse"]),
];

const List<_DiminutiveItem> _diminutivesExtension = <_DiminutiveItem>[
  _DiminutiveItem("Baum", "Bäumchen", <String>["Baumen", "Baumung", "Bäume"]),
  _DiminutiveItem("Blume", "Blümchen", <String>["Blumen", "Blumung", "Blumer"]),
  _DiminutiveItem(
      "Vogel", "Vögelchen", <String>["Vogelung", "Vogeler", "Vögel"]),
  _DiminutiveItem("Brot", "Brötchen", <String>["Brote", "Brotung", "Broter"]),
  _DiminutiveItem("Ball", "Bällchen", <String>["Balle", "Ballung", "Bälle"]),
  _DiminutiveItem("Topf", "Töpfchen", <String>["Töpfe", "Topfung", "Topfer"]),
  _DiminutiveItem("Glas", "Gläschen", <String>["Gläser", "Glasung", "Glaser"]),
  _DiminutiveItem("Sack", "Säckchen", <String>["Säcke", "Sackung", "Sacken"]),
  _DiminutiveItem("Rose", "Röschen", <String>["Rosen", "Rosung", "Rosener"]),
  _DiminutiveItem("Kind", "Kindchen", <String>["Kinder", "Kindung", "Kindig"]),
  _DiminutiveItem(
      "Tisch", "Tischchen", <String>["Tische", "Tischung", "Tischig"]),
  _DiminutiveItem("Lamm", "Lämmchen", <String>["Lämmer", "Lammung", "Lammen"]),
  _DiminutiveItem("Ente", "Entchen", <String>["Enten", "Entung", "Entig"]),
  _DiminutiveItem("Tasse", "Tässchen", <String>["Tassen", "Tassung", "Tassig"]),
  _DiminutiveItem(
      "Stern", "Sternchen", <String>["Sterne", "Sternung", "Sternig"]),
];

const List<_PairItem> _oppositesExtension = <_PairItem>[
  _PairItem("hoch", "tief", <String>["breit", "rund", "bunt"]),
  _PairItem("lang", "kurz", <String>["hell", "weich", "süß"]),
  _PairItem("breit", "schmal", <String>["laut", "warm", "neu"]),
  _PairItem("schwer", "leicht", <String>["dunkel", "trocken", "sauer"]),
  _PairItem("hart", "weich", <String>["hoch", "voll", "schwarz"]),
  _PairItem("alt", "neu", <String>["rund", "warm", "lang"]),
  _PairItem("sauber", "schmutzig", <String>["schnell", "hell", "weich"]),
  _PairItem("nass", "trocken", <String>["klein", "laut", "spitz"]),
  _PairItem("süß", "sauer", <String>["voll", "neu", "lang"]),
  _PairItem("oben", "unten", <String>["heute", "leise", "warm"]),
  _PairItem("vorne", "hinten", <String>["hell", "rund", "weich"]),
  _PairItem("früh", "spät", <String>["trocken", "bunt", "klein"]),
  _PairItem("offen", "geschlossen", <String>["süß", "schnell", "lang"]),
  _PairItem("fröhlich", "traurig", <String>["hoch", "glatt", "voll"]),
];

const List<_CategoryItem> _categoriesExtension = <_CategoryItem>[
  _CategoryItem(<String>["Stuhl", "Tisch", "Schrank"], "Möbel",
      <String>["Obst", "Wetter", "Werkzeug"]),
  _CategoryItem(<String>["Rose", "Tulpe", "Sonnenblume"], "Blumen",
      <String>["Fahrzeuge", "Kleidung", "Getränke"]),
  _CategoryItem(<String>["Birke", "Eiche", "Tanne"], "Bäume",
      <String>["Gefühle", "Möbel", "Werkzeug"]),
  _CategoryItem(<String>["Wasser", "Milch", "Tee"], "Getränke",
      <String>["Körperteile", "Blumen", "Berufe"]),
  _CategoryItem(<String>["Auge", "Ohr", "Nase"], "Körperteile",
      <String>["Sportarten", "Werkzeuge", "Getränke"]),
  _CategoryItem(<String>["Montag", "Mittwoch", "Freitag"], "Wochentage",
      <String>["Jahreszeiten", "Zahlen", "Möbel"]),
  _CategoryItem(<String>["Frühling", "Sommer", "Winter"], "Jahreszeiten",
      <String>["Wochentage", "Körperteile", "Farben"]),
  _CategoryItem(<String>["Rot", "Grün", "Blau"], "Farben",
      <String>["Formen", "Berufe", "Tiere"]),
  _CategoryItem(<String>["Kreis", "Dreieck", "Quadrat"], "Formen",
      <String>["Farben", "Pflanzen", "Lebensmittel"]),
  _CategoryItem(<String>["Schwimmen", "Turnen", "Fußball"], "Sportarten",
      <String>["Getränke", "Kleidung", "Möbel"]),
  _CategoryItem(<String>["Bäckerin", "Lehrer", "Ärztin"], "Berufe",
      <String>["Tiere", "Pflanzen", "Werkzeuge"]),
  _CategoryItem(<String>["Freude", "Angst", "Trauer"], "Gefühle",
      <String>["Farben", "Formen", "Wochentage"]),
  _CategoryItem(<String>["Karotte", "Gurke", "Paprika"], "Gemüse",
      <String>["Obst", "Werkzeug", "Kleidung"]),
  _CategoryItem(<String>["Bleistift", "Heft", "Radiergummi"], "Schulsachen",
      <String>["Getränke", "Körperteile", "Wetter"]),
];

const List<_PairItem> _synonymsExtension = <_PairItem>[
  _PairItem("flink", "schnell", <String>["langsam", "schwer", "leer"]),
  _PairItem(
      "öffnen", "aufmachen", <String>["schließen", "vergessen", "verlieren"]),
  _PairItem("schließen", "zumachen", <String>["öffnen", "warten", "suchen"]),
  _PairItem(
      "verstehen", "begreifen", <String>["vergessen", "laufen", "zeichnen"]),
  _PairItem("bekommen", "erhalten", <String>["verlieren", "geben", "schlafen"]),
  _PairItem("beenden", "abschließen", <String>["beginnen", "öffnen", "holen"]),
  _PairItem("schauen", "blicken", <String>["hören", "riechen", "essen"]),
  _PairItem("mutig", "tapfer", <String>["ängstlich", "müde", "nass"]),
  _PairItem("winzig", "sehr klein", <String>["riesig", "laut", "schnell"]),
  _PairItem("riesig", "sehr groß", <String>["winzig", "leer", "leise"]),
  _PairItem("finster", "dunkel", <String>["hell", "bunt", "weich"]),
  _PairItem("ruhig", "still", <String>["laut", "hart", "süß"]),
  _PairItem(
      "helfen", "unterstützen", <String>["stören", "verlieren", "schlafen"]),
  _PairItem("erzählen", "berichten", <String>["schweigen", "laufen", "werfen"]),
];

const List<_PairItem> _pastTensesExtension = <_PairItem>[
  _PairItem("trinken", "trank", <String>["trinkte", "trinkt", "trinken"]),
  _PairItem("finden", "fand", <String>["findete", "findet", "gefunden"]),
  _PairItem("geben", "gab", <String>["gebte", "gibt", "geben"]),
  _PairItem("nehmen", "nahm", <String>["nehmte", "nimmt", "genommen"]),
  _PairItem(
      "sprechen", "sprach", <String>["sprechte", "spricht", "gesprochen"]),
  _PairItem("lesen", "las", <String>["lesete", "liest", "gelesen"]),
  _PairItem("singen", "sang", <String>["singte", "singt", "gesungen"]),
  _PairItem("sitzen", "saß", <String>["sitzte", "sitzt", "gesessen"]),
  _PairItem("stehen", "stand", <String>["stehte", "steht", "gestanden"]),
  _PairItem("fahren", "fuhr", <String>["fahrte", "fährt", "gefahren"]),
  _PairItem("spielen", "spielte", <String>["spielt", "spielen", "gespielt"]),
  _PairItem("malen", "malte", <String>["malt", "malen", "gemalt"]),
  _PairItem("lernen", "lernte", <String>["lernt", "lernen", "gelernt"]),
  _PairItem("fragen", "fragte", <String>["fragt", "fragen", "gefragt"]),
];

const List<_ComparisonItem> _comparisonsExtension = <_ComparisonItem>[
  _ComparisonItem("klein", "kleiner, am kleinsten",
      <String>["klein, am kleiner", "kleinste, kleiner", "kleiner, am klein"]),
  _ComparisonItem("lang", "länger, am längsten",
      <String>["langer, am langsten", "lang, am länger", "längste, länger"]),
  _ComparisonItem("kurz", "kürzer, am kürzesten",
      <String>["kurzer, am kurzsten", "kurz, am kürzer", "kürzeste, kürzer"]),
  _ComparisonItem("hoch", "höher, am höchsten",
      <String>["hocher, am hochsten", "hoch, am höher", "höchste, höher"]),
  _ComparisonItem("tief", "tiefer, am tiefsten",
      <String>["tief, am tiefer", "tiefste, tiefer", "tiefer, am tief"]),
  _ComparisonItem("warm", "wärmer, am wärmsten",
      <String>["warmer, am warmsten", "warm, am wärmer", "wärmste, wärmer"]),
  _ComparisonItem("kalt", "kälter, am kältesten",
      <String>["kalter, am kaltsten", "kalt, am kälter", "kälteste, kälter"]),
  _ComparisonItem("alt", "älter, am ältesten",
      <String>["alter, am altsten", "alt, am älter", "älteste, älter"]),
  _ComparisonItem("jung", "jünger, am jüngsten",
      <String>["junger, am jungsten", "jung, am jünger", "jüngste, jünger"]),
  _ComparisonItem("hell", "heller, am hellsten",
      <String>["hell, am heller", "hellste, heller", "heller, am hell"]),
  _ComparisonItem("dunkel", "dunkler, am dunkelsten", <String>[
    "dunkel, am dunkler",
    "dunkelste, dunkler",
    "dunkler, am dunkel"
  ]),
  _ComparisonItem("leise", "leiser, am leisesten",
      <String>["leise, am leiser", "leiseste, leiser", "leiser, am leise"]),
  _ComparisonItem("laut", "lauter, am lautesten",
      <String>["laut, am lauter", "lauteste, lauter", "lauter, am laut"]),
  _ComparisonItem("stark", "stärker, am stärksten", <String>[
    "starker, am starksten",
    "stark, am stärker",
    "stärkste, stärker"
  ]),
  _ComparisonItem("schwer", "schwerer, am schwersten", <String>[
    "schwer, am schwerer",
    "schwerste, schwerer",
    "schwerer, am schwer"
  ]),
];

const List<_VerbFormItem> _verbFormsExtension = <_VerbFormItem>[
  _VerbFormItem("Ich _____ (lesen) jeden Abend.", "lese",
      <String>["liest", "lesen", "lest"]),
  _VerbFormItem("Du _____ (fahren) mit dem Rad.", "fährst",
      <String>["fahre", "fahren", "fahrt"]),
  _VerbFormItem("Wir _____ (bauen) ein Baumhaus.", "bauen",
      <String>["baut", "baue", "baust"]),
  _VerbFormItem("Ihr _____ (malen) ein Plakat.", "malt",
      <String>["male", "malen", "malst"]),
  _VerbFormItem("Die Kinder _____ (laufen) zur Wiese.", "laufen",
      <String>["läuft", "laufe", "laufst"]),
  _VerbFormItem("Oma _____ (backen) einen Kuchen.", "backt",
      <String>["backe", "backen", "backst"]),
  _VerbFormItem("Du _____ (essen) eine Marille.", "isst",
      <String>["esse", "essen", "esst"]),
  _VerbFormItem("Ich _____ (trinken) Wasser.", "trinke",
      <String>["trinkst", "trinkt", "trinken"]),
  _VerbFormItem("Wir _____ (helfen) unserem Nachbarn.", "helfen",
      <String>["hilft", "helfe", "hilfst"]),
  _VerbFormItem("Ihr _____ (nehmen) eure Hefte.", "nehmt",
      <String>["nehme", "nehmen", "nimmst"]),
  _VerbFormItem("Der Vogel _____ (singen) im Baum.", "singt",
      <String>["singen", "singe", "singst"]),
  _VerbFormItem("Du _____ (geben) mir den Ball.", "gibst",
      <String>["gebe", "geben", "gebt"]),
  _VerbFormItem("Ich _____ (sehen) einen Regenbogen.", "sehe",
      <String>["siehst", "sieht", "sehen"]),
  _VerbFormItem("Wir _____ (sein) ein gutes Team.", "sind",
      <String>["bin", "ist", "seid"]),
  _VerbFormItem("Ihr _____ (haben) heute Sport.", "habt",
      <String>["habe", "hast", "hat"]),
];

const List<_SentencePartItem> _sentencePartsExtension = <_SentencePartItem>[
  _SentencePartItem("Die Kinder bauen eine Höhle.", "Wer?", "Die Kinder",
      <String>["bauen", "eine Höhle", "Höhle"]),
  _SentencePartItem("Lumo erklärt die Aufgabe.", "Was tut Lumo?", "erklärt",
      <String>["Lumo", "die Aufgabe", "Aufgabe"]),
  _SentencePartItem("Am Montag besuchen wir die Bücherei.", "Wann?",
      "Am Montag", <String>["wir", "besuchen", "die Bücherei"]),
  _SentencePartItem("Mia spielt auf der Wiese.", "Wo?", "auf der Wiese",
      <String>["Mia", "spielt", "Wiese"]),
  _SentencePartItem("Paul trägt den Korb zum Markt.", "Wohin?", "zum Markt",
      <String>["Paul", "trägt", "den Korb"]),
  _SentencePartItem("Die Katze schläft auf dem Sofa.", "Wo?", "auf dem Sofa",
      <String>["Die Katze", "schläft", "Katze"]),
  _SentencePartItem("Nach dem Essen räumen wir auf.", "Wann?", "Nach dem Essen",
      <String>["wir", "räumen auf", "Essen"]),
  _SentencePartItem("Der Bäcker verkauft Semmeln.", "Wer?", "Der Bäcker",
      <String>["verkauft", "Semmeln", "heute"]),
  _SentencePartItem("Die Kinder schenken Oma Blumen.", "Wem?", "Oma",
      <String>["Die Kinder", "Blumen", "schenken"]),
  _SentencePartItem("Lena liest ein Abenteuerbuch.", "Wen oder was?",
      "ein Abenteuerbuch", <String>["Lena", "liest", "Abenteuer"]),
  _SentencePartItem("Im Frühling blühen die Bäume.", "Wann?", "Im Frühling",
      <String>["die Bäume", "blühen", "Bäume"]),
  _SentencePartItem("Opa wartet vor der Schule.", "Wo?", "vor der Schule",
      <String>["Opa", "wartet", "Schule"]),
  _SentencePartItem("Die Familie fährt nach Graz.", "Wohin?", "nach Graz",
      <String>["Die Familie", "fährt", "Familie"]),
  _SentencePartItem("Der Hund jagt den Ball.", "Wen oder was?", "den Ball",
      <String>["Der Hund", "jagt", "Hund"]),
  _SentencePartItem("Das Mädchen hilft seinem Bruder.", "Wem?", "seinem Bruder",
      <String>["Das Mädchen", "hilft", "Mädchen"]),
  _SentencePartItem("Die Lehrerin erklärt das Spiel.", "Wer?", "Die Lehrerin",
      <String>["erklärt", "das Spiel", "Spiel"]),
];

const List<_CompoundItem> _compoundsExtension = <_CompoundItem>[
  _CompoundItem("Zahnbürste", "eine Bürste zum Putzen der Zähne", <String>[
    "eine Bürste für Haare",
    "ein Zahn aus Holz",
    "eine kleine Tasche"
  ]),
  _CompoundItem("Regenschirm", "ein Schirm zum Schutz vor Regen", <String>[
    "ein Schirm aus Regen",
    "eine Wolke im Zimmer",
    "ein Hut aus Papier"
  ]),
  _CompoundItem("Haustür", "eine Tür zu einem Haus", <String>[
    "ein Haus aus Türen",
    "ein Fenster im Auto",
    "ein Tor zum Wald"
  ]),
  _CompoundItem("Apfelsaft", "ein Saft aus Äpfeln", <String>[
    "ein Apfel aus Saft",
    "ein Saft aus Birnen",
    "ein Glas mit Milch"
  ]),
  _CompoundItem("Handschuh", "ein Kleidungsstück für die Hand", <String>[
    "ein Schuh für den Fuß",
    "eine Hand aus Stoff",
    "ein warmer Schal"
  ]),
  _CompoundItem("Fußball", "ein Ball für das Fußballspiel", <String>[
    "ein Fuß aus Gummi",
    "ein Ball zum Lesen",
    "ein Schuh mit Rädern"
  ]),
  _CompoundItem("Spielplatz", "ein Platz zum Spielen", <String>[
    "ein Spiel ohne Regeln",
    "ein Platz zum Schlafen",
    "ein Buch voller Spiele"
  ]),
  _CompoundItem("Fahrradhelm", "ein Helm zum Schutz beim Radfahren", <String>[
    "ein Helm für Fahrräder ohne Fahrer",
    "ein Rad aus Helmen",
    "eine Mütze aus Papier"
  ]),
  _CompoundItem("Vogelhaus", "ein kleines Haus für Vögel", <String>[
    "ein Vogel aus Holz",
    "ein Haus für Fische",
    "ein Baum ohne Blätter"
  ]),
  _CompoundItem("Schneemann", "eine Figur aus Schnee", <String>[
    "ein Mann aus Sand",
    "ein Schirm bei Regen",
    "eine warme Jacke"
  ]),
  _CompoundItem(
      "Sonnenbrille", "eine Brille zum Schutz vor hellem Sonnenlicht", <String>[
    "eine Brille zum Lesen im Dunkeln",
    "eine Sonne aus Glas",
    "ein Hut aus Metall"
  ]),
  _CompoundItem("Waldweg", "ein Weg durch einen Wald", <String>[
    "ein Wald aus Wegen",
    "ein Weg im Schwimmbad",
    "eine Brücke aus Büchern"
  ]),
  _CompoundItem("Blumentopf", "ein Topf für eine Pflanze", <String>[
    "eine Blume aus Ton",
    "ein Topf zum Trinken",
    "ein Hut für Tiere"
  ]),
  _CompoundItem("Milchflasche", "eine Flasche für Milch", <String>[
    "Milch aus Glas",
    "eine Flasche für Sand",
    "ein Glas für Schrauben"
  ]),
  _CompoundItem("Schulhof", "ein Hof bei einer Schule", <String>[
    "eine Schule in einem Hofladen",
    "ein Hof für Flugzeuge",
    "ein Zimmer voller Betten"
  ]),
];

const List<_CaseItem> _caseNomAkkItemsExtension = <_CaseItem>[
  _CaseItem("Der Vogel baut ein Nest.", "Der Vogel", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Mia trägt den Korb.", "den Korb", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
  _CaseItem("Die Kinder spielen im Hof.", "Die Kinder", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Opa liest die Zeitung.", "die Zeitung", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
  _CaseItem("Ein Fuchs läuft über die Wiese.", "Ein Fuchs", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Lumo sucht den Ball.", "den Ball", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
  _CaseItem("Der Zug hält am Bahnhof.", "Der Zug", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Wir kaufen eine Semmel.", "eine Semmel", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
  _CaseItem("Die Katze schläft auf dem Sofa.", "Die Katze", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Anna zeichnet einen Baum.", "einen Baum", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
  _CaseItem("Das Fahrrad steht im Hof.", "Das Fahrrad", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Paul öffnet die Tür.", "die Tür", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
  _CaseItem("Die Lehrerin erklärt das Spiel.", "Die Lehrerin", "Wer-Fall",
      <String>["Wen-Fall", "Wem-Fall"]),
  _CaseItem("Das Kind pflückt einen Apfel.", "einen Apfel", "Wen-Fall",
      <String>["Wer-Fall", "Wem-Fall"]),
];

const List<_SentenceMcItem> _capitalizationItemsExtension = <_SentenceMcItem>[
  _SentenceMcItem("Auf der Wiese wächst eine blume.", "Blume",
      <String>["wächst", "eine", "Auf"]),
  _SentenceMcItem(
      "Im Korb liegt ein apfel.", "Apfel", <String>["liegt", "ein", "Im"]),
  _SentenceMcItem(
      "Das kind lacht laut.", "Kind", <String>["lacht", "laut", "Das"]),
  _SentenceMcItem("Wir finden einen schönen stein.", "Stein",
      <String>["finden", "schönen", "Wir"]),
  _SentenceMcItem(
      "Am Himmel steht der mond.", "Mond", <String>["steht", "der", "Am"]),
  _SentenceMcItem("Meine schwester singt gern.", "Schwester",
      <String>["singt", "gern", "Meine"]),
  _SentenceMcItem("Heute besuchen wir die bücherei.", "Bücherei",
      <String>["besuchen", "wir", "Heute"]),
  _SentenceMcItem("Paul trägt einen schweren korb.", "Korb",
      <String>["trägt", "schweren", "Paul"]),
  _SentenceMcItem(
      "Im Winter fällt oft schnee.", "Schnee", <String>["fällt", "oft", "Im"]),
  _SentenceMcItem(
      "Die katze sitzt am Fenster.", "Katze", <String>["sitzt", "am", "Die"]),
  _SentenceMcItem("Ich suche meinen bleistift.", "Bleistift",
      <String>["suche", "meinen", "Ich"]),
  _SentenceMcItem(
      "Auf dem Tisch steht ein glas.", "Glas", <String>["steht", "ein", "Auf"]),
  _SentenceMcItem(
      "Lumo öffnet die tür.", "Tür", <String>["öffnet", "die", "Lumo"]),
  _SentenceMcItem("Oma erzählt eine geschichte.", "Geschichte",
      <String>["erzählt", "eine", "Oma"]),
];

const List<_SimpleMcItem> _ieOrIItemsExtension = <_SimpleMcItem>[
  _SimpleMcItem("Wiese", <String>["Wise", "Wihse", "Wiesse"]),
  _SimpleMcItem("Biene", <String>["Bine", "Bihne", "Bienne"]),
  _SimpleMcItem("Lied", <String>["Lid", "Lihd", "Liedd"]),
  _SimpleMcItem("Ziege", <String>["Zige", "Zihge", "Zieege"]),
  _SimpleMcItem("spielen", <String>["spilen", "spihlen", "spiellen"]),
  _SimpleMcItem("fliegen", <String>["fligen", "flihgen", "flieggen"]),
  _SimpleMcItem("sieben", <String>["siben", "sihben", "siebben"]),
  _SimpleMcItem("Ziel", <String>["Zil", "Zihl", "Ziell"]),
];

const List<_CaseItem> _fourCasesItemsExtension = <_CaseItem>[
  _CaseItem("Die Kinder spielen im Hof.", "Die Kinder", "Wer-Fall (1.)",
      <String>["Wessen-Fall (2.)", "Wem-Fall (3.)", "Wen-Fall (4.)"]),
  _CaseItem("Ein Vogel baut ein Nest.", "Ein Vogel", "Wer-Fall (1.)",
      <String>["Wessen-Fall (2.)", "Wem-Fall (3.)", "Wen-Fall (4.)"]),
  _CaseItem("Das Blatt des Baumes ist grün.", "des Baumes", "Wessen-Fall (2.)",
      <String>["Wer-Fall (1.)", "Wem-Fall (3.)", "Wen-Fall (4.)"]),
  _CaseItem(
      "Die Tasche der Lehrerin ist blau.",
      "der Lehrerin",
      "Wessen-Fall (2.)",
      <String>["Wer-Fall (1.)", "Wem-Fall (3.)", "Wen-Fall (4.)"]),
  _CaseItem("Das Fell des Hundes ist weich.", "des Hundes", "Wessen-Fall (2.)",
      <String>["Wer-Fall (1.)", "Wem-Fall (3.)", "Wen-Fall (4.)"]),
  _CaseItem("Paul hilft seinem Bruder.", "seinem Bruder", "Wem-Fall (3.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wen-Fall (4.)"]),
  _CaseItem("Wir danken der Feuerwehr.", "der Feuerwehr", "Wem-Fall (3.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wen-Fall (4.)"]),
  _CaseItem("Die Ärztin hilft dem Kind.", "dem Kind", "Wem-Fall (3.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wen-Fall (4.)"]),
  _CaseItem(
      "Oma erzählt den Kindern eine Geschichte.",
      "den Kindern",
      "Wem-Fall (3.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wen-Fall (4.)"]),
  _CaseItem("Mia trägt einen Korb.", "einen Korb", "Wen-Fall (4.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wem-Fall (3.)"]),
  _CaseItem("Wir füttern die Tiere.", "die Tiere", "Wen-Fall (4.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wem-Fall (3.)"]),
  _CaseItem("Lumo findet den Schlüssel.", "den Schlüssel", "Wen-Fall (4.)",
      <String>["Wer-Fall (1.)", "Wessen-Fall (2.)", "Wem-Fall (3.)"]),
];

const List<_SentenceMcItem> _dassDasItemsExtension = <_SentenceMcItem>[
  _SentenceMcItem(
      "Ich hoffe, ___ du wieder gesund bist.", "dass", <String>["das", "daß"]),
  _SentenceMcItem(
      "Wir merken, ___ der Wind stärker wird.", "dass", <String>["das", "daß"]),
  _SentenceMcItem(
      "Lena glaubt, ___ die Antwort stimmt.", "dass", <String>["das", "daß"]),
  _SentenceMcItem(
      "Opa freut sich, ___ wir ihn besuchen.", "dass", <String>["das", "daß"]),
  _SentenceMcItem("Ich wünsche mir, ___ morgen die Sonne scheint.", "dass",
      <String>["das", "daß"]),
  _SentenceMcItem("Paul erklärt, ___ er den Ball verloren hat.", "dass",
      <String>["das", "daß"]),
  _SentenceMcItem(
      "Wir sehen, ___ die Pflanze wächst.", "dass", <String>["das", "daß"]),
  _SentenceMcItem("Die Lehrerin sagt, ___ wir helfen sollen.", "dass",
      <String>["das", "daß"]),
  _SentenceMcItem("Ich mag ___ kleine Tier.", "das", <String>["dass", "daß"]),
  _SentenceMcItem("Wir öffnen ___ Fenster.", "das", <String>["dass", "daß"]),
  _SentenceMcItem("___ Kind spielt im Garten.", "Das", <String>["Dass", "Daß"]),
  _SentenceMcItem("Ich lese ___ Buch, ___ du mir geliehen hast. (Beide Lücken)",
      "das, das", <String>["dass, dass", "das, dass"]),
  _SentenceMcItem("Das Fahrrad, ___ dort steht, gehört Mia.", "das",
      <String>["dass", "daß"]),
  _SentenceMcItem("Wir suchen ___ Heft mit dem blauen Umschlag.", "das",
      <String>["dass", "daß"]),
];

const List<_SentenceMcItem> _adverbItemsExtension = <_SentenceMcItem>[
  _SentenceMcItem(
      "Wir treffen uns bald.", "bald", <String>["Wir", "treffen", "uns"]),
  _SentenceMcItem(
      "Das Kind wartet drinnen.", "drinnen", <String>["Das", "Kind", "wartet"]),
  _SentenceMcItem("Lena liest gern.", "gern", <String>["Lena", "liest"]),
  _SentenceMcItem("Opa kommt jetzt.", "jetzt", <String>["Opa", "kommt"]),
  _SentenceMcItem("Gestern regnete es.", "Gestern", <String>["regnete", "es"]),
  _SentenceMcItem("Bereits im Frühling blüht diese Blume.", "Bereits",
      <String>["wächst", "eine", "Blume"]),
  _SentenceMcItem(
      "Die Katze sitzt oben.", "oben", <String>["Die", "Katze", "sitzt"]),
  _SentenceMcItem(
      "Der Ball liegt unten.", "unten", <String>["Der", "Ball", "liegt"]),
  _SentenceMcItem("Paul besucht uns manchmal.", "manchmal",
      <String>["Paul", "besucht", "uns"]),
  _SentenceMcItem("Mia kommt immer.", "immer", <String>["Mia", "kommt"]),
  _SentenceMcItem("Wir vergessen dich nie.", "nie", <String>["Wir", "üben"]),
  _SentenceMcItem("Im Garten wachsen überall Blumen.", "überall",
      <String>["Das", "Team", "trainiert"]),
  _SentenceMcItem("Die Familie ist unterwegs.", "unterwegs",
      <String>["Die", "Familie", "ist"]),
  _SentenceMcItem(
      "Ich habe vorhin gekocht.", "vorhin", <String>["Ich", "habe", "gekocht"]),
];

const List<_VerbFormMcItem> _plusquamItemsExtension = <_VerbFormMcItem>[
  _VerbFormMcItem("trinken", "hatte getrunken",
      <String>["trinkt", "trank", "wird trinken"]),
  _VerbFormMcItem(
      "finden", "hatte gefunden", <String>["findet", "fand", "wird finden"]),
  _VerbFormMcItem(
      "geben", "hatte gegeben", <String>["gibt", "gab", "wird geben"]),
  _VerbFormMcItem(
      "nehmen", "hatte genommen", <String>["nimmt", "nahm", "wird nehmen"]),
  _VerbFormMcItem("sprechen", "hatte gesprochen",
      <String>["spricht", "sprach", "wird sprechen"]),
  _VerbFormMcItem(
      "essen", "hatte gegessen", <String>["isst", "aß", "wird essen"]),
  _VerbFormMcItem(
      "sehen", "hatte gesehen", <String>["sieht", "sah", "wird sehen"]),
  _VerbFormMcItem(
      "fahren", "war gefahren", <String>["fährt", "fuhr", "wird fahren"]),
  _VerbFormMcItem(
      "laufen", "war gelaufen", <String>["läuft", "lief", "wird laufen"]),
  _VerbFormMcItem(
      "bleiben", "war geblieben", <String>["bleibt", "blieb", "wird bleiben"]),
  _VerbFormMcItem(
      "malen", "hatte gemalt", <String>["malt", "malte", "wird malen"]),
  _VerbFormMcItem(
      "lernen", "hatte gelernt", <String>["lernt", "lernte", "wird lernen"]),
  _VerbFormMcItem(
      "fragen", "hatte gefragt", <String>["fragt", "fragte", "wird fragen"]),
  _VerbFormMcItem(
      "bauen", "hatte gebaut", <String>["baut", "baute", "wird bauen"]),
];

const List<_DirectSpeechItem> _directSpeechExtension = <_DirectSpeechItem>[
  _DirectSpeechItem("Lumo sagt: „Wir schaffen das.“", <String>[
    "Lumo sagt Wir schaffen das.",
    "„Lumo sagt: Wir schaffen das.“",
    "Lumo sagt: Wir schaffen das."
  ]),
  _DirectSpeechItem("„Wie geht es dir?“, fragt Opa.", <String>[
    "Wie geht es dir?, fragt Opa.",
    "„Wie geht es dir?, fragt Opa.“",
    "„Wie geht es dir?“ fragt Opa."
  ]),
  _DirectSpeechItem("Mia ruft: „Pass auf!“", <String>[
    "Mia ruft Pass auf!",
    "„Mia ruft: Pass auf!“",
    "Mia ruft: Pass auf!"
  ]),
  _DirectSpeechItem("„Ich helfe dir“, sagt Paul.", <String>[
    "Ich helfe dir, sagt Paul.",
    "„Ich helfe dir, sagt Paul.“",
    "„Ich helfe dir“ sagt Paul."
  ]),
  _DirectSpeechItem("Die Lehrerin sagt: „Bitte öffnet eure Hefte.“", <String>[
    "Die Lehrerin sagt Bitte öffnet eure Hefte.",
    "„Die Lehrerin sagt: Bitte öffnet eure Hefte.“",
    "Die Lehrerin sagt: Bitte öffnet eure Hefte."
  ]),
  _DirectSpeechItem("„Wo ist mein Ball?“, fragt das Kind.", <String>[
    "Wo ist mein Ball?, fragt das Kind.",
    "„Wo ist mein Ball?, fragt das Kind.“",
    "„Wo ist mein Ball?“ fragt das Kind."
  ]),
  _DirectSpeechItem("Oma sagt: „Die Suppe ist fertig.“", <String>[
    "Oma sagt Die Suppe ist fertig.",
    "„Oma sagt: Die Suppe ist fertig.“",
    "Oma sagt: Die Suppe ist fertig."
  ]),
  _DirectSpeechItem("„Hurra, wir haben gewonnen!“, ruft Lena.", <String>[
    "Hurra, wir haben gewonnen!, ruft Lena.",
    "„Hurra, wir haben gewonnen!, ruft Lena.“",
    "„Hurra, wir haben gewonnen!“ ruft Lena."
  ]),
  _DirectSpeechItem("Der Trainer fragt: „Wer spielt mit?“", <String>[
    "Der Trainer fragt Wer spielt mit?",
    "„Der Trainer fragt: Wer spielt mit?“",
    "Der Trainer fragt: Wer spielt mit?"
  ]),
  _DirectSpeechItem("„Wir gehen jetzt los“, sagt Mama.", <String>[
    "Wir gehen jetzt los, sagt Mama.",
    "„Wir gehen jetzt los, sagt Mama.“",
    "„Wir gehen jetzt los“ sagt Mama."
  ]),
  _DirectSpeechItem("Tom sagt: „Ich habe eine Idee.“", <String>[
    "Tom sagt Ich habe eine Idee.",
    "„Tom sagt: Ich habe eine Idee.“",
    "Tom sagt: Ich habe eine Idee."
  ]),
  _DirectSpeechItem("„Tut dein Arm weh?“, fragt die Ärztin.", <String>[
    "Tut dein Arm weh?, fragt die Ärztin.",
    "„Tut dein Arm weh?, fragt die Ärztin.“",
    "„Tut dein Arm weh?“ fragt die Ärztin."
  ]),
  _DirectSpeechItem("Der Bäcker sagt: „Die Semmeln sind frisch.“", <String>[
    "Der Bäcker sagt Die Semmeln sind frisch.",
    "„Der Bäcker sagt: Die Semmeln sind frisch.“",
    "Der Bäcker sagt: Die Semmeln sind frisch."
  ]),
  _DirectSpeechItem("„Bleib bitte stehen!“, ruft Papa.", <String>[
    "Bleib bitte stehen!, ruft Papa.",
    "„Bleib bitte stehen!, ruft Papa.“",
    "„Bleib bitte stehen!“ ruft Papa."
  ]),
  _DirectSpeechItem("Nora fragt: „Darf ich dir helfen?“", <String>[
    "Nora fragt Darf ich dir helfen?",
    "„Nora fragt: Darf ich dir helfen?“",
    "Nora fragt: Darf ich dir helfen?"
  ]),
  _DirectSpeechItem("„Wir halten zusammen“, sagt das Team.", <String>[
    "Wir halten zusammen, sagt das Team.",
    "„Wir halten zusammen, sagt das Team.“",
    "„Wir halten zusammen“ sagt das Team."
  ]),
  _DirectSpeechItem("Der Gärtner sagt: „Die Blumen brauchen Wasser.“", <String>[
    "Der Gärtner sagt Die Blumen brauchen Wasser.",
    "„Der Gärtner sagt: Die Blumen brauchen Wasser.“",
    "Der Gärtner sagt: Die Blumen brauchen Wasser."
  ]),
];

const List<_CommaItem> _commasExtension = <_CommaItem>[
  _CommaItem(
      "Im Obstkorb liegen Äpfel, Birnen, Bananen und Marillen.", <String>[
    "Im Obstkorb liegen Äpfel Birnen Bananen und Marillen.",
    "Im Obstkorb liegen Äpfel Birnen, Bananen und Marillen.",
    "Im Obstkorb liegen, Äpfel Birnen Bananen und Marillen."
  ]),
  _CommaItem(
      "Auf der Wiese wachsen Klee, Gras, Gänseblümchen und Löwenzahn.",
      <String>[
        "Auf der Wiese wachsen Klee Gras Gänseblümchen und Löwenzahn.",
        "Auf der Wiese wachsen Klee Gras, Gänseblümchen und Löwenzahn.",
        "Auf der Wiese wachsen, Klee Gras Gänseblümchen und Löwenzahn."
      ]),
  _CommaItem("Wir besuchen Wien, Graz, Linz und Salzburg.", <String>[
    "Wir besuchen Wien Graz Linz und Salzburg.",
    "Wir besuchen Wien Graz, Linz und Salzburg.",
    "Wir besuchen, Wien Graz Linz und Salzburg."
  ]),
  _CommaItem(
      "Zum Malen brauche ich Papier, Pinsel, Wasser und Farben.", <String>[
    "Zum Malen brauche ich Papier Pinsel Wasser und Farben.",
    "Zum Malen brauche ich Papier Pinsel, Wasser und Farben.",
    "Zum Malen brauche ich, Papier Pinsel Wasser und Farben."
  ]),
  _CommaItem("Für das Brot brauchen wir Mehl, Wasser, Hefe und Salz.", <String>[
    "Für das Brot brauchen wir Mehl Wasser Hefe und Salz.",
    "Für das Brot brauchen wir Mehl Wasser, Hefe und Salz.",
    "Für das Brot brauchen wir, Mehl Wasser Hefe und Salz."
  ]),
  _CommaItem("Im Wald leben Füchse, Rehe, Eichhörnchen und Spechte.", <String>[
    "Im Wald leben Füchse Rehe Eichhörnchen und Spechte.",
    "Im Wald leben Füchse Rehe, Eichhörnchen und Spechte.",
    "Im Wald leben, Füchse Rehe Eichhörnchen und Spechte."
  ]),
  _CommaItem("In der Tasche sind Heft, Buch, Trinkflasche und Jause.", <String>[
    "In der Tasche sind Heft Buch Trinkflasche und Jause.",
    "In der Tasche sind Heft Buch, Trinkflasche und Jause.",
    "In der Tasche sind, Heft Buch Trinkflasche und Jause."
  ]),
  _CommaItem("Ich mag Lesen, Schwimmen, Turnen und Malen.", <String>[
    "Ich mag Lesen Schwimmen Turnen und Malen.",
    "Ich mag Lesen Schwimmen, Turnen und Malen.",
    "Ich mag, Lesen Schwimmen Turnen und Malen."
  ]),
  _CommaItem("Wir beobachten Regen, Wind, Wolken und Sonnenschein.", <String>[
    "Wir beobachten Regen Wind Wolken und Sonnenschein.",
    "Wir beobachten Regen Wind, Wolken und Sonnenschein.",
    "Wir beobachten, Regen Wind Wolken und Sonnenschein."
  ]),
  _CommaItem(
      "Im Garten ernten wir Karotten, Gurken, Tomaten und Salat.", <String>[
    "Im Garten ernten wir Karotten Gurken Tomaten und Salat.",
    "Im Garten ernten wir Karotten Gurken, Tomaten und Salat.",
    "Im Garten ernten wir, Karotten Gurken Tomaten und Salat."
  ]),
  _CommaItem(
      "Auf dem Tisch stehen Teller, Gläser, Schüsseln und Tassen.", <String>[
    "Auf dem Tisch stehen Teller Gläser Schüsseln und Tassen.",
    "Auf dem Tisch stehen Teller Gläser, Schüsseln und Tassen.",
    "Auf dem Tisch stehen, Teller Gläser Schüsseln und Tassen."
  ]),
  _CommaItem("Wir messen Länge, Breite, Höhe und Gewicht.", <String>[
    "Wir messen Länge Breite Höhe und Gewicht.",
    "Wir messen Länge Breite, Höhe und Gewicht.",
    "Wir messen, Länge Breite Höhe und Gewicht."
  ]),
  _CommaItem(
      "Die Kinder sammeln Blätter, Steine, Zapfen und Kastanien.", <String>[
    "Die Kinder sammeln Blätter Steine Zapfen und Kastanien.",
    "Die Kinder sammeln Blätter Steine, Zapfen und Kastanien.",
    "Die Kinder sammeln, Blätter Steine Zapfen und Kastanien."
  ]),
  _CommaItem(
      "Auf der Straße sehen wir Busse, Fahrräder, Autos und Motorräder.",
      <String>[
        "Auf der Straße sehen wir Busse Fahrräder Autos und Motorräder.",
        "Auf der Straße sehen wir Busse Fahrräder, Autos und Motorräder.",
        "Auf der Straße sehen wir, Busse Fahrräder Autos und Motorräder."
      ]),
  _CommaItem("Im Zoo leben Elefanten, Löwen, Giraffen und Zebras.", <String>[
    "Im Zoo leben Elefanten Löwen Giraffen und Zebras.",
    "Im Zoo leben Elefanten Löwen, Giraffen und Zebras.",
    "Im Zoo leben, Elefanten Löwen Giraffen und Zebras."
  ]),
  _CommaItem(
      "Für den Ausflug packen wir Regenjacke, Sonnenhut, Wasser und Jause.",
      <String>[
        "Für den Ausflug packen wir Regenjacke Sonnenhut Wasser und Jause.",
        "Für den Ausflug packen wir Regenjacke Sonnenhut, Wasser und Jause.",
        "Für den Ausflug packen wir, Regenjacke Sonnenhut Wasser und Jause."
      ]),
  _CommaItem("Am Himmel sehen wir Sonne, Mond, Sterne und Wolken.", <String>[
    "Am Himmel sehen wir Sonne Mond Sterne und Wolken.",
    "Am Himmel sehen wir Sonne Mond, Sterne und Wolken.",
    "Am Himmel sehen wir, Sonne Mond Sterne und Wolken."
  ]),
];
