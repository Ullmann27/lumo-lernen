# Lern-DNA und Insight: Reparaturbericht

[Draft-PR #290](https://github.com/Ullmann27/lumo-lernen/pull/290) baut auf dem geprüften Geschichten-Commit `086eb42ab7b834050f1f345b52cb3e811d816748` auf. Speicherung, JSON-Formate, Wallet, Pakete, Stimmen und Godot-Pin bleiben unverändert. Kein Main-Merge, Release oder APK-Build in diesem Block. Heinz hat die spätere Gesamt-APK inzwischen ausdrücklich freigegeben.

## Tatsächliche Änderungen

Die Engine verwendet ausschließlich Snapshots der aktiven, profilgebundenen `learningSkills()`/`SkillRecord`-Daten. Fach, Thema sowie richtige und falsche Antworten bleiben getrennt. Die vorgegebenen Beispielstärken, künstlichen Confidence-Werte und erfundenen Sitzungs-, Emotions- und Zeitangaben sind entfernt. Die Quelldatensätze werden nicht verändert.

Trefferquoten erscheinen zusammen mit der Antwortanzahl. Bei null Antworten wird fehlende Datengrundlage angezeigt. Unter zehn Antworten bleibt die Einordnung neutral und wird als kleine Stichprobe bezeichnet. Zehn ist eine vorsichtige Darstellungsregel, kein wissenschaftlich validierter Diagnosegrenzwert. Auch größere Stichproben bleiben Übungsbeobachtungen. Elternkarte, Settings und Heatmap zeigen diese Nachweise; mittlere, kleine und unbeantwortete Themen werden nicht ausgeblendet. Lernempfehlungen bleiben erhalten.

Insight zeigt Gesamtantworten statt kumulierter gelöster Aufgaben als angebliches Heute-Ergebnis. Die bestehende Streakanzeige verwendet weiterhin tatsächlich gespeicherte Tagesdaten. Alte namensgebundene ErrorBreakdown-Werte werden nicht als Daten des aktuellen Kindes hinzugemischt.

Beide KI-Elternanalysen verwenden denselben Prompt mit profilgebundenen Gesamtwerten. Er verlangt keine Wochenereignisse ohne Zeitdaten. Vollständige Themenzeilen werden auf 1.200 Zeichen budgetiert; ausgelassene Themen werden gekennzeichnet. Namen bleiben lokal. Elternfreigabe und ausdrücklich angeforderter Request bleiben erhalten. Profil- und Datenwechsel verwerfen verspätete KI-Antworten.

`ParentReportCard` aktualisiert den Bericht bei Benachrichtigungen, löst dabei aber keinen erneuten Profilladeversuch aus. Dadurch verursacht Speicherfehler → Notify keinen Load-Kreislauf. Die Initialladung bleibt einmalig möglich; eine spätere ausdrückliche Wiederholung bleibt möglich.

Die Bereinigung im `ParentReportCard` betrifft seine KI-Analyse. Der lokale `ParentReportEngine` mit bisheriger Mastery-/Reading-Auswertung ist nicht vollständig evidenzbereinigt. Sein globaler Reading-Bestand und namens-/klassenbasierte `childId` bleiben ein gesonderter P0-Prüfauftrag. Die neue KI-Payload verwendet diese unzugeordneten Daten nicht.

## Tatsächliche Testprovenienz

| Quell-SHA | Actions-Lauf | Ergebnis |
|---|---|---|
| `917320083e13cdaaf790a189558b94996d40be32` | 38386317649 | RED: 1.458 PASS, 117 SKIP, 5 FAIL; neue Profile bekamen drei feste Stärken |
| `02bde6b5f4314edd0db4b70e14697a009e1bd113` | 38388788109 | 1.472 PASS, 117 SKIP, 0 FAIL; 24 Infos; Basis-DNA und Insight-Widgetfälle grün |
| `377da989c738b8e2aa44f71c586bc3f2690d4ad9` / `b2984120c48d6fe2fdb11d48636769dd441dc90d` | 38389564532 / 38390504178 | Abgelöste Zwischenläufe; kein vollständiges Ergebnis übernommen |
| `12458ae55637446b281f034328c15800e34c845f` | 38391156973 | Analyse erfolgreich, 24 Infos; unvollständige Suite mit 1.469 PASS / 117 SKIP vor Timeout- und Folgefehlern; Job nach 25 Minuten cancelled |
| `fe3778847c88c35a40e99ae5012c1f160680b908` | 38394508328 | **1.476 PASS, 117 SKIP, 0 FAIL; Analyse erfolgreich mit 24 Infos** |

Der Lauf für `12458…` blockierte in der erweiterten Testvorbereitung für 80 gespeicherte Antworten: `LearningProfileEngine._saveTail` wurde im pausierten Widget-FakeAsync-Kontext erzeugt und anschließend in `runAsync` abgewartet. Nach zehn Minuten meldete der Widgettest einen Timeout; folgende Tests erhielten Reentrant-runAsync-Fehler. `fe377…` erzeugt auch den Fixture-AppState im echten Async-Kontext. Alle 80 persistierten Antworten sowie die vollständigen acht Themenzeilen, Request-, Consent-, Namens- und Profilprüfungen bleiben bestehen. Kein Produktcode wurde für diese Fixturekorrektur geändert. Der abgebrochene Lauf wird ausdrücklich nicht als bestandene Gesamtprüfung ausgegeben.

Toolchain: Flutter 3.44.9, Dart 3.12.2. Der bestehende Reviewworkflow verwendet:

```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2
```

Neue Tests decken Klasse 1–4, fehlende/kleine/große Stichproben, Themen ohne Daten, tatsächliche Zähler, unveränderte Quelldaten, gespeicherte gleichnamige Profile und Neustart, Live-Profilwechsel, beide KI-Transporte und wirklich verzögerte Antworten, Speicherfehler ohne automatische Wiederholung sowie 360/800 Pixel mit 150 Prozent Schrift ab. Originalprotokolle: `dna-917-RED.log.gz`, `dna-02bde6-GREEN.log.gz`, `dna-124-INCOMPLETE.log.gz`.

## Review und visuelle Grenzen

Der unabhängige Quellreview fand Promptüberlänge und zu hellen Text in neutralen Heatmap-Zellen. Beides wurde korrigiert und durch Tests abgesichert. Nachreview bestätigt Budgetierung, Consent und Revisionsschutz. Weitere konkrete Diffreviews bestätigen die Lade-Kreislaufkorrektur und den echten Async-Kontext der Testvorbereitung. Keiner dieser Reviews führte Flutter aus; die tatsächliche CI bleibt maßgeblich.

Die echten Flutter-Captures zeigen 360/800 Pixel mit 150 Prozent Schrift. Die erste Aufnahme auf `02bde6…` belegt den zu hellen Text. Die Korrektur verwendet `#374151` auf `#F3F4F6` und einen natürlich umbrechenden Titel. Das bestehende cremefarbene Heatmaplayout bleibt vorerst erhalten und ist Kandidat für den getrennten Premiumdesign-Transfer aus PR #281. Diese Aufnahmen sind kein Android-, physischer Fold- oder visueller Gesamtnachweis.

Der letzte Lauf wurde vollständig abgeschlossen. `outcomes.json` aus dem selbst heruntergeladenen Artefakt bestätigt Quell-SHA `fe377884…` und Erfolg von Dependencies, Analyse und Tests; alle drei Befehle Exit 0. Artefakt 11811830843, ZIP-SHA256 `08869c9a14b77e9257f9bd1e93906ed28e1ab9df140f476dccb76871847b3f75`. Neue Originaltests/Analyse und Bilder unter `dna-fe377884-*` bzw. `visuals/fe377884-*`; Bildprovenienz in `visuals/learning-dna-manifest.json`. Die aktuelle 360-Pixel-Aufnahme bestätigt den lesbaren dunklen Text und natürlichen Titelumbruch.
