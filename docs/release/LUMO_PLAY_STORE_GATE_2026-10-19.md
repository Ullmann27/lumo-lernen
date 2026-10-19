# Lumo Lernen – Google-Play-Abnahme (19. Oktober 2026)

**Entscheidung: Die Android-Test-APK 1988 ist nachgewiesen; eine Play-Store-Veröffentlichung ist NICHT freigegeben.**

Dieses Dokument unterscheidet strikt den bereits gebauten **privaten Sideload-/Testkanal**
von einer noch **nicht signierten und nicht in Play geprüften AAB**.
Ein grüner APK-Emulatortest ist kein Google-Play-Abnahmebeleg.

## Reproduzierbar bestätigter Stand

- **Lumo 0.12.76+1988**, Quellstand `cb4ee545864caaa84f1ed5d465f0490a121038a3`,
  [GitHub-Release](https://github.com/Ullmann27/lumo-lernen/releases/tag/lumo-v0.12.76-1988-fair-cards).
- Signierte **Android-Test-APK** mit 316.123.454 Bytes und
  SHA-256 `3bb0e5a723e084effb5dd784b3cb323afd14badc434c6ec48eddbb29bd6b58c4`.
- **App-ID der Test-APK:** `dev.ullmann.lumo.lumo_lernen.coachpreview`.
  **Nicht** als registrierte Google-Play-Paket-ID behaupten.
- `APK-VERIFICATION.json` aus `lumo-1988-arm64-verified` meldet
  versionCode 1988, minSdk 24, targetSdk 36, ARM64 und 16-KB-ELF-Alignment
  **für diese APK**, nicht automatisch für ein künftiges AAB.
- [Integrationsbuild einschließlich voller Flutter-Regression und Emulator-Tour:
  erfolgreich](https://github.com/Ullmann27/lumo-lernen/actions/runs/39240144926).
  Die Android-Tour installierte und durchlief **die x86_64-Emulatorvariante**
  aus demselben Build. Sie hat die Prüfsumme
  `1942f7e7f1584b969212189cb5d9a4cd9e3a1fd86ed9bb00216723d7f95731a8`.
  Das separat veröffentlichte **ARM64-Artefakt** hat die oben genannte andere
  SHA-256-Prüfsumme und ist paketgeprüft, aber **noch nicht auf einem ARM64-Gerät
  live installiert und gespielt**. Beide Varianten haben denselben Flutter- und
  Godot-Quellstand; eine identische APK-Datei wird nicht behauptet.
- [Echter Spielewelt-Bildvergleich: erfolgreich](https://github.com/Ullmann27/lumo-lernen/actions/runs/39240145096),
  mit sichtbarem Hinweis `Bauwelt: In Entwicklung`. Cards, Kart und die
  Lerneinstiege dürfen dadurch auf 360×800 nicht aus dem sichtbaren Bereich rutschen.

**Grenzen dieser Nachweise:** Kein physischer Fold-Test, keine reproduzierbare
60-FPS-Messung, keine hörende Qualitätsabnahme der Stimme, keine Play-Console-Prüfung
und keine Store-Produktionsfreigabe.

## Produktgrenzen, die beim Play-Paket erhalten bleiben müssen

- **Lumo Lernen** (Mathematik, Deutsch, Englisch, Geschichten, Schreibtrainer,
  Lern- und Denkprofil) ist das Kernprodukt. Bestehende kindliche Lerndaten
  nicht versehentlich löschen oder ändern.
- Lumo Cards hat einen regelgebundenen Bot mit variabler Strategie und Tests.
  Vier Gewinnt und das Kartenmodul nicht ohne Fehlernachweis deaktivieren.
- **Bauwelt** bleibt sichtbar als `In Entwicklung`, aber nicht startbar;
  bestehende Bauwelt-Spielstände bleiben gespeichert.
- Lumo Kart bleibt als eingebettetes Godot-Spiel prüfpflichtig;
  Grafikqualität/60 FPS sind keine gemessenen Tatsachen.
- **Wichtig bei Wechsel der Paket-ID:** `.coachpreview` und eine andere
  Play-`applicationId` haben getrennte Android-App-Datensandboxes.
  Eine automatische Übernahme vorhandener Kinderprofile/Spielstände ist
  damit **nicht** belegt. Datenmigration gesondert planen und testen;
  keine irreführende Zusage im Store-Listing.

## Separater Play-Staging-Kanal (in PR #382; noch nicht auf main)

- `scripts/prepare_play_android.py` erzeugt eine eigene Android-Hostkonfiguration:
  API 36, kontrollierte Paket-ID und private Upload-Signatur.
  Der Sideload-APK-Kanal bleibt unverändert.
- `REQUEST_INSTALL_PACKAGES` und die native APK-Installationsmöglichkeit
  werden für den Play-Host deaktiviert.
- `scripts/build_play_aab.sh` baut ein Flutter-App-Bundle und prüft die
  Signatur mit `jarsigner -verify -strict` gegen den privaten Upload-Keystore.
  Kennwörter gelangen nicht als Klartext-Argumente in die Kommandozeile.
- `.github/workflows/lumo-play-aab-staging.yml` ist **manuell**, auf
  `main` und die geschützte GitHub-Umgebung `play-upload` begrenzt und
  veröffentlicht **nie** eigenmächtig im Play Store.
- `.github/workflows/lumo-play-security-tests.yml` testet für Änderungen
  ohne Store-Secrets die Host-Konfiguration, ein selbstsigniertes
  Testzertifikat und die Zurückweisung nachträglich unsignierter Archive.
  Das manuelle AAB-Staging wiederholt dieselben Regressionen zwingend.

**Keine echte AAB mit bestätigter finaler Paket-ID und echtem privaten
Play-Upload-Schlüssel liegt bislang als überprüftes Release-Artefakt vor.**
Grüne Offline-Regressionsprüfungen allein ändern das nicht.

## Noch offene Freigabegates

| Gate | Status | Erforderlicher Nachweis |
| --- | --- | --- |
| Finaler Paketname | BLOCKIERT | Exakter App-Eintrag in der Play Console bestätigt |
| Privater Upload-Key | BLOCKIERT | Play-Upload-Zertifikat, sichere GitHub-Secrets und geschützte Umgebung |
| Tatsächlich signierte AAB | BLOCKIERT | Manuelles Staging auf `main`; AAB, Prüfsumme, Zertifikatsfingerabdruck, Bundle-Inhalt |
| App-Bundle-Laufzeit | OFFEN | `bundletool`-Installationstest der abgeleiteten APKs auf API 36, 64-bit und 16-KB-Laufzeit |
| Geräte/Fold | OFFEN | Echtes Gerät, Hoch-/Querformat, Lebenszyklus, Sprachwiedergabe, Performance/Abstürze |
| Bundle-Größe | OFFEN | Tatsächliche Play-Auslieferungsgröße und mögliche Asset-Delivery-Beschränkungen messen |
| Paketwechsel/Daten | OFFEN | Sichere Migration aus der Test-App oder ausdrückliche, nutzerfreundliche Trennung |
| Kinder-/Datenschutz | BLOCKIERT | SDK-/Netzwerkprüfung, Elternzustimmung, Data Safety, Datenschutzerklärung, Lösch- und Speicherfristen |
| Store-Listing | BLOCKIERT | Verifizierte Bilder, Altersfreigabe, Familienrichtlinien und keine unfertigen Spiele als fertig darstellen |
| Kaufmodell | OFFEN | Tatsächlich konfigurierte Play-Abos und Preis; **9,99 €/Monat ist bislang nur ein geplantes Angebot** |
| Test-/Produktionsfreigabe | BLOCKIERT | Nachweise aus dem tatsächlichen Play-Console-Konto und erforderlichen Tests |

## Offizielle Referenzen (bei Freigabe erneut auf Aktualität prüfen)

- [Ziel-API-Anforderungen](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Android App Bundle](https://support.google.com/googleplay/android-developer/answer/9844279)
- [Families Policy](https://support.google.com/googleplay/android-developer/answer/9893335)
- [Data Safety](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Android 16-KB Page Size](https://developer.android.com/guide/practices/page-sizes)
- [Anforderungen an geschlossene Tests neuer persönlicher Entwicklerkonten](https://support.google.com/googleplay/android-developer/answer/14151465)

**Harte Freigaberegel:** Keine Zusammenführung auf `main` und keine
Play-Store-/Produktionsbehauptung allein aufgrund von Test-APK- oder
Offline-CI-Ergebnissen. Erst konkrete Paketidentität, Signierung, AAB-Gerätetest,
Datenschutz- und Play-Console-Abnahme nachweisen.
