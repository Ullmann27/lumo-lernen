# 2031: konkrete Abnahmefälle und Nachweisgrenzen

## Quellen und aktueller Laufstatus

- **Unveränderte APK:** `e05a96a52aaf57e466e79831f15aaffd144284ee`, Version `0.13.19+2031`.
- **Native Quelle:** `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.
- **QA-Quelle von Vollreplay 4 und Zusatzlauf 3:** `ae6c27c81d41342179a0bf6e60fedbcafacb63a4`, Tree `52e8fc78e7cd17781a567d64d7b311e1f45ce874`. Beide aktiviert am 16.11.2026 um 06:52:23 UTC. [Exakte Quellen-/Aktivierungsbindung](evidence/replay_attempt4_integration_20261116/README.md).
- **QA-Quelle des getrennten Zusatzlaufs 4:** `7b811531ecd3034c0689edd3b39e44223d966857`, Tree `5a71668c9a912ae5a514843b8a4521ab246258b5`; aktiviert am 16.11.2026 um 07:17:13 UTC, tatsächlich FAIL um 07:24:25 UTC.
- **Getrennte Publikationsquelle:** `7270fbb7e9d496e91df18cedd0776a5d4f9a3c85`, Tree `3f76a3bbe5c4d7afe0fe3418efd8840991995397`; [Run 43823660756](https://github.com/Ullmann27/lumo-lernen/actions/runs/43823660756) von 07:24:43 bis 07:27:52 UTC **SUCCESS**. Herkunfts-/APK-/Tourprüfung, neue Veröffentlichung und anonymer vollständiger APK-Download sind bestätigt.

| Lauf | Auftrag | Zuletzt dokumentierter Status |
|---|---|---|
| [Vollständiger Replay 4: 43819768411](https://github.com/Ullmann27/lumo-lernen/actions/runs/43819768411) | Frische vollständige Originaltour, anschließend vollständige native Referenztour an denselben APK-Bytes | **SUCCESS**, Job 133139916895, Abschluss 07:16:35 UTC; Original, Referenz und kombinierter Ergebnisprüfer jeweils **PASS_WITH_LIMITATIONS** |
| [Zusatzlauf 3: 43819768114](https://github.com/Ullmann27/lumo-lernen/actions/runs/43819768114) | Vier zusätzliche Laufzeitfälle auf frischer Installation | **Gesamt-FAIL**, beobachtet um 07:05 UTC: `Current visible Flutter text missing: Dein Lernatelier`, vor Beginn des Bridge-Stoppfalls. Zahlenkorrektur, aktiver Wechsel und nativer Banane-Langsamer-Fall sind separat aus Originalen bestätigt. |
| [Zusatzlauf 4: 43822740773](https://github.com/Ullmann27/lumo-lernen/actions/runs/43822740773) | Vier getrennte Zusatzfälle mit korrigiertem Akademieübergang | **FAIL**, Job 133149336951, Abschluss 07:24:25 UTC; Vorher-Aufnahme vor der ersten numerischen Fehlantwort scheitert an der Bereitschaftsprüfung. Hintergrund in den Kandidaten, Lumo erst in späterer Fehleraufnahme; Ursache offen. Kein Zusatzfall dieses Runs abgeschlossen. |

Diese Karte beschreibt die tatsächlichen Probeaufrufe und erforderlichen Belege. Sie erklärt laufende oder fehlgeschlagene Läufe nicht für bestanden. Der Zusatzlauf ist ausdrücklich `immutable-runtime-cases`, Schema `lumo.nextgen.runtime_cases.android`, mit `release_eligible=false` und `original_probe_requirement_satisfied=false`. Er ersetzt keine vollständige Tour oder Veröffentlichungsfreigabe.

**Öffentliche ARM64-Test-APK:** [Lumo-Lernen-Neu-0.13.19-2031.apk](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.19-2031/Lumo-Lernen-Neu-0.13.19-2031.apk). Der vorhandene Originalbeleg bestätigt am **07:27:47 UTC** HTTP 200 ohne Authorization-Header, vollständige **535.026.362 Bytes** und SHA-256 **`e6ca8e512ddc56755ae8664b3438b0e78b87a7f0e77f1cd55cac592b20b316d7`**. Release **446720910**, Asset **753897981**, Tagquelle **e05a96a**. Die Veröffentlichung ist kein Ersatz für die weiterhin fehlende aktive native Stoppabnahme oder eine vollständige Modernisierung. [Anonymer Voll-Downloadbeleg](evidence/ci-2031-publication-verified/original/publication-proof/PUBLIC-DOWNLOAD-VERIFIED.json).

## Ergebnisdateien und Herkunft

- Vollständige Originaltour: `android/original-android/learning-android-result.json`.
- Anschließende Referenztour: `android/reference-android/reference-android-result.json`.
- Getrennte Zusatzfälle: `android/runtime-cases/runtime-cases-result.json`.

Diese Pfade sind relativ zum jeweils tatsächlichen Run-Artefakt. Jeder Ergebnisstatus wird gemeinsam mit Run, QA-Commit, APK-Identität, Job, Artefakt und Hashmanifest ausgewertet. Dateinummern entstehen im jeweiligen Lauf. Nachfolgende Rohbelegnamen bezeichnen Tagbestandteile; alte Nummern oder Medien werden nicht als neue Aufnahmen eingesetzt. Auch ein Gesamt-PASS würde ausschließlich die wirklich ausgeführten Gates bestätigen.

**Vollreplay 4 ist jetzt an echte Originale gebunden:** Artefakt **14204544628**, ZIP **136.444.327 Bytes**, SHA-256 **`4becebd332755f1046d945f61dcfcf4317316d617d568c685576edcd69bcee9f`**. Originaltour **06:55:37–07:04:22 UTC**, Referenztour **07:04:22–07:16:25 UTC**. Ihre Resultat-SHA-256 sind **`ab8f1e2750993d4e4436b1d7e7f10fd5e51128397bf76cbb8f2e6c854b2854ea`** und **`1063cd4c28556952ee9604f0fc968113c9f5b053c97e81bd2e779092bfdb919f`**. Der unveränderte `verify_2031_tours` bestätigte die vorhandenen Resultate zusätzlich. [Unabhängige Bindung](evidence/ci-2031-complete-replay-verified/independent-result-verification.json), [Originaltour](evidence/ci-2031-complete-replay-verified/original/android/original-android/learning-android-result.json), [Referenztour](evidence/ci-2031-complete-replay-verified/original/android/reference-android/reference-android-result.json).

Die Originaltour registriert **34 Screenshots und 14 Videos**, die Referenztour **18 Screenshots und 12 Videos**. Das sind Medienzahlen dieser tatsächlichen Abläufe und keine zusätzlichen getesteten Aufgabenvarianten. Die frühere fehlgeschlagene Androidstufe im ursprünglichen Buildrun bleibt FAIL.

## 1. 8 + 5 und „Warum zuerst zwei?“

**Vollständiger Replay:** In der Flutter-Zehnerbrücke wird die konkrete Frage in den eigenen Aufgabenkontext getippt. Nach der Rückkehr muss der erste tatsächlich angebotene eigene Stein-Tipp `moved=1` speichern. In der passenden geführten nativen 8+5-Aufgabe wird nach sichtbarem Reset die Frage über das beobachtete Godot-Eingabefeld gesendet. Die Erklärung muss selbst von **0 / 5 bewegt** auf **2 / 5 bewegt** wechseln; danach werden keine manuellen Bewegungstasten zur Erfüllung dieses Gates verwendet.

**Belege:** `conversation`, `bridge.checkpoint`, `native_learning.why_question`, insbesondere `observed_initial_moved`, `observed_final_moved`, `manual_move_buttons_pressed_after_question`, `response`, `playback` und Video. Rohbelege unter anderem `why-native-written-before-send`, `why-native-two-moved-by-explanation`, `native-why-two-result.json` und `native-speech.txt`.

**Ergebnis Vollreplay 4:** Flutter speichert den ersten Stein-Tipp als `moved=1`. Die native Erklärung wechselt tatsächlich von 0 auf 2 bewegte Objekte, ohne nachfolgende manuelle Bewegungstaste oder Bewertungsaufruf. Neue Player-ID **19**, Native-PID **7245**; Video `0402-native-why-two-question-and-demonstration.mp4`, aktuelle Frage-/Antwortbilder 0410/0415/0426.

**Grenze:** Die Frage ist getippt. Die automatische native Bewegung ist ein Erklärungsmodell, keine bewertete Antwort. `acoustic_words_verified=false` bleibt maßgeblich.

## 2. Banane wiederholen

**Vollständiger Replay:** Die Flutter-Wortwerkstatt baut Ba/na/ne und bedient Silbenaudio, Stopp und Wiederholung. Die native Referenz öffnet die spezialisierte geführte Banane-Szene, verlangt drei sichtbare Silbenschritte und bedient **Noch einmal** innerhalb des tatsächlich beobachteten Fragepanels. Dafür sind vier neue, geordnete und vollständig abgeschlossene native Wiedergabesegmente erforderlich.

**Belege:** `word.checkpoint.tokens`, `banana.steps`, `banana.repeat_playback.segments=4`, `utterance_ids`, `repeat_video` und `preservation`. Vollständige umgebrochene Texte müssen aus demselben frischen Bild und derselben OCR-Variante hervorgehen.

**Ergebnis Vollreplay 4:** Alle drei Silbenschritte samt vollständigem Endstatus **Das Wort hat 3 Silben** sind beobachtet. Die Wiederholung liefert vier neue geordnete Player-Paare **19, 20, 21, 22 in PID 9377**. Belege: Schritte 0128/0134/0141 und `0159-banana-four-segment-repeat.mp4` mit **39,384733 Sekunden** positiver Dauer. `native_answer_submitted=false` bleibt bestehen.

**Grenze:** Banane/Ba/na/ne ist die Zuordnung des Quellvertrags zu den Segmenten. `segment_words_verified_acoustically=false`; die Videos enthalten keine Audiospur. Ein sichtbarer Text allein belegt keine gesprochene Wiedergabe.

## 3. Banane langsamer

**Vollständiger Replay:** Der vorhandene Flutter-Weg bedient **Langsamer** in der Wortwerkstatt und anschließend Stopp. Daraus folgt kein nativer Langsamer-Nachweis.

**Zusatzlauf:** Die native Banane wird geöffnet; genau ein beobachteter Fragen-Tap führt zum Panel. Erst nach echtem Hintergrund, Header, passenden Shortcut-Geschwistern und zwei stabilen Frames wird **Langsamer** innerhalb dieses Panels bedient. Vier neue native Start-/Abschluss-IDs und unveränderter Aufgaben-/Modell-/Lernbestand sind erforderlich.

**Belege:** `native_runtime_cases.banana_slower`, insbesondere `playback`, `model_before`, `model_after`, `preservation` und `video`. Erst das tatsächlich geprüfte Teilresultat darf als abgeschlossen gelten.

**Aktuell belegt:** Zusatzlauf 3 meldet für diesen Fall **PASS_WITH_LIMITATIONS**. Das originale Sprachlog enthält vier neue geordnete MediaPlayer-Start-/Abschlusspaare **7–10 in PID 6407**, Profil `lumo-free-supertonic-de-v1`. Vorher-/Nachher-Modell: **0 / 3 bewegt**. Die Rohlogpaare und Originalmedien wurden zusätzlich geprüft. [Teilfallnachweis](evidence/ci-2031-runtime-cases-academy-navigation-failure/verified-completed-subcases.json).

**Grenze:** `actual_rate_in_log=false` und `acoustic_speed_verified=false`. Belegt sind die langsamer gewählte Aktion und vier zugeordnete Player-Segmente, keine gemessene akustische Geschwindigkeit. Das 64,066222 Sekunden lange Originalvideo hat keine Tonspur. Die im Androidresultat aufgezeichnete Profilerhaltung wurde bei dieser zusätzlichen Teilprüfung nicht nochmals aus allen Preferences rekonstruiert. Der anschließende Navigationsfehler lässt den Gesamtlauf FAIL bleiben.

## 4. Muster fortsetzen und Hinweis

**Vollständiger Replay:** Flutter bedient die vorhandene Hilfe. Die native Referenz liest die aktuelle Core-Musterfrage, öffnet deren sichtbaren 3D-Einstieg, bedient **Gruppe entdecken** und verlangt den Hinweis zur kleinsten wiederkehrenden Gruppe mit neuer Wiedergabe. Sie wählt eine Form und kehrt zunächst ausdrücklich ungewertet zur identischen Aufgabe zurück.

**Belege:** `pattern.task.sequence`, `period`, `observed_group_hint`, `hint_playback`, `native_proposal`, `native_confirmation_performed=false`, `returned_task` und `preservation`.

**Ergebnis Vollreplay 4:** Die tatsächliche Folge lautet **Quadrat – Stern – Quadrat – Stern**. Der Hinweis **Die kleinste Gruppe hat 2 Zeichen** und neue Player-ID **7 in PID 10900** sind belegt. Quadrat wird als nativer Vorschlag gewählt; der Rückweg zeigt die identische Frage und bleibt ungewertet. `core_answer_submitted=false`, `core_submission.status=NOT_EXERCISED`: Die erforderliche gleichzeitige eindeutige Core-Antwortüberschrift mit vier aktiven Karten wurde nicht beobachtet.

**Grenze:** Geprüft ist dieses konkrete Klasse-1-Muster mit kleinster Periode 2. Eine abgegebene fachliche Core-Antwort wird nicht behauptet. Der optionale vorhandene Core-Antworttap dürfte nur bei `core_answer_submitted=true` sowie tatsächlichem `core_submission.status=PASS` als ausgeführt berichtet werden. Es wird kein zusätzlicher Bestätigungsschritt erfunden.

## 5. Fachlich falsche numerische Antwort

**Zusatzlauf:** Nach der ungewerteten 8+5-Bauphase geht der reale UI-Weg in den freien Abruf **9+7**. Die Probe tippt **15** und betätigt ausdrücklich **Antwort prüfen**. Ein neuer gespeicherter falscher Versuch, richtige Frage/Erwartung, eigener Versuchsschlüssel und passende Supportdaten müssen vorliegen.

**Belege:** `numeric_wrong_then_correct.wrong`, einschließlich `checkpoint_before`, `checkpoint_after`, `verification.stored_attempt`, `lab_attempt_id`, Journey-Deltas, Screenshot und Video. Eine bloß editierte Eingabe genügt nicht.

**Aktueller Fallstand:** Die echte 15-Abgabe ist aus Zusatzläufen 2 und 3 gesondert belegt. Zusatzlauf 4 hat sie nicht ausgeführt: Die Vorher-Aufnahme bricht ab, bevor 15 eingegeben oder **Antwort prüfen** betätigt wird. Seine zwölf bytegleichen Kandidatenbilder zeigen den Android-Hintergrund ohne Lumo und liegen mit 2,791 Bits unter der 3,0-Bit-Bereitschaftsschwelle. Erst die spätere Fehleraufnahme zeigt die lesbare 9+7-Seite. Die Ursache dieses unterschiedlichen Aufnahmezustands bleibt offen. Der Lauf bleibt FAIL und liefert keinen weiteren numerischen Bewertungsnachweis.

**Grenze:** Die bewertete Aufgabe ist 9+7; das 8+5-Demomodell hat einen anderen Zweck. Die falsche Kreiswahl der Originaltour ist weiterhin nur ein ungewerteter Modellkandidat und ersetzt diesen numerischen Fehlversuch nicht.

## 6. Korrektur einer Antwort

**Zusatzlauf:** Nach dem falschen 15-Versuch wird **16** eingegeben und erneut über **Antwort prüfen** fachlich abgeschickt. Der zweite gespeicherte Versuch muss eine eigene Identität haben. Die richtige Antwort zählt als unterstützt, weil bereits eine Fehlantwort vorlag; unverändert übernommen werden der bisherige Lernbestand und die konkreten Support-/Journey-Bezüge.

**Belege:** `numeric_wrong_then_correct.corrected` mit getrenntem gespeichertem Versuch, `verification`, Checkpoint und Video.

**Aktueller Fallstand:** Die 16-Korrektur ist aus Zusatzläufen 2 und 3 belegt. Zusatzlauf 4 erreichte weder die vorausgesetzte falsche Abgabe noch diesen Korrekturschritt.

**Zusätzlicher Originalweg:** Beim Muster wird nach Kreis und Hinweis Dreieck gewählt; `patternChoice=0` beziehungsweise `1` wird gespeichert, ohne dadurch automatisch eine Bewertung/Belohnung auszulösen.

**Grenze:** Beides sind echte manuelle Korrekturen. Eine gesprochene Korrektur oder eine Korrektur nach fehlerhafter Spracherkennung ist damit nicht belegt.

## 7. Verhörte gesprochene Zahl

**Nicht durch diese Touren abgedeckt.** Die Originalprobe fordert das Mikrofon über echte UI an, bedient gegebenenfalls die beobachtete Berechtigung und unterscheidet tatsächliche Listening-/Limitation-Zustände. Sie liefert keine echte Äußerung und manipuliert kein Erkennungsergebnis.

**Belege der begrenzten Mikrofonprüfung:** `conversation.recognition=NOT_VERIFIED`, `microphone_ui_outcome`, `recognition_observations`, `recognition-services.txt` und `microphone-observation.json`.

**Ergebnis Vollreplay 4:** `microphone_request_observed=true`, `microphone_ui_outcome=explicit_device_limitation`, `postgrant_explicit_start=false`. Die UI weist auf nicht bestätigte deutsche Spracherkennung hin. Daraus folgt weder ein begonnenes Listening noch eine erfolgreiche deutsche Erkennung.

Ein getipptes 15 mit anschließender 16-Korrektur ist kein Nachweis einer verhörten Zahl. Ein deutscher Bereitschaftstext ist allein ebenfalls kein Listening- oder Erkennungserfolg.

## 8. Stopp während Wiedergabe

**Vollständiger Replay:** Sichtbare Flutter-Stopp-Aktionen müssen angehaltene Erklärung beziehungsweise entsprechende Rückmeldung und dieselbe Aufgabe zeigen; nach Mikrofonanforderung wird der Aus-/Startzustand kontrolliert. Diese Flutter-Schritte fordern nicht unmittelbar davor jeweils einen belegten aktiven Audiostart.

**Zusatzlauf:** In der nativen Zehnerbrücke wird eine aktuelle aktive Wiedergabe anhand eigener PID, erwarteten Profils und neuer Start-ID belegt. Der sichtbare Knopf **Stimme stoppen** wird einmal direkt bedient. Danach werden der frische Rückkehrknopf **Schritt anhören** und ein Beobachtungsfenster von mindestens fünf Sekunden verlangt.

**Belege:** `native_runtime_cases.bridge_active_stop`, insbesondere `active_before_stop`, `stop_touch`, `returned_voice_control`, `observation_seconds`, `no_late_new_segments=true`, `active_id_completed_after_stop=false` und Video.

**Aktueller Stand:** Die Flutter-Stopp-Aktionen sind Teil des erfolgreichen Vollreplays 4. Der zusätzliche aktive native Stoppfall bleibt offen: Zusatzlauf 3 brach beim Übergang davor ab; Zusatzlauf 4 scheiterte bereits vor der ersten numerischen Fehlantwort. Keine der beiden Unterbrechungen wird als Stoppnachweis gewertet.

**Grenze:** Ein erfolgreicher Zusatzfall würde sichtbare Zustands- und tatsächliche Player-Ereignisse innerhalb eines endlichen Fensters belegen. Kein akustischer Stillstand, kein millisekundengenauer Zustellzeitpunkt und kein gemeinsamer Mund-/Gestenstopp werden daraus abgeleitet.

## 9. Aufgabenwechsel während aktiver Antwort

**Zusatzlauf:** AutoRead wird über echte Einstellungen ausgeschaltet und gespeichert, damit die ausdrückliche Silbenwiederholung erhalten bleibt. Banane wird korrekt gebaut. Bei unveränderten 1080×2340 Pixeln wird vorübergehend 320 dpi eingestellt; echte WM-/PNG-/Checkpoint-/Profildaten binden Vorbereitung und Rückstellung.

Vor genau einem Replay müssen drei Silben, Next und Replay gemeinsam in einer frischen Ansicht sichtbar sein. Danach muss ein weiteres frisches XML gleichzeitig eine aktive Silbe und **Jetzt selbstständig antworten** enthalten. Das vollständige Intervall vom XML-Erfassungsbeginn bis zum angeforderten Next-Tap darf höchstens eine Sekunde betragen; die Aktivsuche bleibt auf 45 Sekunden begrenzt. Es gibt keinen vorherigen Stopp zur Herstellung dieses Falls. Die neue Aufgabe muss `word-rakete` in `recall` unbeantwortet zeigen, ohne zusätzlichen Versuch oder Belohnung; die alte Aktivmarkierung muss weg sein.

**Belege:** `flutter_switch_during_syllable_playback.observation`, `capture_to_touch_seconds`, `replay_preparation`, `checkpoint_before/after`, `verification`, `viewport` und Video. Ursprüngliche Dichte und AutoRead werden anschließend wiederhergestellt, bevor die nativen Zusatzfälle beginnen.

**Grenze:** Das ist Flutter-Player-Semantik. Tatsächlicher Touch-Zustellzeitpunkt und akustische Ausgabe werden nicht gemessen. Der größere logische Emulatorviewport belegt diesen Fall nicht in der ursprünglichen Dichte oder auf physischer Fold-Hardware. Ein normaler Wechsel nach Stopp wäre kein Ersatz.

## 10. App-Unterbrechung, Rückkehr und Größenwechsel

**Vollständiger Replay:** Für Bridge, Wörter und Muster wird nach vorherigem Stopp einmal Home gesendet. Die Probe bewahrt frische vollständige Activity-Dumps auf und wartet höchstens 15 Sekunden auf einen eindeutigen fremden Vordergrund. Anschließend wird die App gestartet; Prompt, vollständiger Taskcheckpoint, Profil und Lern-/Belohnungsbestand müssen erhalten bleiben.

**Belege:** `foreground_transitions[]`, die jeweiligen `pause_resume`, `route_return` und `checkpoint`, vollständige Activity-Dumps, Vorher-/Nachher-PNGs, Videos und Präferenzen.

**Ergebnis Vollreplay 4:** Für Bridge, Wörter und Muster ist der fremde Vordergrund jeweils tatsächlich als `com.google.android.apps.nexuslauncher/.NexusLauncherActivity` beobachtet, nach **0,167 / 0,115 / 0,168 Sekunden**. Alle drei Pause-/Resume- und Routenrückkehrprüfungen erhalten den jeweiligen vollständigen Checkpoint sowie das Profil und die zwei vorhandenen verglichenen Lernschlüssel. Alle vier folgenden Größenansichten und die abschließende Displayrückstellung erhalten ebenfalls den Bridge-Checkpoint.

Die vier Größenansichten sind **emulierte Layoutkonfigurationen**:

| Layoutname der Probe | Pixel | Android-Dichte |
|---|---|---:|
| compact | 720×1600 | 320 dpi |
| expanded | 1768×2208 | 360 dpi |
| fold7-cover-emulated | 1080×2520 | 420 dpi |
| fold7-inner-emulated | 1968×2184 | 420 dpi |

Die Bridge-Aufgabe und ihr Checkpoint müssen über diese Wechsel erhalten bleiben; jede Aufnahme muss die tatsächliche Größenänderung enthalten und eine positive Dauer besitzen. Die Bezeichnungen sind keine Behauptung eines physischen Fold7-, Scharnier-, Prozesstod- oder Upgrade-Tests. Home während aktiver nativer Sprache ist ebenfalls kein Fall dieses Ablaufs.

## 11. Antwortvorschläge und Bestätigung

Die numerischen Zusatzfälle benutzen den echten vorhandenen Prüfknopf. Die native Musterauswahl bleibt beim Rückweg zunächst ungewertet; der optionale Core-Antwortweg ist getrennt ausgewiesen. Sprach-/Coach-Kandidaten besitzen dagegen ihren eigenen fachlich freigegebenen ausdrücklichen Bestätigungsweg.

Die Tour erzeugt keinen echten gesprochenen Kandidaten. Im tatsächlichen Vollreplay 4 wurde auch der optionale Core-Antworttap nach nativer Musterwahl nicht ausgeführt. Die korrekten Scope-/Owner-/Bestätigungsregeln aus Widget-, Host- und nativen Tests sind deshalb gesonderte Quellnachweise und kein Ersatz für einen tatsächlich gesprochenen Androidfall. Im Prüfungsmodus sind Hinweise und Antwortvorschläge absichtlich gesperrt; Wiederholen, langsamer und stoppen bleiben begrenzte zulässige Hilfen.

## Gesondert geprüfte Teilfälle mit eigener Runbindung

**Zusatzlauf 2, 43816667737, QA `25d4aa1eb3b684eb10e38b4fa7e0270d02e8f9b3`:** Zahlenfehler/Korrektur sowie der Wechsel bei tatsächlicher aktiver Silbenanzeige sind aus Originalen unabhängig bestätigt. Der Wechsel belegte Silbe 1/Ba, gleichzeitig aktiviertes Next, 0,132656392 Sekunden Erfassungsbeginn bis angefordertem Tap, unbeantwortete Rakete und unveränderte Lern-/Belohnungsdaten. 1080×2340 Pixel sowie 440→320→440 dpi und Checkpoint-Erhaltung sind getrennt geprüft.

Der Gesamtlauf bleibt **FAIL** am ersten noch panelfreien nativen Bild. Native Langsamer-/Stoppergebnisse wurden damit nicht bestanden. [Originale und Teilfallbindung](evidence/ci-2031-runtime-cases-native-panel-failure/README.md). Diese alten Originale werden nicht als Resultate von Replay 4 oder Zusatzlauf 3 ausgegeben.

**Zusatzlauf 3, 43819768114, QA `ae6c27c81d41342179a0bf6e60fedbcafacb63a4`:** Die gespeicherten Abgaben 15 falsch und 16 unterstützt richtig besitzen getrennte IDs; der zweite Versuch hat wegen der vorherigen Fehlantwort `hint=true`. Der aktive Wechsel von `word-banane` nach `word-rakete` bleibt in derselben Sitzung und erzeugt keinen zusätzlichen Versuch oder eine weitere Belohnung. Beide vorhandenen Ergebnisprüfer wurden an den Originalresultaten mit exakt gebundenen QA-Quellen erneut ausgeführt. Der native Banane-Langsamer-Fall ist mit den oben genannten vier Player-Paaren und Originalmedien bestätigt; dieser begrenzte Nachweis ist keine akustische Messung.

Die vollständigen Originale dieses Laufs liegen im Artefakt **14204766749**, ZIP **37.623.671 Bytes**, SHA-256 **`660794dab77f440a7af869e60e51bfd310c014706570f37344a3a40447736ee0`**. Der Gesamtlauf bleibt **FAIL**: 0399/0400 zeigen das offene Atelier, 0409 den erneuten Werkzeugbereich-Tap und 0410 den wieder geschlossenen Bereich. **Der native Stoppfall wurde nicht begonnen.** [Originalstatus und Navigation](evidence/ci-2031-runtime-cases-academy-navigation-failure/README.md), [verifizierte abgeschlossene Teilfälle](evidence/ci-2031-runtime-cases-academy-navigation-failure/verified-completed-subcases.json).

**Zusatzlauf 4, 43822740773, Job 133149336951, QA `7b811531ecd3034c0689edd3b39e44223d966857`:** Gesamt-FAIL vor der ersten numerischen Abgabe. Originalfehler: `Flutter 0134-numeric-before-wrong-answer stayed visually unrendered after 12 frames; last entropy=2.791`. Das Ergebnis endet um 07:24:16 UTC, der Job um 07:24:25 UTC. Die zwölf Kandidatenbilder sind bytegleich (SHA-256 **`4f35e9ad513aeb47822ff071fac20b46641347754834d394aac6768d2b180081`**) und zeigen den Android-Hintergrund ohne Lumo; die Heuristik lehnt jedes mit 2,791 < 3,0 Bits ab. Das **spätere** Fehlerbild **0135** zeigt die lesbare 9+7-Aufgabe mit leerem Eingabefeld und Prüfknopf. Daraus darf kein False Negative der früheren Prüfung abgeleitet werden. Belegt sind der Capture-Abbruch und unterschiedliche Aufnahmezustände; deren Ursache ist noch offen. Eine fachliche Fehlbewertung wurde nicht ausgeführt.

Keiner der vier Zusatzfälle dieses Runs ist abgeschlossen; auch der korrigierte Akademieübergang wurde noch nicht erneut erreicht. Die vollständigen **187 Originalmitglieder** sind im Artefakt **14204798832**, ZIP **22.181.444 Bytes**, SHA-256 **`d28a0b855eb8ad8cc5127cac5fa0b453f79999dd98a798ba449bdb72ad6131df`**, erhalten. [Originalresultat](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/runtime-cases-result.json), [erste Kandidatenaufnahme](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/0134-numeric-before-wrong-answer-render-candidate-1.png), [Bereitschaftsprotokoll](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/0134-numeric-before-wrong-answer-render-readiness.json), [späteres Fehlerbild](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/0135-runtime-failure-current-screen.png), [Archivbewahrung](evidence/ci-2031-runtime-cases-numeric-capture-failure/archive-retention.json). Eine enge Diagnose läuft; ein neuer Fix oder Folgelauf ist hier noch nicht behauptet.

## Abschlussdaten und Grenzen

Vollreplay 4 ist vollständig mit `PASS_WITH_LIMITATIONS` ausgewertet. Zusatzlauf 3 bleibt trotz dreier abgeschlossener Teilfälle FAIL; Zusatzlauf 4 bleibt FAIL vor der ersten numerischen Abgabe. Die fehlende aktive Stoppabnahme bleibt offen und wird nicht aus anderen Laufteilen zusammengesetzt. Der getrennte Publikationsrun hat Herkunfts-/APK-/Tourprüfung, neue Veröffentlichung und anonymen Voll-Download erfolgreich abgeschlossen. Diese nachgewiesene Auslieferung ersetzt keine vollständige zusätzliche Fallabnahme.

**Leistungsgrenze des erfolgreichen Vollreplays:** In der nativen 8+5-Szene wurden **49 Godot-`_process`-Intervalle in sieben Fenstern über 36,516349 Messsekunden** bei insgesamt **40,829471584 Sekunden** Szenenbeobachtung gemessen. Mittel **745,2316122448982 ms**, entsprechend **1,3418647083255772 Hz**; **49/49** Intervalle über 16,7 ms. Schlechtester Fenster-P95 und -P99 jeweils **1.015,883 ms**. **14 Samples** in Fenstern 38–40 zeigen gleichzeitig Sprache/Fuchs/Effekt-Zustände. Native-PID **7245**, `gl_compatibility`, llvmpipe LLVM 20.1.2. Das ist eine deutlich langsame Emulator-Prozessmessung und keine bestandene 60-FPS-Abnahme. Kleine Fenster mit 6–8 Samples liefern keine stabile globale P99-Schätzung; Display-Präsentation und akustische Ausgabe werden nicht daraus abgeleitet. [Originale Leistungsdaten](evidence/ci-2031-complete-replay-verified/original/android/original-android/native-learning-performance.json).

Eine erfolgreiche Tour bestätigt weder sämtliche 236 Curriculumfamilien noch alle Aufgabenvarianten, 48-dp-Flächen, physisches Foldverhalten, akustische Wort-/Geschwindigkeitsqualität oder 60 FPS. Generische native Aufgabenkarten sind keine individuellen räumlichen Fachmodelle; die native Figur läuft in einer separaten Activity. `fullModernizationComplete=false` bleibt maßgeblich. Veröffentlichung und anonymer APK-Download sind separat bestandene Gates; ihre vollständige Identität und die verbleibenden Grenzen stehen in [ANDROID_DELIVERY_2031.md](ANDROID_DELIVERY_2031.md).

## Maßgebliche Probequellen

- `.github/probes/lumo_nextgen_learning_android_probe.py`: Originaltour, eigene Aufnahme, Lifecycle-/Erhaltungsgates.
- `.github/probes/lumo_nextgen_reference_android_probe.py`: vollständige Banane-/Musterreferenzen und native Ereignisbindung.
- `.github/probes/lumo_nextgen_current_reference_android_probe.py` und `lumo_nextgen_native_reader.py`: aktueller vollständiger Mehrzeilenleser.
- `.github/probes/lumo_nextgen_2031_replay_reference_android_probe.py`: unveränderliche 2031-Identität und vorausgesetzte vollständige Originaltour.
- `.github/probes/lumo_nextgen_2031_runtime_cases_android_probe.py` und `lumo_nextgen_2031_native_runtime_cases.py`: die vier getrennten Zusatzfälle und ihre Ergebnisprüfer.

Die gemeinsame QA-Bindung von Vollreplay 4/Zusatzlauf 3 und die vorhandenen 230/230 Hostprüfungen sind unter [replay_attempt4_integration_20261116](evidence/replay_attempt4_integration_20261116/README.md) dokumentiert. Die spätere QA-Identität von Zusatzlauf 4 bleibt davon getrennt. Für diese Dokumentationsfassung wurden keine neuen Tests oder Androidaktionen ausgeführt; der vorhandene zusätzliche Ergebnisprüfer-Lauf von Root wird ausdrücklich als Prüfung gespeicherter Originale ausgewiesen.
