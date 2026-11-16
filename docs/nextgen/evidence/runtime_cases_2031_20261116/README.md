# Zusätzliche beobachtete Fälle · unveränderte APK 2031

**Stand dieser Übergabe: Python-Prüfer implementiert und lokal geprüft; kein Androidlauf.**
Die beiden neuen Quelldateien liegen auf dem Komponentenbranch
`qa/lumo-2031-lab-runtime-cases-20261116`, Basis
`51a3bfdedf4d6a745fb574ae9186c1094eb11abf`.
Die APK bleibt exakt aus `e05a96a52aaf57e466e79831f15aaffd144284ee`,
Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`, Version 0.13.19/2031.

## Getrennter Zweck und Herkunft

Die neue `RuntimeCasesProbe` erbt die vorhandene `ReplayProbe` und damit den
aktuellen `ReferenceProbe`-Pfad. Ihre eigene `run()` ruft weder die vollständige
Tour noch `reset_successful_original()` auf. Sie verlangt eine eigene frische
Installation auf einem zuvor paketfreien API-35-x86-Emulator, echte Onboarding-
und Einstellungsaktionen sowie die unveränderten 2031-Candidate-, Download-,
Signatur-, installierten SHA- und Quellenprüfer.

Der Runtime-Kontext bleibt `qa/lumo-nextgen-2031-android-20261116`, damit der
unveränderte 2031-Downloader genutzt wird. Root liefert den neuen Workflow und
`.github/probes/lumo_nextgen_2031_runtime_cases.json` separat. Die neue Probe
prüft dessen feste Quellen-/Versionsfelder, die vollständige geordnete
Vier-Fälle-Liste und den positiven ganzzahligen `caseAttempt`.

Ergebnis: `runtime-cases-result.json`, Schema
`lumo.nextgen.runtime_cases.android`, Modus `immutable-runtime-cases`.
`release_eligible`, `original_probe_requirement_satisfied`,
`fullModernizationComplete`, `historical_tour_pass_used` und
`private_app_data_written_by_probe` bleiben false, auch im Fehlerfall.
Der Zusatz ersetzt keine Original-/Referenztour und kein Veröffentlichungsgate.

## Tatsächliche geplante Fälle

- **Falsche Zahl und Korrektur:** 8+5 wird über echte Plättchen gemeinsam gebaut.
  Erst im danach sichtbaren freien Abruf wird **9+7** bewertet: `15` eingeben,
  ausdrücklich „Antwort prüfen“, anschließend `16` und erneut prüfen. Jeweils
  genau ein gespeicherter fachlicher Versuch, unveränderte ältere Versuche,
  passende Aufgaben-/Profilfelder sowie fortgeschriebene Lab- und Journey-IDs
  sind Pflicht. Die zweite Antwort muss als begleitet gespeichert sein. Der
  AttemptLog besitzt eine separate ID; sie wird nicht mit der Lab-ID verwechselt.
- **Aufgabenwechsel während Silbenwiedergabe:** Banane wird über die sichtbaren
  Bausteine korrekt gebaut und geprüft. „Automatisch vorlesen“ wird zuvor per
  echter Einstellung ausgeschaltet: automatisches Modellfeedback würde sonst
  den Silben-Wiederholpfad durch einen Prosasatz ersetzen. Eine ausdrücklich
  gestartete Silbenwiedergabe bleibt so für „Noch einmal“ erhalten. Nur eine
  frische Android-Hierarchie, die gleichzeitig genau eine aktuelle Silbe
  („gerade aktiv“) und den aktiv angebotenen Next-Button enthält, erlaubt den
  einen Wechsel-Tap. Verpasste, verspätete oder mehrdeutige Beobachtungen schlagen
  fehl. Danach sind `word-rakete/recall`, ein leeres Antwortfeld, unveränderte
  Versuchs-/Belohnungsdaten und das Verschwinden der alten Aktivmarkierung nötig.
  Vor Native wird automatisches Vorlesen per echter UI wieder eingeschaltet.
- **Native Fälle:** Das separat von Conversation gelieferte neue Modul
  `lumo_nextgen_2031_native_runtime_cases.py` erhält dieselbe Instanz auf der
  sichtbar erreichten „LUMO AKADEMIE“. Es darf keine Installation/Resets vornehmen.
  Seine eigene Prüfung für Banane-Langsamer und Bridge-Stopp wird zusätzlich
  durch `verify_runtime_cases(result, *, qa_commit, workflow_run_id)` aufgerufen.

## Lokale Prüfung und ehrliche Grenze

`focused-final-14.log`: **14/14 Python-Tests**, 0 Fehler/Skips. Frühere 12er- und
13er-Entwicklungsläufe bleiben separat erhalten und werden nicht addiert.
Die in einem negativen Test gedruckte `status=FAIL`-JSON ist ein ausdrücklich
konstruiertes Eintrittsfehlerszenario, kein Android-Ergebnis.

Die Tests verwenden ausdrücklich konstruierte Zustandsdaten und echte
`xml.etree.ElementTree.Element`-Repräsentationen. Sie prüfen unter anderem
fehlende/doppelte/falsche Bewertungsbuchungen, verlorene Hilfe, fremde IDs,
mehrdeutige/unsichtbare UI, einen tatsächlich zu spät beobachteten aktiven Zustand
und die Weitergabe einer Ablehnung durch den nativen Owner-Validator. Sie
erfinden keine Original-XMLs, Audioereignisse, APKs oder Laufzeitaufnahmen.
Die konkreten nativen Felder prüft der separate Owner; seine Implementierung
ist eine Integrationsabhängigkeit dieses Komponentencommits.

Die Flutter-Aktivmarkierung ist an den wirklichen `VoiceStatus.speaking`
gebunden, aber kein akustischer Beleg oder natives MediaPlayer-Log. Kein
gesprochener/verhörter Zahlenversuch, keine Aussprache-/Geschwindigkeitsmessung,
keine millisekundengenaue Stopp- oder physische Fold-Abnahme wird behauptet.
Der aktuelle vollständige Replay bleibt mit seinem eigenen tatsächlichen
Ergebnis getrennt; historische FAILs werden nicht umgedeutet.

CLI nach Integration der Root-Konfiguration und des nativen Zusatzmoduls:

```sh
python3 .github/probes/lumo_nextgen_2031_runtime_cases_android_probe.py \
  --candidate candidate \
  --download-evidence evidence/download \
  --qa-commit "$GITHUB_SHA" --workflow-run-id "$GITHUB_RUN_ID" \
  --out evidence/runtime-cases
