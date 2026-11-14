# Studio: zusätzliche Originalbelege vom 14. November 2026

Diese Sammlung sichert die ausdrücklich ausgewählten Originalbelege, Gegenproben und Integrationsprüfungen. Sie enthält keine neue Android-Gesamtabnahme und verändert keine der ursprünglichen Fehlresultate.

## Quellen und geprüfte Binärdatei

| Bedeutung | Exakte Identität |
| --- | --- |
| Aktuelle reguläre Produktquelle, PR 466 | `c081cfaaa3e7ddedbca21a46f63dbe4a8cc0d111` |
| Gesonderte QA-Quelle für den Nachtest derselben APK, PR 478 | `3e08c7953b84aed6fff30e9e55665de75f79ec77` |
| Herkunft der tatsächlich für diesen Nachtest verwendeten unveränderten APK | `4ab96666f954baf258422d6ed277fc297b7ddeef` |
| Unveränderter nativer Godot-Stand | `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` |
| Vorgänger der QA-Reparatur mit den hier archivierten ursprünglichen Fehlern | `a446f3c1a320ad5297e17606727d801c5e993ce1` |
| Vorheriger Belegkopf dieser Dokumentationslinie | `372b9532ba73597be0d3893eae88a6ec1c18db11` |

Die neue Produktquelle wird durch diese Belege nicht als bereits auf Android bestanden dargestellt. Der gesonderte QA-Nachtest baut keine neue APK. Sein `github-checkpoint.json` bindet die APK ausdrücklich an 4ab und die Prüfer an 3e08. Die jeweiligen CI-Metadaten sind zeitgebundene Originalbeobachtungen; sie werden hier nicht zu späteren Ergebnissen umgedeutet.

## Inhalt und Aussagegrenzen

- `cards-readiness/`: 80 eingefrorene Belege aus den API35-/API37-Originalen sowie dem kleinen Readerfix. Beide ursprünglichen Nachtests erreichten die Lernbewegungen und Rückkehr sowie das erste vollständige Kartenfrontenpaar. Danach scheiterte die Layoutbeobachtung an derselben 113-Byte-Antwort über eine vorübergehend fehlende Datei. Die neue Behandlung bewahrt die Originalantwort und lässt den unveränderten begrenzten Beobachtungsloop erneut prüfen. Lokale positive Transportfolgen sind kein neuer Android-Draw-PASS.
- `german-controller/`: 15 Belege für die eng begrenzte deutsche Ansprachekorrektur, ergänzt um die ursprüngliche Paketliste. Der ausführbare Produktquellpfad wird nicht in diesem Dokumentationscommit installiert. Originalquellsnapshots und Patchtexte liegen ausschließlich unter `docs/evidence/`.
- `same-apk-qa/`: 16 ursprüngliche Vorbereitungsbelege, Paketmanifest, unabhängige Review und tatsächlicher GitHub-Checkpoint. Der Binder bindet genau 16 freigegebene QA-Abweichungen, das Originalartefakt und die tatsächlich gemessenen APK-/PCK-Bytes; die ursprünglichen Android-Gates bleiben bestehen. Neue Resultate dieses Nachtests sind in dieser eingefrorenen Sammlung noch nicht enthalten.
- `publication-guards/`: 20 zeitgebundene Originalbelege zu den ausgelösten Workflows und ihren Veröffentlichungsbedingungen. Ein laufender oder gesonderter historischer Workflow wird nicht pauschal als erfolgreich dargestellt.
- `integrated-source-checkpoint/`: Referenzmanifest der 37 integrierten Quellen, Integrations-/GitHub-Checkpoint sowie die drei zusätzlichen Cards-Prüfgruppen mit insgesamt 36 PASS (6 Reader, 18 Layout, 12 Lifecycle). Diese 36 werden getrennt von den vorherigen 131 lokalen Vertragsprüfungen geführt.
- `public-archive/`: Die 27 explizit erfassten Archivierungsdateien, darunter die unveränderte 99.443-Byte-Verifikations-ZIP mit 17 Mitgliedern, Originaljoblog, Quellbindungen, öffentliche Bytevergleichsbelege, unabhängige Review und der dokumentierte lokale Cleanup. Die 526.570.745-Byte-Creative-ZIP wurde unverändert öffentlich archiviert und nach unabhängiger Prüfung nur als lokale Duplikatkopie entfernt. GitHub meldet `immutable:false`; eine dauerhafte Unveränderlichkeit wird nicht behauptet. Der Creative-Lauf bleibt FAIL.

## Ablage und Integrität

Das Gesamtmanifest referenziert bereits vorhandene lokale Dateien. Für diese Sammlung wurden keine Bilder oder Originalarchive erneut kopiert und keine Quellen installiert. Quellmanifeste werden nur als Dokumentationsreferenzen aufgenommen; ihre darin aufgeführten Produktpfade werden nicht rekursiv übernommen. Bereits in Paketlisten enthaltene Quellmanifeste erscheinen genau einmal.

`collection-validation.json` enthält die tatsächliche Hashprüfung und die Kollisionsprüfung gegen 4.495 frühere Pfade plus 187 zuletzt veröffentlichte Pfade, zusammen 4.682. Alle Zielpfade dieser Sammlung beginnen mit `docs/evidence/studio-followup-20261114/` und sind neu. Das vollständige `upload-manifest.json` wird zusätzlich als Dokumentationsdatei gesichert; es ist wegen seiner Selbstreferenz nicht Teil seiner eigenen Dateiliste.

Die großen Android-ZIPs, APKs und das Creative-Gesamtarchiv sind ausdrücklich nicht enthalten. Physische Fold7-Leistung, 60 FPS und eine vollständige Master-Abnahme werden nicht behauptet.
