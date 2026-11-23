# Visuelle Sperre des Kandidaten 2069

Stand: 23. November 2026. **Dieser Kandidat ist nicht zur Auslieferung freigegeben.**
Der Quellstand wurde gebaut und funktional geprüft. Die anschließende Sichtprüfung
der tatsächlichen Spielbilder hat Fehler gefunden. Der laufende Android- und
Veröffentlichungsablauf wurde deshalb vor der Veröffentlichung abgebrochen.

## Eindeutige Identität

| Merkmal | Wert |
| --- | --- |
| Version | 0.14.0+2069 |
| Flutter-Quelle | `91a121f4302a4840ede44ece8a0494477d81c579` |
| Godot-Quelle | `9decd8eb59b03f31cdc7b2a33b0703a1e0d9b8c2` |
| Buildlauf | [45176827649, Versuch 2](https://github.com/Ullmann27/lumo-lernen/actions/runs/45176827649) |
| Erfolgreicher Buildjob | `137702207095` |
| ARM64-APK | `Lumo-Lernen-Test-0.14.0-2069.apk` |
| Bytes | 537148799 |
| APK-SHA-256 | `ac289d918c5f72bfd82165753962471554478233a4a6869d23b2e80112ea066b` |
| Testzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Enthaltenes Godot-PCK SHA-256 | `12c30dca523877d6d89339c74e13e785c217cc5c48583d26b49485e733a75cab` |
| Verifizierte Metadaten-ZIP SHA-256 | `21076e08820c3d082c22c8ccb546e1c81eba1ea354a6ecdc9e6dc4a2b3cc2999` |

Die Metadaten-ZIP wurde vollständig heruntergeladen und ihr Digest unabhängig
bestätigt. Der Abruf des großen APK-Artefakts über den Connector brach am
Zeitlimit ab; deshalb wird kein unabhängiger lokaler APK-Downloadnachweis für
diesen Kandidaten behauptet. Die APK-Identität oben stammt aus dem erfolgreichen
Build und seinen Paketprüfungen. ARM64- und Emulator-APK enthalten dasselbe PCK.

## Tatsächliche Prüfergebnisse

| Prüfung | Ergebnis |
| --- | --- |
| Native JVM-Verträge | 79 bestanden |
| Gezielte Flutter-Runde | 158 bestanden |
| World mit Godot 4.6.3 | 169 Prüfaussagen bestanden |
| Original-Schatzsuche | 92 Prüfaussagen bestanden |
| Native Kartentische | 26 Prüfaussagen bestanden |
| HostBridge | Bestanden |
| World gegen das tatsächlich aus der ARM64-APK entnommene PCK | 169 Prüfaussagen bestanden |
| Fünf tatsächliche Rendereraufnahmen | Erzeugt, keine Shader-/Scriptfehler im Capture-Log |
| Visuelle Abnahme | **Nicht bestanden** |
| Android-Rundgang | **Abgebrochen**, kein Gesamt-PASS |
| Veröffentlichung | Abgebrochen; der vorgesehene Release-Tag war bei der Nachprüfung nicht vorhanden |

Der erste Versuch desselben Runs scheiterte an HTTP 429 beim Abruf der
fest gepinnten JSON-Testbibliothek. Die unveränderte Wiederholung bestand diese
Tests. Dieser externe Fehler wird nicht als Produktfehler oder als bestandene
Prüfung umgedeutet.

## Sichtbare Mängel

- In `world-kart_driving.webp` füllt nahes Blattwerk fast die gesamte Spielsicht.
  Kart, Fahrer und Straße sind nicht hinreichend erkennbar.
- In `world-saved_village.webp` verdeckt ein Baum den Avatar und Teile des
  Dorfportals.
- Die Aktionsschaltfläche mit dem Text „Ansprechen“ überschreitet den rechten
  Bildrand in Quer- und Hochformat. Die bisherige Rechteckprüfung hatte die
  spätere textabhängige Mindestgröße nicht erfasst.
- Der Ankunftsweg zur Schule zeigt an dieser Stelle eine Fundamentwand statt
  eines klar erkennbaren Zugangs.
- Das große Schild der Schatzinsel greift in die zentrale Sicht auf die Figur.

Eine Korrektur muss die gewöhnliche Spielkamera und die tatsächliche Oberfläche
betreffen. Die vorhandenen Aufnahmeorte werden für den Vergleich beibehalten.

## Leistungsgrenze der Aufnahmen

Die fünf Bilder entstanden mit Godot 4.6.3, GL Compatibility und Mesa llvmpipe
auf zwei CPU-Threads. Die gemessenen Medianzeiten liegen zwischen 342,603 und
1358,493 ms pro Frame. Das ist in dieser Umgebung keine flüssige Wiedergabe.
Diese Software-Renderwerte sind keine Messung auf einem physischen Android-Gerät
und begründen insbesondere keine 60-FPS-Aussage.

## Auslieferungssperre und Fortsetzung

Commit `f3b315bfabea1b41b30923e891fb7e0b406e52d3` trägt den ausdrücklich geprüften
Marker `[world-visual-hold]`. Der neue Lauf derselben bestehenden
Concurrency-Gruppe hat den Vorgänger tatsächlich abgebrochen; der Hold-Lauf
`45182351403` stoppt absichtlich vor dem Checkout. Es wurde kein Main-Branch
zusammengeführt und kein älteres Release ersetzt.

Der nächste korrigierte Kandidat erhält Version 2070, einen neuen exakten
Godot-Pin und erneut alle Prüfungen. Die Pipeline stellt seine tatsächlichen
World-Aufnahmen bereits vor dem APK-Bau als eigenes Artefakt bereit, damit die
Sichtprüfung früher erfolgen kann. Ein späterer bestandener Kandidat ersetzt
nicht diesen dokumentierten Befund.
