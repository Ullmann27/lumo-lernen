# Weiterarbeitsprompt für GPT‑6 im Chat-Modus

Du übernimmst Lumo Lernen, Lumo Kart und sämtliche vorhandenen Spiele, bis Astra zurückkehrt. Arbeite autonom direkt am bestehenden Code. Keine Konzeptschleifen, keine unnötigen Rückfragen, keine erfundenen Erfolge. Nutze GitHub und verfügbare Ausführungswerkzeuge aktiv. Der Nutzer möchte möglichst lange echte Entwicklung; antworte sehr kurz mit Änderungen, Tests, Bildern, PRs, APK und offenen Punkten.

## Sofort den echten Stand prüfen

- Flutter: `Ullmann27/lumo-lernen`, Arbeitsbranch `codex/lumo-1977-premium-learning-2026-10-18`.
- Godot: `Ullmann27/lumo-godot`, PR **#101**, Branch `codex/lumo-1977-cavern-production-2026-10-18`, geprüfter Quellpin **`efa1f69b4128a047e6196ee85762447e412db266`**.
- Sichere Rückfallversion **APK 1976 / 0.12.64**, Flutter PR **#362**, Quelle `840708ac5669e1705376f20ceb87ef4e09bca155`, Godot PR **#100** / `6518a13fb8eb30c81c8a2115d14791cbe7ddd24a`. Diese Version und ihre Artefakte erhalten.
- Neuer Kandidat **0.12.65+1977**. Er enthält den oben genannten exakten Godot-Pin. Die bisherigen historischen Versionspins bleiben erhalten.
- Die neuesten Commits, PRs und Actions jetzt selbst abrufen. Kein alter Main-Branch als vermeintlich neueste App verwenden. Offene PRs sind teilweise bereits in der gestapelten Kandidatenkette enthalten; nicht blind noch einmal cherry-picken.
- App-PR ermitteln: `gh pr list --repo Ullmann27/lumo-lernen --head codex/lumo-1977-premium-learning-2026-10-18 --state all`.

## Zuerst den begonnenen Meilenstein abschließen

1. App-Workflow **Lumo Lernen Kart unified integration APK** und Godot-PR #101 prüfen. Godot-Actions: Stage2 `39089816809`, Darkride `39089816876`, Event `39089816831`, Fabrik `39089816815`. Die letzten drei waren bereits SUCCESS; Stage2 lief bei Übergabe noch. Status immer frisch lesen.
2. Der App-Workflow führt vollständige Flutter-/Python-Tests aus, baut ARM64 und x86_64 mit Godot 4.6.3 und überprüft Signatur, Version, PCK und Provenienz. Danach installiert Job `android-tour` exakt die gebaute x86_64-APK und prüft App → Garage → tatsächliche Fahrt → Pause → Flutter-Rückkehr, gespeicherte Lerndaten, Neustart und Fold-Größen. Fehler anhand echter Logs beheben, keine Gates ausschalten.
3. Bei erfolgreichem Bau Artefakt `lumo-lernen-kart-unified-2026-candidate` herunterladen. Beide ZIP-Integritäten und APK-Hash unabhängig prüfen. Die ARM64-Datei heißt `Lumo-Lernen-Neu.apk`; PCK-/Quellstand, VersionCode 1977 und Paketkennung gegen `BUILD-PROVENANCE.json` und `APK-VERIFICATION.json` abgleichen. Installations-/Tour-Erfolg separat prüfen. Erst dann einen fertigen APK-Download melden.
4. Noch laufenden lokalen vollständigen Flutter-Test überprüfen, wenn die Umgebung erhalten ist: `/workspace/scratch/flutter-full-final.log`. Er hatte bei Übergabe über 300 bestandene Fälle und keine Fehler. Das ist KEIN abgeschlossener Gesamterfolg. Der frühere Lauf `flutter-full-1977.log` wurde wegen eines inzwischen behobenen Test-Harness-Stalls abgebrochen und ist kein gültiger Abschlussbeleg.
5. Bei erforderlichen Änderungen Versions-/Godot-Policy, Cleanup-Allowlist und Tests konsistent halten; APK 1976 nicht umschreiben. Neue sichere Kandidaten und kleine nachvollziehbare Commits verwenden. Kein Force-Push; kein Main-Merge oder öffentlicher Release in diesem Auftrag.

## Bereits implementiert und gezielt geprüft

- Gemeinsame Glasflächen mit Lichtkanten; größere originale Navigationsgrafiken; bei großer Schrift horizontal erreichbare Tabs mit festem Mehr-Menü.
- Echter animierter Lernfortschritt mit reduziertem Bewegungsmodus und Ticker-Unterdrückung auf unsichtbaren Routen. Gemeinsamer Rahmen für 19 Module; Plus-Handy/Fold-Ansicht mit lesbaren, nicht mehr abgeschnittenen großen Sprechblasen und echtem Erfolgszähler. Antworten und Safe Areas wurden nach visueller Prüfung nachgebessert.
- Rechenhaus, Sternenpfad, Farbenkisten, Buchstabenfüllen: navy/cyan Spielwelt, klar lesbare helle Aufgabenflächen, echter nummerierter Rundenfortschritt, zugängliche Pause. Würfelrennen: lesbare Spielerstände und Positionsbalken. Memory: dauerhafte echte Paarmarkierungen/Semantik, echte Gesamtsummen, schmale zweistellige Punktstände passen. Cards: lesbare Zug-/Nachzieh-Anzeigen, ruhiger Modus ohne Nachzieh-Puls.
- LumoVoice serialisiert neue Wiedergabe gegen ausstehende native Stop-Bestätigungen. Verspätete Stop-Antworten dürfen die neue Begrüßung nicht stoppen oder deren Zustand überschreiben. F2-/Sulafat-Identitäten und Originaldateien erhalten. Die neue Regression war vor dem Fix rot. Native Kanalaufrufe im Widget-Test laufen bewusst mit `tester.runAsync`; das gilt auch für die initiale Route des MaterialApp.
- Sonnenhafen: echte unregelmäßige Höhlengeometrie, Felsgruppen, Stalaktiten, importierte Kristallgärten und Wasserkanäle in fünf zusätzlichen Material-Batches. Fahrbahn/Kollisionen/Checkpoints/Spielstände unverändert. Höhlen-/Wasser-Shader nutzen kontrollierte Rennzeit statt unabhängiger TIME-Animation; Pause und reduzierte Bewegung werden eingehalten.
- 3D-Fabrik erzeugt High/Mobile-GLBs mit 324/144 Dreiecken je Kristallgruppe, validiert echte Binärgeometrie, Normalen, Indizes und Bounds. Blender 4.3.2 und Godot 4.6.3 importieren beide Varianten. Kein trainiertes Text-zu-3D-System oder automatischer KI-Dienst behauptet.

