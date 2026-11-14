# Tatsächlicher Studio-Build auf e3d161cb

Diese Prüfung liest ausschließlich den vollständigen Originaljoblog des erfolgreich abgeschlossenen Jobs `verify-and-build` **132009667976** aus Run **43461547945**. Der Host ist `e3d161cb2f79b732ac2dbafc2764b151247f018b`, der tatsächlich geprüfte und exportierte Native-Pin `76980a941fa05d047574d8cc386d3249d93ffca3`. Es wurden keine Prüfungen erneut ausgeführt und keine Produktdateien geändert.

Der vollständige Log enthält **1.504.998 Bytes / 12.672 Zeilen**, SHA-256 `2f85fa6cbdbdf270384bb9bc900bc0698c7d6ec3b84aea257e0102b78bfebda0`. Die vom GitHub-Connector zurückgegebene vollständige Textfassung ist mit ursprünglichem BOM und Zeitstempeln erhalten. Das ist kein neu behaupteter Download des komprimierten GitHub-Logarchivs. Die Originalschritt-Metadaten bestätigen den erfolgreichen Abschluss von Build, separater APK-Verifikation und beiden Uploadschritten.

## Neue tatsächlich ausgeführte Prüfungen

| Prüfung | Ergebnis des aktuellen Jobs |
|---|---|
| Vollständige `scripts/tests` | 353 bestanden, 0 fehlgeschlagen, 0 übersprungen; 81,735 s |
| Vollständige `tools/android_qa/tests` | 746 bestanden, 0 fehlgeschlagen, 0 übersprungen; 49,375 s |
| Font-/Capture-Guard | 3 bestanden; 0,091 s |
| Export-/Quellschutz | 23 bestanden; 0,214 s |
| Launcher-Icons während des Builds | 8 bestanden; 2,842 s |
| Vollständige Flutter-Suite | 2.510 bestanden, 0 fehlgeschlagen, 0 übersprungen; Runner und Flutter Exit 0; 546 erzeugte PNGs |
| Weitere gezielte Flutter-Aufrufe | 31, 3, 3, 3, 19, 5 und 3 Tests, jeweils bestanden |

Die Teilaufrufe können Prüfungen aus den vollständigen Suiten wiederholen. Deshalb werden sie nicht zu einer scheinbar eindeutigen Gesamtzahl addiert. Die 546 PNGs sind ein im Originalresultat dokumentierter Captureumfang, keine neue Behauptung, jedes Bild visuell geöffnet zu haben. Das originale vollständige Flutter-Artefakt und die eingegrenzte `Lernen`-Hit-Test-Reichweite wurden bereits separat im benachbarten `flutter/`-Ordner gesichert.

Die neue Native-Prüfung ist im benachbarten `native/`-Ordner an Originalartefakt **14060103448** gebunden: **84 erforderliche Probeaufrufe** sowie statisch **117 PASS / 7 WARN / 0 FAIL**. Die Pflichtmarker und die Nextgen-/Studio-TSVs stimmen mit den eingefrorenen Helpern überein. Die separaten Touch-Dichtejobs sind kein Bestandteil dieses neuen Host-Native-Artefakts.

## Tatsächlicher Export und APK-Build

Der vollständige Build enthält zwei unterschiedliche Gradle-Phasen: Der Konfigurations-Vorcheck `verifyLumoSplitVersionCodes` benötigte 2 Minuten 35 Sekunden. Erst danach lief der tatsächliche Flutter-Aufruf `assembleRelease` **245,5 Sekunden** und erzeugte beide Release-APKs. Die zwischenzeitlichen Basisversionswerte des Konfigurationschecks sind nicht die finalen APK-Versionen.

| CI-verifiziertes Paket | Bytes | SHA-256 |
|---|---:|---|
| ARM64 APK | 322.123.041 | `c8f3f15a2e9eb77a1f03152f849f0e73211de91cd6f4299fb6555e557735a3d1` |
| x86_64 APK | 325.277.610 | `d2ffac6c1749284ae3c7e6439a6775f086bdcaec308595ae58b988dddf99bf93` |
| Gemeinsames Godot-PCK | 66.217.416 | `a5bd0c24692b97acad1ce48522f5f34aa56643009af341a70c5aaaa01b71dfe3` |

