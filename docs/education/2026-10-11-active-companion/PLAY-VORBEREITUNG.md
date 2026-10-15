# Technische Google-Play-Vorbereitung — noch keine Store-Freigabe

Stand 12.10.2026. Kandidat 1932 befindet sich noch in Prüfung. Keine Veröffentlichung und keine Zahlungen aktiviert.

## Nachweisbarer Bestand

- Testpaket `dev.ullmann.lumo.lumo_lernen.coachpreview`, minSdk 24 / targetSdk 36 in den bisherigen APK-Belegen; die neue APK wird separat vermessen.
- Testupdates erhalten die bestehende Zertifikats-Prüfsumme `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Diese Update-Identität darf in der Testreihe nicht gewechselt werden.
- Offline-Sprachcode: MIT (Supertone); Modell: BigScience Open RAIL-M. Lizenzdateien unter `assets/audio/voice/lumo_free/`, Modellzuordnung und Hashes in `config/lumo-offline-voice.json`. Kostenlose lokale Ausführung ist keine kommerzielle Lizenz-/Datenschutzabnahme.
- Cloud-Sprachausgabe und Mikrofon sind in `AppSettings` standardmäßig aus; Modellfreigabe ist ein getrenntes Feld. Vorlernen verwendet eigene Elternfreigabe und getrennten Entdeckungsfortschritt.
- Letzte installierte x86_64-Test-APK 1931: 305.467.200 Bytes; ARM64: 302.322.803 Bytes. Kein Nachweis einer bereits zulässigen Store-Liefergröße oder eines funktionierenden App-Bundles.

## Konkrete technische Vorbedingungen

| Bereich | Befund | Nächster erforderlicher Nachweis |
|---|---|---|
| Signierung | `scripts/prepare_android.py` signiert auch Release-Builds mit dem vorhandenen Debug-Testschlüssel | Eigenständige gesicherte Play-Upload-Signierung und bestehende Produktions-Paketidentität klären; Testupdates weiterhin unverändert signieren |
| Installation | Host fügt `REQUEST_INSTALL_PACKAGES` hinzu | Store-Variante ohne diese Test-Auslieferungsberechtigung vorbereiten und ihren echten Manifest-/Funktionsunterschied prüfen |
| Kamera/Mikrofon | Host deklariert `CAMERA` und `RECORD_AUDIO`; Nutzung darf nur nach bewusster Freigabe erfolgen | Gesamte tatsächliche Laufzeit-Freigabematrix einschließlich Widerruf und Elternbereich prüfen |
| Elternbereich | Lokale Erwachsenenbestätigung vorhanden | Geeignete abschließende Elternprüfung und Familien-Anforderungen anhand des tatsächlichen Elternflusses prüfen |
| Datensicherheit | Lernstände und Profile bestehen; Online-Komponenten sind optional | Datenflüsse, Empfänger, Aufbewahrung, Löschung, SDKs und reale Datenschutzerklärung inventarisieren; keine pauschale Behauptung „keine Datenübertragung“ |
| Sprache/Assets | Sprach-Lizenztexte erhalten; Original-Sulafat und Lumo unverändert | Quellen-/Rechteinventar aller Sprachaufnahmen, Figuren, Schriften, Bilder und Godot-Assets vollständig abzeichnen |
| Lieferformat/Größe | Bisher Test-APK mit großem lokalem Modell und Godot | Installierbares AAB, Geräte-/ABI-Aufteilung und gemessene Download-/Installationsgröße; gegebenenfalls zulässige modulare Auslieferung prüfen |
| Geräte | Android-16-x86_64-Belege vorhanden; keine physische ARM64-/Fold-Abnahme | Physische Geräte, Audio, Scharnier, Speicher, Ladezeit und Bedienbarkeit separat messen |

Dies ist ein konkreter technischer Befund anhand der vorhandenen Quellen, keine Rechtsberatung, Store-Compliance-Bestätigung oder Freigabe zur öffentlichen Veröffentlichung. Keine Änderung an Signatur, Berechtigungen oder gespeicherten Nutzerdaten vorgenommen.
