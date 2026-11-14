# Originalbelege zum Studio-Kandidaten 4ab96666

Diese erste Beleglieferung betrifft ausschließlich **Host `4ab96666f954baf258422d6ed277fc297b7ddeef`** mit Native **`803e7a626ea6ef0aeeda9c37010e844033d3a8e3`**. Der Entwicklungszweig des Kandidaten bleibt unverändert. Die Dokumentationsbranch ist kein neu gebauter APK-Quellstand.

## Bereits abgeschlossene neue Prüfungen

[Verpflichtender Android-Workflow 43530667812, Versuch 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43530667812).

| Prüfung | Tatsächliches neues Ergebnis | Originalbeleg |
| --- | --- | --- |
| Android-Hostkompilierung | SUCCESS; tatsächliche Kotlin-/Java-Klassen einschließlich MainActivity, LumoGameActivity, Cards und Offline-Sprache; Gradle 2 min 41 s | [Review](host-compile/review.json), [Originalresultat](host-compile/original/result.json), [vollständiger Joblog](host-compile/job-original.log) |
| Vollständige Flutter-Suite | **2.514 PASS, 0 FAIL, 0 SKIP**; finales Maschinenereignis success=true bei 517,401 s | [Originalzusammenfassung](flutter/original/acceptance-summary.json), [Originalmaschinenlog](flutter/original/flutter-machine.jsonl), [Auswertung](flutter/review.json) |
| Flutter-Bildinventar | 546 PNG-Einträge in einem neuen Originalartefakt mit 548 Mitgliedern; alle ZIP-Mitglieder CRC-geprüft | [Vollständiges Archivinventar](flutter/archive-inventory.json) |

Das Flutter-Originalartefakt **14087637888** hat **333.604.197 Byte**, SHA256 `dea2a82c895e3cc3822e4880dba28f3fb1437ec2ce8adbb60be50fda3ead2d4c`. Das Android-Hostartefakt **14086444645** hat **5.393 Byte**, SHA256 `b8aacb680c8cc30398fc8ac78d11a438a03fb172619148c29a425a2d35304861`. Die originalen Artefaktmetadaten binden beide an den oben genannten Run und Host-Commit. Das große Flutter-ZIP wird nicht als zusätzlicher Git-Blob dupliziert; seine beiden ursprünglichen Ergebnisdateien und sein vollständiges Mitgliedsinventar sind hier gesichert.

Der rohe Flutter-Maschinenlog enthält neben Ereignisobjekten auch normale Prozessausgabe. Die unabhängige Auswertung erhält und zählt diese 750 Nicht-Ereigniszeilen; sie zählt 2.514 sichtbare Testabschlüsse und 555 erfolgreiche interne/verborgene Abschlüsse getrennt. Die 555 internen Einträge werden **nicht** als zusätzliche Produkttests ausgegeben.

## Zu diesem Zeitpunkt noch offen

Die anschließende native Gesamtprüfung innerhalb des Host-Builds läuft. Der neue APK-Bau, API35, API37/Android17, die 2017→2019-Updateprobe, Creative-Android und der Publisher haben noch keine erfolgreiche Gesamtabnahme in dieser Beleglieferung. Der Status-Snapshot bleibt historisch; spätere Ergebnisse werden separat ergänzt.

Die 546 Flutter-PNGs wurden inventarisiert, **nicht alle manuell angesehen**. Native803 besitzt unabhängig davon bereits die gesonderte aktuelle Abnahme mit 32 tatsächlich gesichteten Bildern. Kein Headless-, Software-Renderer- oder Medien-FPS-Wert wird als Fold7-Messung ausgegeben.

## Ergänzende Bestandsbefunde

Die Wartezeit wurde für drei eng begrenzte Untersuchungen der noch offenen Produktanforderungen genutzt:

- [Original-Lumo: tatsächliche Gesichtsgeometrie und Riggrenzen](../lumo-face-readonly-20261114/FACE_RIG_FINDINGS.md). Zwei neue echte Blender-Nahaufnahmen zeigen die unveränderte Geometrie; sie sind keine neue Gesichtsanimation. Original-GLB und Körper-Action-Library blieben hashgleich.
- [Memory, Vier Gewinnt und Quizshow: konkrete vorhandene Regeln und Anschlussstellen](../next-native-games-interface-20261114/READ_ONLY_INTEGRATION.md). Zwanzig Hostquellen sind an4ab gebunden. Der Bericht ist keine fertige native Umsetzung.
- [Englisch: vorhandene Aufgaben, Objekt- und Sprachgrenzen](../english-3d-readonly-20261114/ENGLISH_3D_READONLY_FINDING.md). Dreiundzwanzig relevante Dateien wurden an4ab/803e gebunden. Die vorhandene lokale Sprachschnittstelle ist auf Deutsch ausgelegt; englische Aussprache wird nicht als implementiert behauptet.

Diese Dateien ändern keine Produktquelle, Speicherformate, Versionsnummer, Native-Pin, Receipt, Workflow oder Schwelle. Sie erweitern ausschließlich den überprüfbaren Arbeitsstand. **Main wurde nicht verändert oder zusammengeführt.**
