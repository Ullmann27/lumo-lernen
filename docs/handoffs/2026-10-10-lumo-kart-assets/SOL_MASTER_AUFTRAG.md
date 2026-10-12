# SOL 6.1 / Sehr hoch – Ausführungsauftrag Lumo Lernen + Lumo Kart

**Für Perplexity Computer. Verbindlicher Entwicklungsauftrag, keine Konzeptstudie.**

Beginne mit [README](./README.md) und [Asset- und Transferstatus](./ASSET_BESTAND_UND_TRANSFER.md). Die ZIP-Bände sind in dieser GitHub-Übergabe aktuell **nur inventarisiert, nicht als Binärdateien hochgeladen**. Arbeite so lange wie zulässig mit den vorhandenen Referenzen und Codequellen weiter; für nicht verfügbare Bildarchive eine konkrete, einmalige Dateiübergabe anfordern, statt fehlende Dateien zu erfinden.

## Leitlinie

Du bist federführender Flutter-/Android-, Godot-4.6-, Blender-, 3D-Character-/Environment-/VFX-, UI/UX-, Game-Physics-, KI-, Performance-, Security-, QA- und Release-Engineer. **Das vorhandene Produkt fertigstellen. Keine neue Lumo-App und kein neues Rennspiel.** Bestehende Lernstände, Profile, Belohnungen, Schreibcoach, Audioarchitektur, Kart-Physik und Lumo-Identität erhalten. Keine unautorisierten Zahlungen oder Zugangs-Umgehungen.

**GitHub:** https://github.com/Ullmann27/lumo-lernen und https://github.com/Ullmann27/lumo-godot

**Prioritäten in dieser Reihenfolge:** (1) echter Kart-Lade-/Menübildschirm auf Samsung Galaxy Z Fold, (2) animierter originaler Lumo, (3) hochwertige befahrbare Rennstrecke mit Looping und Sprüngen, (4) bestehende gesamte Lern-App, (5) vollständige Android-APK-Abnahme.

### 0 – Bevor du schreibst

- Prüfe `main`, alle relevanten offenen PRs, CI, Commit-SHAs und die tatsächlichen Godot-Pins. **Offene PRs sind nicht automatisch im Produkt.**
- Lern-App-PRs #246, #248, #253, #255, #256, #257; Godot-PRs #44, #45, #46, #47, #49, #50, #51 beachten.
- Designquellen: `docs/DESIGN_ZIEL_2026-10-04.md`, `docs/DESIGN_ZIEL_KART_2026-10-04.md`, `docs/DESIGN_ASSETS_2026-10-04.md`, Originalreferenzen aus PR #248. Abweichende alte Designregeln nach jüngsten Nutzerentscheidungen gewichten.
- Menüreferenz `50666.gif` mit fünf sichtbaren Moduskarten, großem animiertem Lumo im Kart und **genau einem** goldenen Weiter-Button; Garage `50294.png`, Rennen `50288.png`, weitere `k09_modus_waehlen.png`, `k08_cup_streckenauswahl.png` etc. Zuerst tatsächlich finden und visuell prüfen.
- Prüfe vor jeder Neugenerierung die vorhandenen PNG/GLB/Blend/Meshy/Tripo-Daten und `PR #51`: bestehendes Lumo-Rig mit 65 Bones, neun Clips, ca. 30.000 Dreiecken.
- Die bisherigen 4K-Konzeptbilder dürfen Stil zeigen, aber nicht als spielfertige 3D-/Trackmodelle ausgegeben werden.
- Erstelle eine unveränderliche Ausgangsinventur mit Hashes, Branch-Herkunft und Abweichungsliste. Für Arbeit eigene Featurebranches und kleine PRs nutzen; kein ungefragtes Merge in `main`.

### 1 – Kart-Einstieg, Ladebildschirm und echtes Hauptmenü

