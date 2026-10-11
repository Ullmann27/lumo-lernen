# Lumo Lernen: geprüfter Qualitätsfeinschliff

11. Oktober 2026. Aufbau auf PR #261 (`5f2f32f`), einschließlich dessen Android-Basis aus #259. Produktänderung: `dc708ea`. Eigener Branch `astra/lumo-learning-quality-2026-10-11`. Kein Merge nach main, keine neue APK. Der Godot-Pin bleibt unverändert.

## Sichtbares Ergebnis

- **Querformat 640 × 360:** Plus, Minus, Formen, Uhr und Zahlen zeigen Aufgabe und Antworten nebeneinander. Zurück, Modul, Lumo und tatsächlicher Fortschritt stehen links. Die zuvor raumfüllende globale Kopf-/Navigationsleiste wird in diesem Format durch den direkten Rückweg zur Übersicht ersetzt. Safe Areas bleiben berücksichtigt. Große Schrift nutzt Scrollen statt verkleinerter Texte.
- **Ruhigere Hologlasflächen:** Die bestehende gemeinsame Glaskomponente unterstützt einen Deckkraftwert. Lernkarten nutzen 90 % statt 68 %; die Bibliothek lenkt hinter Texten und Mengen weniger ab. Cyan-Kanten und Original-Lumo bleiben erhalten. Andere App-Bereiche behalten ihren Wert.
- **Lesbare Auswahl:** Formen und Uhr zeigen im kurzen Querformat breite Zeilen; Wörter werden nicht mitten im Namen umgebrochen. Plus nutzt dort 2 × 2 große Antworten und erreichbare Tipp-/Weiter-Aktionen.
- **Lumo-Hinweise:** Hinweise beziehen sich auf Mengen, Nachfolger, Ecken/Seiten oder Stunden-/Minutenzeiger. Richtige Antworten lösen weiterhin erst nach erfolgreichem Speichern Jubel und Zählfortschritt aus.
- **Uhr:** Bei den ersten vollen Stunden enthalten auch alle Ablenkantworten volle Stunden. Die richtige Lösung lässt sich nicht mehr allein an der einzigen Antwort mit „Uhr“ erkennen. Stunden umfassen jetzt 1–12; 12:30 heißt „halb 1“, 12:45 „Viertel vor 1“. Der lange Minutenzeiger ist zusätzlich farblich unterscheidbar.
- **Zahlen:** Nachfolgeraufgaben enthalten auch 9 → 10; zuvor endete die Ausgangszahl bei 8.

Originalvergleich: [Plus-Referenz 51024.jpg](../2026-10-11-learning-adventures/images/Originalreferenz-51024.jpg). Dunkelblaue Lernwelt, Lumo mit Buch, Hologlas, Mengen und klare Antwortflächen bleiben verbindlich. Die Fold-/Querformat-Komposition passt diese Elemente an die verfügbare Fläche an.

## Echte Vorher-/Nachher-Bilder

Die PNGs stammen aus den bestehenden echten Modul-Widgets im Flutter-Testrenderer. Keine generierten Konzepte, kein Android-Emulator und kein physisches Fold. Die Aufgaben werden regulär zufällig erzeugt; Vorher/Nachher zeigt daher teilweise unterschiedliche Aufgaben. Fold: 2176 × 1812 physische Pixel bei Dichte 2,25, gerendert in logischer Auflösung. Die hier sichtbaren Aufnahmen enthalten keine simulierten Systemleisten; die gesonderten Layouttests prüfen 24-Pixel-Safe-Areas.

| Modul / Format | Ausgangsstand | Geprüfte Änderung |
|---|---|---|
| plus-bis-10-reference · phone-360x800 | [Vorher](images/before/plus-bis-10-reference-phone-360x800.png) | [Nachher](images/after/plus-bis-10-reference-phone-360x800.png) |
| plus-bis-10-reference · landscape-640x360 | [Vorher](images/before/plus-bis-10-reference-landscape-640x360.png) | [Nachher](images/after/plus-bis-10-reference-landscape-640x360.png) |
| plus-bis-10-reference · fold-2176x1812-density-225 | [Vorher](images/before/plus-bis-10-reference-fold-2176x1812-density-225.png) | [Nachher](images/after/plus-bis-10-reference-fold-2176x1812-density-225.png) |
| minus-bis-10 · phone-360x800 | [Vorher](images/before/minus-bis-10-phone-360x800.png) | [Nachher](images/after/minus-bis-10-phone-360x800.png) |
| minus-bis-10 · landscape-640x360 | [Vorher](images/before/minus-bis-10-landscape-640x360.png) | [Nachher](images/after/minus-bis-10-landscape-640x360.png) |
| minus-bis-10 · fold-2176x1812-density-225 | [Vorher](images/before/minus-bis-10-fold-2176x1812-density-225.png) | [Nachher](images/after/minus-bis-10-fold-2176x1812-density-225.png) |
| formen · phone-360x800 | [Vorher](images/before/formen-phone-360x800.png) | [Nachher](images/after/formen-phone-360x800.png) |
| formen · landscape-640x360 | [Vorher](images/before/formen-landscape-640x360.png) | [Nachher](images/after/formen-landscape-640x360.png) |
| formen · fold-2176x1812-density-225 | [Vorher](images/before/formen-fold-2176x1812-density-225.png) | [Nachher](images/after/formen-fold-2176x1812-density-225.png) |
| uhr · phone-360x800 | [Vorher](images/before/uhr-phone-360x800.png) | [Nachher](images/after/uhr-phone-360x800.png) |
| uhr · landscape-640x360 | [Vorher](images/before/uhr-landscape-640x360.png) | [Nachher](images/after/uhr-landscape-640x360.png) |
| uhr · fold-2176x1812-density-225 | [Vorher](images/before/uhr-fold-2176x1812-density-225.png) | [Nachher](images/after/uhr-fold-2176x1812-density-225.png) |
| zahlen-bis-10 · phone-360x800 | [Vorher](images/before/zahlen-bis-10-phone-360x800.png) | [Nachher](images/after/zahlen-bis-10-phone-360x800.png) |
| zahlen-bis-10 · landscape-640x360 | [Vorher](images/before/zahlen-bis-10-landscape-640x360.png) | [Nachher](images/after/zahlen-bis-10-landscape-640x360.png) |
| zahlen-bis-10 · fold-2176x1812-density-225 | [Vorher](images/before/zahlen-bis-10-fold-2176x1812-density-225.png) | [Nachher](images/after/zahlen-bis-10-fold-2176x1812-density-225.png) |

