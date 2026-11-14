# Native-Producer-Triage: eingefrorener Lesestand 14.11.2026, 20:54:51 UTC

## Ergebnis und Grenzen

Die gelesenen Producerstände enthalten echte neue Funktionen. Keiner der drei vollständigen Headbäume wird hier zur unmittelbaren Übernahme freigegeben. Der akzeptierte Native-Pin bleibt `84789d0c2c6fb4b6ecd2897ce1951b89f958b604`, Tree `91cc8fc1c6f8a36336b7ac9a12585284a983a6f6` (3770 Dateien). Host `ec936873a45ffeb9ab347cc6bdb10951e38fac5e` und sein laufender Gesamtlauf 43633922088/1 bleiben unverändert.

Dies ist eine Quellen- und Evidenztriage: keine neue Engine-, Test-, Renderer- oder Emulatorausführung; kein neuer Bilder-/Artefaktdownload und keine visuelle Abnahme dieser Produceränderungen. Nur bereits abgeschlossene Joblogs wurden einmal gelesen. Bewegliche Zweige und spätere Nachfolger sind damit nicht vollständig abgenommen.

| Priorität / eingefrorener Stand | Tatsächliches PR-Delta gegen seine Basis | Befund gegen Native847 |
|---|---:|---|
| #182 `29080ef8cd1a5b385eeeec97976fbefd31280427` | 38 Dateien: 23 Produkt, 10 Tests, 2 Tools, 2 Workflows, 1 Dokument | Neue Englisch-/Memory-/Quiz-Funktionen; 33 neue und 5 andere Dateien. Eigene Desktop-Autoritätsläufe erfolgreich. Gemeinsame Host-/Bootanbindung fehlt am geprüften PR-Head bzw. aktuellen Host. |
| #183 `c84926650363c2faab8a83ee592ebd7aa8486a6d` | 42 Dateien: 19 Produkt, 17 Tests, 1 Tool, 5 Dokumente | Neue lange Strecken, Rivalenadapter und feste Items; 23 neue und 19 andere Dateien. Kein Actions-Lauf genau auf diesem Skip-CI-Head. Ein bestehender Physikvertrag scheitert nachweislich mit seinen Runtimebytes im #184-Testmerge. |
| #184 `b875e1e58f9c0c101ddabc74c98d4498e2215fbf` | 9 Dateien: 4 Produkt, 2 Tests, 2 Workflows, 1 Dokument | Modulare Strecken-/Fahrzeugteile, 5 neue und 4 andere Dateien. Enger Modular-Test grün; zwingende Abhängigkeiten auf #183. Gesamtkatalog 16 erfolgreiche und 4 fehlgeschlagene Läufe. |
| #181, nur angeforderter alter Head `3213d2aca377476cf4959f380701d87177cec959` | Vier genau benannte Reparatur-/Testdateien | Alle vier Blobs und Modi bereits identisch in847. Kein erneuter Import nötig. |
| #181, während der Lektüre beobachteter Nachfolger `2cea87a45a10c92cf46e752b759452925bc2f2ea` | Neuer Commit direkt nach3213 | Separat und ungeprüft. Seine behaupteten Android-Dichte-/HUD-Korrekturen werden nicht in die Äquivalenz des alten3213 eingeschlossen. |

## Englisch, Memory und Quiz: echte Prüfungen, konkrete Anschlussgrenze

Run43611803404 verwendet Native29080 zusammen mit Host `50503fef8e93700d9a889e33c3d2c37fccb46e42`. Die drei unveränderten Originaljoblogs liegen unter `original-logs/`; konkrete Zeilen stehen in `original-marker-index.json`:

- Quiz: 28 Dartfälle, 1786 Checks, 0 Skip; Native-Runtime 381 Checks und6 Aufnahmen.
- Memory: 30 Dartfälle/1694 Checks, Scheduler7 Fälle/13 Checks; View7020 Checks/8 Aufnahmen; Native-Runtime244 Checks/57 Inputs.
- Englisch: 10 Dartfälle/2955 Checks; Native7633 Checks/17 Aufnahmen/196 Inputs.

Run43611803408 hat neun erfolgreiche Studiojobs; zwei weitere aktuelle Head-Läufe (Stage2 und Stunts) sind ebenfalls erfolgreich. Diese zusätzlichen Erfolge sind hier Metadatenbelege. Ihre Bildarchive wurden für diese Triage nicht geladen. Die Autoritätslogs erklären selbst die simulierte Speicher-/Lifecycle-Transportgrenze; daraus folgt kein Android-Binder-, vollständiger APK- oder FPS-Nachweis.

Am PR182-Head enthält `scripts/app/app_boot.gd` (Blob `2fc3b5ea4fac7440733ae5a77a8289bcd57557f6`) Memory und Quiz nicht in der Start-Allowlist; unbekannte Ziele fallen auf games zurück. Der aktuelle Hostec lässt in `tools/auto_install/MainActivity.kt` ebenfalls weder memory/quiz noch Englisch/english_objects zu. Direkt gestartete Szenen im Autoritätstest schließen diese Produktanbindung nicht.

Der bereits existierende Integratorcommit `9f8341494ea316c9e36ed6722915ab34b22e67bd` hat eine eng erkennbare Bootkorrektur und kombinierte Lernweltbytes; beides steckt bereits in der Basis von #183/#184. Das ist ein möglicher Quellbaustein für eine spätere geprüfte Union. Seine im Committext genannten lokalen Boot-/Layoutzahlen wurden hier nicht als eigene Originaltestbelege nachgespielt.

