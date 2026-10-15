/// Authored properties and transfer examples, not randomized colour variants.
/// Each offered set has one matching answer (circle and oval both lack corners).
const shapeQuestions = <(String, String, List<String>, String)>[
  (
    'Welche Form hat genau drei Ecken?',
    'Dreieck',
    ['Dreieck', 'Quadrat', 'Kreis'],
    'Drei gerade Seiten treffen sich an drei Ecken.'
  ),
  (
    'Welche Form hat genau drei gerade Seiten?',
    'Dreieck',
    ['Rechteck', 'Dreieck', 'Oval'],
    'Ein Dreieck hat drei Seiten und drei Ecken.'
  ),
  (
    'Welche Form passt zu einem Verkehrsschild mit drei Ecken?',
    'Dreieck',
    ['Dreieck', 'Kreis', 'Quadrat'],
    'Achte auf die drei Ecken des Schildes, nicht auf seine Farbe.'
  ),
  (
    'Du verbindest drei Punkte, die nicht auf einer Geraden liegen, zu einer geschlossenen Form mit drei geraden Seiten. Welche Form entsteht?',
    'Dreieck',
    ['Dreieck', 'Oval', 'Rechteck'],
    'Die drei Punkte müssen außerhalb einer gemeinsamen geraden Linie liegen. Dann bilden sie ein Dreieck.'
  ),
  (
    'Welche dieser Formen hat keine Ecke?',
    'Kreis',
    ['Dreieck', 'Kreis', 'Quadrat'],
    'Unter diesen drei Formen hat nur der Kreis keine Ecke. Auch ein Oval hätte keine Ecke.'
  ),
  (
    'Welche Form passt zur kreisrunden Fläche einer Münze?',
    'Kreis',
    ['Kreis', 'Dreieck', 'Oval'],
    'Die runde Münzfläche ist ein Kreis; der ganze Gegenstand ist ein Körper.'
  ),
  (
    'Welche Form ist rund und in jede Richtung gleich breit?',
    'Kreis',
    ['Kreis', 'Oval', 'Rechteck'],
    'Ein Kreis ist durch seinen Mittelpunkt in jede Richtung gleich breit. Ein längliches Oval nicht.'
  ),
  (
    'Welche Form passt zu einem Zifferblatt, dessen Rand überall gleich weit vom Mittelpunkt entfernt ist?',
    'Kreis',
    ['Kreis', 'Quadrat', 'Oval'],
    'Beim Kreis liegen alle Randpunkte gleich weit vom Mittelpunkt entfernt.'
  ),
  (
    'Welche Form hat vier gleich lange Seiten und vier Ecken wie die Ecke eines Heftes?',
    'Quadrat',
    ['Quadrat', 'Kreis', 'Dreieck'],
    'Ein Quadrat hat vier gleich lange Seiten und vier rechte Winkel.'
  ),
  (
    'Eine quadratische Fliese ist 10 cm breit und 10 cm hoch. Welche Form hat ihre Fläche?',
    'Quadrat',
    ['Quadrat', 'Oval', 'Dreieck'],
    'Die vier Seiten der quadratischen Fliese sind gleich lang.'
  ),
  (
    'Welche Form passt zu einem vierseitigen Spielbrett, bei dem alle Seiten gleich lang und alle Winkel recht sind?',
    'Quadrat',
    ['Quadrat', 'Kreis', 'Dreieck'],
    'Rechte Winkel und vier gleich lange Seiten kennzeichnen ein Quadrat.'
  ),
  (
    'Du drehst eine Form mit vier gleich langen Seiten und vier rechten Winkeln auf eine Spitze. Wie heißt sie weiterhin?',
    'Quadrat',
    ['Dreieck', 'Quadrat', 'Oval'],
    'Durch Drehen ändern sich Seitenlängen und Winkel nicht. Ein gedrehtes Quadrat bleibt ein Quadrat.'
  ),
  (
    'Welche Form hat vier rechte Winkel, zwei lange und zwei kurze Seiten?',
    'Rechteck',
    ['Rechteck', 'Quadrat', 'Dreieck'],
    'Bei diesem Rechteck sind gegenüberliegende Seiten gleich lang; die benachbarten Seiten sind verschieden lang.'
  ),
  (
    'Welche Form passt zu einem Heftblatt, das deutlich höher als breit ist und vier rechte Winkel hat?',
    'Rechteck',
    ['Rechteck', 'Quadrat', 'Oval'],
    'Das Heftblatt hat zwei längere und zwei kürzere Seiten.'
  ),
  (
    'Welche Form hat die Vorderfläche einer Tür mit vier rechten Winkeln, die viel höher als breit ist?',
    'Rechteck',
    ['Dreieck', 'Rechteck', 'Kreis'],
    'Die Vorderfläche ist ein Rechteck. Die ganze Tür hat auch eine Dicke.'
  ),
  (
    'Eine geschlossene Form hat vier rechte Winkel. Zwei Seiten sind 8 cm, zwei Seiten 4 cm lang. Welche Form ist es?',
    'Rechteck',
    ['Rechteck', 'Quadrat', 'Kreis'],
    'Gegenüberliegende Seiten sind gleich lang. Weil 8 cm und 4 cm verschieden sind, ist es kein Quadrat.'
  ),
  (
    'Welche Form ist länglich und rund, ohne gerade Seiten?',
    'Oval',
    ['Oval', 'Kreis', 'Rechteck'],
    'Ein längliches Oval hat keine Ecken, ist aber nicht in jede Richtung gleich breit.'
  ),
  (
    'Welche Form sieht ungefähr aus wie der Umriss eines Eies?',
    'Oval',
    ['Oval', 'Dreieck', 'Quadrat'],
    'Ein Ei ist ein Körper. Sein länglicher runder Umriss ähnelt einem Oval.'
  ),
  (
    'Welche Form passt zu einem geschlossenen Rand, der rund und deutlich breiter als hoch ist?',
    'Oval',
    ['Oval', 'Kreis', 'Rechteck'],
    'Ein Oval kann länglich sein. Der Kreis wäre durch seinen Mittelpunkt in jede Richtung gleich breit.'
  ),
  (
    'Welche Form entsteht, wenn du einen Kreis in die Breite ziehst, ohne Ecken hineinzumachen?',
    'Oval',
    ['Kreis', 'Oval', 'Dreieck'],
    'Aus dem gleichmäßig runden Kreis wird ein längliches Oval.'
  ),
];
