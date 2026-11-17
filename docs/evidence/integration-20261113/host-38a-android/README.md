# Host PR465 / 38a49f7d — abgeschlossener fehlgeschlagener CI-Versuch

Dieses kompakte Transportpaket gehört ausschließlich zu Host
38a49f7dda404923da3955592ccb213871f2027d, Tree
625b7940d9e8a4ddf32203126721efd97b3e8c2e, und dem originalen
PR-Versuch 1 des Workflows **LUMO Kart graphics 2019 Android candidate**:
https://github.com/Ullmann27/lumo-lernen/actions/runs/43497829121

Der Lauf endete am 13.11.2026 um 20:17:27 UTC mit **FAILURE**.

## Tatsächlich erreichte Ergebnisse

- Echte Android-Host-Kompilation: **PASS**, neun geforderte Klassen gegen
  Godot-AAR 4.6.3.stable; zehn vorgeschaltete Verträge ohne Skip bestanden.
- Vollständige Flutter-Suite: **2.512 PASS, 0 Skips, Exit 0**.
  Die Originalmaschine enthält zusätzlich 556 verborgene erfolgreiche
  Lade-/Hilfsereignisse; diese werden nicht als weitere Fachtests gezählt.
- Build- und Erhaltungsverträge: **436 Tests, genau ein Fehler, Exit 1**.
  LongParentScrollTest.test_existing_default_search_is_not_silently_unbounded
  erwartet in scripts/tests/test_android_voice_scroll.py:66 noch 24
  Beobachtungen. Der vorhandene Leser beobachtet nach dem letzten erlaubten
  Scrollschritt nochmals: 13 Beobachtungen je Richtung ergeben 26, bei
  weiterhin höchstens zwölf Gesten je Richtung.
- APK-Bau, native Gameplay-Gates dieses Hostjobs, API-35/API-37-Touren,
  2017→2019-Erhaltung und Android-Abschlussprüfung wurden nicht ausgeführt.
  GitHub liefert für die vor Expansion übersprungene Tourmatrix genau einen
  Platzhalterjob mit dem ursprünglichen Ausdruck als Namen.
- Der Publisher ist **SKIPPED**. Seine veröffentlichte Bedingung akzeptiert
  nur den Grafik-Producerzweig, nicht den Integrationszweig.

## Inhalt und Originaltreue

original-evidence.tar.gz enthält die vollständigen unveränderten finalen
GitHub-REST-Antworten einschließlich aller Jobs und Schritte, die vorherigen
Status-Snapshots, beide vollständigen Rohjoblogs, den kleinen originalen
Compiler-ZIP samt seinen fünf Originaldateien, die ursprüngliche
Flutter-Zusammenfassung und den vollständigen Maschinenlog, Quellen,
Verifikationen sowie vollständige ZIP-Member- und PNG-Indizes.

Die drei großen Raster-ZIPs und alle 576 Original-PNG bleiben im benannten
Scratch-Originalcheckpoint. Ihre Herkunft, IDs, Originaldigests, Größen und
vollständigen Memberhashes stehen im Manifest und den archivierten Indizes.
Es wurden keine Bilder neu kodiert. Insgesamt wurden vier Original-ZIPs,
601 Member und 576 PNG transport-/decoderseitig geprüft. Dies ist keine
menschliche Bild- oder Android-Laufzeitfreigabe.

Jedes archivierte Mitglied wurde nach Entpacken erneut bytegleich mit der
Originaldatei verglichen. manifest.json und file-list.tsv enthalten die
vollständige Zuordnung und Original-/Roundtrip-SHA256. Die äußere
SHA256SUMS bindet die vier Transportdateien.

Die separat erzeugte .ci-results/build-contracts.log wurde vom Workflow
nicht hochgeladen. Der vollständige originale Konsoleninhalt samt
Zeitstempeln ist im Fehlerjoblog erhalten; eine zusätzliche Originaldatei
wird nicht behauptet. Kein neuer Lauf, Quellpatch, Commit, Pin oder Receipt
wurde durch diesen Collector erzeugt.
