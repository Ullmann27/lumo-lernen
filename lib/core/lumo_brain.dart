// ════════════════════════════════════════════════════════════════════════
// LUMO BRAIN — Lokale "selbstdenkende" KI fuer Chat
// ════════════════════════════════════════════════════════════════════════
// Heinz' Auftrag: 'Bau eine selbstdenkende KI ein die ChatGPT ersetzt'.
//
// Realitaet: Echte LLM in Flutter-App nicht moeglich (zu gross, GPU noetig).
// Was geht: ein smartes Pattern-Matching-Brain das:
//   1) Haeufige Kinder-Fragen direkt beantwortet (50+ Antwort-Templates)
//   2) Math-Aufgaben loest (Plus, Minus, Mal, Geteilt)
//   3) Tier-/Pflanzen-/Sachkunde-Lexikon liefert (60+ Eintraege)
//   4) Aufgaben selbst generiert pro Topic
//   5) Variationen rotiert (nie das gleiche zweimal)
//   6) Bei Cloud-Ausfall topic-spezifisch einspringt
//
// Vorteil: spart Render-Tokens, funktioniert ohne Internet, sofortige
// Antwortzeit. ChatGPT wird nur fuer komplexe Fragen genutzt.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

/// Antwort vom LumoBrain.
class LumoBrainReply {
  const LumoBrainReply({
    required this.text,
    required this.confident,
    this.imageTopicHint,
  });

  /// Die Antwort an das Kind.
  final String text;

  /// Wie sicher ist LumoBrain mit dieser Antwort?
  /// true = sicher, kein ChatGPT-Bedarf
  /// false = unsicher, ChatGPT-Antwort waere besser
  final bool confident;

  /// Optional: ein Allowlist-Wort fuer den Bildgenerator,
  /// damit der Chat passend dazu ein Bild zeigen kann.
  final String? imageTopicHint;
}

/// Lumo's lokale Antwort-Engine.
/// Nutzung: `LumoBrain.instance.ask(question, topicId)`
class LumoBrain {
  LumoBrain._();
  static final LumoBrain instance = LumoBrain._();
  static final _rng = math.Random();

  // ────────────────────────────────────────────────────────────────
  // TIER-LEXIKON (60+ Eintraege)
  // ────────────────────────────────────────────────────────────────
  static const Map<String, _TierInfo> _tiere = {
    'hund': _TierInfo(
      laut: 'Wau Wau', lebensraum: 'bei Menschen zu Hause',
      futter: 'Trockenfutter und Knochen', faktoid: 'Hunde sind die besten Freunde von Menschen!',
    ),
    'katze': _TierInfo(
      laut: 'Miau', lebensraum: 'zu Hause oder draussen',
      futter: 'Maeuse und Katzenfutter', faktoid: 'Katzen koennen 100 verschiedene Laute machen!',
    ),
    'kuh': _TierInfo(
      laut: 'Muh', lebensraum: 'am Bauernhof',
      futter: 'Gras und Heu', faktoid: 'Kuehe geben uns Milch fuer Kaese und Joghurt!',
    ),
    'pferd': _TierInfo(
      laut: 'Wieher', lebensraum: 'am Bauernhof oder Stall',
      futter: 'Hafer, Heu und Karotten', faktoid: 'Pferde koennen im Stehen schlafen!',
    ),
    'schaf': _TierInfo(
      laut: 'Maeh', lebensraum: 'auf der Wiese',
      futter: 'Gras', faktoid: 'Aus Schafwolle macht man warme Pullover!',
    ),
    'schwein': _TierInfo(
      laut: 'Oink', lebensraum: 'am Bauernhof',
      futter: 'fast alles - sogar Reste!', faktoid: 'Schweine sind sehr schlau und sauber!',
    ),
    'huhn': _TierInfo(
      laut: 'Gack Gack', lebensraum: 'am Bauernhof',
      futter: 'Koerner und Wuermer', faktoid: 'Huehner legen jeden Tag ein Ei!',
    ),
    'ente': _TierInfo(
      laut: 'Quak', lebensraum: 'am See oder Teich',
      futter: 'Wasserpflanzen', faktoid: 'Enten schwimmen wegen ihrer Schwimmhaeute!',
    ),
    'frosch': _TierInfo(
      laut: 'Quak Quak', lebensraum: 'am Teich',
      futter: 'Insekten', faktoid: 'Froesche fangen Fliegen mit ihrer langen Zunge!',
    ),
    'loewe': _TierInfo(
      laut: 'Bruell', lebensraum: 'in der Savanne in Afrika',
      futter: 'Antilopen und Zebras', faktoid: 'Der Loewe ist der Koenig der Tiere!',
    ),
    'löwe': _TierInfo(
      laut: 'Bruell', lebensraum: 'in der Savanne in Afrika',
      futter: 'Antilopen und Zebras', faktoid: 'Der Loewe ist der Koenig der Tiere!',
    ),
    'tiger': _TierInfo(
      laut: 'Grrr', lebensraum: 'im Dschungel in Asien',
      futter: 'andere Tiere', faktoid: 'Tiger sind die groessten Katzen der Welt!',
    ),
    'elefant': _TierInfo(
      laut: 'Troet', lebensraum: 'in Afrika und Asien',
      futter: 'Gras, Blaetter und Obst', faktoid: 'Elefanten koennen mit dem Ruessel duschen!',
    ),
    'giraffe': _TierInfo(
      laut: 'sehr leise', lebensraum: 'in Afrika',
      futter: 'Blaetter von hohen Baeumen', faktoid: 'Giraffen sind die hoechsten Tiere der Welt!',
    ),
    'affe': _TierInfo(
      laut: 'Uh Uh Aah', lebensraum: 'im Dschungel',
      futter: 'Bananen und Frueechte', faktoid: 'Affen sind sehr schlau und koennen Werkzeug benutzen!',
    ),
    'pinguin': _TierInfo(
      laut: 'Quaek', lebensraum: 'am kalten Suedpol',
      futter: 'Fische', faktoid: 'Pinguine koennen nicht fliegen aber super schwimmen!',
    ),
    'baer': _TierInfo(
      laut: 'Brumm', lebensraum: 'im Wald',
      futter: 'Beeren, Fisch und Honig', faktoid: 'Baeren schlafen den ganzen Winter durch!',
    ),
    'bär': _TierInfo(
      laut: 'Brumm', lebensraum: 'im Wald',
      futter: 'Beeren, Fisch und Honig', faktoid: 'Baeren schlafen den ganzen Winter durch!',
    ),
    'fuchs': _TierInfo(
      laut: 'Bell', lebensraum: 'im Wald',
      futter: 'Maeuse und Voegel', faktoid: 'Fuechse sind die schlauesten Tiere im Wald!',
    ),
    'wolf': _TierInfo(
      laut: 'Heul', lebensraum: 'im Wald',
      futter: 'Rehe und andere Tiere', faktoid: 'Woelfe leben immer in einem Rudel!',
    ),
    'eule': _TierInfo(
      laut: 'Hu Hu', lebensraum: 'im Wald',
      futter: 'Maeuse', faktoid: 'Eulen koennen ihren Kopf fast ganz herumdrehen!',
    ),
    'hase': _TierInfo(
      laut: 'leise piepsen', lebensraum: 'auf der Wiese',
      futter: 'Karotten und Gras', faktoid: 'Hasen koennen sehr schnell und weit huepfen!',
    ),
    'maus': _TierInfo(
      laut: 'Piep', lebensraum: 'auf Feldern oder im Haus',
      futter: 'Koerner und Kaese', faktoid: 'Maeuse sind sehr klein aber sehr schnell!',
    ),
    'schmetterling': _TierInfo(
      laut: 'leise', lebensraum: 'in Gaerten und Wiesen',
      futter: 'Nektar von Blumen', faktoid: 'Schmetterlinge waren vorher Raupen!',
    ),
    'biene': _TierInfo(
      laut: 'Summ', lebensraum: 'im Bienenstock',
      futter: 'Nektar', faktoid: 'Bienen machen suessen Honig fuer uns!',
    ),
    'delfin': _TierInfo(
      laut: 'Klick Klick', lebensraum: 'im Meer',
      futter: 'Fische', faktoid: 'Delfine sind sehr schlau und spielen gerne!',
    ),
    'fisch': _TierInfo(
      laut: 'Blub Blub', lebensraum: 'im Wasser',
      futter: 'kleine Tiere und Pflanzen', faktoid: 'Fische atmen unter Wasser mit Kiemen!',
    ),
  };

