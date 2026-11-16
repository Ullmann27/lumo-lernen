# Unabhängige Medienprüfung – Zusatzlauf 2032

Run `43853317375`, Job `133251156609`, QA `ce8458e88d16e7c3b97fafcf34c4d29b0c1d9fdc`.
APK-Quelle `9b38360ca5f21919dce4a2b99e605ee39bbbf454`; Native `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`.

## Ergebnis

Alle 28 vom Ergebnis referenzierten Original-PNGs und alle 12 MP4s stimmen in SHA-256 und den angegebenen Größen mit dem Resultat und Roots Artefaktmanifest überein. Zusätzlich wurde das gesichtete Panelbild 0348 an das Manifest gebunden. Alle zwölf Videos wurden einzeln und nacheinander mit `ffprobe -count_frames` bis EOF gelesen: Exit 0, keine Fehlerausgabe, jeweils mehr als ein Videoframe und positive Dauer. Insgesamt wurden 688 Frames gezählt; die Summe der Clipdauern beträgt 444.990899 Sekunden.

**Keine der zwölf Aufnahmen enthält eine Tonspur.** Akustische Aussprache, tatsächlicher Verlangsamungsfaktor und hörbarer Stopp sind damit nicht aus diesen Videos nachgewiesen.

## Tatsächlich angesehene Originalbilder

### Fehlantwort — `0163-numeric-wrong-after-assessment.png`

Die Zehnerbrücke zeigt die lesbare Aufgabe 9 + 7, Eingabe 15 und die Rückmeldung: Deine Zahl liegt um eins daneben. Die weiteren Erläuterungen und Antwort prüfen sind sichtbar. Der gezeichnete Fuchs sitzt links neben der Lernbeschreibung.

**Grenze:** Das Standbild zeigt den sichtbaren Fehlhinweis; die gespeicherte fachliche Bewertung prüft Learning separat.

### Korrektur — `0177-numeric-corrected-after-assessment.png`

Eingabe 16, ausgegrautes Antwort prüfen, aktive Neue Aufgabe und Richtig! Diese Antwort war mit Hilfe. sind klar sichtbar.

**Grenze:** Der obere Bildbereich ist gleichmäßig dunkelblau; Aufgabenüberschrift und Figur sind in diesem Nachbild nicht sichtbar. Die Zuordnung zu 9 + 7 folgt nicht allein aus diesem Bild. Keine Ursache für den oberen Bildbereich behauptet.

### Vorbereitung des aktiven Wechsels — `0223-switch-joint-viewport-before-replay.png`

Ba, na, ne, die gelegte Silbenreihe, Jetzt selbstständig antworten und Noch einmal sind gleichzeitig lesbar. Der geöffnete Ausschnitt ist nach unten gescrollt; der Worttitel Banane ist oben angeschnitten.

**Grenze:** Dies ist das Bild vor der Wiederholung, kein alleiniger Nachweis einer zu diesem Zeitpunkt aktiven Silbe. Die gemeinsame Ansicht entstand bei der ausdrücklich dokumentierten temporären Emulator-Testdichte 320; kein Beleg für diese Sichtbarkeit bei Standarddichte.

### Neue Aufgabe — `0249-switch-new-unanswered-rakete.png`

Die Wortwerkstatt zeigt Freier Abruf und Schreibe das Namenwort: Ra – ke – te. Das Antwortfeld ist leer und zeigt 0/80. Figur, Aufgabe und Coachbuttons sind gut lesbar; der vorherige Banane-Bau ist nicht sichtbar.

**Grenze:** Der exakte aktive Wechselzeitpunkt, die alte Audioinvalidierung und die Sessionbindung sind aus diesem Nachbild allein nicht messbar.

### Native Banane vorher — `0342-runtime-banana-before-slower.png`

