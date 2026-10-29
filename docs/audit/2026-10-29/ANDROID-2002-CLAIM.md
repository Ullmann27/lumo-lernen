# Separater Android-Auslieferungszweig 2002

Branch: `feat/lumo-living-intelligence-2002-20261029`.
Basis: Tutor-Kern aus [Draft-PR #414](https://github.com/Ullmann27/lumo-lernen/pull/414).
Version: `0.12.90+2002`. Build 2001 bleibt auf seinem bisherigen Branch erhalten.

Geändert werden nur die neue Versionsfreigabe mit unverändertem geprüftem
Godot-Pin, die zugehörigen negativen Pin-Tests, ein eigener 2002-Update-Probe
und eigene 2002-Gates. Die bestehenden 2000/2001-Dateien werden nicht ersetzt.

Veröffentlichung erfordert am gleichen Commit:

1. Analyse, gesamte Flutter-Suite, fokussierte Szenen-/Profil-/Speichertests.
2. Signierte ARM64-Haupt-App und x86_64-Emulatorpaket aus identischem Quellstand,
   unverändertem Anwendungspaket und vertrauenswürdigem Signaturfingerprint.
3. Vollständige bisherige Android-/native Kart-Tour.
4. Auf der veröffentlichten 2000-App tatsächlich per UI erzeugter Lernstand,
   `adb install -r` des 2002-Pakets mit unveränderter Installationsidentität,
   Datenerhalt, Offline-Kart, Neustart und drei Fold-Geometrien.
5. Nur danach ein neues unveränderliches Release mit einzelner ARM64-APK,
   SHA-256 und Build-Provenienz; kein Überschreiben älterer Releases.

Die Pin-Tests bestehen lokal mit 37 Fällen. Android-Ergebnisse sind noch nicht
vorhanden und werden erst nach tatsächlicher GitHub-Ausführung eingetragen.
Der Tutor-Kern hat separat 1.952 lokale Flutter-Tests und 43 fokussierte Fälle
bestanden. Seine 13 Flutter-Bilder sind keine Android-Emulatoraufnahmen und
beweisen weder physische Fold7-Leistung noch lokale Spracheingabe.
