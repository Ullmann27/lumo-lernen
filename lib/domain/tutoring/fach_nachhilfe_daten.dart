part of 'fach_nachhilfe.dart';

/// Bilder (Emoji) zu deutschen Bedeutungen der Englisch-Wörter. Nur für
/// Bildkarten der Antworten und für Lumos Beispiel an einer anderen Aufgabe.
const Map<String, String> _bilder = {
  // Tiere
  'Hund': '🐕', 'Katze': '🐈', 'Vogel': '🐦', 'Fisch': '🐟', 'Pferd': '🐎',
  'Kuh': '🐄', 'Schwein': '🐖', 'Schaf': '🐑', 'Maus': '🐭', 'Löwe': '🦁',
  'Elefant': '🐘', 'Giraffe': '🦒', 'Igel': '🦔', 'Schildkröte': '🐢',
  'Frosch': '🐸', 'Ente': '🦆', 'Biene': '🐝', 'Schmetterling': '🦋',
  'Spinne': '🕷️', 'Schlange': '🐍', 'Eule': '🦉', 'Fuchs': '🦊',
  'Kaninchen': '🐇', 'Ziege': '🐐', 'Huhn': '🐔', 'Küken': '🐥',
  'Bär': '🐻', 'Tiger': '🐅', 'Eichhörnchen': '🐿️',
  // Essen
  'Apfel': '🍎', 'Brot': '🍞', 'Milch': '🥛', 'Wasser': '💧', 'Käse': '🧀',
  'Reis': '🍚', 'Suppe': '🍲', 'Nudeln': '🍝', 'Tomate': '🍅',
  'Karotte': '🥕', 'Erdbeere': '🍓', 'Birne': '🍐', 'Ei': '🥚', 'Saft': '🧃',
  'Erdapfel': '🥔', 'Orange': '🍊', 'Frühstück': '🥣', 'Mittagessen': '🍽️',
  'Abendessen': '🌙🍽️',
  // Körper
  'Auge': '👁️', 'Ohr': '👂', 'Nase': '👃', 'Mund': '👄', 'Hand': '✋',
  'Fuß': '🦶', 'Füße': '🦶🦶', 'Bein': '🦵', 'Arm': '💪', 'Zahn': '🦷',
  'Zähne': '🦷🦷', 'Haare': '💇', 'Finger': '☝️', 'Daumen': '👍',
  'Gesicht': '🙂', 'Lippen': '👄', 'Kopf': '🙂',
  // Schulsachen
  'Buch': '📖', 'Stift': '✏️', 'Tasche': '👜', 'Lineal': '📏',
  'Schultisch': '🪑', 'Sessel': '🪑', 'Radiergummi': '🧽', 'Schere': '✂️',
  'Klebstoff': '🧴', 'Papier': '📄', 'Federpennal': '🖊️',
  'Schultasche': '🎒', 'Schulheft': '📓', 'Wörterbuch': '📚',
  'Taschenrechner': '🧮',
  // Spielzeug
  'Ball': '⚽', 'Puppe': '🪆', 'Auto': '🚗', 'Spielzeugauto': '🚗',
  'Drachen': '🪁', 'Drachen zum Steigenlassen': '🪁', 'Teddybär': '🧸',
  'Puzzle': '🧩', 'Bausteine': '🧱', 'Roboter': '🤖', 'Luftballon': '🎈',
  'Zug': '🚂', 'Roller': '🛴', 'Fahrrad': '🚲', 'Schaukel': '🌳',
  'Murmeln': '🔮', 'Brettspiel': '🎲', 'Springschnur': '🪢',
  // Wetter und Tageszeit
  'Sonne': '☀️', 'Regen': '🌧️', 'Schnee': '❄️', 'Wind': '🌬️',
  'Wolke': '☁️', 'Nacht': '🌙', 'Morgen': '🌅', 'Abend': '🌇',
  'nass': '💧', 'trocken': '🏜️', 'warm': '🌡️', 'kühl': '🧊',
  'bewölkt': '☁️', 'nebelig': '🌫️', 'stürmisch': '🌪️',
  // Familie
  'Mutter': '👩', 'Mama': '👩', 'Vater': '👨', 'Papa': '👨',
  'Schwester': '👧', 'Bruder': '👦', 'Baby': '👶', 'Großmutter': '👵',
  'Großvater': '👴', 'Eltern': '👩‍👨', 'Großeltern': '👵👴',
  // Hobbys und Tun
  'Fußball': '⚽', 'Musik': '🎵', 'Malen': '🎨', 'Tanzen': '💃',
  'Lesen': '📖', 'Schwimmen': '🏊', 'Singen': '🎤', 'Kochen': '🍳',
  'Zeichnen': '✏️', 'Radfahren': '🚴', 'Reiten': '🏇', 'Wandern': '🥾',
  'Schifahren': '⛷️', 'Eislaufen': '⛸️', 'Gärtnern': '🌱',
  'Fotografieren': '📷', 'Backen': '🧁', 'Gitarrespielen': '🎸',
  'Schachspielen': '♟️',
  'laufen': '🏃', 'springen': '🤸', 'essen': '🍽️', 'trinken': '🥤',
  'lesen': '📖', 'schreiben': '✍️', 'singen': '🎤', 'schwimmen': '🏊',
  'zeichnen': '✏️', 'kochen': '🍳', 'bauen': '🧱', 'zählen': '🔢',
};

