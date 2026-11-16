# Unveränderte APK 2031: vorbereiteter vollständiger Android-Replay

Diese Lieferung ergänzt ausschließlich neue QA-/Veröffentlichungsdateien auf
`9886f6637589c23cbae23ccca311090c35cdea8e`. Sie baut keine APK, führt keine
Androidtour aus und veröffentlicht kein Release. Die Home-Transition-/Primärfehler-
Korrektur wird separat integriert; dieser Komponentenlauf enthält sie noch nicht.

## Exakte vorhandene APK und Herkunft

Die APK-Quelle bleibt `e05a96a52aaf57e466e79831f15aaffd144284ee`, Version
`0.13.19` / `2031`, Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.
Originalrun: **43800892196**; validate **133080632526** und build
**133085378884** bestanden, Androidjob **133088843594** scheiterte.

| Gegenstand | Originalartefakt | ZIP-Bytes / SHA-256 | APK-Bytes / SHA-256 |
|---|---:|---|---|
| x86-Prüf-APK | 14197503039 | 538205923 / `fb6cd632881655755a1ac013c508226a57a735418b1884e01c7caa1aa06bd6e5` | 538191823 / `8e96a05c51fc12504a19831cee14b64c6a8e9a35a8a36863db455bed0e2cec1a` |
| ARM64-Download | 14197576182 | 535040468 / `0c254fbc74c13c4ecd98bec2f31203ee93c6c51818150d0fa115a10fad192fa4` | 535026362 / `e6ca8e512ddc56755ae8664b3438b0e78b87a7f0e77f1cd55cac592b20b316d7` |

Beide APKs enthalten die PCK
`94b0a84b8715537fff9ff84e451c889ca1fe1b8440a4448ded93989b3feb0aef`.
Paket und bestehendes Testzertifikat bleiben in den fest gebundenen Konstanten
und der Konfiguration enthalten. Die tatsächliche x86-ZIP-Herkunft ist im
unveränderten Ausschnitt `original-x86-upload.log` aus dem vollständigen Build-
Joblog belegt; die beiden beigefügten Metadatendateien sind Originalkopien.
Die APK-Innenwerte stammen aus `docs/nextgen/evidence/ci-2031-build/summary.json`
und den dortigen ursprünglichen `VERIFY-*.json`.

Der alte Androidfehler bleibt **FAIL**: Home wurde in der Wortpause unmittelbar
abgefragt; ein anschließender Video-Dauerfehler überlagerte die primäre Ausnahme.
Das spätere Bild zeigt den Launcher, der frühe Activity-Rohdump fehlt. Die
Ursache wird hier nicht als Produktfehler oder sicher bewiesenes Übergangsrennen
umgedeutet. Das ursprüngliche FAIL-Artefakt **14197925395**, **29373558 Bytes**,
SHA-256 `f2d1ca9232685fe4d25fcd8d6bd745a687f08ac7eb4ef1c5ec36e469d0ba03f4`,
wird auch vom Publisher unverändert heruntergeladen und mit ausgeliefert.

## Vollständiger neuer QA-Weg

Der bestehende 2028-Replay dient als Vorlage. Die neue Probe überprüft den
gesamten committed Git-Diff gegen die APK-Quelle, auch bei sparse checkout.
Produktcode, Assets, Buildvorlagen, Paket-/Native-Pins und sonstige nicht
freigegebene Pfade sind ausgeschlossen. QA-Commit, QA-Run, ursprüngliche
APK-Quelle und ursprünglicher Buildrun bleiben getrennte Felder.

`qa/lumo-nextgen-2031-android-20261116` wird durch eine Änderung an
`config/nextgen-2031-replay.json` oder `workflow_dispatch` ausgelöst. Alle
Identitätswerte der Konfiguration müssen exakt den eingefrorenen Konstanten
entsprechen; nur die positive `replayAttempt` darf erhöht werden. Die Probe
prüft erneut die echten GitHub-Run-/Job-/Artefaktmetadaten, ZIP-Größe und -SHA,
APK-Innenwerte und tatsächliche APK-Bytes. Eine abgelaufene oder abweichende
Datei wird abgewiesen.

