# Qualitätsnachweis des Kandidaten 2070

**Prüfstand dieser Fassung:** Der signierte Originalbau, die unten aufgeführten
Vertrags- und Paketprüfungen sowie die Sichtprüfung der fünf tatsächlichen
Godot-4.6.3-Aufnahmen sind abgeschlossen. Die anschließende Android-Prüfung im
Job **137748819779 läuft noch**. Ein bestandener vollständiger Android-Rundgang,
ein bestandener Android-Backup-Rückspieltest und ein funktionierender öffentlicher
Einzel-APK-Download sind für 2070 in dieser Fassung **noch nicht bestätigt**.

Dieser Nachweis betrifft ausschließlich den korrigierten Kandidaten 2070. Die
dokumentierte visuelle Sperre von 2069 bleibt in [QUALITY_2069.md](QUALITY_2069.md)
erhalten. Ein späterer erfolgreicher Prüfabschluss ist mit seinen tatsächlichen
Job- und Artefaktidentitäten zu ergänzen.

## 1. Eindeutige Originalidentität

| Merkmal | Verifizierter Wert |
| --- | --- |
| Version | `0.14.1+2070` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Flutter-Quelle / unverändertes Releaseziel | `11c0711f23f887796a7281ddfc6ee7a2aa56ac67` |
| Godot-Quelle | `90648b0639391c88d3c2da0e3f235d30f725256d` |
| Godot-Engine | `4.6.3-stable (official)` |
| Original-Buildrun | [45186225313](https://github.com/Ullmann27/lumo-lernen/actions/runs/45186225313) |
| ARM64-APK-Artefakt-ID | `14826480557` |
| Original-Metadaten-Artefakt-ID | `14826031651` |
| Dateiname | `Lumo-Lernen-Test-0.14.1-2070.apk` |
| ARM64-APK-Größe | `537159895` Bytes |
| ARM64-APK SHA-256 | `8dca425b869b91b18956ecd848ed993ffbd5e21d114fe489b83f78fea6aff6ff` |
| Öffentliches Testzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Eingebettete PCK-Größe | `279880864` Bytes |
| Eingebettete PCK SHA-256 | `9a91ed2b428e086fd0d2c813fc9f55aaac5e65aa75944736a94af55673416fd6` |
| Emulator-APK-ABI | `x86_64` |
| Emulator-APK-Größe | `540330804` Bytes |
| Emulator-APK SHA-256 | `244cfe843578f324833c8216cb8c2d37882d5a352bf18762a1b239b9507c5572` |
| Android SDK | `minSdk 24`, `targetSdk 36` |

`BUILD-PROVENANCE.json`, `APK-VERIFICATION.json` und
`SPLIT-APK-IDENTITY.json` stimmen für diesen Kandidaten überein. ARM64- und
x86_64-APK enthalten **dieselbe PCK** und tragen dasselbe Testzertifikat.
Die Quellprovenienz bestätigt den sauberen getrackten Flutter-Stand. Die
Paketprüfung bestätigt ausschließlich ARM64-Bibliotheken in der ausgelieferten
Handy-APK sowie die geprüfte ELF-/Ressourcenausrichtung.

## 2. Tatsächliche Build- und Regressionsergebnisse

Die folgenden Logs liegen im Originalarchiv `LUMO-WORLD-LOGIK-BELEGE.zip`,
überwiegend unter `build-proof/`. Sie gehören zum oben gebundenen Originalbau.

| Prüfung | Tatsächliches Ergebnis | Originalbeleg |
| --- | --- | --- |
| Signierter ARM64-/Emulator-Bau | Baujob erfolgreich; beide APK-Identitäten gebunden | `BUILD-PROVENANCE.json`, `APK-VERIFICATION.json`, `SPLIT-APK-IDENTITY.json` |
| Native/JVM-Vertragsrunde | **79 Tests bestanden** | `NATIVE-SPEECH-DIALOG-TESTS.txt` |
| Gezielte Flutter-Runde | **158 Tests bestanden** | `FLUTTER-LOGIC-WORLD-TESTS.txt` |
| World, Quellprojekt mit Godot 4.6.3 | **194 Prüfaussagen bestanden** | `GODOT-lumo_world_regression.txt` |
| World-HUD, Quellprojekt mit Godot 4.6.3 | **499 Prüfaussagen bestanden** | `GODOT-lumo_world_hud_regression.txt` |
| Original-Schatzsuche | **92 Prüfaussagen bestanden** | `GODOT-treasure_exploration_regression.txt` |
| Native Kartentische | **26 Prüfaussagen bestanden** | `GODOT-native_table_boot_regression.txt` |
| HostBridge | JNI-ACK, strikte Ablehnung ungültiger Eingaben, Reward-Deduplizierung, Rückkehr, Lebenszyklus und Neustart bestanden | `GODOT-host_bridge_regression.txt` |
| World gegen die tatsächlich aus der ARM64-APK entnommene PCK | **194 Prüfaussagen bestanden** | `WORLD-PCK-REGRESSION.txt` |
| World-HUD gegen dieselbe entnommene PCK | **499 Prüfaussagen bestanden** | `WORLD-PCK-HUD-REGRESSION.txt` |
| Kart-Asset- und Rennprüfung gegen die entnommene PCK | Geforderte Prüfungen und Bau-Gate bestanden; Prozessende-Meldungen unten dokumentiert | `KART-DRIVER-PCK-assets.txt`, `KART-DRIVER-PCK-race.txt` |
| Fünf echte World-Rendereraufnahmen | `PASS views=5 renderer=gl_compatibility` | `GODOT-WORLD-CAPTURE.txt`, `world-ui/world-capture.json` |

Die World-/HUD-Runden im Quellprojekt und im entnommenen Paket sind getrennte
Ausführungen derselben Prüfgruppen; ihre Zahlen werden nicht als unterschiedliche
Produkteigenschaften addiert. Die JVM-Verträge und Flutter-Widgettests ersetzen
keinen vollständigen Android-Rundgang.

**Verbleibende Logmeldung:** `KART-DRIVER-PCK-race.txt` meldet am Prozessende
`ObjectDB instances leaked at exit` und vier noch belegte Ressourcen. Die
geforderten Assertions und der Bau-Gate sind bestanden. Der vollständige
Originalbefund bleibt erhalten; für diesen Prozess wird keine fehlerfreie
Ressourcenfreigabe behauptet.

## 3. Sichtprüfung der fünf tatsächlichen 4.6.3-Aufnahmen

Die fünf Originalbilder wurden durch die koordinierende Prüfung und einen
unabhängigen World-Review visuell abgenommen. Die Capture-Metadaten binden sie
an Godot-Commit `90648b0639391c88d3c2da0e3f235d30f725256d`, die tatsächliche
Spiel-Folgekamera, den GL-Compatibility-Renderer und ein isoliertes synthetisches
Profil. Es handelt sich um gerenderte Spielansichten, nicht um Konzeptbilder.

| Originaldatei unter `build-proof/world-ui/` | Auflösung | Geprüfter Bereich |
| --- | --- | --- |
| `world-treasure_foundation.webp` | 1280 × 720 | Schatzinsel und gewöhnliche Spielsicht |
| `world-village_walking.webp` | 1280 × 720 | Gehen im Dorf und Aktionsoberfläche |
| `world-school_portrait.webp` | 720 × 1280 | Schule im Hochformat |
| `world-kart_driving.webp` | 1280 × 720 | Kartfahrt und freie Sicht vor der Kamera |
| `world-saved_village.webp` | 1280 × 720 | Tatsächlich geladenes vorhandenes Dorf aus dem isolierten Spielstand |

Die Korrekturen wurden an den gewöhnlichen Spielansichten überprüft. Die
vorherigen Mängel – vordergründig verdeckte Kamera, überstehende Aktionstexte und
unpassender Schulzugang – führten bei diesem Kandidaten zu keiner erneuten
visuellen Sperre. Die Bilder und die HUD-Regression belegen die geprüften
Ansichten; andere Orte, Gerätegrößen und ein längerer Spielverlauf sind dadurch
nicht vollständig abgenommen.

### Leistungsgrenze

Die Aufnahmeumgebung verwendet Software-Rendering. Die fünf dokumentierten
Medianzeiten liegen zwischen **469,065 und 1738,455 ms pro Frame**. Das ist auf
diesem Aufnahmerechner keine flüssige Wiedergabe. `world-capture.json` begrenzt
die Messwerte ausdrücklich auf diese Maschine. **Eine physische Android-Messung
oder stabile 60 FPS sind damit nicht nachgewiesen.**

## 4. Unabhängige Prüfung der erhaltenen Original-APK

Die vollständige ARM64-APK wurde zusätzlich über Transferlauf
[45191150151](https://github.com/Ullmann27/lumo-lernen/actions/runs/45191150151)
in neun einzeln geprüften Transportteilen empfangen und wieder bytegleich
zusammengesetzt. Das ist derselbe ursprüngliche Build; es wurde nichts neu gebaut
oder neu signiert.

`LOCAL-APK-BYTE-VERIFICATION.json` bestätigt Dateiname, **537159895 Bytes**,
den Original-APK-SHA und die Herkunft aus Run 45186225313. Der Transportmanifest-
SHA-256 lautet
`158cdd57a1127c6d18c5a1d7404587b840e30e125bc98a7acfdfc5ac9f6f4bfd`.

`LOCAL-APK-VERIFICATION.json` bestätigt unabhängig am empfangenen APK die
tatsächliche Signatur, Paket-/Versionsangaben, ARM64-ABI sowie Größe und SHA der
eingebetteten PCK. Hierfür wurde der vorhandene öffentliche Zertifikatsprüfer
direkt ausgeführt. Ein privater Signierschlüssel wurde weder benötigt noch
angefordert. Die ursprünglichen CI-Prüfbelege bleiben ergänzend maßgeblich.

Zusätzlich ist eine echte ZIP-Sicherung von **525445059 Bytes** vorhanden. Ihre
enthaltene APK besitzt unverändert den Original-SHA. Diese Sicherung erfüllt
allein noch nicht das Auslieferungsziel eines öffentlichen Direktlinks auf eine
einzelne `.apk`.

## 5. Android-Abschluss: aktueller offener Zustand

| Nachweis | Stand dieser Fassung |
| --- | --- |
| Zugehöriger Originalrun | `45186225313` |
| Laufender Android-Job | [137748819779](https://github.com/Ullmann27/lumo-lernen/actions/runs/45186225313/job/137748819779) |
| Abschließende Job-Conclusion | Noch nicht bestätigt; Prüfung läuft |
| Vollständiger `tour/tour-result.json`-Nachweis | Gesamt-PASS noch nicht bestätigt |
| Nativer Start einschließlich World | Abschließende Kombination aus `native-starts.json` und `NATIVE-GAME-STARTS.json` noch nicht bestätigt |
| `tour/local-backup/backup-result.json` | Vollständiger echter SAF-Export-/Rückspiel-PASS noch nicht bestätigt |
| Fertiges Android-Belegartefakt | Abschließende Artefakt-ID noch nicht bestätigt |

Für den Abschluss sind im selben Originalrun-Versuch der erfolgreiche Android-Job,
die tatsächliche Artefakt-ID und die vollständigen Originalberichte festzuhalten.
Tour und Backup müssen die x86_64-APK mit SHA
`244cfe843578f324833c8216cb8c2d37882d5a352bf18762a1b239b9507c5572` und die oben
identifizierte gemeinsame PCK betreffen. Alle geforderten Tour-/Backup-Schritte
und der native World-Start müssen bestanden sein. Ein früherer Build, ein
anderes Artefakt oder allein eine Statusüberschrift ersetzt diese Prüfung nicht.

## 6. Öffentliche Auslieferung: aktueller offener Zustand

**Eine veröffentlichte und anonym vollständig heruntergeladene Einzel-APK ist
noch nicht nachgewiesen.** Für den Veröffentlichungsjob von 2070 wird hier weder
Erfolg noch ein bereits aufgetretener HTTP-403-Fehler behauptet. Der tatsächliche
Ausgang des laufenden Originalablaufs ist abzuwarten und mit Job-ID zu belegen.

Der separat vorbereitete reguläre Ablauf ist in
[REVIEWED_PUBLISH_2070.md](REVIEWED_PUBLISH_2070.md) beschrieben. Sein Configauftrag
ist in diesem Vorbereitungsstand nicht angelegt. Er verlangt eine vom Nutzer
freigegebene Publisher-Identität, die exakten Originalartefakte und sämtliche
abgeschlossenen Android-Belege. Das ursprüngliche Releaseziel 11c0711f bleibt
verbindlich; vorhandene Releases werden nicht überschrieben.

Der öffentliche Abschluss ist erst bestätigt, wenn der tatsächlich erzeugte
Release und das konkrete APK-Asset existieren und der von GitHub gelieferte
Direkt-URL ohne Authentifizierung vollständig über HTTPS heruntergeladen wurde.
Dabei müssen erneut **537159895 Bytes** und SHA-256
`8dca425b869b91b18956ecd848ed993ffbd5e21d114fe489b83f78fea6aff6ff` übereinstimmen.
Release-ID, Asset-ID, tatsächlich erreichbarer URL und der Downloadprüfbericht
sind dann zu dieser Kandidatenidentität zu ergänzen. Bis dahin bleibt der
öffentliche Auslieferungsstatus offen.