/// Farben als Farbfläche (ARGB) – ein Bild ohne Wort.
const Map<String, int> _farben = {
  'rot': 0xFFE53935, 'blau': 0xFF1E88E5, 'grün': 0xFF43A047,
  'gelb': 0xFFFDD835, 'weiß': 0xFFFFFFFF, 'schwarz': 0xFF212121,
  'orange': 0xFFFB8C00, 'braun': 0xFF795548, 'grau': 0xFF9E9E9E,
  'rosa': 0xFFF48FB1, 'lila': 0xFF8E24AA, 'türkis': 0xFF26C6DA,
  'dunkelblau': 0xFF1A237E, 'hellgrün': 0xFF9CCC65, 'golden': 0xFFFFC107,
  'silbern': 0xFFBDBDBD,
};

/// Zahlwörter als Punktmenge (Bild ohne Wort).
const Map<String, int> _zahlwoerter = {
  'null': 0, 'eins': 1, 'zwei': 2, 'drei': 3, 'vier': 4, 'fünf': 5,
  'sechs': 6, 'sieben': 7, 'acht': 8, 'neun': 9, 'zehn': 10, 'elf': 11,
  'zwölf': 12, 'dreizehn': 13, 'vierzehn': 14, 'fünfzehn': 15,
  'sechzehn': 16, 'siebzehn': 17, 'achtzehn': 18, 'neunzehn': 19,
  'zwanzig': 20,
};

