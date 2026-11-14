# Historisches 1999-Gate: echte CI-Bestätigung der getrennten Reparatur

Der Lauf **43472126071**, Job **132046436344** (`update-and-tour`), hat am tatsächlichen Reparaturcommit **a5e03117158c157ba3154083db25947724e67727** erfolgreich abgeschlossen. Dieser Commit liegt getrennt im Draft-PR **469**, Branch `chatgpt/lumo-historical-1999-verifier-20261113`. Die eingefrorenen Studio-Quellen e3d161cb / 76980 werden durch diesen Nachweis weder verändert noch freigegeben.

Das neue originale Beweisartefakt **14062645376** wurde vollständig heruntergeladen: **94.355.474 Bytes**, SHA-256 **`c9962d0e927a7f4e15130a84683f295fdb7b24b54a7e0f47439796ad6cb9438e`**. Größe und Hash stimmen mit GitHub überein. Alle **303** ZIP-Einträge bestanden die CRC-Prüfung; es gibt keine doppelten oder unsicheren Pfade. Der vollständige Originaljobtext umfasst **308.579 Bytes / 3.273 Zeilen**, SHA-256 **`75cedcd485325f571467af44385372d09a6419e48d8e4a65b5f34d38c44dc4ee`**. Zwanzig kompakte Originaldateien wurden unverändert nach `raw/` übernommen.

## Tatsächlich verifizierte alte APKs

| APK | Version | Bytes | SHA-256 |
|---|---|---:|---|
| ARM64-Kandidat | 0.12.87+1999 | 317.113.542 | `6d821c210afa4a26b905325551fb527ac3559eac877dc5ec322993d9350334e2` |
| x86_64-Kandidat | 0.12.87+1999 | 320.266.867 | `b187c3e1d32ff5e1aa1a00be41d302eb3ae599b4df7bde3c651f7727e24095ed` |
| x86_64-Baseline | 0.12.85+1997 | 320.285.647 | `41f93d34869d46f8b0c3ac64ca9898e82d220300e64e34691ed477211ebfbea6` |

Die zwei aktuellen Verifier-JSONs aus diesem Lauf bestätigen für beide 1999-APKs das feste Familienzertifikat `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Der Baseline-Signaturaufruf bestätigt dasselbe Zertifikat. Das gemeinsame historische PCK enthält den Pin `4d0fd40fdf188be6ca86057596c7b51f41701fa3`, ist 54.744.008 Bytes groß und hat SHA-256 `0203d602a776156fcc02a100621e01b6aba3c8a9499a1c447fd439516cab317a`.

Ausgeführt wurde der aktuelle, hier zusätzlich am exakten a5e-Commit gelesene Verifier mit unverändertem festen Signatur-, Paket-, ABI-, Bibliotheks-, Voice-, Ressourcen-, PCK- und Release-Manifestschutz. Nur die vier Erwartungsdateien stammen aus dem vollständigen historischen Commit `c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf`. Beide echten APK-Berichte enthalten identische `expectationsSource`-Hashes. Alle vier Hashes wurden nochmals mit den entsprechenden lokalen Gitobjektbytes verglichen und stimmen überein. Es wird kein historischer Prüfer ausgeführt; ein abweichender Versionsoverride wäre im aktuellen Pfad unzulässig.

Der CI-Log dokumentiert den Download der alten Kandidaten-/Baseline-Artefakte samt passenden originalen Archivdigests. Dieser Reviewer hat deren APKs nicht nochmals heruntergeladen oder lokal verifiziert; lokal wurde ausschließlich das neue Beweisarchiv geprüft. Das ist eine Auswertung tatsächlich durchgeführter CI-Prüfungen, keine erneute Geräteprüfung.

## Updatepfad und klar begrenzte Reichweite

Das originale `update-result.json` meldet **PASS** für **1997 → install -r → 1999 → Offline-Kart → Neustart/Formatwechsel** auf dem konfigurierten API-35-x86_64-Emulator. Beide Installationsprotokolle enthalten `Success`; die gesicherten UID-Dateien sind bytegleich. Der geprüfte Kernlernweg hat eine richtige Antwort, sechs Sterne und 37 XP erzeugt; diese Werte, das Profil und die sechs verglichenen Lernschlüssel bleiben nach Update, Kart-Rückkehr, Neustart und den drei Formatwechseln erhalten. Die native Fahrt zeichnet echte Touchs und einen Distanzzuwachs auf; der Bericht nennt null fatale Abstürze.

Die frischen vorgelagerten CI-Vertragsprüfungen bestanden mit **35**, **15**, **13** und **15** Tests, jeweils ohne gemeldete Fehler oder übersprungene Fälle. Die Rohlogs zeigen trotzdem Diagnosen: vier ungeschlossene APK-Dateireader-Warnungen in den Vertragsfixtures, Vulkan-/ADB-Startmeldungen, Emulator-Abschlusswarnungen und Action-/Node-Abkündigungen.

Die historische Baseline-Lerntour enthält außerdem ausdrücklich **zwei fehlgeschlagene optionale Einstiege (Deutsch und Englisch)** und `dedicated_math_task=false`. Ihr erfolgreicher Mathe-Kernpfad ist daher keine umfassende Abnahme sämtlicher Lernbereiche. Diese Einträge werden unverändert erhalten und im Review ausdrücklich begrenzt. Die **69** enthaltenen PNGs wurden in dieser Prüfung gehasht, jedoch **nicht visuell geöffnet oder neu freigegeben**.

Dieser Nachweis betrifft ausschließlich die historische Reparatur und ersetzt weder den Studio-2019-Updatebeleg noch Android 17, einen physischen Fold7-, 60-FPS-, Wärme-, Audio- oder vollständigen Zwei-Runden-Belohnungstest. Er erzeugt keine finale Releasefreigabe.

`review.json` enthält alle Quellenbindungen und die kompakte Einordnung. Die Originalmetadaten, der vollständige Jobtext, aktuelle Quellkopien, unveränderte ausgewählte Beweisdateien und sämtliche ZIP-Mitgliedshashes liegen daneben. `SHA256SUMS` bindet die gespeicherten Dateien.