Die aktuelle echte Anzeige auf dem aufgeklappten Fold ist nicht akzeptabel: Schriften, Modus- und Gameplaybuttons sind zu klein, Layout wirkt leer und weit von den bestätigten Referenzen entfernt. Untersuche **welches Flutter-/Godot-Menü tatsächlich gestartet wird**, entferne Doppel-/Scheinmenüs, verhindere veraltete Menü-Builds.

Erstelle einen hochwertigen animierten Ladebildschirm: Original-Logo, schwebende Inseln, neonblaue Rennstrecke, Lumo im Kart, Winken, subtile Kamerafahrt, echte Ladezustände, Fehler- und Retry-Pfad, nachfolgende Starts optional überspringbar. Keine Fake-Prozentanzeige; Ton- und reduzierte-Animationen-Einstellungen respektieren.

Hauptmenü: prominenter echter 3D-Lumo rechts beziehungsweise optimal positioniert, fünf große visuell hochwertige Moduskarten, scharf lesbare Typografie und klarer großer goldener Weiter-Button. Blau/Cyan/Gold, hochwertige 3D-Bühne mit echter Beleuchtung, lebendiger Background, gute Kamera, Garage. Jeder aktive Modus muss funktionieren; fehlende Modi transparent als nicht verfügbar markieren. Kein schwarzes Podest, kein kleiner Fuchs, keine billigen technischen Platzhalter.

**Fold-Abnahme:** 360×800, 640×360, 1280×720 und breite aufgeklappte Konfiguration; geschlossene und geöffnete Formfaktoren, Orientierung, Safe Areas, UI-Scaling, Scrollfähigkeit, keine abgeschnittenen Textzeilen, keine überlappten Buttons. Touchziele sinnvoll mindestens 48 dp, spielrelevante Gas/Lenken/Bremse/Drift/Turbo/Item-Flächen ausreichend größer und mit Multitouch-Test. Nach jedem sichtbaren Schritt echte Godot-/Flutter-Screenshots nebeneinander mit Originalreferenz; verbleibende Abweichungen protokollieren.

### 2 – Einen originalgetreuen beweglichen Lumo tatsächlich in Runtime integrieren

Nicht noch einmal blind in Meshy neu generieren! Bestehendes rigged GLB aus Godot-PR #51 und ursprüngliche Lumo-Vorlagen inspizieren. Identität: orangefarbenes Fell, weiße Schnauze, blaue Stirn-Fliegerbrille, braune Augen, dunkelblaue Rennjacke mit cyanfarbenem L, passende Ohren/Schweif. Rig/Skins/Clip-Transitionen, animierbare Augen und ggf. Mundmechanik kontrollieren.

Bewegungen: Idle, Blinzeln, Winken, Kopfbewegung, Auf-Aufgaben-Zeigen, Jubeln, im Kart Sitzen/Lenken, Drift, Sprung, Landung, Trefferrückmeldung, Ergebnis. Physische Hände am Lenkrad, Fahrer korrekt am Sitz befestigt, keine verformten Arme. Mund-/Lippensynchronität **nur nach echtem Test** behaupten; Audio-Envelope allein ist keine echte Visem-Synchronisation.

**Sulafat-Stimme wird parallel von anderem Agenten bearbeitet**: vorhandene Stimme nicht ersetzen, alte TTS nicht wieder aktivieren, lediglich kompatible Ereignisse für Sprech-/Kopf-/Mundanimation anschließen. Godot-/Flutter-Integrationen in einem realen APK-Build überprüfen.

### 3 – Actionreicher vorhandener Kurs, Zielrunde ca. 50 Sekunden

Keine hübsche falsche Streckencollage statt Spielfahrt. Eine bereits existierende fahrbare Strecke nehmen, modular korrekt ergänzen und dabei die zuvor inventarisierten 10 ZIP-Bände nach Nutzerfreigabe/Dateibereitstellung verwenden. Siehe [Asset-Inventar](./ASSET_BESTAND_UND_TRANSFER.md). Für Fahrbahn Curve3D / parametrisierte Blender-Meshes und echte vereinfachte Collider bevorzugen; visuelle Motive als Form-/Materialreferenz.

