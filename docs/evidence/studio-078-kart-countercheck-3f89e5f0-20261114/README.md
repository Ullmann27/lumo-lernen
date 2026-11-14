# Abgeschlossener Kart-Gegencheck mit unveränderter APK

Der gezielte API35-Gegencheck **43587032836**, Versuch 1, Job
**132423646790**, ist am 14. November 2026 um **11:00:06 UTC** erfolgreich
abgeschlossen. Die getrennte QA-Quelle lautet
`3f89e5f045171424e9187ebdfb9ec1900ab16df3`.

Die bereits gebaute APK ist unverändert: Host
`078774ddaf64808addaa4c6406f6a3c85b1f239a`, Native
`785413d395292a243eaa0a0748671eb15d3f80ff`, APK-SHA256
`51af20ad5f0ac6a7196e1f703877805509b39a0ac27303619bc8adde5e0d00fe`,
PCK-SHA256
`aafe4afc0c5c38656b08b86ec382762d0af6b1ae7116b1187db4f2b04bb949a3`.
Der Originalbericht bindet Version 0.13.8+2020 und alle acht ursprünglichen
APK-Identitätsbedingungen. Der Binder bestätigt identische Quellen- und
Binärbindungen vor und nach der Tour; es wurde keine neue APK gebaut oder
veröffentlicht.

## Tatsächlicher Ablauf

Die Probe erkannte den regulären Hinweis zum Überspringen auf **zwei frischen
Screenshots**. Die tatsächlich gelesenen Kontrast-OCR-Zeilen lauten einmal
„Tippen zum Überspringen“ und einmal „Tippen zum Uberspringen“; beide erfüllen
den bestehenden normalisierten Exaktvergleich. Der tatsächliche Touch lag
bei **[1267,418]**. Der vollständige Skip-Nachweis benötigte **12,396425 s**
bei **32,851609 s** Rest der ursprünglichen 55-Sekunden-Frist.

Danach bestanden die ursprünglichen Prüfungen: gespeicherter Countdown 0,
Rennzeit mindestens 1 Sekunde, sichtbarer Renn-HUD und drei Gasimpulse. Die
abschließende Fahrprüfung weist für dieselbe Runde einen gespeicherten
Distanzgewinn von 107,19 und Rennzeitgewinn von 5,02 aus. Die ersten beiden
Zwischenbeobachtungen sind damit nicht als eigener Fahr- oder Latenzbeweis
umgedeutet. Die Pause hält den beobachteten Rundenzustand stabil. Rückkehr zu
Flutter, Benutzbarkeit der Lernansicht, das beobachtete Profil und zwei bereits
vorhandene Lernschlüssel nach Rückkehr und Neustart bestehen ebenfalls.

Der Tour-Schrittbericht enthält **21/21 erfolgreiche Schritte**: 18 bestehende
harte Prüfungen und drei Displayprüfungen. Getrennt davon liefen im selben
CI-Job **23 Kart-Probenverträge** in 1,084 s und **24 Binderverträge** in 0,275 s
erfolgreich, jeweils ohne Skip. Diese Zahlen werden nicht zu einer gemeinsamen
Android-Prüfzahl addiert.

## Originale und Grenzen

`original-job.log` ist der einmal abgerufene vollständige Original-Joblog:
**1.481.906 Bytes**, SHA256
`c03dfaad9502a29a92274904b20d5b5c9933137124dea8908f86486198242a32`.
Die finalen Run-, Job- und Artefaktantworten sind unverändert gespeichert.
Die beiden Dateien `*-from-original-job.json` sind ausdrücklich aus den
tatsächlichen JSON-Ausgaben des Logs extrahierte Berichte mit Logzeilenbindung;
sie werden nicht als separat heruntergeladene ZIP-Mitglieder ausgegeben.

Das tatsächliche Artefakt **14110986739** hat laut Originalmetadaten
**71.743.019 Bytes** und SHA256
`568844700a939578ca358ddc1ecd40c499d0ab673a4c16088849827e62470b4d`.
Root übernimmt den einmaligen Archivdownload, CRC-Abgleich und die Bildsichtung
in einem getrennten Nachweis. Dieser Reviewer hat weder eine zweite APK/ZIP
geladen noch Originalbilder als selbst angesehen ausgegeben. Die 1.658
libunwind-Diagnosezeilen bleiben im vollständigen Log erhalten.

Der ursprüngliche Unified-Lauf **43580229005** bleibt **FAIL**. Auch der
Haupt-Studio-Lauf **43580228966** wird durch diesen Gegencheck nicht ersetzt.
Der Binder markiert den neuen Lauf ausdrücklich als diagnostisch und
`original_failure_replaced=false`. Der Nachweis betrifft den regulären
Skip-Bedienweg auf dieser unveränderten API35-Emulator-APK; er ist kein
API37-PASS, kein physischer Fold7-Test und kein Geräte-FPS- oder Latenzbeleg.
Er rekonstruiert keine damals ungemessene Physik-/Frame-Zeitreihe rückwirkend.
