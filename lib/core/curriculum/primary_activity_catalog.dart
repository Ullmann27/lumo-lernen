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
    CurriculumActivity(id:'g1_music_voice',subject:'Musik',grade:1,title:'Lumo-Klangdetektiv',instruction:'Höre drei Alltagsklänge und beschreibe laut: hoch/tief, laut/leise, kurz/lang.',competency:'Hören und Erfassen',evidence:'Lehrkraft kann kurze Audio-/Textnotiz abhaken.'),
    CurriculumActivity(id:'g1_music_move',subject:'Musik',grade:1,title:'Rhythmus-Schritte',instruction:'Klatsche einen einfachen 4er-Rhythmus und gehe ihn danach mit vier Schritten mit.',competency:'Tanzen, Bewegen und Darstellen',evidence:'Selbstcheck + Lehrkraftbeobachtung.'),
    CurriculumActivity(id:'g2_music_make',subject:'Musik',grade:2,title:'Eigenes Klangmuster',instruction:'Erfinde mit Stimme, Klatschen oder einem Gegenstand ein 8-Schläge-Muster und wiederhole es.',competency:'Singen und Musizieren',evidence:'Audioaufnahme optional; Lehrkraft bestätigt.'),
    CurriculumActivity(id:'g2_music_compare',subject:'Musik',grade:2,title:'Klangfarben vergleichen',instruction:'Vergleiche zwei Instrumente oder Alltagsklänge und nenne mindestens zwei Unterschiede.',competency:'Hören und Erfassen',evidence:'Kurze Antwort oder Audio.'),
    CurriculumActivity(id:'g3_music_form',subject:'Musik',grade:3,title:'Musik in Teilen',instruction:'Höre ein kurzes Musikstück und markiere wiederkehrende Teile als A/B/A oder ähnlich.',competency:'Hören und Erfassen',evidence:'Muster im Aktivitätsblatt.'),
    CurriculumActivity(id:'g3_music_scene',subject:'Musik',grade:3,title:'Musik darstellen',instruction:'Erfinde zu einem kurzen Musikstück eine Bewegungsfolge mit Anfang, Wiederholung und Schluss.',competency:'Tanzen, Bewegen und Darstellen',evidence:'Lehrkraftbeobachtung.'),
    CurriculumActivity(id:'g4_music_create',subject:'Musik',grade:4,title:'Mini-Komposition',instruction:'Plane 16 Schläge mit mindestens zwei Klangquellen und einer Wiederholung. Führe sie auf.',competency:'Singen und Musizieren',evidence:'Plan + Aufführung.'),
    CurriculumActivity(id:'g4_music_reflect',subject:'Musik',grade:4,title:'Wirkung von Musik',instruction:'Beschreibe, wie ein ausgewähltes Musikstück wirkt und wodurch dieser Eindruck entsteht.',competency:'Hören und Erfassen',evidence:'3-5 Sätze oder Audio.'),

    // Kunst und Gestaltung – Praxis, Wahrnehmen/Reflektieren, Kommunizieren.
    CurriculumActivity(id:'g1_art_feeling',subject:'Kunst und Gestaltung',grade:1,title:'Gefühl in Farben',instruction:'Gestalte ein Bild zu einem Gefühl mit mindestens drei Farben und erkläre deine Wahl.',competency:'Bildnerische Praxis',evidence:'Foto des Werks + kurze Erklärung.'),
    CurriculumActivity(id:'g1_art_notice',subject:'Kunst und Gestaltung',grade:1,title:'Formen entdecken',instruction:'Finde in deiner Umgebung Kreis, Rechteck und freie Form und zeichne je ein Beispiel.',competency:'Wahrnehmen und Reflektieren',evidence:'Zeichnung/Fotodokumentation.'),
    CurriculumActivity(id:'g2_art_material',subject:'Kunst und Gestaltung',grade:2,title:'Material-Mix',instruction:'Gestalte ein Bild oder Objekt aus zwei unterschiedlichen Materialien und beschreibe deren Wirkung.',competency:'Bildnerische Praxis',evidence:'Foto + Materialliste.'),
    CurriculumActivity(id:'g2_art_talk',subject:'Kunst und Gestaltung',grade:2,title:'Über Bilder sprechen',instruction:'Wähle ein Bild und nenne, was dir zuerst auffällt, welche Stimmung es hat und warum.',competency:'Kommunizieren',evidence:'Audio/Text.'),
    CurriculumActivity(id:'g3_art_perspective',subject:'Kunst und Gestaltung',grade:3,title:'Nah und fern',instruction:'Zeichne dieselbe Szene mit Vordergrund, Mitte und Hintergrund.',competency:'Bildnerische Praxis',evidence:'Werkfoto.'),
    CurriculumActivity(id:'g3_art_compare',subject:'Kunst und Gestaltung',grade:3,title:'Zwei Werke vergleichen',instruction:'Vergleiche zwei Bilder nach Farbe, Form, Motiv und Wirkung.',competency:'Wahrnehmen und Reflektieren',evidence:'Vergleichstabelle.'),
    CurriculumActivity(id:'g4_art_message',subject:'Kunst und Gestaltung',grade:4,title:'Bild mit Botschaft',instruction:'Gestalte ein Plakat, das eine klare Botschaft vermittelt. Begründe drei Gestaltungsentscheidungen.',competency:'Kommunizieren',evidence:'Plakat + Begründung.'),
    CurriculumActivity(id:'g4_art_redesign',subject:'Kunst und Gestaltung',grade:4,title:'Neu gestalten',instruction:'Wähle ein Alltagsobjekt oder Symbol und entwirf eine neue visuelle Variante für eine andere Zielgruppe.',competency:'Bildnerische Praxis',evidence:'Entwurf + Reflexion.'),

    // Technik und Design – Entwickeln, Herstellen, Reflektieren.
    CurriculumActivity(id:'g1_tech_fold',subject:'Technik und Design',grade:1,title:'Papier trägt',instruction:'Falte Papier so, dass es möglichst viele Radiergummis trägt. Probiere zwei Varianten.',competency:'Entwickeln',evidence:'Foto + Anzahl.'),
    CurriculumActivity(id:'g1_tech_join',subject:'Technik und Design',grade:1,title:'Verbinden und lösen',instruction:'Verbinde zwei Materialien auf zwei Arten, z. B. kleben und knoten, und vergleiche.',competency:'Herstellen',evidence:'Werkstück + Vergleich.'),
    CurriculumActivity(id:'g2_tech_bridge',subject:'Technik und Design',grade:2,title:'Mini-Brücke',instruction:'Baue eine kleine Brücke aus Papier/Karton, die ein Spielzeug trägt.',competency:'Herstellen',evidence:'Foto + Belastungstest.'),
    CurriculumActivity(id:'g2_tech_safe',subject:'Technik und Design',grade:2,title:'Werkzeug sicher nutzen',instruction:'Ordne für eine geplante Bastelarbeit Werkzeug, Schutzregel und Arbeitsschritt richtig zu.',competency:'Reflektieren',evidence:'Arbeitsplan.'),
    CurriculumActivity(id:'g3_tech_mechanism',subject:'Technik und Design',grade:3,title:'Bewegung übertragen',instruction:'Baue oder untersuche einen einfachen Hebel, ein Rad oder eine Rolle und erkläre die Wirkung.',competency:'Entwickeln',evidence:'Skizze + Erklärung.'),
    CurriculumActivity(id:'g3_tech_plan',subject:'Technik und Design',grade:3,title:'Erst planen, dann bauen',instruction:'Skizziere ein kleines Produkt mit Maßen und Materialliste und stelle es danach her.',competency:'Herstellen',evidence:'Plan + Produktfoto.'),
    CurriculumActivity(id:'g4_tech_design',subject:'Technik und Design',grade:4,title:'Produkt verbessern',instruction:'Untersuche ein Alltagsprodukt und entwirf eine sicherere oder nachhaltigere Variante.',competency:'Entwickeln',evidence:'Vorher/Nachher-Skizze.'),
    CurriculumActivity(id:'g4_tech_review',subject:'Technik und Design',grade:4,title:'Qualitätscheck',instruction:'Prüfe ein selbst hergestelltes Werkstück an drei vorher festgelegten Kriterien und verbessere es.',competency:'Reflektieren',evidence:'Checkliste + Verbesserung.'),

    // Bewegung und Sport – sechs Erfahrungsbereiche.
    CurriculumActivity(id:'g1_sport_motor',subject:'Bewegung und Sport',grade:1,title:'Balance-Parcours',instruction:'Gehe, hüpfe und balanciere über einen sicheren Mini-Parcours.',competency:'Motorische Grundlagen',evidence:'Lehrkraftbeobachtung.',requiresAdult:true),
    CurriculumActivity(id:'g1_sport_game',subject:'Bewegung und Sport',grade:1,title:'Fair spielen',instruction:'Spiele ein einfaches Fang- oder Ballspiel und nenne danach eine Fairness-Regel.',competency:'Spielen',evidence:'Lehrkraftbeobachtung.',requiresAdult:true),
    CurriculumActivity(id:'g2_sport_forms',subject:'Bewegung und Sport',grade:2,title:'Laufen, Springen, Werfen',instruction:'Absolviere je eine sichere Lauf-, Sprung- und Wurfaufgabe und vergleiche deine Versuche.',competency:'Elementare Bewegungsformen',evidence:'Lehrkraftprotokoll.',requiresAdult:true),
    CurriculumActivity(id:'g2_sport_health',subject:'Bewegung und Sport',grade:2,title:'Puls spüren',instruction:'Spüre deinen Puls vor und nach kurzer Bewegung und beschreibe den Unterschied.',competency:'Gesund leben',evidence:'Beobachtung ohne medizinische Bewertung.',requiresAdult:true),
    CurriculumActivity(id:'g3_sport_create',subject:'Bewegung und Sport',grade:3,title:'Bewegungsfolge',instruction:'Erfinde eine kurze sichere Bewegungsfolge mit mindestens vier Elementen.',competency:'Wahrnehmen und Gestalten',evidence:'Vorführung.',requiresAdult:true),
    CurriculumActivity(id:'g3_sport_team',subject:'Bewegung und Sport',grade:3,title:'Team-Aufgabe',instruction:'Löse in einer Gruppe eine Bewegungsaufgabe, bei der alle beteiligt sein müssen.',competency:'Spielen / Sozialkompetenz',evidence:'Lehrkraftbeobachtung.',requiresAdult:true),
    CurriculumActivity(id:'g4_sport_plan',subject:'Bewegung und Sport',grade:4,title:'Eigenes Warm-up',instruction:'Plane und leite ein kurzes, altersgerechtes Warm-up mit drei Übungen.',competency:'Methodenkompetenz',evidence:'Plan + Durchführung.',requiresAdult:true),
    CurriculumActivity(id:'g4_sport_risk',subject:'Bewegung und Sport',grade:4,title:'Risiko einschätzen',instruction:'Bewerte drei sichere Beispielsituationen: Was kann ich selbst, wo brauche ich Hilfe?',competency:'Erleben und Wagen / Selbstkompetenz',evidence:'Reflexionsbogen.',requiresAdult:true),

    // Verkehrs- und Mobilitätsbildung – Handlung, Risiko, Reflexion.
    CurriculumActivity(id:'g1_mobility_way',subject:'Verkehrs- und Mobilitätsbildung',grade:1,title:'Mein sicherer Schulweg',instruction:'Markiere mit einer erwachsenen Person sichere Querungsstellen auf einem einfachen Plan.',competency:'Verkehrsbezogene Handlungskompetenz',evidence:'Plan + Besprechung.',requiresAdult:true),
    CurriculumActivity(id:'g1_mobility_signs',subject:'Verkehrs- und Mobilitätsbildung',grade:1,title:'Sehen und gesehen werden',instruction:'Finde drei Dinge, die Fußgängerinnen und Fußgänger im Straßenverkehr sichtbar machen.',competency:'Gefahrenabschätzung',evidence:'Foto-/Symbolauswahl.',requiresAdult:true),
    CurriculumActivity(id:'g2_mobility_cross',subject:'Verkehrs- und Mobilitätsbildung',grade:2,title:'Sicher queren',instruction:'Erkläre an einem sicheren Übungsort die Schritte zum Überqueren einer Straße.',competency:'Verkehrsbezogene Handlungskompetenz',evidence:'Lehrkraftbeobachtung.',requiresAdult:true),
    CurriculumActivity(id:'g2_mobility_view',subject:'Verkehrs- und Mobilitätsbildung',grade:2,title:'Perspektivenwechsel',instruction:'Beschreibe dieselbe Verkehrssituation aus Sicht eines Kindes, Radfahrers und Autofahrers.',competency:'Gefahrenabschätzung',evidence:'3 Perspektiven.'),
    CurriculumActivity(id:'g3_mobility_plan',subject:'Verkehrs- und Mobilitätsbildung',grade:3,title:'Route vergleichen',instruction:'Vergleiche zwei Wege nach Sicherheit, Zeit und Umweltwirkung.',competency:'Mobilitätsbezogene Reflexionskompetenz',evidence:'Vergleichstabelle.'),
    CurriculumActivity(id:'g3_mobility_rules',subject:'Verkehrs- und Mobilitätsbildung',grade:3,title:'Regeln begründen',instruction:'Wähle drei Verkehrsregeln und erkläre, welches Risiko sie verringern.',competency:'Verkehrsbezogene Handlungskompetenz',evidence:'Begründungen.'),
    CurriculumActivity(id:'g4_mobility_choice',subject:'Verkehrs- und Mobilitätsbildung',grade:4,title:'Mobilitätsentscheidung',instruction:'Plane einen Alltagsweg und begründe dein Verkehrsmittel nach Sicherheit, Kosten und Umwelt.',competency:'Mobilitätsbezogene Reflexionskompetenz',evidence:'Entscheidungsmatrix.'),
    CurriculumActivity(id:'g4_mobility_hazard',subject:'Verkehrs- und Mobilitätsbildung',grade:4,title:'Gefahren vorausdenken',instruction:'Analysiere drei dargestellte Verkehrssituationen und beschreibe jeweils sichere Alternativen.',competency:'Gefahrenabschätzung',evidence:'Risiko + sichere Handlung.'),

    // Deutsch – mündliche Sprachhandlung und Zuhören ergänzen die digitalen
    // Lese-/Schreib-/Rechtschreibaufgaben.
    CurriculumActivity(id:'g1_de_listen',subject:'Deutsch',grade:1,title:'Erzähl mir drei Dinge',instruction:'Höre einer kurzen Erzählung zu und nenne danach drei Dinge in der richtigen Reihenfolge.',competency:'(Zu-)Hören und Sprechen',evidence:'Audio oder Lehrkraftbeobachtung.'),
    CurriculumActivity(id:'g2_de_retell',subject:'Deutsch',grade:2,title:'Geschichte nacherzählen',instruction:'Erzähle einen kurzen Text mit Anfang, Mitte und Ende in eigenen Worten nach.',competency:'(Zu-)Hören und Sprechen',evidence:'Audio/Beobachtung.'),
    CurriculumActivity(id:'g3_de_explain',subject:'Deutsch',grade:3,title:'Etwas verständlich erklären',instruction:'Erkläre einem anderen Kind einen bekannten Ablauf so, dass es ihn ohne Nachfragen ausführen könnte.',competency:'Sprechen und Sprachhandeln',evidence:'Lehrkraftbeobachtung.'),
    CurriculumActivity(id:'g4_de_discuss',subject:'Deutsch',grade:4,title:'Standpunkt begründen',instruction:'Nimm zu einer altersgerechten Frage Stellung, nenne zwei Gründe und gehe auf ein Gegenargument ein.',competency:'Sprechen und Sprachhandeln',evidence:'Audio/Lehrkraftbeobachtung.'),

    // Englisch/Lebende Fremdsprache – Schwerpunkt Hören/Sprechen.
    CurriculumActivity(id:'g1_en_listen',subject:'Englisch',grade:1,title:'Listen and point',instruction:'Höre fünf bekannte englische Wörter und zeige jeweils auf das passende Bild oder Objekt.',competency:'Hören',evidence:'5 Zuordnungen.'),
    CurriculumActivity(id:'g1_en_speak',subject:'Englisch',grade:1,title:'Hello, I am …',instruction:'Begrüße Lumo auf Englisch und sage deinen Namen mit einem einfachen Satz.',competency:'Sprechen',evidence:'Kurze Audioantwort.'),
    CurriculumActivity(id:'g2_en_commands',subject:'Englisch',grade:2,title:'Listen and do',instruction:'Führe vier einfache englische Anweisungen aus, zum Beispiel stand up, point to red, clap twice.',competency:'Hören',evidence:'4 ausgeführte Handlungen.'),
    CurriculumActivity(id:'g2_en_dialogue',subject:'Englisch',grade:2,title:'Mini dialogue',instruction:'Führe einen sehr kurzen Dialog mit Begrüßung, Frage nach dem Befinden und Verabschiedung.',competency:'Sprechen',evidence:'Dialogaufnahme optional.'),
    CurriculumActivity(id:'g3_en_info',subject:'Englisch',grade:3,title:'Find the information',instruction:'Höre oder lies einen kurzen englischen Alltagstext und finde drei konkrete Informationen.',competency:'Hören und Lesen',evidence:'3 Antworten.'),
    CurriculumActivity(id:'g3_en_talk',subject:'Englisch',grade:3,title:'My favourite …',instruction:'Sprich in drei bis vier einfachen englischen Sätzen über ein Hobby, Tier oder Essen.',competency:'Sprechen',evidence:'Audioantwort.'),
    CurriculumActivity(id:'g4_en_message',subject:'Englisch',grade:4,title:'Short message',instruction:'Schreibe eine kurze englische Nachricht mit Begrüßung, zwei Informationen und Abschluss.',competency:'Schreiben',evidence:'Textnachricht.'),
    CurriculumActivity(id:'g4_en_roleplay',subject:'Englisch',grade:4,title:'Everyday role play',instruction:'Spiele eine einfache Alltagssituation auf Englisch, z. B. einkaufen oder nach dem Weg fragen.',competency:'Sprechen und Interagieren',evidence:'Rollenspiel.'),

    // Sachunterricht – forschend, sozial und wirtschaftlich handeln statt
    // alles nur abzufragen.
    CurriculumActivity(id:'g1_su_observe',subject:'Sachunterricht',grade:1,title:'Natur beobachten',instruction:'Beobachte draußen eine Pflanze oder ein Tier und notiere oder zeichne drei Merkmale.',competency:'Naturwissenschaftlicher Kompetenzbereich',evidence:'Skizze/Fotodokumentation.'),
    CurriculumActivity(id:'g1_su_map',subject:'Sachunterricht',grade:1,title:'Mein Nahraum',instruction:'Zeichne einen einfachen Wegplan von einem vertrauten Ort und markiere drei Orientierungspunkte.',competency:'Geografischer Kompetenzbereich',evidence:'Wegplan.'),
    CurriculumActivity(id:'g2_su_firstaid',subject:'Sachunterricht',grade:2,title:'Wer hilft im Notfall?',instruction:'Ordne typische Notfälle der richtigen Hilfsorganisation zu und erkläre, welche Information beim Notruf wichtig ist.',competency:'Sozialwissenschaftlicher Kompetenzbereich',evidence:'Zuordnung + Erklärung.'),
    CurriculumActivity(id:'g2_su_habitat',subject:'Sachunterricht',grade:2,title:'Lebensraum vergleichen',instruction:'Vergleiche zwei heimische Lebensräume nach Pflanzen, Tieren und Bedingungen.',competency:'Naturwissenschaftlicher Kompetenzbereich',evidence:'Vergleichstabelle.'),
    CurriculumActivity(id:'g3_su_trade',subject:'Sachunterricht',grade:3,title:'Vom Produkt zum Geschäft',instruction:'Verfolge den Weg eines Alltagsprodukts von Rohstoff/Herstellung bis Verkauf und Konsum.',competency:'Wirtschaftlicher Kompetenzbereich',evidence:'Prozesskette.'),
    CurriculumActivity(id:'g3_su_force',subject:'Sachunterricht',grade:3,title:'Kraft erforschen',instruction:'Untersuche mit sicheren Alltagsgegenständen eine Wirkung von Reibung, Magnetismus oder Hebel und protokolliere Beobachtungen.',competency:'Technischer/Naturwissenschaftlicher Kompetenzbereich',evidence:'Versuchsprotokoll.',requiresAdult:true),
    CurriculumActivity(id:'g4_su_energy',subject:'Sachunterricht',grade:4,title:'Energie im Alltag',instruction:'Finde vier Beispiele für Energieumwandlung im Alltag und erkläre jeweils, was sich verändert.',competency:'Naturwissenschaftlicher Kompetenzbereich',evidence:'4 Beispiele + Erklärung.'),
    CurriculumActivity(id:'g4_su_democracy',subject:'Sachunterricht',grade:4,title:'Gemeinsam entscheiden',instruction:'Plane mit einer Gruppe eine kleine Klassenentscheidung mit Vorschlägen, Abstimmung und begründeter Auswertung.',competency:'Sozialwissenschaftlicher Kompetenzbereich',evidence:'Abstimmungsprotokoll.'),
  ];
}
