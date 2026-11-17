# Lumo Lernen + Lumo Kart + Lumo Cards – Stabilisierungsbaseline

Stand: 17.10.2026. **Freeze für Feature-Entwicklung:** keine zusätzlichen Spielwelten, Grafiksysteme oder KI-Funktionen, bis das vorhandene System als Ganzes nachweislich stabil ist.

## 1. Reproduzierbarer Ausgangspunkt

- Flutter-Integration vor diesem QA-Patch: `57d6281696329e0da925e7a66a5811376decdb69`, Version `0.12.56+1968`, PR #342; PR #341 und die geprüfte 1966-Linie liegen in der gemeinsamen Commit-Historie.
- Godot-Quellpin: `61f51b942b2521b506e6b203b89a1b3ec2bd284f`, Godot 4.6.3, Sonnenhafen-Kran in Godot-PR #78.
- Die Version 1967 (ohne den späteren Audio-Test-Patch) hat bereits **verify + apk + android-tour** erfolgreich in [Run 38995207095](https://github.com/Ullmann27/lumo-lernen/actions/runs/38995207095) bestanden; dieser Beleg gilt **nicht automatisch** als finale 1968-Abnahme.
- 1968-Capture-Audioplugin-Fix: Test-only-EventChannel und unübersprungene 18 Screenshots, [Run 38996903829](https://github.com/Ullmann27/lumo-lernen/actions/runs/38996903829) grün. Produktive `audioplayers`-Implementierung bleibt unverändert.
- Der umfassende [Runtime-Test](https://github.com/Ullmann27/lumo-lernen/blob/chatgpt/lumo-stabilisierung-2026-10-17/.github/workflows/lumo-runtime-apk.yml) ist ein zusätzlicher Pflicht-Gate und **nicht** durch einen grünen Flutter-Widgettest ersetzbar.

## 2. Reparaturen in dieser Baseline

1. `tools/android_qa/native_lap_evidence_recovery.py` – veraltete `SOURCE_SHA256` nach dokumentierter Godot-Codeprüfung auf `0fbc839429f52ca4ed07641220b396e1be4ddb5fac250e2faaa2557f9b9d9064` korrigiert.
2. `tools/android_qa/native_handoff_evidence_recovery.py` – identische Korrektur; historische Fixture-Hashes **unverändert**.
3. `.github/workflows/lumo-runtime-apk.yml` – diesen Stabilisierungsbranch zum vorhandenen Push-Gate hinzugefügt. Es muss den **tatsächlich aus `config/godot-source.json` geholten Git-Stand** gegen alle sechs nativen QA-Hashes vergleichen; bei Abweichung rot statt Fake-PASS.

Basis dieser Korrektur: Claudes geprüfter Commit `f3c2ca944db7c994644c752fe80212d67d8fff45` und der unveränderte `kart_island.gd` zwischen Godot `b5f1989` und `61f51b9` (Godot-PR #78 ändert ausschließlich die Kranintegration und Test-/Bilddateien).

## 3. Genealogie – kein erneutes Zusammenkopieren bereits enthaltener Branches

Per GitHub-Commit-Vergleich geprüft: Die **Heads** der PRs #327, #328, #332, #333, #334, #335, #336, #337, #339, #340, #341 sind vollständig Vorfahren des 1968-Integrationsheads (GitHub `behind_by: 0` bei `PR-SHA...1968-SHA`). Diese Quellstände dürfen nicht blind nochmals gecherrypickt werden.

**Noch nicht durch Abstammung geklärt:** PR #320 (divergiert, 7 eigene Commits), PR #331 (Claude-Korrekturen; einzelne Dateien wie Maven-Mirror existieren bereits, der komplette Head ist nicht schlicht Vorfahr), weitere historische PRs, sowie der optionale Cloud-Tutoring-Pilot PR #310. Diese Fälle **einzeln anhand von Diffs, fachlicher Wirkung und Tests** prüfen. Eine historische PR darf nicht allein wegen ihrer Nummer gelöscht oder geschlossen werden.

Godot-PR #78 ist derzeit offen und liefert den exakt gepinnten Source-Stand; sein separater Merge in `lumo-godot/main` ist **keine** Voraussetzung dafür, dass ein SHA-festgepinnter Flutter-APK-Build reproduzierbar ist. Kein Blind-Merge von Godot-Vorgängerbranches.

## 4. Definition „grundstabil“ (Release-Sperren)

Ein neuer stabiler Integrationsstart ist erst zugelassen, wenn diese Punkte mit **derselben Flutter-Commit-SHA und demselben Godot-Pin** belegt sind:

- Flutter `analyze` ohne Fehler, komplette Test-Suite und die für den Branch vorgesehenen Python-/Node-QA-Tests grün; Screenshot-Captures für Telefon, Fold offen/zugeklappt und Querformat.
- Echtes Godot-4.6.3-Import- und native Race-/Lap-/Handoff-/Fahrphysik-Regressionen.
- Exakter Source-Hash-Gate für alle sechs gebundenen Godot-Dateien; bei Source-Update nie ein bloßes Konstanten-Update ohne inhaltliche Review.
- Vollständiger ARM64-Android-Build mit Version, Zertifikat, Paketidentität, SHA-256 und gespeicherten echten APK-Artefakten.
- **Echte** Flutter→Garage→Rennen-GAS-Fahrt: messbare Strecken- und Zeitzunahme und Weltbewegung, HUD, Pause und eingefrorene Session, Rückkehr zur Flutter-Lern-App, Kinderprofil und Lernstand unverändert, App-Neustart.
- Lumo Cards navigierbar, Kinderprofile getrennt; Schreibcoach und Journal bleiben aktiv; Schuljahr/Klassenwahl darf fremden Lernstand nicht überschreiben.
- Keine stillen `skip`-Änderungen an Tests, keine ausgeschalteten Audio-, Speicher- oder Berechtigungsfunktionen, keine erfundene APK-/60-FPS-Meldung. 60 FPS auf realem Fold7 erfordert **separaten Hardware-Nachweis**.

## 5. Bereinigung ohne Datenverlust

- **Erhalten:** `main`, dieser Stabilisierungsbranch, PR-Branches und historische Beweisartefakte bis zum tatsächlichen Merge/Abschluss.
- **Konsolidieren:** Nach grünem Gesamtlauf genau **einen** nachvollziehbaren Integrations-PR Richtung `main` behalten und die abgeleiteten Teil-PRs mit verlinkter Ziel-SHA als „in Baseline aufgegangen“ schließen; bis dahin keine Massen-Schließungen.
- **Abweichungen:** PR #320, #331 und weitere divergierte Branches als individuelle Backlog-Aufgaben dokumentieren; keine automatischen Überschreibungen des neueren Lern-/Android-Standes.
- **Rollback:** immer letztes nachweislich grünes 1967-Build-Artefakt und den vorherigen Git-Commit behalten. Keinen Release verteilen, solange die neue Baseline nicht komplett grün ist.
- **Offen bis zur Abnahme:** Ergebnisse des großen Runtime-Workflows, 1968-Android-Tour auf neuem Branch, reale Gerätetests/FPS auf Fold7 sowie aktualisierte visuelle Prüfung des Sonnenhafen-Krans.

## 6. Neues Entwicklungsfenster

Nach Abschluss der Stabilisierung: eingefrorene Baseline-Version und Git-Tag/SHA schriftlich festhalten; getrennt priorisierten Gameplay-/Grafik-Backlog pflegen; neue Features nur in kleinen PRs mit eigenem Regressionstest und anschließendem zusammenhängendem Android-Rennnachweis. Keine Projekt-„Aufräumaktion“ darf Datenbanken, Profile, Schreibtrainer, Journal oder Kauf-/Belohnungsstände still löschen.
