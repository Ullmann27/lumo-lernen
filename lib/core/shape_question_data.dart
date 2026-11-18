/// Formenfragen für die 1. Klasse: kurze Sätze, Alltagsdinge, keine
/// Fachwörter wie „rechter Winkel“ oder „Mittelpunkt“. Jede Kartenauswahl
/// hat genau eine passende Antwort (Kreis und Oval haben beide keine Ecke
/// und stehen deshalb bei solchen Fragen nie gemeinsam zur Wahl).
const shapeQuestions = <(String, String, List<String>, String)>[
  (
    'Welche Form hat genau 3 Ecken?',
    'Dreieck',
    ['Dreieck', 'Quadrat', 'Kreis'],
    'Ein Dreieck hat 3 Ecken und 3 Seiten.'
  ),
  (
    'Welche Form hat genau 3 gerade Seiten?',
    'Dreieck',
    ['Rechteck', 'Dreieck', 'Oval'],
    'Ein Dreieck hat 3 Seiten und 3 Ecken.'
  ),
  (
    'Ein Verkehrsschild hat 3 Ecken. Welche Form hat es?',
    'Dreieck',
    ['Dreieck', 'Kreis', 'Quadrat'],
    'Zähle die Ecken des Schildes. Es sind 3: ein Dreieck.'
  ),
  (
    'Du zeichnest 3 gerade Striche. Sie treffen sich an 3 Ecken. Welche Form entsteht?',
    'Dreieck',
    ['Dreieck', 'Oval', 'Rechteck'],
    '3 Striche und 3 Ecken ergeben ein Dreieck.'
  ),
  (
    'Welche dieser Formen hat keine Ecke?',
    'Kreis',
    ['Dreieck', 'Kreis', 'Quadrat'],
    'Der Kreis ist rund. Er hat keine Ecke.'
  ),
  (
    'Du schaust von oben auf eine Münze. Welche Form siehst du?',
    'Kreis',
    ['Kreis', 'Dreieck', 'Quadrat'],
    'Eine Münze ist rund wie ein Kreis.'
  ),
  (
    'Welche Form ist rund und überall gleich breit?',
    'Kreis',
    ['Kreis', 'Oval', 'Rechteck'],
    'Ein Kreis ist überall gleich breit. Ein Oval ist länglich.'
  ),
  (
    'Welche Form hat das Zifferblatt einer runden Uhr?',
    'Kreis',
    ['Kreis', 'Quadrat', 'Dreieck'],
    'Eine runde Uhr hat die Form eines Kreises.'
  ),
  (
    'Welche Form hat 4 Ecken und 4 gleich lange Seiten?',
    'Quadrat',
    ['Quadrat', 'Kreis', 'Dreieck'],
    'Ein Quadrat hat 4 Ecken. Alle 4 Seiten sind gleich lang.'
  ),
  (
    'Eine Fliese hat 4 Ecken. Sie ist genauso breit wie hoch. Welche Form hat sie?',
    'Quadrat',
    ['Quadrat', 'Oval', 'Dreieck'],
    'Gleich breit und gleich hoch mit 4 Ecken: Das ist ein Quadrat.'
  ),
  (
    'Ein Spielbrett hat 4 Ecken. Alle 4 Seiten sind gleich lang. Welche Form hat es?',
    'Quadrat',
    ['Quadrat', 'Kreis', 'Dreieck'],
    '4 Ecken und 4 gleich lange Seiten: Das ist ein Quadrat.'
  ),
  (
    'Du drehst ein Quadrat auf eine Spitze. Welche Form ist es jetzt?',
    'Quadrat',
    ['Dreieck', 'Quadrat', 'Oval'],
    'Beim Drehen bleibt die Form gleich. Es ist immer noch ein Quadrat.'
  ),
  (
    'Welche Form hat 4 Ecken, 2 lange Seiten und 2 kurze Seiten?',
    'Rechteck',
    ['Rechteck', 'Quadrat', 'Dreieck'],
    'Ein Rechteck hat 4 Ecken. Gegenüberliegende Seiten sind gleich lang.'
  ),
  (
    'Ein Heftblatt hat 4 Ecken. Es ist höher als breit. Welche Form hat es?',
    'Rechteck',
    ['Rechteck', 'Quadrat', 'Oval'],
    'Das Heftblatt hat 2 lange und 2 kurze Seiten: ein Rechteck.'
  ),
  (
    'Eine Tür hat 4 Ecken. Sie ist viel höher als breit. Welche Form hat sie?',
    'Rechteck',
    ['Dreieck', 'Rechteck', 'Kreis'],
    'Die Tür hat 2 lange und 2 kurze Seiten: ein Rechteck.'
  ),
  (
    'Eine Tafel Schokolade hat 4 Ecken. Sie ist länger als breit. Welche Form hat sie?',
    'Rechteck',
    ['Rechteck', 'Quadrat', 'Kreis'],
    '4 Ecken, 2 lange und 2 kurze Seiten: Das ist ein Rechteck.'
  ),
  (
    'Welche Form ist rund und länglich?',
    'Oval',
    ['Oval', 'Kreis', 'Rechteck'],
    'Ein Oval ist rund, aber länglich. Es hat keine Ecke.'
  ),
  (
    'Welche Form sieht aus wie ein Ei?',
    'Oval',
    ['Oval', 'Dreieck', 'Quadrat'],
    'Ein Ei ist rund und länglich wie ein Oval.'
  ),
  (
    'Eine Form ist rund und breiter als hoch. Welche Form ist es?',
    'Oval',
    ['Oval', 'Kreis', 'Rechteck'],
    'Ein Kreis ist überall gleich breit. Diese Form ist länglich: ein Oval.'
  ),
  (
    'Du ziehst einen Kreis in die Länge. Welche Form entsteht?',
    'Oval',
    ['Kreis', 'Oval', 'Dreieck'],
    'Aus dem Kreis wird eine längliche runde Form: ein Oval.'
  ),
];
