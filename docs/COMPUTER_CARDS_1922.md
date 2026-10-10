# Lumo Cards und Vier Gewinnt: Entwicklerübergabe 1922

## Basis und Grenzen

Basis: `36f884f325bab6954a7fd5306788b4a192f881f3` auf
`codex/lumo-reference-assets-2026-10-10`. Dies ist der neueste geprüfte
Referenzarchiv-Zweig auf der 1921/1920-Entwicklungslinie, nicht das ältere
`main`. Godot bleibt unverändert auf dem exakten Pin aus
`config/godot-source.json`. Kein Main-Merge, Force-Push oder Release.

## Zuständigkeiten

- `lib/features/games/connect_four/connect_four_engine.dart`: reine Regeln,
  Schwerkraft, 69 Gewinnlinien, Remis, nicht-mutierende Anfänger-KI.
- `lib/features/games/connect_four/lumo_connect_four_game.dart`: Flutter-UI,
  Einzelspiel/lokales Zweierspiel, Fallanimation, Pause, Neustart, Wallet.
- `lib/widgets/design/lumo_motion.dart`: gemeinsame Druck- und Hoverreaktion,
  einschließlich reduzierter Animationen und abgebrochener Berührungen.
- `lib/core/lumo_voice_policy.dart`: Textaufbereitung und Offline-Stimmenwahl.
- `lib/core/lumo_voice.dart`: serialisierte Ausgabe, Mute-/Clip-Startschutz.
- `tools/voice/import_generated_clips.mjs`: Audioimport, AAC, reale
  Hüllkurven, SHA-256 und Entfernung ersetzter Katalogaufnahmen.
- `scripts/audit_source.mjs`: Erreichbarkeit ab `main.dart`, aktive Pakete,
  fehlende/verwaiste Sprachdateien.

## Design und Audio

Der vorhandene Lumo-Nachthimmel und der Original-Fuchs werden weiterverwendet.
Die zwei generierten Umgebungsvarianten sind Konzepte, keine Runtime-Bilder;
keine davon ersetzt ungeprüft die Markenwelt. Cyan/Gold-Steine, dunkles Glas
und Leuchtkonturen lösen das alte helle Brett ab. Es gibt keinen fingierten
Lern-Duell-Modus und keine fest eingebauten Beispielbelohnungen.

Sechs neue deutsche Sulafat-Aufnahmen ersetzen den alten Piper-Katalog.
Häufiges Lob und Zughinweise haben explizite Alias-Auslöser. Alle anderen
Texte verwenden Geräte-TTS mit natürlicheren Sprechprofilen; die Stimme
hängt weiterhin vom installierten Android-TTS-Anbieter ab. Keine
Kinderdaten werden zur Laufzeit an den Synthesedienst gesendet.

Die akustische Auswertung des externen Prüftools war nicht verwendbar:
es meldete trotz Audiodatei, nur Text erhalten zu haben. Deshalb wird
keine objektive Klangabnahme oder hörbare Echtgeräteprüfung behauptet.
Die drei Stimmproben ermöglichen spätere persönliche Feinabstimmung.

## Bereinigung und Fehlerbehebung

Unbenutztes altes Onboarding samt Schrittindikator entfernt. Der ausschließlich
von Vertragstests verwendete Lehrplan-Support liegt nun unter `test/support/`.
Alle direkt deklarierten Laufzeitpakete werden verwendet; kein Paket wurde
blind entfernt oder wegen einer neueren Versionsnummer ausgetauscht.
Alte Lernstände, Referenzbilder und Godot-Spiele bleiben erhalten.

Der Belohnungs-Burst entfernt nur noch seine eigene Route, statt nach
1,8 Sekunden eventuell eine inzwischen geöffnete Seite zu schließen.
Einstellungen und Löschdialog prüfen den tatsächlich verwendeten
BuildContext nach asynchronen Operationen.

## Prüfbefehle

```sh
flutter pub get --enforce-lockfile
node scripts/audit_source.mjs
flutter analyze
flutter test --no-pub --concurrency=2
node --test server/lumo-ai-proxy/test/*.test.js
python3 -m unittest discover -s scripts/tests
python3 -m unittest discover -s tools/android_qa/tests
dart scripts/audit_content.dart
bash scripts/build_unified_apk.sh
```

Für Widget-Renderbilder:
`LUMO_CONNECT_CAPTURES=/absoluter/pfad flutter test test/design/connect_four_visual_test.dart`.
Diese Bilder stammen aus der Flutter-Test-Engine und sind keine
Android-Geräteaufnahmen. Der APK-Build muss erst tatsächlich abgeschlossen
und signatur-/versions-/PCK-geprüft sein, bevor ein APK-Erfolg gemeldet wird.
