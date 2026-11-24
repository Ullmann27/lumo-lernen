# Vollständiger Android-Replay 4 — unveränderte APK 2031

Der tatsächliche [Workflow 43819768411](https://github.com/Ullmann27/lumo-lernen/actions/runs/43819768411), Job **133139916895**, ist am 16.11.2026 um **07:16:35 UTC erfolgreich abgeschlossen**. Seine Quelle ist **ae6c27c81d41342179a0bf6e60fedbcafacb63a4**, Tree **52e8fc78e7cd17781a567d64d7b311e1f45ce874**, Zweig `qa/lumo-nextgen-2031-android-20261116`. Die geprüfte APK bleibt Quelle **e05a96a52aaf57e466e79831f15aaffd144284ee**, Native **678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef**. Keine Produktänderung oder erneute Kompilierung wurde als QA-Korrektur ausgegeben.

## Originale und erneute Ergebnisprüfung

Originaltour **06:55:37–07:04:22 UTC**, Referenztour **07:04:22–07:16:25 UTC**: beide und das kombinierte Ergebnis **PASS_WITH_LIMITATIONS**. Die unveränderten Ergebnisprüfer wurden zusätzlich mit genau den Quellen des QA-Commits an den unveränderten Originalresultaten ausgeführt: [independent-result-verification.json](independent-result-verification.json). Das ist eine zusätzliche Prüfung gespeicherter Resultate, keine weitere Androidtour.

- [Originaltour](original/android/original-android/learning-android-result.json), SHA-256 `ab8f1e2750993d4e4436b1d7e7f10fd5e51128397bf76cbb8f2e6c854b2854ea`.
- [Referenztour](original/android/reference-android/reference-android-result.json), SHA-256 `1063cd4c28556952ee9604f0fc968113c9f5b053c97e81bd2e779092bfdb919f`.
- [Kombiniertes Ergebnis](original/replay-result.json), [Originale Leistungsdaten](original/android/original-android/native-learning-performance.json).
- [Aus den Originalen gelesene Zählungen](reviewed-execution-summary.json): 230/230 Hostprüfungen; 34+18 registrierte Screenshots, 14+12 Videos. Fokussierte frühere Prüfläufe werden nicht hinzuaddiert.

Artefakt **14204544628**: **136.444.327 Bytes**, SHA-256 **4becebd332755f1046d945f61dcfcf4317316d617d568c685576edcd69bcee9f**. Sämtliche **3.386 Mitglieder / 153.626.839 unkomprimierte Bytes** wurden auf Pfade, Größen, CRC und SHA geprüft. Das gesamte Original-ZIP ist in **17 geordneten Teilen** verlustfrei erhalten; [archive-retention.json](archive-retention.json) bindet jeden Teil. `archiveRetainedLocally=false` im reinen Leserbericht beschreibt dessen ursprüngliche In-Memory-Lesestufe; die nachfolgende vollständige Bewahrung ist im separaten Retention-Manifest nachgewiesen. Ausgewählte Originale sind zusätzlich unverändert entpackt.

Beim ersten Download bestand die vollständige Archiv-/Mitgliederprüfung. Erst die nachfolgende lokale Freiplatzreserve verhinderte die Bewahrung: [retention-first-attempt.json](retention-first-attempt.json), [erste Mitgliederprüfung](first-download-member-verification.json). Nach dokumentierter Verkleinerung ausschließlich eingefrorener eigener Arbeitskopien wurde dasselbe vollständige ZIP erneut geprüft und bewahrt; die vier zuerst gelesenen Originalresultate waren bytegleich. Kein Androidfehler wurde dadurch verändert.

Das vollständige Rohjoblog (669.986 Bytes, SHA-256 **e8b8d669945343a9558aa668c0be498bb3212b40af1631325cc0f5865ac9869f**) liegt unverändert unter [job-log](job-log/job-log-manifest.json), zusätzlich verlustfrei gzip-komprimiert. API-Beobachtungen stehen in `observed-run.json`, `observed-jobs.json` und `observed-artifacts.json`.

## Tatsächlich beobachtete Szenen

**8+5:** Die getippte Frage „Warum zuerst zwei?“ löst in der nativen aktuellen Aufgabe die sichtbare Bewegung von 0 auf 2 Steine aus: 8+2 im Feld, 3 daneben. Eigene PID **7245**, aktuelle Wiedergabe-ID **19**. Das ist ein Erklärschritt ohne automatische fachliche Abgabe. [Originalbild](original/android/original-android/0426-why-native-ten-and-three-after-explanation.png), [Originalvideo](original/android/original-android/0402-native-why-two-question-and-demonstration.mp4).

**Banane:** Drei beobachtete Schritte Ba/na/ne und anschließend vier neu geordnete Wiedergabesegmente der Wiederholen-Aktion, IDs **19–22**, PID **9377**. [Originalbild](original/android/reference-android/0141-banana-syllable-3.png), [Originalvideo](original/android/reference-android/0159-banana-four-segment-repeat.mp4). Keine akustische Qualitäts-/Wort- oder Geschwindigkeitsmessung.

**Muster:** Quadrat–Stern–Quadrat–Stern, kleinste Gruppe 2. Aktueller Hinweis mit Player-ID **7**, PID **10900**; nativer Quadrat-Vorschlag und ungewertete Rückkehr zur identischen Core-Aufgabe. `core_answer_submitted=false`, `core_submission.status=NOT_EXERCISED`; keine tatsächliche Core-Abgabe behauptet. [Originalbild](original/android/reference-android/0251-pattern-two-sign-group.png), [Originalvideo](original/android/reference-android/0230-pattern-observed-group-and-unconfirmed-proposal.mp4).

Root und Conversation haben die drei genannten Originalbilder angesehen. Der Originalfuchs ist sichtbar und verdeckt die entscheidenden Lernobjekte nicht. In 8+5 ist der Titel umgebrochen, aber vollständig; in Banane überlagern die Silbenblöcke teilweise das große Hintergrundwort, die einzelnen Silben bleiben lesbar. Einzelbilder belegen keine genaue Animations-, Blick-, Gesten- oder Mundsynchronität. Sämtliche hier registrierten Videos haben keine Tonspur.

## Tatsächliche Grenzen

Android API 35, x86 Pixel-5-Emulator, `gl_compatibility`, **llvmpipe LLVM 20.1.2 Softwaregrafik**. Sieben vollständige Messfenster mit **49 Godot-_process-Intervallen** über **36,516349 Messsekunden**, Mittel **745,2316122448982 ms**, Kehrwert **1,3418647083255772 Hz**. **49/49** Intervalle verfehlen 16,7 ms. Schlechtester Fenster-P95/P99 **1.015,883 ms**, nur 6–8 Samples je Fenster; keine stabile globale P99-Schätzung. 14 Samples in drei Fenstern binden gleichzeitig akzeptierten Wiedergabe-, Fuchs- und Effektzustand. Das ist keine erreichte 60-FPS-Abnahme und keine physische Display-/Audiomessung.

Vier echte Emulator-Größenwechsel und Rückstellung erhalten den Bridge-Checkpoint; Home/Rückkehr erhält Bridge-, Wort- und Musterzustand nach vorherigem Stopp. Keine physische Fold7-/ARM64-Nutzung, kein Prozesstod-/Upgrade-Test und kein Home während aktiver nativer Sprache. Mikrofonweg beobachtet eine ausdrückliche Gerätebegrenzung: **STT NOT_VERIFIED**. Nicht sämtliche Aufgabenvarianten, 48-dp-Flächen oder individuellen 3D-Fachmodelle sind abgenommen. **fullModernizationComplete=false**.

Die [Publikationsvorprüfung](publication-preflight.json) bindet zusätzlich alle 31 Publisherdateien und 17 weitere vollständige Replay-Fixtures bytegleich an diesen QA-Commit. Sie ersetzt weder APK- noch Publikationsprüfung. Der separate Zusatzlauf bleibt getrennt und ist kein Bestandteil dieses Gesamt-PASS.