## Kart: tatsächlich roter bestehender Vertrag

Der Originaljob132583042859 (Run43639314835) enthält:

```text
SCRIPT ERROR: Assertion failed: A ring uses only one opaque draw surface
[KartPhysics] FAIL: 22 of 23 checks completed
```

Zeilen2868 und2878 des unveränderten Originalprotokolls. Tatsächlicher Checkout war PR-Testmerge `124cd70d1bfc11c160a87b88ac5a6df902330ee8`, Eltern c849+b875, Tree `ff28b46bdb556c16b6ccdcf428af4a0709b60da8`. Der vollständige Tree unterscheidet sich von b875 nur im Adventure-README und zwei Export-/Blender-Werkzeugen; Runtime und Physiktest sind identisch.

Der unveränderte Physiktest (Blob `da9e5186a46316996cc44a44b1f2c6c4a83f7d61`, auch exakt in847) verlangt eine direkte einzelne Ring-Oberfläche und einen direkten ResonanceHalo-Knoten. Die neue Resonanzproduktion (Blob `4ee7b58ce3987f1e08bc1f5e80abf5405477f145`) verwendet dagegen GateStructure, OutcomeSymbols und GateMotion mit verschachtelter Geometrie. Das ist ein konkret belegter Konflikt zwischen neuer Geometrie und bestehendem Pflichtvertrag. Diese Triage schwächt die Prüfung nicht und entscheidet nicht ungeprüft, ob ein Produktumbau oder eine gleichwertig strenge Vertragsaktualisierung fachlich richtig wäre.

Der enge Modular-Originaljob132583042906 ist tatsächlich erfolgreich: 12 mobile Strecken, 2 Detail-Szenen, vier aktive Chassis. Der B5-Originaljob132583042835 bestätigt DynamicCoastalFoam, SonnenhafenWater und KartTerrainExtent. Beide stammen ebenfalls aus Testmerge124cd70.

Zum eingefrorenen Schlussstand sind alle20 b875-Läufe terminal:16SUCCESS,4FAILURE. Weitere rote Läufe sind VideoReferenceGrade43639314931, Stage243639315027 und Stunts43639314916. Für diese drei wurde kein Originalfehlerlog abgerufen; ihre Ursache bleibt hier ausdrücklich offen.

#183 enthält nur vorbereitete Adapterverträge für fünf weitere Rivalenmodelle; die neuen externen Modelle sind nicht geliefert und bleiben deaktiviert. Die eingecheckte Fahrtevidenz meldet zwölf abgeschlossene Streckenassertionen in zwei Prozessen und ausdrücklich `single_process_suite_completed:false`. Sie ist ein Producerbericht; die dort bezeichneten Rohfahrlogs wurden in diesem Tree nicht als vollständige Originale vorgefunden. Studio-Blenderbilder und abgebrochene Gesamtweltrender werden nicht als Android- oder Runtime-Abnahme ausgegeben.

## Erhalt der bestehenden Integration

Vollständige ungekürzte Treekataloge und path/mode/blob-Vergleiche sind enthalten. Gegen847 fehlen im vollständigen #182-Head1618 akzeptierte Dateien, in #183/#184 jeweils81. Das sind keine geeigneten Ersatzbäume für847.

#183/#184 bewahren unter anderem die aktuellen Original-Hub-, Dorf-, Dream- und Discovery-Readerbytes. Sie enthalten jedoch unseren `tools/validate_live_connections.sh` und fünf zusätzliche bestehende Workflowdateien nicht. Ihr Discoveryworkflow verliert den aktuellen Live-Branch-Trigger und die referenzbezogene Concurrency. Eine spätere Union muss diese bestehenden Verbindungen explizit erhalten; ein pauschaler Baumtausch ist ausgeschlossen.

Die vier alten Village-Dateien sind in `comparisons/village181-four-paths.json` exakt mit Modi und Blobs belegt. Der von HostPR502 verwendete Nativepin570bc enthält sogar eine ältere Worlddatei (`99da8235...`) als847/3213 (`149a4386...`). Der neu beobachtete2cea wird ausschließlich als neuer, noch nicht geprüfter Nachfolger dokumentiert.

## Archiv und Reproduzierbarkeit

- `review.json`: maschinenlesbare Befunde, genaue Köpfe, Abhängigkeiten und Grenzen.
- `trees/`: vollständige rekursive Kataloge, API-Trunkierung jeweilsfalse; kanonisch serialisierte API-Daten.
- `metadata/`: eingefrorene PR-/Commit-/Run-/Jobmetadaten, nicht live nachgeladen.
- `comparisons/`: vollständige PR-Dateilisten, daraus abgeleitete Vergleiche und Ahnenbezüge.
- `original-logs/`: sechs vollständige ursprüngliche dekodierte UTF-8-Joblogs, vorhandene Steuerzeichen/BOM unverändert.
- `read-sources/`: gelesene Gitblob-Quellen unverändert.
- `manifest.json`: SHA-256, Gitblob und Länge jedes Archivbestandteils außer dem selbstreferenziellen Manifest.

Nur dieser eigene Evidenzzweig wird ergänzt. Produktbytes, zentrale Host-/Nativerefs, PRs, laufende Workflows und Veröffentlichung bleiben unverändert.
