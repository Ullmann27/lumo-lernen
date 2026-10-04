# Lumo Android: frische Bildschirmabfragen und APK-Übergabe

Stand 4. Oktober 2026. Projekt `Ullmann27/lumo-lernen`, PR 156,
Zweig `codex/lumo-unified-android-2026-10-03`.

## APK und ausgelieferte Testdateien

Version 0.10.5 / Build 280, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`.
148.336.186 Bytes, SHA-256:
`3c01ba849139583be0b41ef2195e67f68373ebb18d720ce2d1ad1bd638523f48`.
APK-Quellcommit `2427eac913721f0d1144ec44a3fcf0acb9c72d76`.
Zertifikat SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.

Die unveränderten Bytes wurden mit dem lesenden Transferlauf 37180639671,
Commit `dd51208ea72247e5c3dfa95835da8bd5c88c1c72`, unabhängig heruntergeladen.
Dateigröße, Prüfsumme, APK-Struktur und `apksigner`-Prüfung bestanden.
Actions-Artefakt 11294449269 (`Lumo-Build-280-Bytecheck`) enthält die Bytes und
Herkunft, ausdrücklich keine bestandene Gesamtnutzungsprüfung.

Im Chat wurden `Lumo_Lernen_Testversion.apk` und `Lumo_Lernen_Testversion.zip`
bereitgestellt, ausdrücklich als Entwicklungsversion ohne fertige Freigabe.
Die ZIP enthält dieselbe APK und eine Einschränkungs-/Installationsinformation.
Dies ist keine Umbenennung eines fehlgeschlagenen Kandidaten zur fertigen App.
Bestehende Nutzerdaten sollen nicht vorsorglich durch Deinstallation gelöscht werden.
Kein Release wurde veröffentlicht, keine APK ersetzt oder neu signiert.

## Originalnachweise statt widersprüchlicher Protokollansichten

Originaldateien von Lauf 37174626790 belegen Kart, native Rückwege, eine
korrekt gelöste Rechenaufgabe samt Apfelhilfe und Memory. Abbruchstelle war
anschließend die Suche nach „Lumo Cards“, nicht eine falsche Rechenhilfe.
Aufgrund einer zuerst widersprüchlich angezeigten Logansicht wurde kein
App- oder Aufgabenquelltext geändert.

Fünf folgende XML-Dateien `flutter-098` bis `flutter-102` waren trotz
protokollierter Wischgesten bytegleich. Der alte Prüfer verwendete denselben
entfernten Dateipfad nach `uiautomator dump` immer wieder. Androids DumpCommand
kann nach ausbleibendem Idle ohne neue Datei zurückkehren. Ein Exitcode null
belegt daher keine neue Bildschirmaufnahme.

Die erste Reparatur verlangt einen UUID-Pfad je Abfrage, passende Fertigmeldung,
eine gültige Hierarchie und eine dokumentierte Prüfsumme. Fehler dürfen weder
alte XMLs lesen noch weitere Eingaben mit alten Koordinaten auslösen.

Der anschließende Originallauf 37179755477, QA-Commit
`41558da76170dd5fdb85005219b268d7779f2309`, führte alle 168 Helfertests ohne
Auslassungen erfolgreich aus. Die APK wurde installiert; Kart, Lernen und
Memory liefen durch. Der Gesamttest endete wieder beim Scrollen zu Cards:
Die letzten drei frischen Dump-Versuche bestätigten keine neue Datei.
Der Prüfer brach jetzt korrekt ab, statt alte Bildschirmdaten weiterzunutzen.
181 Abfrageversuche wurden protokolliert, darunter acht fehlgeschlagene.
Der Original-Screenshot zeigt eine laufende Spieleauswahl. Ein App-Absturz
ist aus diesem Abbruch nicht nachgewiesen. Cards-Abschluss, Größenwechsel und
Offline-Neustart sind in diesem Lauf nicht bestätigt.

## Zweite Reparatur: tatsächliche Hierarchie ohne globales Idle

`java/LumoUiSnapshot.java` benutzt ausschließlich die bereits vorhandene
Android-Accessibility-Brücke und den Android-Serializer. Es liest die aktive
Hierarchie ohne `waitForIdle`, benötigt aber einen tatsächlich gelieferten
Root und eine neu geschriebene, nichtleere Datei. Es löst keine Touch-Ereignisse
aus, verändert keine App-Einstellungen und schreibt nur in UUID-Prüfpfade.
Die Verbindung wird geschlossen; Fehler führen zu einem Fehler-Exitcode.

`prepare_ui_snapshot.py` kompiliert dieses getrennte Prüfmodul als DEX-Jar,
prüft Dateihashes und beschränkt die Installation ausdrücklich auf den
API-35-Emulator. Ein tatsächlicher Probeabruf muss vor dem Nutzungsablauf
bestehen. Die APK bleibt unverändert; keine Spielzeit und keine Animationen
werden für den Prüfer manipuliert. Die bisherigen sichtbaren Lern-, Spiel-,
Speicher- und Neustartnachweise bleiben erforderlich.

Lokal: Java-8-Zielcode kompiliert; ungültiger Aufruf korrekt abgelehnt.
176 Python-Helferregressionen insgesamt, davon 168 ausgeführt und bestanden,
acht lokale OCR-Bildtests bewusst übersprungen. Diese acht laufen im
GitHub-Runner mit vorhandener OCR-Abhängigkeit. Zusätzlich 22 lokale
Backendtests mit künstlichen Providerantworten bestanden auf Node 22.16.0;
das ist kein Nachweis aktuell verfügbarer externer KI-Quota.

## Aktueller Folgelauf und offene Grenze

Vollständiger Android-Folgelauf **37181279924**, QA-Commit
`b98fd4a4336b660b39006aa81a58d112c8ededf8`.
Der letzte gelesene Status war laufend; Endergebnis und Original-Proof sind
noch vor jeder endgültigen Erfolgsaussage zu prüfen.

Der Workflow exportiert nach erfolgreichem vollständigem Nutzungsnachweis
und erneutem Prüfsummenvergleich dieselbe Datei als `Lumo-Lernen-Neu.apk`.
Das Actions-Artefakt lautet `lumo-android-280-check-37181279924` und enthält
bei Fehlschlag ausschließlich die Originaldiagnose, keine finale APK.
Unveröffentlichter Entwurf bleibt `unified-build-280`, ID 402540673.

Physische Samsung-Geräte, ARM-FPS, endgültige Premium-Grafik, vollständiger
neuer 3D-Fuchs und aktivierte externe Online-KI sind weiterhin getrennte,
nicht durch diese Tests erledigte Punkte. Keine Behauptung, das gesamte
Wunschprojekt sei dadurch bereits vollständig fertig.

## Primärquelle zum Android-Verhalten

AOSP DumpCommand: https://android.googlesource.com/platform/frameworks/testing/+/refs/heads/main/uiautomator/cmds/uiautomator/src/com/android/commands/uiautomator/DumpCommand.java
Die eigene Live-Abfrage nutzt dieselbe Brücke und denselben Serializer,
ist aber eigener Prüfcode und kein Ersatz der Android-Systembibliothek.