/// Rätsel zu einer Bedeutung: beschreibt, ohne das Wort zu nennen.
const Map<String, String> _raetsel = {
  'Hund': 'Dieses Tier bellt und wedelt mit dem Schwanz.',
  'Katze': 'Dieses Tier miaut und schnurrt.',
  'Vogel': 'Dieses Tier hat Federn und einen Schnabel.',
  'Fisch': 'Dieses Tier lebt im Wasser und hat Flossen.',
  'Pferd': 'Auf diesem großen Tier kann man reiten.',
  'Kuh': 'Dieses Tier gibt Milch und macht „Muh“.',
  'Schwein': 'Dieses Tier hat einen Ringelschwanz und grunzt.',
  'Schaf': 'Aus der Wolle dieses Tieres strickt man Pullover.',
  'Maus': 'Dieses kleine Tier piepst und hat einen langen Schwanz.',
  'Löwe': 'Dieses Tier hat eine Mähne und brüllt laut.',
  'Elefant': 'Dieses riesige Tier hat einen Rüssel.',
  'Giraffe': 'Dieses Tier hat einen sehr langen Hals.',
  'Igel': 'Dieses Tier hat Stacheln auf dem Rücken.',
  'Schildkröte': 'Dieses Tier trägt einen harten Panzer und ist langsam.',
  'Frosch': 'Dieses grüne Tier quakt und springt weit.',
  'Ente': 'Dieser Vogel schwimmt im Teich und quakt.',
  'Biene': 'Dieses Tier summt und macht Honig.',
  'Schmetterling': 'Dieses Tier hat bunte Flügel und war vorher eine Raupe.',
  'Spinne': 'Dieses Tier hat acht Beine und baut ein Netz.',
  'Schlange': 'Dieses Tier hat keine Beine und zischt.',
  'Eule': 'Dieser Vogel ist in der Nacht wach.',
  'Fuchs': 'Dieses Tier hat rotes Fell und einen buschigen Schwanz – wie Lumo!',
  'Kaninchen': 'Dieses Tier hat lange Ohren und hoppelt.',
  'Ziege': 'Dieses Tier hat Hörner und meckert „Mäh“.',
  'Esel': 'Dieses Tier hat lange Ohren und ruft „I-A“.',
  'Huhn': 'Dieses Tier legt Eier und gackert.',
  'Küken': 'Das ist ein kleines, gelbes Vogelkind vom Bauernhof.',
  'Bär': 'Dieses große Tier hat ein dickes Fell und schläft im Winter.',
  'Tiger': 'Diese große Raubkatze hat Streifen.',
  'Eichhörnchen': 'Dieses Tier klettert auf Bäume und sammelt Nüsse.',
  'Apfel': 'Dieses runde Obst wächst am Baum und ist rot oder grün.',
  'Brot': 'Das backt die Bäckerin. Daraus macht man eine Jause.',
  'Milch': 'Dieses weiße Getränk kommt von der Kuh.',
  'Wasser': 'Das trinkst du bei Durst. Es kommt aus der Leitung.',
  'Käse': 'Den macht man aus Milch. Manchmal hat er Löcher.',
  'Reis': 'Das sind viele kleine weiße Körner, die man kocht.',
  'Suppe': 'Die isst man warm mit dem Löffel aus dem Teller.',
  'Nudeln': 'Die isst man oft mit Tomatensoße.',
  'Tomate': 'Dieses rote Gemüse steckt im Ketchup.',
  'Karotte': 'Dieses orange Gemüse knabbern Hasen gern.',
  'Erdbeere': 'Diese rote Frucht hat kleine Kerne außen.',
  'Birne': 'Dieses Obst ist unten dick und oben schmal.',
  'Ei': 'Das legt ein Huhn.',
  'Saft': 'Dieses Getränk wird aus Obst gepresst.',
  'Erdapfel': 'Daraus macht man Pommes und Püree.',
  'Auge': 'Damit siehst du.',
  'Ohr': 'Damit hörst du.',
  'Nase': 'Damit riechst du.',
  'Mund': 'Damit sprichst und isst du.',
  'Hand': 'Damit greifst du. Sie hat fünf Finger.',
  'Fuß': 'Darauf stehst du, und er steckt im Schuh.',
  'Füße': 'Darauf stehst du, und sie stecken in Schuhen.',
  'Knie': 'Das ist das Gelenk in der Mitte vom Bein.',
  'Ellbogen': 'Das ist das Gelenk in der Mitte vom Arm.',
  'Haare': 'Die wachsen auf dem Kopf, und man kämmt sie.',
  'Zahn': 'Den putzt du morgens und abends mit der Bürste.',
  'Zähne': 'Die putzt du morgens und abends mit der Bürste.',
  'Kopf': 'Darauf setzt du eine Mütze.',
  'Bauch': 'Der knurrt, wenn du Hunger hast.',
  'Daumen': 'Das ist der dickste Finger an der Hand.',
  'Hals': 'Darum bindest du im Winter einen Schal.',
  'Buch': 'Darin liest du Geschichten.',
  'Stift': 'Damit schreibst oder malst du.',
  'Tasche': 'Darin trägst du deine Sachen.',
  'Lineal': 'Damit ziehst du gerade Striche.',
  'Schultisch': 'Daran sitzt du in der Klasse und schreibst.',
  'Sessel': 'Darauf sitzt du am Tisch.',
  'Radiergummi': 'Damit machst du Bleistiftstriche wieder weg.',
  'Schere': 'Damit schneidest du Papier.',
  'Papier': 'Darauf schreibst und malst du.',
  'Federpennal': 'Darin liegen deine Stifte.',
  'Schultasche': 'Die trägst du auf dem Rücken in die Schule.',
  'Ball': 'Den kannst du werfen, fangen und schießen.',
  'Puppe': 'Mit ihr spielt man, man kann sie anziehen.',
  'Teddybär': 'Ein weiches Kuscheltier zum Einschlafen.',
  'Puzzle': 'Viele kleine Teile ergeben zusammen ein Bild.',
  'Bausteine': 'Damit baust du Türme und Häuser.',
  'Luftballon': 'Den bläst du auf, und er schwebt.',
  'Drachen': 'Der steigt an einer Schnur hoch in den Himmel.',
  'Sonne': 'Sie scheint am Himmel und macht es hell und warm.',
  'Wind': 'Er bläst und bewegt die Blätter an den Bäumen.',
  'Wolke': 'Sie schwebt grau oder weiß am Himmel.',
  'Mutter': 'Diese Frau hat dich lieb und sorgt für dich.',
  'Vater': 'Dieser Mann hat dich lieb und sorgt für dich.',
  'Schwester': 'Dieses Mädchen hat dieselben Eltern wie du.',
  'Bruder': 'Dieser Bub hat dieselben Eltern wie du.',
  'Baby': 'Es ist ganz klein und trinkt aus der Flasche.',
  'Großmutter': 'Sie ist die Mutter von Mama oder Papa.',
  'Großvater': 'Er ist der Vater von Mama oder Papa.',
};

