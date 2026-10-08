# Aktueller integrierter Lumo-Kandidat 1904 · 8. Oktober 2026

Zuerst [die aktuelle 1904-Übergabe](docs/handoffs/LUMO_INTEGRATED_RUNTIME_1904_2026-10-08.md)
lesen. Aktive Integrations-PRs sind App216 und Godot29. Maßgeblich sind der
jeweilige frische Branch-HEAD, `config/godot-source.json` und die tatsächlichen
APK-/PCK-Bytes. Version der Quelle: `0.12.1+1904`.

APK1903 aus App3e1d0eb3/Godot18238d48 wurde in Actions37817947080 wirklich
gebaut und unabhängig byteweise geprüft. Bauen/Puzzle/Rhythmus/Schatzsuche35
bestanden; beide vollständigen Kartläufe bleiben FAIL. Der kleinste Folgefix
repariert echte Touch-Weitergabe von Pause-/Ergebnisbuttons; identischer
BASE-Test strikt RED, Kandidat 35 Checks/sechs Drags/14 echte PNGs GREEN.
Eine getrennte QA-Reparatur prüft den bekannten Emulator vor Fullrace-Reads
und überbrückt ausschließlich den belegten initialen Offlinefehler begrenzt.
288 lokale QA-Guards/0 SKIP sind unabhängig bestätigt.

Die neue exakte APK1904 und ihre Android-Renn-/ACK-/Belohnungsprüfung müssen
im aktuellen Lauf erst gebaut und bestätigt werden. Native Software-GL-Bilder
sind keine APK-/Zielgeräte-/60-FPS-Nachweise. **VISUAL_GAP / NOT FINISHED**.
Keine Änderungen an Main oder Releases. Folgende 1903-/1900-Übergaben sind
historischer Kontext und ersetzen keine aktuelle Provenienzprüfung.

## Integrierter Kandidat 1903 · historische Übergabe

Lies zuerst [die1903-Übergabe](docs/handoffs/LUMO_INTEGRATED_RUNTIME_1903_2026-10-08.md).
Aktiv sind App-Integrationsbranch/PR216 und Godot-Integrationsbranch/PR29;
QA217/218 ist übernommen. Godotpin18238d48, Version0.12.1+1903.
Der erste 1903-Bau auf App76daa1fb ist am ungültigen NDK-Archiv gescheitert;
keine 1903-APK ist daraus entstanden. Dieser Folgecommit ergänzt eine frühe
Prüfung des exakten NDK und korrigiert die anhand echter Androidbilder belegte
Scrollprüfung innerhalb des Pausemodals. Die alten Fehler bleiben erhalten.
Build-/Android-Erfolg muss aus dem aktuellen CI-Lauf und dem tatsächlichen APK
belegt werden. Status beim Commit: VISUAL_GAP / NOT FINISHED.1902 wurde real
gebaut, hatte aber vier Android-Fails; bestätigter Pausefehler jetzt korrigiert.

Die folgende Übergabe dokumentiert den **historischen Stand vor Integration**.
Ihre alten Pins, offenen Merge-Schritte und1900-Abnahme ersetzen keine aktuelle
HEAD-/Claim-/Provenienzprüfung. Die vollständige ursprüngliche Übergabe bleibt
als Kontext erhalten.

## Direkte Übergabe an Claude Opus 5.5 · 8. Oktober 2026

Lies zuerst [die vollständige aktuelle Übergabe](docs/HANDOFF_CODEX_TO_OPUS_2026-10-08.md).
Sie enthält Änderungen an App, Lumo, Karts, Steuerung, Kamera und allen zwölf
Rennwelten, echte Prüfbelege, laufende Builds und konkrete nächste Arbeitsschritte.

## Aktuelle Koordination

- App: Referenz-/Kamerastand PR 214 auf `codex/lumo-reference-app-2026-10-08`
  und zusätzliche Runtimearbeit PR 215 auf `codex/lumo-runtime-apk-2026-10-08`.
- Godot: Referenz-/Kamerastand PR 27 auf `codex/lumo-reference-design-2026-10-08`
  und zusätzliche Speicher-/Kontaktarbeit PR 28 auf `codex/lumo-race-continuity-2026-10-08`.
- Die Paare sind noch nicht vollständig integriert. Frische Heads, Claims und
  deren Übergaben lesen. Meine letzte Kamerakorrektur in `30dc99b` / App `84ce0e3`
  mit der zusätzlichen Runtimearbeit verbinden; keinen fremden Pin überschreiben.
- APK `0.12.0+1900` hat alle sieben Jobs in Actions 37784807913 bestanden.
  Sie enthält die letzte Kamerakorrektur noch nicht. Neue 1901-Kandidaten sind
  separat zu prüfen; ein späterer kombinierter Build sollte mindestens 1902 sein.
- Referenzgleiche Produktionsmodelle, Tonabnahme, physisches Fold und belastbare
  60 FPS bleiben offen. Echte Screenshots und Clips statt Konzeptbilder als
  Runtime-Beleg liefern. Rennen enthalten keine Lernfragen/Antwort-Turbos.

Der vollständige Produktauftrag `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` liegt in der
Lern-App; seine historischen Basis-SHAs nicht als heutige Heads übernehmen.
Die [alte Startanweisung](docs/OPUS_NEXT_ARCHIV_2026-10-07.md) bleibt als Archiv.
Diese Übergabe startet keine weitere KI-Sitzung automatisch.