**Erwartete Strecke:** lange dynamische Runde, breite/schmale/enge Kurven, S-Kurven, große Steilwand, echter vertikaler 360°-Looping, Wand-/Anti-Schwerkraft-Passage, Corkscrew/Spirale, große und kleine Sprungschanze, fliegbare Passage und sicherer Landeplatz, Tunnel, Brücke, Halfpipe, mindestens ein Shortcut, Start-/Zielarena, Boost-Pads, Item-Boxen, Hindernisse, spektakuläre Zielanfahrt. Eigenständige Lumo-Markenwelt, keine kopierten Mario-Kart-Assets oder Strecken.

Looping-Fahrbarkeit erfordert korrekte dynamische Fahrzeugsurface-Normals, Haftsicherstellung, Kameraführung, Kollisionsübergänge, echte Mindestgeschwindigkeit und Respawn. Eigene automatisierte Looping- und Mehrkarttests. **Rundenzeit ~50 s bei schneller optimaler Fahrt** ist zu messen und mit realer Fahrphysik zu optimieren, nicht aus einem Bild abzuschätzen.

Bausteine: Startbogen, Garage, Streckenbegrenzung, Fels/Crystal/Wasserfall/Schwebeinsel, Wald, Tribüne, Licht, Sterne, Tore, Boost, Item. Abstands- und Skalierungsregeln aus vorhandenem Godot-Projekt. LOD, Texturen, UVs, Material-Instancing und mobile Draw Calls kontrollieren. Keine ungeprüfte 4K-Materialflut in Android-APK.

**Kart ist ein Freizeitracer:** keine Mathematik-Lernfragen oder Antworttimer im Rennen, kein `Richtig = Turbo`; Lernfortschritt kann höchstens vorhandene Freischaltungen beeinflussen. Siegergebnisse, Items, Gegner, Cup, Rennspeicherung, Pause und Rückkehr zur Lern-App bleiben korrekt.

### 4 – Den vollständigen Rennen-zu-App-Ablauf testen

App → Kart-Einstieg → Ladebildschirm → Menü → Modus → Cup/Strecke → Fahrer/Kart → Startampel → Start → Gas/Lenken/Drift/Boost → Itemaufnahme/-gebrauch → Looping → Sprung → Shortcut → mindestens ein kompletter Rennabschluss → Ergebnisse/Belohnungen speichern → Garage/App. Mehrere Gegner und gültige Rundenkontrollen. Prüfe HUD, Tacho, Minimap, Pause, Ergebnis, Start-/Zielsound, Musik, lizenzkonforme Sounds. Gegner dürfen nicht unfair durch manipulierte Geschwindigkeitswerte gewinnen.

### 5 – Ganze Lern-App, in vorhandener Reihenfolge

Nach Kart-Einstieg/Charakter/Rundkurs die komplette vorhandene App prüfen, **nicht neu erfinden**: Start, Login/Onboarding, Kinderprofile, Name/Klasse, Hauptmenü, Fächerwahl, Mathematik, Lesen, Deutsch, Handschreiben inkl. S-Pen und Fold, Sachunterricht, Tests, Memory, Lumo Cards, Vier Gewinnt, Profil, Belohnungen, Elternbereich, Audioeinstellungen, Offline-Modus, Updates, Profil-/Fortschrittsspeicher und Datenschutz. Echte Pfade per Widget-/Integrationstest, bei grafischen Korrekturen aktuelle Originalvorlage daneben.

Insbesondere Mathematik: im Code noch Emoji-Äpfel/Bonbons und einfache Mengenkästchen. Vorhandene `apple_red.png`-Planung und echte neue Bilder suchen, fehlende Lumo-konforme PNGs gezielt erstellen und korrekt als zählbare Mengen in Plus/Minus und generischen Renderer integrieren, ohne Bewertung oder XP zu verfälschen. Auf allen Größen pädagogisch lesbar.