/// Ein Knoten im Schaubild des Sachunterrichts.
class FachKnoten {
  const FachKnoten(this.bild, this.titel, this.text);
  final String bild;
  final String titel;
  final String text;
}

/// Ein Schaubild-Modell: Knoten in Reihenfolge, als Kreislauf oder Kette.
class FachSchaubildVorlage {
  const FachSchaubildVorlage(this.titel, this.knoten, {this.kreis = false});
  final String titel;
  final List<FachKnoten> knoten;
  final bool kreis;
}

const _schaubilder = <String, FachSchaubildVorlage>{
  'wasser': FachSchaubildVorlage('Der Weg des Wassers', [
    FachKnoten('☀️', 'Sonne', 'wärmt Meer, Seen und Pfützen'),
    FachKnoten('💨', 'Aufsteigen', 'warmes Wasser verdunstet als Dampf'),
    FachKnoten('☁️', 'Wolken', 'der Dampf kühlt ab und wird zu Tröpfchen'),
    FachKnoten('🌧️', 'Niederschlag', 'Regen, Schnee oder Hagel fällt'),
    FachKnoten('🏞️', 'Quelle und Fluss', 'Wasser fließt zurück ins Meer'),
  ], kreis: true),
  'pflanze': FachSchaubildVorlage('So lebt eine Pflanze', [
    FachKnoten('🌰', 'Samen', 'keimt mit Wasser und Wärme'),
    FachKnoten('🟫', 'Wurzel', 'hält fest und holt Wasser aus dem Boden'),
    FachKnoten('🌿', 'Stängel', 'trägt Blätter und leitet Wasser'),
    FachKnoten('🍃', 'Blatt', 'macht mit Sonnenlicht Nahrung'),
    FachKnoten('🌸', 'Blüte', 'wird bestäubt, daraus wird die Frucht'),
    FachKnoten('🍎', 'Frucht', 'darin liegen neue Samen'),
  ], kreis: true),
  'jahr': FachSchaubildVorlage('Das Jahr im Kreis', [
    FachKnoten('🌷', 'Frühling', 'März, April, Mai – es wird wärmer'),
    FachKnoten('☀️', 'Sommer', 'Juni, Juli, August – heiß, Ferien'),
    FachKnoten('🍂', 'Herbst', 'September, Oktober, November – Blätter fallen'),
    FachKnoten('❄️', 'Winter', 'Dezember, Jänner, Februar – kalt'),
  ], kreis: true),
  'kalender': FachSchaubildVorlage('Zeit messen', [
    FachKnoten('⏱️', 'Minute', '60 Sekunden'),
    FachKnoten('🕐', 'Stunde', '60 Minuten'),
    FachKnoten('🌞', 'Tag', '24 Stunden: Tag und Nacht'),
    FachKnoten('📅', 'Woche', '7 Tage: Montag bis Sonntag'),
    FachKnoten('🗓️', 'Monat', 'etwa 4 Wochen'),
    FachKnoten('🎉', 'Jahr', '12 Monate, etwa 52 Wochen'),
  ]),
  'tagnacht': FachSchaubildVorlage('Tag und Nacht', [
    FachKnoten('🌅', 'Morgen', 'die Sonne geht auf, es wird hell'),
    FachKnoten('☀️', 'Mittag', 'die Sonne steht hoch'),
    FachKnoten('🌇', 'Abend', 'die Sonne geht unter'),
    FachKnoten('🌙', 'Nacht', 'dunkel – viele Menschen schlafen, manche Tiere sind wach'),
  ], kreis: true),
  'strom': FachSchaubildVorlage('Ein Stromkreis', [
    FachKnoten('🔋', 'Batterie', 'gibt die Energie'),
    FachKnoten('〰️', 'Kabel', 'Metall leitet den Strom'),
    FachKnoten('🔘', 'Schalter', 'öffnet oder schließt den Kreis'),
    FachKnoten('💡', 'Lampe', 'leuchtet nur, wenn der Kreis geschlossen ist'),
  ], kreis: true),
  'nahrung': FachSchaubildVorlage('Wer frisst wen?', [
    FachKnoten('🌞', 'Sonne', 'gibt Licht'),
    FachKnoten('🌿', 'Pflanzen', 'machen mit Licht Nahrung'),
    FachKnoten('🐇', 'Pflanzenfresser', 'fressen Pflanzen'),
    FachKnoten('🦊', 'Fleischfresser', 'fressen andere Tiere'),
  ]),
  'verkehr': FachSchaubildVorlage('Sicher unterwegs', [
    FachKnoten('🔴', 'Rot', 'stehen bleiben'),
    FachKnoten('🟡', 'Gelb', 'Achtung, die Ampel wechselt gleich'),
    FachKnoten('🟢', 'Grün', 'gehen – vorher trotzdem schauen'),
    FachKnoten('🚸', 'Gehsteig und Schutzweg', 'hier gehen Menschen zu Fuß'),
  ]),
  'koerper': FachSchaubildVorlage('Mein Körper', [
    FachKnoten('👁️', 'Sehen', 'mit den Augen'),
    FachKnoten('👂', 'Hören', 'mit den Ohren'),
    FachKnoten('👃', 'Riechen', 'mit der Nase'),
    FachKnoten('👅', 'Schmecken', 'mit der Zunge'),
    FachKnoten('✋', 'Fühlen', 'mit der Haut'),
    FachKnoten('🦴', 'Bewegen', 'Knochen, Gelenke und Muskeln'),
  ]),
  'essen': FachSchaubildVorlage('Gut essen und trinken', [
    FachKnoten('💧', 'Trinken', 'am meisten, am besten Wasser'),
    FachKnoten('🥦', 'Gemüse und Obst', 'viel, jeden Tag bunt'),
    FachKnoten('🍞', 'Brot, Nudeln, Reis', 'geben Kraft'),
    FachKnoten('🥛', 'Milch und Käse', 'für Knochen und Zähne'),
    FachKnoten('🍫', 'Süßes und Fett', 'nur wenig'),
  ]),
  'tiere': FachSchaubildVorlage('Tiere ordnen', [
    FachKnoten('🐄', 'Säugetiere', 'Fell, Junge trinken Milch'),
    FachKnoten('🐦', 'Vögel', 'Federn, Schnabel, legen Eier'),
    FachKnoten('🐟', 'Fische', 'Schuppen, atmen mit Kiemen'),
    FachKnoten('🐸', 'Lurche', 'Laich, Kaulquappe, Frosch'),
    FachKnoten('🐞', 'Insekten', 'sechs Beine'),
  ]),
};

