# Lumo Entwicklungsbestand und Reparaturplan · 13. Oktober 2026

## Verbindlicher Quellstand

Diese Inventur bezieht sich auf die **geschützte Integrationslinie**, nicht auf eine installierte Gesamt-APK.

| Quelle | Head zum Abruf | Zustand |
|---|---|---|
| App `main` | `90c239898c2f5fe7230dda05cb9e499069162208` | Ältere, abweichende Produktlinie |
| PR280 | `5fe56eb111f5d44a69ba98ef5424033afa6f417b` | Offen, Draft; geschützte Basis |
| PR284 | `e68b69908b446cbbb50bdb576753dfd96bf68fc3` | Offen, Draft; Profilklasseninitialisierung |
| PR285 / PR287 | `d7440beaba78992ee36c8f4be1513e6b5006c1f6` | Identischer Commit; feste Lernpfadklasse |
| PR281 | `3101d302fefa3b8e650f555080333063d1e30072` | Offen; ausschließlich Spender, kein Basiswechsel |
| PR282 | `b623c3ccc3f74117658a3ea5cc7ebf316809df48` | Offen; ausschließlich Spender |
| App-Auditzweig | `a1ed3034b406199e0e2b5288c0602a3194a65d6b` | Umfangreiche Deltas, selektiv untersuchen |
| Godot-Pin / PR65 | `ec96515a2e359d21e9591120fc81dfd15116e81e` | Unverändert; Godot 4.6.3 |
| Godot `main` | `ee4d932e59cf304c3ff249631a1f8133dbba2079` | Historische Standalone-Linie |

`git merge-base --is-ancestor 5fe56eb HEAD` bestätigt die geschützte Herkunft von PR285. Version bleibt `0.12.31+1938`. CODEX_START/CLAUDE/OPUS_NEXT und die vorhandenen Godot-Claims #15/#17 wurden gelesen. Ihre historischen Build-/Pinanweisungen ersetzen den aktuellen Auftrag nicht.

## Selbst geprüfter CI-Nachweis

