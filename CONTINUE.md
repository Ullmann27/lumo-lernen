# LUMO 2015 — sichere Wiederaufnahme

## Vor jeder Änderung

Aktuellen Gitstatus, eigene Branches und GitHub-PRs455/152/456 neu lesen. Vorhandene uncommittete Arbeit sichern. Kein Reset, Clean, Force-Push oder main-Merge. Der getestete APK-Quellstand ist Flutter `2718f405e69c193d0121c6f6447fe53769d7c803` mit Godot `b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1`; reine Dokumentationscommits sind nicht nachträglich dessen Buildquelle.

## Bereits erledigt

1. Originalreferenzmappe, GLB/Rig und bisherige Integrationen tatsächlich geprüft; echte Vorheraufnahmen gesichert.
2. Erstes zusammenhängendes Sonnenhafenviertel, Garage und Original-Lumo implementiert; Rendererbilder/Clips und vollständige native Spieler-/KI-Fahrprüfungen bestanden.
3. Signierte ARM64-/x86_64-APK 0.13.3+2015 aus dem exakten Quellpaar gebaut. ARM64-Digest `3bb833935d47fca64efeceb753a48f663d48d3d43b3f02f3e9c798ba9538a4cb`, 318708477 Bytes. Paket/Testsignatur unverändert.
4. Unified-Run43024454590: verify-and-build, android-tour und update-from-2014 erfolgreich. Tatsächliche Artefakte und Ergebnis-JSONs sind gelesen; ARM64- und x86_64-PCK sind bytegleich.

## Noch abzuschließen

1. Aktuellen Head von [QA-PR456](https://github.com/Ullmann27/lumo-lernen/pull/456) prüfen. Letzter belegter Stand: `a1d581f0b0b392e0bc4ad7d90fd38d14f8d74095`, Run43034616066, Versuch2, Job130572125063. Beide Versuche dieses Runs scheiterten vor dem Emulator am DNS-Preflight der offiziellen Ubuntu-Paketquellen. Keine Laufzeitprüfung dieses Stands und kein vollständiger Garage-PASS. Nach nachweislich wieder verfügbarer Abhängigkeitsquelle denselben unveränderten Test erneut ausführen und den tatsächlichen neuen Versuch/Job sichern; kein Neustart der APK-Produktion erforderlich.
2. Die Probe verwendet ausschließlich Kandidatenartefakt13858046311 aus Run43024454590. Native Garage/Comet/Gecko/Bestätigen/Zurück/Pause/Weiterfahren und simulierte Fold-Garagen bleiben zu prüfen. Originalresultat, unveränderte Screenshots und quantitative Fahr-/Pausenwerte auslesen. Nur tatsächliche Ergebnisse als PASS ausweisen; Tests nicht für einen grünen Status abschwächen. Bereits gesicherte Fehler-/Teilnachweise stehen im Godot-Nachweiscommit `e885b145c500da3db979c33b437c0432891be3ad`; der frühere echte Garageframe ist kein vollständiger UI-PASS.
3. Erst danach die bestehende APK über einen tatsächlich berechtigten Veröffentlichungsweg bereitstellen. Der vorbereitete Zweig `chatgpt/lumo-2015-verified-apk-delivery-20261111`, Remotecheckpoint `2bb543dd76f75bfacc48bd0cc508b8fce67581bf`, ist inaktiv. Sein zusätzlicher Garagenguard bindet derzeit den fehlgeschlagenen Versuch2 ausdrücklich und lehnt ihn ab; die Bindung darf nur nach Prüfung eines tatsächlich erfolgreichen Folgeversuchs aktualisiert werden. Der frühe Berechtigungscheck blockiert mit dem normalen Actions-Token weiterhin vor Tag-/Release-Schreibzugriffen. Ein passender Browserzugang oder eine tatsächlich verfügbare Release-Funktion ist weiterhin erforderlich.

## Vorgesehene konkrete Release-Daten

- Zielquelle: exakt Flutter2718 und Godotb357; keine neue Version bauen, solange nur Nachweise ergänzt werden.
- Neuer Familienkanal-Tag: `coachpreview-build-2015`; vorhandene Tags/Releases nicht verändern.
- APK-Asset: `Lumo-Lernen-Neu.apk`; zugehörige Prüfsumme `Lumo-Lernen-Neu.apk.sha256`.
- Öffentliches Asset erst nach tatsächlicher Anlage verlinken; Dateigröße und unangemeldeten Download gegen den oben genannten Digest prüfen. Keine hypothetische URL als Lieferung ausgeben.
- Die vorhandene Testsignatur nicht mit Play-Produktionssignierung gleichsetzen. Keine zweite App und keine Löschung vorhandener Nutzerdaten.

Physische Android-/Fold-Leistung, Audio/Haptikempfinden und eine vollständige Android-Zweirundenfahrt sind nicht durch die vorhandenen Emulatorproben bewiesen. Die vollständige Spieler-Zweirundenfahrt wurde im Desktop-Godot-Renderer geprüft. Die 30 vollständigen KI-Zweirundenfahrten wurden mit der Produktions-KI ohne Bildausgabe geprüft. Ergänzende GL-Tests prüfen echte KI-Looping-Anfahrten sowie geschwindigkeitsabhängige Rampenflüge und Landungen; sie ersetzen keinen gerenderten vollständigen KI-Rennlauf. Umfang und offene visuelle Punkte: [STATUS.md](STATUS.md).
