# C4: gemeinsame horizontale Spaltengeometrie

Rein lesende Gegenprüfung der ae394-Ausgangsdatei (SHA256 db6a9bce9c93d680a7e0a67c3c37d64600b44e974943d9d765937bb81cc2b075) und des Fold-Tests (SHA256 1d2196fd362c11f03df9cec6fbc36a557df542ac90277cd7d13f65010938fcdd). Keine Testausführung oder Produktänderung; Root implementiert den Fix.

## Geometrie

Brett und Knöpfe benötigen denselben horizontalen Inhalt und Scrolloffset. Mit identischen Innenrändern von 12,4 dp und mindestens 360,8 dp Außenbreite ist jede logische Spalte mindestens 48 dp breit. Beide X-Zentren liegen bei 12,4 + (c + 0,5) × (W − 24,8) / 7.

Für Sockel, Abstand und Knöpfe sind 28 + 8 + 48 = 84 dp zu reservieren. Das alte feste äußere Seitenverhältnis würde bei der Mindestbreite insgesamt 393,26 dp Höhe benötigen. Im normalen 640×360-Fall stehen ohne Insets ungefähr 280 dp zur Verfügung: Ein 196 dp hohes Brett hat innere Reihen zu 28,53 dp und kreisrunde Steine mit rund 22,83 dp Durchmesser. Der alte AspectRatio-Zwang muss entfallen; auch der Sockel muss die tatsächliche Bretthöhe verwenden.

Root wählt als visuelle Untergrenze sechs Reihen zu 24 dp plus Rahmen, also 168,8 dp Brett und 252,8 dp Gesamtinhalt. Das ist eine erklärte Layoutentscheidung, keine Plattformnorm. Bei noch kleinerem Höhenbudget wird der Inhalt vertikal erreichbar gehalten. Wenn Kopf, Moduswahl, Zugtext und Begleiter bereits die gesamte Portrait-Höhe verbrauchen, genügt ein Scroller nur innerhalb eines nullhohen Spielfelds nicht; die äußere Portraitanordnung muss ebenfalls erreichbar bleiben.

Ohne Insets betragen die horizontalen Viewports bei 320 und 360 dp Breite 296 beziehungsweise 336 dp; der minimale gemeinsame Inhalt benötigt somit 64,8 beziehungsweise 24,8 dp Scrollweg. Der bestehende 3:2-Wide-Split bei 640×360 bietet 348 dp Breite und benötigt 12,8 dp Scrollweg.

## Reichweite des vorhandenen Fold-Tests

Der vorhandene Test verwendet nur 320×740 und wechselt vor seinen Layoutprüfungen auf „Zu zweit“. Er kontrolliert die sieben Renderboxen auf mindestens 48×48 dp und erreicht den letzten Knopf programmgesteuert mit ensureVisible. Ein tatsächlicher Testtap muss anschließend einen Kinderstein in Reihe 6, Spalte 7 erzeugen.

Er prüft keinen Fingerwischer, keine exponierte Clip-Schnittfläche und keine übereinstimmenden Brett-/Knopfmitten. 640×360 und große Schrift sind nicht enthalten. Die vorhandene Zugprüfung und die strengeren Zentrenprüfungen bleiben nötig.

Alle Maße sind aus den gelesenen Constraints hergeleitet. Es wurde kein neuer Test oder Geräteversuch ausgeführt.