[Actions 38375803750](https://github.com/Ullmann27/lumo-lernen/actions/runs/38375803750) ist erfolgreich. Der Verifikationsjob `115223798156` checkt exakt `d7440be…` aus. Originalprotokoll: `pr285-original-ci.log.gz`; Artefakt `11800913355`, Digest `sha256:a291b5561943e1ab5548d066b2040e1e09c42adc4edeb9b989e0364f9c1aa04c`.

- Flutter 3.44.9, Dart 3.12.2.
- `flutter pub get` erfolgreich.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: 24 Informationshinweise; kein Analysefehler.
- `flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2`: 1.456 bestanden, 117 übersprungen, keine fehlgeschlagenen Tests.
- Andere Läufe desselben Commits stehen auf `action_required`; das sind keine ausgeführten fehlgeschlagenen Tests.
- Dieser Nachweis erteilt **keine Android-, APK-, Fold-, Stimmenhör- oder visuelle Gesamtfreigabe**.

Der lokale Flutter-Aufruf wurde durch automatische Sicherheitsprüfung wegen eines unerwarteten Cloud-Metadatenzugriffs blockiert. Er wurde nicht durch andere lokale Aufrufe umgangen. Tests neuer Änderungen laufen über den bestehenden reinen GitHub-Reviewworkflow. Keine neue Workflowdatei und kein Android-Build.

## Inventurumfang und Grenzen

Die reproduzierbare Inventur `python tools/audit_lumo_inventory.py ../lumo-godot` erfasst 316 App- (einschließlich eigenem Arbeitsbranch) und 65 Godot-Remote-Branches sowie 1.862/1.250 Dateien an den oben genannten Basen. Sie vergleicht echte Git-Trees und Blob-IDs. 102 App-/43 Godot-Heads sind bereits Vorfahren der jeweiligen Basis. Weitere Abweichungen sind **Prüfkandidaten**, nicht automatisch verlorene Funktionen. 270 App-/57 Godot-PR-Heads sind einschließlich geschlossener PRs zusätzlich als eigene Git-Refs gelesen und Tree-zu-Tree verglichen; PR-Metadatenindex: 160/6 gemergt, 10/1 geschlossen ohne Merge. Die archivierten Deltas enthalten Pfadlisten und den exakten Quellcommit; Blob-IDs lassen sich mit `git ls-tree <sha> <pfad>` reproduzieren.

- `BESTANDSMATRIX.md` und `feature-matrix.json`: relevante Funktionsblöcke mit den zehn verlangten Feldern.
- `app-branches.json.gz`, `godot-branches.json.gz`: alle untersuchten Heads und vorhandene/abweichende Dateien.
- `dart-import-and-test-index.json.gz`: jede Dart-Datei, mögliche Importkette und direkt referenzierende Tests. **Importkette ist keine Klickfreigabe**; die konkreten Navigationsbefunde stehen in der Bestandsmatrix.
- `app-assets.json.gz`, `godot-assets.json.gz`: Pfade, Blob-IDs und wörtliche Referenzen. Dynamische Manifest-/Verzeichnisaufrufe können ohne Literal funktionieren. Fehlendes Literal allein beweist keine ungenutzte Grafik.
- Alle19 angehängten Quelldateien wurden zusätzlich mit SHA256, ZIP-Dateilisten, Dartquellen bzw. HTML-Element-/Funktionsindex erfasst (`attachment-inventory.json`). HTML-/MVP-ZIPs sind historische Design-/Prototypquellen. Sie werden nicht über die vorhandene Produktionsarchitektur gelegt.

Eine vollständige Funktionsfreigabe jedes Unterrichtsthemas, jedes Spiels und jeder visuellen Referenz ist durch die statische Vollinventur nicht belegt. Ungeprüfte Funktionen werden als solche geführt. Am13.10.2026 hat Heinz die spätere Gesamt-APK ausdrücklich freigegeben, sobald Integration/Prüfung abgeschlossen sind; vorhandene alte Runtime-Nachweise sind separat, nie als Nachweis für neue Commits zu übertragen.

## Nachgewiesene offene Punkte

1. **Geschichten speichern:** Reader `_showFinish` ruft `addStory` ohne `await` auf und meldet unmittelbar Erfolg. `save` ignoriert den bool-Erfolg von SharedPreferences. Doppelte Abschlussaufrufe sind nicht gesperrt. Vorhandener Auditzweig wartet zwar, behandelt aber fehlgeschlagenes Speichern/Wiederholung nicht vollständig.
2. **Geschichten-Antworten und Bilder:** Die als Livebilder kommentierte Seitenillustration ist tatsächlich nur ein Buch-Emoji in einer Farbfläche; `imagePrompt` wird dort nicht gerendert. `_onAnswer` vergibt Sterne/XP, protokolliert aber keine `SkillRecord`-Antwort. Zusammenfassung nutzt vierbuchstabiges Stammmatching; das ist keine belastbare fachliche Richtig/Falsch-Bewertung. Auditzweig würde dieses Matching als korrekte Leseleistung zählen; dieses Delta wird nicht ungeprüft übernommen.
3. **Geschichten-Einstiege:** Freie Bibliothek ist über Home → „Mehr mit Lumo entdecken“ → Magic Hub → Geschichten erreichbar. Direktes Home-/Deutsch-/Lernpfadangebot fehlt an der Basis. Der optionale Filter und die feste Setupklasse sind vorhanden, aber nicht durch die Akademieroute angeschlossen.
4. **Lern-DNA:** Feste Stärken `0.78/0.82/0.74`, künstliche schwächenbasierte Scores und Confidence-Werte. `recentProgress` nennt kumulierte Antworten „Heute“ und Sterne „Streak“. Echte `SkillRecord`-Daten stehen über `learningSkills()` bereit.
5. **Insight:** `state.solved` wird als `recentCorrect` übergeben, `recentHelpUsed: 0`, `totalSessions: 1`. KI-Prompt verlangt Wochenereignisse ohne zeitlich begrenzte Antwortdaten. Fehlerrepository ist namensgebunden; vor Darstellung profilgebundene Quelle benutzen.
6. **Unterricht:** 20 Topic-IDs haben hochwertige Spezialmodule. `_openTopic` nutzt andernfalls `LumoTeacherScreen` (Chat). PR281/Auditzweig enthalten Alternativrouten; Spezialmodule bleiben erhalten. Höhere Klassen öffnen derzeit den expliziten Discovery-Hub, ohne Profilklasse zu verändern.
7. **Meister/Belohnung:** Basis hat 15 Fragen; PR282 besitzt 20-Fragen-Deltas. `family_park` kostet an der Basis **30.000** Sterne statt der geforderten 5.000. Vor Übernahme Auszahlungs-/Mehrfachtipp-/Walletregressionen prüfen, Elternfreigabe erhalten.
8. **Schreibcoach:** Wortmodus und Fortschritt sind aktiv; ML Kit Digital Ink und Blatt-OCR bleiben ausgeschaltet. Nicht gleichsetzen mit fehlendem vorhandenen geometrischem Fingercoach. Spender-S/C/H/O-Deltas separat testen.
9. **Godot:** Animiertes GLB, Adapter, Flotte, Garage, kreative GLBs und umfangreiche Szenen-/Rennprüfungen sind vorhanden. Alte Sulafat-/Premium-Menü-Zweige enthalten keine fehlenden Produktionspfade gegenüber Pin65. Aufwendigere Gestaltung ist keine Freigabe aus Standbildern. Pin bleibt erhalten.
10. **Weitere Datenrisiken:** Geschichtenbibliothek verwendet globalen Schlüssel `lumo_story_library_v1`; Spieleprogression leitet `_childId` aus Name/Schulstufe ab. Das sind keine neuen Fehlernachweise durch einen Profilwechseltest, aber konkrete Prüfaufträge. Eine Profilmigration braucht zuerst Kompatibilitäts-/Bestands- und Zuordnungstests; kein stilles Verschieben alter Hefte.

## Priorisierter Reparaturplan

| Prio | Block | Übernahme/Umfang | Abnahme |
|---|---|---|---|
| P0 | Geschichten-Speicherabschluss | Einzelnes Delta aus Audit, ergänzt um Fehler-/Doppelausführungsschutz | Langsames Schreiben, false/throw, Wiederholung, Zurück, Altbestand; Profil-/Filterregressionen |
| P0 | Profil-/Sternrisiken | Bestehende Lease-/Walletarchitektur erhalten; globalen Story-/Name-Spielschlüssel testen | Zwei gleichnamige Kinder, Klassenwechsel, Reset, Relaunch, keine doppelte Auszahlung |
| P1 | Vorhandene Geschichten anschließen | Home/Deutsch/Lesen/Lernpfad selektiv aus Spendern | Echte Navigation bis Reader, freie/feste Schulstufe, Leerzustand, Antwortpersistenz |
| P1 | Lern-DNA/Insight | SkillRecord statt Beispielstärken; Gesamtzeitraum statt falscher Wochenbehauptung | Null/kleine/große Stichproben, Profilwechsel, Prompt, Elternfreigabe |
| P2 | Unterrichtsrouten | PR281-Routen einzeln; kein Ersatz hochwertiger Module | Jedes Thema Klasse1–4 startet passende Aufgabe, Zahlenraum, Hilfe, Feedback, Speicherstand |
| P2 | Schreibcoach/Stimme | Vorhandene lokale Erkennung/ONNX/Sulafat erhalten | S/C/H/O, wacklige Linien, Wortdiktat, wiederholte Sprache, Offline-/Berechtigungsfehler |
| P2 | Lumo-Meister | PR282 nur konkrete 20-Fragen-/Joker-/Final-/Sternregel-Deltas | Komplette Runde, sichere Stufen, 5.000-Sterne-Regel, Deduplizierung, Neustart |
| P3 | Premium-Heatmap/Fold | PR281-Design selektiv; vorhandenen dunklen Elternbericht schützen | echte Werte, Außen/Innen, große Schrift, Rotation, Screenshotvergleich |
| P3 | Kart/weitere Spiele | Read-only Inventur zuerst, separate Godot-Szenenprüfung vor Pinentscheidung | Start/Rennen/Drift/Items/Finish/Host-ACK/Pause/Fold/Rückkehr/Offline |
| P4 | Android-Gesamtabnahme | Freigabe liegt seit13.10 vor; erst nach geprüfter Integration | Update/Signatur/ARM64/API35+36/Offline-Stimme/PCK/Profile/Fold |

## Nächste Android-Gesamtabnahme (Freigabe liegt vor, noch kein Build)

- Android-Host wird über `scripts/prepare_android.py` und `scripts/build_unified_apk.sh` vorbereitet. Paket aus dem tatsächlich erzeugten Gradlehost und vorhandenen installierten Manifesten lesen; erwartete bisherige Produktlinie `dev.ullmann.lumo.lumo_lernen.coachpreview` anhand des tatsächlich gewählten Flavors verifizieren.
- Vor Build Buildnummer gegen alle bereits ausgelieferten Kandidaten und Reservierungen prüfen, Signaturzertifikat mit vorheriger APK vergleichen; keine neue Kennung/Signatur erzeugen.
- Exakte App-SHA, Godot-Pin und Engine vor Build festschreiben. Eingebettetes PCK und native ONNX-Komponenten/Modelle/HASHs kontrollieren.
- Bestehende Installation mit mehreren synthetischen Profilen, Sternen, Freigaben und gespeicherten Heften **aktualisieren**, nicht nur Neuinstallation testen. Keine realen Kinderdaten in Artefakte.
- Flugmodus: Unterricht, Geschichte, Fingercoach, lokale Stimme und Kart; Onlinefunktionen nur nach bestehender Elternfreigabe; keine neue kostenpflichtige Aktivierung.
- API35/API36-Emulator: vollständige Unterrichts-/Story-/Meister-/Kartketten plus Abbruch/Wiederaufnahme/Rückkehr und einmalige Walletbuchung.
- Sichtbare echte Android-Aufnahmen: Home, Akademie, Verständnisfrage, Speicherabschluss/Fehler, Elternprofil, Heatmap, Schreibcoach, Garage/Rennen/Ergebnis.
- Fold außen/innen, Rotation/Resize, Textskalierung1.0/1.3/2.0 und große Touchflächen; physischer Fold-Leistungstest getrennt von Emulatorlayouttests. Keine FPS-Aussage ohne Messung.
- Originalprotokolle/Exitcodes/Skips und SHA256 für die **exakte** APK sichern. Gesamtfreigabe erst nach dokumentierter Abnahme und Heinz' Entscheidung.

## Offizielle Lehrplanquelle

Am 13.10.2026 gelesen: [BMB – Volksschul-Lehrplan](https://www.bmb.gv.at/Themen/schule/schulpraxis/lp/lp_vs.html), mit Verweis auf den neuen RIS-Lehrplan; [RIS – geltende Fassung](https://ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275). Die schrittweise Einführung seit2023/24 ist belegt. Eine vollständige fachliche Zuordnung aller Lumo-Aufgaben zu Kompetenzen/Schulstufen bleibt Gegenstand der Unterrichtsabnahme; keine pauschale Lehrplankonformität behauptet.

## Laufender Reparaturstand

[Geschichten-PR288](https://github.com/Ullmann27/lumo-lernen/pull/288) ist auf`086eb42ab7b834050f1f345b52cb3e811d816748` technisch geprüft:1458PASS/117SKIP/24Infos, Actions38384915173. Verzögerte/fehlgeschlagene Speicherung, Wiederholung, Altbestand, Seitenwechsel und Rückkehr zur Bibliothek repariert. Ausführlicher Bericht:`GESCHICHTEN-PRUEFBERICHT.md`, Originalprotokoll und echte Widget-Captures beigefügt. Die Basismatrix bleibt als ursprünglicher Ist-Befund erhalten; das ist keine Aussage über noch offene Storyantwort-/Home-/Bildintegration.

[DNA-PR290](https://github.com/Ullmann27/lumo-lernen/pull/290) bearbeitet den nächsten getrennten Block; Ergebnisse erst für den tatsächlich geprüften Head. Zusätzliche19 Uploads sind im Attachmentindex erfasst. [ASTRA-ANBINDUNG.md](ASTRA-ANBINDUNG.md) beschreibt den erneuten tatsächlichen Quellvergleich und die jetzt vorliegende APK-Freigabe.

Der Lern-DNA-/KI-Elternanalyseblock ist auf `fe3778847c88c35a40e99ae5012c1f160680b908` technisch grün: 1.476 PASS / 117 SKIP / 24 Infos, Actions 38394508328. Vollständige Provenienz, korrigierte Testvorbereitung und verbleibende Grenzen: `LERN-DNA-PRUEFBERICHT.md`. Der bestätigte Godot-Pin-Nachweis und die abweichenden Merge-CI-Quellen sind getrennt in `GODOT-PIN-NACHWEIS.md` dokumentiert.
