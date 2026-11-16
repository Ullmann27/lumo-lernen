# LUMO Lernen 0.13.19 (2031): Liefer- und Abnahmestand

## Aktueller dokumentierter Status

**Die ARM64-Test-APK ist öffentlich verfügbar und vollständig anonym heruntergeladen sowie bytegeprüft. Der vollständige Android-Replay ist erfolgreich abgeschlossen: Originaltour, Referenztour und kombiniertes Ergebnis jeweils `PASS_WITH_LIMITATIONS`. Der zusätzliche aktive native Stoppfall bleibt offen.**

[**Lumo-Lernen-Neu-0.13.19-2031.apk direkt herunterladen — ARM64, 535.026.362 Bytes**](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.19-2031/Lumo-Lernen-Neu-0.13.19-2031.apk)

Der Link liefert eine einzelne APK für den Browserdownload. Die anonyme Vollprüfung am **16.11.2026 um 07:27:47 UTC** meldet HTTP 200, keinen Authorization-Header, vollständig gelesene Bytes und den unten angegebenen SHA-256. Es handelt sich um eine öffentliche **Vorab-/Testversion**, nicht um eine Play-Produktionssignierung. [Unveränderter Downloadbeleg](evidence/ci-2031-publication-verified/original/publication-proof/PUBLIC-DOWNLOAD-VERIFIED.json).

**Stand: 16.11.2026, nach dem erfolgreichen Publikationsworkflow um 07:27:52 UTC.** Vollreplay 4 und der vorherige Zusatzlauf 3 verwenden QA **`ae6c27c81d41342179a0bf6e60fedbcafacb63a4`**, Tree **`52e8fc78e7cd17781a567d64d7b311e1f45ce874`**. Zusatzlauf 4 verwendet dagegen QA **`7b811531ecd3034c0689edd3b39e44223d966857`**, Tree **`5a71668c9a912ae5a514843b8a4521ab246258b5`**, auf demselben QA-Zweig `qa/lumo-nextgen-2031-android-20261116`. Die APK ist in allen genannten Läufen unverändert.

Zusatzlauf 3 bleibt FAIL am Navigationsübergang vor dem Bridge-Stoppfall; seine drei zuvor abgeschlossenen Teilfälle sind gesondert belegt. Zusatzlauf 4 ist **FAIL vor der ersten numerischen Fehlantwort**: Zwölf bytegleiche Kandidatenaufnahmen zeigen den Android-Hintergrund ohne Lumo und erreichen die Bereitschaftsschwelle nicht. Erst die spätere Fehleraufnahme 0135 zeigt die lesbare 9+7-Seite. Die Ursache dieses unterschiedlichen Aufnahmezustands ist noch offen; ein falsches Entropieurteil ist nicht belegt. Die aktive native Stoppabnahme bleibt offen. Ergebnisse verschiedener Läufe werden nicht zu einem erfundenen Gesamt-PASS zusammengesetzt.

