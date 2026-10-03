> Neuere Fortsetzung: [Lernfuchs, Aufgaben, PIN und APK](LUMO_COACH_2026-10-02.md).
> Die unten dokumentierte frühere Beschränkung auf Codex wurde durch den späteren ausdrücklichen KI-Auftrag ergänzt.

# Lumo – Fortsetzung für den Schultest

## Grundlage und Ablage

Fortsetzung von PR #151 nach dessen Merge in `main` (`1e0eeaa`). Sämtliche 19
übergebenen Dateien sind bytegenau einschließlich der Duplikate im
[Projektarchiv](../archive/project-sources/2026-10-02/README.md) enthalten.
Nach dem Hinweis auf das öffentliche Repository hat der Nutzer am 2. Oktober
2026 die öffentliche Ablage ausdrücklich freigegeben. Die Originaldateien
bleiben als historische Quellen unverändert; ein Index erklärt Herkunft,
Duplikate, Dateigrößen und SHA-256-Prüfsummen.
Die frühere App wird nicht durch einen alten HTML-Prototyp ersetzt.

## Korrekturen

- Falsche Antworten ohne Wiederholung verwenden die vorhandene Abzugsregel
  statt Abschluss-/Prüfungsboni. Übungsfehlversuche vergeben keine Sterne/XP.
- Fehlgeschlagene Zeichenaufgaben bleiben im Übungsmodus bearbeitbar.
- Schularbeiten erhalten keine Fehlerdetektiv-Tipps; das Tipp-Banner im
  Übungsmodus erzeugt keine unbeschränkte Höhe mehr.
- Gespeicherte Einstellungen werden vor Freigabe der Elternbereiche geladen;
  auch direkte Einstellungs-/Profillinks passieren das PIN-Gate.
- Wallet-Laden berücksichtigt währenddessen verdiente Sterne/XP. Profilreset
  leert auch den Singleton und wartet ausstehende Schreibvorgänge ab.
- Alte Shopguthaben werden vor dem Wechsel zur zentralen Wallet übernommen;
  ein bereits gespeichertes Guthaben von null bleibt null.
- Die Hintergrundanimation begrenzt Transparenz nach Anwendung der Intensität
  und erzeugt dadurch keine ungültigen Farbwerte mehr.
- KI-Statistik liest den Aufgabenvorrat der aktiven Klasse.
- Gesundheitsanzeige unterscheidet gespeicherten API-Schlüssel, erreichbaren
  Proxy und tatsächlich erfolgreiche KI-Verbindung.
- Gleichzeitige identische Aufgabenanfragen teilen die laufende Erzeugung.
  Übergroße Uploads werden mit HTTP 413 beantwortet und zeitnah geschlossen.
- Generierte Mathetexte und Erklärungen werden aus geprüften Rechenschritten
  aufgebaut. Freie KI-Sachgeschichten werden nicht allein wegen passend
  behaupteter Rechenmetadaten als korrekt behandelt. Lokale Sachaufgaben bleiben.
- Deutsche Krieg-/Waffen-Komposita werden vom bestehenden Kinderfilter erfasst.
  Der abschließend gemeldete Fehlalarm bei „Die Kinder kriegen Hausaufgaben“
  ist korrigiert; normale Verbformen werden unabhängig vom Subjekt behandelt.
  Dies bleibt eine begrenzte lexikalische Regel, keine vollständige Sprachprüfung.
- APK-Release enthält wieder die vom App-Updater gelesene Buildnummer/Version.
- `pubspec.lock` hält die für diese Prüfung aufgelösten App-Abhängigkeiten fest.

## Einordnung früherer Reviewmeldungen

Der gemeldete Variantenfehler (24 statt mehr als 30) war im übernommenen Stand
bereits korrigiert. Die ergänzte Prüfung zählt echte sichtbare Aufgaben und
prüft ihre Ergebnisse, statt allein die Größe des Parameterbereichs zu zählen.

Die Behauptung, `gpt-6-luna` sei ein erfundener API-Modellname, wurde nicht
übernommen: Die [offizielle Modellseite](https://developers.openai.com/api/docs/models/gpt-6-luna)
wurde am 2. Oktober 2026 gelesen und nennt diesen Identifier ausdrücklich.
Das beweist keine Freischaltung oder verfügbare Quote im konkreten Konto.

## Prüfstand

Lokal mit Flutter 3.44.9 / Dart 3.12.2:

| Prüfung | Ergebnis |
|---|---|
| Vollständige Flutter-Suite | 295 bestanden, 4 bereits zuvor übersprungen, keine Fehler |
| Backend Node-Regressionen | 17 bestanden nach dem abschließenden Filterfix; künstliche Upstream-Antworten, keine Live-KI |
| Android-Hostvorbereitung | 1 Regressionstest bestanden, inkl. erneutem idempotentem Durchlauf |
| Inhaltsaudit | 26.100 Aufgabenvarianten erfolgreich geprüft |
| Repair Guard | bestanden |
| Flutter-Analyse | 0 Fehler; 28 Warnungen und 76 Hinweise im Gesamtprojekt bleiben sichtbar |
| Änderungen am Anwendungscode auf Whitespace-/Patchfehler | bestanden; historische Originaldateien bleiben bytegenau erhalten |
| Android-APK-Prüfbau | GitHub Actions Build #945 erfolgreich, einschließlich Tests, Analyse und APK-Bau |

Die neuen Integrationstests klicken echte Antworten, prüfen die Wallet nach
Neustart, testen fehlgeschlagene Zeichenversuche und die PIN beim direkten
Settings-Link. Die Health-Prüfung nutzt einen lokalen HTTP-Testserver.
Der [Android-Prüfbau #945](https://github.com/Ullmann27/lumo-lernen/actions/runs/37021317982)
hat Anwendungscode-Commit `8e7016595fa254a33bf892f64b73ba33c61497a7` erfolgreich gebaut.
Die anschließende Archivierung ändert nur Originalquellen und Dokumentation.
Der danach ergänzte Verbfilter-Fix betrifft ausschließlich den separat betriebenen
Node-Server; sein kompletter Testlauf besteht mit 17 Tests. Der Android-/Flutter-
Anwendungscode ist unverändert gegenüber dem erfolgreichen Prüfbau.
Dieser Prüflauf hat keine APK zum Download veröffentlicht;
die automatische APK-Ausgabe des Repositorys erfolgt separat im Release-Workflow.
Keine Produktivbereitstellung durch diese Fortsetzung.

## Noch offen

- Nutzerwahl dieser Fortsetzung: nur Codex-Projekt. Kein Render-Deployment oder
  Live-KI-Aufruf durchgeführt; der zuvor gemeldete Livefehler bleibt unbestätigt.
- Gerätetest auf Android/Fold, Installation/Update, Mikrofon/Kamera und
  Wechsel in die separate Godot-App.
- Gemeinsame Wallet zwischen Flutter und Godot sowie Unterrichtsbewertung.
- Vier im Ausgangsstand übersprungene Flutter-Tests sind weiterhin separat
  sichtbar; ein bestandener Prüflauf ist keine Behauptung völliger Fehlerfreiheit.
