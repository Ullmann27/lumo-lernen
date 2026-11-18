class CurriculumActivity {
  const CurriculumActivity({
    required this.id,
    required this.subject,
    required this.grade,
    required this.title,
    required this.instruction,
    required this.competency,
    required this.evidence,
    this.requiresAdult = false,
  });

  final String id;
  final String subject;
  final int grade;
  final String title;
  final String instruction;
  final String competency;
  final String evidence;
  final bool requiresAdult;
}

/// Nicht-schriftliche Pflichtbereiche des österreichischen Volksschulrahmens.
/// Diese Aktivitäten sind bewusst keine Fake-Multiple-Choice-Tests.
class PrimaryActivityCatalog {
  const PrimaryActivityCatalog._();

  static List<CurriculumActivity> forGrade(int grade, {String? subject}) {
    final g = grade.clamp(1, 4);
    return all
        .where((a) => a.grade == g && (subject == null || a.subject == subject))
        .toList(growable: false);
  }

  static const all = <CurriculumActivity>[
    // Musik – Singen/Musizieren, Bewegen/Darstellen, Hören/Erfassen.
    CurriculumActivity(id:'g1_music_voice',subject:'Musik',grade:1,title:'Lumo-Klangdetektiv',instruction:'Hör dir drei Geräusche aus deinem Alltag an. Sag zu jedem: Ist es hoch oder tief? Laut oder leise? Kurz oder lang?',competency:'Genau hinhören',evidence:'Erzähl es einem Erwachsenen.'),
    CurriculumActivity(id:'g1_music_move',subject:'Musik',grade:1,title:'Rhythmus-Schritte',instruction:'Klatsch viermal im gleichen Takt. Dann geh den Takt mit vier Schritten mit.',competency:'Im Takt klatschen und gehen',evidence:'Zeig es einem Erwachsenen.'),
    CurriculumActivity(id:'g2_music_make',subject:'Musik',grade:2,title:'Eigenes Klangmuster',instruction:'Erfinde ein Klangmuster mit acht Schlägen: mit deiner Stimme, mit Klatschen oder mit einem Gegenstand. Wiederhole es.',competency:'Musik selbst machen',evidence:'Spiel es jemandem vor.'),
    CurriculumActivity(id:'g2_music_compare',subject:'Musik',grade:2,title:'Klangfarben vergleichen',instruction:'Hör dir zwei Instrumente oder zwei Geräusche an. Was ist anders? Nenne zwei Unterschiede.',competency:'Klänge vergleichen',evidence:'Sag oder schreib deine zwei Unterschiede.'),
    CurriculumActivity(id:'g3_music_form',subject:'Musik',grade:3,title:'Musik in Teilen',instruction:'Hör dir ein kurzes Lied an. Welcher Teil kommt wieder? Schreib die Teile als A und B auf, zum Beispiel A – B – A.',competency:'Teile in der Musik erkennen',evidence:'Deine Buchstabenfolge auf einem Zettel.'),
    CurriculumActivity(id:'g3_music_scene',subject:'Musik',grade:3,title:'Musik darstellen',instruction:'Erfinde Bewegungen zu einem kurzen Musikstück: einen Anfang, einen Teil, der sich wiederholt, und einen Schluss.',competency:'Musik in Bewegung zeigen',evidence:'Tanz es jemandem vor.'),
    CurriculumActivity(id:'g4_music_create',subject:'Musik',grade:4,title:'Mini-Komposition',instruction:'Plane ein Stück mit 16 Schlägen. Nimm mindestens zwei Klänge und wiederhole einen Teil. Dann spiel es vor.',competency:'Ein kleines Musikstück erfinden',evidence:'Dein Plan und dein Vorspiel.'),
    CurriculumActivity(id:'g4_music_reflect',subject:'Musik',grade:4,title:'Wirkung von Musik',instruction:'Hör dir ein Musikstück an. Wie fühlst du dich dabei? Woran liegt das: am Tempo, an der Lautstärke, an den Instrumenten?',competency:'Sagen, wie Musik wirkt',evidence:'Drei bis fünf Sätze, gesagt oder geschrieben.'),

    // Kunst und Gestaltung – Praxis, Wahrnehmen/Reflektieren, Kommunizieren.
    CurriculumActivity(id:'g1_art_feeling',subject:'Kunst und Gestaltung',grade:1,title:'Gefühl in Farben',instruction:'Mal ein Bild zu einem Gefühl, zum Beispiel Freude oder Wut. Nimm mindestens drei Farben. Erzähl, warum du sie gewählt hast.',competency:'Mit Farben malen',evidence:'Ein Foto von deinem Bild.'),
    CurriculumActivity(id:'g1_art_notice',subject:'Kunst und Gestaltung',grade:1,title:'Formen entdecken',instruction:'Such in deiner Umgebung einen Kreis, ein Rechteck und eine freie Form. Zeichne von jeder Form ein Beispiel.',competency:'Genau hinschauen',evidence:'Deine Zeichnung.'),
    CurriculumActivity(id:'g2_art_material',subject:'Kunst und Gestaltung',grade:2,title:'Material-Mix',instruction:'Bastle ein Bild oder ein Ding aus zwei verschiedenen Materialien, zum Beispiel Papier und Wolle. Wie fühlen sie sich an? Wie sehen sie aus?',competency:'Mit Material gestalten',evidence:'Ein Foto und die Namen der Materialien.'),
    CurriculumActivity(id:'g2_art_talk',subject:'Kunst und Gestaltung',grade:2,title:'Über Bilder sprechen',instruction:'Schau dir ein Bild an. Was siehst du zuerst? Ist das Bild fröhlich, traurig oder spannend? Warum?',competency:'Sagen, was ich sehe',evidence:'Erzähl es jemandem.'),
    CurriculumActivity(id:'g3_art_perspective',subject:'Kunst und Gestaltung',grade:3,title:'Nah und fern',instruction:'Zeichne eine Landschaft: Vorne ist etwas groß, in der Mitte mittel, hinten ganz klein.',competency:'Nah und fern zeichnen',evidence:'Ein Foto von deiner Zeichnung.'),
    CurriculumActivity(id:'g3_art_compare',subject:'Kunst und Gestaltung',grade:3,title:'Zwei Werke vergleichen',instruction:'Schau dir zwei Bilder an. Vergleiche: Welche Farben? Welche Formen? Was ist zu sehen? Wie wirkt das Bild?',competency:'Bilder vergleichen',evidence:'Eine kleine Tabelle mit deinen Antworten.'),
    CurriculumActivity(id:'g4_art_message',subject:'Kunst und Gestaltung',grade:4,title:'Bild mit Botschaft',instruction:'Gestalte ein Plakat mit einer klaren Botschaft, zum Beispiel „Licht aus, wenn du gehst!“. Erkläre drei Dinge, die du dir dabei überlegt hast.',competency:'Mit Bildern etwas sagen',evidence:'Dein Plakat und deine Erklärung.'),
    CurriculumActivity(id:'g4_art_redesign',subject:'Kunst und Gestaltung',grade:4,title:'Neu gestalten',instruction:'Such dir ein Ding aus dem Alltag aus, zum Beispiel eine Trinkflasche. Gestalte es neu, sodass es kleinen Kindern gefällt.',competency:'Etwas neu gestalten',evidence:'Deine Zeichnung und ein Satz dazu.'),

    // Technik und Design – Entwickeln, Herstellen, Reflektieren.
    CurriculumActivity(id:'g1_tech_fold',subject:'Technik und Design',grade:1,title:'Papier trägt',instruction:'Falte ein Blatt Papier so, dass es möglichst viele Radiergummis trägt. Probier zwei Arten aus.',competency:'Ausprobieren und bauen',evidence:'Ein Foto und wie viele Radiergummis es waren.'),
    CurriculumActivity(id:'g1_tech_join',subject:'Technik und Design',grade:1,title:'Verbinden und lösen',instruction:'Verbinde zwei Dinge auf zwei Arten, zum Beispiel mit Kleber und mit einem Knoten. Was hält besser?',competency:'Dinge verbinden',evidence:'Dein Werkstück und was besser hält.'),
    CurriculumActivity(id:'g2_tech_bridge',subject:'Technik und Design',grade:2,title:'Mini-Brücke',instruction:'Bau aus Papier oder Karton eine kleine Brücke, die ein Spielzeug trägt.',competency:'Etwas Stabiles bauen',evidence:'Ein Foto: Hält die Brücke?'),
    CurriculumActivity(id:'g2_tech_safe',subject:'Technik und Design',grade:2,title:'Werkzeug sicher nutzen',instruction:'Du willst etwas basteln. Welches Werkzeug brauchst du? Worauf musst du dabei aufpassen? Was machst du zuerst?',competency:'Sicher mit Werkzeug arbeiten',evidence:'Dein Bastelplan.'),
    CurriculumActivity(id:'g3_tech_mechanism',subject:'Technik und Design',grade:3,title:'Bewegung übertragen',instruction:'Bau oder untersuche einen Hebel, ein Rad oder eine Rolle. Was passiert, wenn du sie benutzt?',competency:'Wie Dinge sich bewegen',evidence:'Eine Zeichnung und ein Satz dazu.'),
    CurriculumActivity(id:'g3_tech_plan',subject:'Technik und Design',grade:3,title:'Erst planen, dann bauen',instruction:'Zeichne zuerst einen Plan mit Maßen und einer Liste der Materialien. Dann bau dein Ding.',competency:'Planvoll bauen',evidence:'Dein Plan und ein Foto.'),
    CurriculumActivity(id:'g4_tech_design',subject:'Technik und Design',grade:4,title:'Produkt verbessern',instruction:'Schau dir ein Ding aus dem Alltag genau an. Wie könnte es sicherer sein oder länger halten? Zeichne deine Idee.',competency:'Dinge besser machen',evidence:'Eine Zeichnung: vorher und nachher.'),
    CurriculumActivity(id:'g4_tech_review',subject:'Technik und Design',grade:4,title:'Qualitätscheck',instruction:'Prüfe dein gebasteltes Werkstück: Lege vorher drei Punkte fest, zum Beispiel „hält“, „sieht ordentlich aus“, „ist sicher“. Verbessere dann eine Sache.',competency:'Die eigene Arbeit prüfen',evidence:'Deine drei Punkte und was du verbessert hast.'),

    // Bewegung und Sport – sechs Erfahrungsbereiche.
    CurriculumActivity(id:'g1_sport_motor',subject:'Bewegung und Sport',grade:1,title:'Balance-Parcours',instruction:'Geh, hüpf und balanciere über einen kleinen, sicheren Hindernisweg.',competency:'Gleichgewicht halten',evidence:'Ein Erwachsener schaut zu.',requiresAdult:true),
    CurriculumActivity(id:'g1_sport_game',subject:'Bewegung und Sport',grade:1,title:'Fair spielen',instruction:'Spiel ein Fang- oder Ballspiel. Sag danach eine Regel, damit es für alle fair ist.',competency:'Mit anderen nach Regeln spielen',evidence:'Ein Erwachsener schaut zu.',requiresAdult:true),
    CurriculumActivity(id:'g2_sport_forms',subject:'Bewegung und Sport',grade:2,title:'Laufen, Springen, Werfen',instruction:'Lauf, spring und wirf – jeweils dreimal. Wann warst du am besten?',competency:'Laufen, springen, werfen',evidence:'Ein Erwachsener schreibt mit.',requiresAdult:true),
    CurriculumActivity(id:'g2_sport_health',subject:'Bewegung und Sport',grade:2,title:'Puls spüren',instruction:'Fühl deinen Puls am Handgelenk. Dann hüpf eine Minute lang und fühl noch einmal. Was ist anders?',competency:'Den eigenen Körper spüren',evidence:'Erzähl, was du gespürt hast.',requiresAdult:true),
    CurriculumActivity(id:'g3_sport_create',subject:'Bewegung und Sport',grade:3,title:'Bewegungsfolge',instruction:'Erfinde eine kurze Bewegungsfolge mit mindestens vier Teilen, zum Beispiel Hüpfer, Drehung, Strecken, Rolle.',competency:'Bewegungen erfinden',evidence:'Zeig sie jemandem.',requiresAdult:true),
    CurriculumActivity(id:'g3_sport_team',subject:'Bewegung und Sport',grade:3,title:'Team-Aufgabe',instruction:'Löst in einer Gruppe eine Bewegungsaufgabe, bei der alle mitmachen müssen.',competency:'Gemeinsam eine Aufgabe lösen',evidence:'Ein Erwachsener schaut zu.',requiresAdult:true),
    CurriculumActivity(id:'g4_sport_plan',subject:'Bewegung und Sport',grade:4,title:'Eigenes Warm-up',instruction:'Plane ein kurzes Aufwärmen mit drei Übungen und mach es mit anderen vor.',competency:'Ein Aufwärmen planen',evidence:'Dein Plan und das Vormachen.',requiresAdult:true),
    CurriculumActivity(id:'g4_sport_risk',subject:'Bewegung und Sport',grade:4,title:'Risiko einschätzen',instruction:'Denk an drei Bewegungen, zum Beispiel auf einen Baum klettern. Was kannst du schon allein? Wo brauchst du Hilfe?',competency:'Einschätzen, was ich mir zutraue',evidence:'Erzähl es einem Erwachsenen.',requiresAdult:true),

    // Verkehrs- und Mobilitätsbildung – Handlung, Risiko, Reflexion.
    CurriculumActivity(id:'g1_mobility_way',subject:'Verkehrs- und Mobilitätsbildung',grade:1,title:'Mein sicherer Schulweg',instruction:'Zeichne mit einem Erwachsenen deinen Schulweg auf. Markiere die Stellen, an denen du sicher über die Straße gehst.',competency:'Sicher zur Schule gehen',evidence:'Dein Plan.',requiresAdult:true),
    CurriculumActivity(id:'g1_mobility_signs',subject:'Verkehrs- und Mobilitätsbildung',grade:1,title:'Sehen und gesehen werden',instruction:'Such drei Dinge, mit denen dich Autofahrer gut sehen, zum Beispiel Reflektoren an der Jacke.',competency:'Gut gesehen werden',evidence:'Zeig oder fotografiere die drei Dinge.',requiresAdult:true),
    CurriculumActivity(id:'g2_mobility_cross',subject:'Verkehrs- und Mobilitätsbildung',grade:2,title:'Sicher queren',instruction:'Zeig mit einem Erwachsenen an einer sicheren Stelle, wie du über die Straße gehst: stehen bleiben, schauen, gehen.',competency:'Sicher über die Straße gehen',evidence:'Ein Erwachsener schaut zu.',requiresAdult:true),
    CurriculumActivity(id:'g2_mobility_view',subject:'Verkehrs- und Mobilitätsbildung',grade:2,title:'Perspektivenwechsel',instruction:'Stell dir eine Kreuzung vor. Was sieht ein Kind? Was sieht jemand auf dem Rad? Was sieht jemand im Auto?',competency:'Sich in andere hineindenken',evidence:'Drei Sätze, einer für jeden.'),
    CurriculumActivity(id:'g3_mobility_plan',subject:'Verkehrs- und Mobilitätsbildung',grade:3,title:'Route vergleichen',instruction:'Vergleiche zwei Wege, zum Beispiel zur Schule: Welcher ist sicherer? Welcher ist kürzer? Bei welchem fährt kein Auto?',competency:'Wege vergleichen',evidence:'Eine kleine Tabelle.'),
    CurriculumActivity(id:'g3_mobility_rules',subject:'Verkehrs- und Mobilitätsbildung',grade:3,title:'Regeln begründen',instruction:'Such dir drei Verkehrsregeln aus. Erkläre bei jeder, wovor sie dich schützt.',competency:'Verkehrsregeln verstehen',evidence:'Drei Erklärungen.'),
    CurriculumActivity(id:'g4_mobility_choice',subject:'Verkehrs- und Mobilitätsbildung',grade:4,title:'Mobilitätsentscheidung',instruction:'Schau dir deinen Weg zur Schule an. Womit kommst du am sichersten hin: zu Fuß, mit dem Bus oder mit dem Auto? Erzähle, warum.',competency:'Den besten Weg wählen',evidence:'Dein Weg und deine Gründe.'),
    CurriculumActivity(id:'g4_mobility_hazard',subject:'Verkehrs- und Mobilitätsbildung',grade:4,title:'Gefahren vorausdenken',instruction:'Denk an drei Stellen auf deinem Weg, an denen es gefährlich werden kann. Was tust du dort, damit dir nichts passiert?',competency:'Gefahren früh erkennen',evidence:'Drei Stellen und was du dort tust.'),

    // Deutsch – mündliche Sprachhandlung und Zuhören ergänzen die digitalen
    // Lese-/Schreib-/Rechtschreibaufgaben.
    CurriculumActivity(id:'g1_de_listen',subject:'Deutsch',grade:1,title:'Erzähl mir drei Dinge',instruction:'Hör einer kurzen Geschichte zu. Erzähl danach drei Dinge, die passiert sind – in der richtigen Reihenfolge.',competency:'Zuhören und erzählen',evidence:'Erzähl es einem Erwachsenen.'),
    CurriculumActivity(id:'g2_de_retell',subject:'Deutsch',grade:2,title:'Geschichte nacherzählen',instruction:'Erzähl eine kurze Geschichte mit deinen eigenen Worten nach: Wie fängt sie an? Was passiert dann? Wie endet sie?',competency:'Nacherzählen',evidence:'Erzähl sie jemandem.'),
    CurriculumActivity(id:'g3_de_explain',subject:'Deutsch',grade:3,title:'Etwas verständlich erklären',instruction:'Erkläre einem anderen Kind etwas, das du gut kannst, zum Beispiel Zähneputzen. Es soll es ohne Nachfragen nachmachen können.',competency:'Etwas gut erklären',evidence:'Ein Erwachsener hört zu.'),
    CurriculumActivity(id:'g4_de_discuss',subject:'Deutsch',grade:4,title:'Standpunkt begründen',instruction:'Sag deine Meinung zu einer Frage, zum Beispiel „Sollen Kinder Hausübungen bekommen?“. Nenne zwei Gründe und sag, was jemand anderer dazu denken könnte.',competency:'Die eigene Meinung begründen',evidence:'Sag es einem Erwachsenen.'),

    // Englisch/Lebende Fremdsprache – Schwerpunkt Hören/Sprechen.
    CurriculumActivity(id:'g1_en_listen',subject:'Englisch',grade:1,title:'Listen and point',instruction:'Hör fünf englische Wörter, die du kennst. Zeig jedes Mal auf das passende Bild oder Ding.',competency:'Englisch hören',evidence:'Fünfmal richtig gezeigt.'),
    CurriculumActivity(id:'g1_en_speak',subject:'Englisch',grade:1,title:'Hello, I am …',instruction:'Begrüß Lumo auf Englisch und sag deinen Namen: „Hello, I am …“',competency:'Englisch sprechen',evidence:'Sag es laut.'),
    CurriculumActivity(id:'g2_en_commands',subject:'Englisch',grade:2,title:'Listen and do',instruction:'Mach vier englische Aufträge nach, zum Beispiel stand up, point to red, clap twice.',competency:'Englisch verstehen',evidence:'Vier Aufträge gemacht.'),
    CurriculumActivity(id:'g2_en_dialogue',subject:'Englisch',grade:2,title:'Mini dialogue',instruction:'Sprich ein kurzes Gespräch auf Englisch: begrüßen, fragen „How are you?“ und verabschieden.',competency:'Englisch sprechen',evidence:'Spiel es mit jemandem.'),
    CurriculumActivity(id:'g3_en_info',subject:'Englisch',grade:3,title:'Find the information',instruction:'Hör oder lies einen kurzen englischen Text. Finde drei Dinge heraus, zum Beispiel einen Namen, eine Farbe und eine Zahl.',competency:'Englisch hören und lesen',evidence:'Drei Antworten.'),
    CurriculumActivity(id:'g3_en_talk',subject:'Englisch',grade:3,title:'My favourite …',instruction:'Erzähl in drei oder vier kurzen englischen Sätzen von deinem Lieblingstier, Hobby oder Essen: „My favourite … is …“',competency:'Englisch sprechen',evidence:'Sag es laut.'),
    CurriculumActivity(id:'g4_en_message',subject:'Englisch',grade:4,title:'Short message',instruction:'Schreib eine kurze Nachricht auf Englisch: eine Begrüßung, zwei Dinge über dich und einen Gruß am Schluss.',competency:'Englisch schreiben',evidence:'Deine Nachricht.'),
    CurriculumActivity(id:'g4_en_roleplay',subject:'Englisch',grade:4,title:'Everyday role play',instruction:'Spiel eine Alltagsszene auf Englisch, zum Beispiel einkaufen oder nach dem Weg fragen.',competency:'Englisch im Gespräch',evidence:'Spiel es mit jemandem.'),

    // Sachunterricht – forschend, sozial und wirtschaftlich handeln statt
    // alles nur abzufragen.
    CurriculumActivity(id:'g1_su_observe',subject:'Sachunterricht',grade:1,title:'Natur beobachten',instruction:'Schau dir draußen eine Pflanze oder ein Tier genau an. Zeichne oder schreib drei Dinge auf, die dir auffallen.',competency:'Genau beobachten',evidence:'Deine Zeichnung.'),
    CurriculumActivity(id:'g1_su_map',subject:'Sachunterricht',grade:1,title:'Mein Nahraum',instruction:'Zeichne einen Weg, den du gut kennst, zum Beispiel zum Spielplatz. Markiere drei Dinge, an denen du dich orientierst.',competency:'Sich zurechtfinden',evidence:'Dein Wegplan.'),
    CurriculumActivity(id:'g2_su_firstaid',subject:'Sachunterricht',grade:2,title:'Wer hilft im Notfall?',instruction:'Wer hilft bei einem Brand, wer bei einem Unfall? Ordne zu: Feuerwehr 122, Polizei 133, Rettung 144. Was sagst du am Telefon?',competency:'Im Notfall Hilfe holen',evidence:'Deine Zuordnung und was du sagst.'),
    CurriculumActivity(id:'g2_su_habitat',subject:'Sachunterricht',grade:2,title:'Lebensraum vergleichen',instruction:'Vergleiche zwei Orte in der Natur, zum Beispiel Wald und Wiese: Welche Pflanzen und Tiere leben dort?',competency:'Lebensräume vergleichen',evidence:'Eine kleine Tabelle.'),
    CurriculumActivity(id:'g3_su_trade',subject:'Sachunterricht',grade:3,title:'Vom Produkt zum Geschäft',instruction:'Wie kommt ein Ding zu dir, zum Beispiel ein Apfel oder ein Heft? Zeichne den Weg: Woher kommt es, wer macht es, wo wird es verkauft?',competency:'Woher Dinge kommen',evidence:'Dein gezeichneter Weg.'),
    CurriculumActivity(id:'g3_su_force',subject:'Sachunterricht',grade:3,title:'Kraft erforschen',instruction:'Probier mit einem Erwachsenen aus: Was zieht ein Magnet an? Was rutscht leicht, was schwer? Schreib auf, was du siehst.',competency:'Forschen und beobachten',evidence:'Deine Notizen.',requiresAdult:true),
    CurriculumActivity(id:'g4_su_energy',subject:'Sachunterricht',grade:4,title:'Energie im Alltag',instruction:'Finde vier Dinge zu Hause, die Strom oder Wärme brauchen, zum Beispiel den Toaster. Was machen sie daraus?',competency:'Verstehen, wofür wir Energie brauchen',evidence:'Vier Beispiele mit je einem Satz.'),
    CurriculumActivity(id:'g4_su_democracy',subject:'Sachunterricht',grade:4,title:'Gemeinsam entscheiden',instruction:'Entscheidet in einer Gruppe etwas gemeinsam, zum Beispiel ein Spiel für die Pause: Vorschläge sammeln, abstimmen, Ergebnis sagen.',competency:'Abstimmen und mitbestimmen',evidence:'Das Ergebnis eurer Abstimmung.'),
  ];
}
