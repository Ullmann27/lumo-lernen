# LUMO 2015 — sichere Wiederaufnahme

## Vor jeder Änderung

Aktuellen Gitstatus, eigene Branches und GitHub-PRs455/152/456 neu lesen. Vorhandene uncommittete Arbeit sichern. Kein Reset, Clean, Force-Push oder main-Merge. Der getestete APK-Quellstand ist Flutter `2718f405e69c193d0121c6f6447fe53769d7c803` mit Godot `b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1`; reine Dokumentationscommits sind nicht nachträglich dessen Buildquelle.

## Bereits erledigt

1. Originalreferenzmappe, GLB/Rig und bisherige Integrationen tatsächlich geprüft; echte Vorheraufnahmen gesichert.
2. Erstes zusammenhängendes Sonnenhafenviertel, Garage und Original-Lumo implementiert; Rendererbilder/Clips und vollständige native Spieler-/KI-Fahrprüfungen bestanden.
3. Signierte ARM64-/x86_64-APK 0.13.3+2015 aus dem exakten Quellpaar gebaut. ARM64-Digest `3bb833935d47fca64efeceb753a48f663d48d3d43b3f02f3e9c798ba9538a4cb`, 318708477 Bytes. Paket/Testsignatur unverändert.
4. Unified-Run43024454590: verify-and-build, android-tour und update-from-2014 erfolgreich. Tatsächliche Artefakte und Ergebnis-JSONs sind gelesen; ARM64- und x86_64-PCK sind bytegleich.

## Noch abzuschließen

1. Aktuellen Head und Lauf von [QA-PR456](https://github.com/Ullmann27/lumo-lernen/pull/456) prüfen. Er verwendet ausschließlich das vorhandene Kandidatenartefakt13858046311 aus Run43024454590. Native Garage/Comet/Gecko/Bestätigen/Zurück/Pause/Weiterfahren und simulierte Fold-Garagen sind zusätzliche Pflichtnachweise dieses Arbeitsschritts. Nur tatsächliche Ergebnisse als PASS ausweisen.
2. Ergebnisartefakt rücklesen, ursprüngliche Screenshots prüfen und mit Quellen/Hashes im Godot-Integrationsbericht sichern. Tests niemals für einen grünen Status abschwächen. Ein fehlgeschlagenes SDK-Setup ist kein durchgeführter UI-Test; ein fehlerhafter Logabruf ist kein Absturzfreiheitsnachweis.
3. Erst danach die bestehende APK über einen tatsächlich berechtigten Veröffentlichungsweg bereitstellen. Der vorbereitete Zweig `chatgpt/lumo-2015-verified-apk-delivery-20261111`, Remotecheckpoint71abdee397bd7e2381af95b77f6524b395100c54, ist inaktiv. Sein früher Berechtigungscheck blockiert mit dem normalen Actions-Token bewusst vor Tag-/Release-Schreibzugriffen.

## Vorgesehene konkrete Release-Daten

- Zielquelle: exakt Flutter2718 und Godotb357; keine neue Version bauen, solange nur Nachweise ergänzt werden.
- Neuer Familienkanal-Tag: `coachpreview-build-2015`; vorhandene Tags/Releases nicht verändern.
- APK-Asset: `Lumo-Lernen-Neu.apk`; zugehörige Prüfsumme `Lumo-Lernen-Neu.apk.sha256`.
- Öffentliches Asset erst nach tatsächlicher Anlage verlinken; Dateigröße und unangemeldeten Download gegen den oben genannten Digest prüfen. Keine hypothetische URL als Lieferung ausgeben.
- Die vorhandene Testsignatur nicht mit Play-Produktionssignierung gleichsetzen. Keine zweite App und keine Löschung vorhandener Nutzerdaten.

Physische Android-/Fold-Leistung, Audio/Haptikempfinden und eine vollständige Android-Zweirundenfahrt sind nicht durch die vorhandenen Emulatorproben bewiesen. Die vollständige Spieler-/Gegnerdurchfahrt einschließlich Loopings/Rampen ist separat im tatsächlichen Desktop-Godot-Renderer geprüft. Umfang und offene visuelle Punkte: [STATUS.md](STATUS.md).
