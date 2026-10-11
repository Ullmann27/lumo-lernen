# Tatsächliche Abnahme der Testversion 1931

Produktquelle `0dc3b1f30d7d885cc0c9914d1f557fad8655d762`, PR267, Version0.12.24+1931.
Diese Nachweise und der direkte ZIP-Workflow verändern keinen Produktcode und
lösen keinen weiteren APK-Bau aus.

- Exakte vollständige Flutter-CI38154592604:1302bestanden,117optionale
  Aufnahmefälle übersprungen,0fehlgeschlagen. Lokale Pythonregressionen:97PASS.
- Android16/API36 x86_64-Emulator38154543561: Update1930→1931 ohne
  Deinstallation, Profil/Wallet erhalten, kostenlose lokale F2-Stimme und
  Original-Sulafat-Aufnahmen, Synthese/Wiedergabe/Pause/Fortsetzen/Stopp,
  Godot-Menü/Rückkehr, vollständiges Plus, Minus und getrenntes freiwilliges
  Vorlernen, tatsächliche Speicherung und Neustart bestanden.
- Minuskurs:2richtige selbstständige Antworten,1falsche Antwort,1Aufgabe mit
  Hilfe; bestehende Plusdaten und Entdeckungsdaten unverändert. Beide tatsächlich
  aufgerufenen Hilfen unterscheiden sich. Geführte Beispiele zählen nicht als
  selbstständig gelöste Schulaufgaben. Die vorhandene Wallet bleibt unverändert.
- 14gespeicherte tatsächliche Accessibility-Frames erneut mit den unveränderten
  Prüfbedingungen geprüft: richtige Antwort, korrekte Rückmeldung und aktivierte
  Weiter-Taste im selben aktuellen Ausschnitt.
- Original-ZIP tatsächlich heruntergeladen/geöffnet: CRC, SHA256, exakte
  eingebettete APK und13echte Android-Bilder geprüft. ARM64-APK-Signatur zusätzlich
  lokal kryptografisch über Googleapksig8.9.1/den bestehenden JavaVerifier bestätigt.

Die drei PNGs hier sind echte Android-Emulatoraufnahmen. Das MP4 besteht aus
64echten Flutter-Widget-Laufzeitframes nach dem Replay-Tap. Es ist keine
Android-Aufnahme und keine Messung der mobilen Bildrate. Der zusätzliche
vollständige Minuskurs-Test besteht an sechs simulierten Größen einschließlich
320×568,Querformat640×360,Tablet1024×768,Foldziel und2×Schrift.

## Reproduzierbare ergänzende Flutter-Probes

Von der Repositorywurzel mit Flutter3.44.9:

```
flutter test docs/education/2026-10-11-1931-final/minus_device_matrix_test.dart --plain-name 'complete school course and reachable targets'
LUMO_GUIDED_CAPTURE_DIR=/tmp/lumo-minus-captures flutter test docs/education/2026-10-11-1931-final/minus_animation_capture_test.dart --plain-name 'actual subtract_ten'
```

Die Dateien sind dokumentierte Ableitungen vorhandener, im Produktcommit
enthaltener Prüfläufe. Sie tauschen ausschließlich die geprüfte Kurskonstante
beziehungsweise den Kurs für die vorhandene Replay-Aufnahmeschleife aus.

Das Curriculum-Inventar zeigt vorhandene App-Themen und ihren Anschluss an
tatsächlich geführte Einführungen. Es ist kein Vollständigkeitsnachweis für den
österreichischen Lehrplan. Deutsch und Sachunterricht haben bereits Aufgaben,
aber noch keine geführten Einführungen; weitere Mathematikwege fehlen ebenfalls.
Automatische Inhaltsprüfungen sind keine externe pädagogische Abnahme.

Offen: physisches Samsung/Fold/ARM64, echte Scharnierereignisse, menschliche
Sprachqualität, komplette Android-Mehrprofil-/Widerrufsmatrix, vollständiges
Kart-Rennen, externe Lehrplan-/Erwachsenen-/Lizenz-/Google-Play-Abnahme.
Testversion; keine öffentliche Releasefreigabe oder echten Zahlungen.