## Ausgeführte Prüfung

- Ausgangsstand: 81 Layout-/Speichertests und 20 Laufzeitaufnahmen bestanden.
- Sieben neue Fehlerfälle vor Korrektur nachgewiesen: falsche Uhr-Antwortstufe, fehlender Nachfolger von 9 und nicht sichtbare Antworten in allen fünf Querformatmodulen. Originalprotokoll `logs/quality-red.log.gz`.
- Vollständige Suite: **1006 bestanden, 107 übersprungen, keine Fehler**. Darunter 80 optionale Capture-Cases, die separat sämtlich ausgeführt wurden; 27 bestehende weitere Skips bleiben bestehen.
- 80 Aufnahmen: 20 Module × Phone, Querformat, breites Layout und Fold; sämtliche Renderprüfungen bestanden. Dadurch ist der gemeinsame Baustein auch auf den übrigen Modulen geprüft. Die 30 ausgewählten Vorher-/Nachher-PNGs oben zeigen die Prioritätsmodule.
- Analyse: **0 Errors, 0 Warnings, 20 bestehende Info-Lints**. Keine neuen Pakete, keine Änderung an Wallet, Profilverwaltung, Stimme, Schreibcoach oder Buildkonfiguration.
- Uhr-Grenzfälle: alle acht Aufgabenanzeigen und sieben Übergänge mit 12 Uhr, halb 1, Viertel nach 12 und Viertel vor 1 geprüft; vier unterschiedliche Antwortmöglichkeiten pro Aufgabe. Der vollständige Sitzungsabschluss wird separat durch die bestehenden Fortschrittstests geprüft.
- Layout: alle fünf Module mit Safe Areas, Fold, großer Schrift (Faktor 2) und kurzen Querformaten; Antworten mindestens 48 × 48. Bestehende Tests für gespeicherte Antworten, Wiederholung bei Speicherfehlern, gesperrte Navigation während Speicherung und einmaligen Abschlussbonus bestehen weiter.

Reproduktion:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos
flutter test --reporter expanded
LUMO_LEARNING_CAPTURE_DIR=/tmp/lumo-learning-captures flutter test test/design/learning_adventure_capture_test.dart --reporter expanded
```

Quellstände, Prüfzahlen und Datei-Hashes: [EVIDENCE.json](EVIDENCE.json). Der unabhängige Agentenreview des App-Diffs `5f2f32f..59f7f3a` fand keine wesentlichen Codeprobleme. Sein Hinweis zur präzisen Beschreibung des Uhr-Grenzfalltests ist oben eingearbeitet. Der Review war lesend und führte keine zusätzlichen Tests aus; eigene Bildprüfung und ausgeführte Tests sind getrennt belegt.

## Konkrete Inhaltslücken / nächste pädagogische Etappe

Bezug: [österreichischer Volksschulrahmen Klasse 1–4](../../AUSTRIA_VOLKSSCHULE_CURRICULUM_2026.md). Diese fünf Einstiegsübungen sind kein vollständiger Lehrplannachweis.

| Bereich | Noch offene Aufgabe |
|---|---|
| Plus/Minus bis 10 | Nullaufgaben, vollständiges Wegnehmen mit Ergebnis 0 und systematisch belegte Aufgabenabdeckung ergänzen. Das Minus-Modul erzeugt derzeit nur positive Ergebnisse. |
| Formen | Gedrehte/verschieden große Formen, Vergleichen von Eigenschaften und Übergang zu geometrischen Körpern; aktuell vor allem sechs feste ebene Motive benennen. |
| Uhr | Selbstständiges Stellen einer Uhr, Digital-/24-Stunden-Bezug, Zeitspannen und kompetenzabhängige Auswahl. Der Schwierigkeitswechsel folgt noch der Aufgabenposition; neue Zeitarten sind nicht in jeder zufälligen Sitzung garantiert. |
| Zahlen | Vorgänger, Zahlzerlegungen und Zahlenstrahl gezielt abdecken; die drei vorhandenen Aufgabenarten ersetzen dies nicht. |
| Fehlerfeedback | Bei Uhr/Formen/Zahlen läuft die Rückmeldung noch nach kurzer Zeit weiter. Selbstbestimmtes Erklären/Wiederholen sollte mit gespeichertem Lernkontext und der laufenden Sol-Sprachintegration abgestimmt werden. |
| Klasse 3–4 | Transfer der Gestaltung ist geprüft; Inhaltsvollständigkeit, Kompetenzabdeckung und Hilfestufen der höheren Klassen sind gesondert zu auditieren. |

Noch ausstehend: gemeinsame Android-Integration, Update-/Gerätetest und physisches Galaxy Z Fold. Aus den Flutter-Testbildern werden keine Geräte-FPS, Wärme- oder Akkuaussagen abgeleitet. Backend/Sulafat und gewöhnliche Buildarbeit bleiben im vereinbarten Sol-Bereich.
