# Lumo AppEdit 1959 – Grafikintegration, Restarbeiten und Android-Rennstart

**Status: Entwicklungsstand, kein Produktrelease.** Stichtag 16.10.2026.  
**Basis:** `chatgpt/lumo-1958-visual-story-integration-2026-10-16` / `6c1abbae4d6c10dcda015c80d3c190e4874f0b21`  
**Branch:** `chatgpt/lumo-1959-kart-garage-ocr-repair-2026-10-16`  
**Godot-Quell-Pin:** `b5f19890f81971a72b703b4718aac4607999521c`.  
**Leitregel:** Kein Löschen oder Ersetzen des Schreibtrainers, Journals, der Lumo-Originalgrafiken, Lernstände, Profile, Stimmen, Rennphysik oder bestehenden Godot-Grafiksysteme.

## A. Was wirklich bereits an der gemeinsamen App hängt

| Paket | Ist-Zustand | Nächste Aufgabe |
|---|---|---|
| 3D-Lerninseln und Premium-Quizbühne | Branches sind Vorfahren des aktuellen Flutter-Quellstands, Quellcode vorhanden | Android-Screenshots, Navigations- und Performanceabnahme statt doppelter Codekopie |
| Hologlas-Fortschrittsleiste für freiwilliges Schulstufenüben | `cross_grade_practice_screen.dart`, `cross_grade_visual_scene.dart` und Tests sind im aktuellen Branch byteidentisch zu PR #320 | Android-Sichtkontrolle und Datenerhalt |
| Original-Lumo-Designassets | Bestehendes Bildarchiv im Flutter-Stamm; frühere Sammlung aus `claude/design-tafeln` ist kein fehlender Git-Import | Für jedes relevante Asset nachweisen, ob es tatsächlich in einer UI-/3D-Szene referenziert wird; unreferenzierte Assets als gezielte Aufgaben erfassen |
| Mentoren, Lernhelfer, Fold-Journal, Geschichte-Leser, Soundnavigation | Grundmodule im Flutter-Stamm enthalten | Echte Fold-/Audio-/Overlay-Regression statt Blindmerge |
| Story-Generator | In APK 1958 kompatibel erweitert: Begleiter, Zaubergegenstand, sechs Erzählvarianten und profilgebundene Rotation | Kinder-/Story-Reader-Tests auf Android |
| Asphalt, Sonnenhafen-Wasser, Leitplanken, Küstenlicht, LOD, 12 Bauwelt-Objekte, Fold-Garagenvorschau | Änderungen im Vorfahren des tatsächlich eingebundenen Godot-Pins | A/B-Bilder, Schatten/Schärfe und thermische FPS auf echten Android-Geräten bewerten |
| Drei neue Sonnenhafen-Aussichtstürme | Quellcode und Godot-Android-CI im `b5f19890`-Pin vorhanden | Sichtbarkeit und Sicherheit in echter Flutter→Kart-Rennfahrt überprüfen |

Ein Git-Vorfahre oder ein vorhandenes Bild ist **kein Beweis**, dass jeder Menüpunkt jede Ressource zur Laufzeit verwendet. Fehlende Referenzen nur anhand konkreter Dateien/Tests ergänzen.

## B. Tatsächliche verbleibende Integrationslücken

