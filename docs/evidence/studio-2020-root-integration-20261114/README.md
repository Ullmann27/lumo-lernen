# Studio 2020: Root-Integration bis zum Native-Folgecommit

Diese zusätzlichen Originalbelege dokumentieren die kontrollierte Integration der Agentenpakete. Sie ergänzen die getrennten eingefrorenen Pakete für Charakter, Vier Gewinnt, Androidverträge und die konkreten CI-Fehler. Ein Dokumentencommit installiert keine neue App.

## Tatsächlicher Quellstand dieses Freeze

- Hostbasis: `86445f53af5d573549fc8cf03405261611f3cb7e`. 68 ausdrückliche Host-Code-/Testdeltas sind lokal zusammengesetzt und ihre unveränderlichen Gitblobs wurden in GitHub bestätigt. Der endgültige Host-2020-Commit existiert zu diesem Freeze noch nicht. Die vorläufigen Manifeste sind ausdrücklich entsprechend gekennzeichnet.
- Erste gemeinsame Nativequelle: `8be3a95d5d948d457c4c39bc6694138d60b70027`. Deren tatsächlicher Run `43561885899` endete fehlgeschlagen; die vier erfolgreichen und zwei fehlgeschlagenen gestarteten Jobs sowie die drei übersprungenen Folgejobs werden nicht umgedeutet.
- Veröffentlichte Korrektur: `acf51d3bd2997c4b731e9a48e1791e05e756a132`, Tree `625d501c8517fa88787a0a415cd5d5b2e75ac845`, Draft Native-PR167. Gegenüber 8be3 genau vier korrigierte Bestandsdateien und ein neues Dokument; alle anderen 2.230 Dateien unverändert.
- Der neue vollständige Run `43565059832` wurde tatsächlich angelegt und läuft. Dieses Paket enthält seinen ursprünglichen Startmetadatenstand und behauptet keinen abgeschlossenen Erfolg.
- Main und der bisherige Studio-2019-Branch wurden durch die dokumentierten Mutationen nicht verändert.

## Lokale Integrationsprüfungen

Die enthaltenen Protokolle sind echte Ausführungen an den jeweiligen zusammengesetzten Quellen. Die erste Deliverygruppe bestand 59 Tests. Eine spätere gezielte Ergänzung der verpflichtenden Treasure-Bilder bestand 10 Tests; diese Wiederholung wird nicht als 59 + 10 unterschiedliche Tests ausgegeben.

Die zusammengesetzten Android-/Runtime-Verträge und Creative-/Versions-Verträge sind in ihren separaten Ausführungsmetadaten gebunden. Nach Integration der endgültigen C4-Publisher-, Originalarchiv- und Deadlinepakete wurden 29, 20 und 27 entsprechende Fälle erfolgreich ausgeführt. Das sind lokale Vertrags-/Fixtureprüfungen und kein neuer realer Androidlauf.

Die Sprachinstallation wurde mit der tatsächlichen zusätzlichen Kotlin-Klasse geprüft. Die eigentliche gemeinsame Android-Hostkompilierung und APK-Prüfung bleiben erforderlich. Die vorbereiteten 2020-Pintests sind in diesem Freeze noch nicht ausgeführt oder als Sourcefreigabe verwendet; bestehende Policy, Versionsdatei und historischer 2019-Pin wurden noch nicht geändert.

## Sichtprüfung und Speicherung

Die Root-Bildberichte benennen nur die tatsächlich geöffneten Einzelbilder. Bs vollständige Film-/Bildsichtung und Cs unabhängiger Quell-/Medienreview bleiben eigene Belege. Eine Anforderungsliste mit 48 Bildpfaden ist nur die Vorbereitung der Sichtprüfung des neuen vollständigen CI-Artefakts; sie übernimmt keine alten Bildbefunde.

Die Speicherbereinigung ist eng dokumentiert: alte reproduzierbare Flutter-Testkernel wurden entfernt; ein älteres temporäres ZIP wurde nach vollständigem Hashvergleich in ein anderes lokales Dateisystem verlagert. Das ist keine Löschung von Produktquellen, Renderoriginalen oder Gitbelegen.

Der komplette frühere Upload mit 338 Zielpfaden ist als Gitblob-Sicherung nachgewiesen. Eine Referenzänderung des Evidencebranches erfolgt ausschließlich durch Root mit aktuellem erwarteten Parent und vollständigem Vergleich des alten und neuen Git-Trees.

## Abnahmegrenzen

Kein erfolgreicher Android-2020-Lauf, keine neue APK-Veröffentlichung und kein physischer Fold7-/60-FPS-Nachweis werden durch dieses Paket behauptet. Es zeigt die tatsächlich erreichten Zwischenschritte und ihre Grenzen. Nachfolgende CI-Abschlüsse und Hostfreigaben erhalten separate neue Belege.
