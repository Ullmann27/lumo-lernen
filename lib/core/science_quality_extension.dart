import 'science_task_data.dart';

/// Additional topic-specific, answer-reviewed Austrian primary-school questions.
/// Earlier-grade revision alone must not stand in for third/fourth-grade content.
const List<ScienceQuestion> scienceQualityExtensionQuestions = [
  // Grade 3: weather and observation
  ScienceQuestion.item(3, 'Wetter', 'Womit misst man die Niederschlagsmenge?', 'mit einem Regenmesser', ['mit einer Uhr', 'mit einem Kompass', 'mit einem Lineal'], 'Ein Regenmesser sammelt Regen. Die Menge wird üblicherweise in Millimetern angegeben.'),
  ScienceQuestion.item(3, 'Wetter', 'Ein Thermometer zeigt morgens 7 Grad und mittags 14 Grad. Wie groß ist der Unterschied?', '7 Grad', ['14 Grad', '21 Grad', '3 Grad'], '14 minus 7 ergibt einen Temperaturunterschied von 7 Grad.'),
  ScienceQuestion.item(3, 'Wetter', 'Wofür steht ein Pfeil auf einer Wetterkarte meist?', 'für die Windrichtung', ['für die Uhrzeit', 'für das Datum', 'für die Einwohnerzahl'], 'Wetterkarten können die Windrichtung mit Pfeilen darstellen.'),
  ScienceQuestion.item(3, 'Wetter', 'Warum soll man bei Gewitter Schutz in einem Gebäude suchen?', 'weil Blitze gefährlich sind', ['weil Regen immer giftig ist', 'weil Wolken herunterfallen', 'weil Wind die Sonne löscht'], 'Bei Gewitter sind Gebäude ein besserer Schutz als offene Flächen oder einzelne Bäume.'),

  // Grade 3: safe mobility
  ScienceQuestion.item(3, 'Verkehr', 'Ein parkendes Auto verdeckt die Sicht auf die Straße. Was ist sicher?', 'an einer übersichtlichen Stelle queren', ['direkt davor auf die Fahrbahn laufen', 'zwischen Autos rennen', 'mit geschlossenen Augen gehen'], 'Überquere Straßen nur dort, wo du Fahrzeuge frühzeitig sehen kannst.'),
  ScienceQuestion.item(3, 'Verkehr', 'Warum hält man besonders Abstand zu abbiegenden Lastwagen?', 'weil man im toten Winkel übersehen werden kann', ['weil Lastwagen keine Räder haben', 'weil Ampeln dort fehlen', 'weil Reifen immer platzen'], 'Große Fahrzeuge haben Bereiche, die der Fahrer schwer einsehen kann.'),
  ScienceQuestion.item(3, 'Verkehr', 'Du willst mit dem Fahrrad links abbiegen. Was musst du beachten?', 'rechtzeitig schauen und sicher einordnen', ['einfach ohne Schauen abbiegen', 'die Augen schließen', 'auf dem Gehsteig schneller werden'], 'Linksabbiegen erfordert besonders sorgfältigen Schulterblick und die Beachtung der Verkehrsregeln.'),
  ScienceQuestion.item(3, 'Verkehr', 'Was hilft bei Regen, damit andere dich im Straßenverkehr besser sehen?', 'Reflektoren und gut sichtbare Kleidung', ['nur dunkle Kleidung', 'ohne Licht fahren', 'überall schneller laufen'], 'Reflektierende Elemente und passende Beleuchtung verbessern die Sichtbarkeit.'),

  // Grade 3: time and calendar
  ScienceQuestion.item(3, 'Zeit und Kalender', 'Wie viele Minuten ergeben eine Dreiviertelstunde?', '45 Minuten', ['15 Minuten', '30 Minuten', '75 Minuten'], 'Eine Stunde hat 60 Minuten, drei Viertel davon sind 45 Minuten.'),
  ScienceQuestion.item(3, 'Zeit und Kalender', 'Ein Kalenderjahr beginnt mit welchem Monat?', 'Jänner', ['Februar', 'Dezember', 'April'], 'Im österreichischen Kalender beginnt das Jahr mit dem Jänner.'),
  ScienceQuestion.item(3, 'Zeit und Kalender', 'Wie viele Tage hat der Februar in einem Schaltjahr?', '29', ['27', '28', '30'], 'In einem Schaltjahr hat der Februar 29 statt 28 Tage.'),
  ScienceQuestion.item(3, 'Zeit und Kalender', 'Wie viele Wochen sind genau 21 Tage?', '3 Wochen', ['2 Wochen', '4 Wochen', '7 Wochen'], 'Eine Woche dauert sieben Tage. 21 geteilt durch 7 ist 3.'),
  ScienceQuestion.item(3, 'Zeit und Kalender', 'Die Schulstunde beginnt um 9:00 und dauert 50 Minuten. Wann endet sie?', '9:50 Uhr', ['9:15 Uhr', '10:50 Uhr', '8:50 Uhr'], '50 Minuten nach neun ist es 9:50 Uhr.'),

  // Grade 3: living together
  ScienceQuestion.item(3, 'Familie und Gemeinschaft', 'Eine Klasse möchte über das nächste Ausflugsziel entscheiden. Wie geht das fair?', 'Vorschläge sammeln und abstimmen', ['nur das lauteste Kind entscheiden lassen', 'niemanden fragen', 'die Vorschläge verstecken'], 'Beim Abstimmen können alle ihre Stimme abgeben.'),
  ScienceQuestion.item(3, 'Familie und Gemeinschaft', 'Was bedeutet es, eine gemeinsame Regel zu vereinbaren?', 'alle kennen und beachten sie', ['nur einer darf die Regel kennen', 'die Regel gilt nie', 'Regeln werden heimlich geändert'], 'Gemeinsame Regeln helfen beim fairen Zusammenleben.'),
  ScienceQuestion.item(3, 'Familie und Gemeinschaft', 'Ein Kind versteht die Spielregeln noch nicht. Was hilft?', 'ruhig erklären und gemeinsam probieren', ['das Kind auslachen', 'einfach ohne es weiterspielen', 'alle Regeln absichtlich ändern'], 'Geduld und Erklären ermöglichen allen das Mitmachen.'),
  ScienceQuestion.item(3, 'Familie und Gemeinschaft', 'Zwei Kinder sind unterschiedlicher Meinung. Welcher Weg hilft?', 'zuhören und eine Lösung suchen', ['einander anschreien', 'den Streit weitergeben', 'Sachen kaputtmachen'], 'Zuhören und Kompromisse finden kann Konflikte lösen.'),
  ScienceQuestion.item(3, 'Familie und Gemeinschaft', 'Warum teilen wir Aufgaben bei einem Gruppenprojekt auf?', 'damit alle sinnvoll mitarbeiten können', ['damit niemand helfen darf', 'damit ein Kind alle Arbeit hat', 'damit nichts fertig wird'], 'Aufgabenteilung nutzt die Stärken aller Gruppenmitglieder.'),

  // Grade 3: work and society
  ScienceQuestion.item(3, 'Berufe', 'Wer plant, wie ein Haus sicher gebaut werden kann?', 'eine Bauingenieurin oder ein Bauingenieur', ['eine Sängerin', 'ein Koch', 'ein Buchhändler'], 'Bauingenieurinnen und Bauingenieure berechnen und planen Bauwerke.'),
  ScienceQuestion.item(3, 'Berufe', 'Wer repariert häufig kaputte Wasserleitungen?', 'eine Installateurin oder ein Installateur', ['eine Musikerin', 'ein Pilot', 'eine Floristin'], 'Installationsfachkräfte arbeiten an Wasser- und Heizungsanlagen.'),
  ScienceQuestion.item(3, 'Berufe', 'Was ist eine typische Aufgabe einer Tischlerin?', 'Holzmöbel herstellen und reparieren', ['Zähne behandeln', 'Flugzeuge steuern', 'Wetter vorhersagen'], 'Tischlerinnen und Tischler bearbeiten Holz und bauen beispielsweise Möbel.'),
  ScienceQuestion.item(3, 'Berufe', 'Was braucht ein Mensch, der Lebensmittel verkauft, besonders?', 'sauberes Arbeiten und Hygiene', ['ungewaschene Hände', 'offene Lebensmittel am Boden', 'verdorbene Ware'], 'Hygiene schützt Kunden vor Krankheitserregern.'),
  ScienceQuestion.item(3, 'Berufe', 'Wofür ist die Müllabfuhr in einer Gemeinde wichtig?', 'sie sammelt und transportiert Abfälle', ['sie malt Verkehrszeichen', 'sie ersetzt die Feuerwehr', 'sie verteilt Schulnoten'], 'Die Müllabfuhr trägt zur Sauberkeit und Abfallentsorgung bei.'),

  // Grade 3: plants
  ScienceQuestion.item(3, 'Pflanzen', 'Warum brauchen grüne Pflanzen Sonnenlicht?', 'sie nutzen Licht, um Nährstoffe herzustellen', ['damit die Erde leuchtet', 'damit die Wurzeln laufen', 'damit Wasser verschwindet'], 'Bei der Fotosynthese nutzen grüne Pflanzen Licht, Wasser und Kohlendioxid, um Zucker aufzubauen.'),
  ScienceQuestion.item(3, 'Pflanzen', 'Was kann einem Samen helfen zu keimen?', 'Wasser und eine passende Temperatur', ['nur ein Stein', 'nur trockene Luft', 'völlig gefrorener Boden'], 'Viele Samen keimen bei genügend Wasser, Sauerstoff und geeigneter Wärme.'),

  // Grade 4: interpret data, not memorized fixed prompts
  ScienceQuestion.item(4, 'Diagramme lesen', 'Ein Diagramm zeigt 8 Regentage im April und 5 im Mai. Wie viele mehr hat April?', '3 Regentage', ['5 Regentage', '8 Regentage', '13 Regentage'], '8 minus 5 ergibt 3 Regentage Unterschied.'),
  ScienceQuestion.item(4, 'Diagramme lesen', 'Im Balkendiagramm haben drei Klassen 12, 15 und 10 Bücher gelesen. Welche Klasse las am meisten?', 'die Klasse mit 15 Büchern', ['die Klasse mit 10 Büchern', 'die Klasse mit 12 Büchern', 'alle gleich viel'], 'Vergleiche die drei Balkenhöhen. 15 ist die größte Anzahl.'),
  ScienceQuestion.item(4, 'Diagramme lesen', 'Im Diagramm stehen 6 Radfahrende und 9 zu Fuß Gehende. Wie viele sind es zusammen?', '15 Kinder', ['3 Kinder', '9 Kinder', '54 Kinder'], 'Die Gruppen umfassen zusammen 6 plus 9 gleich 15 Kinder.'),
  ScienceQuestion.item(4, 'Diagramme lesen', 'In einer Tabelle stehen 20 Besucher am Montag und 25 am Dienstag. Um wie viele stieg die Zahl?', 'um 5', ['um 20', 'um 25', 'um 45'], '25 minus 20 ergibt eine Zunahme um 5 Personen.'),
];