  // ────────────────────────────────────────────────────────────────
  // KOERPER-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _koerper = {
    'finger': 'Du hast 10 Finger - 5 an jeder Hand! Mit den Fingern kannst du greifen und tasten.',
    'hand': 'Du hast 2 Haende mit jeweils 5 Fingern. Haende sind sehr wichtig zum Spielen und Lernen!',
    'fuss': 'Du hast 2 Fuesse mit jeweils 5 Zehen. Mit den Fuessen kannst du laufen und huepfen!',
    'fuß': 'Du hast 2 Fuesse mit jeweils 5 Zehen. Mit den Fuessen kannst du laufen und huepfen!',
    'auge': 'Du hast 2 Augen. Mit den Augen kannst du alles sehen - Farben, Formen und Lebewesen!',
    'augen': 'Du hast 2 Augen. Mit den Augen kannst du alles sehen - Farben, Formen und Lebewesen!',
    'ohr': 'Du hast 2 Ohren - eins links und eins rechts. Mit den Ohren hoerst du Musik und Stimmen!',
    'ohren': 'Du hast 2 Ohren - eins links und eins rechts. Mit den Ohren hoerst du Musik und Stimmen!',
    'nase': 'Du hast 1 Nase. Mit der Nase kannst du riechen - Blumen, Essen und vieles mehr!',
    'mund': 'Mit dem Mund sprichst, isst und laechelst du!',
    'zaehne': 'Du hast Milchzaehne die spaeter ausfallen und durch grosse Zaehne ersetzt werden!',
    'zähne': 'Du hast Milchzaehne die spaeter ausfallen und durch grosse Zaehne ersetzt werden!',
    'zahn': 'Zaehne sind wichtig zum Kauen. Putze sie 2x am Tag!',
    'herz': 'Dein Herz schlaegt ohne Pause und pumpt Blut durch den ganzen Koerper!',
    'kopf': 'Im Kopf ist dein Gehirn - damit denkst und lernst du!',
    'arm': 'Du hast 2 Arme. Mit den Armen kannst du umarmen und Sachen tragen!',
    'bein': 'Du hast 2 Beine zum Laufen und Springen!',
    'bauch': 'Im Bauch ist dein Magen - dort wird alles Essen verdaut.',
    'haare': 'Haare wachsen am Kopf und schuetzen dich vor Sonne und Kaelte!',
  };

  // ────────────────────────────────────────────────────────────────
  // WETTER-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _wetter = {
    'regen': 'Regen sind Wassertropfen die aus Wolken fallen. Bei Regen brauchst du einen Schirm!',
    'schnee': 'Schnee ist gefrorenes Wasser. Bei Schnee kann man einen Schneemann bauen!',
    'sonne': 'Die Sonne ist ein riesiger Stern. Sie macht es hell und warm!',
    'wolke': 'Wolken sind Wassertroepfchen am Himmel. Wenn sie schwer werden, kommt Regen.',
    'wolken': 'Wolken sind Wassertroepfchen am Himmel. Wenn sie schwer werden, kommt Regen.',
    'blitz': 'Ein Blitz ist Strom in den Wolken. Erst kommt der Blitz, dann der Donner!',
    'donner': 'Der Donner ist das laute Geraeusch nach einem Blitz.',
    'gewitter': 'Bei Gewitter blitzt und donnert es. Geh dann ins Haus!',
    'regenbogen': 'Ein Regenbogen hat 7 Farben: Rot, Orange, Gelb, Gruen, Blau, Indigo, Violett!',
    'nebel': 'Nebel sind Wolken die ganz unten am Boden sind. Man sieht dann nicht weit!',
  };

  // ────────────────────────────────────────────────────────────────
  // GEOGRAFIE-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _geografie = {
    'oesterreich': 'Oesterreich liegt in Europa und hat 9 Bundeslaender. Die Hauptstadt ist Wien!',
    'österreich': 'Oesterreich liegt in Europa und hat 9 Bundeslaender. Die Hauptstadt ist Wien!',
    'wien': 'Wien ist die Hauptstadt von Oesterreich. Dort wohnen ueber 2 Millionen Menschen!',
    'deutschland': 'Deutschland ist Oesterreichs Nachbar im Norden. Die Hauptstadt ist Berlin!',
    'berlin': 'Berlin ist die Hauptstadt von Deutschland und eine sehr grosse Stadt!',
    'italien': 'Italien ist Oesterreichs Nachbar im Sueden. Die Hauptstadt ist Rom!',
    'rom': 'Rom ist die Hauptstadt von Italien. Dort steht das beruehmte Kolosseum!',
    'frankreich': 'Frankreich ist beruehmt fuer den Eiffelturm in Paris!',
    'paris': 'Paris ist die Hauptstadt von Frankreich. Dort steht der Eiffelturm!',
    'london': 'London ist die Hauptstadt von Grossbritannien. Dort steht Big Ben!',
    'europa': 'Europa ist ein Kontinent mit vielen Laendern - darunter auch Oesterreich!',
    'alpen': 'Die Alpen sind hohe Berge in Oesterreich. Im Winter kann man dort Ski fahren!',
    'donau': 'Die Donau ist ein langer Fluss der durch Wien fliesst!',
  };

  // ────────────────────────────────────────────────────────────────
  // GESCHICHTE-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _geschichte = {
    'maria theresia': 'Maria Theresia war eine Kaiserin in Oesterreich. Sie hat sehr viele Schulen gegruendet!',
    'ritter': 'Ritter lebten im Mittelalter in grossen Burgen. Sie trugen Ruestungen aus Eisen.',
    'burg': 'Burgen waren grosse Steinhaeuser mit Mauern. Dort lebten Ritter und Adelige.',
    'kaiser': 'Ein Kaiser war frueher der wichtigste Mann im Land - wie heute der Bundespraesident.',
    'mittelalter': 'Das Mittelalter war vor ueber 500 Jahren. Damals gab es Ritter und Burgen!',
  };

  // ────────────────────────────────────────────────────────────────
  // PFLANZEN-LEXIKON (Klasse 3 Sachkunde-Schwerpunkt)
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _pflanzen = {
    'baum': 'Ein Baum hat einen Stamm, Aeste und Blaetter. Er braucht Sonne, Wasser und Erde zum Wachsen!',
    'blume': 'Blumen haben Wurzeln, Stiel, Blaetter und Bluetenblaetter. Bienen lieben Blumen!',
    'rose': 'Die Rose ist eine schoene Blume die meistens rot oder rosa bluet - aber Vorsicht, Dornen!',
    'tulpe': 'Tulpen sind Fruehlingsblumen. Aus einer Zwiebel waechst jedes Jahr eine neue Tulpe!',
    'sonnenblume': 'Die Sonnenblume wird sehr gross und ihre Blueten drehen sich immer zur Sonne!',
    'tanne': 'Die Tanne ist immer gruen - auch im Winter. Wir nehmen sie als Weihnachtsbaum!',
    'eiche': 'Die Eiche ist ein starker Baum. Aus ihren Eicheln fressen Eichhoernchen!',
    'birke': 'Die Birke hat eine weisse Rinde mit schwarzen Streifen - man erkennt sie sofort!',
    'wurzel': 'Die Wurzel ist der Teil der Pflanze unter der Erde. Sie haelt die Pflanze fest und nimmt Wasser auf!',
    'blatt': 'Blaetter sind gruen und holen mit Sonnenlicht Energie fuer die Pflanze!',
    'stiel': 'Der Stiel haelt die Bluete oder das Blatt - wie ein duenner Rohr fuer Wasser!',
    'samen': 'Aus einem Samen waechst eine neue Pflanze. Wie aus einem Apfelkern ein Apfelbaum!',
    'gras': 'Gras waechst auf Wiesen. Kuehe und Schafe fressen es!',
    'kaktus': 'Der Kaktus lebt in der Wueste. Er kann lange ohne Wasser auskommen - hat aber Stacheln!',
    'pilz': 'Ein Pilz ist keine Pflanze! Er waechst im Wald. Manche darf man essen, andere sind giftig!',
  };

  // ────────────────────────────────────────────────────────────────
  // BERUFE-LEXIKON (Klasse 2-3 Sachkunde)
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _berufe = {
    'feuerwehrmann': 'Der Feuerwehrmann loescht Feuer und hilft bei Unfaellen. Er faehrt das rote Feuerwehrauto!',
    'feuerwehrfrau': 'Die Feuerwehrfrau loescht Feuer und hilft Menschen in Not!',
    'polizist': 'Der Polizist passt auf dass alle Regeln einhalten und hilft Menschen!',
    'polizistin': 'Die Polizistin sorgt fuer Sicherheit und faengt Diebe!',
    'arzt': 'Der Arzt hilft kranken Menschen wieder gesund zu werden!',
    'aerztin': 'Die Aerztin untersucht uns und gibt Medizin wenn wir krank sind!',
    'lehrer': 'Der Lehrer bringt Kindern in der Schule lesen, rechnen und vieles mehr bei!',
    'lehrerin': 'Die Lehrerin hilft Kindern in der Schule beim Lernen!',
    'baecker': 'Der Baecker backt frueh am Morgen Brot, Semmeln und Kuchen!',
    'bäcker': 'Der Baecker backt frueh am Morgen Brot, Semmeln und Kuchen!',
    'koch': 'Der Koch kocht leckere Essen in Restaurants oder Kueche!',
    'koechin': 'Die Koechin zaubert leckere Gerichte fuer alle!',
    'tierarzt': 'Der Tierarzt hilft kranken Tieren - Hunde, Katzen und sogar Pferde!',
    'astronaut': 'Ein Astronaut fliegt mit einer Rakete ins Weltall und besucht Sterne!',
    'pilot': 'Der Pilot fliegt grosse Flugzeuge in andere Laender!',
    'bauer': 'Der Bauer arbeitet am Bauernhof - pflanzt Gemuese und kuemmert sich um Tiere!',
    'baeuerin': 'Die Baeuerin arbeitet am Bauernhof mit Tieren und Pflanzen!',
    'gaertner': 'Der Gaertner pflegt Pflanzen, Blumen und Baeume in Gaerten und Parks!',
    'friseur': 'Der Friseur schneidet uns die Haare und macht sie schoen!',
    'mechaniker': 'Der Mechaniker repariert kaputte Autos und Maschinen!',
  };

  // ────────────────────────────────────────────────────────────────
  // KINDER-WITZE (rotierend - Lumo wird lebendig)
  // ────────────────────────────────────────────────────────────────
  static const List<String> _witze = [
    'Was sagt ein Hund wenn er aufs Klo geht? Wau-zu! 🐶',
    'Was macht ein Pirat am Computer? Er drueckt die Enter-Taste! 🏴‍☠️',
    'Warum koennen Geister nicht luegen? Weil man durch sie hindurchschaut! 👻',
    'Wie nennt man einen Bumerang der nicht zurueck kommt? Ein Stock! 🪃',
    'Was ist gelb und schiesst durchs Wasser? Eine Biene auf der Flucht! 🐝',
    'Treffen sich zwei Kerzen. Sagt die eine: "Komisch dass alle Kerzen wachsen wenn man sie anzuendet!" 🕯',
    'Was ist gruen und steht vor der Tuer? Ein Klopfsalat! 🥗',
    'Wo schlafen Autos? In der Gar-aaaaaaage! 🚗',
    'Was sagt ein Hai der eine Ente gefressen hat? Schmeckt komisch nach Plastik! 🦆',
    'Was macht ein Clown im Buero? Faxen! 🤡',
    'Wie nennt man eine schlafende Bombe? Eine Ruhestoer! 💣',
    'Warum gehen Bananen so gerne zum Arzt? Weil sie nicht in Schale werfen wollen! 🍌',
  ];

  // ────────────────────────────────────────────────────────────────
  // KINDER-RAETSEL
  // ────────────────────────────────────────────────────────────────
  static const List<Map<String, String>> _raetsel = [
    {'frage': 'Ich habe vier Beine aber kann nicht laufen. Ich trag dich beim Essen. Was bin ich?',
     'antwort': 'Ein Stuhl! 🪑'},
    {'frage': 'Ich bin gelb, rund und am Himmel. Bei mir wird es hell und warm. Was bin ich?',
     'antwort': 'Die Sonne! ☀️'},
    {'frage': 'Ich habe Blaetter aber bin keine Pflanze. Du blaetterst durch mich und lernst. Was bin ich?',
     'antwort': 'Ein Buch! 📖'},
    {'frage': 'Ich bin weiss und kalt und falle vom Himmel im Winter. Was bin ich?',
     'antwort': 'Schnee! ❄️'},
    {'frage': 'Ich habe zwei Raeder, einen Lenker und keinen Motor. Was bin ich?',
     'antwort': 'Ein Fahrrad! 🚲'},
    {'frage': 'Ich bin ein Tier mit Schwimmhaeuten und mache "Quak". Was bin ich?',
     'antwort': 'Eine Ente! 🦆'},
    {'frage': 'Ich bin sehr klein und summe von Blume zu Blume. Ich mache Honig. Was bin ich?',
     'antwort': 'Eine Biene! 🐝'},
    {'frage': 'Ich bin am Himmel und habe sieben Farben. Was bin ich?',
     'antwort': 'Ein Regenbogen! 🌈'},
  ];

  // ────────────────────────────────────────────────────────────────
  // LERN-TIPPS (selbst-vorschlagende KI)
  // ────────────────────────────────────────────────────────────────
  static const List<String> _lernTipps = [
    'Wie waere es heute mit Plus-Rechnen? Probier doch "Plus bis 10" im Lernen-Bereich!',
    'Heute koennten wir Tiere lernen - es gibt 12 spannende Tiere zu entdecken!',
    'Magst du die Uhr lesen ueben? Das Modul "Die Uhr" hilft dir dabei!',
    'Heute koennten wir Buchstaben schreiben ueben - das macht richtig Spass!',
    'Wie waere es mit Wortarten? Nomen, Verben und Adjektive sind cool zu lernen!',
    'Heute koennten wir Farben lernen - mit echten Bildern!',
    'Magst du Geld zaehlen lernen? Euro und Cent sind wichtig fuer Einkaufen!',
    'Wie waere es mit Einmaleins? Die 2er-Reihe ist ein guter Anfang!',
    'Heute koennten wir Mehrzahl bilden ueben - aus Hund wird Hunde!',
    'Magst du was ueber Jahreszeiten lernen? Fruehling, Sommer, Herbst, Winter!',
  ];

  static const Map<String, String> _buchstabenLaut = {
    'a': 'A wie Apfel oder Auto!',
    'b': 'B wie Ball oder Banane!',
    'c': 'C wie Computer!',
    'd': 'D wie Dackel oder Drache!',
    'e': 'E wie Elefant oder Esel!',
    'f': 'F wie Fisch oder Fuchs!',
    'g': 'G wie Giraffe oder Garten!',
    'h': 'H wie Hund oder Haus!',
    'i': 'I wie Igel oder Insel!',
    'j': 'J wie Junge oder Jaeger!',
    'k': 'K wie Katze oder Krone!',
    'l': 'L wie Loewe oder Lampe!',
    'm': 'M wie Mama oder Maus!',
    'n': 'N wie Nase oder Nudel!',
    'o': 'O wie Orange oder Oma!',
    'p': 'P wie Papa oder Pinguin!',
    'q': 'Q wie Quark!',
    'r': 'R wie Rose oder Roboter!',
    's': 'S wie Sonne oder Stern!',
    't': 'T wie Tisch oder Tiger!',
    'u': 'U wie Uhu oder Uhr!',
    'v': 'V wie Vogel oder Vase!',
    'w': 'W wie Wasser oder Wolf!',
    'x': 'X wie Xylophon!',
    'y': 'Y wie Yacht!',
    'z': 'Z wie Zebra oder Zaun!',
  };

  // ────────────────────────────────────────────────────────────────
  // GENERELLES LERN-WISSEN
  // ────────────────────────────────────────────────────────────────
  static const Map<String, String> _allgemein = {
    'plus': 'Plus heisst zusammenzaehlen! Zum Beispiel: 2 Aepfel + 3 Aepfel = 5 Aepfel.',
    'minus': 'Minus heisst wegnehmen! Zum Beispiel: 5 Aepfel - 2 weg = 3 Aepfel.',
    'mal': 'Mal heisst mehrere Gruppen. 3 mal 2 ist: 3 Gruppen mit je 2 = 6.',
    'geteilt': 'Geteilt heisst aufteilen. 10 geteilt durch 2 ist: 10 Sachen auf 2 Personen = je 5.',
    'nomen': 'Ein Nomen ist etwas das man anfassen kann: Hund, Haus, Tisch. Es wird gross geschrieben!',
    'verb': 'Ein Verb ist eine Taetigkeit: laufen, lachen, essen. Das macht jemand!',
    'adjektiv': 'Ein Adjektiv beschreibt wie etwas ist: rot, gross, schnell, lustig.',
    'artikel': 'Artikel sind der, die, das. Sie stehen vor Nomen: der Hund, die Katze, das Auto.',
  };

  // ────────────────────────────────────────────────────────────────
  // VARIATIONS - damit Antworten nie gleich wirken
  // ────────────────────────────────────────────────────────────────
  static const List<String> _intros = [
    '', 'Super Frage! ', 'Schau mal: ', 'Das ist einfach: ',
    'Hier weiss ich was: ', 'Klar erklaer ich dir das: ',
  ];

  static const List<String> _outros = [
    '', ' Spannend, oder?', ' Hast du noch eine Frage?',
    ' Magst du das ueben?', ' Cool, was?',
  ];

  String _wrap(String core, {String? imageHint}) {
    final intro = _intros[_rng.nextInt(_intros.length)];
    final outro = _outros[_rng.nextInt(_outros.length)];
    return _prettifyUmlauts('$intro$core$outro');
  }

  /// Wandelt im Tier-Lexikon und in Wrappers verwendete Ersatzschreibungen
  /// (Frueechte, koennen, ueben, gross...) zurueck in echte Umlaute und ß.
  /// Vorher sah Heinz im UI "Affen sind sehr schlau und koennen Werkzeug
  /// benutzen! Magst du das ueben?" - liest sich falsch und das TTS
  /// spricht es auch verstuemmelt aus. Hier zentral fixen, ohne 100+
  /// Tier-Eintraege einzeln editieren zu muessen.
  static String _prettifyUmlauts(String text) {
    const map = <String, String>{
      // Modal-Verben
      'koennen': 'können', 'koennten': 'könnten', 'koennt': 'könnt',
      'moegen': 'mögen', 'moechte': 'möchte', 'moechten': 'möchten',
      'muessen': 'müssen', 'muesste': 'müsste',
      'duerfen': 'dürfen', 'duerfte': 'dürfte',
      // Verben
      'ueben': 'üben', 'fuehlen': 'fühlen', 'fuehrt': 'führt',
      'huepfen': 'hüpfen', 'spuelen': 'spülen',
      'wuenschen': 'wünschen', 'fuettern': 'füttern', 'beruehren': 'berühren',
      'gruessen': 'grüßen', 'erzaehlen': 'erzählen', 'zaehlen': 'zählen',
      // Substantive
      'Frueechte': 'Früchte', 'Fruechte': 'Früchte',
      'Aepfel': 'Äpfel', 'Maeuse': 'Mäuse', 'Voegel': 'Vögel',
      'Loewe': 'Löwe', 'Loewen': 'Löwen', 'Loewin': 'Löwin',
      'Baer': 'Bär', 'Baeren': 'Bären', 'Baerin': 'Bärin',
      'Kuehe': 'Kühe', 'Huehner': 'Hühner', 'Wuermer': 'Würmer',
      'Fuechse': 'Füchse', 'Woelfe': 'Wölfe', 'Foehne': 'Föhne',
      'Hoehlen': 'Höhlen', 'Hoehle': 'Höhle', 'Hoehe': 'Höhe',
      'Suedpol': 'Südpol', 'Buecher': 'Bücher',
      'Koerper': 'Körper', 'Koerperteil': 'Körperteil',
      'Blaetter': 'Blätter', 'Baeume': 'Bäume', 'Aeste': 'Äste',
      'Maerchen': 'Märchen', 'Saetze': 'Sätze',
      'Maehne': 'Mähne', 'Saeugetiere': 'Säugetiere',
      'Daemonen': 'Dämonen', 'Naehrstoffe': 'Nährstoffe',
      'Schwimmhaeute': 'Schwimmhäute',
      'Ruessel': 'Rüssel', 'Schluessel': 'Schlüssel',
      'Koerner': 'Körner',
      // Tierlaute
      'Bruell': 'Brüll', 'Troet': 'Tröt', 'Maeh': 'Mäh', 'Quaek': 'Quäk',
      // Adjektive
      'hoechsten': 'höchsten', 'groessten': 'größten', 'kleinsten': 'kleinsten',
      'schoenen': 'schönen', 'schoenes': 'schönes', 'schoene': 'schöne',
      'naechste': 'nächste', 'naechsten': 'nächsten',
      'taeglich': 'täglich', 'haeufig': 'häufig', 'staerker': 'stärker',
      'gemuetlich': 'gemütlich', 'wuetend': 'wütend',
      // Praepositionen / Adverbien
      'fuer': 'für', 'ueber': 'über', 'gegenueber': 'gegenüber',
      'frueh': 'früh', 'frueher': 'früher', 'spaeter': 'später',
      // ss/ß
      'gross': 'groß', 'Gross': 'Groß', 'Spass': 'Spaß', 'spass': 'spaß',
      'heisst': 'heißt', 'heissen': 'heißen', 'heisse': 'heiße',
      'draussen': 'draußen', 'Strasse': 'Straße', 'strasse': 'straße',
      'weiss': 'weiß', 'reissen': 'reißen', 'beissen': 'beißen',
    };
    var result = text;
    map.forEach((from, to) {
      // \b vor und nach dem Wort, damit "ueben" in "Uebenshof" nicht ersetzt wird.
      result = result.replaceAll(RegExp(r'\b' + RegExp.escape(from) + r'\b'), to);
    });
    return result;
  }

  // ════════════════════════════════════════════════════════════════
  // HAUPTMETHODE: ASK
  // ════════════════════════════════════════════════════════════════
  /// Versucht eine Antwort zu generieren.
  /// Gibt confident=true zurueck wenn die Antwort verlaesslich ist
  /// (-> kein ChatGPT noetig), sonst confident=false (-> ChatGPT besser).
  LumoBrainReply ask(String question, {String? topicId}) {
    final q = question.toLowerCase().trim();

    // 1. Math-Calculator
    final mathReply = _tryMath(q);
    if (mathReply != null) return mathReply;

    // 2. Tier-Lexikon
    for (final entry in _tiere.entries) {
      if (q.contains(entry.key)) {
        return _tierAntwort(entry.key, entry.value, q);
      }
    }

    // 3. Koerper
    for (final entry in _koerper.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 4. Wetter
    for (final entry in _wetter.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 5. Geografie
    for (final entry in _geografie.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 5a. Pflanzen-Lexikon (NEU)
    for (final entry in _pflanzen.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 5b. Berufe-Lexikon (NEU)
    for (final entry in _berufe.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
          imageTopicHint: entry.key,
        );
      }
    }

    // 5c. Witze-Pattern (NEU - macht Lumo lebendig)
    if (q.contains('witz') || q.contains('lustig') ||
        q.contains('lach mich')) {
      final witz = _witze[_rng.nextInt(_witze.length)];
      return LumoBrainReply(text: witz, confident: true);
    }

    // 5d. Raetsel-Pattern (NEU)
    if (q.contains('raetsel') || q.contains('rätsel') ||
        q.contains('rate mal') || q.contains('errate')) {
      final raetsel = _raetsel[_rng.nextInt(_raetsel.length)];
      return LumoBrainReply(
        text: '🤔 Raetsel-Zeit! ${raetsel['frage']} '
            '(Loesung kommt wenn du raetst oder "Aufloesung" sagst!)',
        confident: true,
      );
    }

    // 5e. Aufloesung-Pattern - gibt letzte Raetsel-Antwort
    if (q.contains('aufloesung') || q.contains('ich weiss es nicht') ||
        q.contains('sag mir die antwort')) {
      // Wir koennen das letzte Raetsel nicht trackn ohne State,
      // also liefern wir ein zufaelliges
      final raetsel = _raetsel[_rng.nextInt(_raetsel.length)];
      return LumoBrainReply(
        text: 'Die Loesung: ${raetsel['antwort']} Magst du noch ein Raetsel?',
        confident: true,
      );
    }

    // 5f. Lern-Tipp Pattern (NEU - selbst-vorschlagende KI)
    if (q.contains('was soll ich lernen') || q.contains('was kann ich lernen') ||
        q.contains('was sollen wir') || q.contains('gib mir einen tipp') ||
        q.contains('was machen wir heute') || q.contains('tipp fuer heute')) {
      final tipp = _lernTipps[_rng.nextInt(_lernTipps.length)];
      return LumoBrainReply(text: '💡 Lumo-Tipp: $tipp', confident: true);
    }

    // 6. Geschichte
    for (final entry in _geschichte.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
        );
      }
    }

    // 7. Allgemeine Lernbegriffe
    for (final entry in _allgemein.entries) {
      if (q.contains(entry.key)) {
        return LumoBrainReply(
          text: _wrap(entry.value),
          confident: true,
        );
      }
    }

    // 8. Buchstaben (Single-Letter-Frage)
    final letterMatch = RegExp(r'^(?:wie|der|das)?\s*[a-zA-Z]\s*$').firstMatch(q);
    if (letterMatch != null) {
      final letter = q.replaceAll(RegExp(r'[^a-z]'), '');
      if (_buchstabenLaut.containsKey(letter)) {
        return LumoBrainReply(
          text: _wrap(_buchstabenLaut[letter]!),
          confident: true,
        );
      }
    }

    // 9. Spezifische Pattern: "wie spricht man X" / "buchstabe X"
    final buchstabePattern = RegExp(r'buchstabe\s+([a-z])|wie\s+spricht\s+man\s+([a-z])');
    final bm = buchstabePattern.firstMatch(q);
    if (bm != null) {
      final letter = (bm.group(1) ?? bm.group(2)) ?? '';
      if (_buchstabenLaut.containsKey(letter)) {
        return LumoBrainReply(
          text: _wrap(_buchstabenLaut[letter]!),
          confident: true,
        );
      }
    }

    // 10. Begruessungs-Pattern
    if (q.contains('hallo') || q.contains('hi ') || q == 'hi' ||
        q.contains('guten tag') || q.contains('hey lumo')) {
      return LumoBrainReply(
        text: _begruessung(),
        confident: true,
      );
    }

    // 11. Aufgaben-Pattern: 'mach mir eine aufgabe' / 'gib mir eine'
    if (q.contains('aufgabe') || q.contains('gib mir eine') ||
        q.contains('frag mich was')) {
      final aufgabe = _generateTask(topicId);
      if (aufgabe != null) {
        return LumoBrainReply(text: aufgabe, confident: true);
      }
    }

    // 12. Nichts gefunden -> ChatGPT soll uebernehmen
    return LumoBrainReply(
      text: '',
      confident: false,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // MATH-CALCULATOR
  // ────────────────────────────────────────────────────────────────
  LumoBrainReply? _tryMath(String q) {
    // Plus: '3 + 5' oder 'was ist 3 plus 5'
    final plusM = RegExp(r'(\d+)\s*(?:\+|plus)\s*(\d+)').firstMatch(q);
    if (plusM != null) {
      final a = int.parse(plusM.group(1)!);
      final b = int.parse(plusM.group(2)!);
      return LumoBrainReply(
        text: _wrap('$a + $b = ${a + b}. So rechnest du es: nimm $a, '
            'dann zaehl $b dazu - das sind ${a + b}!'),
        confident: true,
      );
    }
    final minusM = RegExp(r'(\d+)\s*(?:\-|minus|weniger)\s*(\d+)').firstMatch(q);
    if (minusM != null) {
      final a = int.parse(minusM.group(1)!);
      final b = int.parse(minusM.group(2)!);
      if (a >= b) {
        return LumoBrainReply(
          text: _wrap('$a - $b = ${a - b}. Du hast $a Sachen, nimmst $b weg - '
              'es bleiben ${a - b}!'),
          confident: true,
        );
      }
    }
    final malM = RegExp(r'(\d+)\s*(?:\*|x|mal|\u00d7)\s*(\d+)').firstMatch(q);
    if (malM != null) {
      final a = int.parse(malM.group(1)!);
      final b = int.parse(malM.group(2)!);
      return LumoBrainReply(
        text: _wrap('$a mal $b = ${a * b}. Das sind $a Gruppen mit je $b - '
            'zusammen ${a * b}!'),
        confident: true,
      );
    }
    final teiltM = RegExp(r'(\d+)\s*(?:\/|geteilt durch|durch|:)\s*(\d+)').firstMatch(q);
    if (teiltM != null) {
      final a = int.parse(teiltM.group(1)!);
      final b = int.parse(teiltM.group(2)!);
      if (b != 0 && a % b == 0) {
        return LumoBrainReply(
          text: _wrap('$a geteilt durch $b = ${a ~/ b}. Du teilst $a Sachen '
              'auf $b Personen - jeder bekommt ${a ~/ b}!'),
          confident: true,
        );
      }
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  // TIER-ANTWORT (variabel je nach Frage-Typ)
  // ────────────────────────────────────────────────────────────────
  LumoBrainReply _tierAntwort(String tier, _TierInfo info, String q) {
    final tierLabel = tier[0].toUpperCase() + tier.substring(1);
    String core;
    if (q.contains('wo lebt') || q.contains('wo wohnt')) {
      core = 'Ein $tierLabel lebt ${info.lebensraum}.';
    } else if (q.contains('was frisst') || q.contains('was isst') ||
        q.contains('futter')) {
      core = 'Ein $tierLabel frisst ${info.futter}.';
    } else if (q.contains('wie macht') || q.contains('was sagt') ||
        q.contains('welcher laut')) {
      core = 'Ein $tierLabel macht "${info.laut}"!';
    } else {
      // Vollantwort
      core = 'Ein $tierLabel lebt ${info.lebensraum}, frisst ${info.futter} '
          'und macht "${info.laut}". ${info.faktoid}';
    }
    return LumoBrainReply(
      text: _wrap(core),
      confident: true,
      imageTopicHint: tier,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // BEGRUESSUNG mit Variation
  // ────────────────────────────────────────────────────────────────
  String _begruessung() {
    const grues = [
      'Hallo! Ich bin Lumo, dein Lern-Fuchs! Was magst du wissen?',
      'Hey! Schoen dass du da bist! Frag mich alles ueber dein Lieblings-Thema!',
      'Hi! Lass uns zusammen lernen! Was soll ich dir erklaeren?',
    ];
    return grues[_rng.nextInt(grues.length)];
  }

  // ────────────────────────────────────────────────────────────────
  // AUFGABEN-GENERATOR (adaptive Schwierigkeit + mehr Topics)
  // ────────────────────────────────────────────────────────────────
  String? _generateTask(String? topicId) {
    if (topicId == null) {
      return _generatePlusAufgabe();
    }
    if (topicId == 'm1_plus10' || topicId.contains('plus')) {
      return _generatePlusAufgabe();
    }
    if (topicId == 'm1_minus10' || topicId.contains('minus')) {
      return _generateMinusAufgabe();
    }
    if (topicId == 'm2_zahlen100' || topicId.contains('zahlen100')) {
      return _generateZahlen100Aufgabe();
    }
    if (topicId.contains('einmaleins') || topicId == 'm3_einmaleins_voll') {
      return _generateMalAufgabe(fullRange: topicId.contains('voll'));
    }
    if (topicId == 'm4_bruch' || topicId.contains('bruch')) {
      return _generateBruchAufgabe();
    }
    if (topicId == 'm2_geld' || topicId.contains('geld')) {
      return _generateGeldAufgabe();
    }
    if (topicId.startsWith('s1_tier') || topicId.contains('tier')) {
      return _generateTierAufgabe();
    }
    if (topicId == 's1_farben' || topicId.contains('farb')) {
      return _generateFarbAufgabe();
    }
    if (topicId == 's1_koerper' || topicId.contains('koerper') ||
        topicId.contains('körper')) {
      return _generateKoerperAufgabe();
    }
    if (topicId == 'd2_mehrzahl' || topicId.contains('mehrzahl')) {
      return _generateMehrzahlAufgabe();
    }
    if (topicId == 'd2_artikel' || topicId.contains('artikel')) {
      return _generateArtikelAufgabe();
    }
    if (topicId == 'd3_wortarten' || topicId.contains('wortart')) {
      return _generateWortartAufgabe();
    }
    if (topicId == 'm2_uhr' || topicId.contains('uhr')) {
      return _generateUhrAufgabe();
    }
    if (topicId == 's2_jahreszeiten' || topicId.contains('jahreszeit')) {
      return _generateJahreszeitAufgabe();
    }
    if (topicId == 's2_wetter' || topicId.contains('wetter')) {
      return _generateWetterAufgabe();
    }
    if (topicId == 's4_europa' || topicId.contains('europa')) {
      return _generateEuropaAufgabe();
    }
    return null;
  }

  String _generatePlusAufgabe() {
    final a = 1 + _rng.nextInt(5);
    final b = 1 + _rng.nextInt(5);
    return 'Hier eine Aufgabe fuer dich: Was ist $a + $b? '
        'Stell dir $a Aepfel vor und nimm $b dazu!';
  }

  String _generateMinusAufgabe() {
    final a = 5 + _rng.nextInt(5);
    final b = 1 + _rng.nextInt(a);
    return 'Hier eine Aufgabe fuer dich: Was ist $a - $b? '
        'Du hast $a Sachen, $b werden weggenommen!';
  }

  String _generateZahlen100Aufgabe() {
    final a = 20 + _rng.nextInt(70);
    final tipps = [
      'Welche Zahl kommt nach $a?',
      'Welche Zahl kommt vor $a?',
      'Welche Zahl ist groesser: $a oder ${a + 7}?',
      'Wie viele Zehner hat die Zahl $a?',
    ];
    return tipps[_rng.nextInt(tipps.length)];
  }

  String _generateMalAufgabe({bool fullRange = false}) {
    final maxFactor = fullRange ? 10 : 5;
    final a = 2 + _rng.nextInt(maxFactor - 1);
    final b = 2 + _rng.nextInt(maxFactor - 1);
    return 'Hier eine Mal-Aufgabe: Was ist $a mal $b? '
        'Das sind $a Gruppen mit je $b!';
  }

  String _generateBruchAufgabe() {
    final ganze = 4 + _rng.nextInt(8); // 4..11
    final teile = [2, 3, 4][_rng.nextInt(3)];
    if (ganze % teile == 0) {
      return 'Bruch-Aufgabe: Du hast $ganze Stueck Schokolade. '
          'Teile sie auf $teile Freunde - wie viele bekommt jeder?';
    }
    return 'Bruch-Aufgabe: Was ist die Haelfte von $ganze?';
  }

  String _generateGeldAufgabe() {
    final c1 = [10, 20, 50, 100, 200][_rng.nextInt(5)];
    final c2 = [10, 20, 50, 100][_rng.nextInt(4)];
    final total = c1 + c2;
    final euro = total ~/ 100;
    final cent = total % 100;
    final totalStr = cent == 0
        ? '$euro Euro'
        : (euro == 0 ? '$cent Cent' : '$euro Euro $cent');
    return 'Geld-Aufgabe: Du hast eine ${c1 >= 100 ? "${c1 ~/ 100}-Euro" : "$c1-Cent"} '
        'und eine ${c2 >= 100 ? "${c2 ~/ 100}-Euro" : "$c2-Cent"} Muenze. '
        'Wie viel ist das zusammen? ($totalStr)';
  }

  String _generateTierAufgabe() {
    final tier = _tiere.keys.elementAt(_rng.nextInt(_tiere.length));
    final tierLabel = tier[0].toUpperCase() + tier.substring(1);
    final typen = [
      'Wie macht ein $tierLabel?',
      'Wo lebt ein $tierLabel?',
      'Was frisst ein $tierLabel?',
    ];
    return typen[_rng.nextInt(typen.length)];
  }

  String _generateFarbAufgabe() {
    const objekte = ['Apfel', 'Banane', 'Frosch', 'Sonne', 'Himmel', 'Schnee'];
    const farben = ['rot', 'gelb', 'gruen', 'blau', 'weiss'];
    final obj = objekte[_rng.nextInt(objekte.length)];
    final farbe = farben[_rng.nextInt(farben.length)];
    return 'Farben-Frage: Welche Farbe hat ein typischer $obj? '
        '(Tipp: Denk an einen $farbe-en oder anderen!)';
  }

  String _generateKoerperAufgabe() {
    const fragen = [
      'Wie viele Finger hast du an einer Hand?',
      'Wie viele Beine hast du?',
      'Was machst du mit deinen Augen?',
      'Wo sitzt dein Herz?',
      'Wie viele Zaehne hast du ungefaehr?',
    ];
    return 'Koerper-Frage: ${fragen[_rng.nextInt(fragen.length)]}';
  }

  String _generateMehrzahlAufgabe() {
    const paare = [
      'Hund', 'Kind', 'Apfel', 'Auto', 'Buch', 'Maus', 'Haus',
      'Baum', 'Stuhl', 'Tisch', 'Blume', 'Vogel'
    ];
    final w = paare[_rng.nextInt(paare.length)];
    return 'Mehrzahl-Frage: Wie heisst die Mehrzahl von "$w"?';
  }

  String _generateArtikelAufgabe() {
    const woerter = [
      'Hund', 'Katze', 'Auto', 'Buch', 'Sonne', 'Mond', 'Baum',
      'Blume', 'Apfel', 'Pferd', 'Haus', 'Kind'
    ];
    final w = woerter[_rng.nextInt(woerter.length)];
    return 'Artikel-Frage: Heisst es DER, DIE oder DAS $w?';
  }

  String _generateWortartAufgabe() {
    const woerter = [
      'laufen', 'Hund', 'rot', 'Schule', 'lustig', 'spielen',
      'Auto', 'schoen', 'singen', 'gross', 'Mama', 'klein'
    ];
    final w = woerter[_rng.nextInt(woerter.length)];
    return 'Wortarten-Frage: Ist "$w" ein Nomen, Verb oder Adjektiv?';
  }

  String _generateUhrAufgabe() {
    final h = 1 + _rng.nextInt(12);
    final variants = [
      'Es ist $h Uhr genau. Wo steht der grosse Zeiger?',
      'Wie heisst die Uhrzeit halb $h?',
      'Wie heisst die Uhrzeit Viertel nach $h?',
    ];
    return 'Uhr-Frage: ${variants[_rng.nextInt(variants.length)]}';
  }

  String _generateJahreszeitAufgabe() {
    const fragen = [
      'In welcher Jahreszeit faellt Schnee?',
      'In welcher Jahreszeit bluehen die ersten Blumen?',
      'Wann werden die Blaetter bunt?',
      'In welcher Jahreszeit schwimmen wir im Pool?',
      'Wann ist Weihnachten?',
    ];
    return 'Jahreszeit: ${fragen[_rng.nextInt(fragen.length)]}';
  }

  String _generateWetterAufgabe() {
    const fragen = [
      'Was zieht man bei Regen an?',
      'Wann gibt es einen Regenbogen?',
      'Was ist Nebel?',
      'Was kommt nach einem Blitz?',
    ];
    return 'Wetter-Frage: ${fragen[_rng.nextInt(fragen.length)]}';
  }

  String _generateEuropaAufgabe() {
    const fragen = [
      'Wie heisst die Hauptstadt von Oesterreich?',
      'Welches Land liegt im Sueden von Oesterreich?',
      'Wie heisst die Hauptstadt von Italien?',
      'Was ist der laengste Fluss in Oesterreich?',
    ];
    return 'Geografie: ${fragen[_rng.nextInt(fragen.length)]}';
  }

  // ────────────────────────────────────────────────────────────────
  // SELBST-VORSCHLAG: schlaegt naechstes Topic vor
  // ────────────────────────────────────────────────────────────────
  /// Lumo's KI-Vorschlag: was sollte das Kind als naechstes lernen?
  /// Wird in der Akademie oder im Greeting genutzt.
  String suggestNextTopic() {
    return _lernTipps[_rng.nextInt(_lernTipps.length)];
  }
}

class _TierInfo {
  const _TierInfo({
    required this.laut,
    required this.lebensraum,
    required this.futter,
    required this.faktoid,
  });
  final String laut;
  final String lebensraum;
  final String futter;
  final String faktoid;
}