```

Keine vorhandene Probe, Gate-, Produkt-, Pin-, Workflow- oder Publisherdatei
wird durch diesen Komponentencommit geändert. Kein Remoteaufruf oder CI-Start
wurde in dieser Übergabe ausgeführt.

## Enger Nachtrag: Alter der gesamten XML-Erfassung

Der Review des ersten Komponentencommits `9cfa4b0760403ac4b489bea440d3ea6040e09dc0`
fand eine konkrete Messlücke: Der bisherige Zeitstempel begann erst nach
`live_nodes()`. Eine langsam zurückgelieferte aktive Silbenmarkierung konnte
deshalb innerhalb des unveränderten Ein-Sekunden-Frischebudgets erscheinen.

`capture-age-red.log` zeigt den unveränderten Helper mit einem zusätzlichen
konstruierten Transportfall: 1,1 Sekunden XML-Erfassung, danach kein weiterer
Zeitverbrauch. Der erwartete Abbruch fehlte; 14 Tests, genau ein fehlgeschlagener
Subfall. Die getesteten Hashes stehen in `capture-age-red-source.json`; die
exakte Testergänzung ist als `capture-age-red-test.patch` erhalten.

Der Helper beginnt nun vor der XML-Erfassung zu messen und speichert deren
Beginn, Ende und den Zeitpunkt unmittelbar vor dem Aufruf des vorhandenen
Touch-Helfers. `capture_to_touch_seconds` umfasst die gesamte Erfassung,
Auswertung und Hashbildung. Die reine Ergebnisprüfung verlangt endliche,
geordnete Zeitstempel, eine dazu passende Gesamtdauer und höchstens eine
Sekunde. Sowohl das 45-Sekunden-Suchfenster als auch das Ein-Sekunden-
Frischebudget bleiben unverändert. Ein zu langsamer Emulator führt zu FAIL;
die Grenze wird nicht durch einen zweiten Tap oder längere Fristen umgangen.

`capture-age-green.log`: **15/15 gezielte Python-Tests**, keine Fehler/Skips.
`capture-age-source.json` bindet die exakten getesteten Dateien. Die Aufnahme
einer XML-Hierarchie ist weiterhin keine atomare Audio-/Eingabemessung, und der
Zeitstempel bezeichnet den angeforderten Tap, nicht eine gemessene Android-
Eingabezustellung. Es gab keinen Androidlauf, keine Akustikmessung und keine
Änderung gemeinsamer Probe-, Produkt- oder Veröffentlichungsgates.