| Stufe | Konkreter Nachweis | Dokumentierter Status |
|---|---|---|
| Vollständige Produktvalidierung | Run 43800892196, Job 133080632526, APK-Quelle e05a96a | **SUCCESS** |
| Signierte ARM64-/x86-APKs | Derselbe Quellrun, Buildjob 133085378884 | **SUCCESS**, Identität und Bytes geprüft |
| Vollständiger Replay 4 | [Run 43819768411](https://github.com/Ullmann27/lumo-lernen/actions/runs/43819768411), Job 133139916895: frische Originaltour, danach vollständige Referenztour | **SUCCESS**; beide Touren und kombinierter Ergebnisprüfer **PASS_WITH_LIMITATIONS** |
| Getrennter Zusatzlauf 3 | [Run 43819768114](https://github.com/Ullmann27/lumo-lernen/actions/runs/43819768114): vier zusätzliche Laufzeitfälle | **Gesamt-FAIL** um 07:05 UTC; drei vorherige Teilfälle belegt, Stopp nicht begonnen; `release_eligible=false` |
| Getrennter Zusatzlauf 4 | [Run 43822740773](https://github.com/Ullmann27/lumo-lernen/actions/runs/43822740773), Job 133149336951, QA 7b811531 | **FAIL**, Abschluss 07:24:25 UTC, Screenshotbereitschaft vor der ersten Fehlantwort; Ursache des Aufnahmezustands offen; `release_eligible=false` |
| Öffentliche Auslieferung | [Publikationsrun 43823660756](https://github.com/Ullmann27/lumo-lernen/actions/runs/43823660756), 07:24:43–07:27:52 UTC | **SUCCESS**; Herkunfts-/APK-/Tourprüfung, neue Veröffentlichung und vollständiger anonymer Download bestätigt |

Die ursprüngliche gemeinsame Aktivierung von Vollreplay 4 und Zusatzlauf 3, deren Quellen und unabhängige Reviews liegen unter [replay_attempt4_integration_20261116](evidence/replay_attempt4_integration_20261116/README.md). Die Zusatzprüfung ersetzt weder die vollständigen Touren noch den Publisher.

## Unveränderte Produkt- und Paketidentität

| Eigenschaft | Verifizierter Wert |
|---|---|
| Version | `0.13.19+2031` |
| APK-/Flutter-Quelle | `e05a96a52aaf57e466e79831f15aaffd144284ee` |
| Native Quelle | `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef` aus `Ullmann27/lumo-godot` |
| Native Engine | Godot 4.6.3 |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Bestehendes Testzertifikat, SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Eingebettete PCK, SHA-256 | `94b0a84b8715537fff9ff84e451c889ca1fe1b8440a4448ded93989b3feb0aef` |
| Ursprünglicher Buildrun | [43800892196](https://github.com/Ullmann27/lumo-lernen/actions/runs/43800892196) |

| Gebaute APK | Vollständige Dateigröße | SHA-256 |
|---|---:|---|
| ARM64, vorgesehene Gerätedatei | 535.026.362 Bytes | `e6ca8e512ddc56755ae8664b3438b0e78b87a7f0e77f1cd55cac592b20b316d7` |
| x86, unveränderte Emulator-Prüfdatei | 538.191.823 Bytes | `8e96a05c51fc12504a19831cee14b64c6a8e9a35a8a36863db455bed0e2cec1a` |

Paket, Version, Signatur, ABI, Ausrichtung und Offline-Sprachassets wurden am gebauten Paket geprüft. Die vollständige ARM64-APK wurde zusätzlich unabhängig heruntergeladen und gegen Größe/SHA/Provenienz verglichen. Das bestehende Testzertifikat ist keine Play-Produktionssignatur. [Originaler Buildbeleg](evidence/ci-2031-build/README.md).

**APK-Quelle, QA-Quelle und Publikationsquelle sind getrennte Identitäten.** Der erfolgreiche Publikationsrun verwendet **`7270fbb7e9d496e91df18cedd0776a5d4f9a3c85`**, Tree **`3f76a3bbe5c4d7afe0fe3418efd8840991995397`**. Die QA-Korrekturen bauen keine neue APK und ändern weder Runtimequellen, PCK, Version, Profilformat noch Lernstände. Die Veröffentlichung bindet den erfolgreichen Vollreplay an ae6c27c und genau diese geprüften ARM64-Bytes; die beiden späteren Supplemental-FAILs werden nicht als vollständige Abnahme ausgegeben.

## Bereits bestandene Prüfungen und ihre Reichweite

Die vollständige Validierung an der APK-Quelle e05a96a besteht mit **2.896 Fluttertests, 202 vorhandenen Skips und 0 Fehlschlägen; 143 Host-Python-Testmethoden; echtem Godot-Import; 12 nativen Prüfprogrammen mit 55.552 Assertions; 118 Projektprüfungen**. Analyzer: 0 Fehler, 4 Warnungen, 274 Hinweise. Alle **359 Coverage-Quellhashes** und **18 geschützten Dateien** sind geprüft. Die 56 Originalmitglieder und das vollständige Joblog bleiben erhalten. [Validierungsbeleg](evidence/ci-2031-validation/README.md).

Der spätere gemeinsame QA-Hostlauf an `c54295528a3f8a91ef9eb6296279b91a15b36ebd` besteht mit **230/230 Prüfungen** der sieben tatsächlich eingesetzten Gruppen. Deren Quellenbindung zur QA-Quelle ae6c27c des Vollreplays 4 ist dokumentiert. Die fokussierten 19- und 54-Testläufe sind darin enthalten und werden nicht hinzuaddiert. Diese Hostprüfungen ersetzen keine Androidausführung. [Befehle, Quellen und Rohlog](evidence/replay_attempt4_integration_20261116/integrated-host-gates.json).

## Erfolgreicher vollständiger Replay 4

**Run 43819768411, Job 133139916895, QA ae6c27c** hat die echte Originaltour von **06:55:37 bis 07:04:22 UTC** und anschließend die Referenztour von **07:04:22 bis 07:16:25 UTC** ausgeführt. Der Actionsjob endete um **07:16:35 UTC** mit SUCCESS. Beide Touren verwendeten Android 35/x86_64 im Emulator, echte UI-Onboardingprofile und die unveränderte APK; vor der jeweiligen frischen Installation war das Paket abwesend. Kein historischer Tour-PASS und keine direkte private Lerndatenmutation wurden verwendet.

Das vollständige Artefakt ist **14204544628**, ZIP **136.444.327 Bytes**, SHA-256 **`4becebd332755f1046d945f61dcfcf4317316d617d568c685576edcd69bcee9f`**. Die Archivprüfung umfasst **3.386 Mitglieder** und **153.626.839 unkomprimierte Bytes**; die vollständigen Originale sind in bytegenauen Archivteilen erhalten. Die Resultate wurden zusätzlich durch den unveränderten `verify_2031_tours` geprüft. Das ist eine Prüfung vorhandener Originaldaten, kein weiterer Androidlauf. [Archividentität](evidence/ci-2031-complete-replay-verified/artifact-verification.json), [vollständige Originalbewahrung](evidence/ci-2031-complete-replay-verified/archive-retention.json), [unabhängige Ergebnisbindung](evidence/ci-2031-complete-replay-verified/independent-result-verification.json).

| Tatsächliches Ergebnis | Beleg und genaue Grenze |
|---|---|
| Originaltour **PASS_WITH_LIMITATIONS** | 34 registrierte Screenshots, 14 Videos; Flutter-Labor für 8+5, Banane und Muster, eigene Aufgabenfrage, Stopps, echte Mikrofonanforderung, drei Home-/Rückkehrwege und vier Größenansichten |
| 8+5 nach eigener Frage | Erster eigener Stein-Tipp speichert `moved=1`. Native Frage **Warum zuerst zwei?** bewegt selbst von 0 auf 2 der 5 Objekte, ohne nachfolgende manuelle Bewegungstaste; neue Player-ID 19 in PID 7245 |
| Native Banane **PASS_WITH_LIMITATIONS** | Drei sichtbare Silbenschritte, vollständiger Status **Das Wort hat 3 Silben**, danach **Noch einmal** mit vier neuen geordneten Player-Paaren 19–22 in PID 9377; keine akustische Wortprüfung |
| Natives Muster **PASS_WITH_LIMITATIONS** | Tatsächliche Folge **Quadrat – Stern – Quadrat – Stern**, kleinste Periode 2; sichtbarer Gruppenhinweis mit neuer Player-ID 7 in PID 10900; Vorschlag Quadrat und ungewerteter Rückweg zur identischen Frage |
| Nachgelagerte Core-Bewertung des Musters | **NOT_EXERCISED**: keine gleichzeitig eindeutig beobachtete Core-Antwortüberschrift mit vier aktiven Antwortkarten. Der ungewertete Rückweg bleibt belegt; eine fachlich abgegebene Core-Antwort wird nicht behauptet. |
| Referenztour **PASS_WITH_LIMITATIONS** | 18 registrierte Screenshots und 12 Videos; neue disposable Installation für die Banane-/Musterreferenzen, eigene Quellen-/Profilbindung |
| Mikrofon/Erkennung | Echte Anforderung und sichtbare Gerätebegrenzung: `microphone_ui_outcome=explicit_device_limitation`, `recognition=NOT_VERIFIED`. Keine echte gesprochene Äußerung und kein Spracherkennungs-PASS. |

Originalresultat-SHA-256: **`ab8f1e2750993d4e4436b1d7e7f10fd5e51128397bf76cbb8f2e6c854b2854ea`**. Referenzresultat-SHA-256: **`1063cd4c28556952ee9604f0fc968113c9f5b053c97e81bd2e779092bfdb919f`**. Die [Originaltour](evidence/ci-2031-complete-replay-verified/original/android/original-android/learning-android-result.json), [Referenztour](evidence/ci-2031-complete-replay-verified/original/android/reference-android/reference-android-result.json) und das [kombinierte Resultat](evidence/ci-2031-complete-replay-verified/original/replay-result.json) bleiben getrennt. Der frühere Android-FAIL des ursprünglichen Buildruns wird dadurch nicht umklassifiziert.

### Tatsächliche native Leistung im Emulator

Die Messung stammt aus der sichtbaren nativen 8+5-Szene, PID **7245**, Renderer `gl_compatibility`, **llvmpipe LLVM 20.1.2**. Sie misst Godot-`_process`-Intervalle und keine Display-Präsentationszeitpunkte.

| Messgröße | Tatsächlicher Wert |
|---|---:|
| Beobachtete Szene | 40,829471584 Sekunden |
| Zusammengefasste Messfenster | 7 Fenster, 49 Samples, 36,516349 Messsekunden |
| Mittleres Prozessframe-Intervall | 745,2316122448982 ms |
| Daraus berichtete Prozessframe-Rate | 1,3418647083255772 Hz |
| Intervalle über 16,7 ms | 49 von 49 |
| Schlechtester Fenster-P95 / Fenster-P99 | jeweils 1.015,883 ms |
| Gleichzeitige Sprache/Fuchs/Effekt-Zustände | 14 Samples in Fenstern 38–40 |

**Die Messung zeigt eine deutlich langsame Emulatorausführung und keinen erreichten 60-FPS-Zielwert.** Die Fenster enthalten nur 6–8 Samples; ihre P99-Werte sind bei diesem Verfahren die jeweiligen Maxima, keine belastbare globale P99-Schätzung. Die 32 dokumentierten Vorfenster wurden nicht in diese Zusammenfassung eingerechnet. Das Erfassungsgate bestätigt Messung, aktuelle Playback-Ereignisse und Zustandsüberlappung; es ist keine Freigabe für eine bestimmte Bildrate auf physischen Geräten. Die zusätzlichen gfxinfo-/SurfaceFlinger-Rohantworten ersetzen diese Messung nicht. [Originale Leistungsdaten](evidence/ci-2031-complete-replay-verified/original/android/original-android/native-learning-performance.json).

## Tatsächlich erfasste Lernbereiche

Der echte Dart-Katalogexport wurde an `cc4197e622c42dc5387ba06b7e57ac4964e1a07b` ausgeführt; der Quellenstand und die Hashprüfung sind separat von der späteren Releaseaktivierung dokumentiert. Die getrennten Inventare zählen **61 Einträge**, **55 Screendateien**, **236 Curriculumfamilien**, **19 aktive Spezialisteinstiege auf 18 Fachoberflächen**, **6 Lernlabor-Modi mit 35 bestehenden Problem-IDs** und **7 geführte Lektionen**. Die 61 Einträge enthalten auch Navigation, Verträge, geschützte und inaktive Wege. Sie sind keine 61 bewerteten Aufgaben; 236 Familien sind keine 236 einzeln abgenommenen Androidscreens.

| Lernbereich und tatsächlicher Einstieg | Vorhandener Ausbau | Native Darstellung und verbleibende Grenze |
|---|---|---|
| Reguläres Üben, freiwillige andere Klassen, Schulaufträge → Core/CrossGrade | Aufgabenrenderer, lokale Bewertung, aktuelle Aufgabenbindung, eigene Dialog-/Menü- und Größenwechselgrenzen | Spezialmodell bei passender Aufgabe, sonst `task_card`; keine individuelle räumliche Umsetzung aller 236 Familien |
| Fach-/Themenwahl → 19 aktive Spezialrouten | 18 Fachoberflächen mit vorhandener Fachlogik, Aufgaben-Scope, Hilfe und zulässiger Kandidatenbestätigung | Gemeinsame Aufgabenkarte; nicht 19 eigene native Simulationen |
| Lernatelier/Lernlabor → `LearningLabHub` → Werkstatt | Sechs interaktive Fluttermodelle mit Bau-/Abrufphasen, lokaler Prüfung und persistenten Checkpoints | Aufgabenkarte über `fromCompanionContext`; 35 Problem-IDs bleiben erhalten |
| Akademie → Lumo erklärt es mir → geführte Lektion | Sieben schrittweise Lektionen mit Illustration, Animation und Sprachablauf | Passende Spezialszene über `fromLesson`, sonst Karte; eigener Lernweg neben dem Labor |
| Lesen-/Rechtschreib-Einstiege → ReadingContent/Reading Buddy | Lesebegleitung, aktuelle Text-/Aufgabenbindung und Audiozuständigkeit; 24 Lesetexte | Gemeinsame Karte; keine eigene räumliche Szene für jeden Text |
| Geschichtenbibliothek/Erstellung → Reader, vier Lernabenteuer | Lesesitzungen, Buchfragen, Zusammenfassung und passende Begleitung | Karte im Reader; Erstellung/Navigation sind keine automatisch bewerteten Aufgaben |
| Foto-Lernheft → tatsächliche Fotoübung | Aufgabenbezogener Übungsweg mit eigener Fachzuständigkeit | Spezialmodell oder Karte; kein Nachweis fehlerfreier Auswertung beliebiger Fotos |
| Spielen → Minigame-/Levelauswahl | Spiel-/Aufgabenlogik, Speicherung, Wiederaufnahme; 49 Minigame-Level plus ein Quiz-Finallevel | Fachadapter mit Spezialmodell oder Karte; keine 49 eigenen nativen Spielmodelle |
| Quizshow, Cards-Denkpausen, Live und Flame-Lernaufgaben | Lokale Moduszuständigkeit und gemeinsamer LearningQuestionCoach | Generische Karte; Flame bleibt 2D, Teilnahme ist nicht automatisch Beherrschung |
| Fachtests, IQ und kognitive Bereiche | Lokale Bewertung mit absichtlich begrenzter Begleitung | Prüfungsrichtlinie sperrt Hinweise/Antwortvorschläge; Wiederholen, langsamer und stoppen bleiben zulässige Teilfunktionen |
| Praktische Fachaufträge → Durchführung/Journalverknüpfung | 60 erreichbare Aufträge und manuelle Dokumentation | Kein durchgängiger kanonischer Coach-/3D-Anschluss aller Praxisaufträge nachgewiesen |

Der gemeinsame Coach arbeitet mit dem aktuellen Aufgaben-/Schritt-/Sitzungskontext. Fachliche Bewertung und Belohnung bleiben beim zuständigen Lernmodus; ein Sprachvorschlag wird, wo zulässig, ausdrücklich bestätigt. Eine native Erklärungsaktion ist keine automatische richtige Antwort.

**Geschützt:** 18 festgelegte Schreibtrainer-/Journaldateien sind bytegleich zur Basis `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`; zulässig sind äußere Anschlüsse. `d1_woerter` wird vom geschützten Wort-Coach überlagert. Alte Deutsch-Lückensätze sind nicht aktiv erreichbar; der Teacher-Restfallback ist im aktuellen Dispatch keine bewertete Aufgabe. ABC-/Rechentricks-Tafeln sind Referenzen. Kart und native Dschungelarbeiten bleiben ausgeschlossen.

Maßgeblich sind [COVERAGE.json](COVERAGE.json), [COVERAGE.md](COVERAGE.md), [INTEGRATION_V1.md](INTEGRATION_V1.md) und der [ursprüngliche Katalog-/Hashbeleg](evidence/coverage_refresh_20261116_2031/).

## Erhaltene Fehlläufe und bereits belegte Teilfälle

| Lauf | Unverändertes Ergebnis und konkrete Grenze | Originale |
|---|---|---|
| Ursprüngliche Androidstufe 43800892196 | FAIL an der zu frühen Home-Vordergrundabfrage; sekundärer Nullzeitvideo-Fehler. Publisher übersprungen. Kein belegter unerlaubter Produkt-Relaunch. | [Home-Transition](evidence/ci-2031-android-home-transition-failure/README.md) |
| Vollreplay 1: 43806736020 | Originaltour PASS_WITH_LIMITATIONS; Referenz am umgebrochenen nativen Banane-Statustext gescheitert. | [Banane-Leser](evidence/ci-2031-replay-banana-reader-failure/README.md) |
| Vollreplay 2: 43811505799 | Originaltour PASS_WITH_LIMITATIONS; Referenz vor nativer Banane beim Videotransfer mit Exit 1 und 7-Prozent-Fortschrittszeile gescheitert. Kein fehlender Recorderstart belegt. | [Videotransfer](evidence/ci-2031-replay-video-transfer-failure/README.md) |
| Vollreplay 3: 43814971553 | Originaltour PASS_WITH_LIMITATIONS; Referenz FAIL nach Kopierabbruch und tatsächlicher ADB-Offlineantwort. | [Transferzustand](evidence/ci-2031-replay-transfer-state-failure/README.md) |
| Zusatzlauf 1: 43812538819 | FAIL: Weiterknopf sichtbar, Silbenleiste außerhalb der beobachteten Ansicht. Kein Audioausfall aus dieser Lücke ableitbar. | [Aktivbeobachtung](evidence/ci-2031-runtime-cases-active-observation-failure/README.md) |
| Zusatzlauf 2: 43816667737 | Zahlenfehler/Korrektur und Wechsel bei aktiver Silbenanzeige gesondert bestanden; Gesamt-FAIL am ersten noch panelfreien nativen Frame. | [Teilfälle und Panelabbruch](evidence/ci-2031-runtime-cases-native-panel-failure/README.md) |
| Zusatzlauf 3: 43819768114 | Zahlenfehler/Korrektur und aktiver Wechsel PASS, nativer Banane-Langsamer-Fall PASS_WITH_LIMITATIONS; Gesamt-FAIL beim erneuten Akademie-Toggle vor Beginn des Stoppfalls. | [Teilfälle und Navigation](evidence/ci-2031-runtime-cases-academy-navigation-failure/README.md) |
| Zusatzlauf 4: 43822740773 | FAIL an der Bereitschaftsprüfung der Vorher-Aufnahme vor 15-Abgabe zu 9+7; Kandidaten zeigen Hintergrund, spätere Fehleraufnahme Lumo. Kein abgeschlossener Zusatzfall dieses Runs. | [Unverändertes Resultat](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/runtime-cases-result.json) |

Zusatzlauf 2 belegt die echte Bewertung von **15 als falsch zu 9+7**, danach **16 als unterstützt richtig**, sowie den Wechsel bei **Silbe 1: Ba, gerade aktiv** zur unbeantworteten Aufgabe `word-rakete` ohne weitere Bewertungs-/Belohnungsbuchung. Die erfasste XML-Beginn-bis-Tap-Anforderung betrug 0,132656392 Sekunden. Der Fall verwendete 1080×2340 Pixel, vorübergehend 320 statt 440 dpi, und stellte 440 dpi nachweislich wieder her. Das ist weder eine akustische Messung noch ein Standarddichte- oder physischer Foldnachweis. Nativer Langsamer- und Stoppfall waren dort nicht abgeschlossen. [Gebundene Teilfallprüfung](evidence/ci-2031-runtime-cases-native-panel-failure/verified-completed-subcases.json).

**Zusatzlauf 3 ist separat aus seinen Originalen geprüft:** Die Abgaben **15 falsch → 16 unterstützt richtig** und der Wechsel **Banane → unbeantwortete Rakete** ohne zusätzliche Versuchs-/Belohnungsbuchung sind bestätigt. In der nativen Banane wurde **Langsamer** im sichtbaren Panel bedient; das Rohlog belegt vier neue geordnete MediaPlayer-Start-/Endepaare **7–10 in PID 6407**. Das Modell blieb vor/nachher bei **0 / 3 bewegt**. Das Originalvideo `0346-runtime-banana-four-slower-segments.mp4` dauert 64,066222 Sekunden und hat keine Tonspur; die zugehörigen Bilder sind 0339/0378/0395. Die dokumentierte Profil-/Lerndatenerhaltung stammt aus dem Androidfall und wurde in der zusätzlichen Teilprüfung nicht nochmals aus sämtlichen Preferences rekonstruiert. **Wörter, tatsächliches Tempo, Akustik und Mikrofonerkennung sind dadurch nicht nachgewiesen.** [Exakte Teilfall-/Medienbindung](evidence/ci-2031-runtime-cases-academy-navigation-failure/verified-completed-subcases.json).

Der anschließende erneute Tap auf **Lernwerkzeuge & Geschichten** schloss das bereits geöffnete Atelier. Die Originale 0399/0400/0409/0410 belegen diesen Probe-Togglefehler. Der native aktive Stoppfall hat in Zusatzlauf 3 nicht begonnen; dessen Gesamtstatus und Native-Sammelstatus bleiben FAIL.

**Zusatzlauf 4 erreicht den korrigierten nativen Übergang noch nicht.** Der tatsächliche Fehler lautet: `Flutter 0134-numeric-before-wrong-answer stayed visually unrendered after 12 frames; last entropy=2.791`. Er entsteht bei der Vorher-Aufnahme vor dem geplanten 9+7-Fehlversuch, vor Eingabe und Abschicken der falschen 15. Das Ergebnis endet um 07:24:16 UTC, der Actionsjob um 07:24:25 UTC. Alle zwölf Kandidatenbilder besitzen denselben SHA-256 und zeigen den Android-Hintergrund ohne Lumo; ihre Bereitschaftswerte sind **2,791 < 3,0**. Das **erst später** erstellte Originalbild **0135** zeigt dagegen lesbar Aufgabe, leeres Antwortfeld und **Antwort prüfen**. Diese verschiedenen Aufnahmezeitpunkte dürfen nicht gleichgesetzt werden: Aus 0135 folgt kein False Negative der früheren Entropieprüfung. Die Ursache des Capture-/Oberflächenzustands bleibt in Diagnose; eine fachliche Falschbewertung und ein neuer Fix oder Folgelauf werden nicht behauptet. [Erste Kandidatenaufnahme](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/0134-numeric-before-wrong-answer-render-candidate-1.png), [Bereitschaftsoriginal](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/0134-numeric-before-wrong-answer-render-readiness.json), [späteres Fehlerbild](evidence/ci-2031-runtime-cases-numeric-capture-failure/original/android/runtime-cases/0135-runtime-failure-current-screen.png).

Die **187 Originalmitglieder** dieses Laufs sind im Artefakt **14204798832**, ZIP **22.181.444 Bytes**, SHA-256 **`d28a0b855eb8ad8cc5127cac5fa0b453f79999dd98a798ba449bdb72ad6131df`**, vollständig bewahrt. [Archivprüfung](evidence/ci-2031-runtime-cases-numeric-capture-failure/artifact-verification.json), [Originalbewahrung](evidence/ci-2031-runtime-cases-numeric-capture-failure/archive-retention.json). Die ältere erfolgreiche Zahlen-/Wechsel-/Langsamer-Teilprüfung aus Zusatzlauf 3 bleibt separat gültig; sie ersetzt keinen neuen Gesamt-PASS.

Die aktuellen QA-Korrekturen bewahren die historischen FAIL-Originale. Sie warten auf tatsächliche Home-/Panelübergänge, erkennen den vollständigen umgebrochenen Text und sichern den ursprünglichen Fehler. Ein abgebrochener Videotransfer darf nur dieselbe beendete Aufnahme unter unveränderten Identitäts-/Byte-/Dauergates erneut kopieren; ADB-offline wird ausschließlich passiv im bestehenden 90-Sekunden-Budget beobachtet. Es werden keine Apphandlung und keine Aufnahme nachgestellt. Details und Gegenprüfungen: [gemeinsame Integration](evidence/replay_attempt4_integration_20261116/README.md).

## Verifizierte Veröffentlichung und verbleibende Abnahme

Die konkrete Fallzuordnung steht in [ACCEPTANCE_CASES_2031.md](ACCEPTANCE_CASES_2031.md). Vollreplay 4 ist mit seinen echten Resultaten und Leistungsgrenzen dokumentiert. Zusatzläufe 3 und 4 bleiben mit ihren jeweiligen Abbruchstellen FAIL; die aktive native Stoppabnahme bleibt offen. Die enge QA-Diagnose der neuen Capturegrenze läuft, ohne hier einen weiteren Fix oder Androidlauf vorwegzunehmen. Teilfälle werden ihrer tatsächlichen Quelle zugeordnet; Belege verschiedener Runs ergeben keinen zusammengebauten Gesamt-PASS.

Der technische Publisher hat den erfolgreichen vollständigen Replay einschließlich Original-, Referenz- und Performancegates, die unveränderte Build-/Validierungsherkunft sowie die Bytegleichheit seiner **31 gebundenen Prüferdateien** zur erfolgreichen QA-Quelle bestätigt. Release und Tag waren zuvor mit echten 404-Antworten nicht vorhanden. Das neue öffentliche Release besitzt ID **446720910**, Tag **`lumo-nextgen-learning-0.13.19-2031`**, Tag-/Produktquelle **e05a96a**, `draft=false` und `prerelease=true`. APK-Asset **753897981** enthält genau die geprüften **535.026.362 Bytes** mit SHA-256 **`e6ca8e512ddc56755ae8664b3438b0e78b87a7f0e77f1cd55cac592b20b316d7`**. Die getrennte Zusatzprüfung bleibt ein zusätzlicher Fallnachweis und ist niemals selbst releasefähig; die offenen Zusatzfälle werden durch die Publikation nicht als bestanden ausgegeben.

**Öffentlicher APK-Link: bestätigt.** Der Originalbeleg meldet `httpStatus=200`, `authorizationHeaderSent=false`, `entireFileRead=true`, Versuch 1 und `verifiedUtc=2026-11-16T07:27:47Z`; Größe und SHA stimmen vollständig. [Downloadprüfung](evidence/ci-2031-publication-verified/original/publication-proof/PUBLIC-DOWNLOAD-VERIFIED.json), [tatsächliche Release-/Assetmetadaten](evidence/ci-2031-publication-verified/original/publication-proof/PUBLIC-DOWNLOAD.json), [Tagquelle](evidence/ci-2031-publication-verified/original/publication-proof/PUBLIC-TAG.json), [Prüferbindung](evidence/ci-2031-publication-verified/original/publication-proof/qa-publisher-source-binding.json).

Die **15 Originalmitglieder** des Publikationsbelegs sind im Artefakt **14205437855**, ZIP **23.659 Bytes**, SHA-256 **`0574bd5bb9f70e2f5d32840425c7dfc4363249c49f5add30fa5840ab66a32f4f`**, vollständig erhalten. [Archivprüfung](evidence/ci-2031-publication-verified/artifact-verification.json), [Originalbewahrung](evidence/ci-2031-publication-verified/archive-retention.json). Für diese Dokumentationsfortschreibung wurden ausschließlich die vorhandenen Belege gelesen; kein weiterer APK-Download oder Testlauf wurde ausgeführt.

**`fullModernizationComplete=false` und `allTaskVariantsReviewed=false` bleiben bestehen.** Die native Lernwelt hat 11 spezialisierte Modelle und eine generische Aufgabenkarte; sie läuft in einer separaten Android-Activity. Eine dauerhaft in jede Flutter-Aufgabe integrierte 3D-Figur und individuelle räumliche Modelle für sämtliche Familien sind nicht vollständig umgesetzt. Natürliche Fragen bleiben an den freigegebenen aktuellen Aufgabenvertrag gebunden.

Auch nach dem erfolgreichen vollständigen Replay bleiben physisches Fold7-Falten, reale gesprochene Fehl-/Korrekturerkennung, akustische Qualität und Geschwindigkeit, gemeinsam gemessener Ton-/Mund-/Gestenstopp, vollständige Upgrade-/Prozesstod-Erhaltung sowie sämtliche 48-dp-Bedienelemente gesonderte Nachweise. Die vorhandene [Touchflächen-Stichprobe](evidence/ci-2031-layout-touch-inspection/README.md) ist keine Vollabnahme. Die aktuelle langsame Prozessframe-Messung und die getrennte [historische native Messung](evidence/2031-qa-integration-20261116/native-performance-interpretation.json) begründen keine pauschale 60-FPS-Zusage für physische Geräte.
