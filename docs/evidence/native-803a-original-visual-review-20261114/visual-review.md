# Sichtprüfung der 17 neuen Native-Originalbilder – Host 803a

## Ergebnis

Alle **17 unveränderten Original-PNGs** wurden tatsächlich geöffnet und visuell geprüft. Für sämtliche Dateien stimmen **SHA256, Dateigröße und Bildmaße** mit dem mitgelieferten `studio-2020-images.json` überein. In diesen Standbildern wurde keine zusätzliche sichtbare Funktionsblockade gefunden. Zwei konkrete Lesbarkeitsdetails bleiben bei der Schatzsuche bestehen.

1. In `treasure-title-portrait.png` erscheint der Spielname gekürzt als **LUMOS STER…**. Der vollständige Titel ist dort nicht sichtbar; Spiele, Rucksack und Pause bleiben lesbar.
2. In `treasure-title-landscape.png`, `treasure-title-fold.png` und `treasure-title-portrait.png` steht beim Entdeckungszähler **0 /** am Zeilenende und **3** allein in der folgenden Zeile. Die Zahl ist sichtbar, der zusammengehörige Zähler jedoch unglücklich getrennt.

Diese Befunde sind keine nachgewiesenen Eingabeblockaden. Die vollständige Beurteilung steht in `visual-review.json`, einschließlich der genauen Datei- und Hashbindung für jeden Befund.

## Herkunft und Grenzen

Geprüfter Flutter-Host: `803a4e960ffb804a46b6d09417731c031f00f680`; Native-Quelle: `0e26153f0e58cc05739e72923b4c563a4cf380b8`, Tree `5b5992487e60ae805d708965f1500954c6b0556d`. Quelle ist [Run 43578509499, Versuch 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499/attempts/1), [Buildjob 132399130204](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499/job/132399130204), Artefakt `lumo-candidate-pinned-native-gameplay`, ID **14109232711**.

Das vom Learning/UX-Lead gegen die GitHub-API bestätigte Archiv hat 175744828 Bytes und SHA256 `286d623267d1eb59de9ed5933e3308a29a5868c8beff1323b037e64f2ed357f9`. Der Review prüfte selbst die 17 extrahierten PNGs gegen das Manifest mit SHA256 `b4b616916d36086fe106842457dfd20368ce6f9b3ed07c30c7eac96167ba81aa`. Die Originalbytes wurden nicht bearbeitet; kein neuer Renderer, Test, Build oder Refwechsel wurde ausgelöst.

Der Native-CI-Schritt 31 war laut übergebener Jobinformation abgeschlossen/erfolgreich (09:22:30–10:06:29 UTC); der vollständige APK-Job lief bei Artefaktübergabe noch. Die getrennte Wiederprüfung der 52-Modus- und 17-Raster-Gates liegt beim Learning/UX-Lead und wird durch diese Sichtprüfung nicht ersetzt.

**Beobachtungsgrenze:** Standbilder belegen weder eine erfolgreiche Berührung auf einem Android-Gerät noch dp-Abmessungen, reale Safe-Area-Inset-Werte, FPS, hörbare Sprache oder zeitliche Mund-Audio-Synchronität. ≥48-dp-Ziele müssen durch die separat verifizierten Fixture-/Sidecar-Daten belegt werden. Der Film wurde hier nicht abgespielt. Host 803a und sein Native-Pin bleiben unverändert; der separat geprüfte C4-Return-Fix f0c19 gehört nicht zu diesen Aufnahmen.

## Schatzsuche: fünf Ansichten

### treasure-title-compact.png

Pfad im Native-Ausgabeordner: `captures/treasure_title_contrast_regression/treasure-title-compact.png` · 640×320 Pixel · 323987 Bytes.

SHA256: `c5a00d642424f9f06bc24419bf1778e599eba243094429d8a1bbd86deb51362a`.

Der volle Titel, Spiele, Rucksack, Pause, Hinweis, Springen und Ansehen sind sichtbar und voneinander getrennt. Der Hinweis-Knopf ersetzt das dauerhafte Hinweisfeld; der einzeilige Hinweisbalken oberhalb des Avatars schneidet dessen Silhouette nicht sichtbar. Der Avatar und beide unteren Steuerelemente bleiben innerhalb des Bildes.

### treasure-title-fold.png

Pfad im Native-Ausgabeordner: `captures/treasure_title_contrast_regression/treasure-title-fold.png` · 2176×1812 Pixel · 4225366 Bytes.

SHA256: `b1a0d1b406169acc502af8ab049b2b0053cb18a0d93abab6d75a7e132061cc76`.

Voller Titel, vollständiger Aufgabenhinweis und unterer Hinweisbalken sind lesbar. Avatar und Steuerelemente sind sichtbar; zwischen unterem Hinweisbalken, Joystick und Ansehen-Fläche ist Abstand vorhanden.

**Lesbarkeitsbefund:** Der Zähler Entdeckungen 0 / 3 bricht vor der 3 um; die letzte Zahl bleibt vollständig sichtbar.

### treasure-title-landscape-cutout.png

Pfad im Native-Ausgabeordner: `captures/treasure_title_contrast_regression/treasure-title-landscape-cutout.png` · 2400×1080 Pixel · 2622435 Bytes.

SHA256: `c4b4b4ea47fa4a0499c4ddc889826c45c7a4c1b5e9aed0cce0fe54a9b9b34da5`.

Voller Titel, separater Hinweis-Knopf und oberer Hinweisbalken sind sichtbar. Der Avatar bleibt unterhalb der HUD-Zeilen vollständig sichtbar; linke und rechte Steuerflächen sind klar getrennt. Die Darstellung ist gegenüber dem Bildrand eingerückt; reale Geräte-Inset-Werte lassen sich daraus allein nicht bestätigen.

### treasure-title-landscape.png

Pfad im Native-Ausgabeordner: `captures/treasure_title_contrast_regression/treasure-title-landscape.png` · 1920×1080 Pixel · 2718159 Bytes.

SHA256: `dcab2aece457e63187ab94e10740b53fdbb34e1c3bde2b2f9675ddd77d418996`.

Voller Titel, vollständiger Aufgabenhinweis, unterer Hinweisbalken, Avatar und Steuerflächen sind sichtbar. Keine sichtbare Überdeckung des Avatars durch die HUD-Flächen und kein abgeschnittener Hinweistext.

**Lesbarkeitsbefund:** Der Zähler Entdeckungen 0 / 3 bricht vor der 3 um; die Zahl bleibt lesbar, ist aber optisch vom Bruch getrennt.

### treasure-title-portrait.png

Pfad im Native-Ausgabeordner: `captures/treasure_title_contrast_regression/treasure-title-portrait.png` · 1080×2400 Pixel · 2101554 Bytes.

SHA256: `353e88d8274e58ad740cfdcbc1dc15c396c435b768aac28f4e4b0f7d678e0ae8`.

Avatar, Aufgabenhinweis, zweizeiliger unterer Hinweisbalken und untere Steuerflächen sind sichtbar und getrennt. Die Kopfzeile zeigt den Titel gekürzt; Spiele, Rucksack und Pause bleiben vollständig sichtbar.

**Lesbarkeitsbefund:** Der Titel erscheint als LUMOS STER…; der vollständige Spielname ist in dieser Aufnahme nicht sichtbar. Der Zähler Entdeckungen 0 / 3 bricht vor der 3 um; kein Text wird abgeschnitten.

## Vier gewinnt: vier Zustände

### c4-empty-landscape.png

Pfad im Native-Ausgabeordner: `captures/connect_four_visual_capture/c4-empty-landscape.png` · 960×540 Pixel · 82028 Bytes.

SHA256: `05368af4f64863cacfdcd9ce1889e3df8b083f9dc8aa5f0d3fdff91a197846d4`.

Leeres Raster mit sieben Spalten und sechs Reihen sichtbar; alle sieben nummerierten Spaltenknöpfe, Zurück und Pause vollständig lesbar. Status Gespeichert · Cyan ist dran sichtbar. Lumo steht rechts neben dem Brett ohne sichtbare Überlagerung der Steuerleiste.

### c4-paused-small.png

Pfad im Native-Ausgabeordner: `captures/connect_four_visual_capture/c4-paused-small.png` · 640×360 Pixel · 29411 Bytes.

SHA256: `502a673e160d5a9f3f95883ddf1e259f568819de67731340681d2666d7282195`.

Spiel pausiert. Deine Runde bleibt gespeichert. sowie Fortsetzen und Neue Runde vollständig sichtbar. Pausenfeld hat eine sichtbare vertikale Bildlaufleiste. Der Screenshot belegt keine außerhalb des sichtbaren Ausschnitts liegenden Menüaktionen. Sieben Spaltenknöpfe und Pause gedimmt; Status Gold ist dran lesbar. Kein Avatar, entsprechend dem Capture-Fall. Das Brett liegt hinter dem Pausenfeld.

### c4-playing-phone.png

Pfad im Native-Ausgabeordner: `captures/connect_four_visual_capture/c4-playing-phone.png` · 412×915 Pixel · 67672 Bytes.

SHA256: `332d15a61e7eb1e93cbc49f9fedaa7b1e67f985b1d0fd9f97334a093678fbe6c`.

Brett mit sieben Spalten und sechs Reihen vollständig sichtbar; zwei Steine in der mittleren Spalte, gelb über cyan. Alle sieben Spaltenknöpfe, Zurück, Pause und Gespeichert · Cyan ist dran lesbar. Kein Avatar eingeblendet, entsprechend dem vorbereiteten Capture-Fall. Größere freie Bereiche ober- und unterhalb des Bretts, ohne sichtbare Bedienblockade.

### c4-win-landscape.png

Pfad im Native-Ausgabeordner: `captures/connect_four_visual_capture/c4-win-landscape.png` · 960×540 Pixel · 83992 Bytes.

SHA256: `b36497e14dd06e06b070d6b83bddf2114bccc916ff278fe9f11af2a03a748b41`.

Vier cyanfarbene Steine in der unteren Reihe mit vier hellen Gewinnringen und drei gelbe Steine sichtbar. Cyan gewinnt!, Menü und Zurück lesbar; sieben Spaltenknöpfe sichtbar gedimmt. Lumo rechts neben dem Brett sichtbar; keine Überlagerung des Gewinnstatus.

## Lumo und Lernszene: acht Aufnahmen

### audio_jaw.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/audio_jaw.png` · 640×640 Pixel · 306464 Bytes.

SHA256: `9b015897147a7301434c915601be8a90cb3f67b40ba9ad500d641d496b6fd2c9`.

Frontalansicht mit offenen Augen, sichtbaren Ohren und vollständigem Gesicht. Beschriftung Original-Lumo · Apfel – lokale WAV sichtbar. Ein einzelnes Standbild belegt weder hörbare Wiedergabe noch zeitliche Mund-Audio-Synchronität.

### blink.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/blink.png` · 640×640 Pixel · 301312 Bytes.

SHA256: `dab68e04c832a6b7b15a6f62d0b6ca146df035683c5de64c10387302b32aa973`.

Beide Lider deutlich geschlossen; der Zustand ist visuell von der Aufnahme mit offenen Augen unterscheidbar. Gesicht, Ohren und Brille ohne sichtbaren Randbeschnitt.

### blink_intermediate.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/blink_intermediate.png` · 640×640 Pixel · 302531 Bytes.

SHA256: `b2ff356a282b59ed961e80f16b8e8fd7007bf32266232022338e2cb221ab9554`.

Beide Lider teilweise geschlossen, sichtbare Augenöffnung zwischen offenem und geschlossenem Zustand. Gesicht ohne sichtbaren Randbeschnitt; keine zusätzliche Bedienoberfläche in dieser Nahaufnahme.

### gaze_left.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/gaze_left.png` · 640×640 Pixel · 295200 Bytes.

SHA256: `cfa79ca698ac1ed501f8f109eae56e5858f0a5ea2c93c3b64aa4f5b6686a6163`.

Kopf/Blick nach links gegenüber der Frontalansicht verändert; beide Augen und Ohren bleiben sichtbar. Beschriftung Original-Lumo · stumm lesbar. Das Bild belegt keine tatsächliche Stummschaltung eines Audiogeräts.

### muted.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/muted.png` · 640×640 Pixel · 303002 Bytes.

SHA256: `b9ca19a0418fdf2b9ad46886bbfa99651236f517df477c6b181e53880c97e2a1`.

Frontalansicht mit offenen Augen und nahezu geschlossenem Mund; Gesicht und Ohren innerhalb des Bildes. Beschriftung Original-Lumo · stumm sichtbar; tatsächliche Lautstärke oder Tonfreiheit wurde nicht geprüft.

### neutral.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/neutral.png` · 640×640 Pixel · 283007 Bytes.

SHA256: `9094791de91814b8f12ab3ce06f92c6111d0d162c37d4ea3448b80fde6367703`.

Nahaufnahme mit offenen Augen, sichtbaren Ohren, Brille und nahezu geschlossenem Mund. Gesicht innerhalb des Bildes; der untere Körper ist als Teil der Nahaufnahme außerhalb des Bildausschnitts. Beschriftung Original-Lumo · Pause / geschlossen sichtbar.

### stopped.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/stopped.png` · 640×640 Pixel · 299811 Bytes.

SHA256: `d415d7d2401164e3661508c04a73c1b5a2f65812b4f9fe4a655d35aab8129b52`.

Seitlich orientierter Kopf mit offenen Augen, vollständigem Gesicht und sichtbaren Ohren. Beschriftung Original-Lumo · Pause / geschlossen sichtbar; kein Nachweis des zeitlichen Stop-Verhaltens allein durch dieses Standbild.

### teacher_scene.png

Pfad im Native-Ausgabeordner: `captures/lumo_facial_capture/teacher_scene.png` · 640×640 Pixel · 113407 Bytes.

SHA256: `bd9aefcd0216b9504d252ea09e78fbba6261144e1ee4d4509098e8c0823d0c55`.

Wörter bauen · Apfel, die nächste Silbe Ap, die beweglichen Silben fel/Ap und die drei unteren Aktionsknöpfe sind lesbar. Lumo steht links neben der Tafel; sichtbare Figur und Bedienelemente überdecken sich nicht. Kein fehlendes Text-Glyph oder abgeschnittener Haupttext in diesem Originalbild sichtbar.

Review abgeschlossen: **2026-11-14 10:11:33 UTC**. Prüfer: `/root/lumo_release_lead/learning_ux_lead/touch_worker`.

