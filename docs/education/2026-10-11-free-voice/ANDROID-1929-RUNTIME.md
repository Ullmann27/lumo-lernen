# Android 1929: tatsächlicher Bau und gezielte Laufzeitreparatur

Die APK aus [Build 38132054824](https://github.com/Ullmann27/lumo-lernen/actions/runs/38132054824) ist gebaut, aber der anschließende Android-Lauf wurde nicht bestanden. Sie ist keine vollständig freigegebene Testversion und keine produktionsbereite App. APK-Quelle ist `e4756bbcb6890d5054b5eb14ac4ef3ecd2cafa94`; große Kart-Erweiterungen und weitere Stimmexperimente bleiben zurückgestellt.

## Tatsächlich gesichert

- **ARM64:** `Lumo-Lernen-Neu.apk`, 302.252.651 Bytes, SHA-256 `4618a6b78b83f8ad621302bb660b65f56026d6d962d459c73d1f5a86a64d1426`. Die zusätzliche lokale strenge Paketprüfung stimmt bytegleich mit der CI-Prüfung überein.
- **Identität:** `0.12.22+1929`, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, separate Variante „Lumo Lernen Neu“. Nicht die normale Lumo-App und kein Produktionsschlüssel. Testzertifikat `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- **Laufzeit-Teilnachweis:** Das echte Android-16-x86_64-Update von 1928 auf 1929 lief mit `adb install -r`, ohne Deinstallation. UID `10216` und Erstinstallationszeit `2026-10-11 10:44:49` blieben gleich. Das fiktive Profil wurde vor dem Fehler erfolgreich nach dem Update geprüft. Dies ist keine vollständige Lernstandmigration und kein physischer ARM64-Test.
- **Konkreter Fehler:** `No observed parent navigation control`. Die erste gespeicherte UI-Hierarchie zeigt die tatsächlich gestartete Lumo-Startseite mit `Profil\nProfil`. Es gibt dort keinen direkten Eltern-Button. Die alte Probe drückte blind Android-Zurück und landete danach im Pixel Launcher. Eine vorab bestätigte Sprachwiedergabe gab es nicht.

## Eng begrenzte Reparatur

Der Probeweg benutzt die bestehenden sichtbaren App-Schaltflächen: „Profil“, „Profil bearbeiten“, „Elternbereich“. Ein mehrzeiliger Buttontext wird anhand seiner aktuellen Accessibility-Hierarchie erkannt. Fremde Apps, deaktivierte Buttons und nur ähnlich benannte Texte sind keine erlaubten Ziele. Ein Eltern-Button allein gilt nicht als Nachweis der geöffneten Elternseite. Kein Sicherheitssystem wird umgangen; keine App-Daten werden gelöscht oder Fortschritte injiziert.

Sieben neue Unit-Prüfungen des echten Probehelfers ergeben vor der Korrektur fünf Fehler; nach der Korrektur bestehen alle sieben. Mock-Hierarchien dieser Unit-Tests sind ausdrücklich keine Android-Laufzeitnachweise. Die vollständigen damaligen 62 Python-Prüfungen, Python-Kompilierung, YAML-Verifikation und Diff-Prüfung bestehen ebenfalls. Das neue Android-Ergebnis ist davon getrennt zu dokumentieren.

Der eigene Workflow `.github/workflows/lumo-1929-runtime-repair.yml` lädt exakt das bereits gebaute x86_64-Artefakt `11699692796` und die verifizierte 1928-Basis `11686249017`. Er verlangt den erfolgreichen ursprünglichen Buildjob, unveränderte App-Eingaben und exakte APK-Hashes. Kein neuer APK-Bau, keine wiederholte Flutter-Gesamtsuite, keine Veröffentlichung und keine Sprach-API-Kosten.

## Zweiter tatsächlicher Fehler und Portrait-OCR

[Nachprüfung 38134085531](https://github.com/Ullmann27/lumo-lernen/actions/runs/38134085531), QA-Commit `822fd3d22d63afd1aac2f7a3025405054d43a430`, scheitert weiter am Eltern-Einstieg. Sie erreicht diesmal tatsächlich den Profilbildschirm. Android exportiert dessen „Profil bearbeiten“-Schaltfläche jedoch nur innerhalb der größeren Profilkarte: zusammengeführter Text `Level 1 … Profil\nbearbeiten …`, Kartenbounds `[0,831][1080,1678]`. Es gibt keinen eigenständigen Accessibility-Knoten dieses Buttons. Die unretuschierte Laufzeitaufnahme zeigt den Button; der Fehler ist keine bestätigte App-Absturzursache.

Die eng begrenzte Ergänzung erkennt diese tatsächliche benachbarte Wortfolge und benutzt die vorhandene vollständige Screenshot-OCR. Der Buttontext muss in zwei aktuellen Bildern mit stabilen Bounds innerhalb der aktuell beobachteten Profilkarte erscheinen. Erst dann erfolgt ein echter Fingerdruck auf die beobachtete Schrift. Weder Kartenmittelpunkt noch Zielkoordinaten werden geraten. Die bestehenden Godot-Landscape-Guards bleiben unverändert; dieser Flutter-Einstieg funktioniert im Portraitformat. Nach dem Druck bleibt die tatsächlich sichtbare Elternüberschrift zwingend.

Die neue Regression mit dem tatsächlichen zusammengeführten Text schlägt vor dieser Ergänzung fehl. Danach bestehen 12 lokale gezielte Unit-Prüfungen einschließlich zwei aktueller Zielbeobachtungen, Ablehnung fremder/verborgener Texte und Ablehnung von Bounds außerhalb der Profilkarte. Diese Mock-Gerätetests sind kein Android-PASS. Die gespeicherte originale Screenshot-OCR erkennt „bearbeiten“ tatsächlich bei `[707,1191,909,1219]`; das ist ein Befund des fehlgeschlagenen Laufs und keine vorgegebene Koordinate im Probe-Code.

Zusätzlich prüft der unveränderten APK dienende Lauf jetzt „Stopp“: genau ein echter lokaler Playerstart, keine fingierte natürliche Abschlussmeldung und kein späterer Wiederstart. Lokale Synthese, Pause/Fortsetzen und vollständig beendete Aufnahme bleiben eigene zwingende Prüfschritte.

## Noch nicht freigegeben

Die zweite Nachprüfung [38135028290](https://github.com/Ullmann27/lumo-lernen/actions/runs/38135028290) belegt inzwischen den erfolgreichen echten Portrait-Einstieg: zwei aktuelle Original-PNGs, jeweils beobachtete Schriftbounds `[708,1127,909,1155]`, echter Fingerdruck `[808,1141]` und danach die tatsächliche Elternüberschrift. Der gesamte Lauf scheitert jedoch anschließend an `No enabled live Flutter control: App und lokale Stimme prüfen`. Die 24 gespeicherten Suchhierarchien zeigen Update-, Profil-, Bonus- und Lernabschnitte, aber noch keinen Sprachabschnitt. Der Button existiert im tatsächlichen Quellcode; die zwölf Vorwärtsgesten des bisherigen allgemeinen Lesers reichen auf diesem langen Bildschirm nicht bis dorthin.

Die nächste QA-Ergänzung erhält die bestehenden zwölf Versuche als Standard aller anderen Aufrufe. Nur die initiale Sprachdiagnosesuche erhält ausdrücklich maximal 48 Gesten pro Richtung und beginnt vorwärts; Budgets über 64 und unbekannte Richtungen sind unzulässig. Sichtbare, aktivierte Live-Knoten und deren tatsächliche Bounds bleiben zwingend. Zusätzlich wird der erfolgreiche Portrait-Elterneinstieg als eigenes Android-Bild festgehalten; die folgenden Sprachkontrollen verwenden die vorhandene Großansicht 1200 × 896. Vier lokale Regressionen sichern tiefer liegende tatsächliche Controls, unveränderte alte Begrenzung und Budget-/Richtungsablehnung. Die neue positive/Parameterprüfung war vor der Ergänzung rot; nachher müssen alle vier bestehen.

Die tatsächliche lokale Synthese und Player-Abschlüsse, Pause/Fortsetzen/Stopp, Neustart, Kart-Einstieg/Rückkehr und Fold-Zielviewport müssen in diesem Lauf bestanden werden. Der Emulator ist akustisch stumm; menschliche Hörabnahme, emotionaler Eindruck, physisches Samsung/ARM64, echte Scharnierereignisse und ein vollständiges Rennen bleiben davon getrennt offen. Der Lern-App-Fertigstellungsauftrag bleibt der nächste Produktmeilenstein.