1. **M0 / Kritisch: Garage → echtes Rennen.** Build 1958 (CI [38916523320](https://github.com/Ullmann27/lumo-lernen/actions/runs/38916523320)) hat Analyse, vollständige Flutter-/Python-Tests und ARM64-/x86_64-APK-Bau bestanden. Emulator hat Profil, Lernen, Spiele und Öffnen der nativen Kart-Garage bestanden. Auf Garage-Seite 3 stoppte die bestehende OCR mit `Missing Android kart footer at step 3: Weiter`. Der originale Android-Screenshot `21_kart_garage_step_3.png` zeigt den Button **sichtbar** bei 2400×1080. Kein Nachweis, dass Godot oder Fahrzeugphysik kaputt sind.
2. **M0 / Jetzt behoben, Wiederholung ausstehend:** In `.github/probes/modernization_android_tour.py` ist eine zweite, auf gelbe native Aktions-Buttons begrenzte OCR-Erkennung ergänzt. Die gefundene Pillenposition entsteht aus gemessenen gelben Pixeln im echten Screenshot; vor dem Tap muss Tesseract den erwarteten Schriftzug bestätigen. Keine hartcodierten Tap-Koordinaten oder übersprungenen Renn-Gates. Lokale Prüfung am echten fehlschlagenden 1958-Framebuffer hat `Weiter` erkannt; offizieller Android-CI-Rerun steht noch aus.
3. **M0 / Weitere echte Gates:** Rennen `race_world_ready`, echtes 3D-Framebufferbild, HUD, Gasbedienung, Fortschritt in persistentem Godot-Rennstand, Pause/kein Fortschritt während Pause, Rückkehr zu Flutter, unveränderte Profile/Lerndaten, Neustart, Fold-Auflösungswechsel. Diese Anforderungen NICHT absenken.
4. **M1 / Abzweigende Funktionen:** Quiz-Lumo-Safe-Area (#305) ist gegenüber neuer Premium-Bühne divergiert; eine punktuelle Layoutkontrolle und isolierter Patch sind sinnvoll, ein blindes Überschreiben nicht. Familien-Updates (#298), Eltern-Schulstufenwechsel (#313) und verbleibende Spezial-Fixes einzeln vergleichen. Story #306 ist ab 1958 übernommen. NVIDIA-Pilot #310 bleibt bewusst standardmäßig deaktiviert ohne Eltern-/Datenschutzprüfung.
5. **M3–M5 / Grafische Arbeit:** Verbesserung der sichtbaren 3D-Renn-Detaildichte, Streckenlänge, KI-Fahrlinie, fahrbare Höhenlagen, echte Hindernisse, 360-Grad-Loopings mit Kollisionsgeometrie und Physik, Gesichts-Viseme/Lip-Sync, Musik/VFX. Vorhandene Bilder, Blender-/GLB-Assets und Shader zuerst inventarisieren und verlustfrei wiederverwenden. Zielwert 60 FPS ausschließlich messen.
6. **M6:** GitHub-Agentenrollen und CI sind noch kein autonomer Entwicklungsagent; persistente Aufträge, isolierte Codeausführung, Tests, Revision und echte PRs fehlen als geprüfte End-to-End-Kette.
7. **M7:** Physisches Samsung Fold 7, Lautsprecher, GPU-FPS, Thermik, Dialog- und Speicherverhalten auf echter Hardware noch nicht abgenommen.

## C. Bereits belastbare Nachweise / keine Erfolgsbehauptungen ohne Gate

- Flutter 1958 `verify` PASS und `apk` PASS auf demselben SHA `6c1abbae...` (Run 38916523320); `android-tour` FAIL bei Garage Seite 3; bis dorthin keine fatalen Abstürze, Profil/Lernstand nach Rückkehr/Neustart intakt.
- Eigenständiges Godot Kart Android PASS auf Pin-Linie in [Run 38891906395](https://github.com/Ullmann27/lumo-godot/actions/runs/38891906395), aber das ersetzt keinen gemeinsamen Flutter→Kart→echte-Fahrt-Beweis.
- Ein neuer APK-Kandidat darf **gebaut und zur Vorschau ausgeliefert** werden; ein Release-Gütesiegel erst nach durchgängig grünem Android-Rundgang, optischer Bildprüfung und Identitäts-/SHA-Kontrolle.
- Die nächsten Arbeiten priorisieren **M0** vor zusätzlicher umfangreicher Grafikentwicklung, da neue Assets ohne nachweislich startendes Rennen keinen Nutzerwert entfalten.

## D. Konkrete nächste Integration

1. Echte Android-Aufnahme `21_kart_garage_step_3.png` als Diagnoseartefakt behalten, den gelben Aktionsbutton textbestätigt aus seinem aktuellen Pixelbereich erkennen, beide APK-ABIs auf exakt neuem Commit bauen.
2. Alle fünf Garage-Schritte und den Fahrt-/Rückkehrtest laufen lassen, jeden nächsten beobachteten Fehler anhand echter Screenshots und Logs beheben (keine Stummschaltung).
3. Für Grafik nach dem erfolgreichen M0-Gate: Sonnenhafen-Vertical-Slice mit realen A/B-Laufzeitbildern, Physik/LOD/FPS und mindestens einer sichtbaren neuen Strecken-/Objektintegration; danach die übrigen Kurse.
4. Nur reale PR-/CI-Nachweise in [Masterissue #329](https://github.com/Ullmann27/lumo-lernen/issues/329) und im Integrations-PR verlinken.

**Endzustand dieser Aufgabe:** Neuer dokumentierter 1959-APK-Kandidat plus ehrliche PASS/FAIL/SKIP-Matrix; weder vorhandene Qualitätsarbeit doppeln noch ungeprüfte 3D-Reife versprechen.