Sicherheit: getrennte Profile, offline/online Fehlerbehandlung, keine exponierten API-Schlüssel, Kinder-/Elternzustimmungen, saubere lokale Fortschrittsdaten, keine doppelten Belohnungen, keine Regressionen in Schreibcoach/Sulafat/Audiosynchronisation.

### 6 – Tatsächlich messen, dokumentieren, testen

Flutter `analyze` und relevante `test`-Suites, Godot-Import, Godot-Szene/Rennsimulation, Screenshot-Vergleich, Frame-Time, FPS, Memory, Draw-Calls, Android-Geräte-/Emulatortests (deutlich markieren, welches Testmilieu verwendet wurde). 60 FPS auf unterstützten stärkeren Geräten anstreben, aber keine fiktiven Messwerte. Originalmodell und bereinigte Version vergleichen; LOD/Shader/Texturatlas mobiletauglich gestalten. Abgestufter Rollout mit funktionsfähiger Rückfallstrategie, keine Datenverluste.

Führe `docs/LUMO_PRODUKTION_FORTSCHRITT.md` im eigenen Entwicklungsbranch. Pro Meilenstein: Start-SHA, Änderungen, Testresultate, echte Screenshots/Videos, offener Bedarf, nächste konkrete Arbeit. Bei Sitzungsende Übergabe statt Behauptung automatischer Hintergrundarbeit.

### 7 – Zuverlässige Android-APK

Zum Abschluss Flutter und Godot integrieren; Android-Paket-ID, Versionscode, Keystore/Signatur, 16KiB/ABI-Kompatibilität und Datenbeständigkeit prüfen. Eine tatsächlich erzeugte APK mit Hash/Nachweis anbieten, soweit direkte Bereitstellung technisch möglich. Nicht einfach die frühere App deinstallieren lassen. Öffentlichen Release/PR-Merge nur nach Freigabe.

## Autonomie & Kosten

Arbeite selbstständig bei gewöhnlichen Bugs. Bei Toolausfall prüfen: GitHub APIs, andere autorisierte Checkouts, archivierte Assets, Godot Headless, Blender Batch, geeignete kostenlose Alternativen, Log-Analyse. **Keine Umgehung von Sicherheit, Login, Paywall oder Kontosperre.** Kostenpflichtige Meshy-/Tripo-/API-Generierungen nur nach Nutzerfreigabe. Fasse echte Arbeit in nachprüfbaren Teilabschnitten zusammen, statt Stunden an Konzepten zu arbeiten.

## Unmittelbarer Start (kein weiterer Konzept-Prompt)

1. Beide Repos/PRs/Ref-GIFs lesen und geprüfte technische Baseline festhalten.
2. Aktuelles Kart-Hauptmenü in Godot starten, echte Fold-/720p-Screenshots erzeugen, Differenz zu `50666.gif` messen.
3. PR #51-Rig- und Animationstests prüfen, Animation im tatsächlich genutzten Godot-Menü zeigen.
4. Das Flutter-Kart-Starten inklusive Ladebildschirm reparieren und end-to-end testen.
5. **Erst danach** die gesamte vorhandene Rennstrecke mit vorhandenem Baukasten verbessern; den Verfügbarkeitsstatus der zehn 4K-Bände ausdrücklich prüfen.
6. Lern-App systematisch verbessern; Tests und Android-Build nach Meilenstein.
7. Bei jedem Hindernis tatsächlichen Fehler und nächstbesten zulässigen Weg dokumentieren.

**Abnahmeregel:** Ein Bild ist kein 3D-Modell; ein GLB kein rigged Charakter; ein Godot-Import kein funktionierendes Rennen; ein grüner Headless-Test kein realer Fold-Test; eine GitHub-URL noch keine direkt heruntergeladene APK. Beschreibe immer den belegten Ist-Zustand.
