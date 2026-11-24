# LUMO 2016 – Integrations- und APK-Kandidat

**Quelle:** Flutter 2718f405e69c193d0121c6f6447fe53769d7c803, basierend auf erfolgreich gebauter 0.13.3+2015; Godot-Pin b4ccf593d7833e8c259ff0f963494b00d245d03d (isolierter Commit aus PR #155). Unveränderte Android-Paketkennung und originaler Testsignierpfad. Neue Versionskennung 0.13.4+2016.

## Tatsächliche Änderungen
- Native Lufttricks und Driftfunken aus isoliertem Godot-Entwicklungszweig; 2015-Fassaden, Garage und Figurenanimation bleiben erhalten.
- Quellpin-Whitelist explizit und ausschließlich für 2016 erweitert; Tests für fremde/falsche Quellen sowie historische Versionen.
- Bestehende Buildpipeline auf den 2016-Zweig erweitert. Volle Flutter-Capture-Abnahme, alte 2014-Gates und das bestehende Technical-Art-Gate inklusive zusätzlichem Air-Trick-Test sind Voraussetzung vor dem APK-Bau.
- Gesonderte Android-Emulator-Prüfung zur In-place-Aktualisierung von der echten 2015-Baseline (Build 43024454590) auf 2016, mit Prüfung der erhaltenen Kinderdaten, Sterne, XP und Offline-Kart. Aufruf über neuen 2016-Prüfwrapper.

## Grenzen
Quellcode-Integration ist kein bestandener APK-Test. Erfolgreiche CI und die 2015→2016-Aktualisierung müssen nach dem Push erst tatsächlich eintreten. Keine ungeprüften 2013-WIP-Branch-Merges, kein Merge nach main, keine Ersetzung des bisherigen 2015-Installationspakets ohne bestandene Abnahme.
