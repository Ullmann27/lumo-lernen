// ════════════════════════════════════════════════════════════════════════
// TOPIC CURRICULUM — Konkrete Lehrplan-Inhalte pro Topic
// ════════════════════════════════════════════════════════════════════════
// Pro Topic-ID wird ein detaillierter Lehrplan-Kontext gespeichert.
// Dieser Kontext wird in jede ChatGPT-Anfrage eingebettet damit die
// Antworten klassen- UND themen-spezifisch sind.
//
// Heinz Feedback: 'Sachkunde steht Mathematik in Grammatik wird Mathematik
// gefragt. Viertklässler bekommen Erstklässler-Aufgaben.'
// Loesung: Detaillierter Scope pro Topic + Anti-Drift-Regeln.
// ════════════════════════════════════════════════════════════════════════

class TopicCurriculum {
  TopicCurriculum._();

  /// Liefert den vollstaendigen Lehrplan-Kontext fuer ein Topic.
  /// Wird in die ChatGPT-Anfrage eingebettet damit:
  ///   - die Antwort exakt zum Topic passt (kein Off-Topic Drift)
  ///   - die Schwierigkeitsstufe zur Klasse passt
  static TopicContext? of(String topicId) => _data[topicId];

  static final Map<String, TopicContext> _data = {
    // ════════════════════════════════════════════════════════════════
    // KLASSE 1 - MATHEMATIK
    // ════════════════════════════════════════════════════════════════
    'm1_zahlen10': TopicContext(
      grade: 1,
      subject: 'Mathematik',
      title: 'Zahlen 1-10',
      detailedScope:
          'Zahlen von 1 bis 10. Mengen abzaehlen, vergleichen (mehr/weniger/gleich), '
          'in richtige Reihenfolge bringen, Vorgaenger/Nachfolger benennen. '
          'NUR Zahlen bis 10, KEINE groesseren Zahlen.',
      exampleTask:
          'Beispiel: "Hier sind 4 Murmeln. Wenn du 1 dazu nimmst, hast du jetzt 5 Murmeln."',
      vocabulary: ['Zahl', 'zaehlen', 'mehr', 'weniger', 'gleich', 'Reihenfolge'],
      forbidden: 'NICHT Plus/Minus rechnen, NICHT ueber 10 zaehlen, NICHT Einmaleins.',
      complexityHint: 'Erste Klasse, 6-7 Jahre, kann gerade Zahlen erkennen',
    ),
    'm1_plus10': TopicContext(
      grade: 1,
      subject: 'Mathematik',
      title: 'Plus bis 10',
      detailedScope:
          'Addition mit Ergebnis maximal 10. Beispielaufgaben: 2+3, 4+5, 6+4. '
          'Mit Bildern (Fingern, Aepfeln) visualisieren.',
      exampleTask:
          '3 + 2 = ? Stell dir 3 Aepfel vor. Leg 2 dazu. Wie viele sind es jetzt? Antwort: 5.',
      vocabulary: ['plus', 'dazu', 'zusammen', 'gleich'],
      forbidden:
          'KEINE Aufgaben mit Ergebnis ueber 10. KEIN Minus. KEINE groesseren Zahlen.',
      complexityHint: 'Klasse 1 - Plus mit Ergebnis bis 10',
    ),
    'm1_minus10': TopicContext(
      grade: 1,
      subject: 'Mathematik',
      title: 'Minus bis 10',
      detailedScope:
          'Subtraktion mit Zahlen bis 10. Beispiele: 7-3, 10-6, 8-5. Visualisieren mit Wegnehmen.',
      exampleTask:
          '7 - 3 = ? Du hast 7 Bonbons. Du isst 3. Wie viele sind noch da? Antwort: 4.',
      vocabulary: ['minus', 'weg', 'uebrig', 'wegnehmen'],
      forbidden: 'KEIN Plus. KEINE Zahlen ueber 10. KEINE negativen Zahlen.',
      complexityHint: 'Klasse 1 - Minus im Zahlenraum bis 10',
    ),
    'm1_formen': TopicContext(
      grade: 1,
      subject: 'Mathematik',
      title: 'Formen',
      detailedScope:
          'Geometrische Grundformen: Kreis, Quadrat, Dreieck, Rechteck. '
          'Wo findet man sie im Alltag? Wieviele Ecken hat eine Form?',
      exampleTask:
          'Ein Quadrat hat 4 Ecken und 4 gleich lange Seiten. Wie viele Ecken hat ein Dreieck?',
      vocabulary: ['Kreis', 'Quadrat', 'Dreieck', 'Rechteck', 'Ecke', 'Seite', 'rund'],
      forbidden: 'KEIN Rechnen. KEINE 3D-Formen (Wuerfel, Kugel) - nur Flaechen.',
      complexityHint: 'Klasse 1 - Erste Geometrie',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 1 - DEUTSCH
    // ════════════════════════════════════════════════════════════════
    'd1_buchstaben_aj': TopicContext(
      grade: 1,
      subject: 'Deutsch',
      title: 'Buchstaben A-J',
      detailedScope:
          'Buchstaben A, B, C, D, E, F, G, H, I, J kennen lernen. '
          'Wie klingen sie? Welches Wort faengt mit A an? "A wie Apfel", "B wie Ball"...',
      exampleTask:
          '"A wie Apfel - kannst du noch ein Wort finden das mit A anfaengt? Affe! Auto!"',
      vocabulary: ['Buchstabe', 'Anfangslaut', 'wie', 'Apfel', 'Ball', 'Affe'],
      forbidden: 'KEIN Rechnen. KEINE Buchstaben nach J. KEIN Schreiben (das macht das Schreibmodul).',
      complexityHint: 'Klasse 1 - Erste Buchstaben hoeren',
    ),
    'd1_buchstaben_kt': TopicContext(
      grade: 1,
      subject: 'Deutsch',
      title: 'Buchstaben K-T',
      detailedScope:
          'Buchstaben K, L, M, N, O, P, Q, R, S, T mit Wortbeispielen.',
      exampleTask: '"M wie Maus. Kannst du noch ein M-Wort? Mama! Milch!"',
      vocabulary: ['Buchstabe', 'Anfangslaut', 'Maus', 'Nase', 'Otto'],
      forbidden: 'KEIN Rechnen. NICHT Buchstaben A-J, NICHT U-Z.',
      complexityHint: 'Klasse 1 - Mittlere Buchstaben',
    ),
    'd1_buchstaben_uz': TopicContext(
      grade: 1,
      subject: 'Deutsch',
      title: 'Buchstaben U-Z',
      detailedScope: 'Buchstaben U, V, W, X, Y, Z mit Wortbeispielen.',
      exampleTask: '"V wie Vogel. Kannst du noch ein V-Wort?"',
      vocabulary: ['Buchstabe', 'Vogel', 'Wolke', 'Zebra'],
      forbidden: 'KEIN Rechnen. NICHT Buchstaben A-T.',
      complexityHint: 'Klasse 1 - Letzte Buchstaben',
    ),
    'd1_woerter': TopicContext(
      grade: 1,
      subject: 'Deutsch',
      title: 'Erste Wörter',
      detailedScope:
          'Erste einfache Woerter: MAMA, PAPA, OMA, OPA, BALL, AUTO, HUND, KATZE. '
          'Buchstaben zusammensetzen zu Woertern.',
      exampleTask:
          'Mama hat 4 Buchstaben: M-A-M-A. Lies langsam: Em-A-Em-A. Das ergibt MAMA!',
      vocabulary: ['Wort', 'Buchstaben', 'lesen', 'MAMA', 'PAPA', 'BALL'],
      forbidden: 'KEIN Rechnen. KEINE schwierigen Woerter. NICHT Grammatik.',
      complexityHint: 'Klasse 1 - Erste 3-4-Buchstaben-Woerter',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 1 - SACHKUNDE
    // ════════════════════════════════════════════════════════════════
    's1_tiere': TopicContext(
      grade: 1,
      subject: 'Sachkunde',
      title: 'Tiere',
      detailedScope:
          'Bauernhof-Tiere (Kuh, Schwein, Huhn, Pferd, Schaf, Ziege), '
          'Wald-Tiere (Reh, Fuchs, Eichhoernchen, Hase), '
          'Haustiere (Hund, Katze, Hamster). Was fressen sie? Wo leben sie?',
      exampleTask:
          'Die Kuh lebt am Bauernhof und gibt Milch. Sie frisst Gras. Welches Tier gibt noch Milch?',
      vocabulary: ['Bauernhof', 'Wald', 'Haustier', 'Futter', 'Milch', 'Wolle'],
      forbidden: 'KEIN Rechnen. KEINE Buchstaben. NICHT Pflanzen.',
      complexityHint: 'Klasse 1 - Erste Tier-Kunde',
    ),
    's1_farben': TopicContext(
      grade: 1,
      subject: 'Sachkunde',
      title: 'Farben',
      detailedScope:
          'Grundfarben: Rot, Blau, Gelb, Gruen, Orange, Lila, Schwarz, Weiss. '
          'Was ist welche Farbe? Wie mischt man Farben (Rot+Gelb=Orange).',
      exampleTask:
          'Eine Tomate ist rot. Die Sonne ist gelb. Wenn du Rot und Gelb mischst, kommt Orange dabei raus!',
      vocabulary: ['Rot', 'Blau', 'Gelb', 'Gruen', 'mischen', 'Farbe'],
      forbidden: 'KEIN Rechnen. KEINE Buchstaben. NICHT Formen.',
      complexityHint: 'Klasse 1 - Farben erkennen',
    ),
    's1_koerper': TopicContext(
      grade: 1,
      subject: 'Sachkunde',
      title: 'Mein Körper',
      detailedScope:
          'Koerperteile: Kopf, Arme, Beine, Haende, Fuesse, Augen, Ohren, Nase, Mund. '
          'Wozu braucht man sie? Augen zum Sehen, Ohren zum Hoeren.',
      exampleTask:
          'Mit den Augen kannst du sehen. Mit den Ohren kannst du hoeren. Womit riechst du?',
      vocabulary: ['Kopf', 'Arm', 'Bein', 'Auge', 'Ohr', 'Nase', 'Mund', 'sehen', 'hoeren'],
      forbidden: 'KEIN Rechnen. KEINE detaillierte Anatomie. NICHT Krankheiten.',
      complexityHint: 'Klasse 1 - Erste Koerperkunde',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 2 - MATHEMATIK
    // ════════════════════════════════════════════════════════════════
    'm2_zahlen100': TopicContext(
      grade: 2,
      subject: 'Mathematik',
      title: 'Zahlen bis 100',
      detailedScope:
          'Zahlen von 1 bis 100 lesen, schreiben, vergleichen. '
          'Zehner und Einer unterscheiden (z.B. 47 = 4 Zehner + 7 Einer). '
          'In 10er-Schritten zaehlen: 10, 20, 30...',
      exampleTask:
          '47 besteht aus 4 Zehnern und 7 Einern. Schreib die Zahl, die 1 Zehner und 5 Einer hat. Antwort: 15.',
      vocabulary: ['Zehner', 'Einer', 'Hunderter', 'Stelle'],
      forbidden: 'KEINE Zahlen ueber 100. KEIN Bruchrechnen. NICHT Einmaleins.',
      complexityHint: 'Klasse 2 - Zahlenraum bis 100',
    ),
    'm2_einmaleins': TopicContext(
      grade: 2,
      subject: 'Mathematik',
      title: 'Kleines 1×1',
      detailedScope:
          'Multiplikation: 2er-, 5er-, 10er-Reihe. '
          'Beispiele: 2×3=6, 5×4=20, 10×7=70. '
          'Mal als wiederholte Addition: 3×4 = 4+4+4 = 12.',
      exampleTask:
          '3×4 bedeutet: 3 mal 4. Also 4+4+4 = 12. Probier 5×2 (5 mal die 2): 2+2+2+2+2 = ?',
      vocabulary: ['mal', 'Reihe', 'Multiplikation', 'mehrfach'],
      forbidden: 'NICHT 3er, 4er, 6er, 7er, 8er, 9er Reihe. NICHT Division. NICHT ueber 100.',
      complexityHint: 'Klasse 2 - Nur 2er, 5er, 10er-Reihe',
    ),
    'm2_uhr': TopicContext(
      grade: 2,
      subject: 'Mathematik',
      title: 'Die Uhr',
      detailedScope:
          'Uhrzeit ablesen: volle Stunden (3:00), halbe Stunden (3:30), Viertel (3:15, 3:45). '
          'Stundenzeiger und Minutenzeiger erkennen.',
      exampleTask:
          'Wenn der grosse Zeiger auf 12 zeigt und der kleine auf 7, ist es 7 Uhr. Was ist es, wenn der grosse auf 6 zeigt? Halb!',
      vocabulary: ['Stunde', 'Minute', 'Zeiger', 'halb', 'viertel'],
      forbidden: 'KEIN normales Rechnen. NICHT Sekunden. NICHT 24h-Format.',
      complexityHint: 'Klasse 2 - Analoge Uhr lesen',
    ),
    'm2_geld': TopicContext(
      grade: 2,
      subject: 'Mathematik',
      title: 'Geld',
      detailedScope:
          'Euro und Cent kennen lernen. 1€ = 100 Cent. '
          'Muenzen: 1c, 2c, 5c, 10c, 20c, 50c, 1€, 2€. '
          'Einkaufs-Aufgaben: Was kostet 2 Brote?',
      exampleTask:
          'Ein Apfel kostet 50 Cent. Du kaufst 2 Aepfel. Wie viel zahlst du? 50+50=100 Cent = 1 Euro.',
      vocabulary: ['Euro', 'Cent', 'Muenze', 'kaufen', 'kostet', 'bezahlen'],
      forbidden: 'KEINE grossen Geldbetraege (>10€). NICHT Prozentrechnen.',
      complexityHint: 'Klasse 2 - Kleines Geld bis 10 Euro',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 2 - DEUTSCH
    // ════════════════════════════════════════════════════════════════
    'd2_saetze': TopicContext(
      grade: 2,
      subject: 'Deutsch',
      title: 'Sätze bilden',
      detailedScope:
          'Aus Woertern Saetze bauen. Ein Satz hat Subjekt + Verb (Wer? + Was tut?). '
          'Satzanfang gross, Punkt am Ende. Beispiel: "Der Hund bellt."',
      exampleTask:
          'Bau einen Satz mit den Woertern: Katze, schlaeft, Sofa. -> "Die Katze schlaeft auf dem Sofa."',
      vocabulary: ['Satz', 'Subjekt', 'Verb', 'gross', 'Punkt'],
      forbidden: 'KEIN Rechnen. NICHT Faelle/Grammatik vertieft. KEINE komplexen Saetze.',
      complexityHint: 'Klasse 2 - Erste einfache Saetze',
    ),
    'd2_artikel': TopicContext(
      grade: 2,
      subject: 'Deutsch',
      title: 'Der/Die/Das',
      detailedScope:
          'Bestimmte Artikel: DER (maennlich, z.B. der Hund), '
          'DIE (weiblich/Mehrzahl, z.B. die Katze, die Hunde), '
          'DAS (saechlich, z.B. das Kind).',
      exampleTask:
          'Welcher Artikel passt zu "Auto"? Das Auto. Zu "Sonne"? Die Sonne. Probier: ___ Tisch?',
      vocabulary: ['Artikel', 'der', 'die', 'das', 'maennlich', 'weiblich', 'saechlich'],
      forbidden: 'KEIN Rechnen. NICHT Faelle (Nominativ, Akkusativ...). NICHT Pluralbildung.',
      complexityHint: 'Klasse 2 - Bestimmte Artikel',
    ),
    'd2_mehrzahl': TopicContext(
      grade: 2,
      subject: 'Deutsch',
      title: 'Mehrzahl',
      detailedScope:
          'Einzahl/Mehrzahl bilden. "Ein Hund - viele Hunde", "ein Apfel - viele Aepfel". '
          'Verschiedene Endungen: -e, -en, -er, -s, oder Umlaut.',
      exampleTask:
          'Ein Hund. Mehrere: Hunde. Ein Apfel. Mehrere: Aepfel (mit Umlaut!). Wie heisst die Mehrzahl von Baum?',
      vocabulary: ['Einzahl', 'Mehrzahl', 'Plural', 'mehrere', 'Umlaut'],
      forbidden: 'KEIN Rechnen. NICHT Faelle. NICHT unregelmaessige Verben.',
      complexityHint: 'Klasse 2 - Pluralbildung Nomen',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 2 - SACHKUNDE
    // ════════════════════════════════════════════════════════════════
    's2_jahreszeiten': TopicContext(
      grade: 2,
      subject: 'Sachkunde',
      title: 'Jahreszeiten',
      detailedScope:
          'Fruehling, Sommer, Herbst, Winter. Was passiert in jeder Jahreszeit? '
          'Wetter, Tiere, Pflanzen, Kleidung.',
      exampleTask:
          'Im Fruehling werden die Tage waermer, Blumen bluehen. Was passiert mit den Baeumen im Herbst?',
      vocabulary: ['Fruehling', 'Sommer', 'Herbst', 'Winter', 'bluehen', 'fallen', 'kalt'],
      forbidden: 'KEIN Rechnen. KEINE Buchstaben. NICHT Klimazonen.',
      complexityHint: 'Klasse 2 - Vier Jahreszeiten',
    ),
    's2_wetter': TopicContext(
      grade: 2,
      subject: 'Sachkunde',
      title: 'Wetter',
      detailedScope:
          'Wetterphaenomene: Sonne, Regen, Schnee, Wind, Wolken, Gewitter, Nebel. '
          'Wann ist welches Wetter? Wie misst man Temperatur (Thermometer)?',
      exampleTask:
          'Wenn die Sonne scheint, ist es warm. Wenn es regnet, brauchen wir was? Einen Regenschirm!',
      vocabulary: ['Sonne', 'Regen', 'Schnee', 'Wind', 'Wolke', 'Thermometer'],
      forbidden: 'KEIN Rechnen. NICHT Klimawandel.',
      complexityHint: 'Klasse 2 - Wetter-Grundkunde',
    ),
    's2_verkehr': TopicContext(
      grade: 2,
      subject: 'Sachkunde',
      title: 'Verkehr',
      detailedScope:
          'Sicher zur Schule: Ampel (Rot=stehen, Gruen=gehen), Zebrastreifen, '
          'Schulweg, Fahrradregeln, Helm tragen.',
      exampleTask:
          'An der Ampel: Was bedeutet rot? Stehen bleiben. Was bedeutet gruen? Gehen. Bei gelb?',
      vocabulary: ['Ampel', 'Zebrastreifen', 'Fahrrad', 'Helm', 'Schulweg'],
      forbidden: 'KEIN Rechnen. NICHT Autotypen.',
      complexityHint: 'Klasse 2 - Verkehrserziehung',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 3 - MATHEMATIK
    // ════════════════════════════════════════════════════════════════
    'm3_zahlen1000': TopicContext(
      grade: 3,
      subject: 'Mathematik',
      title: 'Zahlen bis 1000',
      detailedScope:
          'Zahlenraum bis 1000. Hunderter, Zehner, Einer. '
          'Beispiel: 437 = 4 Hunderter + 3 Zehner + 7 Einer. '
          'Vergleichen, sortieren, schriftliches Plus/Minus.',
      exampleTask:
          'Die Zahl 256 besteht aus 2 Hundertern, 5 Zehnern und 6 Einern. Schreib eine Zahl mit 3 Hundertern und 4 Zehnern (3_40 = 340).',
      vocabulary: ['Hunderter', 'Zehner', 'Einer', 'Stellenwert'],
      forbidden: 'KEIN Bruchrechnen. KEINE Zahlen ueber 1000.',
      complexityHint: 'Klasse 3 - Zahlenraum 1000',
    ),
    'm3_einmaleins_voll': TopicContext(
      grade: 3,
      subject: 'Mathematik',
      title: 'Großes 1×1',
      detailedScope:
          'Alle Multiplikations-Reihen 1×1 bis 10×10. '
          'Auch Division als Umkehrung: 6×4=24, also 24÷4=6.',
      exampleTask:
          '7×8 = ? Tipp: 7×8 ist genauso wie 8×7. Du kannst auch 7×4 = 28 doppelt nehmen: 28+28 = 56.',
      vocabulary: ['mal', 'geteilt durch', 'Quotient', 'Reihe', 'umgekehrt'],
      forbidden: 'NICHT Bruchrechnen. NICHT ueber 100 (max 10×10=100).',
      complexityHint: 'Klasse 3 - Volles Einmaleins + Division',
    ),
    'm3_geometrie': TopicContext(
      grade: 3,
      subject: 'Mathematik',
      title: 'Geometrie',
      detailedScope:
          'Umfang von Rechteck/Quadrat berechnen (alle Seiten zusammenzaehlen). '
          'Flaeche als Anzahl Quadrate. Erste Wuerfel/Quader im Raum.',
      exampleTask:
          'Ein Quadrat hat alle Seiten 5cm lang. Der Umfang ist 5+5+5+5 = 20cm. '
          'Bei einem Rechteck mit 4cm und 3cm? 4+3+4+3 = 14cm.',
      vocabulary: ['Umfang', 'Flaeche', 'Seite', 'Rechteck', 'Quadrat', 'Wuerfel'],
      forbidden: 'KEIN Bruchrechnen. NICHT Volumen berechnen.',
      complexityHint: 'Klasse 3 - Umfang/Flaeche Basis',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 3 - DEUTSCH
    // ════════════════════════════════════════════════════════════════
    'd3_wortarten': TopicContext(
      grade: 3,
      subject: 'Deutsch',
      title: 'Wortarten',
      detailedScope:
          'NOMEN (Dinge: Hund, Tisch, Liebe), '
          'VERBEN (Taetigkeiten: laufen, denken), '
          'ADJEKTIVE (Eigenschaften: schoen, klein, schnell).',
      exampleTask:
          'Im Satz "Der schnelle Hund laeuft": Nomen = Hund. Verb = laeuft. Adjektiv = schnell. '
          'Finde Wortarten in: "Die rote Blume bluehte."',
      vocabulary: ['Nomen', 'Verb', 'Adjektiv', 'Hauptwort', 'Taetigkeitswort', 'Eigenschaftswort'],
      forbidden: 'KEIN Rechnen. NICHT Faelle. NICHT Zeitformen.',
      complexityHint: 'Klasse 3 - Drei Hauptwortarten',
    ),
    'd3_zeitformen': TopicContext(
      grade: 3,
      subject: 'Deutsch',
      title: 'Zeitformen',
      detailedScope:
          'Gegenwart (Praesens): "Ich gehe.", '
          'Vergangenheit (Praeteritum): "Ich ging.", '
          'Zukunft (Futur): "Ich werde gehen." NUR diese 3 einfachen Formen.',
      exampleTask:
          '"Ich spiele." ist Gegenwart. "Ich spielte." ist Vergangenheit. "Ich werde spielen." ist Zukunft. '
          'Wie heisst die Vergangenheit von "lachen"?',
      vocabulary: ['Gegenwart', 'Vergangenheit', 'Zukunft', 'Zeit', 'Verb'],
      forbidden: 'KEIN Rechnen. NICHT Perfekt/Plusquamperfekt. NICHT Konjunktiv.',
      complexityHint: 'Klasse 3 - Drei einfache Zeiten',
    ),
    'd3_geschichten': TopicContext(
      grade: 3,
      subject: 'Deutsch',
      title: 'Geschichten',
      detailedScope:
          'Kurze Geschichten lesen und verstehen. Hauptfigur erkennen. '
          'Anfang, Mitte, Ende einer Geschichte. Eigene Maerchen.',
      exampleTask:
          'Eine Geschichte hat einen Anfang ("Es war einmal..."), eine Mitte (was passiert) und ein Ende '
          '("...und sie lebten gluecklich"). Erzaehl mir eine kleine Geschichte ueber einen Fuchs!',
      vocabulary: ['Geschichte', 'Anfang', 'Mitte', 'Ende', 'Hauptfigur', 'Maerchen'],
      forbidden: 'KEIN Rechnen. NICHT Romane. NICHT Lyrik analysieren.',
      complexityHint: 'Klasse 3 - Erste Textarbeit',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 3 - SACHKUNDE
    // ════════════════════════════════════════════════════════════════
    's3_oesterreich': TopicContext(
      grade: 3,
      subject: 'Sachkunde',
      title: 'Österreich',
      detailedScope:
          'Die 9 Bundeslaender Oesterreichs: Wien, Niederoesterreich, Oberoesterreich, '
          'Steiermark, Tirol, Salzburg, Kaernten, Vorarlberg, Burgenland. '
          'Hauptstadt = Wien. Berge (Alpen), Donau.',
      exampleTask:
          'Oesterreich hat 9 Bundeslaender. Die Hauptstadt ist Wien. In welchem Bundesland wohnt ihr? '
          'Heinz wohnt in Niederoesterreich (Gaenserndorf).',
      vocabulary: ['Bundesland', 'Hauptstadt', 'Wien', 'Alpen', 'Donau'],
      forbidden: 'KEIN Rechnen. NICHT Politik. NICHT Geschichte vertieft.',
      complexityHint: 'Klasse 3 - Bundeslaender Oesterreich',
    ),
    's3_natur': TopicContext(
      grade: 3,
      subject: 'Sachkunde',
      title: 'Natur',
      detailedScope:
          'Pflanzen (Baum, Strauch, Blume), Pflanzenteile (Wurzel, Stamm, Blatt, Bluete). '
          'Wie wachsen Pflanzen (Wasser, Licht, Erde)? Heimische Baeume.',
      exampleTask:
          'Eine Pflanze braucht Wasser, Licht und Erde um zu wachsen. Welche 3 Teile hat eine Blume? '
          'Wurzel (unten), Stamm/Stiel, Bluete (oben).',
      vocabulary: ['Pflanze', 'Wurzel', 'Stamm', 'Blatt', 'Bluete', 'wachsen'],
      forbidden: 'KEIN Rechnen. NICHT Genetik.',
      complexityHint: 'Klasse 3 - Pflanzen-Grundwissen',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 4 - MATHEMATIK
    // ════════════════════════════════════════════════════════════════
    'm4_million': TopicContext(
      grade: 4,
      subject: 'Mathematik',
      title: 'Zahlen bis 1 Million',
      detailedScope:
          'Sehr grosse Zahlen lesen und schreiben. '
          'Millionen, Hunderttausender, Zehntausender, Tausender. '
          'Beispiel: 1.250.000 = eine Million zweihundertfuenfzigtausend. '
          'Schriftlich addieren/subtrahieren grosser Zahlen.',
      exampleTask:
          'Die Zahl 234.567 lesen wir: "Zweihundertvierunddreissigtausend fuenfhundertsiebenundsechzig". '
          'Was ist 100.000 + 50.000? Antwort: 150.000.',
      vocabulary: ['Million', 'Hunderttausender', 'Zehntausender', 'Tausender', 'Stellenwerttafel'],
      forbidden:
          'AUF KEINEN FALL Aufgaben wie "3 Aepfel + 2 Aepfel" - das ist 1. Klasse! '
          'Es geht um Zahlen ueber 1000!',
      complexityHint:
          'Klasse 4 - GROSSE Zahlen ueber 1000! Schueler kann Einmaleins + Zahlenraum 1000.',
    ),
    'm4_bruch': TopicContext(
      grade: 4,
      subject: 'Mathematik',
      title: 'Bruchrechnen',
      detailedScope:
          'Brueche: 1/2 (eine Haelfte), 1/3 (ein Drittel), 1/4 (ein Viertel), 1/8. '
          'Zaehler oben, Nenner unten. Brueche aus Bildern ablesen (z.B. Pizza in 4 Teile, 1 weg). '
          'Einfache Vergleiche: 1/2 > 1/4.',
      exampleTask:
          'Eine Pizza hat 4 Stuecke. Du isst 1 Stueck. Du hast 1/4 gegessen. '
          'Es bleiben 3/4 uebrig. Welcher Bruch ist groesser: 1/2 oder 1/4? Antwort: 1/2 (das ist die Haelfte!).',
      vocabulary: ['Bruch', 'Zaehler', 'Nenner', 'Haelfte', 'Drittel', 'Viertel', '1/2', '1/4'],
      forbidden:
          'KEINE einfachen Aufgaben wie "3+2 Aepfel" - es geht um BRUECHE! '
          'KEINE Dezimalzahlen. KEINE Prozentrechnung.',
      complexityHint:
          'Klasse 4 - BRUECHE! Wenn du Aepfel verwendest, dann nur als Bruch (1/2 Apfel, nicht 3 Aepfel)!',
    ),
    'm4_textaufgaben': TopicContext(
      grade: 4,
      subject: 'Mathematik',
      title: 'Textaufgaben',
      detailedScope:
          'Sachaufgaben mit Geld, Zeit, Laengen aus dem Alltag. '
          'Frage erkennen, Rechenweg planen, Antwort als Satz formulieren. '
          'Mit grossen Zahlen oder Multiplikation.',
      exampleTask:
          'Anna kauft 3 Buecher zu je 8 Euro. Wieviel zahlt sie? '
          'Rechenweg: 3 × 8 = 24. Antwort: Anna zahlt 24 Euro.',
      vocabulary: ['Frage', 'Rechenweg', 'Antwort', 'Sachaufgabe'],
      forbidden: 'KEINE einfachen Aufgaben mit 3 Aepfeln. Es muss eine richtige Textaufgabe sein.',
      complexityHint: 'Klasse 4 - Komplexe Textaufgaben mit mehreren Schritten',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 4 - DEUTSCH
    // ════════════════════════════════════════════════════════════════
    'd4_grammatik': TopicContext(
      grade: 4,
      subject: 'Deutsch',
      title: 'Grammatik',
      detailedScope:
          'Die VIER FAELLE: Nominativ (Wer?), Genitiv (Wessen?), Dativ (Wem?), Akkusativ (Wen?). '
          'Satzglieder: Subjekt, Praedikat (Verb), Objekt. '
          'Beispiel: "Der Hund (Nom) gibt dem Kind (Dativ) den Ball (Akk)."',
      exampleTask:
          'Im Satz "Die Mutter gibt dem Kind den Apfel": '
          'Wer gibt? Die Mutter (Nominativ). Wem? Dem Kind (Dativ). Was? Den Apfel (Akkusativ).',
      vocabulary: ['Nominativ', 'Genitiv', 'Dativ', 'Akkusativ', 'Subjekt', 'Objekt', 'Praedikat'],
      forbidden:
          'AUF KEINEN FALL Mathe-Aufgaben! Das hier ist DEUTSCH-GRAMMATIK! '
          'KEINE Rechenaufgaben. KEINE einfachen Saetze ohne Faelle.',
      complexityHint:
          'Klasse 4 - Die 4 Faelle (Nom/Gen/Dat/Akk). Schueler kennt schon Wortarten + Zeitformen.',
    ),
    'd4_aufsatz': TopicContext(
      grade: 4,
      subject: 'Deutsch',
      title: 'Aufsätze',
      detailedScope:
          'Texte schreiben: Erzaehlung (was passiert ist), Beschreibung (wie etwas aussieht), '
          'Bericht (wer/was/wo/wann/warum). Einleitung-Hauptteil-Schluss.',
      exampleTask:
          'Eine Erzaehlung hat einen Anfang, eine spannende Mitte und ein Ende. '
          'Bei einer Beschreibung sagst du wie etwas aussieht: Farbe, Groesse, Form. '
          'Beschreib mir deine Schultasche!',
      vocabulary: ['Erzaehlung', 'Beschreibung', 'Bericht', 'Einleitung', 'Hauptteil', 'Schluss'],
      forbidden: 'KEIN Rechnen. NICHT Grammatik analysieren.',
      complexityHint: 'Klasse 4 - Texte schreiben',
    ),

    // ════════════════════════════════════════════════════════════════
    // KLASSE 4 - SACHKUNDE
    // ════════════════════════════════════════════════════════════════
    's4_europa': TopicContext(
      grade: 4,
      subject: 'Sachkunde',
      title: 'Europa',
      detailedScope:
          'Europa ist ein Kontinent. Nachbarlaender Oesterreichs: Deutschland, Schweiz, Italien, Slowenien, '
          'Ungarn, Slowakei, Tschechien, Liechtenstein. '
          'Bekannte Hauptstaedte: Berlin, Rom, Paris, London, Madrid.',
      exampleTask:
          'Oesterreich liegt in Europa und hat 8 Nachbarlaender. Im Norden ist Deutschland mit Berlin als Hauptstadt. '
          'Welches Land liegt im Sueden von Oesterreich? Italien!',
      vocabulary: ['Kontinent', 'Europa', 'Nachbarland', 'Hauptstadt', 'Grenze'],
      forbidden: 'KEIN Rechnen. NICHT EU-Politik. NICHT andere Kontinente.',
      complexityHint: 'Klasse 4 - Europa-Geografie',
    ),
    's4_geschichte': TopicContext(
      grade: 4,
      subject: 'Sachkunde',
      title: 'Geschichte',
      detailedScope:
          'Zeitreise durch Oesterreichs Geschichte: Roemer in Carnuntum, '
          'Ritter und Burgen im Mittelalter, Kaiserzeit (Maria Theresia, Franz Joseph), '
          'Zweiter Weltkrieg, heute Republik Oesterreich.',
      exampleTask:
          'Im Mittelalter lebten Ritter in Burgen. Sie hatten Schwerter und Ruestungen. '
          'Die Burg Kreuzenstein in Niederoesterreich kannst du heute noch besichtigen! '
          'Wer regiert heute in Oesterreich? Der Bundespraesident.',
      vocabulary: ['Mittelalter', 'Ritter', 'Burg', 'Kaiser', 'Maria Theresia', 'Republik'],
      forbidden:
          'AUF KEINEN FALL Mathe-Aufgaben! '
          'AUF KEINEN FALL fragen "Was moechtest du lernen - Mathe oder Tiere?" - das hier ist GESCHICHTE!',
      complexityHint:
          'Klasse 4 - Oesterreichs Geschichte. Steig direkt mit einem konkreten Geschichts-Thema ein!',
    ),
  };
}

/// Detaillierter Lehrplan-Kontext fuer ein Topic.
/// Wird in die ChatGPT-Anfrage eingebettet.
class TopicContext {
  const TopicContext({
    required this.grade,
    required this.subject,
    required this.title,
    required this.detailedScope,
    required this.exampleTask,
    required this.vocabulary,
    required this.forbidden,
    required this.complexityHint,
  });
  final int grade;
  final String subject;
  final String title;
  final String detailedScope;
  final String exampleTask;
  final List<String> vocabulary;
  final String forbidden;
  final String complexityHint;

  /// Baut einen praezisen Prompt-Header fuer ChatGPT.
  String buildPromptHeader() {
    final vocab =
        vocabulary.isEmpty ? '' : '\nVerwende Woerter wie: ${vocabulary.join(", ")}.';
    return '''
[STRENGER LEHRPLAN-KONTEXT - HALTE DICH GENAU DARAN]
Klasse: $grade. Klasse Volksschule Oesterreich
Fach: $subject
Thema: $title
$complexityHint

WAS IN DIESEM TOPIC GELEHRT WIRD:
$detailedScope

KONKRETES BEISPIEL wie eine gute Antwort aussieht:
$exampleTask

VERBOTEN IN DIESER ANTWORT:
$forbidden$vocab

WICHTIG: 
- Antworte nur zum Thema "$title" aus $subject Klasse $grade!
- KEINE Themen-Wechsel anbieten ("magst du Mathe oder Tiere?")!
- Max 3 kurze Saetze + 1 konkrete Aufgabe/Frage.
- Sprich das Kind direkt an. Lobe oft.
[KONTEXT-ENDE]

''';
  }
}