Beide APKs werden **zweimal** streng geprüft: im Buildskript und im nachfolgenden eigenständigen CI-Schritt. Die beiden JSON-Berichte je ABI stimmen vollständig überein. Sie nennen Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, Version **0.13.7+2019**, minSdk 24 / targetSdk 36, genau die jeweilige ABI, 16-KiB-ELF- und Ressourcen-Ausrichtung sowie das feste Familienzertifikat `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Der PCK-Bericht nennt Godot 4.6.3 und den vollständigen Native-Pin 76980. Die Offline-Sprachpaketprüfung umfasst 155 Clips einschließlich Modell-, Lizenz- und Bibliotheksprüfungen; sie ist kein Hörtest.

Diese Angaben stammen aus den echten CI-Verifierausgaben. Dieser Reviewer hat **keine APK-Binärdatei heruntergeladen oder lokal nochmals geprüft**. Die unabhängige Prüfung des Originalkandidatenarchivs liegt bei Root. Die Quellschutzlogik wurde am exakten e3d-Gitinhalt gelesen und gehasht: Vor/nach Vorbereitung, Abhängigkeiten, Export und Build werden Änderungen an versionierten Quellen abgewiesen, der Native-Pin wird erzwungen, und Build-Provenienz wird geschrieben. Der Inhalt der separaten `BUILD-PROVENANCE.json` ist nicht im Joblog abgedruckt und wird hier nicht als bereits direkt gelesen ausgegeben.

## Warnungen und praktische Grenzen

Der Analyzer ist **nicht fehler- und warnungsfrei**: Er meldet **103 Hinweise und 5 Warnungen, keine Fehler**. Der tatsächliche Aufruf setzt `--no-fatal-infos --no-fatal-warnings`. Die fünf Warnungen betreffen ungenutzte Methoden, Variablen bzw. Imports; Datei und Stelle stehen in `flutter-analysis-findings.json`.

Die alten nativen Filter erlauben nach vorhandenem Pflicht-PASS weiterhin drei Ressourcenfehler beim Szenenende (4, 2 und 4 Ressourcen) samt ObjectDB-Warnungen. Diese Zeilen stehen vollständig in den Rohlogs und in `strict-error-lines.json`; sie wurden nicht repariert und werden nicht als fehlerfreie Läufe dargestellt. Die native Notiz dokumentiert außerdem 96 Compatibility-Rendererwarnungen, 19 absichtlich ausgelöste Reward-ACK-Ablehnungen sowie die sieben statischen Bestandswarnungen.

Im vollständigen Job stehen **drei** ADB-Daemon-Verbindungsfehler: einer im nativen Prüfblock und zwei während Import/Export. Das sind keine Nachweise eines erfolgreichen Emulatorstarts. Weitere echte Diagnosen sind die nicht unterstützte Kotlin-Plugin-Version, veraltete Android-/Gradle-Einstellungen und APIs, ein Gradle-10-Kompatibilitätshinweis sowie die abgefangene Ausnahme `Already watching path: .../android`. Der tatsächliche Build und die strengen APK-Prüfungen waren danach erfolgreich; eine Ursachenbehebung der Watcher-Ausnahme ist damit nicht belegt. GitHub-Action-/Node-Abkündigungshinweise bleiben ebenfalls erhalten.

Dieser Job beweist weder den Abschluss der getrennten Android-35-/Android-37-Touren noch die 2017→2019-Datenerhaltung oder die finale Auslieferungsprüfung. Er ist kein physischer Fold7-, 60-FPS-, Wärme-, Latenz- oder hörbarer Sprachnachweis und erteilt keine vollständige visuelle oder finale Releasefreigabe.

## Dateien

`build-execution-review.json` enthält den gebundenen Befund; `verify-and-build-original.log` den vollständigen Originaltext. Die `raw/`-Auszüge sind unveränderte zusammenhängende Abschnitte mit Zeilen-/Hashmanifest. `parsed-apk-verifications.json` enthält alle vier tatsächlich ausgegebenen Berichte. `reviewed-source-manifest.json` bindet die neun gelesenen aktuellen Dateien an ihre e3d-Gitblobs. `SHA256SUMS` umfasst alle Dateien dieses Evidenceordners außer sich selbst.