Wörter bauen · Banane, die Anweisung für Ba, drei leere Zielplätze und 0 / 3 bewegt sind sichtbar. Der Fuchs steht links oberhalb der Tafel und verdeckt keine wesentliche Aufgabenbeschriftung.

**Grenze:** Eine einzelne Pose belegt weder den Animationsverlauf noch eine Audio-Mund-Synchronisation.

### Native Aktion Langsamer — `0348-runtime-banana-slower-panel.png`

Das geöffnete und gescrollte Fragepanel zeigt Fragefeld, Sprechen, Frage senden, Stopp sowie die klar getrennten Aktionen Noch einmal, Langsamer und Ein Hinweis. Hinter dem abgedunkelten Panel bleibt die Banane-Szene erkennbar.

**Grenze:** Der Panelkopf liegt durch den Scrollstand außerhalb dieses Ausschnitts. Dieses Bild belegt das sichtbare Langsamer-Control, aber weder seinen Tap noch die tatsächliche akustische Geschwindigkeit.

### Native Banane danach — `0389-runtime-banana-after-slower.png`

Die Erklärung benennt Ba – na – ne und Sprechstücke statt Buchstaben. Drei leere Zielplätze und 0 / 3 bewegt sind weiterhin sichtbar; der Audiofooter zeigt Schritt anhören. Der Fuchs steht links oberhalb der Tafel mit einer gehobenen Pfote.

**Grenze:** Vorher-/Nachherpose und Untertitel sind sichtbar; aus den Bildern folgt keine präzise zeitliche Kopplung von Mund, Pfote und Ton. Keine akustische Messung der Verlangsamung.

### Muster vor fachlicher Abgabe — `0488-pattern-before-explicit-core-answer.png`

Wähle die richtige Antwort: und alle vier großen Karten Quadrat, Dreieck, Stern, Kreis sind vollständig sichtbar. Der Kopf zeigt 0 Sterne und 0 / 400 XP; der Hilfetext ist lesbar.

**Grenze:** Die konkrete ABAB-Aufgabenzeile liegt in diesem gescrollten Ausschnitt oberhalb. Aufgabenidentität und richtige Form müssen zusätzlich an den aktuellen Rohdaten gebunden werden.

### Muster nach fachlicher Abgabe — `0492-pattern-after-explicit-core-assessment.png`

Der Kopf zeigt nun 5 Sterne und 33 / 400 XP. Die unteren Antwortkarten und der Hilfetext sind sichtbar; der innere Bildkreis der Tippkarte ist in diesem Bild leer.

**Grenze:** Das Bild enthält keinen ausdrücklichen Richtig-Text und ist kein selbständiger Beweis der assistierten fachlichen Musterbewertung. Diese Zuordnung erfolgt durch Learnings Prüfung des neuen Originaldatensatzes.

## Umfang und Herkunft

`review.json` bindet alle neun persönlichen Sichtbefunde an Originalpfad, Größe und SHA-256. `media-hash-review.json` enthält jede aktuelle Medienreferenz des Resultats; `video-eof-review.json` und die einzelnen unveränderten ffprobe-Ausgaben dokumentieren die vollständige sequenzielle Lektüre. Es wurden keine Bilder/Videos in dieses Paket kopiert.

Die gesonderte fachliche Originalprüfung übernimmt Learning. Diese Medienprüfung führt keinen Fachverifier, keine neue Androidhandlung und keinen CI-/Downloadvorgang aus. Die Originale unter `/dev/shm/lumo-2032-runtime-cases-originals` wurden ausschließlich gelesen.

Die erste fehlgeschlagene In-Memory-Übertragung und der erfolgreiche spätere Streamtransfer sind keine zwei Androidläufe. Das hier geprüfte Material gehört ausschließlich zu Run `43853317375`.

Keine Aussage zu vollständiger Modernisierung, physischem Fold7, ARM64-Laufzeit, 60 FPS, allgemeiner 48-dp-Abnahme oder millisekundengenauer Mund-/Gesten-/Audiokopplung.