Gezielte Nachweise: **82 Lernlayout-/Mengen-/Safe-Area-/Save-Prüfungen**, **67 Sprachtests**, **43 Spielprüfungen**, **160 Build-Pythontests** (lokal ein Gradle-Skip), **15 native Godot-Proben**, **56 Godot-Pythontests** bestanden. Unabhängige Codeprüfung fand keinen konkreten Blocker. App-Tour rendert **19** echte Fälle. Die vollständigen neuen CI-/APK-/Android-Ergebnisse zusätzlich prüfen.

Bilder und Inventar: `docs/evidence/1977/README.md` in Flutter und `docs/evidence/1977-cavern/README.md` in Godot. Das Inventar dokumentiert 402 App-/106 Godot-Branches vor Veröffentlichung. Bilder sind unveränderte Flutter-/Godot-Laufzeitrender auf Linux mit Original-Assets, keine physischen Fold7-Aufnahmen.

## Bekannter zusätzlicher Prüfpunkt

Der ältere optionale native `scripts/tests/kart_complete_flow_regression.gd` verlangt am ersten Save/Resume `game.distance == progress`. Eine echte GPU-Diagnose ergab: `paused=true`, gleiche Ergebnis-ID, aber Distanzdifferenz **−1,1×10⁻¹³ m** durch Textserialisierung. Das ist kein beobachteter Spielstandsverlust. Den Test an die bereits bestehende strenge absolute **1e-9-m-Toleranz** der Continuity-Probe angleichen und anschließend das gesamte echte Zweirundenrennen erneut ausführen; keine Positionen, Checkpoints oder Ergebnisse einspritzen. Die Laufzeit-/Physikdatei dafür nicht ändern. Die Diagnose liegt lokal in `fullrace1977-diagnostic.log`; der Test-Fix ist noch NICHT implementiert. Native Renderproben müssen bei Assertion-Fail zuverlässig abbrechen; ein hängender Godot-Prozess ist kein PASS.

## Danach weiterentwickeln, Lern-App zuerst

- Startseite, Klassen-/Fachmenüs, Mathe, Deutsch, Englisch, Nachhilfe, Schreibtrainer, Journal, Profil, Belohnungen und Spieleauswahl einzeln tatsächlich öffnen, fotografieren und gezielt verbessern. Gemeinsame vorhandene Komponenten bevorzugen; keine funktionslosen neuen Menüs oder Platzhalter.
- Original-Lumo aus vorhandenen Referenzen beibehalten. Gesicht, Brille, Fell, Outfit und Proportionen vergleichen; keine neue Ersatzfigur. Natürliches Begrüßen/Sprechen/Animation anhand echter Ton-/Bildaufnahmen verbessern. Der jetzige Sprachfix verbessert Zuverlässigkeit; eine neue hörbar natürlichere Stimme wurde damit nicht produziert.
- Sämtliche Spiele inventarisieren und weiter verbessern. Connect Four und die kreativen Godot-Spiele wurden in diesem Pass bewahrt und regressionsgeprüft, aber nicht als neue vollständige Premium-Art-Pässe ausgegeben. Musik, Steuerung, Pausen, Rückkehr, Mehrfachberührung, Belohnungen und Speicherung jedes Spiels prüfen.
- Sonnenhafen weiter von der jetzt detaillierteren Höhle aus entwickeln: organische Geländeübergänge, hochwertigere Materialien/Beleuchtung, charaktervolle Landschaften, sichere Brücken/Sprünge/Abkürzungen und abwechslungsreiche Rennereignisse. Eigene Markenwelt. Keine gefährliche neue dynamische Fahrbahn ohne tatsächliche Kollisions-/KI-/Respawn-Tests.
- Fabrik/Blender/Godot-Pipeline für echte weitere Original-Assets verwenden. Ausgaben durch beide Importer prüfen und im laufenden Spiel verwenden. Keine bloß abgelegten, ungenutzten Assets als fertige Verbesserung melden.
- Android/Fold7: Außen-/Innendisplay, große Schrift, echte Rotation, Größenwechsel, Hintergrund/Pause und Rückkehr testen. **60 FPS erst nach echter physischer Framezeitmessung behaupten.** Konsolen-/Mario-Kart-Gleichwertigkeit bleibt ein Qualitätsziel, kein erreichter Nachweis.

Erhalte alle Profile, Lernstände, Spielstände, Module und Freischaltungen. Aufgaben-/Belohnungslogik nicht durch Präsentationsänderungen ersetzen. Sichere einen überprüfbaren nächsten Meilenstein mit echten Screenshots, Tests und möglichst neuer APK. Berichte knapp und ehrlich.
