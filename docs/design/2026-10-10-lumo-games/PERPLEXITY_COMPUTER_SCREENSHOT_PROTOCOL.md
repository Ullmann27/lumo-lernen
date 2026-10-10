# VERBINDLICHES LIVE-SCREENSHOT- UND FREIGABEPROTOKOLL — LUMO
Stand 10.10.2026 · Gilt für Perplexity Computer, Claude Sonnet, Codex und andere Entwicklungsagenten.

## 1. Zweck

Der Auftraggeber muss während der Programmierung laufend selbst beurteilen können, ob neue Ansichten dem ursprünglichen Lumo-Design entsprechen. **Vorher-/Nachher-Bilder sind ein verbindliches Zwischenergebnis, nicht nur eine Beilage zur finalen APK.** Die originale Gestaltung ist unter `DESIGN_BESTANDSSCHUTZ.md` festgelegt; die zehn Originaldateien stehen unter `references/`.

## 2. Wann MUSS ein Bild erscheinen?

- **Ganz am Anfang:** ungeänderter Ist-Zustand der betroffenen Szene/Flutter-Seite plus das zugehörige Referenzbild; beschriftet mit Git-SHA, Bildschirmgröße, Renderer/Device und Datum.
- **Nach JEDER sichtbaren Änderung** an Lumo (Gesicht, Körper, Kart), Levelgeometrie, Streckendekoration, Licht, Shader, Menü, HUD, Knopfgrößen, Karte, Lernseite, Audio-Auswahloberfläche oder Ergebnisbildschirm: neues echtes Nachher-Bild, unmittelbar dem Vorher-Bild gegenübergestellt.
- **Bei umfangreicher visueller Arbeit mindestens nach jedem visuellen Meilenstein**, und zusätzlich ungefähr alle 10–15 Minuten aktiver Layout-/3D-Arbeit, sofern neue darstellbare Änderungen vorliegen: keine halbstündigen „unsichtbaren“ Grafikphasen.
- **Nach Fehlerbehebungen** (z. B. fünfter Rennmodus abgeschnitten, Wangenlücke, falscher Skalierungsfaktor) und **vor jedem Build/PR-Merge**: die reparierte Stelle sichtbar nachweisen.
- **Wenn Rendern gerade unmöglich ist:** sofort ein Problemprotokoll und die tatsächlich vorhandenen Logs/Fehlbilder zeigen; nicht aus KI-Generatoren Ersatz-Screenshots als „echte Godot Runtime“ ausgeben. Reparatur priorisieren und dann echte Bilder nachreichen.

## 3. Technische Herstellung

1. Vorher und Nachher müssen aus **derselben ausführbaren realen App/Szene** stammen: Flutter Screenshot über Emulator/integration_test, Godot Viewport `get_texture().get_image()` oder Android `adb exec-out screencap -p`. Kein Figma-, Text-to-Image- oder Canvas-Bild als Laufzeit-Nachweis.
2. Für den Vergleich feste **Kamera, Track, Fahrzeug, Lernstand/Test-Account, Bildschirmauflösung, Tages-/Lichtphase, UI-Zustand** und reproduzierbare Zufalls-Seed verwenden. Bei Bewegung mehrere kontrollierte Frames erfassen.
3. In den Format-Gates mindestens: **1280×720 Querformat**, **640×360 kompaktes Fold-Querformat**, **1200×896 großes Fold/Tablet**, **360×800 Android-Portrait** für die Lern-App. Weitere tatsächliche Displaymaße ergänzen. Bei Fold die echte nutzbare Fläche und Touchbedienung prüfen, nicht nur ein Bild skalieren.
4. Bildvergleich pro Szene als **zwei Einzelbilder + Side-by-Side-Kontaktabzug** (links Vorher, rechts Nachher), zusätzlich optional Alpha-Overlay und Bilddifferenz. Referenz-Illustrationen gesondert mit `SOLL (Konzeptgrafik)` kennzeichnen.
5. In GitHub versionierte Nachweise unter `docs/qa/visual/<feature>/<YYYY-MM-DD>/<commit>/` oder in GitHub Actions Artifacts mit unmittelbar anklickbarer URL sichern. **GitHub Actions Artifacts können verfallen:** maßgebliche Vorher-/Nachher-Bilder möglichst als dauerhaft versionierte, komprimierte PNG/WebP-Dateien ins Repository; große Sammlungen über Artefakte/Release mit Manifest und SHA256. Keine riesigen Dateien ungeprüft committen.
6. In jeder Fortschrittsmeldung **direkte Links pro Bild** und, soweit der Client es unterstützt, eingebettete Bildvorschauen liefern. Keine reine Dateipfad-Angabe ohne URL; keine Collage als einziger Beweis, damit der Nutzer hineinzoomen kann.

## 4. Jedes sichtbare Update muss enthalten

**Bildschirm/Funktion:** [z. B. Kart – Moduswahl]
**Vorher:** [direkt öffnbarer Bildlink]
**Nachher:** [direkt öffnbarer Bildlink]
**Referenz:** [exaktes Originalbild/Link]
**Änderung:** [knappe technische Beschreibung]
**Vergleich:** [was sichtbar besser ist / was sichtbar noch abweicht]
**Quelle:** [Repository, Branch, Commit]
**Format & Laufzeit:** [Größe, Android/Godot-Version, Renderer]
**Tests:** [belegt bestanden / fehlgeschlagen / offen]
**Nutzerentscheidung:** [freigegeben / Korrekturwunsch / noch nicht geprüft]

## 5. Eingriff durch den Auftraggeber

Der Auftraggeber muss **jederzeit** einen visuellen Korrekturwunsch formulieren können. Bei eingehendem Feedback zu Szene X:
- die weitere visuelle Änderung an **X** anhalten,
- Zustand und Bildlinks sichern,
- Feedback als verbindliche Akzeptanzbedingung konkretisieren,
- Korrektur entwickeln und **erneut Vorher/Nachher-Bilder ausgeben**,
- bis dahin nicht behaupten, X entspreche dem Bild und keine ungeprüfte APK als finale Auslieferung kennzeichnen.
Unabhängige Code-/Testarbeiten können weiterlaufen; sie dürfen die strittige Szene nicht überschreiben. Für größere Änderungen an originalen Markenassets oder Shell-Strukturen **ausdrückliche Zustimmung vor Integration** einholen. „Keine Rückfragen“ gilt für normale technische Routineentscheidungen, NICHT für entgegenstehende Designrückmeldungen und unumkehrbare Eingriffe.

## 6. Freigabebedingung

Ein „visuell fertig“ oder „APK final“ ist unzulässig, solange ein wesentlicher Screenshotvergleich fehlt, wichtige Referenzabweichungen ungelöst sind, Buttons nicht erreichbar sind oder Android-Installation/Spielablauf nicht nachgewiesen wurden. Eine grüne CI allein bedeutet NICHT „wie Referenz“.