Der Bash-Runner arbeitet weiterhin mit `set -euo pipefail`: zuerst die gesamte
aktuelle Originaltour, danach erst die komplette Referenztour. Deren Reset
verlangt die neue erfolgreiche Originaltour, deren tatsächliches Ergebnis-Hash,
installierte APK, selben Emulator und UI-erzeugtes Testprofil. Banane behält
drei Silbenschritte und vier beobachtete Wiedergabesegmente; Muster behält den
ungewerteten Native-Rückweg und den getrennten optionalen Core-Antwortweg.
Warum-zuerst-zwei, gemeinsame Audio-/Figur-/Effektfenster, Grenzen der
Aufnahmedauer und alle bisherigen Ausführungsgates bleiben erhalten.

`ReplayProbe` erbt die aktuelle `CurrentCandidateProbe`: ihr vorhandener
mehrzeiliger Musterleser wird auch hier verwendet. Nur die beiden
Identitätshooks wechseln in den expliziten Immutable-Replay-Modus; der normale
`current-build`-Pfad verlangt unverändert QA-Quelle gleich APK-Quelle.
Ausgabe: `lumo-nextgen-2031-replay-evidence` mit getrennten Original- und
Referenzergebnissen und geprüftem `replay-result.json`.

## Veröffentlichung erst nach tatsächlichem Erfolg

Der Publisher und sein Workflow müssen bereits im geprüften QA-Tree liegen.
`QA_BOUND_FILES` bindet die tatsächlichen Reader-/Signatur-/Capture-/Publisher-
Abhängigkeiten, aktuelle Gates, Tests, Musterfixture und Replaykonfiguration
bytegleich an den erfolgreichen QA-Commit. Diese Gatequellen dürfen zwischen
Prüfung und Veröffentlichung nicht wechseln.

**Es wurde keine `config/nextgen-2031-replay-publish.json` angelegt.** Erst nach
einem echten erfolgreichen Replay sind folgende beobachtete Werte einzutragen:

| Feld | Verbindliche Herkunft |
|---|---|
| `schemaVersion` | Ganzzahl `1` |
| `apkSourceCommit` | unveränderte APK-Quelle `e05a96a52aaf57e466e79831f15aaffd144284ee` |
| `qaCommit` | exakte vollständige SHA des erfolgreichen neuen QA-Commits |
| `qaRun` | tatsächlicher eigener erfolgreicher Workflow-Run |
| `qaArtifact` | originale GitHub-Felder `id`, `name`, `size_in_bytes`, `digest`; Name `lumo-nextgen-2031-replay-evidence` |

Trigger: `delivery/lumo-nextgen-2031-replay-20261116`, ausschließlich der neue
Publishconfig-Pfad beziehungsweise `workflow_dispatch`. Beide tatsächlichen
Touren und ihre gemeinsamen Gates werden erneut geprüft. Das alte FAIL bleibt
FAIL. Nur ein wirklich beobachtetes HTTP 404 für **Release und Tag** erlaubt die
Neuanlage. Das Release und sein Tag müssen auf die **APK-Quelle**, nicht die QA-
oder Publikationsquelle, zeigen. Der unveränderte gemeinsame Public-Download-
Helfer prüft genau ein veröffentlichtes APK-Asset und liest anschließend die
gesamte Datei anonym mit exakter Bytezahl/SHA. Ein bestehendes Release wird
nicht geändert.

## Tatsächlich durchgeführte Komponentenprüfung

`component-gates.log`: **24/24 Pythonprüfungen bestanden**, keine Skips. Dazu
gehören die bestehenden negativen Herkunfts-/Gatefälle, echte lokale Git-/Shell-
Prozesse und der vorhandene bytegleiche zweizeilige Original-Patternframe.
Die künstlichen Ergebnisobjekte sind ausdrücklich reine Prüferfixtures, kein
Androidnachweis. `syntax-cli.json` belegt Python-AST, YAML, alle Shellblöcke und
CLI-Hilfe. Die endgültige integrierte Homefix-Prüfung und jeder Androidlauf
stehen aus. `source.json` bindet die tatsächlich geprüften lokalen Dateibytes.

`fullModernizationComplete` bleibt false. Physisches ARM64/Fold7, echte erkannte
Sprache, akustische Qualität und 60 FPS werden durch diese Vorbereitung nicht
belegt. Keine Remote-, Build-, Installations- oder Veröffentlichungsaktion wurde
in diesem Komponentenauftrag ausgeführt.
