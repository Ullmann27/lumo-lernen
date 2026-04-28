# Lumo Lernen – nächster Funktions- und Stabilitätsplan

## Grundregel: HomeShell bleibt stabil

Der HomeScreen darf beim Wechsel in andere Bereiche nicht visuell zerfallen oder komplett anders wirken. Die App bekommt deshalb eine feste Shell:

- linke Navigation bleibt immer sichtbar und im gleichen Stil
- rechter Lumo-Bereich bleibt sichtbar oder wird kompakt eingeblendet
- nur der mittlere Content-Bereich wechselt
- Farben, Rundungen, Schatten, Typografie und Kartenstil bleiben einheitlich
- kein Rückfall auf alte Standard-Material-Ansichten
- keine schwarzen Debug-/Exportleisten
- keine roten Flutter-Fehlerflächen

Ziel: Wenn ein Kind auf Mathematik, Deutsch, Englisch, Übung, Test, Schularbeit, Foto oder Profil tippt, bleibt die App weiterhin wie Lumo Lernen aussehen. Es darf nicht wie eine andere App wirken.

## App-Struktur nach bewährtem Lern-App-Schema

Lumo Lernen folgt künftig einer klaren Struktur:

1. Home
   - Tagesmission
   - Weiterlernen
   - Fachkarten
   - Lumo-Vorschlag
   - Sterne, XP, Level, Fortschritt

2. Lernen
   - Fächer
   - Klassenstufe
   - Themenbereiche
   - Lernpfad

3. Übung
   - adaptive Einzelaufgaben
   - sofortiges Feedback
   - Erklärung
   - automatische nächste Aufgabe

4. Missionen
   - 5-Minuten-Startmission
   - 10-Minuten-Fuchsmission
   - Schwächen-Wiederholung
   - Tagesziel

5. Test / Schularbeit
   - gemischte Aufgaben
   - Zeitrahmen
   - Ergebnis
   - Note
   - Speicherung im Profil

6. Lumo-KI
   - sichere kindgerechte Hilfe
   - keine offenen privaten Gespräche
   - Erklärungen zu Aufgaben
   - Pausen- und Motivationstexte

7. Scanner
   - Aufgabenfoto vorbereiten
   - OCR/Textparser vorbereiten
   - Elternreview
   - Übernahme ins Training

8. Profil / Elternbereich
   - Sterne, XP, Level
   - Fehlerprofil
   - Stärken
   - nächste Empfehlung
   - Verlauf

## Stimme / TTS

Die Stimme muss kindgerechter und menschlicher wirken. Kurzfristig wird ein TTS-Service eingebaut:

- langsamere Sprechgeschwindigkeit
- wärmere Tonhöhe
- weichere Sprachpausen
- klare kurze Sätze
- Ein/Aus-Schalter
- sicherer Fallback, falls keine Stimme verfügbar ist

Wichtig: Offline-/Geräte-TTS kann nur so menschlich sein, wie die am Gerät vorhandene Stimme. Für wirklich hochwertige menschliche Stimmen wird später eine Neural-TTS-API oder eine vorbereitete Audio-Bibliothek benötigt.

## Aufgaben und Missionen

Der Aufgabenpool muss größer und besser gegliedert werden:

- Mathematik
- Deutsch
- Rechtschreibung
- Lesen
- Schreiben
- Englisch
- Sachunterricht

Jede Aufgabe braucht:

- Fach
- Klasse
- Thema
- Schwierigkeit
- Frage
- Antwortmöglichkeiten
- richtige Antwort
- Erklärung
- Visualisierungstyp
- Fehlerkategorie

Missionen müssen wirklich genutzt werden:

- Weiterlernen startet passende Mission
- Schularbeit nutzt gemischten Generator
- Fehler erhöhen Schwächenprofil
- richtige Antworten erhöhen Sterne/XP
- Abschluss wird gespeichert

## Kinder-KI

Lumo darf nur sicher und kindgerecht agieren:

- erklärt Lernstoff
- motiviert
- beruhigt bei Fehlern
- schlägt kurze Missionen vor
- schlägt Pausen vor
- blockiert private Daten und gefährliche Inhalte

Keine offenen Chats über Adresse, Telefonnummer, Schule, Social Media, Treffen oder Erwachsenenthemen.

## Speicherlogik

Die App muss lokal speichern:

- Sterne
- XP
- Level
- gelöste Aufgaben
- Fehler pro Thema
- abgeschlossene Missionen
- letzte Note
- letzte Empfehlung

## Technische Reihenfolge

1. Build stabilisieren
2. feste AppShell einführen
3. MissionEngine vollständig verdrahten
4. Aufgabenstruktur erweitern
5. VoiceService/TTS einbauen
6. LocalStore speichern/laden
7. ScanParser vorbereiten
8. Tests ergänzen
9. UI erst danach weiter polieren

## Akzeptanzkriterien

- HomeShell bleibt beim Navigieren optisch konsistent
- keine alten Standard-Screens mehr nach Klick auf Optionen
- Lumo bleibt als Begleiter sichtbar
- Aufgaben springen automatisch weiter
- Missionen funktionieren
- Stimme ist optional und crasht nicht
- Profil speichert Lernstand
- GitHub Actions APK-Build bleibt grün
