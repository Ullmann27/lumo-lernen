# Android-APK-Abschluss – 4. Oktober 2026

## Aktueller Stand

**Die vollständige Android-Nutzungsprüfung ist noch nicht als bestanden bestätigt. Eine finale APK wurde noch nicht übergeben.**

Projekt `Ullmann27/lumo-lernen`, PR #156, Zweig `codex/lumo-unified-android-2026-10-03`.

Aktueller Gesamtlauf: **37174626790**, QA-Commit `e332e24104345b1d851e2903939c3336ea5dc995`.
Der zugehörige Transfer wurde durch Commit `3dba7a43111ea73df1e3e7e0e25b777c0e1bd364` gestartet. Er wartet ausschließlich auf diesen konkreten Gesamtlauf und darf eine finale APK nur bei passenden Originalnachweisen übernehmen. Bei einem Fehlschlag wird ausschließlich die Diagnose übertragen.

Unveränderte APK: Version **0.10.5, Build 280**, Entwurf `unified-build-280`, SHA-256 `3c01ba849139583be0b41ef2195e67f68373ebb18d720ce2d1ad1bd638523f48`.

Die Änderungen dieser Fortsetzung betreffen die Android-Testwerkzeuge und die Dateiübertragung. App-Quellen, APK-Bytes und Signatur wurden nicht geändert. Kein Release wurde veröffentlicht; PR #156 wurde nicht zusammengeführt.

## Aus Originaldateien nachgewiesene Fortschritte

Der Emulator wird anhand seiner tatsächlichen ausführbaren Datei geprüft. `-no-window` verlangt ausdrücklich `qemu-system-x86_64-headless` aus dem verifizierten, gepinnten SDK. Falsche, fehlende und doppelte Prozesse bleiben Fehler. Die Originaldateien der Folgeläufe bestätigen diese Prüfung.

Lauf **37172929269** absolvierte ein vollständiges Kart-Rennen mit zwei Runden, vier korrekten Lernantworten, beobachteter Hilfestellung, Ergebnis, Neustart und Rückkehr in die Spieleauswahl. Danach wurde auch die Flutter-Rechenaufgabe mit lokaler Apfel-Erklärung gelöst und `Aufgabe 2 / 30` erreicht. Der Gesamtlauf scheiterte erst beim Prüfen der Rückkehr zur Akademie-Überschrift.

Der Originaltransfer dieses Laufs (`Lumo-Android-Prueflauf.zip`) hat SHA-256 `55e9a412e11c3e98c2c50941bd36b4796f4d90f2e6a421f3d652245dbd340a4`. Seine 149 Hilfstests hatten keine Fehler, aber acht mangels OCR-Installation übersprungene Bildtests. Das wird nicht als 149 vollständig ausgeführte erfolgreiche Tests ausgegeben.

Lauf **37173963537** führte nach Installation der OCR-Abhängigkeiten **alle 153 Hilfstests ohne Fehler und ohne Auslassung** aus. Sein tatsächlicher Spieltest endete an einer weiteren Prüferannahme: Eine korrekte Antwort war lesbar, eine falsche Antwort jedoch noch nicht. Dieser Lauf ist deshalb insgesamt nicht bestanden. Originaltransfer `Lumo-Android-Nutzungstest.zip`, SHA-256 `75bb1485c066f0d912e1b4f8c62bc057bf9aa7f766c832ec6bf8c3fb3ea4efec`.

## Gezielte Reparaturen der Testwerkzeuge

Die Kart-Fragenanalyse bevorzugt vollständige beobachtete Fragen mit `= ?` gegenüber schwächeren OCR-Lesarten ohne Gleichheitszeichen. Dadurch werden die aufgezeichneten Varianten `7-22?` und `3-35?` nicht gegen die eindeutig vollständig erkannten Fragen `7-2=?` und `3-3=?` ausgespielt. Widersprüche zwischen gleichwertigen vollständigen Lesarten bleiben Fehler. Ein Fragenwechsel wird unabhängig von lesbaren Antwortknöpfen erkannt; gleiche Fragen mit anderer Leerzeichen- oder Minusdarstellung zählen nicht als Wechsel.

Beim Zurückkehren aus dem Flutter-Lernmodul enthielt die erste echte Semantics-Aufnahme vorübergehend keine Beschriftungen und keinen Scrollbereich. Die folgende Aufnahme zeigte die korrekt zurückgekehrte Akademie mit beibehaltener Scrollposition. Die Prüfung wartet nun begrenzt auf tatsächlichen Inhalt, bevor sie höchstens vier echte Aufwärtsgesten innerhalb des beobachteten Scrollbereichs ausführt. Sie wiederholt weder Android Back noch erfindet sie Koordinaten. Der erforderliche Nachweis der Akademie-Überschrift und des gespeicherten Lernfortschritts bleibt bestehen. Quell-Blob `fd613afe0f7a1e00658066502c7402d2f01d5382`; vier neue Regressionen und Replay der Original-XMLs bestanden.

Fehlantwort und lokale Erklärung sind jetzt eine eigenständig erforderliche Interaktion innerhalb des Rennens. Sind bei einer Frage nur die richtige Antwort und ihr realer Knopf lesbar, wird keine falsche Antwort geraten. Der Fehlantwort-/Hilfenachweis darf an einer späteren eindeutig lesbaren Frage stattfinden, muss aber vor erfolgreichem Rennabschluss tatsächlich vorliegen. Ohne korrekte Lernantwort beziehungsweise ohne verlangten Hilfenachweis bleibt der vollständige Lauf ein Fehler. Quell-Blob `c4192dd84fac9c5111055d0894842c105499b5b8`; 51 Kart-Regressionen einschließlich sechs neuer Nachweisprüfungen bestanden lokal.

Diese Angaben sind Tests der Prüfer und beobachtete Teilabläufe, kein Ersatz für den noch laufenden vollständigen Android-Gesamttest.

## Quellenkorrektur und Grenzen

Eine frühere Protokollansicht zu Lauf 37171778921 hatte `Can't create ViewModelProvider for detached fragment` behauptet. Seine heruntergeladenen Originaldateien bestätigen diese Diagnose nicht; sie zeigen einen Abbruch beim Erkennen des Kart-Fragenwechsels. Deshalb wurde auf dieser Grundlage keine Godot-/Android-Activity verändert.

Ein früher lokaler Gesamtlauf der nur übertragenen Helferkopie hatte zwei Fehler wegen fehlender Flutter-App-Quelldateien. Diese lokalen Gesamttests wurden nicht als vollständig bestanden ausgegeben. Die vollständige Quelldateistruktur ist im Repository-Runner vorhanden. Frühere Flutter-, Backend- und Lerninhalts-Testzahlen wurden in dieser Fortsetzung nicht neu ausgeführt.

## Noch zu bestätigen

Endergebnis des oben genannten Gesamtlaufs aus seinem Original-Proof lesen: vollständige Lern-/Memory-/Kartenspiel-Abläufe, emulierte Fold-Größen, Offline-Neustart und gespeicherte Fortschritte. Nur bei erfolgreichem, passenden Lauf dieselbe erneut heruntergeladene und SHA-256-geprüfte Datei `Lumo-Lernen-Neu.apk` übergeben. Keine Umbenennung eines fehlgeschlagenen Kandidaten zur fertigen Version.

Physische Samsung-Geräte, endgültige Premium-Grafik, ein vollständig neuer 3D-Fuchs sowie sämtliche externen KI-Dienste sind dadurch nicht als getestet oder fertiggestellt nachgewiesen.
