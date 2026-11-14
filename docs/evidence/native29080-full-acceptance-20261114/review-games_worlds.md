# Native 29080 – aktuelle Sichtprüfung durch games_worlds

Erstellt: 2026-11-14T16:35:48.959991+00:00

**Ergebnis: 15 aktuelle Originalbilder persönlich geöffnet; 15 im beschriebenen Sichtumfang akzeptiert, kein neuer blockierender Sichtbefund.** Die ausgewählte Stichprobe enthält vier Bauweltbilder, ein Siedlungsbild, neun Puzzlebilder und ein Schatzsuchebild.

Quelle: Native `29080ef8cd1a5b385eeeec97976fbefd31280427`, Tree `5ddbea2b1d5e76ed592a27c36079632d7f26cada`, [Run 43611803408](https://github.com/Ullmann27/lumo-godot/actions/runs/43611803408), Versuch 1. Die gelesenen gespeicherten Originalmetadaten weisen alle neun Jobs als erfolgreich aus.

Originalartefakt `14121618349`, **227.270.408 Bytes**, SHA-256 `f9d84c3d4f80f27fe134ab5e4cb040b811262d6d6c6a032433bc5f644ed886fc`. Root prüfte sämtliche 5.085 ZIP-CRCs. Ich verglich die 15 ausgewählten PNGs bytegenau mit ihren aktuellen ZIP-Mitgliedern, prüfte deren CRC beim Lesen und dekodierte jedes PNG vollständig. Danach öffnete ich jedes Bild einzeln. Die Dateien sind nach der Sichtprüfung unverändert.

## Grenzen und kleine Befunde

- Der einzelne Puzzlehinweis zeigt „1 Tipps“. Dies ist ein konkreter kleiner Sprachfehler, kein belegter Eingabe- oder Spielblocker.
- Die kompakten Puzzlemenüs zeigen die letzte Rückkehraktion nur teilweise am Scrollrand. Die Scrollleiste ist sichtbar. Diese Frames belegen deshalb keine vollständig exponierte 48-dp-Rückkehrfläche; die gelesene Ereignisfolge enthält keinen gesonderten Tipp auf diese Menüaktion.
- Breite Bauwelt-Werkzeug- und Materialleisten sowie kompakte Puzzlewerkzeugleisten sind horizontal scrollbar. Abgeschnittene Randteile werden ausdrücklich nicht als gleichzeitig vollständig sichtbar beschrieben.
- Es sind Desktopbilder aus Godot 4.6.3 mit X11/Compatibility/Mesa llvmpipe. Safe-Area- und Dichtewerte sind vorgegebene Plattform-Fixtures. Android, Geräteleistung und physische 60 FPS wurden in dieser Prüfung nicht gemessen.
- Keine Quelle, kein Pin, kein Receipt und kein Gitref wurde geändert; keine Tests oder Rendererläufe wurden wiederholt.

## Einzelbilder

### 1. build – 02_build_moved.png

- Archivpfad: `nextgen-evidence/nextgen/captures/build_nextgen_play_regression/02_build_moved.png`
- SHA-256: `0abe31a9da071d3a58ec841204fb9297c11a4cfae5a252c92eb13ddca086d5ca`
- Abmessungen: 1280 × 720 Pixel; 1,409,012 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Welt 1, zwei Teile, Ebene 0 und 90 Grad; eine cyan markierte Brücke und ein kleines Haus stehen in der gerenderten Inselwelt. Die Statuszeile meldet die versetzte Brücke und verweist auf Rückgängig.

**Lesbarkeit:** Titel, Werkzeugnamen, Bauziel und Testaktion sind lesbar. Die Szene zeigt räumliche Baukörper, Fluss und Schatten; die Auswahl ist sichtbar.

**Einschränkung:** Werkzeug- und Materialreihen sind horizontal scrollbar; rechts sind weitere Elemente angeschnitten. Die dunkle Statusschrift liegt unmittelbar auf dem grünen Weltbild und besitzt geringeren Kontrast als die Dialogflächen. Ein Standbild beweist weder die Bewegung noch Rückgängig.

### 2. build – build-dialog-640x360-current-goal.png

- Archivpfad: `touch-evidence/build/captures/build_dialog_density_regression/build-dialog-640x360-current-goal.png`
- SHA-256: `3cecaad0266b7aadfe894f0736e51dddd9cc5fc0ca59ac16e1c61bd61a11121a`
- Abmessungen: 640 × 360 Pixel; 129,694 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Der Dialog Aktuelles Bauziel ist auf 640 × 360 geöffnet. Er zeigt Verbinde die Inseln, die vollständige Wegaufgabe sowie Mein Bauwerk testen und Abbrechen.

**Lesbarkeit:** Die beiden Hauptaktionen und der gesamte Zieltext passen in die helle Dialogfläche und sind klar lesbar.

**Einschränkung:** Der Dialog verdeckt bestimmungsgemäß Teile der dahinterliegenden Bauwelt. Dieses Bild allein belegt keine ausgelöste Test- oder Abbrechen-Aktion.

### 3. build – build-dialog-1080x2400-templates-bottom.png

- Archivpfad: `touch-evidence/build/captures/build_dialog_density_regression/build-dialog-1080x2400-templates-bottom.png`
- SHA-256: `aa2cc71d6070dad41ece420119b669099a03a0b8578bc62bab6055d326850332`
- Abmessungen: 1080 × 2400 Pixel; 1,284,317 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Der Vorlagendialog Neue Welt / Vorlage steht auf 1080 × 2400 am unteren Scrollbereich. Brücke ist markiert; Sternenturm, Garten, drei Parzellen, Leere Insel und Abbrechen sind sichtbar.

**Lesbarkeit:** Die sichtbaren Vorlagen und der feststehende Abbrechen-Knopf sind lesbar. Die vertikale Scrollleiste kennzeichnet die Liste.

**Einschränkung:** Der obere Eintrag Starter-Haus ist durch die Scrollposition angeschnitten. Der darunterliegende Weltkopf ist teilweise verdeckt bzw. gekürzt; daraus folgt keine vollständige Freigabe jeder Hintergrundbeschriftung. Die Dialogbedienung wird separat durch den Touchbericht gestützt.

### 4. settlement – 06_settlement_relocation.png

- Archivpfad: `nextgen-evidence/nextgen/captures/build_settlement_play_regression/06_settlement_relocation.png`
- SHA-256: `6824c6062589561b0ad965dba32b186ca550a514f789f62ee1198f4f22db30cc`
- Abmessungen: 388 × 390 Pixel; 57,203 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Der Siedlungsdialog Platz für Neues? erläutert den vorübergehenden Auszug eines Bewohners, zwei verbleibende Bewohner und die Rückgabe von 4 Holz, 3 Stein und 1 Münze.

**Lesbarkeit:** Der gesamte Text einschließlich der Rückgängig-Erklärung sowie Haus behalten und Ja, umbauen passt in 388 × 390. Die Singularform 1 Münze ist sichtbar korrekt.

**Einschränkung:** Die Aufnahme zeigt einen Bestätigungsdialog, nicht den anschließenden Umbau oder die Wiederherstellung. Die beiden Aktionen wurden in dieser Sichtprüfung nicht manuell bedient.

### 5. puzzle – puzzle_rotation_640x360.png

- Archivpfad: `studio-evidence/captures/puzzle_rotation_regression/puzzle_rotation_640x360.png`
- SHA-256: `67e8ca45d30825868e9b703b5b450ea210d43eaaca9d31acb6853776cbb3b829`
- Abmessungen: 640 × 360 Pixel; 113,800 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das kompakte Drehpuzzle zeigt Mini, 1 / 6 Teile und eine hervorgehobene Zielstelle. Der Hinweis lautet, dass das angehobene Teil auf den leuchtenden Platz passt.

**Lesbarkeit:** Der Puzzlebereich, die hervorgehobene Stelle und sechs erste Werkzeugaktionen sind sichtbar. Titel, Pause und Zurück sind lesbar.

**Einschränkung:** Die Statuszeile lautet grammatisch fehlerhaft 1 Tipps. Die Werkzeugleiste ist horizontal scrollbar; Speichern und Neues Puzzle sind in diesem Ausschnitt nicht sichtbar. Das große HUD lässt im kompakten Format einen kleineren, aber sichtbaren Tischbereich.

### 6. puzzle – puzzle_rotation_placed.png

- Archivpfad: `studio-evidence/captures/puzzle_rotation_regression/puzzle_rotation_placed.png`
- SHA-256: `7a8a740af7040e19619b271fb766072dfe7be454368a1beff626f0a1f4727ab9`
- Abmessungen: 1280 × 720 Pixel; 509,560 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das Drehpuzzle auf 1280 × 720 zeigt ein korrekt abgelegtes Teil auf dem mittleren Brett, 1 / 6 Teile, 0 Tipps und Das passt! Dein Bild wächst.

**Lesbarkeit:** Bildmotiv, Puzzleform und mittleres Brett sind deutlich erkennbar. Die Aktionsleiste einschließlich Speichern und Neues Puzzle passt sichtbar in die Breite.

**Einschränkung:** Drehen ist in diesem nicht ausgewählten Zustand sichtbar deaktiviert. Weitere Teile überlappen sich in den seitlichen Ablagen; aus dem Standbild folgt kein Beleg ihrer einzelnen Auswahl.

### 7. treasure – treasure_choose_route.png

- Archivpfad: `studio-evidence/captures/treasure_exploration_regression/treasure_choose_route.png`
- SHA-256: `0df2ae372487275460ff9cd987c17e98ab4115da8a39c7f870329ded536a309d`
- Abmessungen: 1280 × 720 Pixel; 1,290,384 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Die Schatzsuche steht nach drei von sieben Hinweisen vor der Wahl Kristallwächter oder Mondgarten. Lumo ist vollständig in der Mitte sichtbar; unten wird das gefundene Brückenwappen gemeldet.

**Lesbarkeit:** Der Titel steht auf dunklem Hintergrund. Questtext, Rucksack, Springen, ANSEHEN und Fundmeldung sind lesbar. Die Fundmeldung verdeckt weder Lumo noch die sichtbaren Hauptcontrols.

**Einschränkung:** Die Zahl Entdeckungen 0 / 3 bricht im Questfeld über zwei Zeilen um. Diese Aufnahme zeigt die Wegwahl, nicht die beiden vollständigen Wege oder die finale Abgabe.

### 8. puzzle – 960x540-rotation-menu.png

- Archivpfad: `studio-evidence/captures/puzzle_menu_lifecycle_regression/960x540-rotation-menu.png`
- SHA-256: `d75d39cc24109f5692d386e0a484677086a5c5b01f30694b0ac1a8c87585a9eb`
- Abmessungen: 960 × 540 Pixel; 151,982 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das Puzzlemenü auf 960 × 540 zeigt Leuchtturm-Bucht, Mini mit sechs Teilen, Modus Drehpuzzle, Neues Puzzle beginnen und Zur Spielewelt.

**Lesbarkeit:** Der Menütitel und alle fünf Menüaktionen sind vollständig sichtbar und auf dunklen Flächen gut lesbar.

**Einschränkung:** Die Weltanweisung im Hintergrund wird vom geöffneten Menü überlagert. Die Abbildung allein beweist keinen Menüwechsel oder Rücksprung.

### 9. puzzle – 960x540-rotation-play.png

- Archivpfad: `studio-evidence/captures/puzzle_menu_lifecycle_regression/960x540-rotation-play.png`
- SHA-256: `91be337390698ba57edff371853d570d5e54cd0b29b3f2aabab89d056705c36f`
- Abmessungen: 960 × 540 Pixel; 300,994 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das gestartete Drehpuzzle auf 960 × 540 zeigt 0 / 6 Teile, 0 Tipps und Eine Vierteldrehung. Vergleiche Bild und Form.; die Schaltfläche Drehen ist hervorgehoben.

**Lesbarkeit:** Der leere zentrale Brettbereich und die seitlichen Teile sind sichtbar. Sämtliche acht unteren Aktionen passen in die Breite.

**Einschränkung:** Teile überlappen sich in den Ablagen. Die tatsächliche Vierteldrehung wird über die separate Ereignis-/Spielprüfung belegt, nicht durch dieses einzelne Bild.

### 10. puzzle – 960x540-classic-play.png

- Archivpfad: `studio-evidence/captures/puzzle_menu_lifecycle_regression/960x540-classic-play.png`
- SHA-256: `96ff13eb4370bef6964f8e428dc76f8abbaef13df60c826ba79f4624b7e0b2de`
- Abmessungen: 960 × 540 Pixel; 302,119 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das klassische Bilderpuzzle auf 960 × 540 zeigt ein abgelegtes Teil, 1 / 6 Teile, 0 Tipps und die positive Rückmeldung Das passt! Dein Bild wächst.

**Lesbarkeit:** Das mittlere Brett, das passende Bildteil und die sieben unteren Aktionen sind klar erkennbar. Eine Drehaktion ist im klassischen Modus nicht eingeblendet.

**Einschränkung:** Der Zustand belegt einen sichtbaren Teilerfolg, keine vollständige Runde. Seitliche Teile bleiben teilweise überlappt.

### 11. puzzle – 640x360-rotation-menu.png

- Archivpfad: `studio-evidence/captures/puzzle_menu_lifecycle_regression/640x360-rotation-menu.png`
- SHA-256: `7e927fa5fa6fd0e3375a4e5e3d70cd888c90920b13fdeb26c9368b43bcb66fec`
- Abmessungen: 640 × 360 Pixel; 72,841 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das Startmenü des Drehpuzzles auf 640 × 360 zeigt Leuchtturm-Bucht, Mini mit sechs Teilen und den Startknopf.

**Lesbarkeit:** Die wesentlichen Auswahlfelder und Neues Puzzle beginnen sind lesbar. Rechts ist die vertikale Scrollleiste sichtbar.

**Einschränkung:** Die untere Aktion Zur Spielewelt ist am unteren Scrollrand nur teilweise sichtbar. Das ist eine Scrollposition, kein Beleg einer vollständig exponierten 48-dp-Rückkehrfläche in genau diesem Frame. Der gelesene Puzzle-Ereignisbericht belegt Start/Pause/Fortsetzen, jedoch keinen gesonderten Tipp auf diese teilweise verdeckte Menüaktion.

### 12. puzzle – 640x360-rotation-play.png

- Archivpfad: `studio-evidence/captures/puzzle_menu_lifecycle_regression/640x360-rotation-play.png`
- SHA-256: `932f5b2023b9311eebe53405a174bccf9b5c6ab700395037bb350df498c17fb4`
- Abmessungen: 640 × 360 Pixel; 109,731 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das Drehpuzzle auf 640 × 360 zeigt 0 / 6 Teile, 0 Tipps und die Rückmeldung zur Vierteldrehung.

**Lesbarkeit:** Titel und Status sind lesbar, der zentrale Brettbereich bleibt sichtbar. Drehen und die fünf folgenden Werkzeuge sind vollständig abgebildet.

**Einschränkung:** Die Werkzeugleiste läuft horizontal weiter; spätere Aktionen sind in dieser Scrollposition nicht sichtbar. Die Szene besitzt wegen der großen Bedienflächen einen kleinen Tischbereich.

### 13. puzzle – 640x360-classic-play.png

- Archivpfad: `studio-evidence/captures/puzzle_menu_lifecycle_regression/640x360-classic-play.png`
- SHA-256: `265de3d2eecaeb019e5708c91183ff0d545187a44bf3ba37e0d66307b620f275`
- Abmessungen: 640 × 360 Pixel; 109,561 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das klassische Bilderpuzzle auf 640 × 360 zeigt ein abgelegtes Teil, 1 / 6 Teile und Das passt! Dein Bild wächst.

**Lesbarkeit:** Der Erfolgshinweis und das eingesetzte Teil sind sichtbar. Die Werkzeugleiste bis Speichern ist lesbar.

**Einschränkung:** Die folgende Aktion am rechten Rand ist angeschnitten und über die horizontale Scrollleiste erreichbar gedacht; dieses Bild beweist deren Bedienung nicht. Der Puzzlebereich ist im kompakten Format klein.

### 14. build – build-landscape-cutout.png

- Archivpfad: `studio-evidence/captures/mobile_safe_area_regression/build-landscape-cutout.png`
- SHA-256: `04c77e2634b3f35924c623c26f5b540c1dce3f724f65f39bd75cae826393f2d5`
- Abmessungen: 2400 × 1080 Pixel; 2,497,261 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Die Bauwelt im Landscape-Cutout-Profil zeigt Welt 1 mit 197 Teilen, Ebene 0 und 0 Grad; Inseln, Burg, Brücke und weitere Baukörper sind gerendert.

**Lesbarkeit:** Zurück, Titel, Pause, Mit Lumo laufen sowie die ersten Werkzeuge stehen deutlich innerhalb des linken Sicherheitsabstands. Die großen Beschriftungen sind lesbar.

**Einschränkung:** Die langen Werkzeug- und Materialreihen werden am rechten Rand abgeschnitten und horizontal gescrollt. Die hohe Dichte führt zu großen HUD-Flächen; der Welttext liegt direkt über dem Landschaftsbild. Die Randwerte sind eine Desktop-Fixture, keine Messung an einem realen Androidgerät.

### 15. puzzle – puzzle-landscape-cutout.png

- Archivpfad: `studio-evidence/captures/mobile_safe_area_regression/puzzle-landscape-cutout.png`
- SHA-256: `6622d8c3ab667f13e83b827f560168b254e768beb0b280f076a3d31c5323d719`
- Abmessungen: 2400 × 1080 Pixel; 479,283 Bytes.
- Persönlich geöffnet: **ja**. Im beschriebenen Sichtumfang akzeptiert: **ja**. Blockierender Befund: **nein**.

**Beobachteter Zustand:** Das Puzzlemenü im Landscape-Cutout-Profil zeigt Leuchtturm-Bucht, Leicht mit zwölf Teilen, Bilderpuzzle und Neues Puzzle beginnen.

**Lesbarkeit:** Die Hauptfelder und der Startknopf sind kontrastreich und lesbar. Zurück und Pause bleiben außerhalb des mittleren Menüs sichtbar.

**Einschränkung:** Zur Spielewelt ist am unteren Scrollrand teilweise angeschnitten. Titel und Weltanweisung werden vom geöffneten Menü überlagert. Die gesonderte Safe-Area-Prüfung misst für Puzzle Zurück und Pause, nicht sämtliche Menüaktionen.

## Separat: gelesene Gameplay- und Touchbelege

Die folgenden Angaben stammen aus den aktuellen Originalprotokollen und Sidecars desselben ZIPs. Sie sind keine aus Standbildern abgeleiteten Bedienbehauptungen und keine von mir neu gestarteten Tests. Vollständige Pfade, SHA-256-Werte, Ergebniszeilen und relevante Messdaten stehen in `gameplay-touch-review-games_worlds.json`.

| Bereich | Headless-Checks | Renderer-Checks | Tatsächlich berichteter Umfang |
|---|---:|---:|---|
| Bauwelt Nextgen | 62 | 70 | Touch, Verschieben/Drehen, Historie, Speichern, Lumo-Laufen/Springen/Kollision, Pause/Layout |
| Siedlung | 127 | 139 | Routen, Bauplatztouch, bezahltes Bauen, sichtbare KI, Save-Isolation, Pause/Layout |
| Bauwelt-Dialoge | 2.016 | 2.046 | Dialoggrenzen, erhaltene Auswahl, echtes Scrollen/Auswählen/Abbrechen, ≥48 dp, Restore |
| Puzzle-Drehung | 4.558 | 4.565 | Orientierung, alte Saves, tatsächliches Picking, Touchdrehung, Wiederaufnahme |
| Puzzle-Menü/Lifecycle | 720 | 732 | Menüwechsel, Start, Teilwahl/Drehung, klassisches Ziehen, Pause und Fortsetzen |
| Gemeinsame Safe Area | 112 | 124 | Plattformgrenze mit Dichte-/Inset-Fixture; ausgewählte Controls |

Diese Zahlen werden nicht zu einer vermeintlichen Anzahl unabhängiger Tests oder realer Benutzereingaben zusammengezählt.

**Bauwelt:** Der Dialogbericht enthält 285 Messungen für fünf Formate und zwölf Captureeinträge. Davon verlangen 175 Messungen vollständig exponierte Ziele; 110 prüfen erhaltene Auswahlmöglichkeiten ohne diese Forderung. Die kleinsten berichteten Breiten und Höhen liegen je Profil bei mindestens 48 dp. Für die beiden tatsächlich angesehenen Dialogzustände sind insbesondere die echte Zieltestaktion, die letzte Auswahl nach vertikalem Drag und der feststehende Abbrechen-Knopf gebunden. Die Rohprotokolle enden ohne Assertionsfehler.

**Puzzle:** Der Renderer-Sidecar nennt 732 Checks, null Fehler und ausdrücklich keine Zustands-/Teilpositionsinjektion. Er enthält 62 Touch-Drücken, 62 Loslassen und 16 Dragereignisse sowie 42 Menüstichproben für 6/12/24/48/96 Teile, fünf Motive und beide Moduswerte. Vier Starts, zwei echte Teilwahlen, zwei Drehtipps, zwei klassische Picks mit Drag, vier Pausen und zwei Fortsetzungen sind im Journal erfasst. Daraus wird keine Prüfung des nicht protokollierten Menü-Rückkehrtipps konstruiert.

**Safe Area:** Der Bericht bindet eine Oberfläche von 2.400 × 1.080, Dichte 2,625 und die Fixture `[136, 63, 0, 63]`. Für diese beiden Module misst er Bauwelt-Zurück/Pause/Verschieben und Puzzle-Zurück/Pause. Die fünf exponierten Ziele erreichen jeweils mindestens 48 dp und liegen laut Messbericht im sicheren Rechteck. Das ist keine pauschale Messung sämtlicher Menüaktionen und kein Androidgerätenachweis.

**Unveränderte Warnungen:** Die zwölf gelesenen Protokolle enthalten im Rendererpfad die Hinweise zur nicht umstellbaren V-Sync-Einstellung sowie zu nicht unterstütztem Screen-Space-AA und Volumetric Fog unter Compatibility. Keine `ERROR:`- oder `SCRIPT ERROR:`-Zeile wurde in diesen zwölf ausgewählten Logs gefunden. Andere Archivlogs wurden hiermit nicht pauschal freigegeben.