/// Welches Schaubild passt zum Thema (Sachunterricht).
String? _schaubildFuer(String thema) {
  final t = thema.toLowerCase();
  if (t.contains('wasser') || t.contains('wetter')) return 'wasser';
  if (t.contains('pflanze')) return 'pflanze';
  if (t.contains('jahreszeit')) return 'jahr';
  if (t.contains('zeit und kalender') || t.contains('monate')) {
    return 'kalender';
  }
  if (t.contains('tag und nacht')) return 'tagnacht';
  if (t.contains('strom')) return 'strom';
  if (t.contains('ökosystem')) return 'nahrung';
  if (t.contains('verkehr')) return 'verkehr';
  if (t.contains('körper')) return 'koerper';
  if (t.contains('ernährung')) return 'essen';
  if (t == 'tiere') return 'tiere';
  return null;
}

/// Lebensnahe Beispiele zum Thema (Sachunterricht), ohne Lösung.
const _alltag = <String, List<String>>{
  'wasser': [
    'Denk an eine Pfütze nach dem Regen. Am nächsten sonnigen Tag ist sie '
        'kleiner geworden. Wohin könnte das Wasser gegangen sein?',
    'Denk an den Deckel auf einem Topf mit heißem Wasser: Innen hängen '
        'Tropfen. Woher kommen sie?',
  ],
  'pflanze': [
    'Denk an eine Blume auf dem Fensterbrett: Was braucht sie jeden Tag, '
        'damit sie nicht welkt?',
    'Denk an einen Apfel, den du aufschneidest: Was findest du in der Mitte?',
  ],
  'jahr': [
    'Denk an deinen Geburtstag: Ist es dann draußen warm oder kalt? '
        'Welche Kleidung trägst du dann?',
  ],
  'kalender': [
    'Denk an deine Schulwoche: Wie viele Tage gehst du in die Schule, und '
        'wie viele Tage ist Wochenende?',
  ],
  'tagnacht': [
    'Denk an dein Zimmer am Abend: Was siehst du draußen, wenn du ins Bett '
        'gehst, und was am Morgen?',
  ],
  'strom': [
    'Denk an eine Taschenlampe: Wann leuchtet sie, und was ist anders, wenn '
        'du sie ausschaltest?',
  ],
  'nahrung': [
    'Denk an einen Garten: Wer knabbert am Salat, und wer jagt vielleicht '
        'den, der am Salat knabbert?',
  ],
  'verkehr': [
    'Denk an deinen Schulweg: Wo gehst du, wo fahren die Autos, und wo '
        'darfst du über die Straße?',
  ],
  'koerper': [
    'Denk an das Mittagessen: Was merkst du mit der Nase, was mit dem Mund '
        'und was mit den Fingern?',
  ],
  'essen': [
    'Denk an deine Jause: Was davon gibt dir lange Kraft, und was ist nur '
        'eine kleine Nascherei?',
  ],
  'tiere': [
    'Denk an Tiere, die du kennst: Hat das Tier Fell, Federn oder Schuppen? '
        'Wie kommen seine Jungen zur Welt?',
  ],
};
