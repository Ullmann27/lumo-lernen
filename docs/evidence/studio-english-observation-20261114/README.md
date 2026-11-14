# Englische Lernwelt: aktuelle Beobachtung und Android-Prüfer

Basis: Host `50f2a0edf87a0e22f24345d8504f4d83e803bf37`, Native `e4e5ce03e644a2f23b01a96f1d340a882a1798c4`. Die drei Native-Dateien und die sechs neuen Host-Dateien sind getrennt in den beiden Source-Manifesten gebunden. Gemeinsame Router, Android-Launcher, Workflows und Speicherstände wurden hier nicht verändert.

## Tatsächlich ausgeführte Prüfung

Der finale Headlesslauf meldet 3479 Checks und 98 reale Godot-Touch-Ereignisse, Exit 0. Der separate echte Software-Renderer meldet 3509 Checks, dieselben 98 Touch-Ereignisse und zehn neue PNGs, Exit 0 in 327,971 Sekunden. Beide verwenden die unveränderte tatsächliche Dart-Producer-Ausgabe mit SHA256 `489e7179254cfb951fdf0e8c538a75b000c1f5e61ac74f796ee369e9f457e606`. Die Zahlen werden nicht addiert. Alle zehn finalen Bilder wurden einzeln geöffnet; final-source-render-review.json nennt jeden Hash und Befund. Die Android-View-/JNI-/Audio-Grenze bleibt eine deklarierte Desktopfixture.

Die neuen Python-Verträge haben tatsächlich 26/26 Fälle ohne Skip bestanden. Zusätzlich liest der finale Validator alle zehn aktuellen PNG-/Sidecar-Paare und berechnet die Projektion unabhängig. Sichtbare Pixeldetails ersetzen keine semantische Bilderkennung. Alte 3365/3395-Protokolle bleiben historische Zwischenstände.

## Native-Aufruf

Bestehender Godot-Aufruf mit `--script res://scripts/tests/learning_english_regression.gd`, danach `--capture --output=<Ausgabeverzeichnis> --task-fixtures=<tatsächliches english-activity.json des gepinnten Host-Producers>`. Marker: `LEARNING_ENGLISH_PASS`; Originalreport `learning-english-report.json`. Pro PNG entstehen die bisherige Capturebeschreibung und zusätzlich eine tatsächliche `*.layout.json`. Der Dateiname `user://learning_layout_v1.json` ist nur eine atomare, bei Zustands-/Layoutwechsel invalidierte Beobachtung; er ist keine Eingabe- oder Speicherschnittstelle.

## Android-Aufruf und Voraussetzungen

Der neue Prüfer ist `.github/probes/lumo_english_objects_android_probe.py`. Er verlangt `--candidate-source`, `--native-source`, `--expected-source`, `--expected-native`, `--apk`, `--provenance`, `--sums`, `--tour-result`, `--serial`, `--expected-api` (35 oder37) und `--out`. Alle Quellen sind vollständige tatsächliche Commit-SHAs; CWD und ausgeführter Prüfer müssen im sauberen Kandidatencheckout liegen. Root integriert den konkreten Aufruf nach dem bestehenden vollständigen21-Schritte-Lauf auf demselben bereits installierten APK. Die zusätzliche Probe installiert nichts und fordert kein Root an; sie verlangt den bereits privilegierten kurzlebigen CI-Emulator.

Der bestehende fiktive `LumoTest`-Ein-Kind-Datensatz der Tour bleibt Voraussetzung. Die Navigation behandelt die tatsächlich beobachtete Cards-Zwischenebene über `Zur Spielwelt zurück`, dann Lernen → Englisch → Schulsachen. Es wird keine Antwort oder Aufgabe injiziert. Ein aktuell nicht unterstütztes Wort erzeugt eine ausdrückliche Unsupported-Fehlermeldung. Noch fehlen bag, rubber, school bag, desk, chair, pencil case und paper; diese sieben Gegenstände folgen separat.

Pure Verträge: `python3 -B -m unittest discover -s tools/android_qa/tests -p test_english_objects_android_probe.py -v` im vorbereiteten Host. Die vier JSON-Testfixtures stammen bytegleich aus der tatsächlichen lokalen Produktionsszene und bleiben als platform_fixture gekennzeichnet.

## Grenzen und erhaltene Warnungen

Keine Androidabnahme dieser neuen Quellen, keine englische Aussprache- oder Hörprüfung, keine angewendete Jaw-/Phonemprüfung und keine Fold7-/60FPS-/Temperaturmessung. Die drei Rendererwarnungen zu VSync, Screen-space AA und volumetrischem Nebel sowie die Pillow-getdata-Deprecation im negativen Blankbildtest sind in den unveränderten Rohlogs erhalten. Alle vorhandenen Produkt-/Profil-/Journal-/Schreibtrainerpfade bleiben unberührt; der Probevergleich beansprucht nur tatsächlich vorhandene geschützte Schlüssel.
