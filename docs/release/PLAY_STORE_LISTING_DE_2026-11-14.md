# Deutscher Play-Store-Textentwurf – 14. November 2026

**Status:** redaktioneller Entwurf auf dem unten angegebenen Quellstand. Nicht veröffentlicht.

**Geprüfter Host:** [dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f](https://github.com/Ullmann27/lumo-lernen/commit/dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f)  
**Tree:** `01b3eaddc6b58a0c7f741b039a87f0e26e8af61e`  
**Sprache:** Deutsch; Ausrichtung auf die Volksschule, Klassen 1–4.

Dieser Text ist die aktuelle, enger belegte Fortschreibung von [05_STORE_MATERIAL_TEXTE.md](../marktstart/2026-10-11/05_STORE_MATERIAL_TEXTE.md). Der bestehende Titel und der Kern der Kurzbeschreibung bleiben erhalten. Die frühere Fassung bleibt als historischer Planungsstand bestehen. Preis-, Premium-, Abo- und Werbeaussagen daraus werden hier nicht übernommen.

## Öffentlicher Textentwurf

Die folgenden drei Textblöcke enthalten jeweils nur den Inhalt des entsprechenden Play-Console-Feldes. Überschriften, Zeichentabelle, Quellhinweise und interne Punkte außerhalb dieser Blöcke gehören nicht in diese Felder.

### Titel

```text
Lumo Lernen – Volksschule
```

### Kurzbeschreibung

```text
Mit Lumo Mathe, Lesen und Schreiben in der 1.–4. Klasse üben
```

### Vollständige Beschreibung

```text
Mit dem Fuchs Lumo üben Kinder der 1. bis 4. Klasse der Volksschule Mathe, Lesen und Schreiben. Aufgaben nach Klasse und Thema, kurze Lesetexte und Spiele bringen Abwechslung ins Üben zuhause.

Mathe und Deutsch
Übe Grundrechenarten, den Umgang mit Geld und geometrische Formen. In Deutsch geht es unter anderem um Wörter, Sätze und Rechtschreibung. Wähle ein Thema aus oder wiederhole Inhalte aus früheren Klassen.

Lesen und Schreiben
Lies kurze Texte und beantworte Fragen zum Inhalt. Im Schreibcoach lassen sich Buchstaben mit dem Finger schreiben und wiederholen. Für eigene Texte und Geschichten gibt es das Lumo-Journal.

Lernen im Blick
Der Elternbericht fasst die in der App erfassten Lern- und Leseergebnisse zusammen. So können Erwachsene die Übungen begleiten und passende Themen zum Weiterüben auswählen.

Spielen zwischendurch
Zur Spielwelt gehören Memory, Lumo Cards und Vier gewinnt. Die Spiele ergänzen die Lernbereiche und bieten Abwechslung zwischen den Übungen.

Offline üben, Online-Hilfe optional
Eingebaute Mathe- und Deutschaufgaben lassen sich ohne Internet bearbeiten. Optionale Online-KI-Hilfen und Online-Bilder benötigen eine Internetverbindung und die entsprechende Freigabe in der App. Für die eingebauten Übungsaufgaben müssen diese Online-Funktionen nicht aktiviert werden.
```

## Interne Zeichenprüfung

| Feld | Zeichen im Entwurf | Offizielle Höchstzahl |
|---|---:|---:|
| Titel | 25 | 30 |
| Kurzbeschreibung | 60 | 80 |
| Vollständige Beschreibung | 1306 | 4.000 |

Gezählt wird der genaue Inhalt jedes Textblocks einschließlich Leerzeichen und der LF-Zeilenumbrüche innerhalb der vollständigen Beschreibung. Markdown-Begrenzer und der abschließende Zeilenumbruch vor dem schließenden Begrenzer zählen nicht zum Feld. Alle verwendeten Zeichen liegen in der Unicode-Basisebene; Codepoint- und UTF-16-Zählung ergeben hier identische Werte.

Google nennt aktuell 30, 80 und 4.000 Zeichen für diese Felder. Quelle: [App erstellen und einrichten – Haupt-Store-Eintrag](https://support.google.com/googleplay/android-developer/answer/9859152?hl=de), abgerufen am 14. November 2026. Die [Metadatenrichtlinie](https://support.google.com/googleplay/android-developer/answer/9898842?hl=de) verlangt eine zutreffende Beschreibung der Funktionalität.

## Interne Quellen- und Freigabegrenze

Die einzelnen Aussagen sind in [PLAY_STORE_LISTING_DE_2026-11-14.sources.json](PLAY_STORE_LISTING_DE_2026-11-14.sources.json) mit Pfad, unveränderlicher Git-Blob-ID und Zeilenbeleg zugeordnet. Die Quellenprüfung umfasst echte lokale Aufgabengeneratoren und ihre Aufrufer, Schreibcoach und Journal, Elternbericht, die drei genannten Spielrouten sowie die Freigaben für Online-Hilfe und Online-Bilder.

„Ohne Internet“ bezieht sich ausschließlich auf die genannten eingebauten Mathe- und Deutschaufgaben. Es ist keine Aussage über sämtliche App-Funktionen, SDK-Telemetrie oder die Verarbeitung personenbezogener Daten. Lokale Hilfestellungen werden nicht als internetpflichtig beschrieben. Online-Dienste wurden für diese Textarbeit nicht kontaktiert; ihre Erreichbarkeit wird nicht zugesichert.

Diese Dokumentation bescheinigt keine Veröffentlichung, Store-Zulassung oder vollständige Release-Abnahme. Die laufende Build- und Gerätevalidierung bleibt getrennt. Für diese Textarbeit wurden keine neuen Flutter-, Android- oder Flugmodusprüfungen ausgeführt. Vor Übernahme in die Play Console müssen Text und tatsächlicher auszuliefernder Build zusammenpassen.

## Interne offene Betreiberangaben vor einer Veröffentlichung

Die folgenden Angaben sind außerhalb des öffentlichen Textentwurfs zu bestätigen; in dieser Arbeit wurden dafür keine öffentlichen Kontaktdaten erfunden oder aus privaten Profilinformationen übernommen:

- **Entwickler-/Betreiberangabe:** die für das tatsächliche Play-Konto und den Store-Auftritt zutreffende, freigegebene Angabe.
- **Öffentliche Support-E-Mail-Adresse:** eine erreichbare, ausdrücklich für den Store vorgesehene Adresse. Google verlangt eine Kontakt-E-Mail-Adresse; eine zusätzliche Support-Website wird empfohlen.
- **Datenschutzerklärung:** eine aktive, öffentlich erreichbare URL zur tatsächlich zutreffenden Erklärung. Google verlangt diese in der Play Console und zusätzlich einen Link oder den Erklärungstext in der App.
- **Datenschutzkontakt und Verantwortlichkeit:** die bestätigten Entwicklerangaben sowie eine Kontaktmöglichkeit für Datenschutzanfragen müssen zur tatsächlichen Datenverarbeitung passen. Der App-Titel oder das im Store genannte Rechtssubjekt muss in der Erklärung genannt werden.

Die Angaben zu tatsächlichen Datenflüssen, Drittanbietern, Aufbewahrung und Löschung sind mit dem freizugebenden Build abzugleichen. Der Store-Text ersetzt weder diese Erklärung noch die Angaben zur Datensicherheit. Quelle: [Google-Play-Richtlinie zu Nutzerdaten, Abschnitt Datenschutzerklärung](https://support.google.com/googleplay/android-developer/answer/10144311?hl=de), abgerufen am 14. November 2026.

Es werden hier weder ein vollständiger Lehrplan, ein bestimmter Lernerfolg, eine Bildrate, eine fremde Qualitätszertifizierung noch eine Garantie „keine Datenverarbeitung“ behauptet. Ein Preis-, Kauf- oder Abomodell wird nicht vorweggenommen.
